import 'dart:io';

import 'package:ddr001_diag_view_app/app/app_dependencies.dart';
import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:ddr001_diag_view_app/presentation/app_controller.dart';
import 'package:ddr001_diag_view_app/infrastructure/camera/camera_models.dart';
import 'package:ddr001_diag_view_app/infrastructure/camera/camera_port.dart';
import 'package:ddr001_diag_view_app/infrastructure/vision/vision_models.dart';
import 'package:ddr001_diag_view_app/infrastructure/vision/vision_pipeline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/presentation_fixture.dart';

void main() {
  late PresentationFixture fixture;
  late AppController controller;

  setUp(() async {
    fixture = await PresentationFixture.create();
    controller = AppController(fixture.dependencies);
  });

  tearDown(() async => fixture.dispose());

  test('bootstrap without session resolves login', () async {
    await controller.initialize();
    expect(controller.state.page, AppPage.login);
  });

  test('local login normalizes, auto-creates and persists session', () async {
    await controller.initialize();
    await controller.login(
      '  María José López  ',
      ' FIELD@AQUAFIM.MX ',
      '+52 449 123 4567',
    );
    expect(controller.state.user?.displayName, 'María José López');
    expect(controller.state.user?.email, 'field@aquafim.mx');
    expect(fixture.session.userId, controller.state.user?.id);
    final second = AppController(fixture.dependencies);
    await second.initialize();
    expect(second.state.page, AppPage.home);
    expect(second.state.user?.displayName, 'María José López');
  });

  test('existing named user keeps identity and is not duplicated', () async {
    final existing = User(
      id: 'existing-user',
      email: 'existing@aquafim.mx',
      phone: '4491234567',
      displayName: 'Nombre Original',
      createdAt: DateTime.utc(2026, 8, 1),
    );
    await fixture.dependencies.users.save(existing);

    await controller.login('Nombre Distinto', existing.email, existing.phone);

    expect(controller.state.user?.id, existing.id);
    expect(controller.state.user?.displayName, 'Nombre Original');
    expect(
      await fixture.database.select(fixture.database.users).get(),
      hasLength(1),
    );
  });

  test('legacy user without name is updated in place', () async {
    final legacy = User(
      id: 'legacy-user',
      email: 'legacy@aquafim.mx',
      phone: '4497654321',
      createdAt: DateTime.utc(2026, 8, 1),
    );
    await fixture.dependencies.users.save(legacy);

    await controller.login('Martín Osuna', legacy.email, legacy.phone);

    final persisted = await fixture.dependencies.users.getById(legacy.id);
    expect(controller.state.user?.id, legacy.id);
    expect(persisted?.displayName, 'Martín Osuna');
    expect(
      await fixture.database.select(fixture.database.users).get(),
      hasLength(1),
    );
  });

  test('session preferences store only active_user_id', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesSessionStore();
    await store.saveActiveUserId('user-1');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getKeys(), {'active_user_id'});
    expect(preferences.getString('active_user_id'), 'user-1');
  });

  test('logout clears session but preserves local cases', () async {
    await controller.login('Martín Osuna', 'field@aquafim.mx', '4491234567');
    final userId = controller.state.user!.id;
    await controller.identifyMeter(meterId: 'M-1', lpsApprox: 20);
    await controller.logout();
    expect(fixture.session.userId, isNull);
    expect(
      (await fixture.dependencies.users.getById(userId))?.displayName,
      'Martín Osuna',
    );
    expect(await fixture.dependencies.cases.listLocalCases(), hasLength(1));
  });

  test('identification accepts unlocated meter and all flow points', () async {
    await controller.login('Martín Osuna', 'field@aquafim.mx', '4491234567');
    for (final flow in FlowPoint.values) {
      controller.selectFlow(flow);
      await controller.identifyMeter(
        meterId: 'meter-${flow.name}',
        lpsApprox: 2.5,
      );
      expect(
        controller.state.meter?.externalStatus,
        ExternalMeterStatus.unknownOffline,
      );
      expect(controller.state.flow?.code, flow);
    }
  });

  test('method selector exposes only productive domain methods', () {
    expect(MeasurementMethod.values, [
      MeasurementMethod.visual,
      MeasurementMethod.manual,
      MeasurementMethod.led,
      MeasurementMethod.ble,
    ]);
  });

  test('starting sample freezes selected configuration', () async {
    await _prepare(controller, method: MeasurementMethod.manual);
    controller.updateSetup(
      litersPerPulse: 2,
      evidenceStepLiters: 20,
      uncertaintyLiters: .5,
    );
    await controller.startSample();
    final frozen = controller.state.sample!.configuration;
    controller.updateSetup(
      litersPerPulse: 9,
      evidenceStepLiters: 99,
      uncertaintyLiters: 9,
    );
    expect(frozen.litersPerPulse, 2);
    expect(frozen.evidenceStepLiters, 20);
    expect(controller.state.sample!.configuration.litersPerPulse, 2);
  });

  test('manual pulse increments count and persists Vref', () async {
    await _prepare(controller, method: MeasurementMethod.manual);
    controller.updateSetup(
      litersPerPulse: 2,
      evidenceStepLiters: 25,
      uncertaintyLiters: 1,
    );
    await controller.startSample();
    await controller.addManualPulse();
    await controller.addManualPulse();
    final persisted = await fixture.dependencies.samples.getById(
      controller.state.sample!.id,
    );
    expect(persisted?.pulseCount, 2);
    expect(persisted?.referenceLitersProgress, 4);
  });

  test('RUNNING sample is recovered by a new controller', () async {
    await _prepare(controller, method: MeasurementMethod.manual);
    await controller.startSample();
    await controller.addManualPulse();
    final restarted = AppController(fixture.dependencies);
    await restarted.initialize();
    expect(restarted.state.page, AppPage.recovery);
    expect(restarted.state.sample?.id, controller.state.sample?.id);
    await restarted.resumeSample();
    expect(restarted.state.page, AppPage.run);
  });

  test(
    'recovery reanalyzes existing unconfirmed START without new Evidence',
    () async {
      final dependencies = fixture.dependencies.copyWith(
        camera: _FakeCameraPort(),
        visualPipeline: _FakeVisualPipeline(),
      );
      controller = AppController(dependencies);
      await _prepare(controller, method: MeasurementMethod.visual);
      await controller.startSample();
      final photo = File('${fixture.directory.path}/recovery-start.jpg');
      await photo.writeAsBytes(List<int>.filled(900, 7));
      await controller.processCapturedPhoto(photo.path);
      final evidenceId = controller.state.readingProposal!.evidenceId;
      final restarted = AppController(dependencies);
      await restarted.initialize();
      await restarted.resumeSample();
      expect(restarted.state.page, AppPage.camera);
      expect(restarted.state.readingProposal!.evidenceId, evidenceId);
      expect(restarted.state.evidence, hasLength(1));
    },
  );

  test(
    'real capture flow associates START and FINAL evidence with readings',
    () async {
      final pipeline = _FakeVisualPipeline();
      final cameraDependencies = fixture.dependencies.copyWith(
        camera: _FakeCameraPort(),
        visualPipeline: pipeline,
      );
      controller = AppController(cameraDependencies);
      await _prepare(controller, method: MeasurementMethod.visual);
      await controller.startSample();
      expect(controller.state.page, AppPage.camera);
      expect(controller.state.capturePurpose, CapturePurpose.start);

      final start = File('${fixture.directory.path}/start.jpg');
      await start.writeAsBytes(List<int>.generate(900, (index) => index % 255));
      await controller.processCapturedPhoto(start.path);
      final discarded = controller.state.readingProposal!;
      await controller.recapturePhoto();
      expect(
        await cameraDependencies.evidence.getById(discarded.evidenceId),
        isNull,
      );
      expect(
        await cameraDependencies.fileStore.exists(discarded.evidencePath),
        isFalse,
      );
      await controller.processCapturedPhoto(start.path);
      final startEvidenceId = controller.state.readingProposal!.evidenceId;
      final countBeforeAdjustment = controller.state.evidence.length;
      const adjusted = DialVisionConfiguration(
        totalizerRegion: TotalizerRegion(NormalizedRect(.2, .1, .5, .2)),
        selectedDial: NormalizedCircle(.45, .6, .18),
        multiplier: .01,
        litersPerRevolution: 1,
        totalizerConfiguration: TotalizerConfiguration(
          digitCount: 3,
          decimalPlaces: 1,
          source: DialConfigurationSource.autoConfirmed,
        ),
      );
      await controller.reanalyzeRegions(adjusted);
      expect(controller.state.readingProposal!.evidenceId, startEvidenceId);
      expect(controller.state.evidence, hasLength(countBeforeAdjustment));
      await controller.confirmCameraReading(
        odometer: 47,
        needle: .1,
        corrected: false,
      );
      expect(
        controller.state.sample!.initialReading!.evidenceId,
        startEvidenceId,
      );
      expect(
        controller.state.sample!.initialReading!.source,
        ReadingSource.autoConfirmed,
      );
      expect(controller.state.sample!.meterFaceConfiguration!.dialRadius, .18);
      expect(
        controller.state.sample!.configuration.needleLitersPerRevolution,
        1,
      );

      final recovered = AppController(cameraDependencies);
      await recovered.initialize();
      expect(recovered.state.sample!.meterFaceConfiguration!.multiplier, .01);
      expect(
        recovered
            .state
            .sample!
            .meterFaceConfiguration!
            .totalizerConfiguration!
            .decimalPlaces,
        1,
      );

      await controller.setDevelopmentVisualReference(10);
      controller.requestFinalEvidence();
      final finalPhoto = File('${fixture.directory.path}/final.jpg');
      await finalPhoto.writeAsBytes(
        List<int>.generate(900, (index) => (index * 3) % 255),
      );
      await controller.processCapturedPhoto(finalPhoto.path);
      final finalEvidenceId = controller.state.readingProposal!.evidenceId;
      await controller.confirmCameraReading(
        odometer: 47,
        needle: .2,
        corrected: true,
      );
      expect(
        controller.state.sample!.finalReading!.evidenceId,
        finalEvidenceId,
      );
      expect(
        controller.state.sample!.finalReading!.source,
        ReadingSource.manual,
      );
      expect(controller.state.page, AppPage.readings);
      await controller.closeSample(
        initialOdometer: 47,
        initialNeedle: .1,
        finalOdometer: 47,
        finalNeedle: .21,
        visualReferenceLiters: 10,
        createDevelopmentEvidence: false,
      );
      expect(controller.state.sample!.status, SampleStatus.closedValid);
      expect(controller.state.sample!.finalReading!.reading.needleLiters, .21);
      expect(
        controller.state.sample!.finalReading!.source,
        ReadingSource.manual,
      );
      expect(
        controller.state.sample!.finalReading!.evidenceId,
        finalEvidenceId,
      );
    },
  );

  test(
    'VISUAL persists explicit reference without fictitious pulses',
    () async {
      await _prepare(controller, method: MeasurementMethod.visual);
      await controller.startSample();
      await controller.setDevelopmentVisualReference(125);
      expect(controller.state.sample?.pulseCount, 0);
      expect(controller.state.sample?.referenceLitersProgress, 125);
    },
  );

  test('development evidence closes sample with real Stage 1 result', () async {
    await _prepare(controller, method: MeasurementMethod.visual);
    await controller.startSample();
    await controller.closeSample(
      initialOdometer: 47,
      initialNeedle: 0,
      finalOdometer: 47,
      finalNeedle: 25,
      visualReferenceLiters: 125,
    );
    expect(controller.state.page, AppPage.result);
    expect(controller.state.sample?.status, SampleStatus.closedValid);
    expect(controller.state.sample?.result?.referenceLiters, 125);
    expect(controller.state.sample?.checksum, isNotEmpty);
  });

  test(
    'missing development evidence retains INVALID_EVIDENCE sample',
    () async {
      await _prepare(controller, method: MeasurementMethod.visual);
      await controller.startSample();
      await controller.closeSample(
        initialOdometer: 47,
        initialNeedle: 0,
        finalOdometer: 47,
        finalNeedle: 25,
        visualReferenceLiters: 125,
        createDevelopmentEvidence: false,
      );
      expect(controller.state.page, AppPage.invalidEvidence);
      expect(controller.state.sample?.status, SampleStatus.invalidEvidence);
    },
  );

  test(
    'repeat creates a later sample without deleting invalid history',
    () async {
      await _prepare(controller, method: MeasurementMethod.visual);
      await controller.startSample();
      final oldId = controller.state.sample!.id;
      await controller.closeSample(
        initialOdometer: 47,
        initialNeedle: 0,
        finalOdometer: 47,
        finalNeedle: 25,
        visualReferenceLiters: 125,
        createDevelopmentEvidence: false,
      );
      await controller.repeatSample();
      await controller.startSample();
      final samples = await fixture.dependencies.samples.listByFlow(
        controller.state.flow!.id,
      );
      expect(samples, hasLength(2));
      expect(samples.first.id, oldId);
      expect(samples.first.status, SampleStatus.invalidEvidence);
      expect(samples.last.sampleNumber, 2);
    },
  );
}

