import '../decision/decision_rule.dart';

final class SampleResult {
  const SampleResult({
    required this.referenceLiters,
    required this.indicatedLiters,
    required this.errorPct,
    required this.uncertaintyPct,
    required this.mpePct,
    required this.decisionMetrics,
    required this.verdict,
  });

  final double referenceLiters;
  final double indicatedLiters;
  final double errorPct;
  final double uncertaintyPct;
  final double mpePct;
  final DecisionMetrics decisionMetrics;
  final SampleVerdict verdict;
}
