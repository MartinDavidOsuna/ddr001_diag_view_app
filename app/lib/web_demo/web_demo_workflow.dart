part of 'web_demo_app.dart';

final class _Run extends StatefulWidget {
  const _Run(this.controller);
  final WebDemoController controller;
  @override
  State<_Run> createState() => _RunState();
}

final class _RunState extends State<_Run> {
  final evidenceKey = GlobalKey();
  int lastEvidenceCount = 0;
  WebDemoController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final count = controller.photos.length;
    if (count >= 4 && count != lastEvidenceCount) {
      lastEvidenceCount = count;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final evidenceContext = evidenceKey.currentContext;
        if (!mounted || evidenceContext == null) return;
        Scrollable.ensureVisible(
          evidenceContext,
          alignment: 1,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      });
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: _PinnedRun(controller),
        ),
        Expanded(
          child: _Page(
            children: [
              const StatusBanner(
                text: _simulationNotice,
                color: AppColors.warning,
                icon: Icons.science_outlined,
              ),
              const SizedBox(height: 14),
              KeyedSubtree(
                key: evidenceKey,
                child: _EvidenceView(
                  photos: controller.photos,
                  pending: true,
                  reference: controller.referenceLiters,
                ),
              ),
              const SizedBox(height: 14),
              _Registry(
                photos: controller.photos,
                settings: controller.runSettings,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: controller.pauseToHome,
                child: const Text('SALIR SIN DESCARTAR'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _PinnedRun extends StatelessWidget {
  const _PinnedRun(this.controller);
  final WebDemoController controller;
  @override
  Widget build(BuildContext context) => Material(
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
            'Medidor ${controller.meterId}',
            key: const Key('running-meter-id'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${controller.flowPoint.name.toUpperCase()} · Caudal calculado · K ${controller.runSettings.value('k')} L/pulso',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Text(
            controller.measurementStarted
                ? 'Inicio: ${_date(controller.startedAt!)}'
                : 'Flujo previo activo · la medición aún no inicia',
            style: const TextStyle(
              color: AppColors.heading,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(child: _Metric('Pulsos', '${controller.pulseCount}')),
              Expanded(
                child: _Metric(
                  'Caudal calc.',
                  '${controller.flowLps.toStringAsFixed(2)} L/s',
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _Metric(
                  'V patrón',
                  '${controller.referenceLiters.toStringAsFixed(2)} L',
                ),
              ),
            ],
          ),
          const Divider(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  'Medidor del hidrante',
                  '${controller.pulseCount} pulsos',
                ),
              ),
              Expanded(
                child: _Metric(
                  'Caudal hidrante',
                  controller.pulseCount == 0
                      ? 'Sin pulsos'
                      : '${controller.hydrantFlowLps.toStringAsFixed(2)} L/s',
                ),
              ),
              Expanded(
                child: _Metric(
                  'V hidrante',
                  '${controller.hydrantLiters.toStringAsFixed(2)} L',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tiempo: ${_duration(controller.elapsed)}',
            textAlign: TextAlign.right,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          if (!controller.measurementStarted)
            FilledButton(
              key: const Key('begin-measurement'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: controller.startMeasurement,
              child: const Text('INICIAR PRUEBA'),
            )
          else
            FilledButton(
              key: const Key('finish-run'),
              onPressed: controller.pulseCount == 0
                  ? null
                  : controller.finishMeasurement,
              child: const Text(
                'FINALIZAR Y CONFIRMAR LECTURAS',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    ),
  );
}

final class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.muted, fontSize: 11),
      ),
      Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: color,
        ),
      ),
    ],
  );
}

final class _EvidenceView extends StatelessWidget {
  const _EvidenceView({
    required this.photos,
    this.pending = false,
    this.reference = 0,
  });
  final List<DemoEvidence> photos;
  final bool pending;
  final double reference;
  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'CAPTURA DE EVIDENCIAS',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (photos.isEmpty)
          const Text(
            'INICIO se captura al momento de iniciar la prueba, las intermedias y FINAL se derivarán al conocer el volumen final.',
            style: TextStyle(color: AppColors.muted),
          ),
        for (final photo in photos)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: InkWell(
              onTap: () => _showPhoto(
                context,
                photo.asset,
                '${photo.label} · ${photo.volume.toStringAsFixed(1)} L · ${_time(photo.at)}',
              ),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Image.asset(
                    photo.asset,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    semanticLabel: 'Fotografía ${photo.label}',
                  ),
                  const Icon(
                    Icons.check_circle,
                    size: 17,
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
            title: Text(
              '${photo.label} · ${photo.volume.toStringAsFixed(0)} L',
            ),
            subtitle: Text(_time(photo.at)),
            trailing: const Text(
              'Capturada',
              style: TextStyle(color: AppColors.success),
            ),
            onTap: () => _showPhoto(
              context,
              photo.asset,
              '${photo.label} · ${photo.volume.toStringAsFixed(1)} L · ${_time(photo.at)}',
            ),
          ),
        if (pending && photos.isNotEmpty)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.pending_outlined,
              color: AppColors.warning,
            ),
            title: Text('FINAL · ${reference.toStringAsFixed(0)} L'),
            trailing: const Text(
              'Pendiente',
              style: TextStyle(color: AppColors.warning),
            ),
          ),
        if (photos.isNotEmpty)
          const Text(
            'EVIDENCIA DE SIMULACIÓN · toque una fotografía para ampliarla.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
      ],
    ),
  );
}

