import 'package:ddr001_app/core/metrology/metrology.dart';
import 'package:flutter_test/flutter_test.dart';

SampleResult sample(double error, SampleVerdict verdict) => SampleResult(
  referenceLiters: 100,
  indicatedLiters: 100 + error,
  errorPct: error,
  uncertaintyPct: 0,
  mpePct: 2,
  decisionMetrics: DecisionMetrics(
    acceptanceMetricPct: error.abs(),
    rejectionMetricPct: error.abs(),
  ),
  verdict: verdict,
);

FlowPointResult flow(FlowPoint point, FlowPointStatus status) =>
    FlowPointResult(flowPoint: point, status: status, samples: const []);

void main() {
  group('flow point summary', () {
    test('all passing samples pass the flow point', () {
      final result = FlowPointResult.summarize(
        flowPoint: FlowPoint.q3,
        samples: [sample(0.1, SampleVerdict.pass)],
        mpePct: 2,
      );
      expect(result.status, FlowPointStatus.pass);
    });
    test('one failed sample fails the flow point', () {
      final result = FlowPointResult.summarize(
        flowPoint: FlowPoint.q3,
        samples: [
          sample(0.1, SampleVerdict.pass),
          sample(3, SampleVerdict.fail),
        ],
        mpePct: 2,
      );
      expect(result.status, FlowPointStatus.fail);
    });
    test('one inconclusive sample makes the flow point inconclusive', () {
      final result = FlowPointResult.summarize(
        flowPoint: FlowPoint.q3,
        samples: [
          sample(0.1, SampleVerdict.pass),
          sample(1.9, SampleVerdict.inconclusive),
        ],
        mpePct: 2,
      );
      expect(result.status, FlowPointStatus.inconclusive);
    });
    test('n<3 can pass while repeatability remains not evaluable', () {
      final result = FlowPointResult.summarize(
        flowPoint: FlowPoint.q3,
        samples: [sample(0.1, SampleVerdict.pass)],
        mpePct: 2,
      );
      expect(
        result.statistics!.repeatabilityStatus,
        RepeatabilityStatus.notEvaluable,
      );
    });
    test('passing repeatability retains pass', () {
      final result = FlowPointResult.summarize(
        flowPoint: FlowPoint.q3,
        samples: [
          sample(-0.5, SampleVerdict.pass),
          sample(0, SampleVerdict.pass),
          sample(0.5, SampleVerdict.pass),
        ],
        mpePct: 2,
      );
      expect(result.statistics!.repeatabilityStatus, RepeatabilityStatus.pass);
      expect(result.status, FlowPointStatus.pass);
    });
    test('failed repeatability fails the flow point', () {
      final result = FlowPointResult.summarize(
        flowPoint: FlowPoint.q3,
        samples: [
          sample(-1, SampleVerdict.pass),
          sample(0, SampleVerdict.pass),
          sample(1, SampleVerdict.pass),
        ],
        mpePct: 2,
      );
      expect(result.statistics!.repeatabilityStatus, RepeatabilityStatus.fail);
      expect(result.status, FlowPointStatus.fail);
    });
  });

  group('case verdict', () {
    test('all explicitly required flows pass means approved', () {
      expect(
        calculateCaseVerdict(
          requiredFlowPoints: {FlowPoint.q1, FlowPoint.q3},
          flowResults: [
            flow(FlowPoint.q1, FlowPointStatus.pass),
            flow(FlowPoint.q3, FlowPointStatus.pass),
          ],
        ),
        CaseVerdict.approved,
      );
    });
    test('any required failed flow means rejected', () {
      expect(
        calculateCaseVerdict(
          requiredFlowPoints: {FlowPoint.q1, FlowPoint.q3},
          flowResults: [
            flow(FlowPoint.q1, FlowPointStatus.pass),
            flow(FlowPoint.q3, FlowPointStatus.fail),
          ],
        ),
        CaseVerdict.rejected,
      );
    });
    test('any required inconclusive flow means inconclusive', () {
      expect(
        calculateCaseVerdict(
          requiredFlowPoints: {FlowPoint.q1, FlowPoint.q3},
          flowResults: [
            flow(FlowPoint.q1, FlowPointStatus.pass),
            flow(FlowPoint.q3, FlowPointStatus.inconclusive),
          ],
        ),
        CaseVerdict.inconclusive,
      );
    });
    test('missing required flow means inconclusive', () {
      expect(
        calculateCaseVerdict(
          requiredFlowPoints: {FlowPoint.q1, FlowPoint.q3},
          flowResults: [flow(FlowPoint.q1, FlowPointStatus.pass)],
        ),
        CaseVerdict.inconclusive,
      );
    });
  });

  test('VISUAL is not a pulse source while MANUAL LED and BLE are', () {
    expect(MeasurementMethod.visual.isPulseEventSource, isFalse);
    expect(MeasurementMethod.manual.isPulseEventSource, isTrue);
    expect(MeasurementMethod.led.isPulseEventSource, isTrue);
    expect(MeasurementMethod.ble.isPulseEventSource, isTrue);
  });
}
