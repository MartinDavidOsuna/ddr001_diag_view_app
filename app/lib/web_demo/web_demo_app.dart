import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:web/web.dart' as web;

import '../app/app_assets.dart';
import '../app/theme/app_theme.dart';
import '../core/metrology/metrology.dart';
import '../presentation/common/section_card.dart';
import '../presentation/common/app_version_label.dart';
import 'web_demo_domain.dart';
import 'web_demo_export.dart';

part 'web_demo_workflow.dart';
part 'web_demo_results.dart';

const _simulationNotice =
    'MODO SIMULACIÓN · PRUEBA SIMULADA — NO CORRESPONDE A UNA VERIFICACIÓN FÍSICA';

final class Ddr001WebDemoApp extends StatefulWidget {
  const Ddr001WebDemoApp({super.key, this.controller});
  final WebDemoController? controller;
  @override
  State<Ddr001WebDemoApp> createState() => _Ddr001WebDemoAppState();
}

final class _Ddr001WebDemoAppState extends State<Ddr001WebDemoApp> {
  late final controller = widget.controller ?? WebDemoController();
  bool ready = false;
  String? startupError;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      ready = true;
    } else {
      unawaited(_initialize());
    }
  }

  Future<void> _initialize() async {
    try {
      await controller.initialize();
      if (mounted) setState(() => ready = true);
    } catch (error) {
      if (mounted) {
        setState(
          () => startupError =
              'No se pudo recuperar el almacenamiento local: $error',
        );
      }
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AQ VF DDR001',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: !ready
        ? Scaffold(
            body: Center(
              child: startupError == null
                  ? const CircularProgressIndicator()
                  : Text(startupError!),
            ),
          )
        : AnimatedBuilder(
            animation: controller,
            builder: (context, _) => _DemoShell(controller),
          ),
  );
}

