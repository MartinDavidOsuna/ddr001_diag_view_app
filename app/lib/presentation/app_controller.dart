import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../app/app_dependencies.dart';
import '../core/metrology/metrology.dart';
import '../domain/expected_evidence_plan.dart';
import '../domain/models.dart';
import '../domain/pulse/pulse_source.dart';
import '../infrastructure/camera/camera_models.dart';
import '../infrastructure/vision/vision_models.dart';
import '../infrastructure/pulse/ble_discovery.dart';
import '../infrastructure/pulse/ble_pulse_source.dart';
import '../domain/pulse/esp32_counter_protocol.dart';
import '../infrastructure/pulse/camera_resource_coordinator.dart';
import '../infrastructure/pulse/led_pulse_detector.dart';
import '../infrastructure/camera/flutter_camera_adapter.dart';

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
  invalidEvidence,
  camera,
  debugCalibration,
}

enum CapturePurpose { start, intermediate, finalEvidence }

enum HardwareState { notConnected, preparing, ready, error, disconnected }

final class AppViewState {
  const AppViewState({
    this.page = AppPage.loading,
    this.busy = false,
    this.user,
    this.activeCase,
    this.meter,
    this.flow,
    this.sample,
    this.selectedFlow = FlowPoint.q3,
    this.selectedMethod = MeasurementMethod.visual,
    this.lpsApprox,
    this.litersPerPulse = 1,
    this.evidenceStepLiters = 25,
    this.readingUncertaintyLiters = 1,
    this.hardwareState = HardwareState.notConnected,
    this.evidence = const [],
    this.samples = const [],
    this.cases = const [],
    this.errorMessage,
    this.capturePurpose,
    this.captureVolumeLiters,
    this.cameraState = CameraOperationState.idle,
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
  final double litersPerPulse;
  final double evidenceStepLiters;
  final double readingUncertaintyLiters;
  final HardwareState hardwareState;
  final List<Evidence> evidence;
  final List<Sample> samples;
  final List<VerificationCase> cases;
  final String? errorMessage;
  final CapturePurpose? capturePurpose;
  final double? captureVolumeLiters;
  final CameraOperationState cameraState;
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
    double? litersPerPulse,
    double? evidenceStepLiters,
    double? readingUncertaintyLiters,
    HardwareState? hardwareState,
    List<Evidence>? evidence,
    List<Sample>? samples,
    List<VerificationCase>? cases,
    String? errorMessage,
    bool clearError = false,
    CapturePurpose? capturePurpose,
    bool clearCapturePurpose = false,
    double? captureVolumeLiters,
    CameraOperationState? cameraState,
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
    litersPerPulse: litersPerPulse ?? this.litersPerPulse,
    evidenceStepLiters: evidenceStepLiters ?? this.evidenceStepLiters,
    readingUncertaintyLiters:
        readingUncertaintyLiters ?? this.readingUncertaintyLiters,
    hardwareState: hardwareState ?? this.hardwareState,
    evidence: evidence ?? this.evidence,
    samples: samples ?? this.samples,
    cases: cases ?? this.cases,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    capturePurpose: clearCapturePurpose
        ? null
        : capturePurpose ?? this.capturePurpose,
    captureVolumeLiters: captureVolumeLiters ?? this.captureVolumeLiters,
    cameraState: cameraState ?? this.cameraState,
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
  LedPulseSource? _ledSource;
  StreamSubscription<PulseEvent>? _pulseSubscription;
  StreamSubscription<PulseSourceState>? _pulseStateSubscription;
  StreamSubscription<int>? _counterSubscription;
  StreamSubscription<PulseEvent>? _ledSubscription;
  final CameraResourceCoordinator _cameraCoordinator =
      CameraResourceCoordinator();
  Timer? _ledReconciliationTimer;
  Timer? _ledMetricsTimer;
  int? _latestEsp32Counter;
  int _pendingOpticalPulses = 0;
  Future<void> _pulseQueue = Future.value();

  Future<void> initialize() async {
    await _guard(() async {
      final user = await dependencies.auth.restoreSession();
      if (user == null) {
        state = state.copyWith(page: AppPage.login, clearUser: true);
        return;
      }
      final running = (await dependencies.samples.listIncomplete())
          .where((sample) => sample.status == SampleStatus.running)
          .toList();
      if (running.isNotEmpty) {
        await _loadSampleContext(running.first);
        state = state.copyWith(user: user, page: AppPage.recovery);
      } else {
        state = state.copyWith(user: user, page: AppPage.home);
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
      state = const AppViewState(page: AppPage.login);
    });
  }

  void showHome() =>
      state = state.copyWith(page: AppPage.home, clearError: true);
  void startIdentification() =>
      state = state.copyWith(page: AppPage.identification, clearError: true);
  void showSettings() => state = state.copyWith(page: AppPage.settings);
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
      for (final flow in flows) {
        samples.addAll(await dependencies.samples.listByFlow(flow.id));
      }
      state = state.copyWith(
        activeCase: verificationCase,
        meter: meter,
        samples: samples,
        page: AppPage.caseSummary,
      );
    });
  }

