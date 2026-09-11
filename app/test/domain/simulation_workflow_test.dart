import 'dart:io';

import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:ddr001_diag_view_app/domain/simulation/simulation_values.dart';
import 'package:ddr001_diag_view_app/infrastructure/simulation/simulation_evidence_capture.dart';
import 'package:ddr001_diag_view_app/presentation/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import '../support/presentation_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PresentationFixture fixture;

  setUp(() async => fixture = await PresentationFixture.create());
  tearDown(() => fixture.dispose());

  test('bundled simulation Evidence placeholder exists physically', () async {
    final placeholder = File(SimulationEvidenceCaptureAdapter.assetPath);
    expect(await placeholder.exists(), isTrue);
    final bytes = await placeholder.readAsBytes();
    expect(bytes.length, greaterThan(1000));
    expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
  });

  test('Q1 random flow stays in 5-7 and adjacent changes stay within .5', () {
    final values = <double>[0, 1, .1, .9, .25, .75];
    var index = 0;
    final generator = SimulationFlowGenerator(
      flowPoint: FlowPoint.q1,
      randomValue: () => values[index++ % values.length],
    );
    final generated = List.generate(30, (_) => generator.next());

    expect(generated.every((value) => value >= 5 && value <= 7), isTrue);
    for (var i = 1; i < generated.length; i++) {
      expect((generated[i] - generated[i - 1]).abs(), lessThanOrEqualTo(.5));
    }
  });

  test('Q2 random flow stays in 2-3 and adjacent changes stay within .5', () {
    final values = <double>[1, 0, .8, .2, .6, .4];
    var index = 0;
    final generator = SimulationFlowGenerator(
      flowPoint: FlowPoint.q2,
      randomValue: () => values[index++ % values.length],
    );
    final generated = List.generate(30, (_) => generator.next());

    expect(generated.every((value) => value >= 2 && value <= 3), isTrue);
    for (var i = 1; i < generated.length; i++) {
      expect((generated[i] - generated[i - 1]).abs(), lessThanOrEqualTo(.5));
    }
  });

  test(
    'operator controls start and finish while the real engine calculates',
    () async {
      final controller = _controller(fixture);
      await _prepareSimulation(controller, meterId: 'SIM-CONTROLLED');

      expect(controller.state.sample?.status, SampleStatus.draft);
      expect(controller.state.measurementStarted, isFalse);
      expect(controller.state.simulationFlowLps, 6);
      await Future<void>.delayed(const Duration(milliseconds: 550));
      expect(controller.state.sample?.pulseCount, 0);

      final pressedAt = DateTime.now().toUtc();
      await controller.beginMeasurement();
      expect(controller.state.measurementStarted, isTrue);
      expect(
        controller.state.sample?.startedAt?.difference(pressedAt).abs(),
        lessThan(const Duration(milliseconds: 100)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 260));
      expect(controller.state.sample!.pulseCount, greaterThan(0));

      await controller.requestFinalEvidence();
      expect(controller.state.page, AppPage.readings);
      expect(controller.state.measurementStarted, isFalse);
      final reference =
          controller.state.sample!.pulseCount *
          controller.state.sample!.configuration.litersPerPulse;
      await controller.closeSample(
        initialTotalizer: 10.345,
        initialNeedle: 250,
        initialMeterTotalLiters: 10.345,
        finalTotalizer: 10.345 + reference / 1000,
        finalNeedle: 250,
        finalMeterTotalLiters: 10.345 + reference / 1000,
      );

      final closed = controller.state.sample!;
      expect(closed.status, SampleStatus.closedValid);
      expect(closed.simulationScenario, SimulationScenario.operatorControlled);
      expect(closed.initialReading?.reading.needleLiters, 250);
      expect(closed.finalReading?.reading.needleLiters, 250);
      expect(closed.result?.referenceLiters, closeTo(reference, 1e-9));
      expect(closed.result?.indicatedLiters, closeTo(reference, 1e-9));
      expect(closed.result?.verdict, SampleVerdict.pass);
      expect(closed.checksum, hasLength(64));
      final evidence = await fixture.dependencies.evidence.listBySample(
        closed.id,
      );
      expect(evidence.first.type, EvidenceType.start);
      expect(evidence.last.type, EvidenceType.finalEvidence);
      expect(
        evidence.every((item) => File(item.localPath).existsSync()),
        isTrue,
      );
      controller.dispose();
    },
  );

  test(
    'restart recovers simulation without starting pulses by itself',
    () async {
      await fixture.seedSession();
      final first = _controller(fixture);
      await first.initialize();
      await _prepareSimulation(first, login: false, meterId: 'SIM-RECOVERY');
      await first.beginMeasurement();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final before = first.state.sample!.pulseCount;
      expect(before, greaterThan(0));
      first.dispose();

      final restarted = _controller(fixture);
      await restarted.initialize();
      expect(restarted.state.page, AppPage.recovery);
      await restarted.resumeSample();
      expect(restarted.state.page, AppPage.run);
      expect(restarted.state.measurementStarted, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 550));
      expect(restarted.state.sample?.pulseCount, before);
      expect(restarted.state.simulationFlowLps, 6);
      restarted.dispose();
    },
  );
}

AppController _controller(PresentationFixture fixture) => AppController(
  fixture.dependencies,
  const Uuid(),
  (flowPoint) =>
      SimulationFlowGenerator(flowPoint: flowPoint, randomValue: () => .5),
);

Future<void> _prepareSimulation(
  AppController controller, {
  required String meterId,
  bool login = true,
}) async {
  if (login) {
    await controller.login('QA Simulación', 'qa@aquafim.mx', '4491234567');
  }
  await controller.identifyMeter(meterId: meterId, testBenchId: 'SIMULATION');
  controller.selectMethod(MeasurementMethod.simulation);
  controller.updateSetup(
    litersPerPulse: .1,
    evidenceStepLiters: .5,
    uncertaintyLiters: .01,
    minimumVolumeLiters: .5,
    maximumVolumeLiters: 300,
  );
  await controller.startSample();
}
