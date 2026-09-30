import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/metrology/metrology.dart';
import '../../domain/models.dart';
import '../app_controller.dart';

Future<void> showCorrectionDialog(BuildContext context, {Sample? sample}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CorrectionDialog(sample: sample),
    );

final class _CorrectionDialog extends ConsumerStatefulWidget {
  const _CorrectionDialog({this.sample});
  final Sample? sample;
  @override
  ConsumerState<_CorrectionDialog> createState() => _CorrectionDialogState();
}

final class _CorrectionDialogState extends ConsumerState<_CorrectionDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _fields = <String, TextEditingController>{};
  late final String _checksum;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(appControllerProvider);
    _checksum = state.activeCase!.checksum!;
    final sample = widget.sample;
    if (sample == null) {
      _fields['meter'] = TextEditingController(text: state.activeCase!.meterId);
      _fields['bench'] = TextEditingController(
        text: state.activeCase!.testBenchId,
      );
    } else {
      final initial = sample.initialReading?.reading;
      final end = sample.finalReading?.reading;
      final initialTotal = initial == null
          ? 0.0
          : initial.odometerUnits * initial.litersPerOdometerUnit +
                initial.needleLiters;
      for (final entry in <String, double?>{
        'referenceK': sample.configuration.litersPerPulse,
        'hydrantK': sample.configuration.hydrantLitersPerPulse,
        'uncertainty': sample.configuration.readingUncertaintyLiters,
        'odometerScale': sample.configuration.litersPerOdometerUnit,
        'needleScale': sample.configuration.needleLitersPerRevolution,
        'visualReference': sample.result?.referenceLiters,
        'initialOdometer': initial?.odometerUnits,
        'initialNeedle': initial?.needleLiters,
        'finalOdometer': end?.odometerUnits,
        'finalNeedle': end?.needleLiters,
        'initialTotal': initialTotal,
        'finalTotal': initialTotal + (sample.result?.indicatedLiters ?? 0),
      }.entries) {
        _fields[entry.key] = TextEditingController(
          text: entry.value?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Widget _field(String key, String label, {bool numeric = true}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      key: Key('correction-$key'),
      controller: _fields[key],
      enabled: !_saving,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (text) {
        if (text == null || text.trim().isEmpty) return 'Campo obligatorio';
        if (numeric) {
          final n = double.tryParse(text.replaceAll(',', '.'));
          if (n == null || !n.isFinite || n < 0) {
            return 'Introduce un número válido no negativo';
          }
        }
        return null;
      },
    ),
  );

  double _number(String key) =>
      double.parse(_fields[key]!.text.replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final sample = widget.sample;
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(
          sample == null
              ? 'Corregir identificación'
              : 'Corregir lecturas · ${sample.configuration.flowPoint.name.toUpperCase()}-${sample.sampleNumber}',
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'La corrección conserva los datos anteriores y recalcula los resultados. Quedará pendiente de sincronización.',
                  ),
                  const SizedBox(height: 16),
                  if (sample == null) ...[
                    _field('meter', 'ID / número de cuenta', numeric: false),
                    _field('bench', 'Banco de pruebas', numeric: false),
                  ] else ...[
                    const Text('Configuración de cálculo'),
                    _field('referenceK', 'Medidor patrón · litros por pulso'),
                    _field('hydrantK', 'Hidrante · litros por pulso'),
                    _field('odometerScale', 'Escala del odómetro (L/unidad)'),
                    _field('needleScale', 'Escala de aguja (L/vuelta)'),
                    _field('uncertainty', 'Incertidumbre base uL (L)'),
                    if (sample.configuration.measurementMethod ==
                        MeasurementMethod.visual)
                      _field('visualReference', 'Volumen de referencia (L)'),
                    const Text(
                      'Pulsos y fotografías originales se conservan. El paso y las condiciones de captura corresponden a la adquisición original.',
                    ),
                    const SizedBox(height: 12),
                    _field('initialOdometer', 'INICIO · totalizador'),
                    _field('initialNeedle', 'INICIO · aguja (L)'),
                    _field('finalOdometer', 'FINAL · totalizador'),
                    _field('finalNeedle', 'FINAL · aguja (L)'),
                    if (!sample
                        .configuration
                        .measurementMethod
                        .allowsUnboundedNeedleReading) ...[
                      const Text(
                        'Se conserva el avance registrado. Ajusta estos totales si también fue capturado incorrectamente.',
                      ),
                      _field('initialTotal', 'INICIO · total del medidor (L)'),
                      _field('finalTotal', 'FINAL · total del medidor (L)'),
                    ],
                  ],
                  TextFormField(
                    key: const Key('correction-reason'),
                    controller: _reason,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Motivo de la corrección',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Indica el motivo'
                        : null,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            key: const Key('save-correction'),
            onPressed: _saving
                ? null
                : () async {
                    if (!_form.currentState!.validate()) return;
                    setState(() {
                      _saving = true;
                      _error = null;
                    });
                    final saved = await ref
                        .read(appControllerProvider.notifier)
                        .correctHistoricalCase(
                          expectedChecksum: _checksum,
                          reason: _reason.text,
                          sampleId: sample?.id,
                          initialOdometer: sample == null
                              ? null
                              : _number('initialOdometer'),
                          initialNeedle: sample == null
                              ? null
                              : _number('initialNeedle'),
                          finalOdometer: sample == null
                              ? null
                              : _number('finalOdometer'),
                          finalNeedle: sample == null
                              ? null
                              : _number('finalNeedle'),
                          initialTotalLiters: sample == null
                              ? null
                              : _number('initialTotal'),
                          finalTotalLiters: sample == null
                              ? null
                              : _number('finalTotal'),
                          litersPerPulse: sample == null
                              ? null
                              : _number('referenceK'),
                          hydrantLitersPerPulse: sample == null
                              ? null
                              : _number('hydrantK'),
                          readingUncertaintyLiters: sample == null
                              ? null
                              : _number('uncertainty'),
                          litersPerOdometerUnit: sample == null
                              ? null
                              : _number('odometerScale'),
                          needleLitersPerRevolution: sample == null
                              ? null
                              : _number('needleScale'),
                          visualReferenceLiters:
                              sample?.configuration.measurementMethod ==
                                  MeasurementMethod.visual
                              ? _number('visualReference')
                              : null,
                          meterId: _fields['meter']?.text,
                          testBenchId: _fields['bench']?.text,
                        );
                    if (!context.mounted) return;
                    if (saved) {
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        _saving = false;
                        _error =
                            ref.read(appControllerProvider).errorMessage ??
                            'No se pudo guardar.';
                      });
                    }
                  },
            child: Text(_saving ? 'GUARDANDO…' : 'GUARDAR Y RECALCULAR'),
          ),
        ],
      ),
    );
  }
}

