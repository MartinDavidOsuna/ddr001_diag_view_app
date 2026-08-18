import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ddr001_diag_view_app/app/app_dependencies.dart';
import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:ddr001_diag_view_app/presentation/app_controller.dart';
import 'package:ddr001_diag_view_app/infrastructure/camera/camera_models.dart';
import 'package:ddr001_diag_view_app/infrastructure/camera/camera_port.dart';
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
    final armedAt = controller.state.sample!.startedAt!;
    await controller.addManualPulse();
    final firstPulseAt = controller.state.sample!.startedAt!;
    await controller.addManualPulse();
    final persisted = await fixture.dependencies.samples.getById(
      controller.state.sample!.id,
    );
    expect(persisted?.pulseCount, 2);
    expect(persisted?.referenceLitersProgress, 4);
    expect(firstPulseAt.isBefore(armedAt), isFalse);
    expect(persisted?.startedAt, firstPulseAt);
  });

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
      final start = File('${fixture.directory.path}/threshold-start.jpg');
      await start.writeAsBytes(List<int>.filled(900, 9));
      await controller.processCapturedPhoto(start.path);
      await controller.reanalyzeRegions(
        const DialVisionConfiguration(
          totalizerConfiguration: TotalizerConfiguration(
            digitCount: 3,
            decimalPlaces: 1,
          ),
        ),
      );
      await controller.confirmCameraReading(
        odometer: 1,
        needle: 0,
        corrected: true,
      );
      await controller.addManualPulse();
      expect(controller.state.page, AppPage.run);
      await controller.addManualPulse();
      expect(controller.state.page, AppPage.run);
      expect(controller.state.capturePurpose, isNull);
      expect(camera.captureCount, 1);
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
    'recovery restores technician-selected START regions without new Evidence',
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
      const selected = DialVisionConfiguration(
        totalizerRegion: TotalizerRegion(NormalizedRect(.08, .72, .44, .16)),
        selectedDial: NormalizedCircle(.78, .22, .14),
        multiplier: .01,
        litersPerRevolution: 1,
        totalizerConfiguration: TotalizerConfiguration(
          digitCount: 6,
          decimalPlaces: 2,
        ),
      );
      await controller.reanalyzeRegions(selected);
      final evidenceId = controller.state.readingProposal!.evidenceId;
      final restarted = AppController(dependencies);
      await restarted.initialize();
      await restarted.resumeSample();
      expect(restarted.state.page, AppPage.camera);
      expect(restarted.state.readingProposal!.evidenceId, evidenceId);
      expect(restarted.state.readingProposal!.analysisCompleted, isFalse);
      final restored = restarted.state.readingProposal!.configuration;
      expect(restored.totalizerRegion.geometry.left, .08);
      expect(restored.totalizerRegion.geometry.top, .72);
      expect(restored.selectedDial.centerX, .78);
      expect(restored.selectedDial.centerY, .22);
      expect(restored.multiplier, .01);
      expect(restored.totalizerConfiguration?.decimalPlaces, 2);
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
      expect(controller.state.readingProposal!.analysisCompleted, isFalse);
      final discarded = controller.state.readingProposal!;
      await controller.recapturePhoto();
      expect(
        await cameraDependencies.points.listBySample(
          controller.state.sample!.id,
        ),
        isEmpty,
      );
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
      expect(
        controller.state.points
            .singleWhere((point) => point.type == PointType.start)
            .readingLiters,
        47000.1,
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
      await controller.requestFinalEvidence();
      final finalEvidenceId = controller.state.readingProposal!.evidenceId;
      expect(controller.state.page, AppPage.camera);
      expect(controller.state.busy, isFalse);
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
      final finalPointBeforeClosure = controller.state.points.singleWhere(
        (point) => point.type == PointType.finalPoint,
      );
      expect(finalPointBeforeClosure.readingLiters, 47000.2);
      expect(finalPointBeforeClosure.indicatedLiters, closeTo(10.1, 1e-9));
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
  @override
  Widget buildPreview() => const SizedBox();
  @override
  Future<CapturedPhoto> capture() async {
    captureCount++;
    final file = File(
      '${Directory.systemTemp.path}/ddr001-auto-intermediate-$captureCount.jpg',
    );
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

Future<void> _prepare(
  AppController controller, {
  required MeasurementMethod method,
}) async {
  await controller.login('Martín Osuna', 'field@aquafim.mx', '4491234567');
  controller.selectFlow(FlowPoint.q3);
  await controller.identifyMeter(meterId: 'meter-stage3', lpsApprox: 20);
  controller.selectMethod(method);
}
