// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../app/app_assets.dart';
import '../app/theme/app_theme.dart';
import '../core/metrology/metrology.dart';
import 'web_demo_domain.dart';

final class Ddr001WebDemoApp extends StatefulWidget {
  const Ddr001WebDemoApp({super.key});

  @override
  State<Ddr001WebDemoApp> createState() => _Ddr001WebDemoAppState();
}

final class _Ddr001WebDemoAppState extends State<Ddr001WebDemoApp> {
  late final WebDemoController controller = WebDemoController();

  @override
  void initState() {
    super.initState();
    controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AQ VF DDR001 · Demo',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: AnimatedBuilder(
      animation: controller,
      builder: (context, _) => _DemoShell(controller: controller),
    ),
  );
}

final class _DemoShell extends StatelessWidget {
  const _DemoShell({required this.controller});
  final WebDemoController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 78,
      title: Row(
        children: [
          Image.asset(AppAssets.logoSymbol, width: 48, height: 48),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VERIFICADOR FUNCIONAL',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Text(
                'DEMO WEB LOCAL · SIN API / SIN BASE DE DATOS',
                style: TextStyle(fontSize: 11, color: AppColors.warning),
              ),
            ],
          ),
        ],
      ),
      actions: const [
        _ConnectedIndicator(icon: Icons.bluetooth, label: 'ESP32'),
        SizedBox(width: 12),
        _ConnectedIndicator(icon: Icons.settings_remote, label: 'CONTROL'),
        SizedBox(width: 22),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (controller.page) {
            WebDemoPage.home => _Home(controller),
            WebDemoPage.setup => _Setup(controller),
            WebDemoPage.run => _Run(controller),
            WebDemoPage.readings => _Readings(controller),
            WebDemoPage.result => _Result(controller),
            WebDemoPage.report => _Report(controller),
          },
        ),
      ),
    ),
  );
}

final class _ConnectedIndicator extends StatelessWidget {
  const _ConnectedIndicator({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: '$label conectado · indicador demostrativo',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.success, size: 22),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.success,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}

final class _Home extends StatelessWidget {
  const _Home(this.controller);
  final WebDemoController controller;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const _Banner(
        text:
            'MODO SIMULACIÓN · presentación autónoma · todos los datos permanecen en este navegador',
        icon: Icons.science_outlined,
        color: AppColors.warning,
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: controller.startSetup,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('NUEVA VERIFICACIÓN SIMULADA'),
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          const Expanded(
            child: Text(
              'HISTORIAL LOCAL',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          OutlinedButton.icon(
            onPressed: controller.history.isEmpty
                ? null
                : () => _confirmClear(context, controller),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('BORRAR HISTORIAL'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (controller.history.isEmpty)
        const _Card(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: Text('Sin expedientes demo guardados.')),
          ),
        )
      else
        ...controller.history.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Card(
              child: ListTile(
                leading: Icon(
                  _verdictIcon(item.verdict),
                  color: _verdictColor(item.verdict),
                ),
                title: Text(
                  item.meterId,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${item.testBenchId} · ${_date(item.createdAt)} · ${_verdict(item.verdict)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => controller.openReport(item),
              ),
            ),
          ),
        ),
    ],
  );

  Future<void> _confirmClear(
    BuildContext context,
    WebDemoController controller,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar historial local'),
        content: const Text(
          'Se eliminarán exclusivamente los expedientes demo guardados en este navegador. Esta acción no afecta Android, API ni SQL.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('BORRAR'),
          ),
        ],
      ),
    );
    if (accepted == true) await controller.clearHistory();
  }
}

final class _Setup extends StatefulWidget {
  const _Setup(this.controller);
  final WebDemoController controller;

  @override
  State<_Setup> createState() => _SetupState();
}

final class _SetupState extends State<_Setup> {
  final meter = TextEditingController(text: 'DEMO-0001');
  final bench = TextEditingController(text: 'BANCO-DEMO');

