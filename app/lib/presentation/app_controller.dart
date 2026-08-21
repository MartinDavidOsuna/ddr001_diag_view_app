import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../app/app_dependencies.dart';
import '../core/metrology/metrology.dart';
import '../domain/expected_evidence_plan.dart';
import '../domain/control_start_gate.dart';
import '../domain/models.dart';
import '../domain/pulse/pulse_source.dart';
import '../domain/pulse/pulse_flow_estimate.dart';
import '../infrastructure/camera/camera_models.dart';
import '../infrastructure/camera/camera_port.dart';
import '../infrastructure/vision/vision_models.dart';
import '../infrastructure/pulse/ble_discovery.dart';
import '../infrastructure/pulse/ble_pulse_source.dart';
import '../domain/pulse/esp32_counter_protocol.dart';
import '../infrastructure/pulse/camera_resource_coordinator.dart';
import '../infrastructure/pulse/led_pulse_detector.dart';
import '../infrastructure/camera/flutter_camera_adapter.dart';
import '../infrastructure/export/case_export_service.dart';

enum AppPage {
  loading,
  login,
  recovery,
  home,
  identification,
  method,
  setup,
  run,
  readings,
  result,
  caseSummary,
  history,
  settings,
  manual,
  invalidEvidence,
  camera,
  debugCalibration,
}

enum CapturePurpose {
  cameraPreparation,
  start,
  intermediate,
  manualDiagnostic,
  finalEvidence,
}

enum HardwareState { notConnected, preparing, ready, error, disconnected }

enum GpsCaptureState {
  idle,
  capturing,
  captured,
  serviceDisabled,
  denied,
  permanentlyDenied,
  timeout,
  error,
}

final class AppViewState {
  const AppViewState({
    this.page = AppPage.loading,
    this.busy = false,
    this.user,
    this.activeCase,
    this.meter,
    this.flow,
    this.sample,
    this.selectedFlow = FlowPoint.q1,
    this.selectedMethod = MeasurementMethod.ble,
    this.lpsApprox,
    this.q1LpsApprox = 1.5,
    this.q2LpsApprox = 1.0,
    this.identificationMeterId = '',
    this.identificationTestBenchId = '',
    this.deviceMetadata = const DeviceMetadata(),
    this.litersPerPulse = 1,
    this.evidenceStepLiters = 25,
    this.readingUncertaintyLiters = 1,
    this.minimumVolumeLiters = 100,
    this.maximumVolumeLiters = 300,
    this.controlStartMinimumLps = 0.5,
    this.controlStartMaximumLps = 50,
    this.hydrantLitersPerPulse = 1,
    this.litersPerOdometerUnit = 1000,
    this.needleLitersPerRevolution = 100,
    this.totalizerIntegerDigits = 5,
    this.totalizerDecimalPlaces = 0,
    this.cameraZoomLevel = 1,
    this.measurementStarted = false,
    this.finalizingMeasurement = false,
    this.preStartControlPulseCount = 0,
    this.preStartControlFirstPulseAt,
    this.hydrantMonitorPulseCount = 0,
    this.hydrantMonitorFirstPulseAt,
    this.remoteControlConnected = false,
    this.hardwareState = HardwareState.notConnected,
    this.evidence = const [],
    this.samples = const [],
    this.points = const [],
    this.casePointsBySample = const {},
    this.caseEvidenceBySample = const {},
    this.cases = const [],
    this.errorMessage,
    this.capturePurpose,
    this.captureVolumeLiters,
    this.cameraState = CameraOperationState.idle,
    this.initialReadingProposal,
    this.readingProposal,
    this.bleDevices = const [],
    this.selectedBleDevice,
    this.ledDarkBrightness,
    this.ledBrightBrightness,
    this.ledFps,
    this.ledRegion = const LedRegion(
      left: .35,
      top: .35,
      width: .30,
      height: .30,
    ),
    this.ledLivePulses = 0,
    this.ledReconciledPulses = 0,
    this.ledFalsePositives = 0,
    this.ledFramesDropped = 0,
    this.gps,
    this.gpsCaptureState = GpsCaptureState.idle,
    this.gpsMessage,
    this.hydrantLookupInProgress = false,
    this.exportedFiles,
    this.syncMessage = 'Pendiente local',
    this.reportSampleIds = const {},
    this.meterUnderTestPulseCount = 0,
    this.meterUnderTestFirstPulseAt,
  });

  final AppPage page;
  final bool busy;
  final User? user;
  final VerificationCase? activeCase;
  final Meter? meter;
  final FlowPointRecord? flow;
  final Sample? sample;
  final FlowPoint selectedFlow;
  final MeasurementMethod selectedMethod;
  final double? lpsApprox;
  final double q1LpsApprox;
  final double q2LpsApprox;
  final String identificationMeterId;
  final String identificationTestBenchId;
  final DeviceMetadata deviceMetadata;
  final double litersPerPulse;
  final double evidenceStepLiters;
  final double readingUncertaintyLiters;
  final double minimumVolumeLiters;
  final double maximumVolumeLiters;
  final double controlStartMinimumLps;
  final double controlStartMaximumLps;
  final double hydrantLitersPerPulse;
  final double litersPerOdometerUnit;
  final double needleLitersPerRevolution;
  final int totalizerIntegerDigits;
  final int totalizerDecimalPlaces;
  final double cameraZoomLevel;
  final bool measurementStarted;
  final bool finalizingMeasurement;
  final int preStartControlPulseCount;
  final DateTime? preStartControlFirstPulseAt;
  final int hydrantMonitorPulseCount;
  final DateTime? hydrantMonitorFirstPulseAt;
  final bool remoteControlConnected;
  final HardwareState hardwareState;
  final List<Evidence> evidence;
  final List<Sample> samples;
  final List<TestPoint> points;
  final Map<String, List<TestPoint>> casePointsBySample;
  final Map<String, List<Evidence>> caseEvidenceBySample;
  final List<VerificationCase> cases;
  final String? errorMessage;
  final CapturePurpose? capturePurpose;
  final double? captureVolumeLiters;
  final CameraOperationState cameraState;
  final VisualReadingProposal? initialReadingProposal;
  final VisualReadingProposal? readingProposal;
  final List<BleDeviceCandidate> bleDevices;
  final BleDeviceCandidate? selectedBleDevice;
  final LedRegion ledRegion;
  final double? ledDarkBrightness;
  final double? ledBrightBrightness;
  final double? ledFps;
  final int ledLivePulses;
  final int ledReconciledPulses;
  final int ledFalsePositives;
  final int ledFramesDropped;
  final GpsSnapshot? gps;
  final GpsCaptureState gpsCaptureState;
  final String? gpsMessage;
  final bool hydrantLookupInProgress;
  final ExportedCaseFiles? exportedFiles;
  final String syncMessage;
  final Set<String> reportSampleIds;
  final int meterUnderTestPulseCount;
  final DateTime? meterUnderTestFirstPulseAt;

  AppViewState copyWith({
    AppPage? page,
    bool? busy,
    User? user,
    bool clearUser = false,
    VerificationCase? activeCase,
    bool clearCase = false,
    Meter? meter,
    bool clearMeter = false,
    FlowPointRecord? flow,
    bool clearFlow = false,
    Sample? sample,
    bool clearSample = false,
    FlowPoint? selectedFlow,
    MeasurementMethod? selectedMethod,
    double? lpsApprox,
    double? q1LpsApprox,
    double? q2LpsApprox,
    String? identificationMeterId,
    String? identificationTestBenchId,
    DeviceMetadata? deviceMetadata,
    double? litersPerPulse,
    double? evidenceStepLiters,
    double? readingUncertaintyLiters,
    double? minimumVolumeLiters,
    double? maximumVolumeLiters,
    double? controlStartMinimumLps,
    double? controlStartMaximumLps,
    double? hydrantLitersPerPulse,
    double? litersPerOdometerUnit,
    double? needleLitersPerRevolution,
    int? totalizerIntegerDigits,
    int? totalizerDecimalPlaces,
    double? cameraZoomLevel,
    bool? measurementStarted,
    bool? finalizingMeasurement,
    int? preStartControlPulseCount,
    DateTime? preStartControlFirstPulseAt,
    bool clearPreStartControlFirstPulseAt = false,
    int? hydrantMonitorPulseCount,
    DateTime? hydrantMonitorFirstPulseAt,
    bool clearHydrantMonitorFirstPulseAt = false,
    bool? remoteControlConnected,
    HardwareState? hardwareState,
    List<Evidence>? evidence,
    List<Sample>? samples,
    List<TestPoint>? points,
    Map<String, List<TestPoint>>? casePointsBySample,
    Map<String, List<Evidence>>? caseEvidenceBySample,
    List<VerificationCase>? cases,
    String? errorMessage,
    bool clearError = false,
    CapturePurpose? capturePurpose,
    bool clearCapturePurpose = false,
    double? captureVolumeLiters,
    CameraOperationState? cameraState,
    VisualReadingProposal? initialReadingProposal,
    bool clearInitialReadingProposal = false,
    VisualReadingProposal? readingProposal,
    bool clearReadingProposal = false,
    List<BleDeviceCandidate>? bleDevices,
    BleDeviceCandidate? selectedBleDevice,
    bool clearSelectedBleDevice = false,
    LedRegion? ledRegion,
    double? ledDarkBrightness,
    double? ledBrightBrightness,
    double? ledFps,
    int? ledLivePulses,
    int? ledReconciledPulses,
    int? ledFalsePositives,
    int? ledFramesDropped,
    GpsSnapshot? gps,
    bool clearGps = false,
    GpsCaptureState? gpsCaptureState,
    String? gpsMessage,
    bool clearGpsMessage = false,
    bool? hydrantLookupInProgress,
    ExportedCaseFiles? exportedFiles,
    String? syncMessage,
    Set<String>? reportSampleIds,
    int? meterUnderTestPulseCount,
    DateTime? meterUnderTestFirstPulseAt,
    bool clearMeterUnderTestFirstPulseAt = false,
  }) => AppViewState(
    page: page ?? this.page,
    busy: busy ?? this.busy,
    user: clearUser ? null : user ?? this.user,
    activeCase: clearCase ? null : activeCase ?? this.activeCase,
    meter: clearMeter ? null : meter ?? this.meter,
    flow: clearFlow ? null : flow ?? this.flow,
    sample: clearSample ? null : sample ?? this.sample,
    selectedFlow: selectedFlow ?? this.selectedFlow,
    selectedMethod: selectedMethod ?? this.selectedMethod,
    lpsApprox: lpsApprox ?? this.lpsApprox,
    q1LpsApprox: q1LpsApprox ?? this.q1LpsApprox,
    q2LpsApprox: q2LpsApprox ?? this.q2LpsApprox,
    identificationMeterId: identificationMeterId ?? this.identificationMeterId,
    identificationTestBenchId:
        identificationTestBenchId ?? this.identificationTestBenchId,
    deviceMetadata: deviceMetadata ?? this.deviceMetadata,
    litersPerPulse: litersPerPulse ?? this.litersPerPulse,
    evidenceStepLiters: evidenceStepLiters ?? this.evidenceStepLiters,
    readingUncertaintyLiters:
        readingUncertaintyLiters ?? this.readingUncertaintyLiters,
    minimumVolumeLiters: minimumVolumeLiters ?? this.minimumVolumeLiters,
    maximumVolumeLiters: maximumVolumeLiters ?? this.maximumVolumeLiters,
    controlStartMinimumLps:
        controlStartMinimumLps ?? this.controlStartMinimumLps,
    controlStartMaximumLps:
        controlStartMaximumLps ?? this.controlStartMaximumLps,
    hydrantLitersPerPulse: hydrantLitersPerPulse ?? this.hydrantLitersPerPulse,
    litersPerOdometerUnit: litersPerOdometerUnit ?? this.litersPerOdometerUnit,
    needleLitersPerRevolution:
        needleLitersPerRevolution ?? this.needleLitersPerRevolution,
    totalizerIntegerDigits:
        totalizerIntegerDigits ?? this.totalizerIntegerDigits,
    totalizerDecimalPlaces:
        totalizerDecimalPlaces ?? this.totalizerDecimalPlaces,
    cameraZoomLevel: cameraZoomLevel ?? this.cameraZoomLevel,
    measurementStarted: measurementStarted ?? this.measurementStarted,
    finalizingMeasurement: finalizingMeasurement ?? this.finalizingMeasurement,
    preStartControlPulseCount:
        preStartControlPulseCount ?? this.preStartControlPulseCount,
    preStartControlFirstPulseAt: clearPreStartControlFirstPulseAt
        ? null
        : preStartControlFirstPulseAt ?? this.preStartControlFirstPulseAt,
    hydrantMonitorPulseCount:
        hydrantMonitorPulseCount ?? this.hydrantMonitorPulseCount,
    hydrantMonitorFirstPulseAt: clearHydrantMonitorFirstPulseAt
        ? null
        : hydrantMonitorFirstPulseAt ?? this.hydrantMonitorFirstPulseAt,
    remoteControlConnected:
        remoteControlConnected ?? this.remoteControlConnected,
    hardwareState: hardwareState ?? this.hardwareState,
    evidence: evidence ?? this.evidence,
    samples: samples ?? this.samples,
    points: points ?? this.points,
    casePointsBySample: casePointsBySample ?? this.casePointsBySample,
    caseEvidenceBySample: caseEvidenceBySample ?? this.caseEvidenceBySample,
    cases: cases ?? this.cases,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    capturePurpose: clearCapturePurpose
        ? null
        : capturePurpose ?? this.capturePurpose,
    captureVolumeLiters: captureVolumeLiters ?? this.captureVolumeLiters,
    cameraState: cameraState ?? this.cameraState,
    initialReadingProposal: clearInitialReadingProposal
        ? null
        : initialReadingProposal ?? this.initialReadingProposal,
    readingProposal: clearReadingProposal
        ? null
        : readingProposal ?? this.readingProposal,
    bleDevices: bleDevices ?? this.bleDevices,
    selectedBleDevice: clearSelectedBleDevice
        ? null
        : selectedBleDevice ?? this.selectedBleDevice,
    ledRegion: ledRegion ?? this.ledRegion,
    ledDarkBrightness: ledDarkBrightness ?? this.ledDarkBrightness,
    ledBrightBrightness: ledBrightBrightness ?? this.ledBrightBrightness,
    ledFps: ledFps ?? this.ledFps,
    ledLivePulses: ledLivePulses ?? this.ledLivePulses,
    ledReconciledPulses: ledReconciledPulses ?? this.ledReconciledPulses,
    ledFalsePositives: ledFalsePositives ?? this.ledFalsePositives,
    ledFramesDropped: ledFramesDropped ?? this.ledFramesDropped,
    gps: clearGps ? null : gps ?? this.gps,
    gpsCaptureState: gpsCaptureState ?? this.gpsCaptureState,
    gpsMessage: clearGpsMessage ? null : gpsMessage ?? this.gpsMessage,
    hydrantLookupInProgress:
        hydrantLookupInProgress ?? this.hydrantLookupInProgress,
    exportedFiles: exportedFiles ?? this.exportedFiles,
    syncMessage: syncMessage ?? this.syncMessage,
    reportSampleIds: reportSampleIds ?? this.reportSampleIds,
    meterUnderTestPulseCount:
        meterUnderTestPulseCount ?? this.meterUnderTestPulseCount,
    meterUnderTestFirstPulseAt: clearMeterUnderTestFirstPulseAt
        ? null
        : meterUnderTestFirstPulseAt ?? this.meterUnderTestFirstPulseAt,
  );
}

