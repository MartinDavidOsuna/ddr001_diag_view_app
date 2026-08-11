import 'dart:typed_data';
import 'dart:math' as math;

import '../../core/metrology/metrology.dart';
import '../../domain/models.dart';

final class NormalizedRect {
  const NormalizedRect(this.left, this.top, this.width, this.height)
    : assert(left >= 0 && top >= 0 && width > 0 && height > 0),
      assert(left + width <= 1 && top + height <= 1);
  final double left, top, width, height;
  ({int x, int y, int width, int height}) pixels(
    int imageWidth,
    int imageHeight,
  ) {
    final x = (left * imageWidth).round().clamp(0, imageWidth - 1);
    final y = (top * imageHeight).round().clamp(0, imageHeight - 1);
    return (
      x: x,
      y: y,
      width: (width * imageWidth).round().clamp(1, imageWidth - x),
      height: (height * imageHeight).round().clamp(1, imageHeight - y),
    );
  }
}

final class TotalizerRegion {
  const TotalizerRegion(this.geometry);
  final NormalizedRect geometry;
}

final class NormalizedCircle {
  const NormalizedCircle(this.centerX, this.centerY, this.radius)
    : assert(centerX >= 0 && centerX <= 1),
      assert(centerY >= 0 && centerY <= 1),
      assert(radius > 0 && radius <= .5);
  final double centerX, centerY, radius;
  ({int x, int y, int width, int height}) squarePixels(
    int imageWidth,
    int imageHeight,
  ) {
    final centerPixelX = centerX * imageWidth;
    final centerPixelY = centerY * imageHeight;
    final radiusPixels = radius * imageWidth;
    final left = (centerPixelX - radiusPixels).round().clamp(0, imageWidth - 1);
    final top = (centerPixelY - radiusPixels).round().clamp(0, imageHeight - 1);
    final diameter = (radiusPixels * 2).round();
    final size = math.min(
      diameter,
      math.min(imageWidth - left, imageHeight - top),
    );
    return (x: left, y: top, width: size, height: size);
  }

  NormalizedRect get bounds {
    final left = (centerX - radius).clamp(0.0, 1.0);
    final top = (centerY - radius).clamp(0.0, 1.0);
    return NormalizedRect(
      left,
      top,
      (radius * 2).clamp(.01, 1 - left),
      (radius * 2).clamp(.01, 1 - top),
    );
  }
}

final class DialCandidate {
  const DialCandidate({
    required this.id,
    required this.geometry,
    required this.confidence,
    this.multiplier,
    this.litersPerRevolution,
    this.selected = false,
  });
  final String id;
  final NormalizedCircle geometry;
  final double? multiplier, litersPerRevolution;
  final double confidence;
  final bool selected;
}

DialCandidate? selectHighestMetrologicalResolution(List<DialCandidate> values) {
  final known = values.where((c) => c.litersPerRevolution != null).toList()
    ..sort((a, b) => a.litersPerRevolution!.compareTo(b.litersPerRevolution!));
  if (known.isEmpty ||
      (known.length > 1 &&
          (known[0].litersPerRevolution! - known[1].litersPerRevolution!)
                  .abs() <
              1e-9)) {
    return null;
  }
  return known.first;
}

double? parseDialMultiplier(String text) {
  final value = text.toLowerCase().replaceAll(',', '.').replaceAll('×', 'x');
  final match = RegExp(r'x\s*(1|0\.1|0\.01|0\.001)(?!\d)').firstMatch(value);
  return match == null ? null : double.tryParse(match.group(1)!);
}

final class DialVisionConfiguration {
  const DialVisionConfiguration({
    this.totalizerRegion = const TotalizerRegion(
      NormalizedRect(.275, .125, .34, .045),
    ),
    this.selectedDial = const NormalizedCircle(.453, .332, .14),
    this.zeroAngleDegrees = -90,
    this.clockwise = true,
    this.litersPerRevolution = 100,
    this.multiplier = 1,
    this.source = DialConfigurationSource.manual,
    this.totalizerConfiguration,
  });
  final TotalizerRegion totalizerRegion;
  final NormalizedCircle selectedDial;
  final double zeroAngleDegrees, litersPerRevolution, multiplier;
  final bool clockwise;
  final DialConfigurationSource source;
  final TotalizerConfiguration? totalizerConfiguration;

