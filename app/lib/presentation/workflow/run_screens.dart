import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/metrology/metrology.dart';
import '../../domain/expected_evidence_plan.dart';
import '../../domain/models.dart';
import '../app_controller.dart';
import '../common/app_scaffold.dart';
import '../home/home_screens.dart';

final class TestRunScreen extends ConsumerStatefulWidget {
  const TestRunScreen({super.key});
  @override
  ConsumerState<TestRunScreen> createState() => _TestRunScreenState();
}

final class _TestRunScreenState extends ConsumerState<TestRunScreen> {
  final _visualReference = TextEditingController(text: '125');

  @override
  void dispose() {
    _visualReference.dispose();
    super.dispose();
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
    return PopScope(
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
                  const SizedBox(height: 12),
                  Text(
                    'Medidor ${state.meter?.id ?? '—'}',
                    key: const Key('running-meter-id'),
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${config.flowPoint.name.toUpperCase()} · ${config.lpsApprox?.toStringAsFixed(2) ?? '—'} L/s · K ${config.litersPerPulse} L/pulso',
                    style: const TextStyle(color: AppColors.muted),
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
                  else if (config.measurementMethod == MeasurementMethod.visual)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const StatusBanner(
                          text:
                              'MODO DE DESARROLLO · Valor que Stage 4 entregará desde visión confirmada.',
                          color: AppColors.heading,
                          icon: Icons.developer_mode,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          key: const Key('visual-reference'),
                          controller: _visualReference,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Vref / progreso visual (L)',
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
                    StatusBanner(
                      text:
                          '${methodLabel(config.measurementMethod)} · No conectado. Integración de hardware real reservada para Stage 5.',
                      color: AppColors.warning,
                      icon: Icons.sensors_off,
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
              child: _Registry(sample: sample, evidence: state.evidence),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('finish-run'),
              onPressed: reference > 0 ? controller.showReadings : null,
              child: const Text('FINALIZAR Y CONFIRMAR LECTURAS'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: controller.showHome,
              child: const Text('SALIR SIN DESCARTAR'),
            ),
          ],
        ),
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
            captured ? 'Capturada' : 'Pendiente',
            style: TextStyle(
              color: captured ? AppColors.success : AppColors.warning,
            ),
          ),
        );
      }).toList(),
    );
  }
}

final class _Registry extends StatelessWidget {
  const _Registry({required this.sample, required this.evidence});
  final Sample sample;
  final List<Evidence> evidence;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _row(
        'Inicio',
        '0 L',
        evidence.any((item) => item.type == EvidenceType.start)
            ? 'Capturada'
            : 'Pendiente',
      ),
      for (final item in evidence.where(
        (item) => item.type == EvidenceType.intermediate,
      ))
        _row(
          'Intermedia',
          '${item.volumeRefLiters?.toStringAsFixed(0) ?? '—'} L',
          'Capturada',
        ),
      _row(
        'Final',
        sample.status == SampleStatus.closedValid
            ? '${sample.result?.referenceLiters.toStringAsFixed(0)} L'
            : '—',
        evidence.any((item) => item.type == EvidenceType.finalEvidence)
            ? 'Capturada'
            : 'Pendiente',
      ),
      const SizedBox(height: 8),
      const Text(
        'Los errores de puntos son diagnósticos; el resultado oficial usa el endpoint.',
        style: TextStyle(color: AppColors.warning, fontSize: 12),
      ),
    ],
  );

  Widget _row(String point, String volume, String status) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(point)),
        Expanded(child: Text(volume, textAlign: TextAlign.center)),
        Expanded(
          child: Text(
            status,
            textAlign: TextAlign.end,
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
      ],
    ),
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