final appDependenciesProvider = Provider<AppDependencies>(
  (ref) => throw StateError('AppDependencies must be overridden at bootstrap.'),
);

final appControllerProvider =
    StateNotifierProvider<AppController, AppViewState>((ref) {
      return AppController(ref.watch(appDependenciesProvider));
    });

final class AppController extends StateNotifier<AppViewState> {
  AppController(this.dependencies, [this._uuid = const Uuid()])
    : super(const AppViewState());

  final AppDependencies dependencies;
  final Uuid _uuid;
  static const _mpe = Class2WaterMpePolicy();
  BlePulseSource? _bleSource;
  String? _bleBoundSampleId;
  MeterFaceConfiguration? _lastMeterFaceConfiguration;
  double? _lastCameraZoom;
  LedPulseSource? _ledSource;
  StreamSubscription<PulseEvent>? _pulseSubscription;
  StreamSubscription<PulseSourceState>? _pulseStateSubscription;
  StreamSubscription<int>? _counterSubscription;
  StreamSubscription<int>? _meterUnderTestCounterSubscription;
  int? _meterUnderTestCounterBaseline;
  int? _hydrantMonitorCounterBaseline;
  bool _bleUiTransitionInProgress = false;
  bool _sampleEndpointFrozen = false;
  int? _latestMeterUnderTestCounter;
  StreamSubscription<PulseEvent>? _ledSubscription;
  final CameraResourceCoordinator _cameraCoordinator =
      CameraResourceCoordinator();
  Timer? _ledReconciliationTimer;
  Timer? _ledMetricsTimer;
  int? _latestEsp32Counter;
  int _pendingOpticalPulses = 0;
  Future<void> _pulseQueue = Future.value();
  bool _openingIntermediateEvidence = false;

  Future<void> initialize() async {
    await _guard(() async {
      final deviceMetadata =
          await dependencies.deviceMetadata?.read() ?? const DeviceMetadata();
      final user = await dependencies.auth.restoreSession();
      if (user == null) {
        state = state.copyWith(
          page: AppPage.login,
          clearUser: true,
          deviceMetadata: deviceMetadata,
        );
        return;
      }
      final running = (await dependencies.samples.listIncomplete())
          .where((sample) => sample.status == SampleStatus.running)
          .toList();
      if (running.isNotEmpty) {
        await _loadSampleContext(running.first);
        state = state.copyWith(
          user: user,
          page: AppPage.recovery,
          deviceMetadata: deviceMetadata,
        );
      } else {
        state = state.copyWith(
          user: user,
          page: AppPage.home,
          deviceMetadata: deviceMetadata,
        );
      }
    });
  }

  Future<void> login(String displayName, String email, String phone) async {
    await _guard(() async {
      final user = await dependencies.auth.login(
        displayName: displayName,
        email: email,
        phone: phone,
      );
      state = state.copyWith(user: user, page: AppPage.home);
    });
  }

  Future<void> logout() async {
    await _guard(() async {
      await dependencies.auth.logout();
      state = AppViewState(
        page: AppPage.login,
        deviceMetadata: state.deviceMetadata,
      );
    });
  }

  void showHome() =>
      state = state.copyWith(page: AppPage.home, clearError: true);
  Future<void> startIdentification() async {
    final saved = await _savedCameraSetup();
    if (saved != null) {
      _lastMeterFaceConfiguration = saved.$1;
      _lastCameraZoom = saved.$2;
    }
    await _stopPulseSources();
    state = AppViewState(
      page: AppPage.identification,
      user: state.user,
      deviceMetadata: state.deviceMetadata,
      cameraZoomLevel: _lastCameraZoom ?? 1,
      remoteControlConnected: state.remoteControlConnected,
      hardwareState: state.hardwareState,
      bleDevices: state.bleDevices,
      selectedBleDevice: state.selectedBleDevice,
    );
  }

  void showSettings() => state = state.copyWith(page: AppPage.settings);
  void showManual() => state = state.copyWith(page: AppPage.manual);
  void showDebugCalibration() {
    if (kDebugMode) {
      state = state.copyWith(page: AppPage.debugCalibration);
    }
  }

  Future<void> showHistory() async {
    await _guard(() async {
      final cases = await dependencies.cases.listLocalCases();
      state = state.copyWith(page: AppPage.history, cases: cases);
    });
  }

  Future<void> openCaseFromHistory(String caseId) async {
    await _guard(() async {
      final verificationCase = await dependencies.cases.getById(caseId);
      if (verificationCase == null) {
        throw StateError('No se encontró el expediente.');
      }
      final meter = await dependencies.meters.getById(verificationCase.meterId);
      final flows = await dependencies.flows.listByCase(caseId);
      final samples = <Sample>[];
      final points = <String, List<TestPoint>>{};
      final evidence = <String, List<Evidence>>{};
      for (final flow in flows) {
        samples.addAll(await dependencies.samples.listByFlow(flow.id));
      }
      for (final sample in samples) {
        points[sample.id] = await dependencies.points.listBySample(sample.id);
        evidence[sample.id] = await dependencies.evidence.listBySample(
          sample.id,
        );
      }
      state = state.copyWith(
        activeCase: verificationCase,
        meter: meter,
        samples: samples,
        casePointsBySample: points,
        caseEvidenceBySample: evidence,
        page: AppPage.caseSummary,
      );
    });
  }

  void selectFlow(FlowPoint value) =>
      state = state.copyWith(selectedFlow: value);
  void selectMethod(MeasurementMethod value) =>
      state = state.copyWith(selectedMethod: value);

  Future<void> replaceOpenSampleMethod(MeasurementMethod value) async {
    final sample = state.sample;
    if (sample == null || sample.status == SampleStatus.closedValid) {
      selectMethod(value);
      return;
    }
    await _stopPulseSources();
    for (final evidence in await dependencies.evidence.listBySample(
      sample.id,
    )) {
      await dependencies.fileStore.deleteTemporary(
        evidence.localPath,
        sampleClosed: false,
      );
    }
    await dependencies.samples.deleteOpen(sample.id);
    state = state.copyWith(
      selectedMethod: value,
      clearSample: true,
      evidence: [],
      points: [],
      measurementStarted: false,
      clearCapturePurpose: true,
      clearReadingProposal: true,
    );
  }

  void setHardwareState(HardwareState value) =>
      state = state.copyWith(hardwareState: value);

  void updateIdentificationDraft({
    String? meterId,
    String? testBenchId,
    double? q1LpsApprox,
    double? q2LpsApprox,
  }) {
    state = state.copyWith(
      identificationMeterId: meterId,
      identificationTestBenchId: testBenchId,
      q1LpsApprox: q1LpsApprox,
      q2LpsApprox: q2LpsApprox,
    );
  }

  void goBack() {
    final previous = switch (state.page) {
      AppPage.identification => AppPage.home,
      AppPage.method => AppPage.identification,
      AppPage.setup => AppPage.method,
      AppPage.camera =>
        state.capturePurpose == CapturePurpose.cameraPreparation
            ? AppPage.setup
            : AppPage.run,
      AppPage.run => AppPage.setup,
      AppPage.readings => AppPage.run,
      AppPage.result => AppPage.caseSummary,
      AppPage.manual => AppPage.settings,
      AppPage.settings ||
      AppPage.history ||
      AppPage.caseSummary => AppPage.home,
      _ => AppPage.home,
    };
    state = state.copyWith(page: previous);
  }

  Future<void> captureGps() async {
    final location = dependencies.location;
    if (location == null) return;
    state = state.copyWith(
      gpsCaptureState: GpsCaptureState.capturing,
      clearGpsMessage: true,
      clearError: true,
    );
    try {
      final gps = await location.capture();
      state = state.copyWith(
        gps: gps,
        gpsCaptureState: GpsCaptureState.captured,
        gpsMessage: 'Ubicación obtenida correctamente.',
      );
    } on LocationFailure catch (error) {
      state = state.copyWith(
        gpsCaptureState: _gpsStateForFailure(error.kind),
        gpsMessage: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        gpsCaptureState: GpsCaptureState.error,
        gpsMessage:
            'No fue posible obtener la ubicación. La prueba puede continuar sin GPS.',
      );
    }
  }

  Future<void> scanBleDevices({bool autoSelectSingle = false}) async {
    final discovery = dependencies.bleDiscovery;
    if (discovery == null) return;
    await _guard(() async {
      state = state.copyWith(hardwareState: HardwareState.preparing);
      final discovered = await discovery.scan();
      final activeDevice = state.selectedBleDevice;
      final connectionActive =
          activeDevice != null &&
          _bleSource != null &&
          (_bleSource!.currentState.status == PulseSourceStatus.ready ||
              _bleSource!.currentState.status == PulseSourceStatus.connected ||
              _bleSource!.currentState.status ==
                  PulseSourceStatus.reconnecting);
      final devices = <BleDeviceCandidate>[
        ...discovered,
        if (connectionActive &&
            !discovered.any((device) => device.id == activeDevice.id))
          activeDevice,
      ];
      final selectedStillPresent = devices.any(
        (device) => device.id == state.selectedBleDevice?.id,
      );
      state = state.copyWith(
        bleDevices: devices,
        hardwareState: selectedStillPresent
            ? HardwareState.ready
            : HardwareState.notConnected,
        clearSelectedBleDevice: !selectedStillPresent,
      );
      if (autoSelectSingle && devices.length == 1) {
        selectBleDevice(devices.single);
      }
    }, showBusy: false);
  }

