import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/metrology/metrology.dart';
import '../../domain/expected_evidence_plan.dart';
import '../../domain/control_start_gate.dart';
import '../../domain/models.dart';
import '../../domain/pulse/pulse_flow_estimate.dart';
import '../../domain/remote_test_control.dart';
import '../../infrastructure/camera/camera_models.dart';
import '../../infrastructure/pulse/led_pulse_detector.dart';
import '../app_controller.dart';
import '../common/app_scaffold.dart';

final class TestRunScreen extends ConsumerStatefulWidget {
  const TestRunScreen({super.key});
  @override
  ConsumerState<TestRunScreen> createState() => _TestRunScreenState();
}

final class _TestRunScreenState extends ConsumerState<TestRunScreen> {
  static const _remoteChannel = MethodChannel('ddr001/remote_test_control');
  final _visualReference = TextEditingController(text: '125');
  final _remoteFocusNode = FocusNode(debugLabel: 'bluetooth-shutter-control');
  DateTime? _lastRemoteActionAt;
  bool _remoteControlArmed = false;
  bool _remoteConfirmationOpen = false;
  final _scrollController = ScrollController();
  final _evidencePlanKey = GlobalKey();
  int _lastExpectedEvidenceCount = 0;
  Timer? _remoteKeepAliveTimer;
  bool _checkingRemote = false;