  void selectFlow(FlowPoint value) =>
      state = state.copyWith(selectedFlow: value);
  void selectMethod(MeasurementMethod value) =>
      state = state.copyWith(selectedMethod: value);
  void setHardwareState(HardwareState value) =>
      state = state.copyWith(hardwareState: value);

  Future<void> scanBleDevices() async {
    final discovery = dependencies.bleDiscovery;
    if (discovery == null) return;
    await _guard(() async {
      state = state.copyWith(hardwareState: HardwareState.preparing);
      final devices = await discovery.scan();
      state = state.copyWith(
        bleDevices: devices,
        hardwareState: devices.isEmpty
            ? HardwareState.notConnected
            : HardwareState.ready,
      );
    });
  }

  void selectBleDevice(BleDeviceCandidate device) {
    state = state.copyWith(
      selectedBleDevice: device,
      hardwareState: HardwareState.ready,
    );
  }

  Future<void> identifyMeter({
    required String meterId,
    required double lpsApprox,
  }) async {
    await _guard(() async {
      final user = state.user;
      if (user == null) throw StateError('No active local session.');
      final id = meterId.trim();
      if (id.isEmpty || !lpsApprox.isFinite || lpsApprox <= 0) {
        throw ArgumentError('Completa medidor y LPS con valores válidos.');
      }
      final now = DateTime.now().toUtc();
      final existingMeter = await dependencies.meters.getById(id);
      final meter = Meter(
        id: id,
        externalStatus:
            existingMeter?.externalStatus ?? ExternalMeterStatus.unknownOffline,
        externalSnapshotJson: existingMeter?.externalSnapshotJson,
        externalCheckedAt: existingMeter?.externalCheckedAt,
        createdAt: existingMeter?.createdAt ?? now,
        updatedAt: now,
      );
      await dependencies.meters.save(meter);
      var verificationCase = await dependencies.cases.findOpenByMeter(id);
      if (verificationCase == null || verificationCase.userId != user.id) {
        verificationCase = VerificationCase(
          id: _uuid.v4(),
          meterId: id,
          userId: user.id,
          status: VerificationCaseStatus.open,
          createdAt: now,
          reportVersion: 1,
        );
        await dependencies.cases.create(verificationCase);
      }
      final existingFlows = await dependencies.flows.listByCase(
        verificationCase.id,
      );
      var flow = existingFlows
          .where((item) => item.code == state.selectedFlow)
          .firstOrNull;
      if (flow == null) {
        flow = FlowPointRecord(
          id: _uuid.v4(),
          caseId: verificationCase.id,
          code: state.selectedFlow,
          lpsApprox: lpsApprox,
          mpePct: _mpe.mpePctFor(state.selectedFlow),
          status: FlowRecordStatus.open,
          createdAt: now,
        );
        await dependencies.flows.create(flow);
      }
      state = state.copyWith(
        meter: meter,
        activeCase: verificationCase,
        flow: flow,
        lpsApprox: lpsApprox,
        page: AppPage.method,
      );
    });
  }