  void selectBleDevice(BleDeviceCandidate device) {
    state = state.copyWith(
      selectedBleDevice: device,
      hardwareState: HardwareState.ready,
    );
  }

  Future<void> disconnectBleDevice() async {
    await _disconnectBleTransport();
    state = state.copyWith(
      hardwareState: HardwareState.notConnected,
      clearSelectedBleDevice: true,
      clearError: true,
    );
  }

  Future<void> identifyMeter({
    required String meterId,
    String? testBenchId,
    double? lpsApprox,
    double? q1LpsApprox,
    double? q2LpsApprox,
  }) async {
    await _guard(() async {
      final user = state.user;
      if (user == null) throw StateError('No active local session.');
      final id = meterId.trim();
      if (id.isEmpty) throw ArgumentError('Captura un medidor válido.');
      final normalizedTestBenchId =
          (testBenchId ?? state.identificationTestBenchId).trim();
      final now = DateTime.now().toUtc();
      final existingMeter = await dependencies.meters.getById(id);
      var meter = Meter(
        id: id,
        externalStatus:
            existingMeter?.externalStatus ?? ExternalMeterStatus.unknownOffline,
        externalSnapshotJson: existingMeter?.externalSnapshotJson,
        externalCheckedAt: existingMeter?.externalCheckedAt,
        createdAt: existingMeter?.createdAt ?? now,
        updatedAt: now,
      );
      final api = dependencies.remoteApi;
      final token = await dependencies.tokenStore?.read();
      if (api != null && token != null) {
        state = state.copyWith(hydrantLookupInProgress: true);
        try {
          final remote = await api.lookupMeter(id, token);
          meter = Meter(
            id: remote.id,
            externalStatus: remote.externalStatus,
            externalSnapshotJson: remote.externalSnapshotJson,
            externalCheckedAt: remote.externalCheckedAt,
            createdAt: existingMeter?.createdAt ?? remote.createdAt,
            updatedAt: now,
          );
        } catch (_) {
          // Identification remains usable offline or while the external
          // read-only adapter is unavailable.
        }
        state = state.copyWith(hydrantLookupInProgress: false);
      }
      await dependencies.meters.save(meter);
      var verificationCase = state.activeCase;
      if (verificationCase == null ||
          verificationCase.userId != user.id ||
          verificationCase.meterId != id) {
        verificationCase = VerificationCase(
          id: _uuid.v4(),
          meterId: id,
          userId: user.id,
          status: VerificationCaseStatus.open,
          createdAt: now,
          reportVersion: 1,
          testBenchId: normalizedTestBenchId,
          deviceId: state.deviceMetadata.id,
          androidVersion: state.deviceMetadata.androidVersion,
          deviceBrand: state.deviceMetadata.brand,
          deviceModel: state.deviceMetadata.model,
        );
        await dependencies.cases.create(verificationCase);
      }
      final existingFlows = await dependencies.flows.listByCase(
        verificationCase.id,
      );
      const configuredFlows = <FlowPoint>[FlowPoint.q1, FlowPoint.q2];
      final persisted = <FlowPoint, FlowPointRecord>{};
      for (final flowCode in configuredFlows) {
        var configured = existingFlows
            .where((item) => item.code == flowCode)
            .firstOrNull;
        if (configured == null) {
          configured = FlowPointRecord(
            id: _uuid.v4(),
            caseId: verificationCase.id,
            code: flowCode,
            mpePct: _mpe.mpePctFor(flowCode),
            status: FlowRecordStatus.open,
            createdAt: now,
          );
          await dependencies.flows.create(configured);
        }
        persisted[flowCode] = configured;
      }
      final flow = persisted[FlowPoint.q1]!;
      state = state.copyWith(
        meter: meter,
        identificationMeterId: id,
        identificationTestBenchId: normalizedTestBenchId,
        activeCase: verificationCase,
        flow: flow,
        selectedFlow: FlowPoint.q1,
        selectedMethod: MeasurementMethod.ble,
        page: AppPage.method,
      );
    });
  }

  void continueToSetup() => state = state.copyWith(page: AppPage.setup);

  void updateSetup({
    required double litersPerPulse,
    required double evidenceStepLiters,
    required double uncertaintyLiters,
    double? minimumVolumeLiters,
    double? maximumVolumeLiters,
    double? controlStartMinimumLps,
    double? controlStartMaximumLps,
    double? hydrantLitersPerPulse,
    double? litersPerOdometerUnit,
    double? needleLitersPerRevolution,
    int? totalizerIntegerDigits,
    int? totalizerDecimalPlaces,
  }) {
    if (litersPerPulse <= 0 ||
        evidenceStepLiters <= 0 ||
        uncertaintyLiters < 0) {
      throw ArgumentError('La configuración contiene valores inválidos.');
    }
    final minimum = minimumVolumeLiters ?? state.minimumVolumeLiters;
    final maximum = maximumVolumeLiters ?? state.maximumVolumeLiters;
    final startMinimum = controlStartMinimumLps ?? state.controlStartMinimumLps;
    final startMaximum = controlStartMaximumLps ?? state.controlStartMaximumLps;
    final hydrantK = hydrantLitersPerPulse ?? state.hydrantLitersPerPulse;
    final odometerScale = litersPerOdometerUnit ?? state.litersPerOdometerUnit;
    final needleScale =
        needleLitersPerRevolution ?? state.needleLitersPerRevolution;
    final integerDigits =
        totalizerIntegerDigits ?? state.totalizerIntegerDigits;
    final decimalPlaces =
        totalizerDecimalPlaces ?? state.totalizerDecimalPlaces;
    if (minimum <= 0 || maximum < minimum) {
      throw ArgumentError('Vmín/Vmáx no son válidos.');
    }
    if (startMinimum < 0 || startMaximum <= startMinimum || hydrantK <= 0) {
      throw ArgumentError('Rango de inicio/K del medidor no válido.');
    }
    if (odometerScale <= 0 ||
        needleScale <= 0 ||
        integerDigits < 1 ||
        decimalPlaces < 0 ||
        decimalPlaces > 3) {
      throw ArgumentError('Escalas/formato del medidor no válidos.');
    }
    state = state.copyWith(
      litersPerPulse: litersPerPulse,
      evidenceStepLiters: evidenceStepLiters,
      readingUncertaintyLiters: uncertaintyLiters,
      minimumVolumeLiters: minimum,
      maximumVolumeLiters: maximum,
      controlStartMinimumLps: startMinimum,
      controlStartMaximumLps: startMaximum,
      hydrantLitersPerPulse: hydrantK,
      litersPerOdometerUnit: odometerScale,
      needleLitersPerRevolution: needleScale,
      totalizerIntegerDigits: integerDigits,
      totalizerDecimalPlaces: decimalPlaces,
    );
  }

  Future<void> startSample({
    MeterFaceConfiguration? inheritedMeterFaceConfiguration,
    double? inheritedCameraZoom,
  }) async {
    await _guard(() async {
      final current = state.sample;
      if (current != null && current.status == SampleStatus.running) {
        state = state.copyWith(
          page: AppPage.camera,
          capturePurpose: CapturePurpose.cameraPreparation,
          cameraState: CameraOperationState.idle,
        );
        return;
      }
      await _stopPulseSources();
      _resetHydrantRunState();
      if ((state.selectedMethod == MeasurementMethod.ble ||
              state.selectedMethod == MeasurementMethod.led) &&
          state.selectedBleDevice == null) {
        throw StateError(
          'Busque y seleccione un ESP32 DDR001 para establecer el contador de integridad.',
        );
      }
      final flow = state.flow;
      final verificationCase = state.activeCase;
      if (flow == null || verificationCase == null) {
        throw StateError('Selecciona un expediente y caudal.');
      }
      final existing = await dependencies.samples.listByFlow(flow.id);
      final now = DateTime.now().toUtc();
      final draft = Sample(
        id: _uuid.v4(),
        flowPointId: flow.id,
        sampleNumber: existing.length + 1,
        status: SampleStatus.draft,
        configuration: SampleConfiguration(
          measurementMethod: state.selectedMethod,
          litersPerPulse: state.litersPerPulse,
          evidenceStepLiters: state.evidenceStepLiters,
          readingUncertaintyLiters: state.readingUncertaintyLiters,
          flowPoint: flow.code,
          mpePct: flow.mpePct,
          lpsApprox: flow.lpsApprox,
          litersPerOdometerUnit: state.litersPerOdometerUnit,
          needleLitersPerRevolution: state.needleLitersPerRevolution,
          minimumVolumeLiters: state.minimumVolumeLiters,
          maximumVolumeLiters: state.maximumVolumeLiters,
          controlStartMinimumLps: state.controlStartMinimumLps,
          controlStartMaximumLps: state.controlStartMaximumLps,
          hydrantLitersPerPulse: state.hydrantLitersPerPulse,
          cameraZoomLevel:
              inheritedCameraZoom ?? _lastCameraZoom ?? state.cameraZoomLevel,
        ),
        createdAt: now,
        updatedAt: now,
        pulseCount: 0,
      );
      await dependencies.samples.createDraft(draft);
      GpsSnapshot? gps = state.gps;
      var gpsCaptureState = state.gpsCaptureState;
      String? gpsMessage = state.gpsMessage;
      if (gps == null && dependencies.location != null) {
        try {
          gps = await dependencies.location!.capture();
          gpsCaptureState = GpsCaptureState.captured;
          gpsMessage = 'Ubicación obtenida correctamente.';
        } on LocationFailure catch (error) {
          gpsCaptureState = _gpsStateForFailure(error.kind);
          gpsMessage = error.message;
        } catch (_) {
          gpsCaptureState = GpsCaptureState.error;
          gpsMessage =
              'No fue posible obtener la ubicación. La prueba puede continuar sin GPS.';
          // GPS is desirable but nullable by contract and never blocks a run.
        }
      }
      var running = await dependencies.samples.start(
        draft.id,
        at: now,
        gps: gps,
      );
      final cameraTemplate =
          inheritedMeterFaceConfiguration ?? _lastMeterFaceConfiguration;
      if (cameraTemplate != null && inheritedMeterFaceConfiguration == null) {
        running = await dependencies.samples.updateMeterFaceConfiguration(
          running.id,
          cameraTemplate,
        );
      }
      state = state.copyWith(
        gps: gps,
        gpsCaptureState: gps == null
            ? gpsCaptureState
            : GpsCaptureState.captured,
        gpsMessage: gpsMessage,
      );
      _resetHydrantRunState();
      if (inheritedMeterFaceConfiguration != null) {
        final configured = await dependencies.samples
            .updateMeterFaceConfiguration(
              running.id,
              inheritedMeterFaceConfiguration,
            );
        await _loadSampleContext(configured);
        state = state.copyWith(
          measurementStarted: false,
          preStartControlPulseCount: 0,
          clearPreStartControlFirstPulseAt: true,
          clearCapturePurpose: true,
          clearInitialReadingProposal: true,
          clearReadingProposal: true,
          meterUnderTestPulseCount: 0,
          clearMeterUnderTestFirstPulseAt: true,
          hydrantMonitorPulseCount: 0,
          clearHydrantMonitorFirstPulseAt: true,
        );
        await _startBleForCurrentSample();
        _enterRunPageAfterBleStart();
        return;
      }
      if (dependencies.camera != null) {
        await _refreshSample(running.id);
        await _startBleForCurrentSample();
        state = state.copyWith(
          page: AppPage.camera,
          capturePurpose: CapturePurpose.cameraPreparation,
          captureVolumeLiters: 0,
          cameraState: CameraOperationState.idle,
          clearReadingProposal: true,
          measurementStarted: false,
          preStartControlPulseCount: 0,
          clearPreStartControlFirstPulseAt: true,
        );
        return;
      }
      await dependencies.evidenceCapture.capture(
        caseId: verificationCase.id,
        sample: running,
        type: EvidenceType.start,
        volumeRefLiters: 0,
        pulseCount: state.selectedMethod.isPulseEventSource ? 0 : null,
      );
      await _refreshSample(running.id);
      _enterRunPageAfterBleStart();
    });
  }