  @override
  void initState() {
    super.initState();
    _remoteChannel.setMethodCallHandler((call) async {
      if (call.method == 'shutterPressed' && mounted) {
        _triggerRemoteAction();
      } else if (call.method == 'remoteConnectionChanged' && mounted) {
        final connected = call.arguments == true;
        if (connected) {
          ref
              .read(appControllerProvider.notifier)
              .setRemoteControlConnected(true);
        } else {
          unawaited(_refreshRemoteConnection());
        }
      }
    });
    unawaited(_refreshRemoteConnection());
    _remoteKeepAliveTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(_refreshRemoteConnection()),
    );
  }

  Future<void> _refreshRemoteConnection() async {
    if (_checkingRemote) return;
    _checkingRemote = true;
    var connected = false;
    try {
      for (var attempt = 1; attempt <= 3; attempt++) {
        connected =
            await _remoteChannel.invokeMethod<bool>('getRemoteConnected') ??
            false;
        if (connected) break;
        if (attempt < 3) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
      if (mounted) {
        ref
            .read(appControllerProvider.notifier)
            .setRemoteControlConnected(connected);
        if (!connected && _remoteControlArmed) {
          setState(() => _remoteControlArmed = false);
        }
      }
    } on PlatformException {
      // Older/native-less test hosts simply report no remote control.
    } finally {
      _checkingRemote = false;
    }
  }

  @override
  void dispose() {
    _visualReference.dispose();
    _remoteFocusNode.dispose();
    _scrollController.dispose();
    _remoteKeepAliveTimer?.cancel();
    _remoteChannel.setMethodCallHandler(null);
    super.dispose();
  }

  void _handleRemoteKey(KeyEvent event) {
    if (event is! KeyDownEvent ||
        (event.logicalKey != LogicalKeyboardKey.audioVolumeUp &&
            event.logicalKey != LogicalKeyboardKey.audioVolumeDown)) {
      return;
    }
    _triggerRemoteAction();
  }

  void _triggerRemoteAction() {
    if (!_remoteControlArmed) {
      if (_remoteConfirmationOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        _armRemoteControl();
      } else {
        _showRemoteConfirmation();
      }
      return;
    }
    final now = DateTime.now().toUtc();
    if (_lastRemoteActionAt != null &&
        now.difference(_lastRemoteActionAt!) <
            const Duration(milliseconds: 750)) {
      return;
    }
    final state = ref.read(appControllerProvider);
    if (state.finalizingMeasurement) return;
    final sample = state.sample;
    if (sample == null) return;
    final controller = ref.read(appControllerProvider.notifier);
    final gate = ControlStartGate.evaluate(
      pulses: state.preStartControlPulseCount,
      litersPerPulse: sample.configuration.litersPerPulse,
      firstPulseAt: state.preStartControlFirstPulseAt,
      now: now,
      minimumLps: sample.configuration.controlStartMinimumLps,
      maximumLps: sample.configuration.controlStartMaximumLps,
    );
    final reference =
        sample.configuration.measurementMethod == MeasurementMethod.visual
        ? sample.referenceLitersProgress ?? 0
        : sample.pulseCount * sample.configuration.litersPerPulse;
    final action = remoteTestAction(
      measurementStarted: state.measurementStarted,
      controlFlowInRange: gate.inRange,
      referenceLiters: reference,
    );
    if (action == RemoteTestAction.none) return;
    _lastRemoteActionAt = now;
    if (action == RemoteTestAction.begin) {
      controller.beginMeasurement();
      return;
    }
    if (dependenciesHaveCamera(ref)) {
      controller.requestFinalEvidence();
    } else {
      controller.showReadings();
    }
  }

  void _armRemoteControl() {
    if (!mounted) return;
    setState(() {
      _remoteControlArmed = true;
      _remoteConfirmationOpen = false;
    });
  }

  Future<void> _showRemoteConfirmation() async {
    if (!mounted) return;
    setState(() => _remoteConfirmationOpen = true);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Control conectado'),
        content: const Text(
          'Presione nuevamente el botón del control o toque ACEPTAR para habilitarlo durante esta prueba.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _armRemoteControl();
            },
            child: const Text('ACEPTAR'),
          ),
        ],
      ),
    );
    if (mounted && !_remoteControlArmed) {
      setState(() => _remoteConfirmationOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final sample = state.sample!;
    final config = sample.configuration;
    final reference = config.measurementMethod == MeasurementMethod.visual
        ? sample.referenceLitersProgress ?? 0
        : sample.pulseCount * config.litersPerPulse;
    _keepLatestEvidenceVisible(sample, reference);
    return KeyboardListener(
      focusNode: _remoteFocusNode,
      autofocus: true,
      onKeyEvent: _handleRemoteKey,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) controller.goBack();
        },
        child: AppScaffold(
          title: 'Prueba en curso',
          showBack: false,
          actions: [
            _RunHeaderStatus(
              esp32Connected: state.hardwareState == HardwareState.ready,
              remoteConnected: _remoteControlArmed || _remoteConfirmationOpen,
              controlPulses: state.preStartControlPulseCount,
              controlFirstPulseAt: state.preStartControlFirstPulseAt,
              litersPerPulse: config.litersPerPulse,
            ),
          ],
          pinnedHeader: _PinnedRunStatus(
            meterId: state.meter?.id ?? '—',
            sample: sample,
            referenceLiters: reference,
            measurementStarted: state.measurementStarted,
            finalizingMeasurement: state.finalizingMeasurement,
            preStartControlPulses: state.preStartControlPulseCount,
            preStartControlFirstPulseAt: state.preStartControlFirstPulseAt,
            meterUnderTestPulses: state.meterUnderTestPulseCount,
            meterUnderTestFirstPulseAt: state.meterUnderTestFirstPulseAt,
            hydrantMonitorPulses: state.hydrantMonitorPulseCount,
            hydrantMonitorFirstPulseAt: state.hydrantMonitorFirstPulseAt,
            controlPulseTimes: state.controlPulseTimes,
            hydrantPulseTimes: state.hydrantPulseTimes,
            litersPerPulse: config.litersPerPulse,
            hydrantLitersPerPulse: config.hydrantLitersPerPulse,
            canFinish: reference > 0,
            onFinish: dependenciesHaveCamera(ref)
                ? controller.requestFinalEvidence
                : controller.showReadings,
            onBegin: controller.beginMeasurement,
          ),
          scrollController: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (config.measurementMethod == MeasurementMethod.manual)
                    FilledButton.icon(
                      key: const Key('manual-pulse'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        minimumSize: const Size.fromHeight(76),
                      ),
                      onPressed: controller.addManualPulse,
                      icon: const Icon(Icons.circle),
                      label: Text(
                        'PULSO (+${config.litersPerPulse.toStringAsFixed(1)} L)',
                        style: const TextStyle(fontSize: 19),
                      ),
                    )
                  else if (config.measurementMethod == MeasurementMethod.visual)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const StatusBanner(
                          text:
                              'LECTURA VISUAL · Ingresa el volumen patrón externo alcanzado; la lectura del medidor proviene de fotografías reales.',
                          color: AppColors.heading,
                          icon: Icons.visibility_outlined,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          key: const Key('visual-reference'),
                          controller: _visualReference,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Volumen patrón externo / progreso (L)',
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () {
                            final value = double.tryParse(
                              _visualReference.text,
                            );
                            if (value != null && value > 0) {
                              controller.setDevelopmentVisualReference(value);
                            }
                          },
                          child: const Text('CONFIRMAR PROGRESO VISUAL'),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (sample.acquisitionIntegrity.isCompromised)
                          const StatusBanner(
                            text:
                                'Adquisición comprometida · conteo no verificable',
                            color: AppColors.danger,
                            icon: Icons.warning_amber,
                          ),
                        if (config.measurementMethod == MeasurementMethod.led &&
                            sample.pulseAcquisitionConfiguration?.ledBaseline ==
                                null)
                          _LedPreparationPanel(initialRegion: state.ledRegion),
                        if (config.measurementMethod == MeasurementMethod.led &&
                            sample.pulseAcquisitionConfiguration?.ledBaseline !=
                                null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'LED live: ${state.ledLivePulses} · reconciliados: ${state.ledReconciledPulses} · falsos: ${state.ledFalsePositives}',
                          ),
                          Text(
                            'Dark ${state.ledDarkBrightness?.toStringAsFixed(1) ?? '—'} · Bright ${state.ledBrightBrightness?.toStringAsFixed(1) ?? '—'} · FPS ${state.ledFps?.toStringAsFixed(1) ?? '—'} · descartados ${state.ledFramesDropped}',
                          ),
                        ],
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SectionCard(
                key: _evidencePlanKey,
                title: 'CAPTURA DE EVIDENCIAS',
                child: EvidencePlanView(
                  sample: sample,
                  evidence: state.evidence,
                  currentReference: reference,
                ),
              ),
              const SizedBox(height: 14),
              _Registry(points: state.points, configuration: config),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: controller.showHome,
                child: const Text('SALIR SIN DESCARTAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _keepLatestEvidenceVisible(Sample sample, double reference) {
    if (reference <= 0) return;
    final count = ExpectedEvidencePlan.derive(
      evidenceStepLiters: sample.configuration.evidenceStepLiters,
      finalVolumeLiters: reference,
    ).requirements.length;
    if (count < 4 || count == _lastExpectedEvidenceCount) return;
    _lastExpectedEvidenceCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _evidencePlanKey.currentContext;
      if (!mounted || context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }
}

final class _RunHeaderStatus extends StatefulWidget {
  const _RunHeaderStatus({
    required this.esp32Connected,
    required this.remoteConnected,
    required this.controlPulses,
    required this.controlFirstPulseAt,
    required this.litersPerPulse,
  });

  final bool esp32Connected;
  final bool remoteConnected;
  final int controlPulses;
  final DateTime? controlFirstPulseAt;
  final double litersPerPulse;

  @override
  State<_RunHeaderStatus> createState() => _RunHeaderStatusState();
}

final class _RunHeaderStatusState extends State<_RunHeaderStatus> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final confidence = PulseFlowEstimate.calculate(
      pulses: widget.controlPulses,
      litersPerPulse: widget.litersPerPulse,
      firstPulseAt: widget.controlFirstPulseAt,
      now: DateTime.now().toUtc(),
    ).confidence;
    final confidenceColor = confidence == 0
        ? Colors.white
        : confidence >= 97
        ? AppColors.success
        : AppColors.danger;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bluetooth,
                size: 19,
                color: widget.esp32Connected
                    ? AppColors.success
                    : AppColors.danger,
              ),
              Text(
                'ESP32',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: widget.esp32Connected
                      ? AppColors.success
                      : AppColors.danger,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.settings_remote,
                size: 20,
                color: widget.remoteConnected ? AppColors.success : Colors.grey,
              ),
            ],
          ),
          Text(
            'Confianza ${confidence.toStringAsFixed(2)}%',
            maxLines: 1,
            style: TextStyle(
              color: confidenceColor,
              fontSize: 11.55,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

final class _PinnedRunStatus extends StatefulWidget {
  const _PinnedRunStatus({
    required this.meterId,
    required this.sample,
    required this.referenceLiters,
    required this.measurementStarted,
    required this.finalizingMeasurement,
    required this.preStartControlPulses,
    required this.preStartControlFirstPulseAt,
    required this.meterUnderTestPulses,
    required this.meterUnderTestFirstPulseAt,
    required this.hydrantMonitorPulses,
    required this.hydrantMonitorFirstPulseAt,
    required this.controlPulseTimes,
    required this.hydrantPulseTimes,
    required this.litersPerPulse,
    required this.hydrantLitersPerPulse,
    required this.canFinish,
    required this.onFinish,
    required this.onBegin,
  });

  final String meterId;
  final Sample sample;
  final double referenceLiters;
  final bool measurementStarted;
  final bool finalizingMeasurement;
  final int preStartControlPulses;
  final DateTime? preStartControlFirstPulseAt;
  final int meterUnderTestPulses;
  final DateTime? meterUnderTestFirstPulseAt;
  final int hydrantMonitorPulses;
  final DateTime? hydrantMonitorFirstPulseAt;
  final List<DateTime> controlPulseTimes;
  final List<DateTime> hydrantPulseTimes;
  final double litersPerPulse;
  final double hydrantLitersPerPulse;
  final bool canFinish;
  final VoidCallback onFinish;
  final VoidCallback onBegin;

  @override
  State<_PinnedRunStatus> createState() => _PinnedRunStatusState();
}

final class _PinnedRunStatusState extends State<_PinnedRunStatus> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final officialPulses =
        widget.measurementStarted || widget.finalizingMeasurement
        ? widget.sample.pulseCount
        : 0;
    final controlReference =
        widget.measurementStarted || widget.finalizingMeasurement
        ? widget.referenceLiters
        : 0.0;
    final firstPulse = widget.measurementStarted
        ? widget.sample.startedAt
        : widget.preStartControlFirstPulseAt;
    final now = DateTime.now().toUtc();
    final gate = ControlStartGate.evaluate(
      pulses: widget.measurementStarted
          ? widget.sample.pulseCount
          : widget.preStartControlPulses,
      litersPerPulse: widget.litersPerPulse,
      firstPulseAt: firstPulse,
      now: now,
      minimumLps: widget.sample.configuration.controlStartMinimumLps,
      maximumLps: widget.sample.configuration.controlStartMaximumLps,
    );
    final calculatedFlow = widget.measurementStarted
        ? PulseFlowEstimate.calculate(
            pulses: widget.sample.pulseCount,
            litersPerPulse: widget.litersPerPulse,
            firstPulseAt: firstPulse,
            now: now,
            recentPulseTimes: widget.controlPulseTimes,
          ).flowLps
        : gate.flowLps;
    final flowInRange = gate.inRange;
    final hydrantEstimate = PulseFlowEstimate.calculate(
      pulses: widget.hydrantMonitorPulses,
      litersPerPulse: widget.hydrantLitersPerPulse,
      firstPulseAt: widget.hydrantMonitorFirstPulseAt,
      now: now,
      recentPulseTimes: widget.hydrantPulseTimes,
    );
    return Material(
      elevation: 8,
      color: AppColors.panelDark,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        key: const Key('pinned-run-status'),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.heading),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '4 · PRUEBA',
              style: TextStyle(
                color: AppColors.heading,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Medidor ${widget.meterId}',
              key: const Key('running-meter-id'),
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.sample.configuration.flowPoint.name.toUpperCase()} · Caudal calculado · K ${widget.litersPerPulse} L/pulso',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Text(
              firstPulse == null
                  ? 'Inicio: esperando primer pulso'
                  : 'Inicio (primer pulso): ${_timestamp(firstPulse)}',
              style: const TextStyle(
                color: AppColors.heading,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: _PinnedValue(
                    label: 'Pulsos',
                    value: '$officialPulses',
                  ),
                ),
                Expanded(
                  child: _PinnedValue(
                    label: 'Caudal calc.',
                    value: '${calculatedFlow.toStringAsFixed(2)} L/s',
                    valueColor: flowInRange ? AppColors.success : null,
                  ),
                ),
                Expanded(
                  child: _PinnedValue(
                    label: 'V patrón',
                    value: '${controlReference.toStringAsFixed(2)} L',
                  ),
                ),
              ],
            ),
            const Divider(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PinnedValue(
                    label: 'Medidor del hidrante',
                    value: '${widget.meterUnderTestPulses} pulsos',
                  ),
                ),
                Expanded(
                  child: _PinnedValue(
                    label: 'Caudal hidrante',
                    value: widget.hydrantMonitorPulses == 0
                        ? 'Sin pulsos'
                        : '${hydrantEstimate.flowLps.toStringAsFixed(2)} L/s',
                  ),
                ),
                Expanded(
                  child: _PinnedValue(
                    label: 'V hidrante',
                    value:
                        '${(widget.meterUnderTestPulses * widget.hydrantLitersPerPulse).toStringAsFixed(2)} L',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.finalizingMeasurement)
              const FilledButton(
                key: Key('finalizing-run'),
                onPressed: null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text('FINALIZANDO…'),
                  ],
                ),
              )
            else if (!widget.measurementStarted)
              FilledButton(
                key: const Key('begin-measurement'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                onPressed: flowInRange ? widget.onBegin : null,
                child: const Text('INICIAR PRUEBA'),
              )
            else
              FilledButton(
                key: const Key('finish-run'),
                onPressed: widget.canFinish ? widget.onFinish : null,
                child: const Text('FINALIZAR Y CONFIRMAR LECTURAS'),
              ),
          ],
        ),
      ),
    );
  }
}

