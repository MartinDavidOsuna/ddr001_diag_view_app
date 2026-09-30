import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:ddr001_diag_view_app/infrastructure/pulse/ble_discovery.dart';
import 'package:ddr001_diag_view_app/presentation/app_controller.dart';
import 'package:ddr001_diag_view_app/presentation/results/result_screens.dart';
import 'package:ddr001_diag_view_app/presentation/home/home_screens.dart';
import 'package:ddr001_diag_view_app/presentation/workflow/setup_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/presentation_fixture.dart';
import '../support/offline_fixture.dart';

void main() {
  late PresentationFixture fixture;
  late AppController controller;
  setUp(() async {
    fixture = await PresentationFixture.create();
    controller = AppController(fixture.dependencies);
  });
  tearDown(() async {
    await fixture.dispose();
  });

  Widget screen(Widget child) => ProviderScope(
    overrides: [
      appDependenciesProvider.overrideWithValue(fixture.dependencies),
      appControllerProvider.overrideWith((ref) => controller),
    ],
    child: MaterialApp(home: child),
  );

  test(
    'new default is 10 and each method freezes configured reference and hydrant K',
    () async {
      await fixture.seedSession();
      await controller.initialize();
      expect(controller.state.litersPerPulse, 10);
      expect(controller.state.hydrantLitersPerPulse, 10);
      for (final method in MeasurementMethod.values) {
        await controller.startIdentification();
        await controller.identifyMeter(
          meterId: 'meter-${method.name}',
          testBenchId: 'bench',
        );
        controller.selectMethod(method);
        if (method == MeasurementMethod.ble ||
            method == MeasurementMethod.led) {
          controller.selectBleDevice(
            const BleDeviceCandidate(
              id: 'test',
              name: 'DDR001-TEST',
              rssi: -30,
            ),
          );
        }
        controller.updateSetup(
          litersPerPulse: 7.5,
          hydrantLitersPerPulse: 12.5,
          evidenceStepLiters: 25,
          uncertaintyLiters: 1,
        );
        await controller.startSample();
        expect(
          controller.state.sample!.configuration.litersPerPulse,
          7.5,
          reason: method.name,
        );
        expect(
          controller.state.sample!.configuration.hydrantLitersPerPulse,
          12.5,
        );
      }
      controller.dispose();
    },
  );

  testWidgets('setup exposes both K values and rejects invalid pulse volume', (
    tester,
  ) async {
    await tester.pumpWidget(screen(const TestSetupScreen()));
    expect(find.byKey(const Key('config-reference-k')), findsOneWidget);
    final field = tester.widget<TextFormField>(
      find.byKey(const Key('config-reference-k')),
    );
    expect(field.controller!.text, '10.0');
    await tester.enterText(find.byKey(const Key('config-reference-k')), 'NaN');
    await tester.ensureVisible(find.byKey(const Key('start-sample')));
    await tester.tap(find.byKey(const Key('start-sample')));
    await tester.pump();
    expect(
      find.text('Introduce litros por pulso mayores que cero.'),
      findsOneWidget,
    );
    expect(controller.state.sample, isNull);
  });

  testWidgets(
    'history has bulk sync next to title and reports missing backend',
    (tester) async {
      await tester.runAsync(() async {
        await fixture.seedSession();
        await controller.initialize();
        await controller.showHistory();
      });
      await tester.pumpWidget(screen(const HistoryScreen()));
      expect(find.byKey(const Key('sync-all-cases')), findsOneWidget);
      await tester.tap(find.byKey(const Key('sync-all-cases')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Backend no configurado'), findsWidgets);
    },
  );

  testWidgets(
    'closed history opens correction dialog, saves and refreshes recalculated result',
    (tester) async {
      await tester.runAsync(() async {
        final seed = OfflineFixture(fixture.database, fixture.directory);
        await seed.seed();
        await seed.prepareClosable();
        await seed.sampleClosure.closeValid('sample-1', at: fixedTime);
        await seed.caseClosure.closeCase(
          caseId: 'case-1',
          requiredFlowPoints: {FlowPoint.q3},
          at: fixedTime,
        );
        await fixture.session.saveActiveUserId('user-1');
        await controller.initialize();
        await controller.openCaseFromHistory('case-1');
      });
      await tester.pumpWidget(screen(const CaseSummaryScreen()));
      await tester.ensureVisible(find.byKey(const Key('edit-sample-sample-1')));
      await tester.tap(find.byKey(const Key('edit-sample-sample-1')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('correction-finalTotal')),
        '47400',
      );
      await tester.enterText(
        find.byKey(const Key('correction-referenceK')),
        '2',
      );
      await tester.enterText(
        find.byKey(const Key('correction-reason')),
        'Error de dedo',
      );
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('save-correction')));
        // Await the database-backed dialog operation without virtual-time IO.
        while (controller.state.busy) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(controller.state.errorMessage, isNull);
      expect(controller.state.samples.single.result!.indicatedLiters, 400);
      expect(controller.state.samples.single.result!.referenceLiters, 400);
      expect(
        controller.state.activeCase!.overallVerdict,
        OverallVerdict.approved,
      );
      expect(controller.state.syncMessage, 'Pendiente (editada)');
      expect(find.byKey(const Key('save-correction')), findsNothing);
    },
  );
}
