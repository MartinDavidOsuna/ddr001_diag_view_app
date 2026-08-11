import 'dart:math' as math;

import '../../domain/models.dart';
import 'vision_models.dart';

final class OdometerParser {
  const OdometerParser();

  List<OdometerCandidate> parse(String text) {
    final candidates = <OdometerCandidate>[];
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    final numericLines = lines.every(
      (line) => RegExp(r'^[0-9OoIl.,\s]+$').hasMatch(line),
    );
    final hasShortFragment = lines.any(
      (line) => line.replaceAll(RegExp(r'\s'), '').length < 3,
    );
    final segments = <String>[
      ...lines,
      if (lines.length > 1 && numericLines && hasShortFragment)
        lines.join().replaceAll(RegExp(r'\s'), ''),
    ];
    for (final rawLine in segments) {
      final compact = rawLine.replaceAll(RegExp(r'\s'), '');
      if (compact.isEmpty) continue;
      final ambiguous = RegExp(r'[OoIl]').hasMatch(compact);
      final normalized = compact
          .replaceAll(RegExp('[Oo]'), '0')
          .replaceAll(RegExp('[Il]'), '1');
      for (final match in RegExp(r'\d+(?:[.,]\d+)?').allMatches(normalized)) {
        final token = match.group(0)!;
        final digits = token.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length < 3) continue;
        final separator = token.indexOf(RegExp(r'[.,]'));
        final explicitDecimals = separator < 0
            ? null
            : token.length - separator - 1;
        final value = double.tryParse(token.replaceAll(',', '.'));
        if (value != null) {
          final candidate = OdometerCandidate(
            raw: rawLine,
            digits: digits,
            value: value,
            ambiguous: ambiguous,
            explicitDecimalPlaces: explicitDecimals,
          );
          if (!candidates.any(
            (existing) =>
                existing.digits == candidate.digits &&
                existing.explicitDecimalPlaces ==
                    candidate.explicitDecimalPlaces,
          )) {
            candidates.add(candidate);
          }
        }
      }
    }
    return candidates;
  }

  OdometerCandidate? select(List<OdometerCandidate> candidates) {
    if (candidates.length != 1 || candidates.single.ambiguous) return null;
    return candidates.single;
  }

  TotalizerReadingProposal? applyConfiguration(
    OdometerCandidate candidate,
    TotalizerConfiguration configuration,
  ) {
    var digits = candidate.digits;
    var trimmedLeadingZeros = false;
    if (digits.length > configuration.digitCount) {
      final extraDigits = digits.substring(
        0,
        digits.length - configuration.digitCount,
      );
      if (!configuration.leadingZerosAllowed ||
          !RegExp(r'^0+$').hasMatch(extraDigits)) {
        return null;
      }
      digits = digits.substring(digits.length - configuration.digitCount);
      trimmedLeadingZeros = true;
    }
    final length = digits.length;
    if (length < configuration.digitCount &&
        !configuration.leadingZerosAllowed) {
      return null;
    }
    final numericDigits = int.tryParse(digits);
    if (numericDigits == null) return null;
    final value = numericDigits / math.pow(10, configuration.decimalPlaces);
    return TotalizerReadingProposal(
      candidate: candidate,
      configuration: configuration,
      value: value,
      requiresConfirmation:
          candidate.ambiguous ||
          trimmedLeadingZeros ||
          length < configuration.digitCount ||
          (candidate.explicitDecimalPlaces != null &&
              candidate.explicitDecimalPlaces != configuration.decimalPlaces),
    );
  }
}
