@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';

import 'package:ddr001_diag_view_app/web_demo/web_demo_app.dart';
import 'package:ddr001_diag_view_app/web_demo/web_demo_domain.dart';
import 'package:ddr001_diag_view_app/web_demo/web_demo_export.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as raster;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final thumbnail = raster.encodePng(raster.Image(width: 1, height: 1));
  final originalReport = reportTestException;
  late ByteData fullResolutionPhoto;
  setUpAll(() async {
    final response = await http.get(
      Uri.base.resolve('/web_demo/demo_meter_face.png'),
    );
    expect(response.statusCode, 200);
    expect(response.bodyBytes.length, greaterThan(2000000));
    fullResolutionPhoto = ByteData.sublistView(response.bodyBytes);
    reportTestException = (details, description) {
      Zone.current.print(details.toString());
      originalReport(details, description);
    };
  });
  tearDownAll(() => reportTestException = originalReport);
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  ByteData? evidenceBytes;
  var evidenceLoads = 0;
  setUp(() {
    evidenceBytes = null;
    evidenceLoads = 0;
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Verificador',
      packageName: 'test',
      version: '1.8.0',
      buildNumber: '26',
      buildSignature: 'test',
    );
    binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
      message,
    ) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (key.endsWith('AssetManifest.bin.json')) {
        final manifest = const StandardMessageCodec().encodeMessage(
          <String, Object?>{},
        )!;
        return ByteData.sublistView(
          utf8.encode(
            jsonEncode(
              base64Encode(
                manifest.buffer.asUint8List(
                  manifest.offsetInBytes,
                  manifest.lengthInBytes,
                ),
              ),
            ),
          ),
        );
      }
      if (key.endsWith('AssetManifest.bin')) {
        return const StandardMessageCodec().encodeMessage(<String, Object?>{});
      }
      if (key.endsWith('.png')) {
        if (key.endsWith('demo_meter_face.png')) evidenceLoads++;
        if (evidenceBytes != null) return evidenceBytes;
        return ByteData.sublistView(thumbnail);
      }
      return ByteData.sublistView(
        utf8.encode(key.endsWith('.json') ? '[]' : 'Manual de simulación'),
      );
    });
  });
  tearDown(
    () => binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      null,
    ),
  );

  Future<WebDemoController> mount(
    WidgetTester tester, {
    double width = 390,
  }) async {
    final controller = WebDemoController();
    await tester.runAsync(controller.initialize);
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      Zone.current.print(details.toString());
      previousErrorHandler!(details);
    };
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    addTearDown(controller.dispose);
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(Ddr001WebDemoApp(controller: controller));
    await tester.pumpAndSettle();
    return controller;
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('Android home, history and configuration fit a narrow viewport', (
    tester,
  ) async {
    final controller = await mount(tester, width: 360);
    expect(find.text('VERIFICADOR FUNCIONAL'), findsOneWidget);
    expect(find.text('Versión: 1.8.0+26'), findsOneWidget);
    expect(find.textContaining('DEMO WEB LOCAL'), findsNothing);
    expect(find.byKey(const Key('run-indicators')), findsNothing);
    await tap(tester, find.text('HISTORIAL LOCAL'));
    expect(find.text('Todavía no hay expedientes locales.'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'BORRAR HISTORIAL'),
          )
          .onPressed,
      isNull,
    );
    controller.navigate(WebDemoPage.setup);
    await tester.pumpAndSettle();
    expect(find.text('Caudal mínimo para iniciar (L/s)'), findsOneWidget);
    expect(find.text('Escala aguja (L/vuelta)'), findsOneWidget);
    expect(find.text('Paso de evidencia (L)'), findsOneWidget);
    expect(find.byKey(const Key('run-indicators')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('complete simulation mirrors Android navigation and photos', (
    tester,
  ) async {
    final controller = await mount(tester);
    await tap(tester, find.byKey(const Key('new-verification')));
    await tester.enterText(find.byKey(const Key('meter-id')), 'WEB-QA');
    await tester.enterText(find.byKey(const Key('test-bench-id')), 'BANCO-QA');
    await tap(tester, find.byKey(const Key('identify-continue')));
    expect(find.text('Ubicación no registrada'), findsOneWidget);
    await tap(tester, find.text('CONTINUAR SIN UBICACIÓN'));
    for (final name in [
      'BLUETOOTH',
      'MANUAL',
      'LECTURA VISUAL',
      'SIMULACIÓN',
    ]) {
      expect(find.widgetWithText(ChoiceChip, name), findsOneWidget);
    }
    await tap(tester, find.byKey(const Key('method-continue')));
    await tap(tester, find.byKey(const Key('start-sample')));
    expect(controller.page, WebDemoPage.run);
    expect(find.byKey(const Key('run-indicators')), findsOneWidget);
    expect(find.text('CAPTURA DE EVIDENCIAS'), findsOneWidget);
    expect(controller.photos, isEmpty);

    for (final flow in ['Q1', 'Q2']) {
      await tap(tester, find.byKey(const Key('begin-measurement')));
      expect(controller.photos.first.label, 'INICIO');
      controller.pulseCount = 202;
      controller.advanceSimulation(const Duration(microseconds: 1));
      await tester.pump();
      expect(controller.photos.length, greaterThan(1));
      await tap(tester, find.byKey(const Key('finish-run')));
      expect(find.byKey(const Key('run-indicators')), findsNothing);
      expect(find.text('LECTURA INICIO'), findsOneWidget);
      expect(find.text('LECTURA FINAL'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('final-totalizer')))
            .controller!
            .text,
        isEmpty,
      );
      await tap(
        tester,
        find.bySemanticsLabel(
          'Totalizador LECTURA INICIO. Toque para ver la carátula completa.',
        ),
      );
      expect(find.byType(InteractiveViewer), findsOneWidget);
      await tap(tester, find.byTooltip('Cerrar'));
      for (final entry in {
        'initial-totalizer': '10.345',
        'initial-needle': '0',
        'final-totalizer': '10.547',
        'final-needle': '0',
      }.entries) {
        await tester.ensureVisible(find.byKey(Key(entry.key)));
        await tester.enterText(find.byKey(Key(entry.key)), entry.value);
      }
      await tap(tester, find.byKey(const Key('confirm-readings')));
      expect(controller.page, WebDemoPage.result);
      expect(find.text('REPETIR PRUEBA $flow'), findsOneWidget);
      expect(find.text('Regla de decisión'), findsOneWidget);
      expect(find.text('|E| − U'), findsOneWidget);
      expect(find.byKey(const Key('run-indicators')), findsNothing);
      if (flow == 'Q1') await tap(tester, find.byKey(const Key('start-q2')));
    }
    await tap(tester, find.byKey(const Key('case-summary')));
    expect(find.text('GENERAR CSV · JSON · HTML · PDF'), findsOneWidget);
    expect(find.text('INFORMACIÓN TÉCNICA LOCAL'), findsNWidgets(2));
    await tap(tester, find.byKey(const Key('close-case')));
    await tap(tester, find.text('TERMINAR'));
    expect(controller.caseClosed, isTrue);
    expect(controller.history, hasLength(1));
    controller.showHistory();
    await tester.pumpAndSettle();
    await tap(tester, find.text('BORRAR HISTORIAL'));
    await tap(tester, find.text('CANCELAR'));
    expect(controller.history, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  test(
    'export reuses image bytes without dropping evidence or integrity',
    () async {
      evidenceBytes = fullResolutionPhoto;
      final controller = WebDemoController();
      addTearDown(controller.dispose);
      await controller.initialize();
      controller.beginCase(meter: 'EXPORT', bench: 'BENCH');
      controller.startMeasurement();
      controller.pulseCount = 202;
      controller.advanceSimulation(const Duration(microseconds: 1));
      controller.finishMeasurement();
      await controller.calculate(
        initialTotalizer: 0,
        initialNeedle: 0,
        finalTotalizer: 0,
        finalNeedle: 202,
      );
      final elapsed = Stopwatch()..start();
      evidenceLoads = 0;
      final stages = <String>[];
      final files = await DemoExport.generate(controller.currentCase, {
        0,
      }, onProgress: stages.add);
      expect(ascii.decode(files['pdf']!.take(4).toList()), '%PDF');
      expect(
        evidenceLoads,
        1,
        reason: 'Load and verify each asset once per export',
      );
      expect(stages, [
        'PREPARANDO HTML…',
        'GENERANDO PDF…',
        'PREPARANDO ARCHIVOS…',
      ]);
      expect(
        RegExp(
          r'/Subtype\s*/Image\b',
        ).allMatches(latin1.decode(files['pdf']!)).length,
        2,
        reason: 'One RGB image and its alpha mask, shared by every photo',
      );
      expect(
        '<div class="photo">'.allMatches(utf8.decode(files['html']!)).length,
        controller.latestSample!.photos.length,
      );
      evidenceBytes = ByteData(4);
      await expectLater(
        DemoExport.generate(controller.currentCase, {0}),
        throwsStateError,
      );
      Zone.current.print('Export completed ${elapsed.elapsed}');
    },
  );

  testWidgets('export failure leaves generating state and permits retry', (
    tester,
  ) async {
    final controller = await mount(tester);
    await tester.runAsync(() async {
      controller.beginCase(meter: 'RETRY', bench: 'BENCH');
      controller.startMeasurement();
      controller.pulseCount = 100;
      controller.advanceSimulation(const Duration(microseconds: 1));
      controller.finishMeasurement();
      await controller.calculate(
        initialTotalizer: 0,
        initialNeedle: 0,
        finalTotalizer: 0,
        finalNeedle: 100,
      );
      await controller.finishCase();
      controller.openReport(controller.history.single);
    });
    await tester.pumpAndSettle();
    final button = find.byKey(const Key('generate-exports'));
    await tester.ensureVisible(button);
    evidenceBytes = ByteData(4);
    await tester.runAsync(() async {
      await tester.tap(button);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(
      find.textContaining('No se pudieron generar los reportes:'),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    evidenceBytes = null;
    await tester.runAsync(() async {
      await tester.tap(button);
      final elapsed = Stopwatch()..start();
      while (elapsed.elapsed < const Duration(seconds: 15)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        if (find.text('ABRIR PDF').evaluate().isNotEmpty) break;
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('ABRIR PDF'), findsOneWidget);
    expect(
      find.textContaining('No se pudieron generar los reportes:'),
      findsNothing,
    );
  });

  testWidgets('generates all reports with full resolution photos in Chrome', (
    tester,
  ) async {
    evidenceBytes = fullResolutionPhoto;
    final controller = await mount(tester);
    await tester.runAsync(() async {
      controller.beginCase(meter: 'EXPORT-QA', bench: 'BANCO');
      for (var flow = 0; flow < 2; flow++) {
        if (flow > 0) controller.startQ2();
        controller.startMeasurement();
        controller.pulseCount = 202;
        controller.advanceSimulation(const Duration(microseconds: 1));
        controller.finishMeasurement();
        await controller.calculate(
          initialTotalizer: 0,
          initialNeedle: 0,
          finalTotalizer: 0,
          finalNeedle: 202,
        );
      }
      await controller.finishCase();
      controller.openReport(controller.history.single);
    });
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('generate-exports')));
    final elapsed = Stopwatch()..start();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('generate-exports')));
      while (elapsed.elapsed < const Duration(seconds: 60)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        if (find.text('ABRIR PDF').evaluate().isNotEmpty) break;
      }
    });
    Zone.current.print('Full-resolution export: ${elapsed.elapsed}');
    for (final format in ['CSV', 'JSON', 'HTML', 'PDF']) {
      expect(find.text('ABRIR $format'), findsOneWidget);
    }
    expect(find.text('GENERANDO…'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'leaving and resuming preserves active evidence and hides indicators',
    (tester) async {
      final controller = await mount(tester);
      controller.beginCase(meter: 'RESUME', bench: 'BENCH');
      controller.startMeasurement();
      controller.advanceSimulation(const Duration(seconds: 8));
      await tester.pump();
      final pulses = controller.pulseCount;
      final photos = controller.photos.length;
      await tap(tester, find.text('SALIR SIN DESCARTAR'));
      expect(find.byKey(const Key('run-indicators')), findsNothing);
      await tap(tester, find.text('REANUDAR PRUEBA'));
      await tap(tester, find.byKey(const Key('resume-sample')));
      expect(controller.pulseCount, pulses);
      expect(controller.photos.length, photos);
      expect(find.byKey(const Key('run-indicators')), findsOneWidget);
      controller.pauseToHome();
      await tester.pump();
    },
  );
}
