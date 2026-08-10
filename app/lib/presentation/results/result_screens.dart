import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/metrology/metrology.dart';
import '../../domain/models.dart';
import '../app_controller.dart';
import '../common/app_scaffold.dart';
import '../home/home_screens.dart';

final class SampleResultScreen extends ConsumerWidget {
  const SampleResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final sample = state.sample!;
    final result = sample.result!;
    final color = verdictColor(result.verdict);
    return AppScaffold(
      title: 'Resultado de prueba',
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusBanner(
            text:
                '${verdictLabel(result.verdict)} · ${result.errorPct.toStringAsFixed(2)} % ±${result.uncertaintyPct.toStringAsFixed(2)} %',
            color: color,
            icon: verdictIcon(result.verdict),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Resultado metrológico',
            child: Column(
              children: [
                _value(
                  'Vref',
                  '${result.referenceLiters.toStringAsFixed(2)} L',
                ),
                _value(
                  'Vind',
                  '${result.indicatedLiters.toStringAsFixed(2)} L',
                ),
                _value('Error', '${result.errorPct.toStringAsFixed(6)} %'),
                _value('U', '${result.uncertaintyPct.toStringAsFixed(6)} %'),
                _value('MPE', '±${result.mpePct.toStringAsFixed(2)} %'),
                _value(
                  '|E| + U',
                  '${result.decisionMetrics.acceptanceMetricPct.toStringAsFixed(6)} %',
                ),
                _value(
                  '|E| − U',
                  '${result.decisionMetrics.rejectionMetricPct.toStringAsFixed(6)} %',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Decisión calculada con valores completos; el redondeo mostrado no interviene.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (result.verdict == SampleVerdict.inconclusive) ...[
            const SizedBox(height: 14),
            const StatusBanner(
              text:
                  'El intervalo cruza el límite. Debe realizarse una nueva muestra.',
              color: AppColors.warning,
              icon: Icons.replay,
            ),
          ],
          const SizedBox(height: 14),
          FilledButton(
            key: const Key('another-sample'),
            onPressed: controller.anotherSample,
            child: const Text('INICIAR OTRA MUESTRA'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: controller.changeFlow,
            child: const Text('CAMBIAR CAUDAL'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('case-summary'),
            onPressed: controller.showCaseSummary,
            child: const Text('TERMINAR / RESUMEN DEL EXPEDIENTE'),
          ),
        ],
      ),
    );
  }

  Widget _value(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

final class InvalidEvidenceScreen extends ConsumerWidget {
  const InvalidEvidenceScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    title: 'Prueba no válida',
    showBack: false,
    child: SectionCard(
      title: 'Evidencia incompleta',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StatusBanner(
            text:
                'No se obtuvo toda la evidencia requerida. La prueba se conservará en el historial y debe repetirse.',
            color: AppColors.danger,
            icon: Icons.broken_image_outlined,
          ),
          const SizedBox(height: 18),
          FilledButton(
            key: const Key('repeat-invalid'),
            onPressed: ref.read(appControllerProvider.notifier).repeatSample,
            child: const Text('REPETIR PRUEBA'),
          ),
        ],
      ),
    ),
  );
}

final class CaseSummaryScreen extends ConsumerWidget {
  const CaseSummaryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final valid = state.samples
        .where(
          (sample) =>
              sample.status == SampleStatus.closedValid &&
              sample.result != null,
        )
        .toList();
    final grouped = <FlowPoint, List<Sample>>{};
    for (final sample in valid) {
      grouped.putIfAbsent(sample.configuration.flowPoint, () => []).add(sample);
    }
    return AppScaffold(
      title: 'Resumen del expediente',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'Expediente',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medidor ${state.meter?.id ?? '—'}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Usuario ${state.user?.email ?? '—'}',
                  style: const TextStyle(color: AppColors.muted),
                ),
                Text(
                  'Estado: ${state.activeCase?.status == VerificationCaseStatus.closed ? 'FINALIZADO' : 'ABIERTO'}',
                ),
                Text(
                  'Resultado global: ${overallLabel(state.activeCase?.overallVerdict)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (grouped.isEmpty)
            const StatusBanner(
              text:
                  'No hay muestras válidas cerradas. El expediente será NO CONCLUYENTE.',
              color: AppColors.warning,
            )
          else
            for (final entry in grouped.entries) ...[
              _FlowSummary(flow: entry.key, samples: entry.value),
              const SizedBox(height: 10),
            ],
          if (state.activeCase?.status == VerificationCaseStatus.open)
            FilledButton(
              key: const Key('close-case'),
              onPressed: () async {
                final confirmed =
                    await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Terminar expediente'),
                        content: const Text(
                          'El expediente cerrado será de solo lectura y no aceptará nuevas muestras.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('CANCELAR'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('TERMINAR'),
                          ),
                        ],
                      ),
                    ) ??
                    false;
                if (confirmed) controller.closeCase();
              },
              child: const Text('TERMINAR EXPEDIENTE'),
            )
          else
            const StatusBanner(
              text: 'Expediente finalizado · solo lectura',
              color: AppColors.heading,
              icon: Icons.lock_outline,
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: controller.showHome,
            child: const Text('VOLVER AL INICIO'),
          ),
        ],
      ),
    );
  }
}

