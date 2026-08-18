import 'package:ddr001_diag_view_app/domain/control_start_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not enable before the first control pulse', () {
    final result = ControlStartGate.evaluate(
      pulses: 0,
      litersPerPulse: 1,
      firstPulseAt: null,
      now: DateTime.utc(2026, 8, 17),
      minimumLps: 1,
      maximumLps: 2,
    );
    expect(result.inRange, isFalse);
  });

  test('enables inclusively inside configured control-flow range', () {
    final first = DateTime.utc(2026, 8, 17, 12);
    final result = ControlStartGate.evaluate(
      pulses: 15,
      litersPerPulse: 1,
      firstPulseAt: first,
      now: first.add(const Duration(seconds: 10)),
      minimumLps: 1,
      maximumLps: 2,
    );
    expect(result.flowLps, 1.5);
    expect(result.inRange, isTrue);
  });

  test('remains disabled below minimum and above maximum', () {
    final first = DateTime.utc(2026, 8, 17, 12);
    for (final pulses in [5, 25]) {
      final result = ControlStartGate.evaluate(
        pulses: pulses,
        litersPerPulse: 1,
        firstPulseAt: first,
        now: first.add(const Duration(seconds: 10)),
        minimumLps: 1,
        maximumLps: 2,
      );
      expect(result.inRange, isFalse);
    }
  });
}
