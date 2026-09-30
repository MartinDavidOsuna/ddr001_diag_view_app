import 'dart:convert';

import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:ddr001_diag_view_app/web_demo/web_demo_domain.dart';
import 'package:ddr001_diag_view_app/web_demo/web_demo_export.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<WebDemoController> start({DemoSettings? settings}) async {
    final controller = WebDemoController();
    addTearDown(controller.dispose);
    await controller.initialize();
    if (settings != null) await controller.saveSettings(settings);
    controller.beginCase(meter: 'DEMO', bench: 'BANCO');
    return controller;
  }

  Future<void> closeSample(
    WebDemoController controller, {
    double error = 0,
  }) async {
    controller.finishMeasurement();
    await controller.calculate(
      initialTotalizer: 0,
      initialNeedle: 0,
      finalTotalizer: 0,
      finalNeedle: controller.referenceLiters * (1 + error / 100),
    );
  }

  test(
    'photos captured while running, frozen endpoint, no duplicates at exact threshold',
    () async {
      final controller = await start();
      controller.advanceSimulation(const Duration(seconds: 10));
      expect(controller.photos, isEmpty);
      expect(controller.elapsed, Duration.zero);
      controller.startMeasurement();
      expect(controller.photos.single.type, EvidenceType.start);
      controller.pulseCount = 75;
      controller.advanceSimulation(const Duration(microseconds: 1));
      expect(controller.photos.map((photo) => photo.volume), [0, 25, 50]);
      final beforeFinal = controller.photos.toList();
      controller.finishMeasurement();
      final frozenEnd = controller.endedAt;
      expect(controller.photos.map((photo) => photo.volume), [0, 25, 50, 75]);
      expect(controller.photos.last.type, EvidenceType.finalEvidence);
      controller.advanceSimulation(const Duration(hours: 1));
      expect(controller.pulseCount, 75);
      expect(controller.photos.take(3), beforeFinal);
      await controller.calculate(
        initialTotalizer: 0,
        initialNeedle: 0,
        finalTotalizer: 0,
        finalNeedle: 75,
      );
      expect(controller.latestSample!.endedAt, frozenEnd);
      expect(
        controller.latestSample!.photos.every(
          (photo) => photo.hash.length == 64,
        ),
        isTrue,
      );
      final snapshotFlows = controller.photos
          .map((photo) => photo.flowLps)
          .toList();
      expect(
        controller.latestSample!.averageFlowLps,
        snapshotFlows.reduce((sum, value) => sum + value) /
            snapshotFlows.length,
      );
      await expectLater(
        controller.calculate(
          initialTotalizer: 0,
          initialNeedle: 0,
          finalTotalizer: 0,
          finalNeedle: 1,
        ),
        throwsStateError,
      );
      expect(controller.samples, hasLength(1));
    },
  );

  test(
    'configuration drives pulses, readings and uncertainty and is frozen',
    () async {
      final controller = await start(
        settings: DemoSettings({
          'k': 2,
          'step': 10,
          'uncertainty': .5,
          'odometerScale': 10,
        }),
      );
      controller.startMeasurement();
      controller.pulseCount = 101;
      controller.advanceSimulation(const Duration(microseconds: 1));
      await controller.saveSettings(DemoSettings({'k': 9}));
      expect(controller.referenceLiters, 202);
      controller.finishMeasurement();
      await controller.calculate(
        initialTotalizer: 0,
        initialNeedle: 0,
        finalTotalizer: 20.2,
        finalNeedle: 0,
      );
      final sample = controller.latestSample!;
      expect(sample.indicatedLiters, 202);
      expect(
        sample.uncertaintyPct,
        closeTo(.5 * 1.4142135623730951 / 202 * 100, 1e-10),
      );
      expect(sample.configuration.value('k'), 2);
      expect(sample.photos[1].volume, 10);
    },
  );

  test(
    'draft survives reload without downtime pulses or duplicate photos',
    () async {
      final controller = await start();
      controller.startMeasurement();
      controller.advanceSimulation(const Duration(seconds: 12));
      controller.pauseToHome();
      await controller.flush();
      final recovered = WebDemoController();
      addTearDown(recovered.dispose);
      await recovered.initialize();
      expect(recovered.page, WebDemoPage.recovery);
      expect(recovered.pulseCount, controller.pulseCount);
      expect(
        recovered.photos.map((photo) => photo.toJson()),
        controller.photos.map((photo) => photo.toJson()),
      );
      recovered.resume();
      expect(recovered.pulseCount, controller.pulseCount);
      expect(recovered.elapsed, controller.elapsed);
      recovered.finishMeasurement();
      await recovered.flush();
    },
  );

  test(
    'repetition retains samples; missing Q2 is never approved; exports share Android renderer',
    () async {
      final controller = await start();
      for (var count = 0; count < 3; count++) {
        if (count > 0) controller.repeatSample();
        controller.startMeasurement();
        controller.pulseCount = 202;
        controller.advanceSimulation(const Duration(microseconds: 1));
        await closeSample(controller);
      }
      expect(controller.currentCase.verdict, SampleVerdict.inconclusive);
      expect(
        controller.currentCase.flows.first.statistics!.repeatabilityStatus,
        RepeatabilityStatus.pass,
      );
      controller.startQ2();
      controller.startMeasurement();
      controller.pulseCount = 202;
      controller.advanceSimulation(const Duration(microseconds: 1));
      await closeSample(controller);
      await controller.finishCase();
      await controller.finishCase();
      expect(controller.history, hasLength(1));
      expect(controller.history.single.samples, hasLength(4));
      expect(controller.history.single.verdict, SampleVerdict.pass);
      final files = await DemoExport.generate(controller.history.single, {
        0,
        3,
      });
      expect(files.keys, containsAll(['csv', 'json', 'html', 'pdf']));
      final html = utf8.decode(files['html']!);
      expect(html, contains('data:image/png;base64,'));
      expect(html, contains('PRUEBA SIMULADA'));
      expect(html, contains('Descargar PDF'));
      expect(html, contains('Registro'));
      expect(ascii.decode(files['pdf']!.take(4).toList()), '%PDF');
      final json = jsonDecode(utf8.decode(files['json']!)) as Map;
      expect(json['schema'], 'ddr001.verification.export/v2');
      expect(utf8.decode(files['csv']!), contains('SIMULATION'));
    },
  );

  test('configuration rejects nonfinite values and invalid ranges', () {
    for (final values in <Map<String, num>>[
      {'k': 0},
      {'step': -1},
      {'uncertainty': double.nan},
      {'minimum': 500},
      {'decimals': 4},
      {'integers': 2.5},
    ]) {
      expect(() => DemoSettings(values), throwsArgumentError);
    }
  });

  test('indicators belong only to the active run screen', () {
    final controller = WebDemoController();
    addTearDown(controller.dispose);
    for (final page in WebDemoPage.values) {
      controller.navigate(page);
      expect(controller.indicatorsVisible, page == WebDemoPage.run);
    }
  });

  test('legacy web samples remain readable without inventing photos', () async {
    final controller = await start();
    controller.startMeasurement();
    controller.pulseCount = 100;
    controller.advanceSimulation(const Duration(microseconds: 1));
    await closeSample(controller);
    final original = controller.latestSample!;
    final legacy = original.toJson()
      ..remove('photos')
      ..remove('settings');
    final restored = DemoSample.fromJson(legacy);
    expect(restored.photos, isEmpty);
    expect(restored.referenceLiters, original.referenceLiters);
    expect(restored.indicatedLiters, original.indicatedLiters);
    expect(restored.verdict, original.verdict);
    expect(() => original.photos.clear(), throwsUnsupportedError);
  });
}
