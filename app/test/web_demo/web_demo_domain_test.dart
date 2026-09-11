import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:ddr001_diag_view_app/web_demo/web_demo_domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('demo begins with fluctuating Q1 flow but no measured volume', () async {
    final controller = WebDemoController(random: Random(7));
    addTearDown(controller.dispose);

    await controller.initialize();
    controller.beginCase(meter: 'DEMO-01', bench: 'BANCO-01');

    expect(controller.flowPoint, FlowPoint.q1);
    expect(controller.flowLps, inInclusiveRange(5, 7));
    expect(controller.measurementStarted, isFalse);
    expect(controller.pulseCount, 0);

    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(controller.flowLps, inInclusiveRange(5, 7));
    expect(controller.pulseCount, 0);
  });

  test('complete Q1 and Q2 use real metrology and persist locally', () async {
    final controller = WebDemoController(random: Random(11));
    addTearDown(controller.dispose);
    await controller.initialize();
    controller.beginCase(meter: 'MEDIDOR-DEMO', bench: 'BANCO-DEMO');

    controller.startMeasurement();
    controller.pulseCount = 202;
    controller.finishMeasurement();
    await controller.calculate(
      initialTotalizer: 10.345,
      initialNeedle: 0,
      finalTotalizer: 10.547,
      finalNeedle: 0,
    );

    expect(controller.latestSample!.referenceLiters, 202);
    expect(controller.latestSample!.indicatedLiters, closeTo(202, 1e-9));
    expect(controller.latestSample!.verdict, SampleVerdict.pass);

    controller.startQ2();
    expect(controller.flowLps, inInclusiveRange(2, 3));
    controller.startMeasurement();
    controller.pulseCount = 75;
    controller.finishMeasurement();
    await controller.calculate(
      initialTotalizer: 20,
      initialNeedle: 0,
      finalTotalizer: 20.075,
      finalNeedle: 0,
    );
    await controller.finishCase();

    expect(controller.history, hasLength(1));
    expect(controller.history.single.samples, hasLength(2));
    expect(controller.page, WebDemoPage.report);

    final recovered = WebDemoController(random: Random(11));
    addTearDown(recovered.dispose);
    await recovered.initialize();
    expect(recovered.history, hasLength(1));
    expect(recovered.history.single.meterId, 'MEDIDOR-DEMO');
    expect(recovered.history.single.samples.last.flowPoint, FlowPoint.q2);

    await recovered.clearHistory();
    final empty = WebDemoController();
    addTearDown(empty.dispose);
    await empty.initialize();
    expect(empty.history, isEmpty);
  });

  test('manual demo needle values are not capped at 100 liters', () async {
    final controller = WebDemoController();
    addTearDown(controller.dispose);
    await controller.initialize();
    controller.beginCase(meter: 'M', bench: 'B');
    controller.startMeasurement();
    controller.pulseCount = 250;
    controller.finishMeasurement();

    await controller.calculate(
      initialTotalizer: 10,
      initialNeedle: 125,
      finalTotalizer: 10,
      finalNeedle: 375,
    );

    expect(controller.latestSample!.indicatedLiters, 250);
  });
}