  void continueToSetup() => state = state.copyWith(page: AppPage.setup);

  void updateSetup({
    required double litersPerPulse,
    required double evidenceStepLiters,
    required double uncertaintyLiters,
  }) {
    if (litersPerPulse <= 0 ||
        evidenceStepLiters <= 0 ||
        uncertaintyLiters < 0) {
      throw ArgumentError('La configuración contiene valores inválidos.');
    }
    state = state.copyWith(
      litersPerPulse: litersPerPulse,
      evidenceStepLiters: evidenceStepLiters,
      readingUncertaintyLiters: uncertaintyLiters,
    );
  }

  Future<void> startSample() async {
    await _guard(() async {
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
          litersPerOdometerUnit: 1000,
          needleLitersPerRevolution: 100,
        ),
        createdAt: now,
        updatedAt: now,
        pulseCount: 0,
      );
      await dependencies.samples.createDraft(draft);
      final running = await dependencies.samples.start(draft.id, at: now);
      if (dependencies.camera != null) {
        await _refreshSample(running.id);
        state = state.copyWith(
          page: AppPage.camera,
          capturePurpose: CapturePurpose.start,
          captureVolumeLiters: 0,
          cameraState: CameraOperationState.idle,
          clearReadingProposal: true,
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
      state = state.copyWith(page: AppPage.run);
    });
  }