  @override
  void dispose() {
    meter.dispose();
    bench.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const Text(
        '1 · IDENTIFICACIÓN',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 16),
      const _Banner(
        text:
            'Sin login. Sólo SIMULACIÓN. No se transmite información fuera del navegador.',
        icon: Icons.lock_outline,
        color: AppColors.success,
      ),
      const SizedBox(height: 18),
      _Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: meter,
                decoration: const InputDecoration(
                  labelText: 'ID / número de cuenta del medidor',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: bench,
                decoration: const InputDecoration(
                  labelText: 'ID / banco de pruebas',
                ),
              ),
              const SizedBox(height: 18),
              const ListTile(
                leading: Icon(Icons.science, color: AppColors.warning),
                title: Text('Método: SIMULACIÓN'),
                subtitle: Text(
                  'Q1 5–7 L/s · Q2 2–3 L/s · variación máxima 0.5 L/s',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => widget.controller.beginCase(
                  meter: meter.text,
                  bench: bench.text,
                ),
                child: const Text('CONFIGURAR PRUEBA'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: widget.controller.showHistory,
                child: const Text('VOLVER'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

final class _Run extends StatelessWidget {
  const _Run(this.controller);
  final WebDemoController controller;

  @override
  Widget build(BuildContext context) {
    final q = controller.flowPoint.name.toUpperCase();
    return ListView(
      children: [
        Text(
          '2 · PRUEBA EN CURSO · $q',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        const _Banner(
          text:
              'MODO SIMULACIÓN · PRUEBA SIMULADA — NO CORRESPONDE A UNA VERIFICACIÓN FÍSICA',
          icon: Icons.science_outlined,
          color: AppColors.warning,
        ),
        const SizedBox(height: 16),
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  '${controller.flowLps.toStringAsFixed(2)} L/s',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  controller.measurementStarted
                      ? 'Medición activa desde ${_time(controller.startedAt!)}'
                      : 'Flujo previo activo · la medición aún no inicia',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 30,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _Metric('Pulsos', '${controller.pulseCount}'),
                    _Metric('Vref', '${controller.pulseCount}.00 L'),
                    _Metric('Tiempo', _duration(controller.elapsed)),
                    const _Metric('K', '1 L/pulso'),
                  ],
                ),
                const SizedBox(height: 24),
                if (!controller.measurementStarted)
                  FilledButton.icon(
                    key: const Key('web-demo-start'),
                    onPressed: controller.startMeasurement,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('INICIAR PRUEBA'),
                  )
                else
                  FilledButton.icon(
                    key: const Key('web-demo-finish'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.red,
                    ),
                    onPressed: controller.pulseCount == 0
                        ? null
                        : controller.finishMeasurement,
                    icon: const Icon(Icons.stop),
                    label: const Text('FINALIZAR Y CONFIRMAR LECTURAS'),
                  ),
              ],
            ),
          ),
        ),
      ],
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
  final initialTotalizer = TextEditingController(text: '10.000');
  final initialNeedle = TextEditingController(text: '0');
  late final TextEditingController finalTotalizer;
  final finalNeedle = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    final end = 10 + widget.controller.pulseCount / 1000;
    finalTotalizer = TextEditingController(text: end.toStringAsFixed(3));
  }

  @override
  void dispose() {
    initialTotalizer.dispose();
    initialNeedle.dispose();
    finalTotalizer.dispose();
    finalNeedle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: ListView(
      children: [
        const Text(
          '3 · CAPTURAR LECTURAS',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        const _Banner(
          text:
              'Evidence demo con números ilustrativos. Toque cualquier recorte para ver la carátula completa.',
          icon: Icons.photo_camera_outlined,
          color: AppColors.heading,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _readingCard(
                context,
                'LECTURA INICIO',
                initialTotalizer,
                initialNeedle,
                constraints.maxWidth > 800
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth,
              ),
              _readingCard(
                context,
                'LECTURA FINAL',
                finalTotalizer,
                finalNeedle,
                constraints.maxWidth > 800
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () async {
            if (!form.currentState!.validate()) return;
            try {
              await widget.controller.calculate(
                initialTotalizer: double.parse(initialTotalizer.text),
                initialNeedle: double.parse(initialNeedle.text),
                finalTotalizer: double.parse(finalTotalizer.text),
                finalNeedle: double.parse(finalNeedle.text),
              );
            } on ArgumentError catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('$error')));
            }
          },
          child: const Text('GUARDAR Y CALCULAR RESULTADO'),
        ),
      ],
    ),
  );

  Widget _readingCard(
    BuildContext context,
    String title,
    TextEditingController totalizer,
    TextEditingController needle,
    double width,
  ) => SizedBox(
    width: width,
    child: _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _DemoCrop(
              label: 'Totalizador $title',
              alignment: const Alignment(0, -0.25),
              scale: 2.9,
            ),
            const SizedBox(height: 10),
            _number(totalizer, 'Valor del totalizador (m³)'),
            const SizedBox(height: 14),
            _DemoCrop(
              label: 'Aguja $title',
              alignment: const Alignment(0, 0.42),
              scale: 3.2,
            ),
            const SizedBox(height: 10),
            _number(needle, 'Lectura de aguja (L)'),
          ],
        ),
      ),
    ),
  );

  Widget _number(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final parsed = double.tryParse(value ?? '');
          return parsed != null && parsed >= 0 ? null : 'Valor inválido.';
        },
      );
}