final class _PinnedValue extends StatelessWidget {
  const _PinnedValue({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
      Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: valueColor,
        ),
      ),
    ],
  );
}

final class _LedPreparationPanel extends ConsumerStatefulWidget {
  const _LedPreparationPanel({required this.initialRegion});
  final LedRegion initialRegion;

  @override
  ConsumerState<_LedPreparationPanel> createState() =>
      _LedPreparationPanelState();
}

final class _LedPreparationPanelState
    extends ConsumerState<_LedPreparationPanel> {
  late LedRegion _region = widget.initialRegion;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final camera = ref.read(appDependenciesProvider).camera;
    if (camera == null) return;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final permission = await camera.requestPermission();
      if (permission != CameraPermissionState.granted) {
        throw StateError('Permiso de cámara requerido para LED.');
      }
      await camera.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final camera = ref.read(appDependenciesProvider).camera;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Apunte al LED integrado y coloque el recuadro sobre él.'),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                fit: StackFit.expand,
                children: [
                  if (_ready && camera != null)
                    camera.buildPreview()
                  else
                    const ColoredBox(color: Colors.black),
                  Positioned(
                    left: _region.left * box.maxWidth,
                    top: _region.top * box.maxHeight,
                    width: _region.width * box.maxWidth,
                    height: _region.height * box.maxHeight,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _region = LedRegion(
                            left:
                                (_region.left + details.delta.dx / box.maxWidth)
                                    .clamp(0, 1 - _region.width),
                            top:
                                (_region.top + details.delta.dy / box.maxHeight)
                                    .clamp(0, 1 - _region.height),
                            width: _region.width,
                            height: _region.height,
                          );
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.amber, width: 3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Text('Tamaño ROI LED'),
          Slider(
            value: _region.width,
            min: .08,
            max: .45,
            onChanged: (size) => setState(() {
              _region = LedRegion(
                left: _region.left.clamp(0, 1 - size),
                top: _region.top.clamp(0, 1 - size),
                width: size,
                height: size,
              );
            }),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          FilledButton(
            key: const Key('confirm-led-region'),
            onPressed: !_ready || appState.busy
                ? null
                : () => ref
                      .read(appControllerProvider.notifier)
                      .prepareLedDetector(_region),
            child: const Text('CONFIRMAR ROI Y PREPARAR LED'),
          ),
        ],
      ),
    );
  }
}