  Future<void> setCameraZoom(double zoomLevel) async {
    if (!zoomLevel.isFinite || zoomLevel <= 0) return;
    state = state.copyWith(cameraZoomLevel: zoomLevel);
    final sample = state.sample;
    if (sample != null && sample.status == SampleStatus.running) {
      final updated = await dependencies.samples.updateCameraZoom(
        sample.id,
        zoomLevel,
      );
      state = state.copyWith(sample: updated);
    }
  }

  Future<void> addManualPulse() async {
    final sample = state.sample;
    if (sample == null ||
        sample.status != SampleStatus.running ||
        _sampleEndpointFrozen ||
        sample.configuration.measurementMethod != MeasurementMethod.manual) {
      return;
    }
    await _guard(() async {
      final now = DateTime.now().toUtc();
      await dependencies.pulseProgress.acceptPulse(
        sample.id,
        PulseEvent(
          id: _uuid.v4(),
          source: PulseSourceType.manual,
          occurredAt: now,
          receivedAt: now,
        ),
      );
      await _refreshSample(sample.id);
      await _openDueIntermediateEvidence(sample.id);
    });
  }

  Future<void> setDevelopmentVisualReference(double liters) async {
    final sample = state.sample;
    if (sample == null ||
        sample.configuration.measurementMethod != MeasurementMethod.visual) {
      return;
    }
    await _guard(() async {
      await dependencies.samples.updateProgress(
        id: sample.id,
        pulseCount: 0,
        referenceLiters: liters,
      );
      await _refreshSample(sample.id);
    });
  }

  Future<void> beginMeasurement() async {
    final sample = state.sample;
    final first = state.preStartControlFirstPulseAt;
    if (sample == null || first == null || state.measurementStarted) return;
    final gate = ControlStartGate.evaluate(
      pulses: state.preStartControlPulseCount,
      litersPerPulse: sample.configuration.litersPerPulse,
      firstPulseAt: first,
      now: DateTime.now().toUtc(),
      minimumLps: sample.configuration.controlStartMinimumLps,
      maximumLps: sample.configuration.controlStartMaximumLps,
    );
    if (!gate.inRange) return;
    state = state.copyWith(measurementStarted: true, clearError: true);
    _meterUnderTestCounterBaseline = _latestMeterUnderTestCounter;
    _hydrantMonitorCounterBaseline = _latestMeterUnderTestCounter;
    state = state.copyWith(
      meterUnderTestPulseCount: 0,
      clearMeterUnderTestFirstPulseAt: true,
      hydrantMonitorPulseCount: 0,
      clearHydrantMonitorFirstPulseAt: true,
    );
    await _captureOfficialStartEvidence();
  }

  Future<void> _captureOfficialStartEvidence() async {
    final camera = dependencies.camera;
    final sample = state.sample;
    if (camera == null || sample == null) return;
    try {
      state = state.copyWith(
        capturePurpose: CapturePurpose.start,
        captureVolumeLiters: 0,
        cameraState: CameraOperationState.capturing,
        clearReadingProposal: true,
      );
      await camera.resume();
      await camera.setZoomLevel(sample.configuration.cameraZoomLevel);
      final photo = await camera.capture();
      await processCapturedPhoto(photo.path, transparent: true);
    } catch (error, stackTrace) {
      debugPrint('START camera capture failed: $error\n$stackTrace');
      state = state.copyWith(
        measurementStarted: false,
        cameraState: CameraOperationState.error,
        errorMessage: 'No fue posible capturar la evidencia INICIO.',
      );
    }
  }

  void setRemoteControlConnected(bool connected) {
    if (state.remoteControlConnected == connected) return;
    state = state.copyWith(remoteControlConnected: connected);
  }

  void showReadings() => state = state.copyWith(page: AppPage.readings);

  Future<void> requestIntermediateEvidence(double volumeLiters) async {
    await _captureIntermediateEvidenceAutomatically(volumeLiters);
  }

  Future<void> _captureIntermediateEvidenceAutomatically(
    double volumeLiters,
  ) async {
    final camera = dependencies.camera;
    final sample = state.sample;
    if (camera == null || sample == null) {
      state = state.copyWith(
        errorMessage:
            'No fue posible capturar automáticamente la evidencia INTERMEDIATE.',
      );
      return;
    }
    await _pauseLedForEvidence();
    state = state.copyWith(
      page: AppPage.run,
      capturePurpose: CapturePurpose.intermediate,
      captureVolumeLiters: volumeLiters,
      cameraState: CameraOperationState.processing,
      clearReadingProposal: true,
    );
    try {
      await camera.resume();
      await camera.setZoomLevel(sample.configuration.cameraZoomLevel);
      final photo = await camera.capture();
      await processCapturedPhoto(photo.path, transparent: true);
    } catch (_) {
      state = state.copyWith(
        page: AppPage.run,
        cameraState: CameraOperationState.error,
        clearCapturePurpose: true,
        errorMessage:
            'No fue posible capturar automáticamente la evidencia INTERMEDIATE.',
      );
      await _resumeLedAfterEvidence(sample);
    }
  }

  Future<void> requestManualDiagnosticPoint() async {
    final sample = state.sample;
    if (sample == null) return;
    final reference = sample.configuration.measurementMethod.isPulseEventSource
        ? sample.pulseCount * sample.configuration.litersPerPulse
        : sample.referenceLitersProgress ?? 0;
    await _pauseLedForEvidence();
    state = state.copyWith(
      page: AppPage.camera,
      capturePurpose: CapturePurpose.manualDiagnostic,
      captureVolumeLiters: reference,
      cameraState: CameraOperationState.idle,
      clearReadingProposal: true,
    );
  }

  Future<void> requestFinalEvidence() async {
    if (state.finalizingMeasurement) return;
    final sample = state.sample;
    if (sample == null) return;
    var reference =
        sample.configuration.measurementMethod == MeasurementMethod.visual
        ? sample.referenceLitersProgress ?? 0
        : sample.pulseCount * sample.configuration.litersPerPulse;
    if (reference <= 0) {
      state = state.copyWith(
        errorMessage: 'El volumen de referencia debe ser mayor que cero.',
      );
      return;
    }
    _sampleEndpointFrozen = true;
    // Freeze the metrological endpoint before doing any camera or vision work.
    // No acquisition callback remains attached while FINAL is captured.
    state = state.copyWith(
      measurementStarted: false,
      finalizingMeasurement: true,
      page: AppPage.run,
      capturePurpose: CapturePurpose.finalEvidence,
      captureVolumeLiters: reference,
      cameraState: CameraOperationState.processing,
      clearReadingProposal: true,
      clearError: true,
    );
    await _freezeSampleAcquisition();
    // Complete callbacks that had already entered the serialized queue before
    // the operator pressed FINALIZAR.
    await _pulseQueue;
    final drainedSample = await dependencies.samples.getById(sample.id);
    if (drainedSample != null &&
        sample.configuration.measurementMethod.isPulseEventSource) {
      reference =
          drainedSample.pulseCount * sample.configuration.litersPerPulse;
      state = state.copyWith(
        sample: drainedSample,
        captureVolumeLiters: reference,
      );
    }
    final camera = dependencies.camera;
    if (camera == null) {
      state = state.copyWith(
        cameraState: CameraOperationState.error,
        measurementStarted: false,
        finalizingMeasurement: false,
        clearCapturePurpose: true,
        errorMessage:
            'No fue posible capturar automáticamente la evidencia FINAL.',
      );
      return;
    }
    try {
      await _pauseLedForEvidence();
      await camera.resume();
      await camera.setZoomLevel(sample.configuration.cameraZoomLevel);
      final photo = await camera.capture();
      await camera.pause();
      await processCapturedPhoto(photo.path, transparent: true);
    } catch (_) {
      state = state.copyWith(
        page: AppPage.run,
        cameraState: CameraOperationState.error,
        measurementStarted: false,
        finalizingMeasurement: false,
        clearCapturePurpose: true,
        errorMessage:
            'No fue posible capturar automáticamente la evidencia FINAL.',
      );
      await _resumeLedAfterEvidence(sample);
    }
  }

  Future<void> _freezeSampleAcquisition() async {
    _ledReconciliationTimer?.cancel();
    _ledReconciliationTimer = null;
    await _pulseSubscription?.cancel();
    _pulseSubscription = null;
    await _counterSubscription?.cancel();
    _counterSubscription = null;
    await _meterUnderTestCounterSubscription?.cancel();
    _meterUnderTestCounterSubscription = null;
    await _ledSubscription?.cancel();
    _ledSubscription = null;
    await _ledSource?.stop();
    _cameraCoordinator.release(CameraConsumer.ledDetector);
  }

  Future<void> processCapturedPhoto(
    String sourcePath, {
    bool transparent = false,
  }) async {
    await _guard(() async {
      var sample = state.sample;
      final verificationCase = state.activeCase;
      final purpose = state.capturePurpose;
      if (sample == null || verificationCase == null || purpose == null) {
        throw StateError('No hay una captura activa.');
      }
      state = state.copyWith(cameraState: CameraOperationState.processing);
      final type = switch (purpose) {
        CapturePurpose.cameraPreparation => EvidenceType.extra,
        CapturePurpose.start => EvidenceType.start,
        CapturePurpose.intermediate => EvidenceType.intermediate,
        CapturePurpose.manualDiagnostic => EvidenceType.extra,
        CapturePurpose.finalEvidence => EvidenceType.finalEvidence,
      };
      if (sample.configuration.measurementMethod == MeasurementMethod.led) {
        if (purpose == CapturePurpose.finalEvidence) {
          await _stopBleCounterSource();
        }
        await _flushLedReconciliation(sample.id);
        sample = await dependencies.samples.getById(sample.id) ?? sample;
      }
      final plannedIntermediate = purpose == CapturePurpose.intermediate
          ? state.captureVolumeLiters
          : null;
      final volume = purpose == CapturePurpose.start
          ? 0.0
          : ((purpose == CapturePurpose.finalEvidence
                    ? state.captureVolumeLiters
                    : plannedIntermediate) ??
                (sample.configuration.measurementMethod.isPulseEventSource
                    ? sample.pulseCount * sample.configuration.litersPerPulse
                    : state.captureVolumeLiters ?? 0));
      final evidencePulseCount =
          sample.configuration.measurementMethod.isPulseEventSource
          ? purpose == CapturePurpose.start
                ? 0
                : (volume / sample.configuration.litersPerPulse).round()
          : null;
      if (purpose == CapturePurpose.cameraPreparation) {
        final frozen = sample.meterFaceConfiguration;
        if (frozen == null) {
          state = state.copyWith(cameraState: CameraOperationState.idle);
          return;
        }
        final proposal = await dependencies.visualPipeline!.extractRegions(
          evidenceId: 'camera-preparation-${sample.id}',
          evidencePath: sourcePath,
          configuration: DialVisionConfiguration.fromDomain(frozen),
        );
        state = state.copyWith(
          cameraState: CameraOperationState.proposalReady,
          readingProposal: proposal,
        );
        return;
      }
      final evidence = await dependencies.evidenceCapture.captureExisting(
        sourcePath: sourcePath,
        caseId: verificationCase.id,
        sample: sample,
        type: type,
        volumeRefLiters: volume,
        pulseCount: evidencePulseCount,
      );
      final flowPulses = purpose == CapturePurpose.start
          ? state.preStartControlPulseCount
          : evidencePulseCount ?? 0;
      final flowFirstPulseAt = purpose == CapturePurpose.start
          ? state.preStartControlFirstPulseAt
          : sample.startedAt;
      final flowLps = PulseFlowEstimate.calculate(
        pulses: flowPulses,
        litersPerPulse: sample.configuration.litersPerPulse,
        firstPulseAt: flowFirstPulseAt,
        now: evidence.capturedAt,
      ).flowLps;
      await dependencies.points.save(
        TestPoint(
          id: 'point-${evidence.id}',
          sampleId: sample.id,
          type: switch (purpose) {
            CapturePurpose.cameraPreparation => PointType.start,
            CapturePurpose.start => PointType.start,
            CapturePurpose.intermediate => PointType.intermediate,
            CapturePurpose.manualDiagnostic => PointType.manualDiagnostic,
            CapturePurpose.finalEvidence => PointType.finalPoint,
          },
          pulseCount: evidencePulseCount,
          referenceLiters: volume,
          capturedAt: evidence.capturedAt,
          meterUnderTestPulseCount: state.meterUnderTestPulseCount,
          flowLps: flowLps,
        ),
      );
      // START and INTERMEDIATE are evidence-only. Visual interpretation is
      // deliberately manual and happens once, after FINAL.
      VisualReadingProposal? proposal;
      VisualReadingProposal? initialProposal;
      if (purpose == CapturePurpose.finalEvidence) {
        try {
          final frozenConfiguration = sample.meterFaceConfiguration == null
              ? null
              : DialVisionConfiguration.fromDomain(
                  sample.meterFaceConfiguration!,
                );
          if (frozenConfiguration != null) {
            proposal = await dependencies.visualPipeline?.extractRegions(
              evidenceId: evidence.id,
              evidencePath: evidence.localPath,
              configuration: frozenConfiguration,
            );
            final allEvidence = await dependencies.evidence.listBySample(
              sample.id,
            );
            final startEvidence = allEvidence
                .where((item) => item.type == EvidenceType.start)
                .firstOrNull;
            if (startEvidence != null) {
              initialProposal = await dependencies.visualPipeline
                  ?.extractRegions(
                    evidenceId: startEvidence.id,
                    evidencePath: startEvidence.localPath,
                    configuration: frozenConfiguration,
                  );
            }
          }
        } catch (_) {
          await dependencies.evidence.deleteFromOpenSample(evidence.id);
          await dependencies.fileStore.deleteTemporary(
            evidence.localPath,
            sampleClosed: false,
          );
          state = state.copyWith(cameraState: CameraOperationState.error);
          rethrow;
        }
      }
      await _refreshSample(sample.id);
      state = state.copyWith(
        cameraState: proposal == null
            ? CameraOperationState.confirmed
            : CameraOperationState.proposalReady,
        readingProposal: proposal,
        initialReadingProposal: initialProposal,
      );
      if (purpose == CapturePurpose.intermediate ||
          purpose == CapturePurpose.manualDiagnostic) {
        state = state.copyWith(page: AppPage.run, clearCapturePurpose: true);
        await _resumeLedAfterEvidence(sample);
      } else if (purpose == CapturePurpose.start) {
        state = state.copyWith(
          page: AppPage.run,
          cameraState: CameraOperationState.confirmed,
          clearCapturePurpose: true,
          clearReadingProposal: true,
        );
      } else if (purpose == CapturePurpose.finalEvidence) {
        state = state.copyWith(
          page: AppPage.readings,
          cameraState: CameraOperationState.confirmed,
          clearCapturePurpose: true,
          measurementStarted: false,
          finalizingMeasurement: false,
        );
      }
    }, showBusy: !transparent);
  }