final class _DemoCrop extends StatelessWidget {
  const _DemoCrop({
    required this.label,
    required this.alignment,
    required this.scale,
  });
  final String label;
  final Alignment alignment;
  final double scale;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black,
    borderRadius: BorderRadius.circular(AppRadius.card),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => showDialog<void>(
        context: context,
        barrierColor: const Color(0xDD000000),
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Image.asset(AppAssets.demoMeterFace),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ),
      child: SizedBox(
        height: 180,
        child: ClipRect(
          child: Transform.scale(
            scale: scale,
            alignment: alignment,
            child: Image.asset(AppAssets.demoMeterFace, fit: BoxFit.cover),
          ),
        ),
      ),
    ),
  );
}

final class _Result extends StatelessWidget {
  const _Result(this.controller);
  final WebDemoController controller;

  @override
  Widget build(BuildContext context) {
    final sample = controller.latestSample!;
    return ListView(
      children: [
        Text(
          '4 · RESULTADO ${sample.flowPoint.name.toUpperCase()}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        _Banner(
          text:
              '${_verdict(sample.verdict)} · ${sample.errorPct.toStringAsFixed(2)} % ±${sample.uncertaintyPct.toStringAsFixed(2)} %',
          icon: _verdictIcon(sample.verdict),
          color: _verdictColor(sample.verdict),
        ),
        const SizedBox(height: 16),
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Wrap(
              spacing: 44,
              runSpacing: 20,
              children: [
                _Metric(
                  'Vref',
                  '${sample.referenceLiters.toStringAsFixed(2)} L',
                ),
                _Metric(
                  'Vind',
                  '${sample.indicatedLiters.toStringAsFixed(2)} L',
                ),
                _Metric('Error', '${sample.errorPct.toStringAsFixed(4)} %'),
                _Metric('U', '${sample.uncertaintyPct.toStringAsFixed(4)} %'),
                _Metric('MPE', '±${sample.mpePct.toStringAsFixed(2)} %'),
                _Metric('Evidencias', '${sample.evidence.length}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (sample.flowPoint == FlowPoint.q1)
          FilledButton(
            onPressed: controller.startQ2,
            child: const Text('COMENZAR Q2'),
          )
        else
          FilledButton(
            onPressed: controller.finishCase,
            child: const Text('GENERAR REPORTE'),
          ),
      ],
    );
  }
}

final class _Report extends StatelessWidget {
  const _Report(this.controller);
  final WebDemoController controller;

  @override
  Widget build(BuildContext context) {
    final item = controller.selectedCase!;
    return ListView(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'REPORTE DE VERIFICACIÓN SIMULADA',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _downloadReport(item),
              icon: const Icon(Icons.download),
              label: const Text('DESCARGAR HTML'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _Banner(
          text: 'PRUEBA SIMULADA — NO CORRESPONDE A UNA VERIFICACIÓN FÍSICA',
          icon: Icons.science_outlined,
          color: AppColors.warning,
        ),
        const SizedBox(height: 16),
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(AppAssets.splashLogo, height: 72),
                const SizedBox(height: 18),
                Text('Medidor: ${item.meterId}'),
                Text('Banco: ${item.testBenchId}'),
                Text('Fecha: ${_date(item.createdAt)}'),
                Text('Resultado global: ${_verdict(item.verdict)}'),
                const Divider(height: 34),
                ...item.samples.map(
                  (sample) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _SampleReport(sample),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: controller.showHistory,
          child: const Text('VOLVER AL HISTORIAL'),
        ),
      ],
    );
  }

  void _downloadReport(DemoCase item) {
    final htmlText = _reportHtml(item);
    final blob = web.Blob(
      [htmlText.toJS].toJS,
      web.BlobPropertyBag(type: 'text/html;charset=utf-8'),
    );
    final url = web.URL.createObjectURL(blob);
    web.HTMLAnchorElement()
      ..href = url
      ..download = 'DDR001-${item.meterId}.html'
      ..click();
    web.URL.revokeObjectURL(url);
  }
}

final class _SampleReport extends StatelessWidget {
  const _SampleReport(this.sample);
  final DemoSample sample;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${sample.flowPoint.name.toUpperCase()} · ${_verdict(sample.verdict)}',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: _verdictColor(sample.verdict),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 28,
        runSpacing: 10,
        children: [
          Text('Vref ${sample.referenceLiters.toStringAsFixed(2)} L'),
          Text('Vind ${sample.indicatedLiters.toStringAsFixed(2)} L'),
          Text('E ${sample.errorPct.toStringAsFixed(4)} %'),
          Text('U ${sample.uncertaintyPct.toStringAsFixed(4)} %'),
          Text('MPE ±${sample.mpePct.toStringAsFixed(2)} %'),
          Text('Caudal prom. ${sample.averageFlowLps.toStringAsFixed(2)} L/s'),
        ],
      ),
      const SizedBox(height: 8),
      Text('Evidence: ${sample.evidence.join(' · ')}'),
    ],
  );
}