final class _DemoShell extends StatelessWidget {
  const _DemoShell(this.controller);
  final WebDemoController controller;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && controller.canGoBack) controller.goBack();
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            toolbarHeight: 70,
            flexibleSpace: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navy, Color(0xFF274D78)],
                ),
              ),
            ),
            leadingWidth: controller.canGoBack ? 92 : 52,
            leading: Row(
              children: [
                if (controller.canGoBack)
                  IconButton(
                    tooltip: 'Volver',
                    onPressed: controller.goBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Image.asset(
                    AppAssets.logoSymbol,
                    width: 30,
                    height: 30,
                  ),
                ),
              ],
            ),
            titleSpacing: 4,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pageTitle(controller.page),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                ),
                const Text(
                  'DDR001 · Modo offline',
                  style: TextStyle(fontSize: 11, color: Color(0xFFBCD0E8)),
                ),
              ],
            ),
            actions: [
              if (controller.indicatorsVisible) const _RunIndicators(),
              if (controller.page == WebDemoPage.home)
                IconButton(
                  tooltip: 'Ajustes',
                  onPressed: () => controller.navigate(WebDemoPage.settings),
                  icon: const Icon(Icons.settings_outlined),
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                if (controller.error != null)
                  StatusBanner(
                    text: controller.error!,
                    color: AppColors.danger,
                  ),
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey(controller.page),
                    child: switch (controller.page) {
                      WebDemoPage.home => _Home(controller),
                      WebDemoPage.identification => _Identification(controller),
                      WebDemoPage.method => _Method(controller),
                      WebDemoPage.setup => _Configuration(controller),
                      WebDemoPage.run => _Run(controller),
                      WebDemoPage.readings => _Readings(controller),
                      WebDemoPage.result => _Result(controller),
                      WebDemoPage.summary => _Summary(controller),
                      WebDemoPage.report => _Report(controller),
                      WebDemoPage.history => _History(controller),
                      WebDemoPage.settings => _Configuration(
                        controller,
                        advanced: true,
                      ),
                      WebDemoPage.manual => const _Manual(),
                      WebDemoPage.recovery => _Recovery(controller),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

String _pageTitle(WebDemoPage page) => switch (page) {
  WebDemoPage.home => 'VERIFICADOR FUNCIONAL',
  WebDemoPage.identification => 'Identificación',
  WebDemoPage.method => 'Método de medición',
  WebDemoPage.setup => 'Preparación',
  WebDemoPage.run => 'Prueba en curso',
  WebDemoPage.readings => 'Capturar lecturas',
  WebDemoPage.result => 'Resultado de prueba',
  WebDemoPage.summary => 'Resumen del expediente',
  WebDemoPage.report => 'Reporte de evidencia',
  WebDemoPage.history => 'Historial local',
  WebDemoPage.settings => 'Ajustes',
  WebDemoPage.manual => 'Manual de uso',
  WebDemoPage.recovery => 'Prueba en curso',
};

final class _RunIndicators extends StatelessWidget {
  const _RunIndicators();
  @override
  Widget build(BuildContext context) => const Padding(
    key: Key('run-indicators'),
    padding: EdgeInsets.only(right: 10),
    child: Tooltip(
      message: 'Indicadores demostrativos; sin conexión física',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bluetooth, size: 19, color: AppColors.success),
              Text(
                'ESP32',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.settings_remote, size: 20, color: AppColors.success),
            ],
          ),
          Text(
            'Indicadores demo',
            style: TextStyle(fontSize: 11.55, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

final class _Page extends StatelessWidget {
  const _Page({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

final class _Home extends StatelessWidget {
  const _Home(this.controller);
  final WebDemoController controller;
  @override
  Widget build(BuildContext context) => _Page(
    children: [
      SectionCard(
        title: 'Inicio',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hola',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Realiza una verificación metrológica completa aun sin conexión.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('new-verification'),
              onPressed: controller.startSetup,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('NUEVA VERIFICACIÓN'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: controller.showHistory,
              icon: const Icon(Icons.history),
              label: const Text('HISTORIAL LOCAL'),
            ),
            if (controller.hasDraft) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => controller.navigate(WebDemoPage.recovery),
                icon: const Icon(Icons.restore),
                label: const Text('REANUDAR PRUEBA'),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 28),
      const Center(
        child: AppVersionLabel(
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ),
    ],
  );
}

final class _History extends StatelessWidget {
  const _History(this.controller);
  final WebDemoController controller;
  @override
  Widget build(BuildContext context) => _Page(
    children: [
      if (controller.history.isEmpty)
        const SectionCard(
          title: 'Expedientes',
          child: Text(
            'Todavía no hay expedientes locales.',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      for (final item in controller.history) ...[
        InkWell(
          onTap: () => controller.openReport(item),
          child: SectionCard(
            title: 'Medidor ${item.meterId}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_date(item.createdAt)),
                const SizedBox(height: 6),
                const Text('Estado: FINALIZADO'),
                Text('Resultado: ${_verdict(item.verdict)}'),
                const Text(
                  'SIMULACIÓN',
                  style: TextStyle(color: AppColors.warning),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: controller.history.isEmpty
            ? null
            : () async {
                if (await _confirm(
                  context,
                  'Borrar historial local',
                  'Se eliminarán exclusivamente los expedientes demo cerrados de este navegador. La prueba en curso se conserva.',
                  'BORRAR',
                )) {
                  await controller.clearHistory();
                }
              },
        icon: const Icon(Icons.delete_sweep_outlined),
        label: const Text('BORRAR HISTORIAL'),
      ),
    ],
  );
}

final class _Identification extends StatefulWidget {
  const _Identification(this.controller);
  final WebDemoController controller;
  @override
  State<_Identification> createState() => _IdentificationState();
}

final class _IdentificationState extends State<_Identification> {
  final form = GlobalKey<FormState>();
  late final meter = TextEditingController(text: widget.controller.meterId);
  late final bench = TextEditingController(text: widget.controller.testBenchId);
  String? gpsMessage;
  @override
  void dispose() {
    meter.dispose();
    bench.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Page(
    children: [
      Form(
        key: form,
        child: SectionCard(
          title: '1 · Identificación',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('meter-id'),
                controller: meter,
                onChanged: (value) => widget.controller.meterId = value,
                decoration: const InputDecoration(
                  labelText: 'ID / número de cuenta del medidor',
                  hintText: 'p. ej. H-016',
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Captura cualquier ID válido.'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('test-bench-id'),
                controller: bench,
                onChanged: (value) => widget.controller.testBenchId = value,
                decoration: const InputDecoration(
                  labelText: 'ID / banco de pruebas',
                  hintText: 'p. ej. BANCO-01',
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Captura el banco de pruebas utilizado.'
                    : null,
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.location_off_outlined,
                  color: AppColors.muted,
                ),
                title: const Text('Ubicación GPS no capturada'),
                subtitle: Text(
                  gpsMessage ?? 'La prueba puede continuar sin ubicación.',
                ),
                trailing: IconButton(
                  key: const Key('capture-gps'),
                  tooltip: 'Obtener ubicación GPS',
                  onPressed: () => setState(
                    () => gpsMessage =
                        'GPS no disponible en la simulación local. No se inventa una ubicación.',
                  ),
                  icon: const Icon(Icons.my_location),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '* Dato informativo para validación interna',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                key: const Key('identify-continue'),
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  if (await _confirm(
                    context,
                    'Ubicación no registrada',
                    '¿Desea continuar sin capturar la ubicación de esta verificación?',
                    'CONTINUAR SIN UBICACIÓN',
                    cancel: 'CAPTURAR UBICACIÓN',
                  )) {
                    widget.controller.identify(
                      meter: meter.text,
                      bench: bench.text,
                    );
                  }
                },
                child: const Text('CONTINUAR'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

final class _Method extends StatelessWidget {
  const _Method(this.controller);
  final WebDemoController controller;
  @override
  Widget build(BuildContext context) => _Page(
    children: [
      SectionCard(
        title: '2 · Fuente / método',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final method in [
                  'BLUETOOTH',
                  'MANUAL',
                  'LECTURA VISUAL',
                  'SIMULACIÓN',
                ])
                  ChoiceChip(
                    label: Text(method),
                    selected: method == 'SIMULACIÓN',
                    onSelected: method == 'SIMULACIÓN' ? (_) {} : null,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            const StatusBanner(
              text:
                  'MODO SIMULACIÓN · Sin Bluetooth, ESP32, backend ni Internet.',
              color: AppColors.warning,
              icon: Icons.science_outlined,
            ),
            const SizedBox(height: 18),
            const StatusBanner(
              text:
                  'SIMULACIÓN CONTROLADA · Q1 fluctúa entre 5 y 7 L/s; Q2 entre 2 y 3 L/s. El técnico decide cuándo iniciar y finalizar, captura las lecturas y el motor calcula el resultado real.',
              color: AppColors.warning,
              icon: Icons.science_outlined,
            ),
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('method-continue'),
              onPressed: () => controller.navigate(WebDemoPage.setup),
              child: const Text('CONFIGURAR PRUEBA'),
            ),
          ],
        ),
      ),
    ],
  );
}

const _settingLabels = {
  'k': 'K (L/pulso)',
  'minimum': 'Vmín orientativo (L)',
  'maximum': 'Vmáx orientativo (L)',
  'startMin': 'Caudal mínimo para iniciar (L/s)',
  'startMax': 'Caudal máximo para iniciar (L/s)',
  'hydrantK': 'Medidor del hidrante · litros por pulso',
  'odometerScale': 'Escala del odómetro (L/unidad)',
  'needleScale': 'Escala aguja (L/vuelta)',
  'integers': 'Enteros del odómetro',
  'step': 'Paso de evidencia (L)',
  'uncertainty': 'Incertidumbre base uL (L)',
};

final class _Configuration extends StatefulWidget {
  const _Configuration(this.controller, {this.advanced = false});
  final WebDemoController controller;
  final bool advanced;
  @override
  State<_Configuration> createState() => _ConfigurationState();
}

final class _ConfigurationState extends State<_Configuration> {
  final form = GlobalKey<FormState>();
  late final fields = {
    for (final key in _settingLabels.keys)
      key: TextEditingController(
        text: widget.controller.settings.values[key].toString(),
      ),
  };
  late int decimals = widget.controller.settings.value('decimals').toInt();
  String? error;
  @override
  void dispose() {
    for (final field in fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Widget field(String key) => TextFormField(
    key: Key('config-$key'),
    controller: fields[key],
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: _settingLabels[key]),
    validator: (text) => double.tryParse(text ?? '')?.isFinite == true
        ? null
        : 'Valor inválido.',
  );
  Widget pair(String first, String second) => Row(
    children: [
      Expanded(child: field(first)),
      const SizedBox(width: 10),
      Expanded(child: field(second)),
    ],
  );
  @override
  Widget build(BuildContext context) => _Page(
    children: [
      if (widget.advanced) ...[
        SectionCard(
          title: 'Usuario actual',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Value('Nombre', 'Operador de simulación'),
              const _Value('Correo', 'No registrado'),
              const _Value('Teléfono', 'No registrado'),
              const _Value('ID del teléfono', 'No disponible'),
              const _Value('Android', 'No disponible'),
              const _Value('Marca', 'No disponible'),
              const _Value('Modelo', 'No disponible'),
              const AppVersionLabel(),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => widget.controller.navigate(WebDemoPage.manual),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('MANUAL DE USO  >'),
              ),
              const SizedBox(height: 10),
              const OutlinedButton(
                onPressed: null,
                child: Text('CERRAR SESIÓN'),
              ),
              const Text(
                'La presentación local no inicia sesión.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
      Form(
        key: form,
        child: SectionCard(
          title: widget.advanced ? 'Ajustes (avanzado)' : 'Configuración',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.advanced) ...[
                _Value('Medidor', widget.controller.meterId),
                const _Value(
                  'Q1 — Caudal operativo',
                  'Calculado durante la prueba',
                ),
                const _Value(
                  'Q2 — Caudal medio',
                  'Calculado durante la prueba',
                ),
                const _Value('Método', 'SIMULACIÓN'),
                const _Value('Escenario', 'Controlada por operador'),
                _Value(
                  'K para Q1',
                  '${widget.controller.settings.value('k')} L/pulso',
                ),
                _Value(
                  'K para Q2',
                  '${widget.controller.settings.value('k')} L/pulso',
                ),
                const Divider(),
                const StatusBanner(
                  text: _simulationNotice,
                  color: AppColors.warning,
                  icon: Icons.science_outlined,
                ),
                const SizedBox(height: 10),
              ] else ...[
                field('k'),
                const SizedBox(height: 10),
              ],
              pair('minimum', 'maximum'),
              const SizedBox(height: 10),
              if (!widget.advanced) ...[
                pair('startMin', 'startMax'),
                const SizedBox(height: 10),
                field('hydrantK'),
                const SizedBox(height: 10),
                pair('odometerScale', 'needleScale'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: field('integers')),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: decimals,
                        decoration: const InputDecoration(
                          labelText: 'Decimales',
                        ),
                        items: [
                          for (final value in [0, 1, 2, 3])
                            DropdownMenuItem(
                              value: value,
                              child: Text(
                                value == 0 ? 'Sin decimales' : '$value',
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(() => decimals = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              field('step'),
              const SizedBox(height: 10),
              field('uncertainty'),
              const SizedBox(height: 10),
              if (error != null)
                Text(error!, style: const TextStyle(color: AppColors.danger)),
              FilledButton(
                key: const Key('start-sample'),
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  try {
                    final settings = DemoSettings({
                      for (final entry in fields.entries)
                        entry.key: num.parse(entry.value.text),
                      'decimals': decimals,
                    });
                    await widget.controller.saveSettings(settings);
                    if (!context.mounted) return;
                    if (widget.advanced) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ajustes aplicados a nuevas muestras.'),
                        ),
                      );
                    } else {
                      widget.controller.beginCase(
                        meter: widget.controller.meterId,
                        bench: widget.controller.testBenchId,
                      );
                    }
                  } catch (failure) {
                    if (mounted) setState(() => error = '$failure');
                  }
                },
                child: Text(
                  widget.advanced ? 'GUARDAR AJUSTES' : 'INICIAR SIMULACIÓN',
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

final class _Recovery extends StatelessWidget {
  const _Recovery(this.controller);
  final WebDemoController controller;
  @override
  Widget build(BuildContext context) => _Page(
    children: [
      SectionCard(
        title: 'Recuperación',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusBanner(
              text: _simulationNotice,
              color: AppColors.warning,
              icon: Icons.science_outlined,
            ),
            const SizedBox(height: 18),
            const StatusBanner(
              text: 'Se encontró una prueba guardada en este dispositivo.',
              color: AppColors.warning,
              icon: Icons.restore,
            ),
            _Value('Medidor', controller.meterId),
            _Value('Caudal', controller.flowPoint.name.toUpperCase()),
            const _Value('Método', 'SIMULACIÓN'),
            _Value(
              'Inicio',
              controller.startedAt == null ? '—' : _date(controller.startedAt!),
            ),
            _Value(
              'Pulsos / progreso',
              '${controller.pulseCount} · ${controller.referenceLiters.toStringAsFixed(1)} L',
            ),
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('resume-sample'),
              onPressed: controller.resume,
              child: const Text('REANUDAR PRUEBA'),
            ),
            OutlinedButton(
              onPressed: () => controller.navigate(WebDemoPage.home),
              child: const Text('IR AL INICIO SIN DESCARTAR'),
            ),
          ],
        ),
      ),
    ],
  );
}

final class _Manual extends StatefulWidget {
  const _Manual();
  @override
  State<_Manual> createState() => _ManualState();
}

final class _ManualState extends State<_Manual> {
  late final manual = rootBundle.loadString('assets/manual/manual_de_uso.md');
  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: manual,
    builder: (context, snapshot) => snapshot.hasData
        ? Markdown(data: snapshot.data!)
        : const Center(child: CircularProgressIndicator()),
  );
}

final class _Value extends StatelessWidget {
  const _Value(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String message,
  String accept, {
  String cancel = 'CANCELAR',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(accept),
          ),
        ],
      ),
    ) ??
    false;

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
String _flowStatus(FlowPointStatus status) => switch (status) {
  FlowPointStatus.pending => 'PENDIENTE',
  FlowPointStatus.pass => 'APRUEBA',
  FlowPointStatus.fail => 'RECHAZA',
  FlowPointStatus.inconclusive => 'NO CONCLUYENTE',
};
String _duration(Duration value) =>
    '${value.inMinutes.toString().padLeft(2, '0')}:${value.inSeconds.remainder(60).toString().padLeft(2, '0')}';
String _date(DateTime value) =>
    '${value.toLocal().day.toString().padLeft(2, '0')}/${value.toLocal().month.toString().padLeft(2, '0')}/${value.toLocal().year} ${_time(value)}';
String _time(DateTime value) =>
    '${value.toLocal().hour.toString().padLeft(2, '0')}:${value.toLocal().minute.toString().padLeft(2, '0')}:${value.toLocal().second.toString().padLeft(2, '0')}';
