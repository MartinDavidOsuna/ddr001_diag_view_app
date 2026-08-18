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
import '../home/home_screens.dart';

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

  @override
  void initState() {
    super.initState();
    _remoteChannel.setMethodCallHandler((call) async {
      if (call.method == 'shutterPressed' && mounted) {
        _triggerRemoteAction();
      } else if (call.method == 'remoteConnectionChanged' && mounted) {
        final connected = call.arguments == true;
        ref
            .read(appControllerProvider.notifier)
            .setRemoteControlConnected(connected);
        if (!connected && _remoteControlArmed) {
          setState(() => _remoteControlArmed = false);
        }
      }
    });
    unawaited(_refreshRemoteConnection());
  }

  Future<void> _refreshRemoteConnection() async {
    try {
      final connected = await _remoteChannel.invokeMethod<bool>(
        'getRemoteConnected',
      );
      if (mounted) {
        ref
            .read(appControllerProvider.notifier)
            .setRemoteControlConnected(connected ?? false);
      }
    } on PlatformException {
      // Older/native-less test hosts simply report no remote control.
    }
  }

  @override
  void dispose() {
    _visualReference.dispose();
    _remoteFocusNode.dispose();
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
    return KeyboardListener(
      focusNode: _remoteFocusNode,
      autofocus: true,
      onKeyEvent: _handleRemoteKey,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final leave =
              await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Prueba en curso'),
                  content: const Text(
                    'La prueba seguirá RUNNING y podrá reanudarse. ¿Salir a inicio?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('CONTINUAR PRUEBA'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('SALIR'),
                    ),
                  ],
                ),
              ) ??
              false;
          if (leave) controller.showHome();
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
            litersPerPulse: config.litersPerPulse,
            hydrantLitersPerPulse: config.hydrantLitersPerPulse,
            canFinish: reference > 0,
            onFinish: dependenciesHaveCamera(ref)
                ? controller.requestFinalEvidence
                : controller.showReadings,
            onBegin: controller.beginMeasurement,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                title: '4 · Prueba',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _Metric(
                            label: 'Pulsos',
                            value: config.measurementMethod.isPulseEventSource
                                ? '${sample.pulseCount}'
                                : 'N/A',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Metric(
                            label: 'Volumen patrón',
                            value: '${reference.toStringAsFixed(1)} L',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Metric(
                            label: 'Método',
                            value: methodLabel(config.measurementMethod),
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                    else if (config.measurementMethod ==
                        MeasurementMethod.visual)
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
                              labelText:
                                  'Volumen patrón externo / progreso (L)',
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
                          if (config.measurementMethod ==
                                  MeasurementMethod.led &&
                              sample
                                      .pulseAcquisitionConfiguration
                                      ?.ledBaseline ==
                                  null)
                            _LedPreparationPanel(
                              initialRegion: state.ledRegion,
                            ),
                          if (config.measurementMethod ==
                                  MeasurementMethod.led &&
                              sample
                                      .pulseAcquisitionConfiguration
                                      ?.ledBaseline !=
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
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Evidencias esperadas',
                child: EvidencePlanView(
                  sample: sample,
                  evidence: state.evidence,
                  currentReference: reference,
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: '5 · Registro',
                child: _Registry(points: state.points),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('capture-diagnostic-point'),
                onPressed: dependenciesHaveCamera(ref)
                    ? controller.requestManualDiagnosticPoint
                    : null,
                child: const Text('CAPTURAR UN PUNTO AHORA'),
              ),
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
    final firstPulse = widget.preStartControlFirstPulseAt;
    final now = DateTime.now().toUtc();
    final gate = ControlStartGate.evaluate(
      pulses: widget.preStartControlPulses,
      litersPerPulse: widget.litersPerPulse,
      firstPulseAt: firstPulse,
      now: now,
      minimumLps: widget.sample.configuration.controlStartMinimumLps,
      maximumLps: widget.sample.configuration.controlStartMaximumLps,
    );
    final calculatedFlow = gate.flowLps;
    final flowInRange = gate.inRange;
    final hydrantEstimate = PulseFlowEstimate.calculate(
      pulses: widget.hydrantMonitorPulses,
      litersPerPulse: widget.hydrantLitersPerPulse,
      firstPulseAt: widget.hydrantMonitorFirstPulseAt,
      now: now,
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
              '${widget.sample.configuration.flowPoint.name.toUpperCase()} · ${widget.sample.configuration.lpsApprox?.toStringAsFixed(2) ?? '—'} L/s · K ${widget.litersPerPulse} L/pulso',
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
                    value: widget.meterUnderTestPulses == 0
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
        'START capturada. Las intermedias y FINAL se derivarán al conocer el volumen final.',
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
  const _Registry({required this.points});
  final List<TestPoint> points;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Punto')),
            DataColumn(label: Text('Fecha / hora')),
            DataColumn(label: Text('Pulsos'), numeric: true),
            DataColumn(label: Text('V.patrón L'), numeric: true),
            DataColumn(label: Text('Lectura L'), numeric: true),
            DataColumn(label: Text('V.mec L'), numeric: true),
            DataColumn(label: Text('Error %'), numeric: true),
          ],
          rows:
              ([...points]
                    ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt)))
                  .map(
                    (point) => DataRow(
                      cells: [
                        DataCell(
                          Text(switch (point.type) {
                            PointType.start => 'INICIO',
                            PointType.intermediate => 'INTERMEDIO',
                            PointType.finalPoint => 'FINAL',
                            PointType.manualDiagnostic => 'MANUAL',
                          }),
                        ),
                        DataCell(Text(_timestamp(point.capturedAt))),
                        DataCell(Text('${point.pulseCount ?? '—'}')),
                        DataCell(
                          Text(
                            point.referenceLiters?.toStringAsFixed(2) ?? '—',
                          ),
                        ),
                        DataCell(
                          Text(point.readingLiters?.toStringAsFixed(2) ?? '—'),
                        ),
                        DataCell(
                          Text(
                            point.indicatedLiters?.toStringAsFixed(2) ?? '—',
                          ),
                        ),
                        DataCell(
                          Text(
                            point.diagnosticErrorPct?.toStringAsFixed(2) ?? '—',
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Los errores de puntos son diagnósticos; el resultado oficial usa el endpoint.',
        style: TextStyle(color: AppColors.warning, fontSize: 12),
      ),
    ],
  );
}

final class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.compact = false,
  });
  final String label;
  final String value;
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.panelDark,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            value,
            style: TextStyle(
              fontSize: compact ? 14 : 25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
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
