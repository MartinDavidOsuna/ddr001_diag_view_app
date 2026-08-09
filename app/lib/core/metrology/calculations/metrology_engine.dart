import '../decision/decision_rule.dart';
import '../decision/mpe_policy.dart';
import '../models/flow_point.dart';
import '../models/sample_result.dart';
import 'error_calculation.dart';
import 'uncertainty.dart';

final class MetrologyEngine {
  const MetrologyEngine({
    this.mpePolicy = const Class2WaterMpePolicy(),
    this.uncertaintyPolicy = const ReadingUncertaintyPolicy(),
    this.decisionRule = const GuardBandDecisionRule(),
  });

  final MpePolicy mpePolicy;
  final UncertaintyPolicy uncertaintyPolicy;
  final GuardBandDecisionRule decisionRule;

  SampleResult evaluate({
    required FlowPoint flowPoint,
    required double referenceLiters,
    required double indicatedLiters,
  }) {
    final error = calculateEndpointErrorPct(
      referenceLiters: referenceLiters,
      indicatedLiters: indicatedLiters,
    );
    final uncertainty = uncertaintyPolicy.calculatePct(
      referenceLiters: referenceLiters,
    );
    final mpe = mpePolicy.mpePctFor(flowPoint);
    final decision = decisionRule.evaluate(
      errorPct: error,
      uncertaintyPct: uncertainty,
      mpePct: mpe,
    );
    return SampleResult(
      referenceLiters: referenceLiters,
      indicatedLiters: indicatedLiters,
      errorPct: error,
      uncertaintyPct: uncertainty,
      mpePct: mpe,
      decisionMetrics: decision.metrics,
      verdict: decision.verdict,
    );
  }
}