  Future<void> confirmCameraReading({
    required double odometer,
    required double needle,
    required bool corrected,
  }) async {
    await _guard(() async {
      final sample = state.sample;
      final proposal = state.readingProposal;
      final purpose = state.capturePurpose;
      if (sample == null || proposal == null || purpose == null) {
        throw StateError('No existe una propuesta de lectura.');
      }
      final confirmed = proposal.confirm(
        odometerValue: odometer,
        needleLiters: needle,
        litersPerOdometerUnit: sample.configuration.litersPerOdometerUnit,
        needleLitersPerRevolution: proposal.configuration.litersPerRevolution,
        corrected: corrected,
      );
      if (purpose == CapturePurpose.start) {
        await dependencies.samples.updateMeterFaceConfiguration(
          sample.id,
          proposal.configuration.toDomain(),
        );
      }
      if (purpose == CapturePurpose.cameraPreparation) {
        await dependencies.samples.updateMeterFaceConfiguration(
          sample.id,
          proposal.configuration.toDomain(),
        );
        await _refreshSample(sample.id);
        state = state.copyWith(
          page: AppPage.run,
          cameraState: CameraOperationState.confirmed,
          clearCapturePurpose: true,
          clearReadingProposal: true,
          measurementStarted: false,
        );
        await _startBleForCurrentSample();
        return;
      }
      await dependencies.samples.updateProgress(
        id: sample.id,
        pulseCount: sample.pulseCount,
        referenceLiters: sample.referenceLitersProgress,
        initialReading: purpose == CapturePurpose.start ? confirmed : null,
        finalReading: purpose == CapturePurpose.finalEvidence
            ? confirmed
            : null,
      );
      final readingLiters =
          confirmed.reading.odometerUnits *
              confirmed.reading.litersPerOdometerUnit +
          confirmed.reading.needleLiters;
      final pointId = 'point-${proposal.evidenceId}';
      final point = state.points
          .where((item) => item.id == pointId)
          .firstOrNull;
      if (point != null) {
        final initial = purpose == CapturePurpose.finalEvidence
            ? sample.initialReading
            : null;
        final indicated = initial == null
            ? (purpose == CapturePurpose.start ? 0.0 : null)
            : calculateIndicatedVolume(
                initial: initial.reading,
                finalReading: confirmed.reading,
                referenceLiters:
                    sample.configuration.measurementMethod.isPulseEventSource
                    ? sample.pulseCount * sample.configuration.litersPerPulse
                    : sample.referenceLitersProgress ?? 0,
              );
        await dependencies.points.save(
          TestPoint(
            id: point.id,
            sampleId: point.sampleId,
            type: point.type,
            capturedAt: point.capturedAt,
            pulseCount: point.pulseCount,
            referenceLiters: point.referenceLiters,
            readingLiters: readingLiters,
            indicatedLiters: indicated,
            needleLiters: confirmed.reading.needleLiters,
            meterUnderTestPulseCount: point.meterUnderTestPulseCount,
            flowLps: point.flowLps,
          ),
        );
      }
      await _refreshSample(sample.id);
      state = state.copyWith(
        page: purpose == CapturePurpose.start ? AppPage.run : AppPage.readings,
        cameraState: CameraOperationState.confirmed,
        clearCapturePurpose: true,
        measurementStarted:
            purpose == CapturePurpose.start &&
            sample.configuration.measurementMethod != MeasurementMethod.ble &&
            sample.configuration.measurementMethod != MeasurementMethod.led,
        finalizingMeasurement: false,
      );
      if (purpose == CapturePurpose.start) {
        if (_bleSource == null) await _startBleForCurrentSample();
      }
    });
  }

  Future<void> reanalyzeRegions(DialVisionConfiguration configuration) async {
    await _guard(() async {
      final proposal = state.readingProposal;
      if (proposal == null) {
        throw StateError('No existe una foto para reanalizar.');
      }
      final sample = state.sample;
      if ((state.capturePurpose == CapturePurpose.start ||
              state.capturePurpose == CapturePurpose.cameraPreparation) &&
          sample != null) {
        await dependencies.samples.updateMeterFaceConfiguration(
          sample.id,
          configuration.toDomain(),
        );
        await _refreshSample(sample.id);
      }
      state = state.copyWith(cameraState: CameraOperationState.processing);
      final analyzed = await dependencies.visualPipeline!.extractRegions(
        evidenceId: proposal.evidenceId,
        evidencePath: proposal.evidencePath,
        configuration: configuration,
      );
      state = state.copyWith(
        readingProposal: analyzed,
        cameraState: CameraOperationState.proposalReady,
      );
    });
  }

  Future<void> previewRegionReadings(
    DialVisionConfiguration configuration,
  ) async {
    // Production camera preparation no longer interprets frames. The method is
    // retained as a compatibility no-op for older widgets/tests.
  }

  Future<void> confirmLiveCameraPreparation(
    DialVisionConfiguration configuration,
  ) async {
    await _guard(() async {
      final sample = state.sample;
      if (sample == null || sample.status != SampleStatus.running) {
        throw StateError('No existe una muestra editable para preparar.');
      }
      final updated = await dependencies.samples.updateMeterFaceConfiguration(
        sample.id,
        configuration.toDomain(),
      );
      final camera = dependencies.camera;
      if (camera case final LiveCameraAnalysisPort liveCamera) {
        await liveCamera.stopAnalysisFrames();
      }
      state = state.copyWith(
        sample: updated,
        clearCapturePurpose: true,
        clearReadingProposal: true,
        cameraState: CameraOperationState.idle,
      );
      await camera?.pause();
      state = state.copyWith(page: AppPage.run, clearError: true);
    });
  }

  Future<void> recapturePhoto() async {
    final proposal = state.readingProposal;
    if (proposal != null) {
      await _guard(() async {
        final sample = state.sample;
        final purpose = state.capturePurpose;
        if (sample != null && purpose != null) {
          final pointType = switch (purpose) {
            CapturePurpose.cameraPreparation => PointType.start,
            CapturePurpose.start => PointType.start,
            CapturePurpose.intermediate => PointType.intermediate,
            CapturePurpose.manualDiagnostic => PointType.manualDiagnostic,
            CapturePurpose.finalEvidence => PointType.finalPoint,
          };
          if (purpose != CapturePurpose.cameraPreparation) {
            await dependencies.points.deleteByTypeFromOpenSample(
              sample.id,
              pointType,
            );
          }
        }
        if (purpose != CapturePurpose.cameraPreparation) {
          await dependencies.evidence.deleteFromOpenSample(proposal.evidenceId);
        }
        await dependencies.fileStore.deleteTemporary(
          proposal.evidencePath,
          sampleClosed: false,
        );
        if (state.sample != null) await _refreshSample(state.sample!.id);
      });
    }
    state = state.copyWith(
      cameraState: CameraOperationState.idle,
      clearReadingProposal: true,
    );
  }

  Future<void> closeSample({
    required double initialTotalizer,
    required double initialNeedle,
    required double initialMeterTotalLiters,
    required double finalTotalizer,
    required double finalNeedle,
    required double finalMeterTotalLiters,
    double? visualReferenceLiters,
    bool createDevelopmentEvidence = true,
  }) async {
    await _guard(() async {
      var sample = state.sample;
      final verificationCase = state.activeCase;
      if (sample == null || verificationCase == null) {
        throw StateError('No hay una prueba activa.');
      }
      final config = sample.configuration;
      final evidence = await dependencies.evidence.listBySample(sample.id);
      final frozenFinal = evidence
          .where((item) => item.type == EvidenceType.finalEvidence)
          .lastOrNull;
      final reference = config.measurementMethod == MeasurementMethod.visual
          ? visualReferenceLiters ?? sample.referenceLitersProgress
          : frozenFinal?.volumeRefLiters ??
                sample.pulseCount * config.litersPerPulse;
      if (reference == null || reference <= 0) {
        throw ArgumentError(
          'El volumen de referencia debe ser mayor que cero.',
        );
      }
      final indicatedLiters = finalMeterTotalLiters - initialMeterTotalLiters;
      if (indicatedLiters < 0) {
        throw ArgumentError(
          'El total FINAL no puede ser menor que el total INICIO.',
        );
      }
      sample = await dependencies.samples.updateProgress(
        id: sample.id,
        pulseCount: config.measurementMethod.isPulseEventSource
            ? frozenFinal?.pulseCount ?? sample.pulseCount
            : sample.pulseCount,
        referenceLiters: reference,
        manualIndicatedLiters: indicatedLiters,
        initialReading: _confirmedFromReview(
          existing: sample.initialReading,
          odometer: initialTotalizer,
          needle: initialNeedle,
          config: config,
          evidenceId: state.initialReadingProposal?.evidenceId,
        ),
        finalReading: _confirmedFromReview(
          existing: sample.finalReading,
          odometer: finalTotalizer,
          needle: finalNeedle,
          config: config,
          evidenceId: state.readingProposal?.evidenceId,
        ),
      );
      if (createDevelopmentEvidence) {
        final plan = ExpectedEvidencePlan.derive(
          evidenceStepLiters: config.evidenceStepLiters,
          finalVolumeLiters: reference,
        );
        final existing = await dependencies.evidence.listBySample(sample.id);
        for (final requirement in plan.requirements.skip(1)) {
          final alreadyCaptured = existing.any(
            (item) =>
                item.type == requirement.type &&
                item.volumeRefLiters != null &&
                plan.volumeMatches(
                  item.volumeRefLiters!,
                  requirement.volumeRefLiters,
                ),
          );
          if (!alreadyCaptured) {
            await dependencies.evidenceCapture.capture(
              caseId: verificationCase.id,
              sample: sample,
              type: requirement.type,
              volumeRefLiters: requirement.volumeRefLiters,
              pulseCount: config.measurementMethod.isPulseEventSource
                  ? (requirement.volumeRefLiters / config.litersPerPulse)
                        .round()
                  : null,
            );
          }
        }
      }
      final closed = await dependencies.sampleClosure.closeValid(
        sample.id,
        at: DateTime.now().toUtc(),
      );
      await _refreshSample(closed.id);
      await _stopPulseSources();
      state = state.copyWith(
        page: closed.status == SampleStatus.invalidEvidence
            ? AppPage.invalidEvidence
            : AppPage.result,
      );
    });
  }

