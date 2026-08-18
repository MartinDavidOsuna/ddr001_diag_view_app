final class ControlStartGateResult {
  const ControlStartGateResult({required this.flowLps, required this.inRange});
  final double flowLps;
  final bool inRange;
}

abstract final class ControlStartGate {
  static ControlStartGateResult evaluate({
    required int pulses,
    required double litersPerPulse,
    required DateTime? firstPulseAt,
    required DateTime now,
    required double minimumLps,
    required double maximumLps,
  }) {
    if (pulses <= 0 || firstPulseAt == null) {
      return const ControlStartGateResult(flowLps: 0, inRange: false);
    }
    final seconds = now.difference(firstPulseAt).inMicroseconds / 1000000;
    if (seconds <= 0) {
      return const ControlStartGateResult(flowLps: 0, inRange: false);
    }
    final flow = pulses * litersPerPulse / seconds;
    return ControlStartGateResult(
      flowLps: flow,
      inRange: flow >= minimumLps && flow <= maximumLps,
    );
  }
}
