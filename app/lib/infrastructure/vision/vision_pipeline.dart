import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'needle_detector.dart';
import 'dial_candidate_detector.dart';
import 'odometer_parser.dart';
import 'odometer_reader.dart';
import 'vision_models.dart';

abstract interface class VisualReadingPipeline {
  Future<VisualReadingProposal> analyze({
    required String evidenceId,
    required String evidencePath,
    DialVisionConfiguration? configuration,
  });
  Future<void> dispose();
}

final class OnDeviceVisualReadingPipeline implements VisualReadingPipeline {
  OnDeviceVisualReadingPipeline({
    required this.odometer,
    required this.needle,
    this.defaultConfiguration = const DialVisionConfiguration(),
    this.parser = const OdometerParser(),
  });
  final OdometerRecognitionPort odometer;
  final NeedleDetectionPort needle;
  final DialVisionConfiguration defaultConfiguration;
  final OdometerParser parser;

  @override
  Future<VisualReadingProposal> analyze({
    required String evidenceId,
    required String evidencePath,
    DialVisionConfiguration? configuration,
  }) async {
    final config = configuration ?? defaultConfiguration;
    final decoded = img.decodeImage(await File(evidencePath).readAsBytes());
    if (decoded == null || decoded.width < 640 || decoded.height < 480) {
      throw StateError('Imagen insuficiente. Repita la fotografía.');
    }
    final face = img.bakeOrientation(decoded);
    final totalizer = _crop(face, config.totalizerRegion.geometry);
    final dial = _cropCircle(face, config.selectedDial);
    final displayTotalizer = img.encodeJpg(totalizer, quality: 92);
    final displayDial = img.encodeJpg(dial, quality: 92);

    // Derived-only OCR image: preserve color separation between the black
    // integer drums and the red fractional drum. The previous grayscale and
    // contrast pass measured 0 exact reads on the controlled simulator corpus.
    var processed = totalizer;
    if (processed.width < 1200) {
      processed = img.copyResize(
        processed,
        width: 1200,
        interpolation: img.Interpolation.cubic,
      );
    }
    final cropPath = p.join(
      Directory.systemTemp.path,
      'ddr001-ocr-$evidenceId.jpg',
    );
    await File(cropPath).writeAsBytes(img.encodeJpg(processed, quality: 95));
    String raw = '';
    try {
      raw = await odometer.recognize(cropPath);
    } catch (_) {
      raw = '';
    } finally {
      final file = File(cropPath);
      if (await file.exists()) await file.delete();
    }
    final candidates = parser.parse(raw);
    final selectedOdometer = parser.select(candidates);
    final configuredTotalizer =
        config.totalizerConfiguration != null && candidates.length == 1
        ? parser.applyConfiguration(
            candidates.single,
            config.totalizerConfiguration!,
          )
        : null;
    NeedleDetection? detectedNeedle;
    try {
      detectedNeedle = await needle.detect(dial, config);
    } catch (_) {
      detectedNeedle = null;
    }
    final detectedCandidates = const DialCandidateDetector().detect(face);
    final dialCandidates = <DialCandidate>[
      DialCandidate(
        id: 'configured',
        geometry: config.selectedDial,
        confidence: 1,
        multiplier: config.multiplier,
        litersPerRevolution: config.litersPerRevolution,
        selected: true,
      ),
      ...detectedCandidates,
    ];
    return VisualReadingProposal(
      evidenceId: evidenceId,
      evidencePath: evidencePath,
      odometerRaw: raw,
      odometerValue: configuredTotalizer?.value ?? selectedOdometer?.value,
      odometerConfidence: null,
      needleLiters: detectedNeedle?.liters,
      needleAngle: detectedNeedle?.angleDegrees,
      needleConfidence: detectedNeedle?.confidence,
      needleCandidatePixelCount: detectedNeedle?.candidatePixelCount,
      odometerCandidates: candidates,
      totalizerReadingProposal: configuredTotalizer,
      configuration: config,
      dialCandidates: dialCandidates,
      totalizerCrop: displayTotalizer,
      dialCrop: displayDial,
      createdAt: DateTime.now().toUtc(),
      warnings: [
        if (candidates.isEmpty)
          'No se pudo leer automáticamente el totalizador.',
        if (candidates.length > 1)
          'Se detectaron varios candidatos de totalizador.',
        if (candidates.any((candidate) => candidate.ambiguous))
          'El OCR contiene caracteres ambiguos.',
        if (configuredTotalizer?.requiresConfirmation ?? false)
          'El formato requiere confirmación del técnico.',
        if (detectedNeedle == null) 'Aguja no detectada',
        if (detectedCandidates.length > 1 &&
            selectHighestMetrologicalResolution(detectedCandidates) == null)
          'Se detectaron varios diales. Confirme el dial de mayor resolución.',
      ],
    );
  }

  img.Image _crop(img.Image source, NormalizedRect region) {
    final px = region.pixels(source.width, source.height);
    return img.copyCrop(
      source,
      x: px.x,
      y: px.y,
      width: px.width,
      height: px.height,
    );
  }

  img.Image _cropCircle(img.Image source, NormalizedCircle circle) {
    final px = circle.squarePixels(source.width, source.height);
    return img.copyCrop(
      source,
      x: px.x,
      y: px.y,
      width: px.width,
      height: px.height,
    );
  }

  @override
  Future<void> dispose() => odometer.dispose();
}
