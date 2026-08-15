import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../infrastructure/camera/camera_models.dart';
import '../../infrastructure/vision/vision_models.dart';
import '../../domain/models.dart';
import '../app_controller.dart';
import '../common/app_scaffold.dart';

final class CameraCaptureScreen extends ConsumerStatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  ConsumerState<CameraCaptureScreen> createState() =>
      _CameraCaptureScreenState();
}

final class _CameraCaptureScreenState extends ConsumerState<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraPermissionState? _permission;
  bool _ready = false;
  bool _initializing = false;
  String? _cameraError;
  final _odometer = TextEditingController();
  final _needle = TextEditingController();
  bool _manualCorrection = false;
  bool _adjustingRegions = false;
  DateTime? _loadedProposalAt;
  late DialVisionConfiguration _visionConfiguration;
  int _digitCount = 4;
  int _decimalPlaces = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    if (_initializing || _ready) return;
    _initializing = true;
    final camera = ref.read(appDependenciesProvider).camera;
    if (camera == null) {
      _initializing = false;
      return;
    }
    try {
      final permission = await camera.requestPermission();
      if (!mounted) return;
      setState(() => _permission = permission);
      if (permission != CameraPermissionState.granted) return;
      await camera.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) {
        setState(() => _cameraError = 'No fue posible iniciar la cámara.');
      }
    } finally {
      _initializing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = ref.read(appDependenciesProvider).camera;
    if (camera == null || _permission != CameraPermissionState.granted) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (!_ready) return;
      _ready = false;
      camera.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (ref.read(appControllerProvider).readingProposal != null) return;
      if (!_ready && !_initializing) {
        _initializing = true;
        camera
            .resume()
            .then((_) {
              if (mounted) setState(() => _ready = true);
            })
            .catchError((_) {
              if (mounted) {
                setState(
                  () => _cameraError = 'No fue posible reabrir la cámara.',
                );
              }
            })
            .whenComplete(() => _initializing = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _odometer.dispose();
    _needle.dispose();
    // AppDependencies owns the shared camera. Evidence releases it so the LED
    // ImageStream can reuse the same physical camera without closing its
    // brightness stream for the rest of the process lifetime.
    unawaited(ref.read(appDependenciesProvider).camera?.pause());
    super.dispose();
  }

  Future<void> _capture() async {
    final camera = ref.read(appDependenciesProvider).camera!;
    try {
      final photo = await camera.capture();
      if (!mounted) return;
      await camera.pause();
      if (mounted) setState(() => _ready = false);
      await ref
          .read(appControllerProvider.notifier)
          .processCapturedPhoto(photo.path);
    } catch (_) {
      if (mounted) {
        setState(() => _cameraError = 'No fue posible capturar la fotografía.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final proposal = state.readingProposal;
    if (proposal != null && _loadedProposalAt != proposal.createdAt) {
      _loadedProposalAt = proposal.createdAt;
      _visionConfiguration = proposal.configuration;
      _digitCount =
          proposal.configuration.totalizerConfiguration?.digitCount ??
          (proposal.odometerCandidates.isEmpty
              ? 4
              : proposal.odometerCandidates.first.digits.length);
      _decimalPlaces =
          proposal.configuration.totalizerConfiguration?.decimalPlaces ?? 1;
      _odometer.text = proposal.odometerValue?.toString() ?? '';
      _needle.text = proposal.needleLiters?.toStringAsFixed(2) ?? '';
      _manualCorrection =
          proposal.odometerValue == null ||
          proposal.needleLiters == null ||
          (proposal.totalizerReadingProposal?.requiresConfirmation ?? false);
    }
    return AppScaffold(
      title: _captureTitle(state.capturePurpose),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: '3 · Carátula para leer y evidencia',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Centre la carátula dentro de la guía. La misma fotografía se guardará como evidencia y se analizará.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_ready)
                          ref
                              .read(appDependenciesProvider)
                              .camera!
                              .buildPreview()
                        else
                          const ColoredBox(color: Colors.black),
                        const _DialGuide(),
                        if (state.cameraState ==
                            CameraOperationState.processing)
                          const ColoredBox(
                            color: Color(0x99000000),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 12),
                                  Text('Analizando lectura...'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_permission == CameraPermissionState.denied)
                  const StatusBanner(
                    text:
                        'Permiso de cámara denegado. La evidencia es obligatoria y la prueba no puede cerrarse válidamente.',
                    color: AppColors.danger,
                    icon: Icons.no_photography_outlined,
                  ),
                if (_permission == CameraPermissionState.permanentlyDenied) ...[
                  const StatusBanner(
                    text:
                        'Permiso denegado permanentemente. Habilite Cámara en Ajustes del sistema.',
                    color: AppColors.danger,
                    icon: Icons.settings_outlined,
                  ),
                  OutlinedButton(
                    onPressed: ref
                        .read(appDependenciesProvider)
                        .camera!
                        .openSettings,
                    child: const Text('ABRIR AJUSTES'),
                  ),
                ],
                if (_cameraError != null)
                  StatusBanner(
                    text: _cameraError!,
                    color: AppColors.danger,
                    icon: Icons.error_outline,
                  ),
                if (proposal == null)
                  FilledButton.icon(
                    key: const Key('capture-photo'),
                    onPressed: _ready && !state.busy ? _capture : null,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('CAPTURAR FOTO'),
                  ),
              ],
            ),
          ),
          if (proposal != null) ...[
            const SizedBox(height: 14),
            SectionCard(
              title: 'Confirmación visual completa',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'TOTALIZADOR',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (proposal.totalizerCrop != null)
                    Image.memory(
                      proposal.totalizerCrop!,
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  Text(
                    'OCR: ${proposal.odometerRaw.isEmpty ? '<no detectado>' : proposal.odometerRaw}',
                  ),
                  Text(
                    'Dígitos: ${proposal.odometerCandidates.isEmpty ? '<ninguno>' : proposal.odometerCandidates.first.digits}',
                  ),
                  if (_visionConfiguration.totalizerConfiguration
                      case final format?) ...[
                    Text('Formato: ${format.pattern} · m³'),
                    Text(
                      proposal.odometerValue == null
                          ? 'Lectura propuesta: no disponible'
                          : 'Lectura propuesta: ${proposal.odometerValue} m³',
                    ),
                  ] else ...[
                    DropdownButtonFormField<int>(
                      key: const Key('totalizer-digit-count'),
                      initialValue: _digitCount,
                      decoration: const InputDecoration(
                        labelText: 'Dígitos totales',
                      ),
                      items: List.generate(8, (index) => index + 1)
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        if (value != null) {
                          _digitCount = value;
                          if (_decimalPlaces >= value) {
                            _decimalPlaces = value - 1;
                          }
                        }
                      }),
                    ),
                    DropdownButtonFormField<int>(
                      key: const Key('totalizer-decimal-places'),
                      initialValue: _decimalPlaces,
                      decoration: const InputDecoration(labelText: 'Decimales'),
                      items: List.generate(_digitCount, (index) => index)
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _decimalPlaces = value ?? 0),
                    ),
                    FilledButton.tonal(
                      key: const Key('confirm-totalizer-format'),
                      onPressed: state.busy
                          ? null
                          : () {
                              final configured = DialVisionConfiguration(
                                totalizerRegion:
                                    _visionConfiguration.totalizerRegion,
                                selectedDial: _visionConfiguration.selectedDial,
                                zeroAngleDegrees:
                                    _visionConfiguration.zeroAngleDegrees,
                                clockwise: _visionConfiguration.clockwise,
                                litersPerRevolution:
                                    _visionConfiguration.litersPerRevolution,
                                multiplier: _visionConfiguration.multiplier,
                                source: _visionConfiguration.source,
                                totalizerConfiguration: TotalizerConfiguration(
                                  digitCount: _digitCount,
                                  decimalPlaces: _decimalPlaces,
                                  source: DialConfigurationSource.autoConfirmed,
                                ),
                              );
                              _visionConfiguration = configured;
                              ref
                                  .read(appControllerProvider.notifier)
                                  .reanalyzeRegions(configured);
                            },
                      child: Text(
                        'CONFIRMAR FORMATO ${_digitCount - _decimalPlaces} ENTEROS · $_decimalPlaces DECIMAL',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'DIAL SELECCIONADO',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (proposal.dialCrop != null)
                    Image.memory(
                      proposal.dialCrop!,
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  Text(
                    'Escala: ×${_visionConfiguration.multiplier} · '
                    '${_visionConfiguration.litersPerRevolution} L/vuelta',
                  ),
                  Text(
                    proposal.needleLiters == null
                        ? 'Aguja no detectada'
                        : 'Aguja detectada: ${proposal.needleLiters!.toStringAsFixed(2)} L',
                  ),
                  for (final warning in proposal.warnings)
                    Text(
                      warning,
                      style: const TextStyle(color: AppColors.warning),
                    ),
                  const SizedBox(height: 10),
                  const Text('¿La lectura es correcta?'),
                  if (_adjustingRegions) ...[
                    const SizedBox(height: 10),
                    _RegionEditor(
                      imagePath: proposal.evidencePath,
                      configuration: _visionConfiguration,
                      onChanged: (value) =>
                          setState(() => _visionConfiguration = value),
                    ),
                    if (proposal.dialCandidates.length > 1) ...[
                      const Text('Candidatos de dial'),
                      Wrap(
                        spacing: 6,
                        children: [
                          for (final candidate in proposal.dialCandidates.skip(
                            1,
                          ))
                            ActionChip(
                              label: Text(candidate.id),
                              onPressed: () {
                                setState(
                                  () => _visionConfiguration =
                                      DialVisionConfiguration(
                                        totalizerRegion: _visionConfiguration
                                            .totalizerRegion,
                                        selectedDial: candidate.geometry,
                                        zeroAngleDegrees: _visionConfiguration
                                            .zeroAngleDegrees,
                                        clockwise:
                                            _visionConfiguration.clockwise,
                                        litersPerRevolution:
                                            _visionConfiguration
                                                .litersPerRevolution,
                                        multiplier:
                                            _visionConfiguration.multiplier,
                                        source: DialConfigurationSource.manual,
                                        totalizerConfiguration:
                                            _visionConfiguration
                                                .totalizerConfiguration,
                                      ),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                    const Text('Tamaño del totalizador'),
                    Slider(
                      value:
                          _visionConfiguration.totalizerRegion.geometry.width,
                      min: .2,
                      max: .9,
                      onChanged: (width) {
                        final r = _visionConfiguration.totalizerRegion.geometry;
                        final safeWidth = width.clamp(.2, 1 - r.left);
                        setState(
                          () => _visionConfiguration = DialVisionConfiguration(
                            totalizerRegion: TotalizerRegion(
                              NormalizedRect(
                                r.left,
                                r.top,
                                safeWidth,
                                (safeWidth * .3).clamp(.08, 1 - r.top),
                              ),
                            ),
                            selectedDial: _visionConfiguration.selectedDial,
                            zeroAngleDegrees:
                                _visionConfiguration.zeroAngleDegrees,
                            clockwise: _visionConfiguration.clockwise,
                            litersPerRevolution:
                                _visionConfiguration.litersPerRevolution,
                            multiplier: _visionConfiguration.multiplier,
                            source: DialConfigurationSource.manual,
                            totalizerConfiguration:
                                _visionConfiguration.totalizerConfiguration,
                          ),
                        );
                      },
                    ),
                    const Text('Tamaño del dial'),
                    Slider(
                      value: _visionConfiguration.selectedDial.radius,
                      min: .08,
                      max: .45,
                      onChanged: (radius) {
                        final c = _visionConfiguration.selectedDial;
                        final safe = radius.clamp(.08, .45);
                        setState(
                          () => _visionConfiguration = DialVisionConfiguration(
                            totalizerRegion:
                                _visionConfiguration.totalizerRegion,
                            selectedDial: NormalizedCircle(
                              c.centerX.clamp(safe, 1 - safe),
                              c.centerY.clamp(safe, 1 - safe),
                              safe,
                            ),
                            zeroAngleDegrees:
                                _visionConfiguration.zeroAngleDegrees,
                            clockwise: _visionConfiguration.clockwise,
                            litersPerRevolution:
                                _visionConfiguration.litersPerRevolution,
                            multiplier: _visionConfiguration.multiplier,
                            source: DialConfigurationSource.manual,
                            totalizerConfiguration:
                                _visionConfiguration.totalizerConfiguration,
                          ),
                        );
                      },
                    ),
                    DropdownButtonFormField<double>(
                      initialValue: _visionConfiguration.multiplier,
                      decoration: const InputDecoration(
                        labelText: 'Escala del dial',
                      ),
                      items: const [1.0, .1, .01, .001]
                          .map(
                            (v) =>
                                DropdownMenuItem(value: v, child: Text('×$v')),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(
                          () => _visionConfiguration = DialVisionConfiguration(
                            totalizerRegion:
                                _visionConfiguration.totalizerRegion,
                            selectedDial: _visionConfiguration.selectedDial,
                            zeroAngleDegrees:
                                _visionConfiguration.zeroAngleDegrees,
                            clockwise: _visionConfiguration.clockwise,
                            multiplier: value,
                            litersPerRevolution: 100 * value,
                            source: DialConfigurationSource.manual,
                            totalizerConfiguration:
                                _visionConfiguration.totalizerConfiguration,
                          ),
                        );
                      },
                    ),
                    FilledButton.tonal(
                      onPressed: state.busy
                          ? null
                          : () => ref
                                .read(appControllerProvider.notifier)
                                .reanalyzeRegions(_visionConfiguration),
                      child: const Text('REANALIZAR'),
                    ),
                  ],
                  if (_manualCorrection) ...[
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('camera-odometer-correction'),
                      controller: _odometer,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Odómetro confirmado',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('camera-needle-correction'),
                      controller: _needle,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Aguja confirmada (L)',
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  FilledButton(
                    key: const Key('confirm-camera-reading'),
                    onPressed: () {
                      final odometer = double.tryParse(_odometer.text);
                      final needle = double.tryParse(_needle.text);
                      if (odometer == null || needle == null) {
                        setState(() => _manualCorrection = true);
                        return;
                      }
                      ref
                          .read(appControllerProvider.notifier)
                          .confirmCameraReading(
                            odometer: odometer,
                            needle: needle,
                            corrected: _manualCorrection,
                          );
                    },
                    child: const Text('CORRECTA'),
                  ),
                  OutlinedButton(
                    onPressed: () => setState(() => _manualCorrection = true),
                    child: const Text('CORREGIR'),
                  ),
                  OutlinedButton(
                    key: const Key('adjust-regions'),
                    onPressed: () =>
                        setState(() => _adjustingRegions = !_adjustingRegions),
                    child: const Text('AJUSTAR REGIONES'),
                  ),
                  TextButton(
                    key: const Key('recapture-photo'),
                    onPressed: () async {
                      await ref
                          .read(appControllerProvider.notifier)
                          .recapturePhoto();
                      await ref.read(appDependenciesProvider).camera!.resume();
                      _odometer.clear();
                      _needle.clear();
                      if (mounted) {
                        setState(() {
                          _manualCorrection = false;
                          _ready = true;
                        });
                      }
                    },
                    child: const Text('REPETIR FOTO'),
                  ),
                ],
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
        ],
      ),
    );
  }
}

final class _RegionEditor extends StatelessWidget {
  const _RegionEditor({
    required this.imagePath,
    required this.configuration,
    required this.onChanged,
  });
  final String imagePath;
  final DialVisionConfiguration configuration;
  final ValueChanged<DialVisionConfiguration> onChanged;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 3 / 4,
    child: LayoutBuilder(
      builder: (context, box) {
        final rect = configuration.totalizerRegion.geometry;
        final dial = configuration.selectedDial;
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(imagePath), fit: BoxFit.fill),
            Positioned(
              left: rect.left * box.maxWidth,
              top: rect.top * box.maxHeight,
              width: rect.width * box.maxWidth,
              height: rect.height * box.maxHeight,
              child: GestureDetector(
                onPanUpdate: (d) => onChanged(
                  _copy(
                    totalizer: TotalizerRegion(
                      NormalizedRect(
                        (rect.left + d.delta.dx / box.maxWidth).clamp(
                          0,
                          1 - rect.width,
                        ),
                        (rect.top + d.delta.dy / box.maxHeight).clamp(
                          0,
                          1 - rect.height,
                        ),
                        rect.width,
                        rect.height,
                      ),
                    ),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber, width: 3),
                  ),
                ),
              ),
            ),
            Positioned(
              left: (dial.centerX - dial.radius) * box.maxWidth,
              top: (dial.centerY - dial.radius) * box.maxHeight,
              width: dial.radius * 2 * box.maxWidth,
              height: dial.radius * 2 * box.maxHeight,
              child: GestureDetector(
                onPanUpdate: (d) => onChanged(
                  _copy(
                    dial: NormalizedCircle(
                      (dial.centerX + d.delta.dx / box.maxWidth).clamp(
                        dial.radius,
                        1 - dial.radius,
                      ),
                      (dial.centerY + d.delta.dy / box.maxHeight).clamp(
                        dial.radius,
                        1 - dial.radius,
                      ),
                      dial.radius,
                    ),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.success, width: 3),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  DialVisionConfiguration _copy({
    TotalizerRegion? totalizer,
    NormalizedCircle? dial,
  }) => DialVisionConfiguration(
    totalizerRegion: totalizer ?? configuration.totalizerRegion,
    selectedDial: dial ?? configuration.selectedDial,
    zeroAngleDegrees: configuration.zeroAngleDegrees,
    clockwise: configuration.clockwise,
    litersPerRevolution: configuration.litersPerRevolution,
    multiplier: configuration.multiplier,
    source: DialConfigurationSource.manual,
    totalizerConfiguration: configuration.totalizerConfiguration,
  );
}

final class _DialGuide extends StatelessWidget {
  const _DialGuide();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Center(
      child: FractionallySizedBox(
        widthFactor: .84,
        heightFactor: .68,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.success, width: 3),
          ),
          child: const Center(
            child: Icon(Icons.add, color: AppColors.success, size: 28),
          ),
        ),
      ),
    ),
  );
}

String _captureTitle(CapturePurpose? purpose) => switch (purpose) {
  CapturePurpose.start => 'Evidencia START',
  CapturePurpose.intermediate => 'Evidencia INTERMEDIATE',
  CapturePurpose.finalEvidence => 'Evidencia FINAL',
  null => 'Cámara',
};