final class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(child: child);
}

final class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.icon, required this.color});
  final String text;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      border: Border.all(color: color.withValues(alpha: .6)),
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );
}

final class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted)),
      Text(
        value,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
    ],
  );
}

String _reportHtml(DemoCase item) {
  final escape = const HtmlEscape().convert;
  final rows = item.samples
      .map(
        (s) =>
            '''<tr><td>${escape(s.flowPoint.name.toUpperCase())}</td><td>${escape(_verdict(s.verdict))}</td><td>${s.referenceLiters.toStringAsFixed(2)} L</td><td>${s.indicatedLiters.toStringAsFixed(2)} L</td><td>${s.errorPct.toStringAsFixed(4)} %</td><td>${s.uncertaintyPct.toStringAsFixed(4)} %</td><td>${s.mpePct.toStringAsFixed(2)} %</td></tr>''',
      )
      .join();
  return '''<!doctype html><html lang="es"><meta charset="utf-8"><title>DDR001 ${escape(item.meterId)}</title><style>body{font-family:Arial;margin:40px;color:#17263a}h1{color:#1f5c99}.warning{padding:14px;background:#fff3d6;border:1px solid #c07b1f}table{border-collapse:collapse;width:100%;margin-top:24px}th,td{border:1px solid #9fb2c8;padding:10px;text-align:left}th{background:#e8eef5}</style><body><h1>VERIFICADOR FUNCIONAL DDR001</h1><p class="warning">PRUEBA SIMULADA — NO CORRESPONDE A UNA VERIFICACIÓN FÍSICA</p><p><b>Medidor:</b> ${escape(item.meterId)}<br><b>Banco:</b> ${escape(item.testBenchId)}<br><b>Fecha:</b> ${escape(_date(item.createdAt))}<br><b>Resultado global:</b> ${escape(_verdict(item.verdict))}</p><table><thead><tr><th>Caudal</th><th>Resultado</th><th>Vref</th><th>Vind</th><th>Error</th><th>U</th><th>MPE</th></tr></thead><tbody>$rows</tbody></table><script>window.print()</script></body></html>''';
}

String _verdict(SampleVerdict value) => switch (value) {
  SampleVerdict.pass => 'APRUEBA',
  SampleVerdict.fail => 'RECHAZA',
  SampleVerdict.inconclusive => 'NO CONCLUYENTE',
};

Color _verdictColor(SampleVerdict value) => switch (value) {
  SampleVerdict.pass => AppColors.success,
  SampleVerdict.fail => AppColors.danger,
  SampleVerdict.inconclusive => AppColors.warning,
};

IconData _verdictIcon(SampleVerdict value) => switch (value) {
  SampleVerdict.pass => Icons.check_circle,
  SampleVerdict.fail => Icons.cancel,
  SampleVerdict.inconclusive => Icons.warning_amber,
};

String _duration(Duration value) =>
    '${value.inMinutes.toString().padLeft(2, '0')}:${value.inSeconds.remainder(60).toString().padLeft(2, '0')}';
String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${_time(value)}';
String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}';
