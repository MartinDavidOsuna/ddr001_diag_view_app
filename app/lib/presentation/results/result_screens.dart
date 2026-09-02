import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

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
          if (sample.isSimulation) ...[
            const StatusBanner(
              text:
                  'MODO SIMULACIÓN · PRUEBA SIMULADA — NO CORRESPONDE A UNA VERIFICACIÓN FÍSICA',
              color: AppColors.warning,
              icon: Icons.science_outlined,
            ),
            const SizedBox(height: 14),
          ],
          StatusBanner(
            text:
                '${verdictLabel(result.verdict)} · ${result.errorPct.toStringAsFixed(2)} % ±${result.uncertaintyPct.toStringAsFixed(2)} %',
            color: color,
            icon: verdictIcon(result.verdict),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title:
                'Resultado ${sample.configuration.flowPoint.name.toUpperCase()}',
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
                if (sample.initialReading != null)
                  _value(
                    'Lectura inicial',
                    '${_readingLiters(sample.initialReading!).toStringAsFixed(3)} L',
                  ),
                _value(
                  'Lectura FINAL capturada',
                  '${_readingLiters(sample.finalReading!).toStringAsFixed(3)} L',
                ),
                _value(
                  'Avance',
                  '${result.indicatedLiters.toStringAsFixed(3)} L',
                ),
                _value('Error', '${result.errorPct.toStringAsFixed(6)} %'),
                _value('U', '${result.uncertaintyPct.toStringAsFixed(6)} %'),
                _value('MPE', '±${result.mpePct.toStringAsFixed(2)} %'),
                _value('Regla de decisión', '|E| + U ≤ MPE'),
                _value(
                  'Duración',
                  sample.startedAt == null || sample.endedAt == null
                      ? '—'
                      : _duration(
                          sample.endedAt!.difference(sample.startedAt!),
                        ),
                ),
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
            key: const Key('repeat-sample'),
            onPressed: controller.repeatSample,
            child: Text(
              'REPETIR PRUEBA ${sample.configuration.flowPoint.name.toUpperCase()}',
            ),
          ),
          if (sample.configuration.flowPoint == FlowPoint.q1) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('start-q2'),
              onPressed: controller.anotherSample,
              child: const Text('COMENZAR Q2'),
            ),
          ],
          if (sample.configuration.flowPoint == FlowPoint.q2) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('case-summary'),
              onPressed: controller.showCaseSummary,
              child: const Text('TERMINAR / RESUMEN DEL EXPEDIENTE'),
            ),
          ],
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

  double _readingLiters(ConfirmedReading reading) =>
      reading.reading.odometerUnits * reading.reading.litersPerOdometerUnit +
      reading.reading.needleLiters;

  String _duration(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
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
          if (state.samples.any((sample) => sample.isSimulation)) ...[
            const StatusBanner(
              text:
                  'MODO SIMULACIÓN · PRUEBA SIMULADA — NO CORRESPONDE A UNA VERIFICACIÓN FÍSICA',
              color: AppColors.warning,
              icon: Icons.science_outlined,
            ),
            const SizedBox(height: 14),
          ],
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
              _FlowSummary(
                flow: entry.key,
                samples: entry.value,
                selectedSampleIds: state.reportSampleIds,
                onSelectionChanged: controller.toggleReportSample,
                pointsBySample: state.casePointsBySample,
                evidenceBySample: state.caseEvidenceBySample,
              ),
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
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('generate-exports'),
            onPressed: state.busy || state.reportSampleIds.isEmpty
                ? null
                : controller.exportCurrentCase,
            icon: const Icon(Icons.description_outlined),
            label: const Text('GENERAR CSV · JSON · HTML · PDF'),
          ),
          if (state.exportedFiles != null) ...[
            const SizedBox(height: 10),
            const StatusBanner(
              text: 'Exportes guardados localmente y disponibles sin conexión.',
              color: AppColors.success,
              icon: Icons.offline_pin_outlined,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => OpenFilex.open(state.exportedFiles!.csvPath),
                  child: const Text('ABRIR CSV'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      OpenFilex.open(state.exportedFiles!.jsonPath),
                  child: const Text('ABRIR JSON'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      OpenFilex.open(state.exportedFiles!.htmlPath),
                  child: const Text('ABRIR HTML'),
                ),
                OutlinedButton(
                  onPressed: () => OpenFilex.open(state.exportedFiles!.pdfPath),
                  child: const Text('ABRIR PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      subject: 'DDR001 · Evidencia de verificación',
                      files: [
                        XFile(state.exportedFiles!.csvPath),
                        XFile(state.exportedFiles!.jsonPath),
                        XFile(state.exportedFiles!.htmlPath),
                        XFile(state.exportedFiles!.pdfPath),
                      ],
                    ),
                  ),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('COMPARTIR'),
                ),
              ],
            ),
          ],
          if (ref.watch(appDependenciesProvider).backendSyncConfigured) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('sync-case'),
              onPressed: state.busy || state.syncMessage == 'Sincronizado'
                  ? null
                  : controller.syncCurrentCase,
              icon: const Icon(Icons.sync),
              label: Text(
                'SYNC · ${state.syncMessage}',
                style: state.syncMessage == 'Sincronizado'
                    ? const TextStyle(color: AppColors.success)
                    : null,
              ),
            ),
          ],
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
  const _FlowSummary({
    required this.flow,
    required this.samples,
    required this.selectedSampleIds,
    required this.onSelectionChanged,
    required this.pointsBySample,
    required this.evidenceBySample,
  });
  final FlowPoint flow;
  final List<Sample> samples;
  final Set<String> selectedSampleIds;
  final void Function(String sampleId, bool selected) onSelectionChanged;
  final Map<String, List<TestPoint>> pointsBySample;
  final Map<String, List<Evidence>> evidenceBySample;
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
          for (final sample in samples) ...[
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: selectedSampleIds.contains(sample.id),
              onChanged: (value) =>
                  onSelectionChanged(sample.id, value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                '${flow.name.toUpperCase()}${samples.length == 1 ? '' : '-${sample.sampleNumber}'} · ${methodLabel(sample.configuration.measurementMethod)}',
              ),
              subtitle: Text('${sample.endedAt?.toLocal() ?? ''}'),
              secondary: Text(
                '${sample.result!.errorPct.toStringAsFixed(2)} %',
                style: TextStyle(
                  color: verdictColor(sample.result!.verdict),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _LocalSampleDetails(
              sample: sample,
              points: pointsBySample[sample.id] ?? const [],
              evidence: evidenceBySample[sample.id] ?? const [],
            ),
          ],
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

final class _LocalSampleDetails extends StatelessWidget {
  const _LocalSampleDetails({
    required this.sample,
    required this.points,
    required this.evidence,
  });

  final Sample sample;
  final List<TestPoint> points;
  final List<Evidence> evidence;

  @override
  Widget build(BuildContext context) {
    final acquisition = sample.pulseAcquisitionConfiguration;
    final firstPoint = points.isEmpty
        ? null
        : ([
            ...points,
          ]..sort((a, b) => a.capturedAt.compareTo(b.capturedAt))).first;
    final lastPoint = points.isEmpty
        ? null
        : ([
            ...points,
          ]..sort((a, b) => a.capturedAt.compareTo(b.capturedAt))).last;
    final hashedEvidence = evidence.where((item) => item.sha256 != null).length;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: const Text('INFORMACIÓN TÉCNICA LOCAL'),
      subtitle: const Text(
        'Adquisición, tiempos, evidencias y cámara',
        style: TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      children: [
        _detail(
          'Integridad',
          _integrityLabel(sample.acquisitionIntegrity.status),
        ),
        _detail(
          'Detalle de integridad',
          sample.acquisitionIntegrity.reason ?? 'Sin incidencias',
        ),
        _detail('ESP32', acquisition?.bleDeviceName ?? 'No registrado'),
        _detail('ID ESP32', acquisition?.bleDeviceId ?? 'No registrado'),
        _detail(
          'Protocolo',
          '${acquisition?.bleProtocolVersion ?? 'No registrado'}',
        ),
        _detail(
          'Origen de incidencia',
          _sourceLabel(sample.acquisitionIntegrity.source),
        ),
        _detail(
          'Momento de incidencia',
          sample.acquisitionIntegrity.occurredAt == null
              ? '—'
              : _localDateTime(sample.acquisitionIntegrity.occurredAt!),
        ),
        _detail(
          'Contador inicial ESP32',
          '${acquisition?.esp32CounterAtStart ?? '—'}',
        ),
        _detail(
          'Contador final ESP32',
          '${acquisition?.lastObservedEsp32Counter ?? '—'}',
        ),
        _detail(
          'Primer punto',
          firstPoint == null ? '—' : _localDateTime(firstPoint.capturedAt),
        ),
        _detail(
          'Último punto',
          lastPoint == null ? '—' : _localDateTime(lastPoint.capturedAt),
        ),
        _detail('Duración efectiva', _sampleDuration(sample)),
        _detail('Pulsos patrón', '${sample.pulseCount}'),
        _detail('Evidencias', '${evidence.length}'),
        _detail(
          'Evidencias con integridad SHA-256',
          '$hashedEvidence de ${evidence.length}',
        ),
        _detail(
          'Zoom congelado',
          '${sample.configuration.cameraZoomLevel.toStringAsFixed(2)}×',
        ),
        _detail(
          'Regiones de cámara',
          sample.meterFaceConfiguration == null
              ? 'No registradas'
              : 'Totalizador y dial congelados; fotografía completa conservada',
        ),
        if (sample.meterFaceConfiguration case final face?) ...[
          _detail(
            'Región totalizador',
            'x ${face.totalizerLeft.toStringAsFixed(4)}, y ${face.totalizerTop.toStringAsFixed(4)}, ancho ${face.totalizerWidth.toStringAsFixed(4)}, alto ${face.totalizerHeight.toStringAsFixed(4)}',
          ),
          _detail(
            'Región dial',
            'centro ${face.dialCenterX.toStringAsFixed(4)}, ${face.dialCenterY.toStringAsFixed(4)}; radio ${face.dialRadius.toStringAsFixed(4)}',
          ),
        ],
        if (evidence.isNotEmpty) ...[
          const Divider(),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'TRAZABILIDAD DE EVIDENCIAS',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          for (final item in ([
            ...evidence,
          ]..sort((a, b) => a.capturedAt.compareTo(b.capturedAt))))
            _detail(
              _evidenceLabel(item.type),
              '${item.volumeRefLiters?.toStringAsFixed(2) ?? '—'} L · ${_localDateTime(item.capturedAt)} · ${item.sha256 == null ? 'sin hash' : 'integridad registrada'}',
            ),
        ],
      ],
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        const SizedBox(width: 12),
        Flexible(child: Text(value, textAlign: TextAlign.right)),
      ],
    ),
  );

  String _integrityLabel(AcquisitionIntegrityStatus status) => switch (status) {
    AcquisitionIntegrityStatus.ok => 'ÍNTEGRA',
    AcquisitionIntegrityStatus.compromised => 'COMPROMETIDA',
  };

  String _evidenceLabel(EvidenceType type) => switch (type) {
    EvidenceType.start => 'INICIO',
    EvidenceType.intermediate => 'INTERMEDIA',
    EvidenceType.finalEvidence => 'FINAL',
    EvidenceType.extra => 'ADICIONAL',
  };

  String _sourceLabel(MeasurementMethod? source) => switch (source) {
    null => 'Sin incidencias',
    MeasurementMethod.ble => 'BLUETOOTH',
    MeasurementMethod.led => 'LED',
    MeasurementMethod.manual => 'MANUAL',
    MeasurementMethod.visual => 'LECTURA VISUAL',
    MeasurementMethod.simulation => 'SIMULACIÓN',
  };

  String _sampleDuration(Sample value) {
    if (value.startedAt == null || value.endedAt == null) return '—';
    final duration = value.endedAt!.difference(value.startedAt!);
    return '${duration.inMinutes.toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  String _localDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
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