  Future<void> repeatSample() async {
    _bleUiTransitionInProgress = true;
    final inherited = await _savedCameraSetup();
    await _stopPulseSources();
    _latestMeterUnderTestCounter = null;
    _meterUnderTestCounterBaseline = null;
    _hydrantMonitorCounterBaseline = null;
    state = state.copyWith(
      page: inherited == null ? AppPage.setup : state.page,
      clearSample: true,
      clearInitialReadingProposal: true,
      clearReadingProposal: true,
      evidence: [],
      meterUnderTestPulseCount: 0,
      clearMeterUnderTestFirstPulseAt: true,
      hydrantMonitorPulseCount: 0,
      clearHydrantMonitorFirstPulseAt: true,
    );
    if (inherited != null) {
      await startSample(
        inheritedMeterFaceConfiguration: inherited.$1,
        inheritedCameraZoom: inherited.$2,
      );
      if (state.page != AppPage.run) _bleUiTransitionInProgress = false;
    } else {
      _bleUiTransitionInProgress = false;
    }
  }

  Future<void> anotherSample() async {
    final current = state.sample;
    final verificationCase = state.activeCase;
    if (current?.configuration.flowPoint == FlowPoint.q1 &&
        current?.status == SampleStatus.closedValid &&
        verificationCase != null) {
      final flows = await dependencies.flows.listByCase(verificationCase.id);
      final q2 = flows.where((item) => item.code == FlowPoint.q2).firstOrNull;
      if (q2 != null) {
        _bleUiTransitionInProgress = true;
        final inherited = await _savedCameraSetup();
        await _stopPulseSources();
        _latestMeterUnderTestCounter = null;
        _meterUnderTestCounterBaseline = null;
        _hydrantMonitorCounterBaseline = null;
        state = state.copyWith(
          page: inherited == null ? AppPage.setup : state.page,
          flow: q2,
          selectedFlow: FlowPoint.q2,
          lpsApprox: q2.lpsApprox,
          clearSample: true,
          clearInitialReadingProposal: true,
          clearReadingProposal: true,
          evidence: [],
          meterUnderTestPulseCount: 0,
          clearMeterUnderTestFirstPulseAt: true,
          hydrantMonitorPulseCount: 0,
          clearHydrantMonitorFirstPulseAt: true,
        );
        if (inherited != null) {
          await startSample(
            inheritedMeterFaceConfiguration: inherited.$1,
            inheritedCameraZoom: inherited.$2,
          );
          if (state.page != AppPage.run) _bleUiTransitionInProgress = false;
        } else {
          _bleUiTransitionInProgress = false;
        }
        return;
      }
    }
    await repeatSample();
  }

  Future<(MeterFaceConfiguration, double)?> _savedCameraSetup() async {
    final verificationCase = state.activeCase;
    if (verificationCase == null) return null;
    final flows = await dependencies.flows.listByCase(verificationCase.id);
    final candidates = <Sample>[];
    for (final flow in flows) {
      candidates.addAll(await dependencies.samples.listByFlow(flow.id));
    }
    candidates.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    for (final sample in candidates) {
      if (sample.meterFaceConfiguration case final face?) {
        return (face, sample.configuration.cameraZoomLevel);
      }
    }
    return null;
  }

  Future<void> changeFlow() async {
    state = state.copyWith(
      page: AppPage.identification,
      clearFlow: true,
      clearSample: true,
      evidence: [],
    );
  }

  Future<void> showCaseSummary() async {
    final verificationCase = state.activeCase;
    if (verificationCase == null) return;
    await _guard(() async {
      final flows = await dependencies.flows.listByCase(verificationCase.id);
      final samples = <Sample>[];
      final points = <String, List<TestPoint>>{};
      final evidence = <String, List<Evidence>>{};
      for (final flow in flows) {
        samples.addAll(await dependencies.samples.listByFlow(flow.id));
      }
      for (final sample in samples) {
        points[sample.id] = await dependencies.points.listBySample(sample.id);
        evidence[sample.id] = await dependencies.evidence.listBySample(
          sample.id,
        );
      }
      state = state.copyWith(
        page: AppPage.caseSummary,
        samples: samples,
        casePointsBySample: points,
        caseEvidenceBySample: evidence,
        reportSampleIds: samples
            .where((sample) => sample.status == SampleStatus.closedValid)
            .map((sample) => sample.id)
            .toSet(),
      );
    });
  }

  Future<void> closeCase() async {
    final verificationCase = state.activeCase;
    if (verificationCase == null) return;
    await _guard(() async {
      final flows = await dependencies.flows.listByCase(verificationCase.id);
      final closed = await dependencies.caseClosure.closeCase(
        caseId: verificationCase.id,
        requiredFlowPoints: flows.map((item) => item.code).toSet(),
        at: DateTime.now().toUtc(),
      );
      state = state.copyWith(activeCase: closed, page: AppPage.caseSummary);
    });
  }

  Future<void> exportCurrentCase() async {
    final verificationCase = state.activeCase;
    final user = state.user;
    final meter = state.meter;
    if (verificationCase == null || user == null || meter == null) return;
    await _guard(() async {
      final flows = await dependencies.flows.listByCase(verificationCase.id);
      final samples = <Sample>[];
      final points = <String, List<TestPoint>>{};
      final evidence = <String, List<Evidence>>{};
      for (final flow in flows) {
        final flowSamples = (await dependencies.samples.listByFlow(flow.id))
            .where(
              (sample) =>
                  state.reportSampleIds.isEmpty ||
                  state.reportSampleIds.contains(sample.id),
            )
            .toList();
        samples.addAll(flowSamples);
        for (final sample in flowSamples) {
          points[sample.id] = await dependencies.points.listBySample(sample.id);
          evidence[sample.id] = await dependencies.evidence.listBySample(
            sample.id,
          );
        }
      }
      final files = await dependencies.caseExport.export(
        CaseExportBundle(
          user: user,
          meter: meter,
          verificationCase: verificationCase,
          flows: flows,
          samples: samples,
          pointsBySample: points,
          evidenceBySample: evidence,
        ),
      );
      state = state.copyWith(exportedFiles: files);
    });
  }

  void toggleReportSample(String sampleId, bool selected) {
    final ids = {...state.reportSampleIds};
    if (selected) {
      ids.add(sampleId);
    } else {
      ids.remove(sampleId);
    }
    state = state.copyWith(reportSampleIds: ids, clearError: true);
  }

  Future<void> syncCurrentCase() async {
    final api = dependencies.remoteApi;
    final token = await dependencies.tokenStore?.read();
    final verificationCase = state.activeCase;
    final user = state.user;
    if (api == null || token == null) {
      state = state.copyWith(
        syncMessage: 'Pendiente local · backend no configurado',
      );
      return;
    }
    if (verificationCase == null || user == null) return;
    await _guard(() async {
      state = state.copyWith(syncMessage: 'Sincronizando…');
      final flows = await dependencies.flows.listByCase(verificationCase.id);
      final samples = <Sample>[];
      for (final flow in flows) {
        samples.addAll(
          (await dependencies.samples.listByFlow(
            flow.id,
          )).where((sample) => sample.status == SampleStatus.closedValid),
        );
      }
      // Binary evidence is staged first. The server associates it when the
      // immutable Sample metadata arrives.
      for (final sample in samples) {
        for (final evidence in await dependencies.evidence.listBySample(
          sample.id,
        )) {
          await api.uploadEvidence(token: token, evidence: evidence);
        }
      }
      await api.postJson('/api/v1/cases', token, {
        'case_id': verificationCase.id,
        'meter_id': verificationCase.meterId,
        'user_id': verificationCase.userId,
        'status': verificationCase.status.name.toUpperCase(),
        'overall_verdict': _overallVerdictApi(verificationCase.overallVerdict),
        'report_version': verificationCase.reportVersion,
        'test_bench_id': verificationCase.testBenchId,
        'device': {
          'id': verificationCase.deviceId,
          'android_version': verificationCase.androidVersion,
          'brand': verificationCase.deviceBrand,
          'model': verificationCase.deviceModel,
        },
        'checksum': verificationCase.checksum,
        'created_at': verificationCase.createdAt.toUtc().toIso8601String(),
        'closed_at': verificationCase.closedAt?.toUtc().toIso8601String(),
      });
      for (final flow in flows) {
        await api.postJson(
          '/api/v1/cases/${verificationCase.id}/flow-points',
          token,
          {
            'flow_point_id': flow.id,
            'code': flow.code.name.toUpperCase(),
            'status': flow.status.name.toUpperCase(),
            'lps_approx': flow.lpsApprox,
            'mpe_pct': flow.mpePct,
            'created_at': flow.createdAt.toUtc().toIso8601String(),
          },
        );
      }
      for (final sample in samples) {
        await api.postJson('/api/v1/samples', token, _sampleSyncJson(sample));
      }
      final syncedEntityIds = <String>{
        verificationCase.id,
        ...flows.map((flow) => flow.id),
        ...samples.map((sample) => sample.id),
      };
      for (final sample in samples) {
        syncedEntityIds.addAll(
          (await dependencies.evidence.listBySample(
            sample.id,
          )).map((evidence) => evidence.id),
        );
      }
      for (final item in await dependencies.sync.listPending()) {
        if (syncedEntityIds.contains(item.entityId)) {
          await dependencies.sync.markSynced(
            item.id,
            at: DateTime.now().toUtc(),
          );
        }
      }
      state = state.copyWith(syncMessage: 'Sincronizado');
    });
  }

  Map<String, Object?> _sampleSyncJson(Sample sample) => {
    'sample_id': sample.id,
    'flow_point_id': sample.flowPointId,
    'sample_number': sample.sampleNumber,
    'status': 'CLOSED_VALID',
    'checksum': sample.checksum,
    'created_at': sample.createdAt.toUtc().toIso8601String(),
    'started_at': sample.startedAt?.toUtc().toIso8601String(),
    'ended_at': sample.endedAt?.toUtc().toIso8601String(),
    'measurement_source': sample.configuration.measurementMethod.name
        .toUpperCase(),
    'pulse_count': sample.pulseCount,
    'acquisition_integrity': sample.acquisitionIntegrity.status.name
        .toUpperCase(),
    'result': sample.result == null
        ? null
        : {
            'v_ref_l': sample.result!.referenceLiters,
            'v_ind_l': sample.result!.indicatedLiters,
            'error_pct': sample.result!.errorPct,
            'uncertainty_pct': sample.result!.uncertaintyPct,
            'mpe_pct': sample.result!.mpePct,
            'verdict': sample.result!.verdict.name.toUpperCase(),
          },
  };

  String? _overallVerdictApi(OverallVerdict? verdict) => switch (verdict) {
    OverallVerdict.approved => 'APROBADO',
    OverallVerdict.rejected => 'RECHAZADO',
    OverallVerdict.inconclusive => 'NO_CONCLUYENTE',
    null => null,
  };

  Future<void> resumeSample() async {
    final sample = state.sample;
    if (sample != null) {
      if (sample.initialReading != null && sample.finalReading != null) {
        state = state.copyWith(page: AppPage.readings);
        return;
      }
      final hasStart = state.evidence.any(
        (item) => item.type == EvidenceType.start,
      );
      if (!hasStart && dependencies.camera != null) {
        if (sample.meterFaceConfiguration == null) {
          state = state.copyWith(
            page: AppPage.camera,
            capturePurpose: CapturePurpose.cameraPreparation,
            captureVolumeLiters: 0,
            cameraState: CameraOperationState.idle,
          );
        } else {
          await _startBleForCurrentSample();
          state = state.copyWith(page: AppPage.run);
        }
      } else {
        await _startBleForCurrentSample();
        state = state.copyWith(page: AppPage.run);
      }
    }
  }