  Future<void> addManualPulse() async {
    final sample = state.sample;
    if (sample == null ||
        sample.status != SampleStatus.running ||
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

  void showReadings() => state = state.copyWith(page: AppPage.readings);

  Future<void> requestIntermediateEvidence(double volumeLiters) async {
    await _pauseLedForEvidence();
    state = state.copyWith(
      page: AppPage.camera,
      capturePurpose: CapturePurpose.intermediate,
      captureVolumeLiters: volumeLiters,
      cameraState: CameraOperationState.idle,
      clearReadingProposal: true,
    );
  }

  Future<void> requestFinalEvidence() async {
    final sample = state.sample;
    if (sample == null) return;
    final reference =
        sample.configuration.measurementMethod == MeasurementMethod.visual
        ? sample.referenceLitersProgress
        : sample.pulseCount * sample.configuration.litersPerPulse;
    if (reference == null || reference <= 0) {
      state = state.copyWith(
        errorMessage: 'El volumen de referencia debe ser mayor que cero.',
      );
      return;
    }
    await _pauseLedForEvidence();
    state = state.copyWith(
      page: AppPage.camera,
      capturePurpose: CapturePurpose.finalEvidence,
      captureVolumeLiters: reference,
      cameraState: CameraOperationState.idle,
      clearReadingProposal: true,
    );
  }

  Future<void> processCapturedPhoto(String sourcePath) async {
    await _guard(() async {
      var sample = state.sample;
      final verificationCase = state.activeCase;
      final purpose = state.capturePurpose;
      if (sample == null || verificationCase == null || purpose == null) {
        throw StateError('No hay una captura activa.');
      }
      state = state.copyWith(cameraState: CameraOperationState.processing);
      final type = switch (purpose) {
        CapturePurpose.start => EvidenceType.start,
        CapturePurpose.intermediate => EvidenceType.intermediate,
        CapturePurpose.finalEvidence => EvidenceType.finalEvidence,
      };
      if (sample.configuration.measurementMethod == MeasurementMethod.led) {
        if (purpose == CapturePurpose.finalEvidence) {
          await _stopBleCounterSource();
        }
        await _flushLedReconciliation(sample.id);
        sample = await dependencies.samples.getById(sample.id) ?? sample;
      }
      final volume = sample.configuration.measurementMethod.isPulseEventSource
          ? sample.pulseCount * sample.configuration.litersPerPulse
          : state.captureVolumeLiters ?? 0;
      final evidence = await dependencies.evidenceCapture.captureExisting(
        sourcePath: sourcePath,
        caseId: verificationCase.id,
        sample: sample,
        type: type,
        volumeRefLiters: volume,
        pulseCount: sample.configuration.measurementMethod.isPulseEventSource
            ? (volume / sample.configuration.litersPerPulse).round()
            : null,
      );
      VisualReadingProposal? proposal;
      try {
        proposal = await dependencies.visualPipeline?.analyze(
          evidenceId: evidence.id,
          evidencePath: evidence.localPath,
          configuration: sample.meterFaceConfiguration == null
              ? null
              : DialVisionConfiguration.fromDomain(
                  sample.meterFaceConfiguration!,
                ),
        );
      } catch (_) {
        // A valid decodable photograph remains evidence when automatic vision fails.
        if (purpose == CapturePurpose.intermediate) {
          proposal = null;
        } else {
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
      if (purpose == CapturePurpose.start) {
        await _startBleForCurrentSample();
      }
      state = state.copyWith(
        cameraState: proposal == null
            ? CameraOperationState.confirmed
            : CameraOperationState.proposalReady,
        readingProposal: proposal,
      );
      if (purpose == CapturePurpose.intermediate) {
        state = state.copyWith(page: AppPage.run, clearCapturePurpose: true);
        await _resumeLedAfterEvidence(sample);
      }
    });
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
      await dependencies.samples.updateProgress(
        id: sample.id,
        pulseCount: sample.pulseCount,
        referenceLiters: sample.referenceLitersProgress,
        initialReading: purpose == CapturePurpose.start ? confirmed : null,
        finalReading: purpose == CapturePurpose.finalEvidence
            ? confirmed
            : null,
      );
      await _refreshSample(sample.id);
      state = state.copyWith(
        page: purpose == CapturePurpose.start ? AppPage.run : AppPage.readings,
        cameraState: CameraOperationState.confirmed,
        clearCapturePurpose: true,
      );
    });
  }

  Future<void> reanalyzeRegions(DialVisionConfiguration configuration) async {
    await _guard(() async {
      final proposal = state.readingProposal;
      if (proposal == null) {
        throw StateError('No existe una foto para reanalizar.');
      }
      state = state.copyWith(cameraState: CameraOperationState.processing);
      final analyzed = await dependencies.visualPipeline!.analyze(
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

  Future<void> recapturePhoto() async {
    final proposal = state.readingProposal;
    if (proposal != null) {
      await _guard(() async {
        await dependencies.evidence.deleteFromOpenSample(proposal.evidenceId);
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
    required double initialOdometer,
    required double initialNeedle,
    required double finalOdometer,
    required double finalNeedle,
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
      final reference = config.measurementMethod == MeasurementMethod.visual
          ? visualReferenceLiters ?? sample.referenceLitersProgress
          : sample.pulseCount * config.litersPerPulse;
      if (reference == null || reference <= 0) {
        throw ArgumentError(
          'El volumen de referencia debe ser mayor que cero.',
        );
      }
      sample = await dependencies.samples.updateProgress(
        id: sample.id,
        pulseCount: sample.pulseCount,
        referenceLiters: reference,
        initialReading: _confirmedFromReview(
          existing: sample.initialReading,
          odometer: initialOdometer,
          needle: initialNeedle,
          config: config,
        ),
        finalReading: _confirmedFromReview(
          existing: sample.finalReading,
          odometer: finalOdometer,
          needle: finalNeedle,
          config: config,
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
    state = state.copyWith(
      page: AppPage.setup,
      clearSample: true,
      evidence: [],
    );
  }

  Future<void> anotherSample() => repeatSample();

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
      for (final flow in flows) {
        samples.addAll(await dependencies.samples.listByFlow(flow.id));
      }
      state = state.copyWith(page: AppPage.caseSummary, samples: samples);
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
        state = state.copyWith(
          page: AppPage.camera,
          capturePurpose: CapturePurpose.start,
          captureVolumeLiters: 0,
          cameraState: CameraOperationState.idle,
        );
      } else if (hasStart &&
          sample.initialReading == null &&
          dependencies.camera != null) {
        final start = state.evidence.lastWhere(
          (item) => item.type == EvidenceType.start,
        );
        final proposal = await dependencies.visualPipeline?.analyze(
          evidenceId: start.id,
          evidencePath: start.localPath,
          configuration: sample.meterFaceConfiguration == null
              ? null
              : DialVisionConfiguration.fromDomain(
                  sample.meterFaceConfiguration!,
                ),
        );
        state = state.copyWith(
          page: AppPage.camera,
          capturePurpose: CapturePurpose.start,
          captureVolumeLiters: 0,
          cameraState: proposal == null
              ? CameraOperationState.error
              : CameraOperationState.proposalReady,
          readingProposal: proposal,
        );
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
    final samples = await dependencies.samples.listByFlow(flow.id);
    state = state.copyWith(
      activeCase: verificationCase,
      meter: meter,
      flow: flow,
      sample: sample,
      selectedFlow: flow.code,
      selectedMethod: sample.configuration.measurementMethod,
      lpsApprox: flow.lpsApprox,
      evidence: evidence,
      samples: samples,
    );
  }

  Future<void> _refreshSample(String id) async {
    final sample = await dependencies.samples.getById(id);
    if (sample == null) throw StateError('No se encontró la muestra.');
    await _loadSampleContext(sample);
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
    await _bleSource?.dispose();
    await _pulseSubscription?.cancel();
    await _pulseStateSubscription?.cancel();
    await _counterSubscription?.cancel();
    final source = BlePulseSource(
      BlePulseConfiguration(
        deviceId: deviceId,
        deviceName: persisted?.bleDeviceName ?? selected?.name,
        serviceUuid: Ddr001BleContract.serviceUuid,
        characteristicUuid: Ddr001BleContract.counterCharacteristicUuid,
        lastObservedCounter: persisted?.lastObservedEsp32Counter,
      ),
    );
    _bleSource = source;
    if (sample.configuration.measurementMethod == MeasurementMethod.ble) {
      _pulseSubscription = source.events.listen((event) async {
        await dependencies.pulseProgress.acceptPulse(sample.id, event);
        await _refreshSample(sample.id);
      });
    }
    _pulseStateSubscription = source.states.listen((pulseState) {
      state = state.copyWith(
        hardwareState: switch (pulseState.status) {
          PulseSourceStatus.ready => HardwareState.ready,
          PulseSourceStatus.connecting ||
          PulseSourceStatus.reconnecting => HardwareState.preparing,
          PulseSourceStatus.error => HardwareState.error,
          _ => HardwareState.disconnected,
        },
        errorMessage: pulseState.message,
      );
      if (pulseState.compromised) {
        unawaited(_markAcquisitionCompromised(sample.id, pulseState.message));
      }
    });
    _counterSubscription = source.counters.listen((counter) async {
      final current = await dependencies.samples.getById(sample.id);
      if (current == null || current.status != SampleStatus.running) return;
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
    await source.start();
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
    await _bleSource?.stop();
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

  Future<void> _guard(Future<void> Function() operation) async {
    state = state.copyWith(busy: true, clearError: true);
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
      state = state.copyWith(busy: false);
    }
  }

  String _friendly(Object? message) =>
      message?.toString() ?? 'La operación no está permitida.';

  @override
  void dispose() {
    unawaited(_stopPulseSources());
    super.dispose();
  }

  ConfirmedReading _confirmedFromReview({
    required ConfirmedReading? existing,
    required double odometer,
    required double needle,
    required SampleConfiguration config,
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
      evidenceId: existing?.evidenceId,
    );
  }
}
