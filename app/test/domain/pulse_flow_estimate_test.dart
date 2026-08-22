import 'package:ddr001_diag_view_app/domain/pulse/pulse_flow_estimate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the latest ten pulses after startup', () {
    final start = DateTime.utc(2026, 8, 21, 12);
    final times = List.generate(
      10,
      (index) => start.add(Duration(seconds: 10 + index)),
    );
    final estimate = PulseFlowEstimate.calculate(
      pulses: 25,
      litersPerPulse: 1,
      firstPulseAt: start,
      now: start.add(const Duration(seconds: 20)),
      recentPulseTimes: times,
    );

    expect(estimate.flowLps, 1);
  });

  test('flow decreases as elapsed time grows without new pulses', () {
    final start = DateTime.utc(2026, 8, 17, 12);
    final first = PulseFlowEstimate.calculate(
      pulses: 10,
      litersPerPulse: 1,
      firstPulseAt: start,
      now: start.add(const Duration(seconds: 10)),
    );
    final later = PulseFlowEstimate.calculate(
      pulses: 10,
      litersPerPulse: 1,
      firstPulseAt: start,
      now: start.add(const Duration(seconds: 100)),
    );

    expect(first.flowLps, 1);
    expect(later.flowLps, .1);
  });

  test('confidence is complement of one-pulse relative resolution', () {
    final start = DateTime.utc(2026, 8, 17, 12);

    expect(
      PulseFlowEstimate.calculate(
        pulses: 1,
        litersPerPulse: 1,
        firstPulseAt: start,
        now: start.add(const Duration(seconds: 1)),
      ).confidence,
      0,
    );
    expect(
      PulseFlowEstimate.calculate(
        pulses: 10,
        litersPerPulse: 1,
        firstPulseAt: start,
        now: start.add(const Duration(seconds: 10)),
      ).confidence,
      90,
    );
  });
}
