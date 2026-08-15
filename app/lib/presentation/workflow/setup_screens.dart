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
  FlowPoint.q1 => 'Q1 — Caudal mínimo',
  FlowPoint.q2 => 'Q2 — Caudal de transición',
  FlowPoint.q3 => 'Q3 — Caudal permanente',
  FlowPoint.q4 => 'Q4 — Caudal de sobrecarga',
};

String meterStatusLabel(ExternalMeterStatus status) => switch (status) {
  ExternalMeterStatus.foundWithSurvey => 'Localizado con levantamiento',
  ExternalMeterStatus.foundNoSurvey => 'Localizado sin levantamiento',
  ExternalMeterStatus.notFound => 'Nuevo / no localizado',
  ExternalMeterStatus.unknownOffline => 'Pendiente de consulta / offline',
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
  final _meter = TextEditingController();
  final _lps = TextEditingController(text: '20');

  @override
  void dispose() {
    _meter.dispose();
    _lps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
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
                decoration: const InputDecoration(
                  labelText: 'ID / número de cuenta del medidor',
                  hintText: 'p. ej. H-016',
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Captura cualquier ID válido.'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FlowPoint>(
                key: const Key('flow-selector'),
                initialValue: state.selectedFlow,
                decoration: const InputDecoration(labelText: 'Caudal'),
                items: FlowPoint.values
                    .map(
                      (flow) => DropdownMenuItem(
                        value: flow,
                        child: Text(flowLabel(flow)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) controller.selectFlow(value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('lps-input'),
                controller: _lps,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'LPS aproximado manual',
                ),
                validator: (value) => (double.tryParse(value ?? '') ?? 0) > 0
                    ? null
                    : 'Ingresa un LPS mayor que cero.',
              ),
              const SizedBox(height: 12),
              StatusBanner(
                text:
                    '${flowLabel(state.selectedFlow)} · MPE ±${const Class2WaterMpePolicy().mpePctFor(state.selectedFlow).toStringAsFixed(0)} %',
                color: AppColors.heading,
                icon: Icons.speed,
              ),
              const SizedBox(height: 10),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.location_off_outlined,
                  color: AppColors.muted,
                ),
                title: Text('GPS preparado'),
                subtitle: Text(
                  'Ubicación no disponible en Stage 3',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.cloud_off_outlined, color: AppColors.muted),
                title: Text('Pendiente de consulta / offline'),
                subtitle: Text(
                  'La cuenta nueva siempre está permitida.',
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
                onPressed: () {
                  if (_form.currentState!.validate()) {
                    controller.identifyMeter(
                      meterId: _meter.text,
                      lpsApprox: double.parse(_lps.text),
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

final class MethodScreen extends ConsumerWidget {
  const MethodScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              children: MeasurementMethod.values
                  .map(
                    (method) => ChoiceChip(
                      key: Key('method-${method.name}'),
                      selected: state.selectedMethod == method,
                      onSelected: (_) => controller.selectMethod(method),
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
            ),
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('method-continue'),
              onPressed: controller.continueToSetup,
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
  });
  final MeasurementMethod method;
  final HardwareState hardwareState;
  final ValueChanged<HardwareState> onHardwareState;
  final List<BleDeviceCandidate> bleDevices;
  final BleDeviceCandidate? selectedBleDevice;
  final Future<void> Function() onScanBle;
  final ValueChanged<BleDeviceCandidate> onSelectBle;

  @override
  Widget build(BuildContext context) {
    if (method == MeasurementMethod.visual) {
      return const StatusBanner(
        text:
            'LECTURA VISUAL productiva con cámara real, OCR de odómetro, detección de aguja y confirmación humana.',
        color: AppColors.heading,
        icon: Icons.visibility_outlined,
      );
    }
    if (method == MeasurementMethod.manual) {
      return const StatusBanner(
        text:
            'Cada toque del botón de pulso incrementará N y persistirá Vref = N × K.',
        color: AppColors.amber,
        icon: Icons.touch_app_outlined,
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
            label: const Text('BUSCAR ESP32 DDR001'),
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

final class TestSetupScreen extends ConsumerStatefulWidget {
  const TestSetupScreen({super.key});
  @override
  ConsumerState<TestSetupScreen> createState() => _TestSetupScreenState();
}

final class _TestSetupScreenState extends ConsumerState<TestSetupScreen> {
  late final _k = TextEditingController(
    text: ref.read(appControllerProvider).litersPerPulse.toString(),
  );
  late final _step = TextEditingController(
    text: ref.read(appControllerProvider).evidenceStepLiters.toString(),
  );
  late final _uncertainty = TextEditingController(
    text: ref.read(appControllerProvider).readingUncertaintyLiters.toString(),
  );

  @override
  void dispose() {
    _k.dispose();
    _step.dispose();
    _uncertainty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    return AppScaffold(
      title: 'Preparación',
      child: SectionCard(
        title: 'Configuración congelada',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _summary('Medidor', state.meter?.id ?? '—'),
            _summary('Caudal', flowLabel(state.selectedFlow)),
            _summary(
              'LPS',
              '${state.lpsApprox?.toStringAsFixed(2) ?? '—'} L/s',
            ),
            _summary('Método', methodLabel(state.selectedMethod)),
            _summary(
              'MPE',
              '±${state.flow?.mpePct.toStringAsFixed(0) ?? '—'} %',
            ),
            const Divider(),
            TextField(
              key: const Key('config-k'),
              controller: _k,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: state.selectedMethod.isPulseEventSource,
              decoration: const InputDecoration(
                labelText: 'K · litros por pulso',
              ),
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
            const Text(
              'Escala: odómetro 1000 L/unidad · aguja 100 L/vuelta',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('start-sample'),
              onPressed: () {
                controller.updateSetup(
                  litersPerPulse: double.tryParse(_k.text) ?? 1,
                  evidenceStepLiters: double.tryParse(_step.text) ?? 25,
                  uncertaintyLiters: double.tryParse(_uncertainty.text) ?? 1,
                );
                controller.startSample();
              },
              child: const Text('INICIAR PRUEBA'),
            ),
          ],
        ),
      ),
    );
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
