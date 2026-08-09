import 'numeric_tolerance.dart';

enum SampleVerdict { pass, fail, inconclusive }

final class DecisionMetrics {
  const DecisionMetrics({
    required this.acceptanceMetricPct,
    required this.rejectionMetricPct,
  });

  final double acceptanceMetricPct;
  final double rejectionMetricPct;
}

final class DecisionOutcome {
  const DecisionOutcome({required this.verdict, required this.metrics});

  final SampleVerdict verdict;
  final DecisionMetrics metrics;
}

final class GuardBandDecisionRule {
  const GuardBandDecisionRule({this.tolerance = const NumericTolerance()});

  final NumericTolerance tolerance;

  DecisionOutcome evaluate({
    required double errorPct,
    required double uncertaintyPct,
    required double mpePct,
  }) {
    if (!errorPct.isFinite) {
      throw ArgumentError.value(errorPct, 'errorPct');
    }
    if (!uncertaintyPct.isFinite || uncertaintyPct < 0) {
      throw ArgumentError.value(uncertaintyPct, 'uncertaintyPct');
    }
    if (!mpePct.isFinite || mpePct <= 0) {
      throw ArgumentError.value(mpePct, 'mpePct');
    }
    final absoluteError = errorPct.abs();
    final acceptanceMetric = absoluteError + uncertaintyPct;
    final rejectionMetric = absoluteError - uncertaintyPct;
    final verdict = tolerance.lessThanOrEqual(acceptanceMetric, mpePct)
        ? SampleVerdict.pass
        : tolerance.greaterThan(rejectionMetric, mpePct)
        ? SampleVerdict.fail
        : SampleVerdict.inconclusive;
    return DecisionOutcome(
      verdict: verdict,
      metrics: DecisionMetrics(
        acceptanceMetricPct: acceptanceMetric,
        rejectionMetricPct: rejectionMetric,
      ),
    );
  }
}
