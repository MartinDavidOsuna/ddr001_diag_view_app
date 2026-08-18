import 'dart:math' as math;

import 'package:image/image.dart' as img;

import 'vision_models.dart';

abstract interface class NeedleDetectionPort {
  Future<NeedleDetection?> detect(
    img.Image dialImage,
    DialVisionConfiguration configuration,
  );
}

double normalizeAngleDegrees(double value) {
  final normalized = value % 360;
  return normalized < 0 ? normalized + 360 : normalized;
}

double angleToLiters(double angleDegrees, DialVisionConfiguration config) {
  final relative = config.clockwise
      ? normalizeAngleDegrees(angleDegrees - config.zeroAngleDegrees)
      : normalizeAngleDegrees(config.zeroAngleDegrees - angleDegrees);
  return relative / 360 * config.litersPerRevolution;
}

final class RedNeedleDetector implements NeedleDetectionPort {
  const RedNeedleDetector({this.minimumRedPixels = 16});

  final int minimumRedPixels;

  @override
  Future<NeedleDetection?> detect(
    img.Image image,
    DialVisionConfiguration config,
  ) async {
    final centerX = image.width / 2;
    final centerY = image.height / 2;
    final scale = math.min(image.width, image.height).toDouble();
    final maxRadius = .55 * scale;
    final points = <({double x, double y, double weight})>[];

    for (var y = 0; y < image.height; y += 2) {
      for (var x = 0; x < image.width; x += 2) {
        final dx = x - centerX;
        final dy = y - centerY;
        final radius = math.sqrt(dx * dx + dy * dy);
        if (radius > maxRadius) continue;
        final pixel = image.getPixel(x, y);
        final red = pixel.r.toDouble();
        final green = pixel.g.toDouble();
        final blue = pixel.b.toDouble();
        final maximum = math.max(red, math.max(green, blue));
        final minimum = math.min(red, math.min(green, blue));
        final chroma = maximum - minimum;
        final saturation = maximum == 0 ? 0.0 : chroma / maximum;
        final hue = chroma == 0
            ? 0.0
            : normalizeAngleDegrees(60 * ((green - blue) / chroma));
        final dominance = red - math.max(green, blue);
        final isRedHue = hue <= 22 || hue >= 338;
        if (maximum < 65 || saturation < .35 || !isRedHue || dominance < 22) {
          continue;
        }
        points.add((
          x: x.toDouble(),
          y: y.toDouble(),
          weight: dominance * saturation,
        ));
      }
    }
    if (points.length < minimumRedPixels) return null;

    // Treat the configured center only as a search anchor. The hub is the red
    // cluster nearest that anchor; angles are then accumulated from the
    // refined physical center. This keeps geometry separate from metrology and
    // avoids a quadrant-dependent bias when the adjusted ROI is slightly off.
    final hubSearchRadius = .12 * scale;
    final hubPoints = points.where((point) {
      final dx = point.x - centerX;
      final dy = point.y - centerY;
      return math.sqrt(dx * dx + dy * dy) <= hubSearchRadius;
    }).toList();
    if (hubPoints.length < 3) return null;
    final hubWeight = hubPoints.fold<double>(0, (sum, p) => sum + p.weight);
    final hubX =
        hubPoints.fold<double>(0, (sum, p) => sum + p.x * p.weight) / hubWeight;
    final hubY =
        hubPoints.fold<double>(0, (sum, p) => sum + p.y * p.weight) / hubWeight;
    final bins = List<double>.filled(360, 0);
    final minNeedleRadius = .08 * scale;
    final maxNeedleRadius = .48 * scale;
    for (final point in points) {
      final dx = point.x - hubX;
      final dy = point.y - hubY;
      final radius = math.sqrt(dx * dx + dy * dy);
      if (radius < minNeedleRadius || radius > maxNeedleRadius) continue;
      final angle = normalizeAngleDegrees(math.atan2(dy, dx) * 180 / math.pi);
      final radialWeight = radius / maxNeedleRadius;
      bins[angle.floor() % bins.length] +=
          point.weight * radialWeight * radialWeight;
    }
    final outerPoints = points.where((point) {
      final dx = point.x - hubX;
      final dy = point.y - hubY;
      return math.sqrt(dx * dx + dy * dy) >= .18 * scale;
    }).toList();
    if (outerPoints.length < math.max(4, minimumRedPixels ~/ 3)) return null;
    // Real water-meter pointers are frequently broad painted triangles rather
    // than one-pixel lines. Measure a narrow radial sector instead of only
    // three degrees, otherwise a valid broad red needle is reported at the
    // wrong edge or rejected for low confidence.
    const halfWindow = 8;
    var bestBin = 0;
    var bestWindowWeight = -1.0;
    for (var center = 0; center < bins.length; center++) {
      var weight = 0.0;
      for (var offset = -halfWindow; offset <= halfWindow; offset++) {
        weight += bins[(center + offset) % bins.length];
      }
      if (weight > bestWindowWeight) {
        bestWindowWeight = weight;
        bestBin = center;
      }
    }
    var neighborhood = 0.0;
    var vectorX = 0.0;
    var vectorY = 0.0;
    for (var offset = -halfWindow; offset <= halfWindow; offset++) {
      final index = (bestBin + offset) % bins.length;
      final weight = bins[index];
      neighborhood += weight;
      final radians = (index + .5) * math.pi / 180;
      vectorX += math.cos(radians) * weight;
      vectorY += math.sin(radians) * weight;
    }
    final total = bins.fold<double>(0, (sum, value) => sum + value);
    final confidence = total == 0
        ? 0.0
        : (neighborhood / total).clamp(0, 1).toDouble();
    if (confidence < .30) return null;
    final radialBuckets = <int>{};
    var maximumReach = 0.0;
    for (final point in points) {
      final dx = point.x - hubX;
      final dy = point.y - hubY;
      final radius = math.sqrt(dx * dx + dy * dy);
      if (radius < minNeedleRadius || radius > maxNeedleRadius) continue;
      final pointAngle = normalizeAngleDegrees(
        math.atan2(dy, dx) * 180 / math.pi,
      );
      final separation = math.min(
        normalizeAngleDegrees(pointAngle - (bestBin + .5)),
        normalizeAngleDegrees((bestBin + .5) - pointAngle),
      );
      if (separation <= 8) {
        radialBuckets.add((radius / (.05 * scale)).floor());
        maximumReach = math.max(maximumReach, radius);
      }
    }
    if (radialBuckets.length < 4 || maximumReach < .25 * scale) return null;
    var angle = vectorX == 0 && vectorY == 0
        ? bestBin + .5
        : normalizeAngleDegrees(math.atan2(vectorY, vectorX) * 180 / math.pi);
    final zeroDistance = math.min(
      normalizeAngleDegrees(angle - config.zeroAngleDegrees),
      normalizeAngleDegrees(config.zeroAngleDegrees - angle),
    );
    if (zeroDistance <= 2) {
      angle = normalizeAngleDegrees(config.zeroAngleDegrees);
    }
    return NeedleDetection(
      angleDegrees: angle,
      liters: angleToLiters(angle, config),
      confidence: confidence,
      candidatePixelCount: points.length,
    );
  }
}
