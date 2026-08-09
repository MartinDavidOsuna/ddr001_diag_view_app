import 'dart:math' as math;

import '../decision/numeric_tolerance.dart';
import '../models/sample_result.dart';

enum RepeatabilityStatus { notEvaluable, pass, fail }

final class SampleStatistics {
  const SampleStatistics({
    required this.n,
    required this.meanErrorPct,
    required this.minimumErrorPct,
    required this.maximumErrorPct,
    required this.dispersionPct,
    required this.sampleStandardDeviationPct,
    required this.repeatabilityStatus,
  });

  final int n;
  final double meanErrorPct;
  final double minimumErrorPct;
  final double maximumErrorPct;
  final double dispersionPct;
  final double? sampleStandardDeviationPct;
  final RepeatabilityStatus repeatabilityStatus;
}

SampleStatistics calculateSampleStatistics(
  List<SampleResult> results, {
  required double mpePct,
  NumericTolerance tolerance = const NumericTolerance(),
}) {
  if (results.isEmpty) {
    throw ArgumentError.value(results, 'results', 'Must not be empty.');
  }
  if (!mpePct.isFinite || mpePct <= 0) {
    throw ArgumentError.value(mpePct, 'mpePct');
  }
  final errors = results.map((result) => result.errorPct).toList();
  final mean = errors.reduce((a, b) => a + b) / errors.length;
  final minimum = errors.reduce(math.min);
  final maximum = errors.reduce(math.max);
  final standardDeviation = errors.length < 2
      ? null
      : math.sqrt(
          errors
                  .map((error) => math.pow(error - mean, 2).toDouble())
                  .reduce((a, b) => a + b) /
              (errors.length - 1),
        );
  final repeatability = errors.length < 3
      ? RepeatabilityStatus.notEvaluable
      : tolerance.lessThanOrEqual(standardDeviation!, mpePct / 3)
      ? RepeatabilityStatus.pass
      : RepeatabilityStatus.fail;
  return SampleStatistics(
    n: errors.length,
    meanErrorPct: mean,
    minimumErrorPct: minimum,
    maximumErrorPct: maximum,
    dispersionPct: maximum - minimum,
    sampleStandardDeviationPct: standardDeviation,
    repeatabilityStatus: repeatability,
  );
}
