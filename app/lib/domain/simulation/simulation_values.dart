import 'dart:math';

import '../../core/metrology/metrology.dart';

typedef SimulationRandomValue = double Function();

final class SimulationFlowRange {
  const SimulationFlowRange(this.minimumLps, this.maximumLps);

  final double minimumLps;
  final double maximumLps;

  static SimulationFlowRange forFlow(FlowPoint flowPoint) =>
      switch (flowPoint) {
        FlowPoint.q1 => const SimulationFlowRange(5, 7),
        FlowPoint.q2 => const SimulationFlowRange(2, 3),
        FlowPoint.q3 => const SimulationFlowRange(.5, 1),
        FlowPoint.q4 => const SimulationFlowRange(.25, .5),
      };
}

/// Produces a field-like fluctuating flow while keeping every adjacent change
/// within 0.5 L/s and every value inside the Q-specific range.
final class SimulationFlowGenerator {
  SimulationFlowGenerator({
    required this.flowPoint,
    SimulationRandomValue? randomValue,
    this.maximumVariationLps = .5,
  }) : _randomValue = randomValue ?? Random().nextDouble,
       range = SimulationFlowRange.forFlow(flowPoint);

  final FlowPoint flowPoint;
  final SimulationFlowRange range;
  final double maximumVariationLps;
  final SimulationRandomValue _randomValue;
  double? _currentLps;

  double get currentLps => _currentLps ?? next();

  double next() {
    final current = _currentLps;
    final minimum = current == null
        ? range.minimumLps
        : max(range.minimumLps, current - maximumVariationLps);
    final maximum = current == null
        ? range.maximumLps
        : min(range.maximumLps, current + maximumVariationLps);
    final value = minimum + (maximum - minimum) * _randomValue().clamp(0, 1);
    _currentLps = value;
    return value;
  }

  Duration pulseInterval(double litersPerPulse) {
    if (!litersPerPulse.isFinite || litersPerPulse <= 0) {
      throw ArgumentError.value(litersPerPulse, 'litersPerPulse');
    }
    return Duration(
      microseconds: max(1, (litersPerPulse / currentLps * 1000000).round()),
    );
  }
}