  Future<void> _loadSampleContext(Sample sample) async {
    final flow = await dependencies.flows.getById(sample.flowPointId);
    if (flow == null) {
      throw StateError('No se encontró el caudal de la muestra.');
    }
    final verificationCase = await dependencies.cases.getById(flow.caseId);
    if (verificationCase == null) {
      throw StateError('No se encontró el expediente de la muestra.');
    }
    final meter = await dependencies.meters.getById(verificationCase.meterId);
    final evidence = await dependencies.evidence.listBySample(sample.id);
    final points = await dependencies.points.listBySample(sample.id);
    final samples = await dependencies.samples.listByFlow(flow.id);
    state = state.copyWith(
      activeCase: verificationCase,
      meter: meter,
      flow: flow,
      sample: sample,
      selectedFlow: flow.code,
      selectedMethod: sample.configuration.measurementMethod,
      lpsApprox: flow.lpsApprox,
      cameraZoomLevel: sample.configuration.cameraZoomLevel,
      evidence: evidence,
      points: points,
      samples: samples,
      gps: sample.gps,
      gpsCaptureState: sample.gps == null
          ? GpsCaptureState.idle
          : GpsCaptureState.captured,
      measurementStarted:
          sample.pulseCount > 0 ||
          evidence.any((item) => item.type == EvidenceType.start),
    );
  }

  Future<void> _refreshSample(String id) async {
    final sample = await dependencies.samples.getById(id);
    if (sample == null) throw StateError('No se encontró la muestra.');
    await _loadSampleContext(sample);
  }

  Future<double?> _firstMissingIntermediate(
    Sample sample,
    double currentReference,
  ) async {
    final evidence = await dependencies.evidence.listBySample(sample.id);
    final step = sample.configuration.evidenceStepLiters;
    for (var volume = step; volume < currentReference; volume += step) {
      final captured = evidence.any(
        (item) =>
            item.type == EvidenceType.intermediate &&
            item.volumeRefLiters != null &&
            (item.volumeRefLiters! - volume).abs() <=
                ExpectedEvidencePlan.comparisonEpsilon,
      );
      if (!captured) return volume;
    }
    return null;
  }

  Future<void> _openDueIntermediateEvidence(String sampleId) async {
    if (_openingIntermediateEvidence || state.page != AppPage.run) return;
    final sample = await dependencies.samples.getById(sampleId);
    if (sample == null || sample.status != SampleStatus.running) return;
    final current = sample.configuration.measurementMethod.isPulseEventSource
        ? sample.pulseCount * sample.configuration.litersPerPulse
        : sample.referenceLitersProgress ?? 0;
    if (current <= 0) return;
    final missing = await _firstMissingIntermediate(sample, current + 1e-9);
    if (missing == null || missing > current) return;
    _openingIntermediateEvidence = true;
    try {
      await requestIntermediateEvidence(missing);
    } finally {
      _openingIntermediateEvidence = false;
    }
  }

  Future<void> _startBleForCurrentSample() async {
    final sample = state.sample;
    if (sample == null ||
        (sample.configuration.measurementMethod != MeasurementMethod.ble &&
            sample.configuration.measurementMethod != MeasurementMethod.led)) {
      return;
    }
    final persisted = sample.pulseAcquisitionConfiguration;
    final selected = state.selectedBleDevice;
    final deviceId = persisted?.bleDeviceId ?? selected?.id;
    if (deviceId == null) {
      throw StateError('Seleccione un ESP32 DDR001 antes de iniciar BLE.');
    }
    if (_bleSource != null && _bleBoundSampleId == sample.id) {
      final status = _bleSource!.currentState.status;
      if (status == PulseSourceStatus.disconnected ||
          status == PulseSourceStatus.stopped ||
          status == PulseSourceStatus.error) {
        await _bleSource!.start();
      }
      return;
    }
    final reusableSource =
        _bleSource != null &&
        _bleSource!.deviceId == deviceId &&
        _bleSource!.currentState.status != PulseSourceStatus.stopped &&
        _bleSource!.currentState.status != PulseSourceStatus.disconnected &&
        _bleSource!.currentState.status != PulseSourceStatus.error;
    if (!reusableSource) {
      await _bleSource?.dispose();
      _bleSource = null;
    }
    await _pulseSubscription?.cancel();
    await _pulseStateSubscription?.cancel();
    await _counterSubscription?.cancel();
    await _meterUnderTestCounterSubscription?.cancel();
    final source =
        _bleSource ??
        BlePulseSource(
          BlePulseConfiguration(
            deviceId: deviceId,
            deviceName: persisted?.bleDeviceName ?? selected?.name,
            serviceUuid: Ddr001BleContract.serviceUuid,
            characteristicUuid: Ddr001BleContract.counterCharacteristicUuid,
            lastObservedCounter: persisted?.lastObservedEsp32Counter,
          ),
        );
    _bleSource = source;
    _bleBoundSampleId = sample.id;
    _pulseSubscription = source.events.listen((event) {
      if (_bleUiTransitionInProgress) return;
      if (state.sample?.id != sample.id) return;
      if (state.finalizingMeasurement || _sampleEndpointFrozen) return;
      final countsTowardMeasurement = state.measurementStarted;
      _pulseQueue = _pulseQueue.then((_) async {
        if (state.sample?.id != sample.id) return;
        // This monitor is deliberately continuous across the START boundary.
        // Official Sample pulses are persisted only after measurementStarted.
        state = state.copyWith(
          preStartControlPulseCount: state.preStartControlPulseCount + 1,
          preStartControlFirstPulseAt:
              state.preStartControlFirstPulseAt ?? event.receivedAt,
        );
        if (!countsTowardMeasurement) return;
        if (sample.configuration.measurementMethod == MeasurementMethod.ble) {
          await dependencies.pulseProgress.acceptPulse(sample.id, event);
          await _refreshSample(sample.id);
          if (!state.finalizingMeasurement) {
            await _openDueIntermediateEvidence(sample.id);
          }
        }
      });
    });
    _pulseStateSubscription = source.states.listen((pulseState) {
      if (_bleUiTransitionInProgress) return;
      if (state.sample?.id != sample.id) return;
      final message = pulseState.message?.trim();
      state = state.copyWith(
        hardwareState: switch (pulseState.status) {
          PulseSourceStatus.ready => HardwareState.ready,
          PulseSourceStatus.connecting ||
          PulseSourceStatus.reconnecting => HardwareState.preparing,
          PulseSourceStatus.error => HardwareState.error,
          _ => HardwareState.disconnected,
        },
        errorMessage: message?.isNotEmpty == true ? message : null,
        clearError:
            message?.isNotEmpty != true &&
            (pulseState.status == PulseSourceStatus.ready ||
                pulseState.status == PulseSourceStatus.connected),
      );
      if (pulseState.compromised) {
        unawaited(_markAcquisitionCompromised(sample.id, pulseState.message));
      }
    });
    _counterSubscription = source.counters.listen((counter) async {
      if (_bleUiTransitionInProgress) return;
      if (state.sample?.id != sample.id) return;
      final current = await dependencies.samples.getById(sample.id);
      if (current == null || current.status != SampleStatus.running) return;
      if (state.sample?.id != sample.id) return;
      final old = current.pulseAcquisitionConfiguration;
      final configuration = PulseAcquisitionConfiguration(
        bleDeviceId: deviceId,
        bleDeviceName: persisted?.bleDeviceName ?? selected?.name,
        bleServiceUuid: Ddr001BleContract.serviceUuid,
        bleCounterCharacteristicUuid:
            Ddr001BleContract.counterCharacteristicUuid,
        bleProtocolVersion: Ddr001BleContract.protocolVersion,
        esp32CounterAtStart: old?.esp32CounterAtStart ?? counter,
        lastObservedEsp32Counter: counter,
        ledRoiLeft: old?.ledRoiLeft,
        ledRoiTop: old?.ledRoiTop,
        ledRoiWidth: old?.ledRoiWidth,
        ledRoiHeight: old?.ledRoiHeight,
        ledRisingDelta: old?.ledRisingDelta,
        ledFallingDelta: old?.ledFallingDelta,
        ledMinPulseIntervalMs: old?.ledMinPulseIntervalMs,
        ledBaseline: old?.ledBaseline,
        ledUsesBleReconciliation:
            old?.ledUsesBleReconciliation ??
            sample.configuration.measurementMethod == MeasurementMethod.led,
      );
      await dependencies.samples.updatePulseAcquisition(
        id: sample.id,
        configuration: configuration,
        integrity: current.acquisitionIntegrity,
      );
      _latestEsp32Counter = counter;
      if (sample.configuration.measurementMethod == MeasurementMethod.led) {
        _scheduleLedReconciliation(sample.id);
        if (old?.ledBaseline != null &&
            _ledSource == null &&
            state.page == AppPage.run) {
          unawaited(_restorePersistedLedDetector(current, old!));
        }
      }
    });
    _meterUnderTestCounterBaseline = null;
    _hydrantMonitorCounterBaseline = null;
    _meterUnderTestCounterSubscription = source.meterUnderTestCounters.listen((
      counter,
    ) {
      if (_bleUiTransitionInProgress) return;
      if (state.sample?.id != sample.id) return;
      _latestMeterUnderTestCounter = counter;
      final monitorBaseline = _hydrantMonitorCounterBaseline;
      if (monitorBaseline == null || counter < monitorBaseline) {
        _hydrantMonitorCounterBaseline = counter;
        state = state.copyWith(
          hydrantMonitorPulseCount: 0,
          clearHydrantMonitorFirstPulseAt: true,
        );
      } else {
        final monitorPulses = counter - monitorBaseline;
        if (monitorPulses != state.hydrantMonitorPulseCount) {
          state = state.copyWith(
            hydrantMonitorPulseCount: monitorPulses,
            hydrantMonitorFirstPulseAt:
                monitorPulses > 0 && state.hydrantMonitorFirstPulseAt == null
                ? DateTime.now().toUtc()
                : state.hydrantMonitorFirstPulseAt,
          );
        }
      }
      if (!state.measurementStarted) return;
      final baseline = _meterUnderTestCounterBaseline;
      if (baseline == null || counter < baseline) {
        _meterUnderTestCounterBaseline = counter;
        state = state.copyWith(meterUnderTestPulseCount: 0);
        return;
      }
      final pulses = counter - baseline;
      if (pulses != state.meterUnderTestPulseCount) {
        state = state.copyWith(
          meterUnderTestPulseCount: pulses,
          meterUnderTestFirstPulseAt:
              pulses > 0 && state.meterUnderTestFirstPulseAt == null
              ? DateTime.now().toUtc()
              : state.meterUnderTestFirstPulseAt,
        );
      }
    });
    if (!reusableSource) await source.start();
  }

