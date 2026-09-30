import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/metrology/metrology.dart';
import '../../domain/models.dart';
import '../../infrastructure/pulse/ble_discovery.dart';
import '../app_controller.dart';
import '../common/app_scaffold.dart';
import '../home/home_screens.dart';

String flowLabel(FlowPoint flow) => switch (flow) {
  FlowPoint.q1 => 'Q1 — Caudal operativo',
  FlowPoint.q2 => 'Q2 — Caudal medio',
  FlowPoint.q3 => 'Q3 — Caudal permanente',
  FlowPoint.q4 => 'Q4 — Caudal de sobrecarga',
};

String meterStatusLabel(ExternalMeterStatus status) => switch (status) {
  ExternalMeterStatus.foundWithSurvey => 'Localizado con levantamiento',
  ExternalMeterStatus.foundNoSurvey => 'Localizado sin levantamiento',
  ExternalMeterStatus.notFound => 'Nuevo / no localizado',
  ExternalMeterStatus.unknownOffline => 'Sin resultado de consulta',
};

final class IdentificationScreen extends ConsumerStatefulWidget {
  const IdentificationScreen({super.key});
  @override
  ConsumerState<IdentificationScreen> createState() =>
      _IdentificationScreenState();
}

final class _IdentificationScreenState
    extends ConsumerState<IdentificationScreen> {
  final _form = GlobalKey<FormState>();
  late final _meter = TextEditingController(
    text: ref.read(appControllerProvider).identificationMeterId,
  );
  late final _testBench = TextEditingController(
    text: ref.read(appControllerProvider).identificationTestBenchId,
  );

  @override
  void dispose() {
    _meter.dispose();
    _testBench.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final capabilities = ref.watch(appDependenciesProvider);
    return AppScaffold(
      title: 'Identificación',
      child: Form(
        key: _form,
        child: SectionCard(
          title: '1 · Identificación',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('meter-id'),
                controller: _meter,
                onChanged: (value) =>
                    controller.updateIdentificationDraft(meterId: value),
                decoration: const InputDecoration(
                  labelText: 'ID / número de cuenta del medidor',
                  hintText: 'p. ej. H-016',
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Captura cualquier ID válido.'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('test-bench-id'),
                controller: _testBench,
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) =>
                    controller.updateIdentificationDraft(testBenchId: value),
                decoration: const InputDecoration(
                  labelText: 'ID / banco de pruebas',
                  hintText: 'p. ej. BANCO-01',
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Captura el banco de pruebas utilizado.'
                    : null,
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  state.gps == null
                      ? Icons.location_off_outlined
                      : Icons.location_on_outlined,
                  color: state.gps == null
                      ? AppColors.muted
                      : AppColors.success,
                ),
                title: Text(
                  state.gpsCaptureState == GpsCaptureState.capturing
                      ? 'Obteniendo ubicación GPS…'
                      : state.gps == null
                      ? 'Ubicación GPS no capturada'
                      : '${state.gps!.latitude.toStringAsFixed(6)}, ${state.gps!.longitude.toStringAsFixed(6)}',
                ),
                subtitle: Text(
                  state.gps == null
                      ? state.gpsMessage ??
                            'Funciona sin internet. La prueba puede continuar si GPS falla.'
                      : 'Precisión ±${state.gps!.accuracyMeters.toStringAsFixed(0)} m',
                  style: const TextStyle(color: AppColors.muted),
                ),
                trailing: IconButton(
                  key: const Key('capture-gps'),
                  onPressed:
                      state.busy ||
                          state.gpsCaptureState == GpsCaptureState.capturing
                      ? null
                      : controller.captureGps,
                  tooltip: 'Obtener ubicación GPS',
                  icon: const Icon(Icons.my_location),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Text(
                  '* Dato informativo para validación interna',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
              if (capabilities.hydrantLookupConfigured)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.manage_search_outlined,
                    color: AppColors.heading,
                  ),
                  title: Text(
                    state.hydrantLookupInProgress
                        ? 'Consultando…'
                        : state.meter == null
                        ? 'Consulta de cuenta disponible'
                        : meterStatusLabel(state.meter!.externalStatus),
                  ),
                  subtitle: const Text(
                    'La consulta es informativa y nunca bloquea la prueba.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              if (state.errorMessage != null)
                Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              const SizedBox(height: 14),
              FilledButton(
                key: const Key('identify-continue'),
                onPressed: () async {
                  if (_form.currentState!.validate()) {
                    if (state.gps == null) {
                      final continueWithoutGps = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Ubicación no registrada'),
                          content: const Text(
                            '¿Desea continuar sin capturar la ubicación de esta verificación?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('CAPTURAR UBICACIÓN'),
                            ),
                            FilledButton(
                              key: const Key('confirm-without-gps'),
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('CONTINUAR SIN UBICACIÓN'),
                            ),
                          ],
                        ),
                      );
                      if (!context.mounted || continueWithoutGps != true) {
                        return;
                      }
                    }
                    await controller.identifyMeter(
                      meterId: _meter.text,
                      testBenchId: _testBench.text,
                    );
                  }
                },
                child: const Text('CONTINUAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class MethodScreen extends ConsumerStatefulWidget {
  const MethodScreen({super.key});

  @override
  ConsumerState<MethodScreen> createState() => _MethodScreenState();
}

final class _MethodScreenState extends ConsumerState<MethodScreen> {
  @override
  void initState() {
    super.initState();
    if (ref.read(appControllerProvider).selectedBleDevice == null) {
      Future.microtask(
        () => ref
            .read(appControllerProvider.notifier)
            .scanBleDevices(autoSelectSingle: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    return AppScaffold(
      title: 'Método de medición',
      child: SectionCard(
        title: '2 · Fuente / método',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  const [
                        MeasurementMethod.ble,
                        MeasurementMethod.manual,
                        MeasurementMethod.visual,
                        MeasurementMethod.simulation,
                      ]
                      .map(
                        (method) => ChoiceChip(
                          key: Key('method-${method.name}'),
                          selected: state.selectedMethod == method,
                          onSelected: method == MeasurementMethod.visual
                              ? null
                              : (_) async {
                                  if (state.sample != null &&
                                      state.sample!.status !=
                                          SampleStatus.closedValid &&
                                      state.selectedMethod != method) {
                                    final replace = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: const Text('Cambiar método'),
                                        content: const Text(
                                          'Se descartará únicamente la preparación dependiente de la muestra abierta. El expediente y Q1/Q2 se conservarán.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              false,
                                            ),
                                            child: const Text('CANCELAR'),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              true,
                                            ),
                                            child: const Text('CAMBIAR'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (replace != true) return;
                                    await controller.replaceOpenSampleMethod(
                                      method,
                                    );
                                    return;
                                  }
                                  controller.selectMethod(method);
                                },
                          label: Text(methodLabel(method)),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 18),
            _MethodPanel(
              method: state.selectedMethod,
              hardwareState: state.hardwareState,
              onHardwareState: controller.setHardwareState,
              bleDevices: state.bleDevices,
              selectedBleDevice: state.selectedBleDevice,
              onScanBle: controller.scanBleDevices,
              onSelectBle: controller.selectBleDevice,
              onDisconnectBle: controller.disconnectBleDevice,
            ),
            if (state.selectedMethod == MeasurementMethod.simulation) ...[
              const SizedBox(height: 18),
              const StatusBanner(
                text:
                    'SIMULACIÓN CONTROLADA · Q1 fluctúa entre 5 y 7 L/s; Q2 entre 2 y 3 L/s. El técnico decide cuándo iniciar y finalizar, captura las lecturas y el motor calcula el resultado real.',
                color: AppColors.warning,
                icon: Icons.science_outlined,
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('method-continue'),
              onPressed:
                  state.selectedMethod == MeasurementMethod.manual ||
                      state.selectedMethod == MeasurementMethod.simulation ||
                      state.hardwareState == HardwareState.ready
                  ? controller.continueToSetup
                  : null,
              child: const Text('CONFIGURAR PRUEBA'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _MethodPanel extends StatelessWidget {
  const _MethodPanel({
    required this.method,
    required this.hardwareState,
    required this.onHardwareState,
    required this.bleDevices,
    required this.selectedBleDevice,
    required this.onScanBle,
    required this.onSelectBle,
    required this.onDisconnectBle,
  });
  final MeasurementMethod method;
  final HardwareState hardwareState;
  final ValueChanged<HardwareState> onHardwareState;
  final List<BleDeviceCandidate> bleDevices;
  final BleDeviceCandidate? selectedBleDevice;
  final Future<void> Function() onScanBle;
  final ValueChanged<BleDeviceCandidate> onSelectBle;
  final Future<void> Function() onDisconnectBle;

  @override
  Widget build(BuildContext context) {
    if (method == MeasurementMethod.visual) {
      return const StatusBanner(
        text:
            'LECTURA VISUAL productiva con cámara real y captura manual de la lectura al finalizar.',
        color: AppColors.heading,
        icon: Icons.visibility_outlined,
      );
    }
    if (method == MeasurementMethod.manual) {
      return const StatusBanner(
        text:
            'Captura manual de pulsos · Cada toque incrementa N una vez y persiste Vref = N × K.',
        color: AppColors.amber,
        icon: Icons.touch_app_outlined,
      );
    }
    if (method == MeasurementMethod.simulation) {
      return const StatusBanner(
        text:
            'MODO SIMULACIÓN · Sin Bluetooth, ESP32, backend ni Internet. Los datos recorren el pipeline real.',
        color: AppColors.warning,
        icon: Icons.science_outlined,
      );
    }
    final label = switch (hardwareState) {
      HardwareState.notConnected => 'No conectado',
      HardwareState.preparing => 'Preparando',
      HardwareState.ready => 'Conectado / listo',
      HardwareState.error => 'Error',
      HardwareState.disconnected => 'Desconectado',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hardwareState == HardwareState.preparing)
          const _ConnectingMetersBanner()
        else
          StatusBanner(
            text: method == MeasurementMethod.ble
                ? '$label · ${selectedBleDevice?.name ?? 'Seleccione DDR001 ESP32'}'
                : '$label · Configure ROI LED y reconciliación BLE.',
            color: hardwareState == HardwareState.ready
                ? AppColors.success
                : AppColors.warning,
            icon: method == MeasurementMethod.ble
                ? Icons.bluetooth_disabled
                : Icons.highlight_outlined,
          ),
        const SizedBox(height: 10),
        if (method == MeasurementMethod.ble ||
            method == MeasurementMethod.led) ...[
          OutlinedButton.icon(
            key: const Key('ble-scan'),
            onPressed: onScanBle,
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('BUSCAR ESP32'),
          ),
          if (selectedBleDevice != null)
            OutlinedButton.icon(
              key: const Key('ble-disconnect'),
              onPressed: onDisconnectBle,
              icon: const Icon(Icons.link_off),
              label: const Text('DESCONECTAR ESP32'),
            ),
          for (final device in bleDevices)
            ListTile(
              selected: selectedBleDevice?.id == device.id,
              onTap: () => onSelectBle(device),
              leading: Icon(
                selectedBleDevice?.id == device.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: Text(device.name),
              subtitle: Text('${device.id} · RSSI ${device.rssi} dBm'),
            ),
          if (method == MeasurementMethod.led)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'BLE se usa únicamente como contador auxiliar de integridad; el método permanece LED.',
              ),
            ),
        ],
      ],
    );
  }
}

final class _ConnectingMetersBanner extends StatefulWidget {
  const _ConnectingMetersBanner();

  @override
  State<_ConnectingMetersBanner> createState() =>
      _ConnectingMetersBannerState();
}

final class _ConnectingMetersBannerState extends State<_ConnectingMetersBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);
  late final Animation<double> _opacity = Tween<double>(
    begin: .42,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: Container(
      key: const Key('connecting-meters-banner'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2388E8).withValues(alpha: .24),
        border: Border.all(color: const Color(0xFF55B5FF), width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'CONECTANDO A MEDIDORES',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF8ED0FF),
          fontWeight: FontWeight.w800,
          letterSpacing: .5,
        ),
      ),
    ),
  );
}

final class TestSetupScreen extends ConsumerStatefulWidget {
  const TestSetupScreen({super.key});
  @override
  ConsumerState<TestSetupScreen> createState() => _TestSetupScreenState();
}

final class _TestSetupScreenState extends ConsumerState<TestSetupScreen> {
  final _form = GlobalKey<FormState>();
  late final _k = TextEditingController(
    text: ref.read(appControllerProvider).litersPerPulse.toString(),
  );
  late final _step = TextEditingController(
    text: ref.read(appControllerProvider).evidenceStepLiters.toString(),
  );
  late final _uncertainty = TextEditingController(
    text: ref.read(appControllerProvider).readingUncertaintyLiters.toString(),
  );
  late final _minimum = TextEditingController(
    text: ref.read(appControllerProvider).minimumVolumeLiters.toString(),
  );
  late final _maximum = TextEditingController(
    text: ref.read(appControllerProvider).maximumVolumeLiters.toString(),
  );
  late final _startMin = TextEditingController(
    text: ref.read(appControllerProvider).controlStartMinimumLps.toString(),
  );
  late final _startMax = TextEditingController(
    text: ref.read(appControllerProvider).controlStartMaximumLps.toString(),
  );
  late final _hydrantK = TextEditingController(
    text: ref.read(appControllerProvider).hydrantLitersPerPulse.toString(),
  );
  late final _odometerScale = TextEditingController(
    text: ref.read(appControllerProvider).litersPerOdometerUnit.toString(),
  );
  late final _needleScale = TextEditingController(
    text: ref.read(appControllerProvider).needleLitersPerRevolution.toString(),
  );
  late final _integerDigits = TextEditingController(
    text: ref.read(appControllerProvider).totalizerIntegerDigits.toString(),
  );
  late int _decimalPlaces = ref
      .read(appControllerProvider)
      .totalizerDecimalPlaces;

  @override
  void dispose() {
    _k.dispose();
    _step.dispose();
    _uncertainty.dispose();
    _minimum.dispose();
    _maximum.dispose();
    _startMin.dispose();
    _startMax.dispose();
    _hydrantK.dispose();
    _odometerScale.dispose();
    _needleScale.dispose();
    _integerDigits.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    return AppScaffold(
      title: 'Preparación',
      child: Form(
        key: _form,
        child: SectionCard(
          title: 'Configuración',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _summary('Medidor', state.meter?.id ?? '—'),
              _summary('Q1 — Caudal operativo', 'Calculado durante la prueba'),
              _summary('Q2 — Caudal medio', 'Calculado durante la prueba'),
              _summary('Método', methodLabel(state.selectedMethod)),
              if (state.selectedMethod == MeasurementMethod.simulation)
                _summary(
                  'Escenario',
                  _simulationScenarioLabel(state.selectedSimulationScenario),
                ),
              TextFormField(
                key: const Key('config-reference-k'),
                controller: _k,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Medidor patrón · litros por pulso',
                  helperText: 'Bluetooth, manual, LED o simulación · Q1 y Q2',
                ),
                validator: _positivePulseValue,
              ),
              const Divider(),
              if (state.selectedMethod == MeasurementMethod.simulation) ...[
                const StatusBanner(
                  text:
                      'MODO SIMULACIÓN · PRUEBA SIMULADA — NO CORRESPONDE A UNA VERIFICACIÓN FÍSICA',
                  color: AppColors.warning,
                  icon: Icons.science_outlined,
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('config-minimum-volume'),
                      controller: _minimum,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Vmín orientativo (L)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      key: const Key('config-maximum-volume'),
                      controller: _maximum,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Vmáx orientativo (L)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('config-control-start-min'),
                      controller: _startMin,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Caudal mínimo para iniciar (L/s)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      key: const Key('config-control-start-max'),
                      controller: _startMax,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Caudal máximo para iniciar (L/s)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                validator: _positivePulseValue,
                key: const Key('config-hydrant-k'),
                controller: _hydrantK,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Medidor del hidrante · litros por pulso',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('config-odometer-scale'),
                      controller: _odometerScale,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Escala del odómetro (L/unidad)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      key: const Key('config-needle-scale'),
                      controller: _needleScale,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Escala aguja (L/vuelta)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('config-totalizer-integers'),
                      controller: _integerDigits,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Enteros del odómetro',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: const Key('config-totalizer-decimals'),
                      initialValue: _decimalPlaces,
                      decoration: const InputDecoration(labelText: 'Decimales'),
                      items: const [0, 1, 2, 3]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                value == 0 ? 'Sin decimales' : '$value',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _decimalPlaces = value ?? 0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('config-step'),
                controller: _step,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Paso de evidencia (L)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('config-u'),
                controller: _uncertainty,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Incertidumbre base uL (L)',
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('start-sample'),
                onPressed: state.busy
                    ? null
                    : () {
                        if (!_form.currentState!.validate()) return;
                        try {
                          controller.updateSetup(
                            litersPerPulse: double.parse(
                              _k.text.replaceAll(',', '.'),
                            ),
                            evidenceStepLiters:
                                double.tryParse(_step.text) ?? 25,
                            uncertaintyLiters:
                                double.tryParse(_uncertainty.text) ?? 1,
                            minimumVolumeLiters:
                                double.tryParse(_minimum.text) ?? 100,
                            maximumVolumeLiters:
                                double.tryParse(_maximum.text) ?? 300,
                            controlStartMinimumLps:
                                double.tryParse(_startMin.text) ?? .5,
                            controlStartMaximumLps:
                                double.tryParse(_startMax.text) ?? 50,
                            hydrantLitersPerPulse: double.parse(
                              _hydrantK.text.replaceAll(',', '.'),
                            ),
                            litersPerOdometerUnit:
                                double.tryParse(_odometerScale.text) ?? 1000,
                            needleLitersPerRevolution:
                                double.tryParse(_needleScale.text) ?? 100,
                            totalizerIntegerDigits:
                                int.tryParse(_integerDigits.text) ?? 5,
                            totalizerDecimalPlaces: _decimalPlaces,
                          );
                          controller.startSample();
                        } on ArgumentError catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${error.message}')),
                          );
                        }
                      },
                child: Text(
                  state.selectedMethod == MeasurementMethod.simulation
                      ? 'INICIAR SIMULACIÓN'
                      : 'PREPARAR CÁMARA',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _positivePulseValue(String? text) {
    final value = double.tryParse((text ?? '').replaceAll(',', '.'));
    return value == null || !value.isFinite || value <= 0
        ? 'Introduce litros por pulso mayores que cero.'
        : null;
  }

  Widget _summary(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

String _simulationScenarioLabel(SimulationScenario scenario) =>
    switch (scenario) {
      SimulationScenario.successful => 'Prueba exitosa',
      SimulationScenario.failed => 'Prueba fallida',
      SimulationScenario.failThenPass =>
        'Mixta: primera muestra falla / segunda aprueba',
      SimulationScenario.operatorControlled => 'Controlada por operador',
    };
