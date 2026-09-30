part of 'web_demo_app.dart';

final class _Result extends StatelessWidget {
  const _Result(this.controller);
  final WebDemoController controller;
  @override
  Widget build(BuildContext context) {
    final sample = controller.latestSample!;
    return _Page(
      children: [
        const StatusBanner(
          text: _simulationNotice,
          color: AppColors.warning,
          icon: Icons.science_outlined,
        ),
        const SizedBox(height: 14),
        StatusBanner(
          text:
              '${_verdict(sample.verdict)} · ${sample.errorPct.toStringAsFixed(2)} % ±${sample.uncertaintyPct.toStringAsFixed(2)} %',
          color: _verdictColor(sample.verdict),
          icon: sample.verdict == SampleVerdict.pass
              ? Icons.check_circle
              : sample.verdict == SampleVerdict.fail
              ? Icons.cancel
              : Icons.help,
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Resultado ${sample.flowPoint.name.toUpperCase()}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Value('Vref', '${sample.referenceLiters.toStringAsFixed(2)} L'),
              _Value('Vind', '${sample.indicatedLiters.toStringAsFixed(2)} L'),
              _Value(
                'Lectura inicial',
                '${sample.initialReadingLiters.toStringAsFixed(3)} L',
              ),
              _Value(
                'Lectura FINAL capturada',
                '${sample.finalReadingLiters.toStringAsFixed(3)} L',
              ),
              _Value(
                'Avance',
                '${sample.indicatedLiters.toStringAsFixed(3)} L',
              ),
              _Value('Error', '${sample.errorPct.toStringAsFixed(6)} %'),
              _Value('U', '${sample.uncertaintyPct.toStringAsFixed(6)} %'),
              _Value('MPE', '±${sample.mpePct.toStringAsFixed(2)} %'),
              const _Value('Regla de decisión', '|E| + U ≤ MPE'),
              _Value(
                'Duración',
                _duration(sample.endedAt.difference(sample.startedAt)),
              ),
              _Value(
                '|E| + U',
                '${sample.result.decisionMetrics.acceptanceMetricPct.toStringAsFixed(6)} %',
              ),
              _Value(
                '|E| − U',
                '${sample.result.decisionMetrics.rejectionMetricPct.toStringAsFixed(6)} %',
              ),
              const SizedBox(height: 8),
              const Text(
                'Decisión calculada con valores completos; el redondeo mostrado no interviene.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        if (sample.verdict == SampleVerdict.inconclusive) ...[
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
          child: Text('REPETIR PRUEBA ${sample.flowPoint.name.toUpperCase()}'),
        ),
        const SizedBox(height: 8),
        if (sample.flowPoint == FlowPoint.q1)
          OutlinedButton(
            key: const Key('start-q2'),
            onPressed: controller.startQ2,
            child: const Text('COMENZAR Q2'),
          )
        else
          OutlinedButton(
            key: const Key('case-summary'),
            onPressed: controller.showSummary,
            child: const Text(
              'TERMINAR / RESUMEN DEL EXPEDIENTE',
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

final class _Summary extends StatefulWidget {
  const _Summary(this.controller);
  final WebDemoController controller;
  @override
  State<_Summary> createState() => _SummaryState();
}

final class _SummaryState extends State<_Summary> {
  Map<String, Uint8List>? files;
  bool busy = false;
  String progress = 'GENERANDO…';
  String? error;
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final item = controller.selectedCase!;
    return _Page(
      children: [
        const StatusBanner(
          text: _simulationNotice,
          color: AppColors.warning,
          icon: Icons.science_outlined,
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Expediente',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Medidor ${item.meterId}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Usuario Operador de simulación',
                style: TextStyle(color: AppColors.muted),
              ),
              Text(
                'Estado: ${controller.caseClosed ? 'FINALIZADO' : 'ABIERTO'}',
              ),
              Text('Resultado global: ${_verdict(item.verdict)}'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final flow in item.flows) ...[
          SectionCard(
            title:
                '${flow.flowPoint.name.toUpperCase()} · ${_flowStatus(flow.status)}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < item.samples.length; index++)
                  if (item.samples[index].flowPoint == flow.flowPoint) ...[
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: controller.selectedSamples.contains(index),
                      onChanged: busy
                          ? null
                          : (value) {
                              controller.toggleSample(index, value ?? false);
                              setState(() => files = null);
                            },
                      title: Text(
                        '${flow.flowPoint.name.toUpperCase()} · SIMULACIÓN · ${item.sampleNumber(index)}',
                      ),
                      subtitle: Text(_date(item.samples[index].endedAt)),
                      secondary: Text(
                        '${item.samples[index].errorPct.toStringAsFixed(2)} %',
                        style: TextStyle(
                          color: _verdictColor(item.samples[index].verdict),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _SampleDetails(item.samples[index]),
                  ],
                if (flow.statistics != null) ...[
                  const Divider(),
                  Text(
                    'n: ${flow.statistics!.n} · media: ${flow.statistics!.meanErrorPct.toStringAsFixed(3)} %',
                  ),
                  Text(
                    'mín: ${flow.statistics!.minimumErrorPct.toStringAsFixed(3)} · máx: ${flow.statistics!.maximumErrorPct.toStringAsFixed(3)} %',
                  ),
                  Text(
                    'dispersión: ${flow.statistics!.dispersionPct.toStringAsFixed(3)} %',
                  ),
                  Text(
                    'desviación estándar: ${flow.statistics!.sampleStandardDeviationPct?.toStringAsFixed(3) ?? '—'} %',
                  ),
                  Text(
                    'Repetibilidad: ${switch (flow.statistics!.repeatabilityStatus) {
                      RepeatabilityStatus.notEvaluable => 'No evaluable',
                      RepeatabilityStatus.pass => 'Cumple',
                      RepeatabilityStatus.fail => 'No cumple',
                    }}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ] else
                  const Text('Sin muestras válidas cerradas.'),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (!controller.caseClosed)
          FilledButton(
            key: const Key('close-case'),
            onPressed: busy
                ? null
                : () async {
                    if (await _confirm(
                      context,
                      'Terminar expediente',
                      'El expediente cerrado será de solo lectura y no aceptará nuevas muestras.',
                      'TERMINAR',
                    )) {
                      try {
                        await controller.finishCase();
                        if (mounted) setState(() => files = null);
                      } catch (failure) {
                        if (mounted) setState(() => error = '$failure');
                      }
                    }
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
          onPressed: busy || controller.selectedSamples.isEmpty
              ? null
              : () async {
                  setState(() {
                    busy = true;
                    error = null;
                    files = null;
                    progress = 'GENERANDO…';
                  });
                  try {
                    final result = await DemoExport.generate(
                      item,
                      Set.of(controller.selectedSamples),
                      closed: controller.caseClosed,
                      onProgress: (stage) {
                        if (mounted) setState(() => progress = stage);
                      },
                    );
                    if (mounted) setState(() => files = result);
                  } catch (failure) {
                    if (mounted) {
                      setState(
                        () => error =
                            'No se pudieron generar los reportes: $failure',
                      );
                    }
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          icon: const Icon(Icons.description_outlined),
          label: Text(
            busy ? progress : 'GENERAR CSV · JSON · HTML · PDF',
            textAlign: TextAlign.center,
          ),
        ),
        if (error != null)
          Text(error!, style: const TextStyle(color: AppColors.danger)),
        if (files != null) ...[
          const SizedBox(height: 10),
          const StatusBanner(
            text:
                'Exportes disponibles sin conexión. Abra cada archivo para descargarlo.',
            color: AppColors.success,
            icon: Icons.offline_pin_outlined,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in files!.entries)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),
                  onPressed: () => _download(entry.value, entry.key, item.id),
                  child: Text('ABRIR ${entry.key.toUpperCase()}'),
                ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                onPressed: () async {
                  final navigator = web.window.navigator;
                  final shared = [
                    for (final entry in files!.entries)
                      web.File(
                        [entry.value.toJS].toJS,
                        '${item.id}.${entry.key}',
                        web.FilePropertyBag(type: _mime(entry.key)),
                      ),
                  ].toJS;
                  final data = web.ShareData(
                    title: 'DDR001 · Evidencia de verificación',
                    files: shared,
                  );
                  try {
                    if (navigator.canShare(data)) {
                      await navigator.share(data).toDart;
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Este navegador no permite compartir archivos. Descargue los exportes con ABRIR.',
                          ),
                        ),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No se compartieron archivos. Puede descargarlos individualmente.',
                          ),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.share_outlined),
                label: const Text('COMPARTIR'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => controller.navigate(WebDemoPage.report),
            child: const Text('VER REPORTE DE EVIDENCIA'),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => controller.navigate(WebDemoPage.home),
          child: const Text('VOLVER AL INICIO'),
        ),
      ],
    );
  }
}

final class _SampleDetails extends StatelessWidget {
  const _SampleDetails(this.sample);
  final DemoSample sample;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 12),
    title: const Text('INFORMACIÓN TÉCNICA LOCAL'),
    subtitle: const Text(
      'Adquisición, tiempos, evidencias y cámara',
      style: TextStyle(color: AppColors.muted, fontSize: 12),
    ),
    children: [
      _Value(
        'Integridad',
        sample.photos.isEmpty
            ? 'Historial anterior sin fotografías'
            : 'ÍNTEGRA · SIMULACIÓN',
      ),
      const _Value('Detalle de integridad', 'Sin incidencias'),
      const _Value('ESP32', 'No registrado'),
      const _Value('ID ESP32', 'No registrado'),
      const _Value('Protocolo', 'No registrado'),
      const _Value('Origen de incidencia', 'Sin incidencias'),
      const _Value('Momento de incidencia', '—'),
      const _Value('Contador inicial ESP32', '—'),
      const _Value('Contador final ESP32', '—'),
      _Value('Primer punto', _date(sample.startedAt)),
      _Value('Último punto', _date(sample.endedAt)),
      _Value(
        'Duración efectiva',
        _duration(sample.endedAt.difference(sample.startedAt)),
      ),
      _Value('Pulsos patrón', '${sample.pulseCount}'),
      _Value('Evidencias', '${sample.photos.length}'),
      _Value(
        'Evidencias con integridad SHA-256',
        '${sample.photos.where((photo) => photo.hash.isNotEmpty).length} de ${sample.photos.length}',
      ),
      const _Value('Zoom congelado', '1.00×'),
      const _Value('Regiones de cámara', 'Recortes ilustrativos de simulación'),
      for (final entry in sample.configuration.values.entries)
        _Value(_settingLabels[entry.key] ?? 'Decimales', '${entry.value}'),
      const Divider(),
      const Text(
        'TRAZABILIDAD DE EVIDENCIAS',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      for (final photo in sample.photos)
        ExpansionTile(
          title: Text('${photo.label} · ${photo.volume.toStringAsFixed(2)} L'),
          subtitle: Text(_date(photo.at)),
          children: [
            SelectableText(
              'SHA-256: ${photo.hash}',
              style: const TextStyle(fontSize: 11),
            ),
            InkWell(
              onTap: () => _showPhoto(context, photo.asset, photo.label),
              child: Image.asset(photo.asset, height: 160),
            ),
          ],
        ),
      if (sample.photos.isNotEmpty)
        _Registry(photos: sample.photos, settings: sample.configuration),
    ],
  );
}

final class _Report extends StatefulWidget {
  const _Report(this.controller);
  final WebDemoController controller;
  @override
  State<_Report> createState() => _ReportState();
}

final class _ReportState extends State<_Report> {
  late final html = DemoExport.renderer.toHtml(
    DemoExport.bundle(
      widget.controller.selectedCase!,
      widget.controller.selectedSamples,
      closed: widget.controller.caseClosed,
    ),
  );
  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: html,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Text('No se pudo abrir el reporte: ${snapshot.error}'),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return HtmlElementView.fromTagName(
        tagName: 'iframe',
        onElementCreated: (element) {
          final frame = element as web.HTMLIFrameElement;
          frame.title = 'Reporte de evidencia de verificación simulada';
          frame.sandbox.value = 'allow-scripts allow-modals';
          frame.style
            ..width = '100%'
            ..height = '100%'
            ..border = '0';
          frame.srcdoc = snapshot.data!.toJS;
        },
      );
    },
  );
}

String _mime(String extension) => switch (extension) {
  'pdf' => 'application/pdf',
  'json' => 'application/json',
  'html' => 'text/html;charset=utf-8',
  _ => 'text/csv;charset=utf-8',
};
void _download(Uint8List bytes, String extension, String name) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: _mime(extension)),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = '$name.$extension';
  anchor.click();
  Timer(const Duration(seconds: 1), () => web.URL.revokeObjectURL(url));
}