  MeterFaceConfiguration toDomain() => MeterFaceConfiguration(
    totalizerLeft: totalizerRegion.geometry.left,
    totalizerTop: totalizerRegion.geometry.top,
    totalizerWidth: totalizerRegion.geometry.width,
    totalizerHeight: totalizerRegion.geometry.height,
    dialCenterX: selectedDial.centerX,
    dialCenterY: selectedDial.centerY,
    dialRadius: selectedDial.radius,
    multiplier: multiplier,
    litersPerRevolution: litersPerRevolution,
    zeroAngleDegrees: zeroAngleDegrees,
    clockwise: clockwise,
    source: source,
    totalizerConfiguration: totalizerConfiguration,
  );
  factory DialVisionConfiguration.fromDomain(MeterFaceConfiguration v) =>
      DialVisionConfiguration(
        totalizerRegion: TotalizerRegion(
          NormalizedRect(
            v.totalizerLeft,
            v.totalizerTop,
            v.totalizerWidth,
            v.totalizerHeight,
          ),
        ),
        selectedDial: NormalizedCircle(
          v.dialCenterX,
          v.dialCenterY,
          v.dialRadius,
        ),
        multiplier: v.multiplier,
        litersPerRevolution: v.litersPerRevolution,
        zeroAngleDegrees: v.zeroAngleDegrees,
        clockwise: v.clockwise,
        source: v.source,
        totalizerConfiguration: v.totalizerConfiguration,
      );
}

final class OdometerCandidate {
  const OdometerCandidate({
    required this.raw,
    required this.digits,
    required this.value,
    required this.ambiguous,
    this.explicitDecimalPlaces,
  });
  final String raw, digits;
  final double value;
  final bool ambiguous;
  final int? explicitDecimalPlaces;
}

final class TotalizerReadingProposal {
  const TotalizerReadingProposal({
    required this.candidate,
    required this.configuration,
    required this.value,
    required this.requiresConfirmation,
  });
  final OdometerCandidate candidate;
  final TotalizerConfiguration configuration;
  final double value;
  final bool requiresConfirmation;
}

final class NeedleDetection {
  const NeedleDetection({
    required this.angleDegrees,
    required this.liters,
    required this.confidence,
    this.candidatePixelCount,
  });
  final double angleDegrees, liters, confidence;
  final int? candidatePixelCount;
}

final class VisualReadingProposal {
  const VisualReadingProposal({
    required this.evidenceId,
    required this.evidencePath,
    required this.odometerRaw,
    required this.odometerValue,
    required this.needleLiters,
    required this.needleAngle,
    required this.warnings,
    required this.createdAt,
    this.configuration = const DialVisionConfiguration(),
    this.dialCandidates = const [],
    this.totalizerCrop,
    this.dialCrop,
    this.odometerConfidence,
    this.needleConfidence,
    this.needleCandidatePixelCount,
    this.odometerCandidates = const [],
    this.totalizerReadingProposal,
  });
  final String evidenceId, evidencePath, odometerRaw;
  final double? odometerValue,
      odometerConfidence,
      needleLiters,
      needleAngle,
      needleConfidence;
  final int? needleCandidatePixelCount;
  final List<OdometerCandidate> odometerCandidates;
  final TotalizerReadingProposal? totalizerReadingProposal;
  final List<String> warnings;
  final DateTime createdAt;
  final DialVisionConfiguration configuration;
  final List<DialCandidate> dialCandidates;
  final Uint8List? totalizerCrop, dialCrop;
  ConfirmedReading confirm({
    required double odometerValue,
    required double needleLiters,
    required double litersPerOdometerUnit,
    required double needleLitersPerRevolution,
    required bool corrected,
  }) => ConfirmedReading(
    reading: MeterReading(
      odometerUnits: odometerValue,
      needleLiters: needleLiters,
      litersPerOdometerUnit: litersPerOdometerUnit,
      needleLitersPerRevolution: needleLitersPerRevolution,
    ),
    source: corrected ? ReadingSource.manual : ReadingSource.autoConfirmed,
    evidenceId: evidenceId,
  );
}
