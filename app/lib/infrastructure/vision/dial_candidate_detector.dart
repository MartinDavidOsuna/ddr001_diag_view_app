import 'dart:math' as math;

import 'package:image/image.dart' as img;

import 'vision_models.dart';

/// Lightweight circular-contour proposer. It does not assign metrological scale.
final class DialCandidateDetector {
  const DialCandidateDetector();

  List<DialCandidate> detect(img.Image source) {
    final image = img.copyResize(source, width: 240);
    final ratio = image.height / image.width;
    final scored = <({double score, double x, double y, double radius})>[];
    for (final radius in [.10, .14, .18, .22, .27]) {
      for (var cy = radius; cy <= ratio - radius; cy += .06) {
        for (var cx = radius; cx <= 1 - radius; cx += .06) {
          var edge = 0.0;
          var inside = 0.0;
          const samples = 32;
          for (var i = 0; i < samples; i++) {
            final angle = 2 * math.pi * i / samples;
            edge += _darkness(
              image,
              cx + radius * math.cos(angle),
              (cy + radius * math.sin(angle)) / ratio,
            );
            inside += _darkness(
              image,
              cx + radius * .72 * math.cos(angle),
              (cy + radius * .72 * math.sin(angle)) / ratio,
            );
          }
          final score = (edge - inside) / samples;
          if (score > 12) {
            scored.add((score: score, x: cx, y: cy / ratio, radius: radius));
          }
        }
      }
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    final selected = <({double score, double x, double y, double radius})>[];
    for (final item in scored) {
      if (selected.any(
        (other) =>
            math.sqrt(
              math.pow(item.x - other.x, 2) + math.pow(item.y - other.y, 2),
            ) <
            math.max(item.radius, other.radius),
      )) {
        continue;
      }
      selected.add(item);
      if (selected.length == 6) break;
    }
    return [
      for (final (index, item) in selected.indexed)
        DialCandidate(
          id: 'circle-$index',
          geometry: NormalizedCircle(
            item.x,
            item.y,
            item.radius.clamp(.05, .45),
          ),
          confidence: (item.score / 80).clamp(0, 1),
        ),
    ];
  }

  double _darkness(img.Image image, double nx, double ny) {
    final x = (nx.clamp(0, 1) * (image.width - 1)).round();
    final y = (ny.clamp(0, 1) * (image.height - 1)).round();
    final pixel = image.getPixel(x, y);
    return 255 - (.299 * pixel.r + .587 * pixel.g + .114 * pixel.b);
  }
}
