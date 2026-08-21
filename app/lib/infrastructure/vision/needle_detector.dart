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

    // The technician-selected ROI center is the physical pivot authority.
    // Do not replace it with the red centroid: broad triangular pointers shift
    // that centroid toward their tip and introduce a systematic angle bias.
    // Red near the center is still required to reject disconnected artifacts.
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
      return math.sqrt(dx * dx + dy * dy) >= .12 * scale;
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
        radialBuckets.add((radius / (.035 * scale)).floor());
        maximumReach = math.max(maximumReach, radius);
      }
    }
    if (radialBuckets.length < 3 || maximumReach < .14 * scale) return null;
    var angle = vectorX == 0 && vectorY == 0
        ? bestBin + .5
        : normalizeAngleDegrees(math.atan2(vectorY, vectorX) * 180 / math.pi);
    // Broad mechanical pointers commonly contain a rounded red counterweight
    // and a narrow triangular tip. Radial mass then points backwards. Detect
    // that asymmetric silhouette with its principal axis and choose the end
    // having the smaller cap (the pointed end).
    final pointWeight = points.fold<double>(0, (sum, p) => sum + p.weight);
    final redCenterX =
        points.fold<double>(0, (sum, p) => sum + p.x * p.weight) / pointWeight;
    final redCenterY =
        points.fold<double>(0, (sum, p) => sum + p.y * p.weight) / pointWeight;
    var covarianceX = 0.0;
    var covarianceY = 0.0;
    var covarianceXY = 0.0;
    for (final point in points) {
      final dx = point.x - redCenterX;
      final dy = point.y - redCenterY;
      covarianceX += point.weight * dx * dx;
      covarianceY += point.weight * dy * dy;
      covarianceXY += point.weight * dx * dy;
    }
    final principalRadians =
        .5 * math.atan2(2 * covarianceXY, covarianceX - covarianceY);
    final axisX = math.cos(principalRadians);
    final axisY = math.sin(principalRadians);
    final projections = points
        .map(
          (point) =>
              (point.x - redCenterX) * axisX + (point.y - redCenterY) * axisY,
        )
        .toList(growable: false);
    final minimumProjection = projections.reduce(math.min);
    final maximumProjection = projections.reduce(math.max);
    final projectionSpan = maximumProjection - minimumProjection;
    if (projectionSpan >= .25 * scale) {
      final capWidth = projectionSpan * .15;
      final negativeCap = projections
          .where((value) => value <= minimumProjection + capWidth)
          .length;
      final positiveCap = projections
          .where((value) => value >= maximumProjection - capWidth)
          .length;
      final smallerCap = math.min(negativeCap, positiveCap);
      final largerCap = math.max(negativeCap, positiveCap);
      if (smallerCap > 0 && smallerCap * 1.8 < largerCap) {
        final pointedAxis = positiveCap < negativeCap
            ? principalRadians
            : principalRadians + math.pi;
        angle = normalizeAngleDegrees(pointedAxis * 180 / math.pi);
      }
    }
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
