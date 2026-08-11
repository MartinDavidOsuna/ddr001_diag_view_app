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
        final dominance = red - math.max(green, blue);
        if (red < 90 || dominance < 35 || red < green * 1.35) continue;
        points.add((x: x.toDouble(), y: y.toDouble(), weight: dominance));
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
      bins[angle.floor() % bins.length] +=
          point.weight * (radius / maxNeedleRadius);
    }
    var bestBin = 0;
    for (var index = 1; index < bins.length; index++) {
      if (bins[index] > bins[bestBin]) bestBin = index;
    }
    final neighborhood =
        bins[(bestBin - 1) % bins.length] +
        bins[bestBin] +
        bins[(bestBin + 1) % bins.length];
    final total = bins.fold<double>(0, (sum, value) => sum + value);
    final confidence = total == 0
        ? 0.0
        : (neighborhood / total).clamp(0, 1).toDouble();
    if (confidence < .18) return null;
    var angle = bestBin + .5;
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
