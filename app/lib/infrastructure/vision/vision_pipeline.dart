import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../../domain/models.dart';
import 'needle_detector.dart';
import 'odometer_parser.dart';
import 'odometer_reader.dart';
import 'vision_models.dart';

abstract interface class VisualReadingPipeline {
  Future<VisualReadingProposal> prepare({
    required String evidenceId,
    required String evidencePath,
    DialVisionConfiguration? configuration,
  });
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
  Future<VisualReadingProposal> prepare({
    required String evidenceId,
    required String evidencePath,
    DialVisionConfiguration? configuration,
  }) async {
    final decoded = img.decodeImage(await File(evidencePath).readAsBytes());
    if (decoded == null || decoded.width < 640 || decoded.height < 480) {
      throw StateError('Imagen insuficiente. Repita la fotografía.');
    }
    return VisualReadingProposal(
      evidenceId: evidenceId,
      evidencePath: evidencePath,
      odometerRaw: '',
      odometerValue: null,
      needleLiters: null,
      needleAngle: null,
      warnings: const [],
      createdAt: DateTime.now().toUtc(),
      configuration: configuration ?? defaultConfiguration,
      analysisCompleted: false,
    );
  }

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
    processed = img.copyExpandCanvas(
      processed,
      padding: 32,
      backgroundColor: img.ColorRgb8(255, 255, 255),
    );
    final variants = <img.Image>[
      processed,
      img.adjustColor(img.grayscale(img.Image.from(processed)), contrast: 1.45),
      img.luminanceThreshold(
        img.grayscale(img.Image.from(processed)),
        threshold: .52,
      ),
    ];
    final rawResults = <String>[];
    final parsedByVariant = <List<OdometerCandidate>>[];
    for (var index = 0; index < variants.length; index++) {
      final cropPath = p.join(
        Directory.systemTemp.path,
        'ddr001-ocr-$evidenceId-$index.jpg',
      );
      await File(cropPath).writeAsBytes(img.encodePng(variants[index]));
      try {
        final recognized = await odometer.recognize(cropPath);
        rawResults.add(recognized);
        parsedByVariant.add(parser.parse(recognized));
      } catch (_) {
        rawResults.add('');
        parsedByVariant.add(const []);
      } finally {
        final file = File(cropPath);
        if (await file.exists()) await file.delete();
      }
    }
    var drumTransitionDetected = false;
    if (config.totalizerConfiguration case final totalizerFormat?) {
      final segmented = await _recognizeDrums(
        processed,
        totalizerFormat.digitCount,
        evidenceId,
      );
      drumTransitionDetected = segmented.transitionDetected;
      rawResults.add(segmented.raw);
      parsedByVariant.add(parser.parse(segmented.raw));
    }
    final raw = rawResults.where((value) => value.trim().isNotEmpty).join('\n');
    final candidates = <OdometerCandidate>[];
    for (final candidate in parsedByVariant.expand((items) => items)) {
      if (!candidates.any(
        (existing) =>
            existing.digits == candidate.digits &&
            existing.explicitDecimalPlaces == candidate.explicitDecimalPlaces,
      )) {
        candidates.add(candidate);
      }
    }
    final selectedOdometer = parser.select(candidates);
    final configuredTotalizer = _selectConfiguredTotalizer(
      parsedByVariant,
      config.totalizerConfiguration,
    );
    NeedleDetection? detectedNeedle;
    try {
      detectedNeedle = await needle.detect(dial, config);
    } catch (_) {
      detectedNeedle = null;
    }
    final dialCandidates = <DialCandidate>[
      DialCandidate(
        id: 'configured',
        geometry: config.selectedDial,
        confidence: 1,
        multiplier: config.multiplier,
        litersPerRevolution: config.litersPerRevolution,
        selected: true,
      ),
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
        if (drumTransitionDetected)
          'Tambor en transición detectado; confirme el dígito anterior.',
        if (detectedNeedle == null) 'Aguja no detectada',
      ],
      analysisCompleted: true,
    );
  }

  TotalizerReadingProposal? _selectConfiguredTotalizer(
    List<List<OdometerCandidate>> byVariant,
    TotalizerConfiguration? configuration,
  ) {
    if (configuration == null) return null;
    final votes = <String, int>{};
    final proposals = <String, TotalizerReadingProposal>{};
    for (final variant in byVariant) {
      final valid = variant
          .map(
            (candidate) => parser.applyConfiguration(candidate, configuration),
          )
          .whereType<TotalizerReadingProposal>()
          .toList();
      if (valid.length != 1) continue;
      final proposal = valid.single;
      final key = proposal.candidate.digits;
      votes[key] = (votes[key] ?? 0) + 1;
      proposals[key] = proposal;
    }
    if (votes.isEmpty) return null;
    final ranked = votes.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    if (ranked.length > 1 && ranked[0].value == ranked[1].value) return null;
    return proposals[ranked.first.key];
  }

  Future<({String raw, bool transitionDetected})> _recognizeDrums(
    img.Image totalizer,
    int digitCount,
    String evidenceId,
  ) async {
    if (digitCount <= 0 || totalizer.width < digitCount * 8) {
      return (raw: '', transitionDetected: false);
    }
    final digits = StringBuffer();
    var transitionDetected = false;
    for (var index = 0; index < digitCount; index++) {
      final left = (index * totalizer.width / digitCount).round();
      final right = ((index + 1) * totalizer.width / digitCount).round();
      final drum = img.copyCrop(
        totalizer,
        x: left,
        y: 0,
        width: math.max(1, right - left),
        height: totalizer.height,
      );
      var result = _parseDrumDigits(
        await _recognizeDrumImage(drum, '$evidenceId-$index-full'),
      );
      if (result == null) {
        final sliceHeight = math.max(1, (drum.height * 0.65).round());
        final upper = img.copyCrop(
          drum,
          x: 0,
          y: 0,
          width: drum.width,
          height: sliceHeight,
        );
        final lower = img.copyCrop(
          drum,
          x: 0,
          y: math.max(0, drum.height - sliceHeight),
          width: drum.width,
          height: sliceHeight,
        );
        final upperResult = _parseDrumDigits(
          await _recognizeDrumImage(upper, '$evidenceId-$index-upper'),
        );
        final lowerResult = _parseDrumDigits(
          await _recognizeDrumImage(lower, '$evidenceId-$index-lower'),
        );
        if (upperResult != null &&
            lowerResult != null &&
            _isNextDrumDigit(upperResult.digit, lowerResult.digit)) {
          result = (digit: upperResult.digit, transition: true);
        } else {
          result = upperResult ?? lowerResult;
        }
      }
      if (result == null) return (raw: '', transitionDetected: false);
      digits.write(result.digit);
      transitionDetected = transitionDetected || result.transition;
    }
    return (raw: digits.toString(), transitionDetected: transitionDetected);
  }

  Future<String> _recognizeDrumImage(img.Image drum, String key) async {
    final prepared = img.copyResize(
      drum,
      width: 260,
      interpolation: img.Interpolation.cubic,
    );
    final gray = img.grayscale(img.Image.from(prepared));
    final variants = <img.Image>[
      prepared,
      img.adjustColor(img.Image.from(gray), contrast: 1.55, gamma: .85),
      img.luminanceThreshold(img.Image.from(gray), threshold: .46),
      img.luminanceThreshold(img.Image.from(gray), threshold: .58),
    ];
    final recognized = <String>[];
    for (var index = 0; index < variants.length; index++) {
      final padded = img.copyExpandCanvas(
        variants[index],
        padding: 45,
        backgroundColor: img.ColorRgb8(255, 255, 255),
      );
      final path = p.join(
        Directory.systemTemp.path,
        'ddr001-drum-$key-$index.png',
      );
      await File(path).writeAsBytes(img.encodePng(padded));
      try {
        final raw = await odometer.recognize(path);
        recognized.add(raw);
        final digits = raw
            .replaceAll(RegExp('[Oo]'), '0')
            .replaceAll(RegExp('[Il|]'), '1')
            .replaceAll(RegExp(r'\D'), '');
        if (digits.length == 1) return digits;
        for (var digitIndex = 0; digitIndex + 1 < digits.length; digitIndex++) {
          if (_isNextDrumDigit(digits[digitIndex], digits[digitIndex + 1])) {
            return '${digits[digitIndex]}${digits[digitIndex + 1]}';
          }
        }
      } catch (_) {
        recognized.add('');
      } finally {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    }
    final normalized = recognized
        .map(
          (value) => value
              .replaceAll(RegExp('[Oo]'), '0')
              .replaceAll(RegExp('[Il|]'), '1')
              .replaceAll(RegExp(r'\D'), ''),
        )
        .where((value) => value.isNotEmpty)
        .toList();
    final singleVotes = <String, int>{};
    for (final value in normalized.where((value) => value.length == 1)) {
      singleVotes[value] = (singleVotes[value] ?? 0) + 1;
    }
    if (singleVotes.isNotEmpty) {
      final ranked = singleVotes.entries.toList()
        ..sort((left, right) => right.value.compareTo(left.value));
      if (ranked.length == 1 || ranked[0].value > ranked[1].value) {
        return ranked.first.key;
      }
    }
    for (final value in normalized) {
      for (var index = 0; index + 1 < value.length; index++) {
        if (_isNextDrumDigit(value[index], value[index + 1])) {
          return '${value[index]}${value[index + 1]}';
        }
      }
    }
    return normalized.isEmpty ? '' : normalized.first;
  }

  ({String digit, bool transition})? _parseDrumDigits(String raw) {
    final normalized = raw
        .replaceAll(RegExp('[Oo]'), '0')
        .replaceAll(RegExp('[Il|]'), '1')
        .replaceAll(RegExp(r'\D'), '');
    if (normalized.length == 1) {
      return (digit: normalized, transition: false);
    }
    for (var index = 0; index + 1 < normalized.length; index++) {
      final upper = normalized[index];
      final lower = normalized[index + 1];
      if (_isNextDrumDigit(upper, lower)) {
        return (digit: upper, transition: true);
      }
    }
    return null;
  }

  bool _isNextDrumDigit(String upper, String lower) {
    final current = int.tryParse(upper);
    final next = int.tryParse(lower);
    return current != null && next != null && (current + 1) % 10 == next;
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