  void _enterRunPageAfterBleStart() {
    _bleUiTransitionInProgress = true;
    state = state.copyWith(page: AppPage.run, busy: false);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _bleUiTransitionInProgress = false;
    });
  }

  void _resetHydrantRunState() {
    _sampleEndpointFrozen = false;
    _latestMeterUnderTestCounter = null;
    _meterUnderTestCounterBaseline = null;
    _hydrantMonitorCounterBaseline = null;
    state = state.copyWith(
      meterUnderTestPulseCount: 0,
      clearMeterUnderTestFirstPulseAt: true,
      hydrantMonitorPulseCount: 0,
      clearHydrantMonitorFirstPulseAt: true,
    );
  }

  Future<void> prepareLedDetector(LedRegion region) async {
    final sample = state.sample;
    final camera = dependencies.camera;
    if (sample == null ||
        sample.configuration.measurementMethod != MeasurementMethod.led ||
        camera is! LedBrightnessPort) {
      throw StateError('Detector LED no disponible para esta Sample.');
    }
    if (_bleSource?.currentState.status != PulseSourceStatus.ready) {
      throw StateError('El contador BLE auxiliar debe estar READY.');
    }
    final frames = camera as LedBrightnessPort;
    await _guard(() async {
      final decision = _cameraCoordinator.acquire(CameraConsumer.ledDetector);
      if (!decision.allowed) {
        throw StateError(decision.message ?? 'Cámara LED no disponible.');
      }
      state = state.copyWith(
        hardwareState: HardwareState.preparing,
        ledRegion: region,
      );
      await frames.start(region);
      final samples = await frames.samples
          .map((sample) => sample.brightness)
          .take(45)
          .timeout(const Duration(seconds: 4))
          .toList();
      await frames.stop();
      if (samples.length < 10) {
        throw StateError('No se recibieron suficientes frames LED.');
      }
      final sorted = [...samples]..sort();
      final darkCount = (sorted.length * .60).floor().clamp(1, sorted.length);
      final darkSamples = sorted.take(darkCount).toList();
      final dark = darkSamples.reduce((a, b) => a + b) / darkSamples.length;
      final bright = sorted.last;
      final contrast = bright - dark;
      final risingDelta = contrast >= 12 ? contrast * .45 : 35.0;
      final fallingDelta = contrast >= 12 ? contrast * .20 : 20.0;
      final detector = LedPulseDetector(
        LedDetectorConfiguration(
          region: region,
          risingDelta: risingDelta,
          fallingDelta: fallingDelta,
          minPulseInterval: const Duration(milliseconds: 150),
        ),
      )..calibrate(darkSamples);
      await _ledSubscription?.cancel();
      await _ledSource?.dispose();
      final source = LedPulseSource(frames, detector);
      _ledSource = source;
      _ledSubscription = source.events.listen((event) {
        _pendingOpticalPulses++;
        state = state.copyWith(ledLivePulses: state.ledLivePulses + 1);
        _scheduleLedReconciliation(sample.id);
      });
      await dependencies.samples.updatePulseAcquisition(
        id: sample.id,
        configuration: _ledConfiguration(
          sample,
          region: region,
          baseline: dark,
          risingDelta: risingDelta,
          fallingDelta: fallingDelta,
        ),
        integrity: sample.acquisitionIntegrity,
      );
      await source.start();
      final adapter = dependencies.camera is FlutterCameraAdapter
          ? dependencies.camera! as FlutterCameraAdapter
          : null;
      _startLedMetrics(adapter);
      state = state.copyWith(
        hardwareState: HardwareState.ready,
        ledDarkBrightness: dark,
        ledBrightBrightness: bright,
        ledFps: adapter?.effectiveFps,
        ledFramesDropped: adapter?.framesDropped,
      );
      await _refreshSample(sample.id);
    });
  }

  Future<void> _restorePersistedLedDetector(
    Sample sample,
    PulseAcquisitionConfiguration configuration,
  ) async {
    final camera = dependencies.camera;
    if (camera is! LedBrightnessPort ||
        configuration.ledBaseline == null ||
        configuration.ledRoiLeft == null ||
        configuration.ledRoiTop == null ||
        configuration.ledRoiWidth == null ||
        configuration.ledRoiHeight == null) {
      return;
    }
    final region = LedRegion(
      left: configuration.ledRoiLeft!,
      top: configuration.ledRoiTop!,
      width: configuration.ledRoiWidth!,
      height: configuration.ledRoiHeight!,
    );
    final detector = LedPulseDetector(
      LedDetectorConfiguration(
        region: region,
        risingDelta: configuration.ledRisingDelta ?? 35,
        fallingDelta: configuration.ledFallingDelta ?? 20,
        minPulseInterval: Duration(
          milliseconds: configuration.ledMinPulseIntervalMs ?? 150,
        ),
      ),
    )..calibrate([configuration.ledBaseline!]);
    final decision = _cameraCoordinator.acquire(CameraConsumer.ledDetector);
    if (!decision.allowed) return;
    final frames = camera as LedBrightnessPort;
    final source = LedPulseSource(frames, detector);
    _ledSource = source;
    await _ledSubscription?.cancel();
    _ledSubscription = source.events.listen((event) {
      _pendingOpticalPulses++;
      state = state.copyWith(ledLivePulses: state.ledLivePulses + 1);
      _scheduleLedReconciliation(sample.id);
    });
    try {
      await source.start();
      _startLedMetrics(
        dependencies.camera is FlutterCameraAdapter
            ? dependencies.camera! as FlutterCameraAdapter
            : null,
      );
      state = state.copyWith(
        hardwareState: HardwareState.ready,
        ledRegion: region,
        ledDarkBrightness: configuration.ledBaseline,
      );
    } catch (error) {
      await _markAcquisitionCompromised(
        sample.id,
        'No fue posible recuperar detector LED: $error',
      );
    }
  }

  PulseAcquisitionConfiguration _ledConfiguration(
    Sample sample, {
    required LedRegion region,
    required double baseline,
    required double risingDelta,
    required double fallingDelta,
  }) {
    final old = sample.pulseAcquisitionConfiguration;
    return PulseAcquisitionConfiguration(
      bleDeviceId: old?.bleDeviceId ?? state.selectedBleDevice?.id,
      bleDeviceName: old?.bleDeviceName ?? state.selectedBleDevice?.name,
      bleServiceUuid: Ddr001BleContract.serviceUuid,
      bleCounterCharacteristicUuid: Ddr001BleContract.counterCharacteristicUuid,
      bleProtocolVersion: Ddr001BleContract.protocolVersion,
      esp32CounterAtStart: old?.esp32CounterAtStart,
      lastObservedEsp32Counter:
          _latestEsp32Counter ?? old?.lastObservedEsp32Counter,
      ledRoiLeft: region.left,
      ledRoiTop: region.top,
      ledRoiWidth: region.width,
      ledRoiHeight: region.height,
      ledRisingDelta: risingDelta,
      ledFallingDelta: fallingDelta,
      ledMinPulseIntervalMs: 150,
      ledBaseline: baseline,
      ledUsesBleReconciliation: true,
    );
  }

  void _scheduleLedReconciliation(String sampleId) {
    _ledReconciliationTimer?.cancel();
    _ledReconciliationTimer = Timer(
      const Duration(milliseconds: 750),
      () => _pulseQueue = _pulseQueue.then(
        (_) => _flushLedReconciliation(sampleId),
      ),
    );
  }

  Future<void> _flushLedReconciliation(String sampleId) async {
    final sample = await dependencies.samples.getById(sampleId);
    final counter = _latestEsp32Counter;
    final baseline = sample?.pulseAcquisitionConfiguration?.esp32CounterAtStart;
    if (sample == null ||
        sample.status != SampleStatus.running ||
        counter == null ||
        baseline == null) {
      return;
    }
    int truth;
    try {
      truth = esp32CounterDelta(baseline: baseline, current: counter);
    } on StateError catch (error) {
      await _markAcquisitionCompromised(sampleId, error.message);
      return;
    }
    var missing = truth - sample.pulseCount;
    if (missing < 0) {
      final excess = -missing;
      state = state.copyWith(
        ledFalsePositives: state.ledFalsePositives + excess,
      );
      await _markAcquisitionCompromised(
        sampleId,
        'El detector LED excedió el contador acumulativo ESP32.',
      );
      return;
    }
    final matchedLive = _pendingOpticalPulses.clamp(0, missing);
    final unmatchedOptical = _pendingOpticalPulses - matchedLive;
    _pendingOpticalPulses = 0;
    if (unmatchedOptical > 0) {
      state = state.copyWith(
        ledFalsePositives: state.ledFalsePositives + unmatchedOptical,
      );
    }
    for (var i = 0; i < matchedLive; i++) {
      await _acceptLedPulse(sampleId, 'optical-confirmed-$counter-$i');
    }
    missing -= matchedLive;
    for (var i = 0; i < missing; i++) {
      await _acceptLedPulse(sampleId, 'ble-reconciled-$counter-$i');
    }
    if (missing > 0) {
      state = state.copyWith(
        ledReconciledPulses: state.ledReconciledPulses + missing,
      );
    }
    await _refreshSample(sampleId);
  }

  Future<void> _acceptLedPulse(String sampleId, String id) async {
    if (_sampleEndpointFrozen) return;
    final now = DateTime.now().toUtc();
    await dependencies.pulseProgress.acceptPulse(
      sampleId,
      PulseEvent(
        id: id,
        source: PulseSourceType.led,
        occurredAt: now,
        receivedAt: now,
      ),
    );
  }

  Future<void> _pauseLedForEvidence() async {
    final sample = state.sample;
    if (sample?.configuration.measurementMethod != MeasurementMethod.led) {
      return;
    }
    await _ledSource?.stop();
    _cameraCoordinator.release(CameraConsumer.ledDetector);
    final decision = _cameraCoordinator.acquire(CameraConsumer.evidence);
    if (!decision.allowed) {
      await _markAcquisitionCompromised(sample!.id, decision.message);
      throw StateError(decision.message ?? 'Cámara no disponible.');
    }
  }

  Future<void> _resumeLedAfterEvidence(Sample sample) async {
    if (sample.configuration.measurementMethod != MeasurementMethod.led) return;
    _cameraCoordinator.release(CameraConsumer.evidence);
    final decision = _cameraCoordinator.acquire(CameraConsumer.ledDetector);
    if (!decision.allowed || _ledSource == null) {
      await _markAcquisitionCompromised(
        sample.id,
        decision.message ?? 'No fue posible restablecer detector LED.',
      );
      return;
    }
    try {
      await _ledSource!.start();
      await _flushLedReconciliation(sample.id);
      state = state.copyWith(hardwareState: HardwareState.ready);
    } catch (error) {
      await _markAcquisitionCompromised(
        sample.id,
        'No fue posible restablecer detector LED: $error',
      );
    }
  }

  Future<void> _stopBleCounterSource() async {
    _ledReconciliationTimer?.cancel();
    await _counterSubscription?.cancel();
    _counterSubscription = null;
    await _meterUnderTestCounterSubscription?.cancel();
    _meterUnderTestCounterSubscription = null;
  }

  void _startLedMetrics(FlutterCameraAdapter? adapter) {
    _ledMetricsTimer?.cancel();
    if (adapter == null) return;
    _ledMetricsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        ledFps: adapter.effectiveFps,
        ledFramesDropped: adapter.framesDropped,
      );
    });
  }

  Future<void> _stopPulseSources() async {
    _ledMetricsTimer?.cancel();
    _ledReconciliationTimer?.cancel();
    await _ledSubscription?.cancel();
    await _ledSource?.dispose();
    _ledSource = null;
    await _pulseSubscription?.cancel();
    await _pulseStateSubscription?.cancel();
    await _counterSubscription?.cancel();
    _counterSubscription = null;
    await _meterUnderTestCounterSubscription?.cancel();
    _meterUnderTestCounterSubscription = null;
    _bleBoundSampleId = null;
  }

  Future<void> _disconnectBleTransport() async {
    await _stopPulseSources();
    await _bleSource?.dispose();
    _bleSource = null;
  }

  Future<void> _markAcquisitionCompromised(
    String sampleId,
    String? reason,
  ) async {
    final current = await dependencies.samples.getById(sampleId);
    if (current == null || current.status != SampleStatus.running) return;
    await dependencies.samples.updatePulseAcquisition(
      id: sampleId,
      configuration:
          current.pulseAcquisitionConfiguration ??
          const PulseAcquisitionConfiguration(),
      integrity: AcquisitionIntegrity(
        status: AcquisitionIntegrityStatus.compromised,
        reason: reason ?? 'Conteo de pulsos no verificable.',
        occurredAt: DateTime.now().toUtc(),
        source: current.configuration.measurementMethod,
      ),
    );
    await _refreshSample(sampleId);
  }

  Future<void> _guard(
    Future<void> Function() operation, {
    bool showBusy = true,
  }) async {
    state = state.copyWith(busy: showBusy, clearError: true);
    try {
      await operation();
    } on ArgumentError catch (error) {
      state = state.copyWith(errorMessage: _friendly(error.message));
    } on StateError catch (error) {
      state = state.copyWith(errorMessage: _friendly(error.message));
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'No fue posible completar la operación local.',
      );
    } finally {
      if (state.busy) state = state.copyWith(busy: false);
    }
  }

  String _friendly(Object? message) =>
      message?.toString() ?? 'La operación no está permitida.';

  @override
  void dispose() {
    unawaited(_disconnectBleTransport());
    super.dispose();
  }

  ConfirmedReading _confirmedFromReview({
    required ConfirmedReading? existing,
    required double odometer,
    required double needle,
    required SampleConfiguration config,
    String? evidenceId,
  }) {
    final unchanged =
        existing != null &&
        existing.reading.odometerUnits == odometer &&
        existing.reading.needleLiters == needle;
    return ConfirmedReading(
      reading: MeterReading(
        odometerUnits: odometer,
        needleLiters: needle,
        litersPerOdometerUnit: config.litersPerOdometerUnit,
        needleLitersPerRevolution: config.needleLitersPerRevolution,
      ),
      source: unchanged ? existing.source : ReadingSource.manual,
      evidenceId: existing?.evidenceId ?? evidenceId,
    );
  }

  GpsCaptureState _gpsStateForFailure(LocationFailureKind kind) =>
      switch (kind) {
        LocationFailureKind.serviceDisabled => GpsCaptureState.serviceDisabled,
        LocationFailureKind.denied => GpsCaptureState.denied,
        LocationFailureKind.permanentlyDenied =>
          GpsCaptureState.permanentlyDenied,
        LocationFailureKind.timeout => GpsCaptureState.timeout,
        LocationFailureKind.unavailable => GpsCaptureState.error,
      };
}
