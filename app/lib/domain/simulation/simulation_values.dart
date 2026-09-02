import '../../core/metrology/metrology.dart';
import '../models.dart';

final class SimulationValues {
  const SimulationValues({
    required this.referenceLiters,
    required this.indicatedLiters,
    required this.flowLps,
  });

  final double referenceLiters;
  final double indicatedLiters;
  final double flowLps;

  static SimulationValues forSample({
    required Sample sample,
    required bool shouldPass,
  }) {
    const reference = 100.0;
    final mpe = sample.configuration.mpePct;
    final errorPct = shouldPass ? (mpe * .25).clamp(.25, 1.0) : mpe + 2;
    final indicated = reference * (1 + errorPct / 100);
    final flow = switch (sample.configuration.flowPoint) {
      FlowPoint.q1 => 1.5,
      FlowPoint.q2 => 1.0,
      FlowPoint.q3 => .5,
      FlowPoint.q4 => .25,
    };
    return SimulationValues(
      referenceLiters: reference,
      indicatedLiters: indicated,
      flowLps: flow,
    );
  }
}
