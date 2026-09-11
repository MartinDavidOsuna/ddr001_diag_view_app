import 'dart:io';
import 'dart:typed_data';

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
  final _initialTotalizer = TextEditingController();
  final _initialNeedle = TextEditingController();
  final _initialMeterTotal = TextEditingController();
  final _finalTotalizer = TextEditingController();
  final _finalNeedle = TextEditingController();
  final _finalMeterTotal = TextEditingController();
  final _visualReference = TextEditingController(text: '125');
  bool _completeEvidence = true;

  @override
  void dispose() {
    _initialTotalizer.dispose();
    _initialNeedle.dispose();
    _initialMeterTotal.dispose();
    _finalTotalizer.dispose();
    _finalNeedle.dispose();
    _finalMeterTotal.dispose();
    _visualReference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final sample = state.sample!;
    final initialProposal = state.initialReadingProposal;
    final finalProposal = state.readingProposal;
    final visual =
        sample.configuration.measurementMethod == MeasurementMethod.visual;
    final unrestrictedNeedle =
        sample.configuration.measurementMethod.allowsUnboundedNeedleReading;
    final productionCamera = ref.read(appDependenciesProvider).camera != null;
    if (_initialTotalizer.text.isEmpty && sample.initialReading != null) {
      _initialTotalizer.text = sample.initialReading!.reading.odometerUnits
          .toString();
      _initialNeedle.text = sample.initialReading!.reading.needleLiters
          .toString();
    }
    if (_finalTotalizer.text.isEmpty && sample.finalReading != null) {
      _finalTotalizer.text = sample.finalReading!.reading.odometerUnits
          .toString();
      _finalNeedle.text = sample.finalReading!.reading.needleLiters.toString();
    }
    if (sample.referenceLitersProgress != null) {
      _visualReference.text = sample.referenceLitersProgress!.toStringAsFixed(
        1,
      );
    }
    return AppScaffold(
      title: 'Capturar lecturas',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusBanner(
              text:
                  'Capture manualmente INICIO y FINAL usando los recortes de ambas evidencias. La app no interpreta las imágenes.',
              color: AppColors.heading,
              icon: Icons.edit_outlined,
            ),
            const SizedBox(height: 14),
            _endpointCard(
              title: 'LECTURA INICIO',
              totalizerCrop: initialProposal?.totalizerCrop,
              dialCrop: initialProposal?.dialCrop,
              fullImagePath: initialProposal?.evidencePath,
              totalizer: _initialTotalizer,
              needle: _initialNeedle,
              meterTotal: _initialMeterTotal,
              keyPrefix: 'initial',
              unrestrictedNeedle: unrestrictedNeedle,
              simulation: sample.isSimulation,
            ),
            const SizedBox(height: 14),
            _endpointCard(
              title: 'LECTURA FINAL',
              totalizerCrop: finalProposal?.totalizerCrop,
              dialCrop: finalProposal?.dialCrop,
              fullImagePath: finalProposal?.evidencePath,
              totalizer: _finalTotalizer,
              needle: _finalNeedle,
              meterTotal: _finalMeterTotal,
              keyPrefix: 'final',
              unrestrictedNeedle: unrestrictedNeedle,
              simulation: sample.isSimulation,
            ),
            if (visual) ...[
              const SizedBox(height: 14),
              SectionCard(
                title: 'VOLUMEN DE REFERENCIA',
                child: _number(
                  _visualReference,
                  'Vref visual confirmado (L)',
                  const Key('reading-vref'),
                ),
              ),
            ],
            if (!productionCamera) ...[
              const SizedBox(height: 14),
              SectionCard(
                title: 'ADAPTADOR DE TEST',
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Generar evidencias locales válidas'),
                  value: _completeEvidence,
                  onChanged: (value) =>
                      setState(() => _completeEvidence = value),
                ),
              ),
            ],
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
                            initialTotalizer: double.parse(
                              _initialTotalizer.text,
                            ),
                            initialNeedle: double.parse(_initialNeedle.text),
                            initialMeterTotalLiters: double.parse(
                              _initialMeterTotal.text,
                            ),
                            finalTotalizer: double.parse(_finalTotalizer.text),
                            finalNeedle: double.parse(_finalNeedle.text),
                            finalMeterTotalLiters: double.parse(
                              _finalMeterTotal.text,
                            ),
                            visualReferenceLiters: visual
                                ? double.parse(_visualReference.text)
                                : null,
                            createDevelopmentEvidence:
                                !productionCamera && _completeEvidence,
                          );
                    },
              child: Text(
                state.busy ? 'FINALIZANDO…' : 'GUARDAR Y CALCULAR RESULTADO',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _endpointCard({
    required String title,
    required List<int>? totalizerCrop,
    required List<int>? dialCrop,
    required String? fullImagePath,
    required TextEditingController totalizer,
    required TextEditingController needle,
    required TextEditingController meterTotal,
    required String keyPrefix,
    required bool unrestrictedNeedle,
    required bool simulation,
  }) => SectionCard(
    title: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (totalizerCrop != null)
          _crop(totalizerCrop, 'Totalizador $title', fullImagePath)
        else if (simulation)
          const Text(
            'Evidence simulada registrada. Capture manualmente los valores observados para calcular el resultado.',
            style: TextStyle(color: AppColors.warning),
          )
        else
          Text(
            'No fue posible presentar el totalizador $title.',
            style: const TextStyle(color: AppColors.warning),
          ),
        const SizedBox(height: 10),
        _number(
          totalizer,
          'Valor del totalizador (m³)',
          Key('$keyPrefix-totalizer'),
        ),
        const SizedBox(height: 14),
        if (dialCrop != null)
          _crop(dialCrop, 'Dial $title', fullImagePath)
        else
          Text(
            'No fue posible presentar el dial $title.',
            style: const TextStyle(color: AppColors.warning),
          ),
        const SizedBox(height: 10),
        _number(
          needle,
          unrestrictedNeedle
              ? 'Lectura de aguja (L)'
              : 'Posición de aguja dentro de la vuelta (L)',
          Key('$keyPrefix-needle'),
        ),
        const SizedBox(height: 10),
        _number(
          meterTotal,
          'Total del medidor (L)',
          Key('$keyPrefix-meter-total-liters'),
        ),
      ],
    ),
  );

  Widget _crop(List<int> bytes, String semanticLabel, String? fullImagePath) =>
      Semantics(
        label: '$semanticLabel. Toque para ver la carátula completa.',
        button: fullImagePath != null,
        child: Material(
          color: Colors.black,
          borderRadius: BorderRadius.circular(AppRadius.card),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: fullImagePath == null
                ? null
                : () => _showFullMeterFace(fullImagePath, semanticLabel),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Image.memory(Uint8List.fromList(bytes), fit: BoxFit.contain),
                if (fullImagePath != null)
                  const Padding(
                    padding: EdgeInsets.all(6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xAA000000),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.zoom_in,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  Future<void> _showFullMeterFace(
    String imagePath,
    String semanticLabel,
  ) async {
    Offset? swipeStart;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xDD000000),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: MediaQuery.sizeOf(dialogContext).width - 32,
          height: MediaQuery.sizeOf(dialogContext).height * .82,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) => swipeStart ??= event.position,
            onPointerUp: (event) {
              final start = swipeStart;
              swipeStart = null;
              if (start == null) return;
              final delta = event.position - start;
              if (delta.dx < -100 && delta.dx.abs() > delta.dy.abs()) {
                Navigator.of(dialogContext).pop();
              }
            },
            onPointerCancel: (_) => swipeStart = null,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: ColoredBox(
                      color: Colors.black,
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 6,
                        boundaryMargin: const EdgeInsets.all(80),
                        child: Center(
                          child: Image.file(
                            File(imagePath),
                            fit: BoxFit.contain,
                            semanticLabel: semanticLabel,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
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
