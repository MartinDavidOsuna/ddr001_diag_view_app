import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/metrology/metrology.dart';
import '../app_controller.dart';
import '../common/app_scaffold.dart';

final class ReadingsScreen extends ConsumerStatefulWidget {
  const ReadingsScreen({super.key});
  @override
  ConsumerState<ReadingsScreen> createState() => _ReadingsScreenState();
}

final class _ReadingsScreenState extends ConsumerState<ReadingsScreen> {
  final _form = GlobalKey<FormState>();
  final _initialOdo = TextEditingController();
  final _initialNeedle = TextEditingController();
  final _finalOdo = TextEditingController();
  final _finalNeedle = TextEditingController();
  final _visualReference = TextEditingController(text: '125');
  bool _completeEvidence = true;

  @override
  void dispose() {
    _initialOdo.dispose();
    _initialNeedle.dispose();
    _finalOdo.dispose();
    _finalNeedle.dispose();
    _visualReference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final sample = state.sample!;
    final visual =
        sample.configuration.measurementMethod == MeasurementMethod.visual;
    final productionCamera = ref.read(appDependenciesProvider).camera != null;
    if (_initialOdo.text.isEmpty && sample.initialReading != null) {
      _initialOdo.text = sample.initialReading!.reading.odometerUnits
          .toString();
      _initialNeedle.text = sample.initialReading!.reading.needleLiters
          .toString();
    }
    if (_finalOdo.text.isEmpty && sample.finalReading != null) {
      _finalOdo.text = sample.finalReading!.reading.odometerUnits.toString();
      _finalNeedle.text = sample.finalReading!.reading.needleLiters.toString();
    }
    if (sample.referenceLitersProgress != null) {
      _visualReference.text = sample.referenceLitersProgress!.toStringAsFixed(
        1,
      );
    }
    return AppScaffold(
      title: 'Confirmar lecturas',
      child: Form(
        key: _form,
        child: Column(
          children: [
            SectionCard(
              title: '6 · Lectura inicial',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StatusBanner(
                    text: productionCamera
                        ? 'Lectura vinculada a evidencia START real. Revise los valores antes del cierre.'
                        : 'Adaptador de prueba sin cámara física.',
                    color: AppColors.heading,
                    icon: Icons.verified_outlined,
                  ),
                  const SizedBox(height: 12),
                  _number(
                    _initialOdo,
                    'Odómetro inicial (unidades de 1000 L)',
                    const Key('initial-odo'),
                  ),
                  const SizedBox(height: 10),
                  _number(
                    _initialNeedle,
                    'Aguja inicial (0–99.999 L)',
                    const Key('initial-needle'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lectura detectada: valor ingresado · ¿Es correcta?',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              title: 'Lectura final',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _number(
                    _finalOdo,
                    'Odómetro final (unidades de 1000 L)',
                    const Key('final-odo'),
                  ),
                  const SizedBox(height: 10),
                  _number(
                    _finalNeedle,
                    'Aguja final (0–99.999 L)',
                    const Key('final-needle'),
                  ),
                  if (visual) ...[
                    const SizedBox(height: 10),
                    _number(
                      _visualReference,
                      'Vref visual confirmado (L)',
                      const Key('reading-vref'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (!productionCamera)
              SectionCard(
                title: 'ADAPTADOR DE TEST',
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Generar evidencias locales válidas'),
                  subtitle: const Text(
                    'Desactiva para probar INVALID_EVIDENCE.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  value: _completeEvidence,
                  onChanged: (value) =>
                      setState(() => _completeEvidence = value),
                ),
              ),
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('confirm-readings'),
              onPressed: state.busy
                  ? null
                  : () async {
                      if (!_form.currentState!.validate()) return;
                      await ref
                          .read(appControllerProvider.notifier)
                          .closeSample(
                            initialOdometer: double.parse(_initialOdo.text),
                            initialNeedle: double.parse(_initialNeedle.text),
                            finalOdometer: double.parse(_finalOdo.text),
                            finalNeedle: double.parse(_finalNeedle.text),
                            visualReferenceLiters: visual
                                ? double.parse(_visualReference.text)
                                : null,
                            createDevelopmentEvidence:
                                !productionCamera && _completeEvidence,
                          );
                    },
              child: Text(
                state.busy ? 'FINALIZANDO…' : 'CORRECTA · CALCULAR RESULTADO',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _number(TextEditingController controller, String label, Key key) =>
      TextFormField(
        key: key,
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final parsed = double.tryParse(value ?? '');
          return parsed != null && parsed >= 0 ? null : 'Valor inválido.';
        },
      );
}
