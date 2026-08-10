import 'package:ddr001_diag_view_app/app/app.dart';
import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:ddr001_diag_view_app/presentation/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/presentation_fixture.dart';

void main() {
  late PresentationFixture fixture;

  setUp(() async => fixture = await PresentationFixture.create());
  tearDown(() async => fixture.dispose());

  testWidgets('bootstrap navigates to login without session', (tester) async {
    await _pump(tester, fixture);
    expect(find.text('Acceso de técnico'), findsOneWidget);
    expect(find.byKey(const Key('login-display-name')), findsOneWidget);
    expect(find.byKey(const Key('login-email')), findsOneWidget);
  });

  testWidgets('bootstrap navigates home with persistent session', (
    tester,
  ) async {
    await fixture.seedSession();
    await _pump(tester, fixture);
    expect(find.text('NUEVA VERIFICACIÓN'), findsOneWidget);
    expect(find.text('Hola, Técnico de Campo'), findsOneWidget);
    expect(find.textContaining('Modo offline'), findsOneWidget);
  });

  testWidgets('login validates required name email and phone', (tester) async {
    await _pump(tester, fixture);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    expect(find.text('Ingresa tu nombre.'), findsOneWidget);
    expect(find.text('Ingresa un correo válido.'), findsOneWidget);
    expect(find.text('Ingresa un teléfono válido.'), findsOneWidget);
  });

  testWidgets('login auto-creates local user and opens home', (tester) async {
    await _pump(tester, fixture);
    await tester.enterText(
      find.byKey(const Key('login-display-name')),
      '  Martín Osuna  ',
    );
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'field@aquafim.mx',
    );
    await tester.enterText(find.byKey(const Key('login-phone')), '4491234567');
    await tester.tap(find.byKey(const Key('login-submit')));
    await _settle(tester);
    expect(find.text('NUEVA VERIFICACIÓN'), findsOneWidget);
    expect(find.text('Hola, Martín Osuna'), findsOneWidget);
    expect(fixture.session.userId, isNotNull);
  });

  testWidgets('identification displays Q1 Q2 Q3 Q4 semantics', (tester) async {
    await fixture.seedSession();
    await _pump(tester, fixture);
    await tester.tap(find.byKey(const Key('new-verification')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('flow-selector')));
    await _settle(tester);
    expect(find.text('Q1 — Caudal mínimo'), findsOneWidget);
    expect(find.text('Q2 — Caudal de transición'), findsOneWidget);
    expect(find.text('Q3 — Caudal permanente'), findsWidgets);
    expect(find.text('Q4 — Caudal de sobrecarga'), findsOneWidget);
  });

  testWidgets('method UI exposes VISUAL MANUAL LED BLE and no legacy method', (
    tester,
  ) async {
    await fixture.seedSession();
    await _pump(tester, fixture);
    await tester.tap(find.byKey(const Key('new-verification')));
    await _settle(tester);
    await tester.enterText(find.byKey(const Key('meter-id')), 'M-UI');
    await tester.tap(find.byKey(const Key('identify-continue')));
    await _settle(tester);
    expect(find.text('LECTURA VISUAL'), findsOneWidget);
    expect(find.text('MANUAL'), findsOneWidget);
    expect(find.text('LED'), findsOneWidget);
    expect(find.text('BLUETOOTH'), findsOneWidget);
    expect(find.text('Simulación'), findsNothing);
  });

  testWidgets('settings logout returns login and does not expose password', (
    tester,
  ) async {
    await fixture.seedSession();
    await _pump(tester, fixture);
    await tester.tap(find.byTooltip('Ajustes'));
    await _settle(tester);
    expect(find.text('Nombre'), findsOneWidget);
    expect(find.text('Técnico de Campo'), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Teléfono'), findsOneWidget);
    expect(find.textContaining('Contraseña'), findsNothing);
    await tester.tap(find.byKey(const Key('logout')));
    await _settle(tester);
    expect(find.text('Acceso de técnico'), findsOneWidget);
  });

  testWidgets('recovery displays and resumes the exact RUNNING sample', (
    tester,
  ) async {
    final controller = AppController(fixture.dependencies);
    await tester.runAsync(() async {
      await fixture.seedSession();
      await controller.initialize();
      controller.startIdentification();
      await controller.identifyMeter(meterId: 'REC-1', lpsApprox: 20);
      controller.selectMethod(MeasurementMethod.manual);
      await controller.startSample();
    });
    final sampleId = controller.state.sample!.id;
    await _pump(tester, fixture);
    expect(find.text('Prueba en curso'), findsWidgets);
    expect(find.text('REC-1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('resume-sample')));
    await _settle(tester);
    expect(find.byKey(const Key('manual-pulse')), findsOneWidget);
    expect(find.text('Medidor REC-1'), findsOneWidget);
    final persisted = await fixture.dependencies.samples.getById(sampleId);
    expect(persisted?.id, sampleId);
  });
}

Future<void> _pump(WidgetTester tester, PresentationFixture fixture) async {
  final controller = AppController(fixture.dependencies);
  await tester.runAsync(controller.initialize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDependenciesProvider.overrideWithValue(fixture.dependencies),
        appControllerProvider.overrideWith((ref) => controller),
      ],
      child: const Ddr001App(initialize: false),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 80)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}