final class _FakeCameraPort implements CameraPort {
  @override
  Widget buildPreview() => const SizedBox();
  @override
  Future<CapturedPhoto> capture() => throw UnimplementedError();
  @override
  Future<void> dispose() async {}
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> openSettings() async => true;
  @override
  Future<void> pause() async {}
  @override
  Future<CameraPermissionState> requestPermission() async =>
      CameraPermissionState.granted;
  @override
  Future<void> resume() async {}
}

final class _FakeVisualPipeline implements VisualReadingPipeline {
  @override
  Future<VisualReadingProposal> analyze({
    required String evidenceId,
    required String evidencePath,
    DialVisionConfiguration? configuration,
  }) async => VisualReadingProposal(
    evidenceId: evidenceId,
    evidencePath: evidencePath,
    odometerRaw: '47',
    odometerValue: 47,
    needleLiters: 10,
    needleAngle: 306,
    needleConfidence: .8,
    warnings: const [],
    createdAt: DateTime.utc(2026, 8, 10),
    configuration: configuration ?? const DialVisionConfiguration(),
  );

  @override
  Future<void> dispose() async {}
}

Future<void> _prepare(
  AppController controller, {
  required MeasurementMethod method,
}) async {
  await controller.login('Martín Osuna', 'field@aquafim.mx', '4491234567');
  controller.selectFlow(FlowPoint.q3);
  await controller.identifyMeter(meterId: 'meter-stage3', lpsApprox: 20);
  controller.selectMethod(method);
}