final class _FlowSummary extends StatelessWidget {
  const _FlowSummary({required this.flow, required this.samples});
  final FlowPoint flow;
  final List<Sample> samples;
  @override
  Widget build(BuildContext context) {
    final results = samples.map((sample) => sample.result!).toList();
    final summary = FlowPointResult.summarize(
      flowPoint: flow,
      samples: results,
      mpePct: results.first.mpePct,
    );
    final stats = summary.statistics!;
    return SectionCard(
      title: '${flow.name.toUpperCase()} · ${flowStatusLabel(summary.status)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final sample in samples)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Muestra ${sample.sampleNumber} · ${methodLabel(sample.configuration.measurementMethod)}',
              ),
              subtitle: Text('${sample.endedAt?.toLocal() ?? ''}'),
              trailing: Text(
                '${sample.result!.errorPct.toStringAsFixed(2)} %',
                style: TextStyle(
                  color: verdictColor(sample.result!.verdict),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const Divider(),
          Text(
            'n: ${stats.n} · media: ${stats.meanErrorPct.toStringAsFixed(3)} %',
          ),
          Text(
            'mín: ${stats.minimumErrorPct.toStringAsFixed(3)} · máx: ${stats.maximumErrorPct.toStringAsFixed(3)} %',
          ),
          Text('dispersión: ${stats.dispersionPct.toStringAsFixed(3)} %'),
          Text(
            'desviación estándar: ${stats.sampleStandardDeviationPct?.toStringAsFixed(3) ?? '—'} %',
          ),
          Text(
            'Repetibilidad: ${repeatabilityLabel(stats.repeatabilityStatus)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

Color verdictColor(SampleVerdict value) => switch (value) {
  SampleVerdict.pass => AppColors.success,
  SampleVerdict.fail => AppColors.danger,
  SampleVerdict.inconclusive => AppColors.warning,
};
String verdictLabel(SampleVerdict value) => switch (value) {
  SampleVerdict.pass => 'APRUEBA',
  SampleVerdict.fail => 'RECHAZA',
  SampleVerdict.inconclusive => 'NO CONCLUYENTE',
};
IconData verdictIcon(SampleVerdict value) => switch (value) {
  SampleVerdict.pass => Icons.check_circle,
  SampleVerdict.fail => Icons.cancel,
  SampleVerdict.inconclusive => Icons.help,
};
String flowStatusLabel(FlowPointStatus value) => switch (value) {
  FlowPointStatus.pending => 'PENDIENTE',
  FlowPointStatus.pass => 'APRUEBA',
  FlowPointStatus.fail => 'RECHAZA',
  FlowPointStatus.inconclusive => 'NO CONCLUYENTE',
};
String repeatabilityLabel(RepeatabilityStatus value) => switch (value) {
  RepeatabilityStatus.notEvaluable => 'No evaluable',
  RepeatabilityStatus.pass => 'Cumple',
  RepeatabilityStatus.fail => 'No cumple',
};
