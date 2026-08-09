import 'package:ddr001_app/core/metrology/metrology.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reference volume', () {
    test('zero pulses produces zero liters', () {
      expect(calculateReferenceVolume(pulseCount: 0, litersPerPulse: 1), 0);
    });
    test('one pulse uses K', () {
      expect(calculateReferenceVolume(pulseCount: 1, litersPerPulse: 1), 1);
    });
    test('fractional K is supported', () {
      expect(
        calculateReferenceVolume(pulseCount: 3, litersPerPulse: 0.25),
        0.75,
      );
    });
    test('invalid K is rejected', () {
      expect(
        () => calculateReferenceVolume(pulseCount: 1, litersPerPulse: 0),
        throwsArgumentError,
      );
    });
    test('negative pulse count is rejected', () {
      expect(
        () => calculateReferenceVolume(pulseCount: -1, litersPerPulse: 1),
        throwsArgumentError,
      );
    });
  });

  group('endpoint error', () {
    test('200 / 200 is zero percent', () {
      expect(
        calculateEndpointErrorPct(referenceLiters: 200, indicatedLiters: 200),
        0,
      );
    });
    test('200 / 202 is positive one percent', () {
      expect(
        calculateEndpointErrorPct(referenceLiters: 200, indicatedLiters: 202),
        1,
      );
    });
    test('200 / 198 is negative one percent', () {
      expect(
        calculateEndpointErrorPct(referenceLiters: 200, indicatedLiters: 198),
        -1,
      );
    });
    test('zero reference is rejected', () {
      expect(
        () => calculateEndpointErrorPct(referenceLiters: 0, indicatedLiters: 1),
        throwsArgumentError,
      );
    });
  });

  test('SSOT reference case fails with endpoint calculation', () {
    const engine = MetrologyEngine();
    final result = engine.evaluate(
      flowPoint: FlowPoint.q3,
      referenceLiters: 212,
      indicatedLiters: 206,
    );
    expect(result.errorPct, closeTo(-2.830188679, 1e-9));
    expect(result.uncertaintyPct, closeTo(0.667081, 1e-6));
    expect(result.mpePct, 2);
    expect(result.verdict, SampleVerdict.fail);
  });

  test('legacy simulator scenario preserves configured error', () {
    const engine = MetrologyEngine();
    final result = engine.evaluate(
      flowPoint: FlowPoint.q3,
      referenceLiters: 200,
      indicatedLiters: 197.6,
    );
    expect(result.errorPct, closeTo(-1.2, 1e-12));
    expect(result.verdict, SampleVerdict.pass);
  });
}
