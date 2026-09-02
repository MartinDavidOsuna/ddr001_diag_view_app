import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ddr001_diag_view_app/app/app_dependencies.dart';
import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:ddr001_diag_view_app/presentation/app_controller.dart';
import 'package:ddr001_diag_view_app/infrastructure/camera/camera_models.dart';
import 'package:ddr001_diag_view_app/infrastructure/camera/camera_port.dart';
import 'package:ddr001_diag_view_app/infrastructure/pulse/ble_discovery.dart';
import 'package:ddr001_diag_view_app/infrastructure/vision/vision_models.dart';
import 'package:ddr001_diag_view_app/infrastructure/vision/vision_pipeline.dart';
import 'package:ddr001_diag_view_app/infrastructure/remote/remote_api.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

  test(
    'manual ESP32 disconnect clears selection outside an active sample',
    () async {
      const device = BleDeviceCandidate(
        id: 'AA:BB:CC:DD:EE:FF',
        name: 'DDR001-PULSE-TEST',
        rssi: -42,
      );
      controller.selectBleDevice(device);
      expect(controller.state.selectedBleDevice, device);
      expect(controller.state.hardwareState, HardwareState.ready);

      await controller.disconnectBleDevice();

      expect(controller.state.selectedBleDevice, isNull);
      expect(controller.state.hardwareState, HardwareState.notConnected);
    },
  );

  test('Rene and Omar are accepted as local master identities', () async {
    final service = MasterAccessAuthService(
      primary: const _RejectingAuthService(),
      local: LocalAuthService(fixture.dependencies.users, fixture.session),
      users: fixture.dependencies.users,
      sessionStore: fixture.session,
      tokens: _FakeTokenStore(),
    );
    for (final identity in MasterAccessIdentity.identities.skip(1)) {
      final user = await service.login(
        displayName: identity.displayName,
        email: identity.email,
        phone: identity.phone,
      );
      expect(user.displayName, identity.displayName);
      expect(user.email, identity.email);
    }
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

  test(
    'master identity creates a local session without primary auth',
    () async {
      final service = MasterAccessAuthService(
        primary: const _RejectingAuthService(),
        local: LocalAuthService(fixture.dependencies.users, fixture.session),
        users: fixture.dependencies.users,
        sessionStore: fixture.session,
        tokens: _FakeTokenStore(),
      );

      final user = await service.login(
        displayName: ' Martin Osuna ',
        email: ' MARTINOSUNA@AGRIENLACE.COM ',
        phone: '999 999 9999',
      );

      expect(user.displayName, MasterAccessIdentity.displayName);
      expect(user.email, MasterAccessIdentity.email);
      expect(user.phone, MasterAccessIdentity.phone);
      expect(fixture.session.userId, user.id);
    },
  );

  test('non-master identity still uses primary auth policy', () async {
    final service = MasterAccessAuthService(
      primary: const _RejectingAuthService(),
      local: LocalAuthService(fixture.dependencies.users, fixture.session),
      users: fixture.dependencies.users,
      sessionStore: fixture.session,
      tokens: _FakeTokenStore(),
    );

    expect(
      () => service.login(
        displayName: 'Otro Usuario',
        email: 'otro@agrienlace.com',
        phone: '9999999999',
      ),
      throwsStateError,
    );
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

  test('identification persists mandatory Q1 and Q2 flow points', () async {
    await controller.login('Martín Osuna', 'field@aquafim.mx', '4491234567');
    await controller.identifyMeter(
      meterId: 'meter-q1-q2',
      q1LpsApprox: 1.5,
      q2LpsApprox: 1.0,
    );
    final flows = await fixture.dependencies.flows.listByCase(
      controller.state.activeCase!.id,
    );
    expect(
      flows.map((flow) => flow.code),
      containsAll([FlowPoint.q1, FlowPoint.q2]),
    );
    expect(
      flows.singleWhere((flow) => flow.code == FlowPoint.q1).lpsApprox,
      isNull,
    );
    expect(
      flows.singleWhere((flow) => flow.code == FlowPoint.q2).lpsApprox,
      isNull,
    );
    expect(controller.state.flow?.code, FlowPoint.q1);
  });

  test(
    'new verification creates another case and preserves BLE selection',
    () async {
      await controller.login('Martín Osuna', 'field@aquafim.mx', '4491234567');
      const device = BleDeviceCandidate(
        id: 'AA:BB:CC:DD:EE:FF',
        name: 'DDR001-PULSE-TEST',
        rssi: -42,
      );
      controller.selectBleDevice(device);
      await controller.identifyMeter(meterId: 'meter-new-case', lpsApprox: 20);
      final firstCaseId = controller.state.activeCase!.id;

      await controller.startIdentification();

      expect(controller.state.activeCase, isNull);
      expect(controller.state.meter, isNull);
      expect(controller.state.sample, isNull);
      expect(controller.state.selectedBleDevice, device);
      expect(controller.state.hardwareState, HardwareState.ready);

      await controller.identifyMeter(meterId: 'meter-new-case', lpsApprox: 20);

      expect(controller.state.activeCase!.id, isNot(firstCaseId));
      expect(await fixture.dependencies.cases.listLocalCases(), hasLength(2));
    },
  );

  test('method selector exposes only productive domain methods', () {
    expect(MeasurementMethod.values, [
      MeasurementMethod.visual,
      MeasurementMethod.manual,
      MeasurementMethod.led,
      MeasurementMethod.ble,
      MeasurementMethod.simulation,
    ]);
  });

  test('starting sample freezes selected configuration', () async {
    await _prepare(controller, method: MeasurementMethod.manual);
    controller.updateSetup(
      litersPerPulse: 2,
      evidenceStepLiters: 20,
      uncertaintyLiters: .5,
      litersPerOdometerUnit: 100,
      needleLitersPerRevolution: 1,
      totalizerIntegerDigits: 5,
      totalizerDecimalPlaces: 2,
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
    expect(frozen.litersPerOdometerUnit, 100);
    expect(frozen.needleLitersPerRevolution, 1);
    expect(controller.state.sample!.configuration.litersPerPulse, 2);
  });

  test('manual pulse increments count and persists Vref', () async {
    expect(fixture.dependencies.bleDiscovery, isNull);
    expect(fixture.dependencies.backendSyncConfigured, isFalse);
    await _prepare(controller, method: MeasurementMethod.manual);
    controller.updateSetup(
      litersPerPulse: 2,
      evidenceStepLiters: 25,
      uncertaintyLiters: 1,
    );
    await controller.startSample();
    await controller.beginMeasurement();
    final armedAt = controller.state.sample!.startedAt!;
    await controller.addManualPulse();
    final firstPulseAt = controller.state.sample!.startedAt!;
    await controller.addManualPulse();
    final persisted = await fixture.dependencies.samples.getById(
      controller.state.sample!.id,
    );
    expect(persisted?.pulseCount, 2);
    expect(persisted?.referenceLitersProgress, 4);
    expect(controller.state.selectedBleDevice, isNull);
    expect(firstPulseAt.isBefore(armedAt), isFalse);
    expect(persisted?.startedAt, firstPulseAt);
  });

  test(
    'manual acquisition cannot pulse before the required START boundary',
    () async {
      final dependencies = fixture.dependencies.copyWith(
        camera: _FakeCameraPort(),
        visualPipeline: _FakeVisualPipeline(),
      );
      controller = AppController(dependencies);
      expect(dependencies.bleDiscovery, isNull);
      await _prepare(controller, method: MeasurementMethod.manual);
      await controller.startSample();
      await controller.confirmLiveCameraPreparation(
        const DialVisionConfiguration(
          totalizerRegion: TotalizerRegion(NormalizedRect(.1, .1, .5, .2)),
          selectedDial: NormalizedCircle(.6, .6, .15),
        ),
      );

      await controller.addManualPulse();
      expect(controller.state.sample?.pulseCount, 0);
      expect(controller.state.measurementStarted, isFalse);

      await controller.beginMeasurement();
      expect(controller.state.measurementStarted, isTrue);
      await controller.addManualPulse();
      expect(controller.state.sample?.pulseCount, 1);
    },
  );

  test(
    'pulse threshold captures required intermediate evidence automatically',
    () async {
      final camera = _FakeCameraPort();
      final dependencies = fixture.dependencies.copyWith(
        camera: camera,
        visualPipeline: _FakeVisualPipeline(),
      );
      controller = AppController(dependencies);
      await _prepare(controller, method: MeasurementMethod.manual);
      controller.updateSetup(
        litersPerPulse: 1,
        evidenceStepLiters: 2,
        uncertaintyLiters: 1,
      );
      await controller.startSample();
      await controller.confirmLiveCameraPreparation(
        const DialVisionConfiguration(
          totalizerRegion: TotalizerRegion(NormalizedRect(.1, .1, .5, .2)),
          selectedDial: NormalizedCircle(.6, .6, .15),
        ),
      );
      await controller.beginMeasurement();
      await controller.addManualPulse();
      expect(controller.state.page, AppPage.run);
      await controller.addManualPulse();
      expect(controller.state.page, AppPage.run);
      expect(controller.state.capturePurpose, isNull);
      expect(camera.captureCount, 2);
      final evidence = await dependencies.evidence.listBySample(
        controller.state.sample!.id,
      );
      expect(
        evidence.where((item) => item.type == EvidenceType.intermediate),
        hasLength(1),
      );
    },
  );

  test('RUNNING sample is recovered by a new controller', () async {
    final camera = _FakeCameraPort();
    final dependencies = fixture.dependencies.copyWith(
      camera: camera,
      visualPipeline: _FakeVisualPipeline(),
    );
    controller = AppController(dependencies);
    await _prepare(controller, method: MeasurementMethod.manual);
    await controller.startSample();
    await controller.confirmLiveCameraPreparation(
      const DialVisionConfiguration(
        totalizerRegion: TotalizerRegion(NormalizedRect(.1, .1, .5, .2)),
        selectedDial: NormalizedCircle(.6, .6, .15),
      ),
    );
    await controller.beginMeasurement();
    await controller.addManualPulse();
    await controller.addManualPulse();
    final evidenceBefore = await fixture.dependencies.evidence.listBySample(
      controller.state.sample!.id,
    );
    final restarted = AppController(dependencies);
    await restarted.initialize();
    expect(restarted.state.page, AppPage.recovery);
    expect(restarted.state.sample?.id, controller.state.sample?.id);
    expect(restarted.state.sample?.pulseCount, 2);
    expect(restarted.state.sample?.referenceLitersProgress, 2);
    await restarted.resumeSample();
    expect(restarted.state.page, AppPage.run);
    expect(restarted.state.sample?.pulseCount, 2);
    expect(
      await dependencies.evidence.listBySample(
        restarted.state.sample!.id,
      ),
      hasLength(evidenceBefore.length),
    );
    await restarted.addManualPulse();
    expect(restarted.state.sample?.pulseCount, 3);
  });

  test(
    'recovery restores technician-selected START regions without new Evidence',
    () async {
      final dependencies = fixture.dependencies.copyWith(
        camera: _FakeCameraPort(),
        visualPipeline: _FakeVisualPipeline(),
      );
      controller = AppController(dependencies);
      await _prepare(controller, method: MeasurementMethod.visual);
      controller.updateSetup(
        litersPerPulse: 1,
        evidenceStepLiters: 25,
        uncertaintyLiters: 1,
        needleLitersPerRevolution: 1000,
      );
      await controller.startSample();
      const selected = DialVisionConfiguration(
        totalizerRegion: TotalizerRegion(NormalizedRect(.08, .72, .44, .16)),
        selectedDial: NormalizedCircle(.78, .22, .14),
        multiplier: 10,
        litersPerRevolution: 1000,
        totalizerConfiguration: TotalizerConfiguration(
          digitCount: 6,
          decimalPlaces: 2,
        ),
      );
      await controller.confirmLiveCameraPreparation(selected);
      final restarted = AppController(dependencies);
      await restarted.initialize();
      await restarted.resumeSample();
      expect(restarted.state.page, AppPage.run);
      final restored = restarted.state.sample!.meterFaceConfiguration!;
      expect(restored.totalizerLeft, .08);
      expect(restored.totalizerTop, .72);
      expect(restored.dialCenterX, .78);
      expect(restored.dialCenterY, .22);
      expect(restored.multiplier, 10);
      expect(restored.litersPerRevolution, 1000);
      expect(
        restarted.state.sample!.configuration.needleLitersPerRevolution,
        1000,
      );
      expect(restored.totalizerConfiguration?.decimalPlaces, 2);
      expect(restarted.state.evidence, isEmpty);
    },
  );

  test('camera zoom is frozen and recovered for the running sample', () async {
    final dependencies = fixture.dependencies.copyWith(
      camera: _FakeCameraPort(),
      visualPipeline: _FakeVisualPipeline(),
    );
    controller = AppController(dependencies);
    await _prepare(controller, method: MeasurementMethod.visual);
    await controller.startSample();
    await controller.setCameraZoom(2.5);
    expect(controller.state.sample!.configuration.cameraZoomLevel, 2.5);

    final restarted = AppController(dependencies);
    await restarted.initialize();
    expect(restarted.state.sample!.configuration.cameraZoomLevel, 2.5);
    expect(restarted.state.cameraZoomLevel, 2.5);
    await restarted.resumeSample();
    expect(restarted.state.cameraZoomLevel, 2.5);
  });

  test('live camera preparation freezes regions without a photo', () async {
    final dependencies = fixture.dependencies.copyWith(
      camera: _FakeCameraPort(),
      visualPipeline: _FakeVisualPipeline(),
    );
    controller = AppController(dependencies);
    await _prepare(controller, method: MeasurementMethod.visual);
    await controller.startSample();
    const configuration = DialVisionConfiguration(
      totalizerRegion: TotalizerRegion(NormalizedRect(.18, .22, .42, .12)),
      selectedDial: NormalizedCircle(.7, .62, .11),
    );

    await controller.confirmLiveCameraPreparation(configuration);

    expect(controller.state.page, AppPage.run);
    expect(controller.state.evidence, isEmpty);
    expect(controller.state.points, isEmpty);
    expect(controller.state.sample!.meterFaceConfiguration!.totalizerLeft, .18);
    expect(controller.state.sample!.meterFaceConfiguration!.dialCenterX, .7);
  });

  test(
    'workflow back returns one step without discarding case state',
    () async {
      await controller.login('Martín Osuna', 'field@aquafim.mx', '4491234567');
      await controller.identifyMeter(
        meterId: 'BACK-1',
        q1LpsApprox: 1.7,
        q2LpsApprox: 1.1,
      );
      expect(controller.state.page, AppPage.method);
      controller.goBack();
      expect(controller.state.page, AppPage.identification);
      expect(controller.state.activeCase, isNotNull);
      expect(controller.state.identificationMeterId, 'BACK-1');
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
      initialTotalizer: 47,
      initialNeedle: 25,
      initialMeterTotalLiters: 100,
      finalTotalizer: 47,
      finalNeedle: 50,
      finalMeterTotalLiters: 125,
      visualReferenceLiters: 125,
    );
    expect(controller.state.page, AppPage.result);
    expect(controller.state.sample?.status, SampleStatus.closedValid);
    expect(controller.state.sample?.result?.referenceLiters, 125);
    expect(controller.state.sample?.initialReading?.reading.odometerUnits, 47);
    expect(controller.state.sample?.initialReading?.reading.needleLiters, 25);
    expect(controller.state.sample?.finalReading?.reading.odometerUnits, 47);
    expect(controller.state.sample?.finalReading?.reading.needleLiters, 50);
    expect(controller.state.sample?.manualIndicatedLiters, 25);
    expect(controller.state.sample?.result?.indicatedLiters, 25);
    expect(controller.state.sample?.checksum, isNotEmpty);
  });

  test(
    '1000 L revolution accepts accumulated total 5000 and needle 500',
    () async {
      await _prepare(controller, method: MeasurementMethod.visual);
      controller.updateSetup(
        litersPerPulse: 1,
        evidenceStepLiters: 2500,
        uncertaintyLiters: 1,
        needleLitersPerRevolution: 1000,
      );
      await controller.startSample();
      await controller.closeSample(
        initialTotalizer: 0,
        initialNeedle: 0,
        initialMeterTotalLiters: 0,
        finalTotalizer: 5,
        finalNeedle: 500,
        finalMeterTotalLiters: 5000,
        visualReferenceLiters: 5000,
      );

      expect(controller.state.errorMessage, isNull);
      expect(controller.state.sample?.status, SampleStatus.closedValid);
      expect(controller.state.sample?.manualIndicatedLiters, 5000);
      expect(
        controller.state.sample?.configuration.needleLitersPerRevolution,
        1000,
      );
    },
  );

  test('1000 L revolution rejects needle position 5000', () async {
    await _prepare(controller, method: MeasurementMethod.visual);
    controller.updateSetup(
      litersPerPulse: 1,
      evidenceStepLiters: 2500,
      uncertaintyLiters: 1,
      needleLitersPerRevolution: 1000,
    );
    await controller.startSample();
    await controller.closeSample(
      initialTotalizer: 0,
      initialNeedle: 0,
      initialMeterTotalLiters: 0,
      finalTotalizer: 5,
      finalNeedle: 5000,
      finalMeterTotalLiters: 5000,
      visualReferenceLiters: 5000,
    );

    expect(controller.state.errorMessage, contains('menor que 1000.0 L'));
    expect(controller.state.sample?.status, SampleStatus.running);
  });

  test('FINAL evidence freezes pulse endpoint used by closure', () async {
    await _prepare(controller, method: MeasurementMethod.manual);
    await controller.startSample();
    await controller.beginMeasurement();
    for (var index = 0; index < 27; index++) {
      await controller.addManualPulse();
    }
    final sample = controller.state.sample!;
    final capture = fixture.dependencies.evidenceCapture;
    await capture.capture(
      caseId: controller.state.activeCase!.id,
      sample: sample,
      type: EvidenceType.start,
      volumeRefLiters: 0,
      pulseCount: 0,
    );
    await capture.capture(
      caseId: controller.state.activeCase!.id,
      sample: sample,
      type: EvidenceType.intermediate,
      volumeRefLiters: 25,
      pulseCount: 25,
    );
    await capture.capture(
      caseId: controller.state.activeCase!.id,
      sample: sample,
      type: EvidenceType.finalEvidence,
      volumeRefLiters: 26,
      pulseCount: 26,
    );

    await controller.closeSample(
      initialTotalizer: 1,
      initialNeedle: 0,
      initialMeterTotalLiters: 100,
      finalTotalizer: 1,
      finalNeedle: 26,
      finalMeterTotalLiters: 126,
      createDevelopmentEvidence: false,
    );

    expect(controller.state.sample?.status, SampleStatus.closedValid);
    expect(controller.state.sample?.pulseCount, 26);
    expect(controller.state.sample?.result?.referenceLiters, 26);
  });

  test(
    'final action captures FINAL first and rejects subsequent pulses',
    () async {
      final camera = _FakeCameraPort();
      final dependencies = fixture.dependencies.copyWith(
        camera: camera,
        visualPipeline: _FakeVisualPipeline(),
      );
      controller = AppController(dependencies);
      await _prepare(controller, method: MeasurementMethod.manual);
      controller.updateSetup(
        litersPerPulse: 1,
        evidenceStepLiters: 1,
        uncertaintyLiters: 1,
      );
      await controller.startSample();
      await controller.confirmLiveCameraPreparation(
        const DialVisionConfiguration(
          totalizerRegion: TotalizerRegion(NormalizedRect(.1, .1, .5, .2)),
          selectedDial: NormalizedCircle(.6, .6, .15),
        ),
      );
      await controller.beginMeasurement();
      await controller.addManualPulse();
      await controller.addManualPulse();
      final capturesBeforeFinal = camera.captureCount;

      await controller.requestFinalEvidence();
      final frozenPulses = controller.state.sample!.pulseCount;
      await controller.addManualPulse();

      final evidence = await dependencies.evidence.listBySample(
        controller.state.sample!.id,
      );
      expect(camera.captureCount, capturesBeforeFinal + 1);
      expect(evidence.last.type, EvidenceType.finalEvidence);
      expect(controller.state.sample!.pulseCount, frozenPulses);
      expect(controller.state.measurementStarted, isFalse);

      final evidenceCount = evidence.length;
      await controller.processCapturedPhoto(camera.lastCapturePath);
      expect(controller.state.page, AppPage.readings);
      expect(controller.state.errorMessage, isNull);
      expect(
        await dependencies.evidence.listBySample(controller.state.sample!.id),
        hasLength(evidenceCount),
      );
    },
  );

  test(
    'missing development evidence retains INVALID_EVIDENCE sample',
    () async {
      await _prepare(controller, method: MeasurementMethod.visual);
      await controller.startSample();
      await controller.closeSample(
        initialTotalizer: 47,
        initialNeedle: 25,
        initialMeterTotalLiters: 100,
        finalTotalizer: 47,
        finalNeedle: 50,
        finalMeterTotalLiters: 125,
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
        initialTotalizer: 47,
        initialNeedle: 25,
        initialMeterTotalLiters: 100,
        finalTotalizer: 47,
        finalNeedle: 50,
        finalMeterTotalLiters: 125,
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

  test('Q2 starts directly and inherits Q1 camera configuration', () async {
    await _prepare(controller, method: MeasurementMethod.visual);
    await controller.startSample();
    const face = DialVisionConfiguration(
      totalizerRegion: TotalizerRegion(NormalizedRect(.12, .2, .48, .14)),
      selectedDial: NormalizedCircle(.72, .65, .13),
    );
    await controller.confirmLiveCameraPreparation(face);
    await controller.setDevelopmentVisualReference(125);
    await controller.closeSample(
      initialTotalizer: 1,
      initialNeedle: 0,
      initialMeterTotalLiters: 100,
      finalTotalizer: 1,
      finalNeedle: 25,
      finalMeterTotalLiters: 225,
      visualReferenceLiters: 125,
    );

    await controller.anotherSample();

    expect(controller.state.page, AppPage.run);
    expect(controller.state.sample?.configuration.flowPoint, FlowPoint.q2);
    expect(controller.state.sample?.meterFaceConfiguration?.totalizerLeft, .12);
    expect(controller.state.sample?.meterFaceConfiguration?.dialCenterX, .72);
    expect(controller.state.evidence, isEmpty);
  });

  test('repeat starts directly and reuses frozen camera regions', () async {
    await _prepare(controller, method: MeasurementMethod.visual);
    await controller.startSample();
    const face = DialVisionConfiguration(
      totalizerRegion: TotalizerRegion(NormalizedRect(.15, .25, .45, .12)),
      selectedDial: NormalizedCircle(.68, .6, .12),
    );
    await controller.confirmLiveCameraPreparation(face);
    await controller.setDevelopmentVisualReference(125);
    await controller.closeSample(
      initialTotalizer: 1,
      initialNeedle: 0,
      initialMeterTotalLiters: 100,
      finalTotalizer: 1,
      finalNeedle: 25,
      finalMeterTotalLiters: 225,
      visualReferenceLiters: 125,
    );

    await controller.repeatSample();

    expect(controller.state.page, AppPage.run);
    expect(controller.state.sample?.sampleNumber, 2);
    expect(controller.state.sample?.meterFaceConfiguration?.totalizerLeft, .15);
    expect(controller.state.sample?.meterFaceConfiguration?.dialCenterX, .68);
  });

  test('GPS success is captured without a network dependency', () async {
    final gps = GpsSnapshot(
      latitude: 29.0729,
      longitude: -110.9559,
      accuracyMeters: 4.5,
      capturedAt: DateTime.utc(2026, 8, 16),
    );
    final locationController = AppController(
      fixture.dependencies.copyWith(location: _FakeLocation(result: gps)),
    );
    await locationController.captureGps();
    expect(locationController.state.gps, same(gps));
    expect(locationController.state.gpsCaptureState, GpsCaptureState.captured);
  });

  test(
    'configured hydrant capability reports Consultando only during request',
    () async {
      final response = Completer<http.Response>();
      final dependencies = fixture.dependencies.copyWith(
        remoteApi: RemoteApiClient(
          baseUrl: 'https://configured.invalid',
          client: MockClient((request) => response.future),
        ),
        tokenStore: _FakeTokenStore(),
      );
      final remoteController = AppController(dependencies);
      await remoteController.login('Técnico', 'field@aquafim.mx', '4491234567');
      final lookup = remoteController.identifyMeter(
        meterId: 'H-100',
        lpsApprox: 20,
      );
      await Future<void>.delayed(Duration.zero);
      expect(remoteController.state.hydrantLookupInProgress, isTrue);
      response.complete(
        http.Response(jsonEncode({'status': 'NOT_FOUND', 'data': null}), 200),
      );
      await lookup;
      expect(remoteController.state.hydrantLookupInProgress, isFalse);
      expect(
        remoteController.state.meter?.externalStatus,
        ExternalMeterStatus.notFound,
      );
    },
  );

  test(
    'GPS captured at start is persisted and restored with RUNNING sample',
    () async {
      final gps = GpsSnapshot(
        latitude: 29.0729,
        longitude: -110.9559,
        accuracyMeters: 3.2,
        capturedAt: DateTime.utc(2026, 8, 16, 20),
      );
      final dependencies = fixture.dependencies.copyWith(
        location: _FakeLocation(result: gps),
      );
      final locationController = AppController(dependencies);
      await _prepare(locationController, method: MeasurementMethod.manual);
      await locationController.startSample();
      final persisted = await dependencies.samples.getById(
        locationController.state.sample!.id,
      );
      expect(persisted?.gps?.latitude, gps.latitude);
      expect(persisted?.gps?.accuracyMeters, gps.accuracyMeters);

      final restarted = AppController(dependencies);
      await restarted.initialize();
      expect(restarted.state.gps?.longitude, gps.longitude);
      expect(restarted.state.gpsCaptureState, GpsCaptureState.captured);
    },
  );

  for (final item in <(LocationFailureKind, GpsCaptureState)>[
    (LocationFailureKind.denied, GpsCaptureState.denied),
    (LocationFailureKind.permanentlyDenied, GpsCaptureState.permanentlyDenied),
    (LocationFailureKind.serviceDisabled, GpsCaptureState.serviceDisabled),
    (LocationFailureKind.timeout, GpsCaptureState.timeout),
    (LocationFailureKind.unavailable, GpsCaptureState.error),
  ]) {
    test('GPS maps ${item.$1.name} to an actionable UI state', () async {
      final locationController = AppController(
        fixture.dependencies.copyWith(
          location: _FakeLocation(
            failure: LocationFailure(item.$1, 'Fallo controlado'),
          ),
        ),
      );
      await locationController.captureGps();
      expect(locationController.state.gps, isNull);
      expect(locationController.state.gpsCaptureState, item.$2);
      expect(locationController.state.gpsMessage, 'Fallo controlado');
    });
  }
}

final class _FakeLocation implements LocationPort {
  const _FakeLocation({this.result, this.failure});
  final GpsSnapshot? result;
  final LocationFailure? failure;

  @override
  Future<GpsSnapshot> capture() async {
    if (failure case final failure?) throw failure;
    return result!;
  }
}

final class _FakeTokenStore implements TokenStore {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> read() async => 'test-token';
  @override
  Future<void> write(String token) async {}
}

final class _FakeCameraPort implements CameraPort {
  int captureCount = 0;
  String get lastCapturePath =>
      '${Directory.systemTemp.path}/ddr001-auto-intermediate-$captureCount.jpg';
  @override
  double get previewAspectRatio => 3 / 4;
  @override
  Future<double> getMinZoomLevel() async => 1;
  @override
  Future<double> getMaxZoomLevel() async => 8;
  @override
  Future<void> setZoomLevel(double zoomLevel) async {}
  @override
  Future<void> focusAt({required double x, required double y}) async {}
  @override
  Widget buildPreview() => const SizedBox();
  @override
  Future<CapturedPhoto> capture() async {
    captureCount++;
    final file = File(lastCapturePath);
    await file.writeAsBytes(List<int>.filled(900, captureCount));
    return CapturedPhoto(path: file.path, capturedAt: DateTime.now().toUtc());
  }

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
  Future<VisualReadingProposal> extractRegions({
    required String evidenceId,
    required String evidencePath,
    required DialVisionConfiguration configuration,
  }) async => VisualReadingProposal(
    evidenceId: evidenceId,
    evidencePath: evidencePath,
    odometerRaw: '',
    odometerValue: null,
    needleLiters: null,
    needleAngle: null,
    warnings: const [],
    createdAt: DateTime.utc(2026, 8, 10),
    configuration: configuration,
    totalizerCrop: Uint8List.fromList(const [1, 2, 3]),
    dialCrop: Uint8List.fromList(const [4, 5, 6]),
    analysisCompleted: true,
  );

  @override
  Future<VisualReadingProposal> prepare({
    required String evidenceId,
    required String evidencePath,
    DialVisionConfiguration? configuration,
  }) async => VisualReadingProposal(
    evidenceId: evidenceId,
    evidencePath: evidencePath,
    odometerRaw: '',
    odometerValue: null,
    needleLiters: null,
    needleAngle: null,
    warnings: const [],
    createdAt: DateTime.utc(2026, 8, 10),
    configuration: configuration ?? const DialVisionConfiguration(),
    analysisCompleted: false,
  );

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

final class _RejectingAuthService implements AuthService {
  const _RejectingAuthService();

  @override
  Future<User?> restoreSession() async => null;

  @override
  Future<User> login({
    required String displayName,
    required String email,
    required String phone,
  }) => throw StateError('Primary authentication unavailable.');

  @override
  Future<void> logout() async {}
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