final class _Registry extends StatelessWidget {
  const _Registry({required this.photos, required this.settings});
  final List<DemoEvidence> photos;
  final DemoSettings settings;
  @override
  Widget build(BuildContext context) {
    final statistics = demoPhotoStatistics(photos);
    Widget cell(String value, {bool header = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      child: Text(
        value,
        style: TextStyle(
          fontSize: header ? 10 : 11,
          fontWeight: header ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
    );
    return SectionCard(
      title: 'Registro',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (photos.isNotEmpty)
            Text(
              _date(photos.first.at).split(' ').first,
              style: const TextStyle(color: AppColors.muted),
            ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.15),
              1: FlexColumnWidth(1.25),
              2: FlexColumnWidth(1.15),
              3: FlexColumnWidth(.85),
              4: FlexColumnWidth(.85),
            },
            border: TableBorder.all(color: AppColors.line),
            children: [
              TableRow(
                children: [
                  for (final label in [
                    'PUNTO',
                    'PULSOS / PATRÓN',
                    'LECTURA L / V.MEC',
                    'ERROR %',
                    'L/s',
                  ])
                    cell(label, header: true),
                ],
              ),
              for (final photo in photos)
                TableRow(
                  children: [
                    cell('${photo.label}\n${_time(photo.at)}'),
                    cell(
                      '${photo.pulses} / ${photo.volume.toStringAsFixed(1)} L',
                    ),
                    cell(
                      photo.pulses == 0
                          ? ''
                          : '${photo.hydrantLiters(settings).toStringAsFixed(2)} / ${photo.pulses}',
                    ),
                    cell(
                      photo.diagnosticErrorPct(settings)?.toStringAsFixed(2) ??
                          '',
                    ),
                    cell(photo.flowLps.toStringAsFixed(2)),
                  ],
                ),
            ],
          ),
          if (statistics != null) ...[
            const SizedBox(height: 8),
            Text(
              'Caudal puntual · mín. ${statistics.minimumLps.toStringAsFixed(2)} · máx. ${statistics.maximumLps.toStringAsFixed(2)} · promedio ${statistics.averageLps.toStringAsFixed(2)} L/s',
              style: const TextStyle(color: AppColors.heading, fontSize: 12),
            ),
          ],
          const SizedBox(height: 6),
          const Text(
            'Los errores de puntos son diagnósticos; el resultado oficial usa el endpoint.',
            style: TextStyle(color: AppColors.warning, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

final class _Readings extends StatefulWidget {
  const _Readings(this.controller);
  final WebDemoController controller;
  @override
  State<_Readings> createState() => _ReadingsState();
}

final class _ReadingsState extends State<_Readings> {
  final form = GlobalKey<FormState>();
  final initialTotalizer = TextEditingController();
  final initialNeedle = TextEditingController();
  final finalTotalizer = TextEditingController();
  final finalNeedle = TextEditingController();
  String? error;
  bool busy = false;
  @override
  void dispose() {
    initialTotalizer.dispose();
    initialNeedle.dispose();
    finalTotalizer.dispose();
    finalNeedle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Page(
    children: [
      Form(
        key: form,
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
            endpoint(
              'LECTURA INICIO',
              'initial',
              initialTotalizer,
              initialNeedle,
              widget.controller.photos.first,
            ),
            const SizedBox(height: 14),
            endpoint(
              'LECTURA FINAL',
              'final',
              finalTotalizer,
              finalNeedle,
              widget.controller.photos.last,
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  error!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('confirm-readings'),
              onPressed: busy
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      setState(() => busy = true);
                      try {
                        await widget.controller.calculate(
                          initialTotalizer: double.parse(initialTotalizer.text),
                          initialNeedle: double.parse(initialNeedle.text),
                          finalTotalizer: double.parse(finalTotalizer.text),
                          finalNeedle: double.parse(finalNeedle.text),
                        );
                      } catch (failure) {
                        if (mounted) setState(() => error = '$failure');
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
              child: Text(
                busy ? 'FINALIZANDO…' : 'GUARDAR Y CALCULAR RESULTADO',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget endpoint(
    String title,
    String prefix,
    TextEditingController totalizer,
    TextEditingController needle,
    DemoEvidence photo,
  ) => SectionCard(
    title: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DemoCrop(
          label: 'Totalizador $title',
          asset: photo.asset,
          alignment: const Alignment(0, -.25),
          scale: 2.9,
        ),
        const SizedBox(height: 10),
        number(totalizer, 'Valor del totalizador (m³)', '$prefix-totalizer'),
        const SizedBox(height: 14),
        _DemoCrop(
          label: 'Aguja $title',
          asset: photo.asset,
          alignment: const Alignment(0, .42),
          scale: 3.2,
        ),
        const SizedBox(height: 10),
        number(needle, 'Lectura de aguja (L)', '$prefix-needle'),
        const SizedBox(height: 8),
        const Text(
          'El avance se calcula en litros con totalizador + aguja; no capture un total duplicado.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    ),
  );

  Widget number(TextEditingController controller, String label, String key) =>
      TextFormField(
        key: Key(key),
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        validator: (text) {
          final value = double.tryParse(text ?? '');
          return value != null && value.isFinite && value >= 0
              ? null
              : 'Valor inválido.';
        },
      );
}

final class _DemoCrop extends StatelessWidget {
  const _DemoCrop({
    required this.label,
    required this.asset,
    required this.alignment,
    required this.scale,
  });
  final String label;
  final String asset;
  final Alignment alignment;
  final double scale;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label. Toque para ver la carátula completa.',
    button: true,
    child: Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showPhoto(context, asset, label),
        child: SizedBox(
          height: 180,
          child: ClipRect(
            child: Transform.scale(
              scale: scale,
              alignment: alignment,
              child: Image.asset(asset, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _showPhoto(
  BuildContext context,
  String asset,
  String label,
) async {
  Offset? swipeStart;
  await showDialog<void>(
    context: context,
    barrierColor: const Color(0xDD000000),
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 640,
        height: MediaQuery.sizeOf(dialogContext).height * .82,
        child: Listener(
          onPointerDown: (event) => swipeStart = event.position,
          onPointerUp: (event) {
            final start = swipeStart;
            swipeStart = null;
            if (start != null &&
                event.position.dx - start.dx < -100 &&
                (event.position.dx - start.dx).abs() >
                    (event.position.dy - start.dy).abs()) {
              Navigator.pop(dialogContext);
            }
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 6,
                  child: Center(
                    child: Image.asset(
                      asset,
                      fit: BoxFit.contain,
                      semanticLabel: label,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 50,
                top: 10,
                child: Text(
                  '$label\nEVIDENCIA DE SIMULACIÓN',
                  style: const TextStyle(color: AppColors.warning),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(dialogContext),
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
