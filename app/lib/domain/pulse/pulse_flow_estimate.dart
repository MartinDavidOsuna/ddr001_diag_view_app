final class PulseFlowEstimate {
  const PulseFlowEstimate({required this.flowLps, required this.confidence});

  final double flowLps;
  final double confidence;

  static PulseFlowEstimate calculate({
    required int pulses,
    required double litersPerPulse,
    required DateTime? firstPulseAt,
    required DateTime now,
    List<DateTime> recentPulseTimes = const [],
  }) {
    if (pulses <= 0 || litersPerPulse <= 0 || firstPulseAt == null) {
      return const PulseFlowEstimate(flowLps: 0, confidence: 0);
    }
    final useRollingWindow = pulses > 10 && recentPulseTimes.length >= 10;
    final windowPulses = useRollingWindow ? 10 : pulses;
    final windowStart = useRollingWindow
        ? recentPulseTimes.first
        : firstPulseAt;
    final elapsedSeconds = now.difference(windowStart).inMilliseconds / 1000.0;
    if (elapsedSeconds <= 0) {
      return const PulseFlowEstimate(flowLps: 0, confidence: 0);
    }

    // A pulse is the acquisition resolution. Its relative contribution to
    // accumulated pulse volume is 1/N; confidence is its complement.
    final confidence = ((pulses - 1) / pulses * 100).clamp(0.0, 100.0);
    return PulseFlowEstimate(
      flowLps: windowPulses * litersPerPulse / elapsedSeconds,
      confidence: confidence,
    );
  }
}
