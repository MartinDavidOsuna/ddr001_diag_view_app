import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../app/app_dependencies.dart';
import '../core/metrology/metrology.dart';
import '../domain/expected_evidence_plan.dart';
import '../domain/models.dart';
import '../infrastructure/camera/camera_models.dart';
import '../infrastructure/vision/vision_models.dart';

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
      final count = sample.pulseCount + 1;
      await dependencies.samples.updateProgress(
        id: sample.id,
        pulseCount: count,
        referenceLiters: count * sample.configuration.litersPerPulse,
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

  void requestIntermediateEvidence(double volumeLiters) {
    state = state.copyWith(
      page: AppPage.camera,
      capturePurpose: CapturePurpose.intermediate,
      captureVolumeLiters: volumeLiters,
      cameraState: CameraOperationState.idle,
      clearReadingProposal: true,
    );
  }

  void requestFinalEvidence() {
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
      final sample = state.sample;
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
      final volume = state.captureVolumeLiters ?? 0;
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
      state = state.copyWith(
        cameraState: proposal == null
            ? CameraOperationState.confirmed
            : CameraOperationState.proposalReady,
        readingProposal: proposal,
      );
      if (purpose == CapturePurpose.intermediate) {
        state = state.copyWith(page: AppPage.run, clearCapturePurpose: true);
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
