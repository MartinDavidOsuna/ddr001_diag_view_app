import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/models.dart';
import '../app_controller.dart';
import '../common/app_scaffold.dart';
import '../common/app_version_label.dart';

final class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final displayName = state.user?.displayName;
    return AppScaffold(
      title: 'DDR001 · Verificador de medidores',
      showBack: false,
      bottomOverlay: const AppVersionLabel(
        style: TextStyle(color: Color(0xFF31445D), fontSize: 12),
      ),
      actions: [
        IconButton(
          onPressed: controller.showSettings,
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Ajustes',
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'Inicio',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  displayName == null || displayName.isEmpty
                      ? 'Hola'
                      : 'Hola, $displayName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Realiza una verificación metrológica completa aun sin conexión.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('new-verification'),
                  onPressed: controller.startIdentification,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('NUEVA VERIFICACIÓN'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: controller.showHistory,
                  icon: const Icon(Icons.history),
                  label: const Text('HISTORIAL LOCAL'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class RecoveryScreen extends ConsumerWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final sample = state.sample!;
    return AppScaffold(
      title: 'Prueba en curso',
      showBack: false,
      child: SectionCard(
        title: 'Recuperación',
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
              const SizedBox(height: 18),
            ],
            const StatusBanner(
              text: 'Se encontró una prueba guardada en este dispositivo.',
              color: AppColors.warning,
              icon: Icons.restore,
            ),
            const SizedBox(height: 18),
            _Info(label: 'Medidor', value: state.meter?.id ?? '—'),
            _Info(
              label: 'Caudal',
              value: state.flow?.code.name.toUpperCase() ?? '—',
            ),
            _Info(
              label: 'Método',
              value: methodLabel(sample.configuration.measurementMethod),
            ),
            _Info(
              label: 'Inicio',
              value: sample.startedAt?.toLocal().toString() ?? '—',
            ),
            _Info(
              label: 'Pulsos / progreso',
              value:
                  '${sample.pulseCount} · ${sample.referenceLitersProgress?.toStringAsFixed(1) ?? '0'} L',
            ),
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('resume-sample'),
              onPressed: ref.read(appControllerProvider.notifier).resumeSample,
              child: const Text('REANUDAR PRUEBA'),
            ),
            OutlinedButton(
              key: const Key('leave-recovery'),
              onPressed: ref.read(appControllerProvider.notifier).showHome,
              child: const Text('IR AL INICIO SIN DESCARTAR'),
            ),
            const SizedBox(height: 8),
            const Text(
              'La prueba no puede descartarse silenciosamente. Salir de esta pantalla no modifica su estado.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

final class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    return AppScaffold(
      title: 'Historial local',
      child: state.cases.isEmpty
          ? const SectionCard(
              title: 'Expedientes',
              child: Text(
                'Todavía no hay expedientes locales.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          : Column(
              children: state.cases
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => ref
                            .read(appControllerProvider.notifier)
                            .openCaseFromHistory(item.id),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        child: SectionCard(
                          title: 'Medidor ${item.meterId}',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.createdAt.toLocal().toString()),
                              const SizedBox(height: 6),
                              Text(
                                'Estado: ${item.status == VerificationCaseStatus.closed ? 'FINALIZADO' : 'ABIERTO'}',
                              ),
                              Text(
                                'Resultado: ${overallLabel(item.overallVerdict)}',
                              ),
                              if (ref
                                  .read(appDependenciesProvider)
                                  .backendSyncConfigured)
                                Text(
                                  'Sincronización: ${state.caseSyncMessages[item.id] ?? 'Pendiente'}',
                                  style: TextStyle(
                                    color:
                                        state.caseSyncMessages[item.id] ==
                                            'Sincronizado'
                                        ? AppColors.success
                                        : AppColors.muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

final class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    return AppScaffold(
      title: 'Ajustes',
      child: Column(
        children: [
          SectionCard(
            title: 'Usuario actual',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Info(label: 'Nombre', value: state.user?.displayName ?? '—'),
                _Info(label: 'Correo', value: state.user?.email ?? '—'),
                _Info(label: 'Teléfono', value: state.user?.phone ?? '—'),
                const SizedBox(height: 12),
                _Info(
                  label: 'ID del teléfono',
                  value: state.deviceMetadata.id ?? 'No disponible',
                ),
                _Info(
                  label: 'Android',
                  value: state.deviceMetadata.androidVersion ?? 'No disponible',
                ),
                _Info(
                  label: 'Marca',
                  value: state.deviceMetadata.brand ?? 'No disponible',
                ),
                _Info(
                  label: 'Modelo',
                  value: state.deviceMetadata.model ?? 'No disponible',
                ),
                const SizedBox(height: 16),
                const AppVersionLabel(style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  key: const Key('manual-de-uso'),
                  onPressed: ref
                      .read(appControllerProvider.notifier)
                      .showManual,
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('MANUAL DE USO  >'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('logout'),
                  onPressed: ref.read(appControllerProvider.notifier).logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('CERRAR SESIÓN'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _OperationalSettings(),
        ],
      ),
    );
  }
}

final class _OperationalSettings extends ConsumerStatefulWidget {
  const _OperationalSettings();
  @override
  ConsumerState<_OperationalSettings> createState() =>
      _OperationalSettingsState();
}

final class _OperationalSettingsState
    extends ConsumerState<_OperationalSettings> {
  late final _k = TextEditingController(
    text: ref.read(appControllerProvider).litersPerPulse.toString(),
  );
  late final _step = TextEditingController(
    text: ref.read(appControllerProvider).evidenceStepLiters.toString(),
  );
  late final _minimum = TextEditingController(
    text: ref.read(appControllerProvider).minimumVolumeLiters.toString(),
  );
  late final _maximum = TextEditingController(
    text: ref.read(appControllerProvider).maximumVolumeLiters.toString(),
  );
  late final _uncertainty = TextEditingController(
    text: ref.read(appControllerProvider).readingUncertaintyLiters.toString(),
  );

  @override
  void dispose() {
    _k.dispose();
    _step.dispose();
    _minimum.dispose();
    _maximum.dispose();
    _uncertainty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Ajustes (avanzado)',
    child: Column(
      children: [
        _field(_k, 'K (L/pulso)'),
        _field(_step, 'Paso captura/evidencia (L)'),
        _field(_minimum, 'Vmín orientativo (L)'),
        _field(_maximum, 'Vmáx orientativo (L)'),
        _field(_uncertainty, 'Incertidumbre de lectura ±L'),
        const SizedBox(height: 8),
        const Text(
          'El MPE se deriva de Q1 y Q2. Los valores quedan congelados al crear cada muestra.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            ref
                .read(appControllerProvider.notifier)
                .updateSetup(
                  litersPerPulse: double.tryParse(_k.text) ?? 1,
                  evidenceStepLiters: double.tryParse(_step.text) ?? 25,
                  uncertaintyLiters: double.tryParse(_uncertainty.text) ?? 1,
                  minimumVolumeLiters: double.tryParse(_minimum.text) ?? 100,
                  maximumVolumeLiters: double.tryParse(_maximum.text) ?? 300,
                );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ajustes aplicados a nuevas muestras.'),
              ),
            );
          },
          child: const Text('GUARDAR AJUSTES'),
        ),
      ],
    ),
  );

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    ),
  );
}

final class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              maxLines: 1,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );
}

String methodLabel(dynamic method) =>
    switch (method.toString().split('.').last) {
      'visual' => 'LECTURA VISUAL',
      'manual' => 'MANUAL',
      'led' => 'LED',
      'ble' => 'BLUETOOTH',
      'simulation' => 'SIMULACIÓN',
      _ => '—',
    };

String overallLabel(OverallVerdict? value) => switch (value) {
  OverallVerdict.approved => 'APROBADO',
  OverallVerdict.rejected => 'RECHAZADO',
  OverallVerdict.inconclusive => 'NO CONCLUYENTE',
  null => 'PENDIENTE',
};