Future<void> showCorrectionHistory(
  BuildContext context,
  WidgetRef ref,
  String caseId,
) async {
  final history = await ref
      .read(appDependenciesProvider)
      .corrections
      .history(caseId);
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Historial de correcciones'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (history.isEmpty) const Text('Sin correcciones registradas.'),
              for (final entry in history)
                ExpansionTile(
                  title: Text(
                    '${DateTime.fromMillisecondsSinceEpoch(entry['corrected_at_ms'] as int).toLocal()}',
                  ),
                  subtitle: Text(entry['reason'] as String),
                  children: [
                    SelectableText(
                      'ANTES\n${_correctionSummary(entry['before_json'] as String)}\n\nDESPUÉS\n${_correctionSummary(entry['after_json'] as String)}',
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CERRAR'),
        ),
      ],
    ),
  );
}

String _correctionSummary(String json) {
  final data = jsonDecode(json) as Map;
  final verification = (data['case'] as List).single as Map;
  final out = StringBuffer(
    'Cuenta: ${verification['meter_id']}\nBanco: ${verification['test_bench_id']}\nRevisión: ${verification['report_version']}\n',
  );
  for (final row in data['samples'] as List) {
    out.writeln(
      '\n${(row['flow_point_code'] as String).toUpperCase()} · muestra ${row['sample_number']}',
    );
    out.writeln(
      'INICIO: totalizador ${row['initial_odometer_units']} · aguja ${row['initial_needle_liters']} L',
    );
    out.writeln(
      'FINAL: totalizador ${row['final_odometer_units']} · aguja ${row['final_needle_liters']} L',
    );
    out.writeln(
      'Vref: ${row['reference_liters']} L · Vind: ${row['indicated_liters']} L',
    );
    out.writeln(
      'Error: ${row['error_pct']} % · U: ${row['uncertainty_pct']} % · MPE: ${row['result_mpe_pct']} %',
    );
  }
  return out.toString();
}
