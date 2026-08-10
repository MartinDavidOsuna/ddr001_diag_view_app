import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:flutter_test/flutter_test.dart';

SampleResult result(double error) => SampleResult(
  referenceLiters: 100,
  indicatedLiters: 100 + error,
  errorPct: error,
  uncertaintyPct: 0,
  mpePct: 2,
  decisionMetrics: DecisionMetrics(
    acceptanceMetricPct: error.abs(),
    rejectionMetricPct: error.abs(),
  ),
  verdict: error.abs() <= 2 ? SampleVerdict.pass : SampleVerdict.fail,
);

void main() {
  group('sample statistics', () {
    test('n=1 has no sample standard deviation or repeatability', () {
      final stats = calculateSampleStatistics([result(1)], mpePct: 2);
      expect(stats.n, 1);
      expect(stats.meanErrorPct, 1);
      expect(stats.sampleStandardDeviationPct, isNull);
      expect(stats.repeatabilityStatus, RepeatabilityStatus.notEvaluable);
    });
    test('n=2 calculates s but repeatability is not evaluable', () {
      final stats = calculateSampleStatistics([
        result(-1),
        result(1),
      ], mpePct: 2);
      expect(stats.n, 2);
      expect(stats.sampleStandardDeviationPct, closeTo(1.414213562, 1e-9));
      expect(stats.repeatabilityStatus, RepeatabilityStatus.notEvaluable);
    });
    test('n=3 calculates mean, extrema, dispersion and sample s', () {
      final stats = calculateSampleStatistics([
        result(-1),
        result(0),
        result(1),
      ], mpePct: 3);
      expect(stats.n, 3);
      expect(stats.meanErrorPct, 0);
      expect(stats.minimumErrorPct, -1);
      expect(stats.maximumErrorPct, 1);
      expect(stats.dispersionPct, 2);
      expect(stats.sampleStandardDeviationPct, 1);
      expect(stats.repeatabilityStatus, RepeatabilityStatus.pass);
    });
    test('n>3 accepts arbitrary list length', () {
      final stats = calculateSampleStatistics([
        result(-1),
        result(0),
        result(1),
        result(2),
      ], mpePct: 5);
      expect(stats.n, 4);
      expect(stats.meanErrorPct, 0.5);
      expect(stats.dispersionPct, 3);
    });
    test('exactly MPE/3 passes repeatability', () {
      final stats = calculateSampleStatistics([
        result(-1),
        result(0),
        result(1),
      ], mpePct: 3);
      expect(stats.sampleStandardDeviationPct, 1);
      expect(stats.repeatabilityStatus, RepeatabilityStatus.pass);
    });
    test('just above MPE/3 fails repeatability', () {
      final stats = calculateSampleStatistics([
        result(-1.00000001),
        result(0),
        result(1.00000001),
      ], mpePct: 3);
      expect(stats.repeatabilityStatus, RepeatabilityStatus.fail);
    });
  });
}
