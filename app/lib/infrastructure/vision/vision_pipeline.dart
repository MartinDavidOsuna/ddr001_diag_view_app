import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../../domain/models.dart';
import 'needle_detector.dart';
import 'odometer_parser.dart';
import 'odometer_reader.dart';
import 'vision_models.dart';

abstract interface class VisualReadingPipeline {
  /// Produces only technician-selected crops. No OCR or needle analysis.
  Future<VisualReadingProposal> extractRegions({
    required String evidenceId,
    required String evidencePath,
    required DialVisionConfiguration configuration,
  });
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

  @override
  Future<VisualReadingProposal> extractRegions({
    required String evidenceId,
    required String evidencePath,
    required DialVisionConfiguration configuration,
  }) async {
    final decoded = img.decodeImage(await File(evidencePath).readAsBytes());
    if (decoded == null) throw StateError('No se pudo abrir la evidencia.');
    final face = img.bakeOrientation(decoded);
    final totalizer = _crop(face, configuration.totalizerRegion.geometry);
    final dial = _cropCircle(face, configuration.selectedDial);
    return VisualReadingProposal(
      evidenceId: evidenceId,
      evidencePath: evidencePath,
      odometerRaw: '',
      odometerValue: null,
      needleLiters: null,
      needleAngle: null,
      warnings: const [],
      createdAt: DateTime.now().toUtc(),
      configuration: configuration,
      totalizerCrop: img.encodeJpg(totalizer, quality: 92),
      dialCrop: img.encodeJpg(dial, quality: 92),
      analysisCompleted: true,
    );
  }

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
    final face = img.bakeOrientation(decoded);
    final numericRegions = <RecognizedTextRegion>[];
    try {
      for (final region in await odometer.recognizeRegions(evidencePath)) {
        if (parser.parse(region.text).isNotEmpty) numericRegions.add(region);
      }
    } catch (_) {
      // Suggestions are optional; manual positioning remains available.
    }
    final dialCandidates = _suggestRedDialCandidates(face);
    var suggested = configuration ?? defaultConfiguration;
    if (configuration == null && numericRegions.length == 1) {
      final region = numericRegions.single;
      final left = region.left.clamp(0.0, .99);
      final top = region.top.clamp(0.0, .99);
      final width = region.width.clamp(.01, 1 - left);
      final height = region.height.clamp(.01, 1 - top);
      suggested = DialVisionConfiguration(
        totalizerRegion: TotalizerRegion(
          NormalizedRect(left, top, width, height),
        ),
        selectedDial: dialCandidates.length == 1
            ? dialCandidates.single.geometry
            : defaultConfiguration.selectedDial,
      );
    } else if (configuration == null && dialCandidates.length == 1) {
      suggested = DialVisionConfiguration(
        totalizerRegion: defaultConfiguration.totalizerRegion,
        selectedDial: dialCandidates.single.geometry,
      );
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
      configuration: suggested,
      dialCandidates: dialCandidates,
      analysisCompleted: false,
    );
  }

  List<DialCandidate> _suggestRedDialCandidates(img.Image image) {
    const columns = 6;
    const rows = 8;
    final counts = List<int>.filled(columns * rows, 0);
    final sumX = List<double>.filled(columns * rows, 0);
    final sumY = List<double>.filled(columns * rows, 0);
    final stride = math.max(2, image.width ~/ 500);
    for (var y = 0; y < image.height; y += stride) {
      for (var x = 0; x < image.width; x += stride) {
        final pixel = image.getPixel(x, y);
        final red = pixel.r.toDouble();
        final green = pixel.g.toDouble();
        final blue = pixel.b.toDouble();
        if (red < 110 || red < green * 1.45 || red < blue * 1.45) continue;
        final column = (x * columns ~/ image.width).clamp(0, columns - 1);
        final row = (y * rows ~/ image.height).clamp(0, rows - 1);
        final index = row * columns + column;
        counts[index]++;
        sumX[index] += x;
        sumY[index] += y;
      }
    }
    final ranked = List<int>.generate(counts.length, (index) => index)
      ..sort((left, right) => counts[right].compareTo(counts[left]));
    final candidates = <DialCandidate>[];
    for (final index in ranked) {
      if (counts[index] < 12 || candidates.length >= 4) break;
      final centerX = sumX[index] / counts[index] / image.width;
      final centerY = sumY[index] / counts[index] / image.height;
      final maximumRadius = math.min(
        .14,
        math.min(
          math.min(centerX, 1 - centerX),
          math.min(centerY, 1 - centerY) * image.height / image.width,
        ),
      );
      if (maximumRadius < .05 ||
          !_hasCircularDialPattern(image, centerX, centerY, maximumRadius) ||
          candidates.any(
            (candidate) =>
                math.sqrt(
                  math.pow(candidate.geometry.centerX - centerX, 2) +
                      math.pow(candidate.geometry.centerY - centerY, 2),
                ) <
                .16,
          )) {
        continue;
      }
      candidates.add(
        DialCandidate(
          id: 'red-dial-${candidates.length + 1}',
          geometry: NormalizedCircle(centerX, centerY, maximumRadius),
          confidence: (counts[index] / 100).clamp(.1, .95),
        ),
      );
    }
    return candidates;
  }

  bool _hasCircularDialPattern(
    img.Image image,
    double centerX,
    double centerY,
    double radius,
  ) {
    var darkSamples = 0;
    const sampleCount = 72;
    for (var index = 0; index < sampleCount; index++) {
      final angle = index * 2 * math.pi / sampleCount;
      final x = ((centerX + math.cos(angle) * radius) * image.width)
          .round()
          .clamp(0, image.width - 1);
      final y =
          ((centerY + math.sin(angle) * radius * image.width / image.height) *
                  image.height)
              .round()
              .clamp(0, image.height - 1);
      final pixel = image.getPixel(x, y);
      final luminance =
          pixel.r.toDouble() * .299 +
          pixel.g.toDouble() * .587 +
          pixel.b.toDouble() * .114;
      if (luminance < 150) darkSamples++;
    }
    // Numerals/ticks around a circular dial create repeated dark samples.
    return darkSamples >= 8;
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
    if (kDebugMode) {
      final debugDirectory = Directory.systemTemp;
      await File(
        p.join(debugDirectory.path, 'ddr001-latest-totalizer.jpg'),
      ).writeAsBytes(displayTotalizer, flush: true);
      await File(
        p.join(debugDirectory.path, 'ddr001-latest-dial.jpg'),
      ).writeAsBytes(displayDial, flush: true);
    }

    // Derived-only OCR image: preserve color separation between the black
    // integer drums and the red fractional drum. The previous grayscale and
    // contrast pass measured 0 exact reads on the controlled simulator corpus.
    final mechanicalStrip = _trimMechanicalDrumStrip(totalizer);
    var scaledTotalizer = mechanicalStrip;
    if (scaledTotalizer.width < 1200) {
      scaledTotalizer = img.copyResize(
        scaledTotalizer,
        width: 1200,
        interpolation: img.Interpolation.cubic,
      );
    }
    final processed = img.copyExpandCanvas(
      scaledTotalizer,
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
    var effectiveTotalizerConfiguration = config.totalizerConfiguration;
    if (effectiveTotalizerConfiguration case final totalizerFormat?) {
      if (totalizerFormat.decimalPlaces == 0 &&
          _hasTrailingRedDrum(mechanicalStrip, totalizerFormat.digitCount)) {
        effectiveTotalizerConfiguration = TotalizerConfiguration(
          digitCount: totalizerFormat.digitCount,
          decimalPlaces: 1,
          unit: totalizerFormat.unit,
          leadingZerosAllowed: totalizerFormat.leadingZerosAllowed,
          source: totalizerFormat.source,
        );
      }
      final segmented = await _recognizeDrums(
        scaledTotalizer,
        totalizerFormat.digitCount,
        evidenceId,
      );
      drumTransitionDetected = segmented.transitionDetected;
      rawResults.add(segmented.raw);
      parsedByVariant.add(parser.parse(segmented.raw));
    }
    final raw = rawResults.where((value) => value.trim().isNotEmpty).join('\n');
    if (kDebugMode) {
      debugPrint(
        'DDR001 vision totalizer=${totalizer.width}x${totalizer.height} '
        'strip=${mechanicalStrip.width}x${mechanicalStrip.height} '
        'raw=${raw.replaceAll('\n', ' | ')}',
      );
    }
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
      effectiveTotalizerConfiguration,
    );
    NeedleDetection? detectedNeedle;
    try {
      detectedNeedle = await needle.detect(dial, config);
    } catch (_) {
      detectedNeedle = null;
    }
    if (kDebugMode) {
      debugPrint(
        'DDR001 vision dial=${dial.width}x${dial.height} '
        'angle=${detectedNeedle?.angleDegrees} '
        'liters=${detectedNeedle?.liters} '
        'confidence=${detectedNeedle?.confidence}',
      );
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
          .where(
            (candidate) => candidate.digits.length >= configuration.digitCount,
          )
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
      final inspectTransitionSlices =
          result == null ||
          (digitCount >= 5 && index == digitCount - 1 && !(result.transition));
      if (inspectTransitionSlices) {
        final sliceHeight = math.max(1, (drum.height * 0.62).round());
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
          result ??= upperResult ?? lowerResult;
        }
      }
      if (result == null) return (raw: '', transitionDetected: false);
      if (kDebugMode) {
        debugPrint(
          'DDR001 drum index=$index digit=${result.digit} '
          'transition=${result.transition}',
        );
      }
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
        if (kDebugMode) {
          debugPrint(
            'DDR001 drum key=$key variant=$index raw=${raw.replaceAll('\n', ' | ')}',
          );
        }
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

  img.Image _trimMechanicalDrumStrip(img.Image source) {
    // Locate the dense, continuous horizontal ink band first. Technician
    // regions intentionally include a small safety margin, and feeding that
    // entire tall crop to single-character OCR makes mechanical digits look
    // like isolated punctuation or letters.
    final minimumRowPixels = math.max(3, (source.width * .12).round());
    var bestTop = 0;
    var bestBottom = source.height;
    var runTop = -1;
    var bestRun = 0;
    for (var y = 0; y < source.height; y++) {
      var foreground = 0;
      for (var x = 0; x < source.width; x++) {
        final pixel = source.getPixel(x, y);
        final red = pixel.r.toDouble();
        final green = pixel.g.toDouble();
        final blue = pixel.b.toDouble();
        final luminance = red * .299 + green * .587 + blue * .114;
        if (luminance < 120 || red - math.max(green, blue) > 28) {
          foreground++;
        }
      }
      if (foreground >= minimumRowPixels) {
        runTop = runTop < 0 ? y : runTop;
      } else if (runTop >= 0) {
        final run = y - runTop;
        if (run > bestRun) {
          bestRun = run;
          bestTop = runTop;
          bestBottom = y;
        }
        runTop = -1;
      }
    }
    if (runTop >= 0 && source.height - runTop > bestRun) {
      bestTop = runTop;
      bestBottom = source.height;
      bestRun = bestBottom - bestTop;
    }
    final verticalMargin = math.max(2, (source.height * .025).round());
    final band = bestRun >= source.height * .25
        ? img.copyCrop(
            source,
            x: 0,
            y: math.max(0, bestTop - verticalMargin),
            width: source.width,
            height:
                math.min(source.height, bestBottom + verticalMargin) -
                math.max(0, bestTop - verticalMargin),
          )
        : source;
    final minimumColumnPixels = math.max(2, (band.height * .08).round());
    var first = source.width;
    var last = -1;
    final top = (band.height * .04).round();
    final bottom = math.max(top + 1, (band.height * .96).round());
    for (var x = 0; x < band.width; x++) {
      var foreground = 0;
      for (var y = top; y < bottom; y++) {
        final pixel = band.getPixel(x, y);
        final red = pixel.r.toDouble();
        final green = pixel.g.toDouble();
        final blue = pixel.b.toDouble();
        final luminance = red * .299 + green * .587 + blue * .114;
        if (luminance < 120 || red - math.max(green, blue) > 28) {
          foreground++;
        }
      }
      if (foreground >= minimumColumnPixels) {
        first = math.min(first, x);
        last = math.max(last, x);
      }
    }
    if (last <= first || last - first < band.width * .45) return band;
    final margin = math.max(2, (band.width * .015).round());
    final left = math.max(0, first - margin);
    final right = math.min(band.width, last + margin + 1);
    return img.copyCrop(
      band,
      x: left,
      y: 0,
      width: right - left,
      height: band.height,
    );
  }

  bool _hasTrailingRedDrum(img.Image strip, int digitCount) {
    if (digitCount < 2 || strip.width < digitCount) return false;
    final left = ((digitCount - 1) * strip.width / digitCount).round();
    final previousLeft = ((digitCount - 2) * strip.width / digitCount).round();
    final trailingDensity = _redDensity(strip, left, strip.width);
    final previousDensity = _redDensity(strip, previousLeft, left);
    return trailingDensity >= .015 &&
        trailingDensity >= previousDensity * 2.2 + .008;
  }

  double _redDensity(img.Image strip, int left, int right) {
    var redPixels = 0;
    var sampled = 0;
    for (var y = 0; y < strip.height; y += 2) {
      for (var x = left; x < right; x += 2) {
        final pixel = strip.getPixel(x, y);
        sampled++;
        if (pixel.r > 90 &&
            pixel.r > pixel.g * 1.25 &&
            pixel.r > pixel.b * 1.25) {
          redPixels++;
        }
      }
    }
    return sampled == 0 ? 0 : redPixels / sampled;
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