final class EvidencePlanView extends StatelessWidget {
  const EvidencePlanView({
    required this.sample,
    required this.evidence,
    required this.currentReference,
    super.key,
  });
  final Sample sample;
  final List<Evidence> evidence;
  final double currentReference;

  @override
  Widget build(BuildContext context) {
    if (currentReference <= 0) {
      return const Text(
        'INICIO se captura al momento de iniciar la prueba, las intermedias y FINAL se derivarán al conocer el volumen final.',
        style: TextStyle(color: AppColors.muted),
      );
    }
    final plan = ExpectedEvidencePlan.derive(
      evidenceStepLiters: sample.configuration.evidenceStepLiters,
      finalVolumeLiters: currentReference,
    );
    return Column(
      children: plan.requirements.map((requirement) {
        final captured = evidence.any(
          (item) =>
              item.type == requirement.type &&
              item.volumeRefLiters != null &&
              plan.volumeMatches(
                item.volumeRefLiters!,
                requirement.volumeRefLiters,
              ),
        );
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            captured ? Icons.check_circle : Icons.pending_outlined,
            color: captured ? AppColors.success : AppColors.warning,
          ),
          title: Text(
            '${evidenceTypeLabel(requirement.type)} · ${requirement.volumeRefLiters.toStringAsFixed(0)} L',
          ),
          trailing: Text(
            captured
                ? 'Capturada'
                : requirement.type == EvidenceType.intermediate
                ? 'Captura automática'
                : 'Pendiente',
            style: TextStyle(
              color: captured ? AppColors.success : AppColors.warning,
            ),
          ),
        );
      }).toList(),
    );
  }
}

