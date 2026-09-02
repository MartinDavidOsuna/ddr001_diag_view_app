import 'package:ddr001_diag_view_app/app/app.dart';
import 'package:ddr001_diag_view_app/app/app_dependencies.dart';
import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:ddr001_diag_view_app/presentation/home/manual_screen.dart';
import 'package:ddr001_diag_view_app/presentation/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../support/presentation_fixture.dart';

void main() {
  late PresentationFixture fixture;

  setUp(() async {
    PackageInfo.setMockInitialValues(
      appName: 'DDR001',
      packageName: 'mx.aquafim.ddr001',
      version: '1.3.4',
      buildNumber: '14',
      buildSignature: '',
    );
    fixture = await PresentationFixture.create();
  });
  tearDown(() async => fixture.dispose());

  testWidgets('bootstrap navigates to login without session', (tester) async {
    await _pump(tester, fixture);
    expect(find.text('Acceso de técnico'), findsOneWidget);
    expect(find.byKey(const Key('login-display-name')), findsOneWidget);
    expect(find.byKey(const Key('login-email')), findsOneWidget);
    expect(find.text('VERIFICADOR FUNCIONAL'), findsOneWidget);
    expect(find.text('Versión: 1.3.4+14'), findsOneWidget);
  });

  testWidgets('bootstrap navigates home with persistent session', (
    tester,
  ) async {
    await fixture.seedSession();
    await _pump(tester, fixture);
    expect(find.text('NUEVA VERIFICACIÓN'), findsOneWidget);
    expect(find.text('Hola, Técnico de Campo'), findsOneWidget);
    expect(find.textContaining('Modo offline'), findsOneWidget);
    expect(find.text('Versión: 1.3.4+14'), findsOneWidget);
    expect(find.byKey(const Key('aquafim-logo-symbol')), findsOneWidget);
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

  testWidgets('identification omits manually entered Q1 and Q2 flow', (
    tester,
  ) async {
    await fixture.seedSession();
    await _pump(tester, fixture);
    await tester.tap(find.byKey(const Key('new-verification')));
    await _settle(tester);
    expect(find.byKey(const Key('flow-selector')), findsNothing);
    expect(find.byKey(const Key('q1-lps-input')), findsNothing);
    expect(find.byKey(const Key('q2-lps-input')), findsNothing);
    expect(find.byKey(const Key('capture-gps')), findsOneWidget);
    expect(
      find.text('* Dato informativo para validación interna'),
      findsOneWidget,
    );
  });

  testWidgets('MANUAL is selectable without BLE hardware', (tester) async {
    await fixture.seedSession();
    await _pump(tester, fixture);
    await tester.tap(find.byKey(const Key('new-verification')));
    await _settle(tester);
    await tester.enterText(find.byKey(const Key('meter-id')), 'M-UI');
    await tester.enterText(find.byKey(const Key('test-bench-id')), 'BANCO-UI');
    await tester.ensureVisible(find.byKey(const Key('identify-continue')));
    await tester.tap(find.byKey(const Key('identify-continue')));
    await _settle(tester);
    expect(find.text('Ubicación no registrada'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-without-gps')));
    await _settle(tester);
    expect(find.text('LECTURA VISUAL'), findsOneWidget);
    expect(find.text('LECTURA VISUAL · DESACTIVADA'), findsNothing);
    expect(find.byKey(const Key('method-manual')), findsOneWidget);
    expect(find.byKey(const Key('method-led')), findsNothing);
    expect(find.text('BLUETOOTH'), findsOneWidget);
    expect(find.text('Simulación'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('method-continue')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('method-manual')));
    await tester.pump();
    expect(find.textContaining('Captura manual de pulsos'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('method-continue')))
          .onPressed,
      isNotNull,
    );
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
    expect(find.byKey(const Key('manual-de-uso')), findsOneWidget);
    expect(find.text('Versión: 1.3.4+14'), findsOneWidget);
    expect(find.byKey(const Key('visual-calibration-debug')), findsNothing);
    expect(find.textContaining('Contraseña'), findsNothing);
    await tester.tap(find.byKey(const Key('logout')));
    await _settle(tester);
    expect(find.text('Acceso de técnico'), findsOneWidget);
  });

  testWidgets('server-only placeholders stay hidden without configuration', (
    tester,
  ) async {
    await fixture.seedSession();
    await _pump(tester, fixture);
    await tester.tap(find.byKey(const Key('new-verification')));
    await _settle(tester);
    expect(find.textContaining('Pendiente de consulta'), findsNothing);
    expect(find.textContaining('Pendiente de servidor'), findsNothing);
    expect(find.textContaining('Consultando...'), findsNothing);
  });

  testWidgets(
    'GPS action shows real coordinates and accuracy from local port',
    (tester) async {
      await fixture.seedSession();
      final dependencies = fixture.dependencies.copyWith(
        location: _WidgetLocation(),
      );
      final controller = AppController(dependencies);
      await tester.runAsync(controller.initialize);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDependenciesProvider.overrideWithValue(dependencies),
            appControllerProvider.overrideWith((ref) => controller),
          ],
          child: const Ddr001App(initialize: false),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('new-verification')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('capture-gps')));
      await _settle(tester);
      expect(find.textContaining('29.072900'), findsOneWidget);
      expect(find.textContaining('Precisión ±4 m'), findsOneWidget);
    },
  );

  testWidgets('manual asset contains every required operating subject', (
    tester,
  ) async {
    final manual = await tester.runAsync(
      () => rootBundle.loadString('assets/manual/manual_de_uso.md'),
    );
    for (final subject in <String>[
      'Selección del totalizador',
      'Selección del dial',
      'GPS',
      'LECTURA VISUAL',
      'MANUAL',
      'LED',
      'BLUETOOTH',
      'Reportes',
      'Resolución de problemas',
      'Glosario',
    ]) {
      expect(manual, contains(subject));
    }
  });

  testWidgets('bundled Manual de uso renders offline without a WebView', (
    tester,
  ) async {
    final controller = AppController(fixture.dependencies);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDependenciesProvider.overrideWithValue(fixture.dependencies),
          appControllerProvider.overrideWith((ref) => controller),
        ],
        child: MaterialApp(
          home: ManualScreen(
            packageInfoLoader: () async => PackageInfo(
              appName: 'DDR001',
              packageName: 'mx.aquafim.ddr001',
              version: '1.0.0',
              buildNumber: '1',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('manual-content')), findsOneWidget);
    expect(find.textContaining('Propósito de la aplicación'), findsWidgets);
    expect(find.byType(Scrollable), findsWidgets);
  });

  testWidgets('recovery displays and resumes the exact RUNNING sample', (
    tester,
  ) async {
    final controller = AppController(fixture.dependencies);
    await tester.runAsync(() async {
      await fixture.seedSession();
      await controller.initialize();
      await controller.startIdentification();
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

final class _WidgetLocation implements LocationPort {
  @override
  Future<GpsSnapshot> capture() async => GpsSnapshot(
    latitude: 29.0729,
    longitude: -110.9559,
    accuracyMeters: 4.2,
    capturedAt: DateTime.utc(2026, 8, 16),
  );
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