bool dependenciesHaveCamera(WidgetRef ref) =>
    ref.read(appDependenciesProvider).camera != null;

final class _Registry extends StatelessWidget {
  const _Registry({required this.points, required this.configuration});
  final List<TestPoint> points;
  final SampleConfiguration configuration;
  @override
  Widget build(BuildContext context) {
    final flowStatistics = PointFlowStatistics.fromPoints(points);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '5 · REGISTRO',
                style: TextStyle(
                  color: AppColors.heading,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              points.isEmpty ? '' : _dateOnly(points.first.capturedAt),
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1.05),
            1: FlexColumnWidth(1.25),
            2: FlexColumnWidth(1.35),
            3: FlexColumnWidth(.85),
            4: FlexColumnWidth(.85),
          },
          border: TableBorder.all(color: AppColors.muted),
          children: [
            const TableRow(
              decoration: BoxDecoration(color: AppColors.panelDark),
              children: [
                _RegistryCell('PUNTO', header: true),
                _RegistryCell('PULSOS/\nPATRÓN', header: true),
                _RegistryCell('LECTURA L /\nV.MEC L', header: true),
                _RegistryCell('ERROR %', header: true),
                _RegistryCell('CAUDAL\nL/s', header: true),
              ],
            ),
            ...([
              ...points,
            ]..sort((a, b) => a.capturedAt.compareTo(b.capturedAt))).map((
              point,
            ) {
              final hydrantPulses = point.meterUnderTestPulseCount ?? 0;
              final hasHydrantReading = hydrantPulses > 0;
              final hydrantLiters =
                  hydrantPulses * configuration.hydrantLitersPerPulse;
              final reference = point.referenceLiters ?? 0;
              final diagnosticError = !hasHydrantReading || reference <= 0
                  ? null
                  : (hydrantLiters - reference) / reference * 100;
              return TableRow(
                children: [
                  _RegistryCell(
                    '${_pointLabel(point.type)}\n${_timeOnly(point.capturedAt)}',
                  ),
                  _RegistryCell(
                    '${point.pulseCount ?? 0} / ${point.referenceLiters?.toStringAsFixed(1) ?? '0.0'} L',
                    numeric: true,
                  ),
                  _RegistryCell(
                    hasHydrantReading
                        ? '${hydrantLiters.toStringAsFixed(2)} / $hydrantPulses'
                        : '',
                    numeric: true,
                  ),
                  _RegistryCell(
                    diagnosticError?.toStringAsFixed(2) ?? '',
                    numeric: true,
                  ),
                  _RegistryCell(
                    point.flowLps?.toStringAsFixed(2) ?? '',
                    numeric: true,
                  ),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        if (flowStatistics != null)
          Text(
            'Caudal puntual · mín. ${flowStatistics.minimumLps.toStringAsFixed(2)} · máx. ${flowStatistics.maximumLps.toStringAsFixed(2)} · promedio ${flowStatistics.averageLps.toStringAsFixed(2)} L/s',
            style: const TextStyle(color: AppColors.heading, fontSize: 12),
          ),
        if (flowStatistics != null) const SizedBox(height: 6),
        const Text(
          'Los errores de puntos son diagnósticos; el resultado oficial usa el endpoint.',
          style: TextStyle(color: AppColors.warning, fontSize: 12),
        ),
      ],
    );
  }
}

final class _RegistryCell extends StatelessWidget {
  const _RegistryCell(this.value, {this.header = false, this.numeric = false});
  final String value;
  final bool header;
  final bool numeric;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
    child: Text(
      value,
      maxLines: 2,
      textAlign: numeric ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: header ? 10 : 11,
        fontWeight: header ? FontWeight.w700 : FontWeight.normal,
      ),
    ),
  );
}

String _pointLabel(PointType type) => switch (type) {
  PointType.start => 'INICIO',
  PointType.intermediate => 'INTERMEDIO',
  PointType.finalPoint => 'FINAL',
  PointType.manualDiagnostic => 'MANUAL',
};

String _timeOnly(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}

String _dateOnly(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year}';
}

String evidenceTypeLabel(EvidenceType type) => switch (type) {
  EvidenceType.start => 'START',
  EvidenceType.intermediate => 'INTERMEDIATE',
  EvidenceType.finalEvidence => 'FINAL',
  EvidenceType.extra => 'EXTRA',
};

String _timestamp(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}
