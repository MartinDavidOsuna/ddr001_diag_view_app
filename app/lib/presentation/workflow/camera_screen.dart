import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../infrastructure/camera/camera_models.dart';
import '../../infrastructure/camera/camera_port.dart';
import '../../infrastructure/vision/vision_models.dart';
import '../../domain/models.dart';
import '../app_controller.dart';
import '../common/app_scaffold.dart';
import '../common/meter_face_region_editor.dart';

final class CameraCaptureScreen extends ConsumerStatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  ConsumerState<CameraCaptureScreen> createState() =>
      _CameraCaptureScreenState();
}

final class _CameraCaptureScreenState extends ConsumerState<CameraCaptureScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraPermissionState? _permission;
  bool _ready = false;
  bool _initializing = false;
  String? _cameraError;
  final _odometer = TextEditingController();
  final _needle = TextEditingController();
  final _dialScale = TextEditingController();
  bool _manualCorrection = false;
  bool _adjustingRegions = false;
  bool _editingRegions = false;
  Timer? _liveReadingTimer;
  bool _liveReadingInProgress = false;
  late final AnimationController _liveValueFade;
  MeterFaceEditTarget _editTarget = MeterFaceEditTarget.totalizer;
  DateTime? _loadedProposalAt;
  late DialVisionConfiguration _visionConfiguration;
  int _digitCount = 6;
  int _decimalPlaces = 0;
  double _minimumZoom = 1;
  double _maximumZoom = 1;
  double _zoomLevel = 1;
  double _zoomAtGestureStart = 1;
  Offset? _focusPoint;
  final GlobalKey _previewKey = GlobalKey();
  bool _automaticRegionAttempted = false;
  bool _automaticRegionInProgress = false;
  final Set<String> _triedSuggestionIds = <String>{};
  List<DialCandidate> _suggestedDials = const [];

  late final CameraPort? _sharedCamera;
  AppPage _currentPage = AppPage.camera;

  @override
  void initState() {
    super.initState();
    _sharedCamera = ref.read(appDependenciesProvider).camera;
    ref.listenManual(
      appControllerProvider,
      (_, next) => _currentPage = next.page,
    );
    final face = ref.read(appControllerProvider).sample?.meterFaceConfiguration;
    final appState = ref.read(appControllerProvider);
    _digitCount =
        appState.totalizerIntegerDigits + appState.totalizerDecimalPlaces;
    _decimalPlaces = appState.totalizerDecimalPlaces;
    _visionConfiguration = face == null
        ? DialVisionConfiguration(
            litersPerRevolution: appState.needleLitersPerRevolution,
            multiplier: dialMultiplierForLitersPerRevolution(
              appState.needleLitersPerRevolution,
            ),
            totalizerConfiguration: TotalizerConfiguration(
              digitCount: _digitCount,
              decimalPlaces: _decimalPlaces,
            ),
          )
        : DialVisionConfiguration.fromDomain(face);
    _dialScale.text = _formatDialScale(
      _visionConfiguration.litersPerRevolution,
    );
    _automaticRegionAttempted = face != null;
    _liveValueFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
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
      _minimumZoom = await camera.getMinZoomLevel();
      _maximumZoom = await camera.getMaxZoomLevel();
      _zoomLevel = ref
          .read(appControllerProvider)
          .cameraZoomLevel
          .clamp(_minimumZoom, _maximumZoom);
      await camera.setZoomLevel(_zoomLevel);
      if (mounted) {
        setState(() => _ready = true);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _attemptAutomaticRegions(),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _cameraError = 'No fue posible iniciar la cámara.');
      }
    } finally {
      _initializing = false;
    }
  }

  Future<void> _setZoom(double value) async {
    final next = value.clamp(_minimumZoom, _maximumZoom).toDouble();
    if ((next - _zoomLevel).abs() < .001) return;
    setState(() => _zoomLevel = next);
    final camera = ref.read(appDependenciesProvider).camera;
    await camera?.setZoomLevel(next);
    await ref.read(appControllerProvider.notifier).setCameraZoom(next);
  }

  Future<void> _stepZoom(int direction) async {
    final range = _maximumZoom - _minimumZoom;
    final step = math.max(.1, range / 20);
    await _setZoom(_zoomLevel + direction * step);
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
    _liveReadingTimer?.cancel();
    _liveValueFade.dispose();
    _odometer.dispose();
    _needle.dispose();
    _dialScale.dispose();
    // The run screen inherits the warm camera. Disposing it here would reopen
    // the sensor on INICIAR and move the START photograph several seconds late.
    if (_currentPage != AppPage.run) {
      unawaited(_sharedCamera?.pause());
    }
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

  Future<void> _repeatPhoto(WidgetRef ref) async {
    await ref.read(appControllerProvider.notifier).recapturePhoto();
    await ref.read(appDependenciesProvider).camera!.resume();
    _odometer.clear();
    _needle.clear();
    if (mounted) {
      setState(() {
        _manualCorrection = false;
        _adjustingRegions = false;
        _ready = true;
      });
    }
  }

  Widget _dialScaleField({required Key key}) => TextFormField(
    key: key,
    controller: _dialScale,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: const InputDecoration(
      labelText: 'Escala del dial (L/vuelta)',
      helperText: 'Use el valor real configurado en Preparación.',
    ),
    onChanged: (text) {
      final value = double.tryParse(text.trim().replaceAll(',', '.'));
      if (value == null || !value.isFinite || value <= 0) return;
      setState(() {
        _visionConfiguration = _copyConfiguration(
          _visionConfiguration,
          multiplier: dialMultiplierForLitersPerRevolution(value),
          litersPerRevolution: value,
        );
      });
    },
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final proposal = state.readingProposal;
    final livePreparation =
        state.capturePurpose == CapturePurpose.cameraPreparation;
    if (proposal != null && _loadedProposalAt != proposal.createdAt) {
      _loadedProposalAt = proposal.createdAt;
      _visionConfiguration = proposal.configuration;
      _digitCount =
          proposal.configuration.totalizerConfiguration?.digitCount ??
          (proposal.odometerCandidates.isEmpty
              ? 5
              : proposal.odometerCandidates.first.digits.length);
      _decimalPlaces =
          proposal.configuration.totalizerConfiguration?.decimalPlaces ?? 0;
      final odometerText = proposal.odometerValue?.toString() ?? '';
      final needleText = proposal.needleLiters?.toStringAsFixed(2) ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _loadedProposalAt != proposal.createdAt) return;
        _odometer.text = odometerText;
        _needle.text = needleText;
        _dialScale.text = _formatDialScale(
          proposal.configuration.litersPerRevolution,
        );
      });
      _manualCorrection =
          proposal.analysisCompleted &&
          (proposal.odometerValue == null ||
              proposal.needleLiters == null ||
              (proposal.totalizerReadingProposal?.requiresConfirmation ??
                  false));
      _adjustingRegions = !proposal.analysisCompleted;
      _editingRegions = !proposal.analysisCompleted;
    }
    if (!livePreparation && _editingRegions && proposal != null) {
      _ensureLiveReadingTimer();
    } else {
      _liveReadingTimer?.cancel();
      _liveReadingTimer = null;
    }
    return AppScaffold(
      title: _captureTitle(state.capturePurpose),
      scrollable: !livePreparation && !_editingRegions,
      child: livePreparation
          ? _buildLiveCameraPreparation(state)
          : _editingRegions && proposal != null
          ? _buildRegionEditingMode(proposal, state)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  title: '3 · Carátula para leer y evidencia',
                  child: proposal != null
                      ? const Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.success),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Fotografía capturada. Regiones fijadas; continúe con ANALIZAR LECTURA.',
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              state.capturePurpose ==
                                      CapturePurpose.cameraPreparation
                                  ? 'Centre la carátula dentro de la guía. Esta fotografía configura zoom y regiones; no es la evidencia INICIO.'
                                  : 'Centre la carátula dentro de la guía. La fotografía se guardará como evidencia y se analizará.',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            if (_ready && _maximumZoom > _minimumZoom)
                              Row(
                                children: [
                                  IconButton(
                                    key: const Key('camera-zoom-out'),
                                    tooltip: 'Disminuir zoom',
                                    onPressed: _zoomLevel <= _minimumZoom
                                        ? null
                                        : () => _stepZoom(-1),
                                    icon: const Icon(Icons.zoom_out, size: 18),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      key: const Key('camera-zoom'),
                                      value: _zoomLevel,
                                      min: _minimumZoom,
                                      max: _maximumZoom,
                                      onChanged: _setZoom,
                                    ),
                                  ),
                                  IconButton(
                                    key: const Key('camera-zoom-in'),
                                    tooltip: 'Aumentar zoom',
                                    onPressed: _zoomLevel >= _maximumZoom
                                        ? null
                                        : () => _stepZoom(1),
                                    icon: const Icon(Icons.zoom_in, size: 18),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 12),
                            AspectRatio(
                              aspectRatio: ref
                                  .read(appDependenciesProvider)
                                  .camera!
                                  .previewAspectRatio,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.card,
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (_ready)
                                      GestureDetector(
                                        key: _previewKey,
                                        behavior: HitTestBehavior.opaque,
                                        onTapDown: (details) async {
                                          final box = _previewKey.currentContext
                                              ?.findRenderObject();
                                          if (box is! RenderBox) return;
                                          final size = box.size;
                                          final normalized = Offset(
                                            (details.localPosition.dx /
                                                    size.width)
                                                .clamp(0.0, 1.0),
                                            (details.localPosition.dy /
                                                    size.height)
                                                .clamp(0.0, 1.0),
                                          );
                                          setState(
                                            () => _focusPoint = normalized,
                                          );
                                          await ref
                                              .read(appDependenciesProvider)
                                              .camera!
                                              .focusAt(
                                                x: normalized.dx,
                                                y: normalized.dy,
                                              );
                                          await Future<void>.delayed(
                                            const Duration(milliseconds: 900),
                                          );
                                          if (mounted &&
                                              _focusPoint == normalized) {
                                            setState(() => _focusPoint = null);
                                          }
                                        },
                                        onScaleStart: (_) =>
                                            _zoomAtGestureStart = _zoomLevel,
                                        onScaleUpdate: (details) async {
                                          final next =
                                              (_zoomAtGestureStart *
                                                      details.scale)
                                                  .clamp(
                                                    _minimumZoom,
                                                    _maximumZoom,
                                                  );
                                          if ((next - _zoomLevel).abs() < .02) {
                                            return;
                                          }
                                          setState(() => _zoomLevel = next);
                                          await ref
                                              .read(appDependenciesProvider)
                                              .camera!
                                              .setZoomLevel(next);
                                        },
                                        onScaleEnd: (_) => ref
                                            .read(
                                              appControllerProvider.notifier,
                                            )
                                            .setCameraZoom(_zoomLevel),
                                        child: ref
                                            .read(appDependenciesProvider)
                                            .camera!
                                            .buildPreview(),
                                      )
                                    else
                                      const ColoredBox(color: Colors.black),
                                    const _DialGuide(),
                                    if (_focusPoint case final point?)
                                      Align(
                                        alignment: Alignment(
                                          point.dx * 2 - 1,
                                          point.dy * 2 - 1,
                                        ),
                                        child: const IgnorePointer(
                                          child: Icon(
                                            Icons.filter_center_focus,
                                            color: Colors.amber,
                                            size: 48,
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: const Color(0x99000000),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            '${_zoomLevel.toStringAsFixed(1)}×',
                                          ),
                                        ),
                                      ),
                                    ),
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
                            if (_permission ==
                                CameraPermissionState.permanentlyDenied) ...[
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
                                onPressed: _ready && !state.busy
                                    ? _capture
                                    : null,
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: const Text('CAPTURAR FOTO'),
                              ),
                          ],
                        ),
                ),
                if (proposal != null) ...[
                  const SizedBox(height: 14),
                  SectionCard(
                    title: proposal.analysisCompleted
                        ? 'Confirmación visual completa'
                        : 'CONFIGURAR LECTURA',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!proposal.analysisCompleted) ...[
                          const Text(
                            'Antes de analizar, marque manualmente en esta fotografía el totalizador y el único dial que utilizará.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Seleccione únicamente los dígitos del totalizador',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Text(
                            'Mueva el rectángulo ámbar y use su control cuadrado para redimensionarlo.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Seleccione el dial de mayor resolución que utilizará para la lectura',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Text(
                            'Mueva el círculo verde y use su control para cambiar el tamaño. La app no elige entre los diales.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            key: const Key('edit-regions'),
                            onPressed: () =>
                                setState(() => _editingRegions = true),
                            icon: const Icon(Icons.crop_free),
                            label: const Text('EDITAR REGIONES'),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            key: const Key('manual-totalizer-digit-count'),
                            initialValue: _digitCount,
                            decoration: const InputDecoration(
                              labelText: 'Dígitos totales del totalizador',
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
                              if (value == null) return;
                              _digitCount = value;
                              if (_decimalPlaces >= value) {
                                _decimalPlaces = value - 1;
                              }
                            }),
                          ),
                          DropdownButtonFormField<int>(
                            key: const Key('manual-totalizer-decimal-places'),
                            initialValue: _decimalPlaces.clamp(
                              0,
                              _digitCount - 1,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Decimales del totalizador',
                            ),
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
                          _dialScaleField(key: const Key('manual-dial-scale')),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            key: const Key('analyze-reading'),
                            onPressed: state.busy
                                ? null
                                : () {
                                    final configured = _copyConfiguration(
                                      _visionConfiguration,
                                      totalizerConfiguration:
                                          TotalizerConfiguration(
                                            digitCount: _digitCount,
                                            decimalPlaces: _decimalPlaces,
                                            source:
                                                DialConfigurationSource.manual,
                                          ),
                                    );
                                    _visionConfiguration = configured;
                                    ref
                                        .read(appControllerProvider.notifier)
                                        .reanalyzeRegions(configured);
                                  },
                            icon: const Icon(Icons.document_scanner_outlined),
                            label: const Text('ANALIZAR LECTURA'),
                          ),
                          TextButton(
                            key: const Key('recapture-unanalysed-photo'),
                            onPressed: () => _repeatPhoto(ref),
                            child: const Text('REPETIR FOTO'),
                          ),
                        ],
                        if (proposal.analysisCompleted) ...[
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
                            'Lectura: ${proposal.totalizerReadingProposal?.candidate.digits ?? proposal.odometerCandidates.firstOrNull?.digits ?? '<no detectado>'}',
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
                              decoration: const InputDecoration(
                                labelText: 'Decimales',
                              ),
                              items:
                                  List.generate(_digitCount, (index) => index)
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
                                      final configured =
                                          DialVisionConfiguration(
                                            totalizerRegion:
                                                _visionConfiguration
                                                    .totalizerRegion,
                                            selectedDial: _visionConfiguration
                                                .selectedDial,
                                            zeroAngleDegrees:
                                                _visionConfiguration
                                                    .zeroAngleDegrees,
                                            clockwise:
                                                _visionConfiguration.clockwise,
                                            litersPerRevolution:
                                                _visionConfiguration
                                                    .litersPerRevolution,
                                            multiplier:
                                                _visionConfiguration.multiplier,
                                            source: _visionConfiguration.source,
                                            totalizerConfiguration:
                                                TotalizerConfiguration(
                                                  digitCount: _digitCount,
                                                  decimalPlaces: _decimalPlaces,
                                                  source:
                                                      DialConfigurationSource
                                                          .autoConfirmed,
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
                            MeterFaceRegionEditor(
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
                                  for (final candidate
                                      in proposal.dialCandidates.skip(1))
                                    ActionChip(
                                      label: Text(candidate.id),
                                      onPressed: () {
                                        setState(
                                          () => _visionConfiguration =
                                              DialVisionConfiguration(
                                                totalizerRegion:
                                                    _visionConfiguration
                                                        .totalizerRegion,
                                                selectedDial:
                                                    candidate.geometry,
                                                zeroAngleDegrees:
                                                    _visionConfiguration
                                                        .zeroAngleDegrees,
                                                clockwise: _visionConfiguration
                                                    .clockwise,
                                                litersPerRevolution:
                                                    _visionConfiguration
                                                        .litersPerRevolution,
                                                multiplier: _visionConfiguration
                                                    .multiplier,
                                                source: DialConfigurationSource
                                                    .manual,
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
                              value: _visionConfiguration
                                  .totalizerRegion
                                  .geometry
                                  .width,
                              min: .2,
                              max: .9,
                              onChanged: (width) {
                                final r = _visionConfiguration
                                    .totalizerRegion
                                    .geometry;
                                final safeWidth = width.clamp(.2, 1 - r.left);
                                setState(
                                  () => _visionConfiguration =
                                      DialVisionConfiguration(
                                        totalizerRegion: TotalizerRegion(
                                          NormalizedRect(
                                            r.left,
                                            r.top,
                                            safeWidth,
                                            (safeWidth * .3).clamp(
                                              .08,
                                              1 - r.top,
                                            ),
                                          ),
                                        ),
                                        selectedDial:
                                            _visionConfiguration.selectedDial,
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
                            const Text('Tamaño del dial'),
                            Slider(
                              value: _visionConfiguration.selectedDial.radius,
                              min: .08,
                              max: .45,
                              onChanged: (radius) {
                                final c = _visionConfiguration.selectedDial;
                                final safe = radius.clamp(.08, .45);
                                setState(
                                  () => _visionConfiguration =
                                      DialVisionConfiguration(
                                        totalizerRegion: _visionConfiguration
                                            .totalizerRegion,
                                        selectedDial: NormalizedCircle(
                                          c.centerX.clamp(safe, 1 - safe),
                                          c.centerY.clamp(safe, 1 - safe),
                                          safe,
                                        ),
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
                            _dialScaleField(
                              key: const Key('analyzed-dial-scale'),
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
                              keyboardType:
                                  const TextInputType.numberWithOptions(
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
                              keyboardType:
                                  const TextInputType.numberWithOptions(
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
                            onPressed: () =>
                                setState(() => _manualCorrection = true),
                            child: const Text('CORREGIR'),
                          ),
                          OutlinedButton(
                            key: const Key('adjust-regions'),
                            onPressed: () => setState(() {
                              _adjustingRegions = false;
                              _editingRegions = true;
                            }),
                            child: const Text('AJUSTAR REGIONES'),
                          ),
                          TextButton(
                            key: const Key('recapture-photo'),
                            onPressed: () async {
                              await ref
                                  .read(appControllerProvider.notifier)
                                  .recapturePhoto();
                              await ref
                                  .read(appDependenciesProvider)
                                  .camera!
                                  .resume();
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

  void _ensureLiveReadingTimer() {
    if (_liveReadingTimer != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final livePreparation =
          ref.read(appControllerProvider).capturePurpose ==
          CapturePurpose.cameraPreparation;
      if (!mounted ||
          (!livePreparation && !_editingRegions) ||
          _liveReadingTimer != null) {
        return;
      }
      _runLiveReading();
      _liveReadingTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _runLiveReading(),
      );
    });
  }

  Future<void> _runLiveReading() async {
    if (!mounted || _liveReadingInProgress) return;
    final livePreparation =
        ref.read(appControllerProvider).capturePurpose ==
        CapturePurpose.cameraPreparation;
    if (livePreparation) {
      await _runLiveCameraReading();
      return;
    }
    if (!_editingRegions) return;
    _liveReadingInProgress = true;
    if (mounted) setState(() {});
    try {
      await ref
          .read(appControllerProvider.notifier)
          .previewRegionReadings(_visionConfiguration);
      _loadedProposalAt = ref
          .read(appControllerProvider)
          .readingProposal
          ?.createdAt;
    } catch (_) {
      // Live preview is advisory and must never interrupt region editing.
    } finally {
      _liveReadingInProgress = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _runLiveCameraReading() async {
    // Live image interpretation is intentionally disabled. Camera preparation
    // only stores technician-positioned regions.
  }

  Future<void> _attemptAutomaticRegions({bool force = false}) async {
    if (!mounted ||
        (_automaticRegionAttempted && !force) ||
        _automaticRegionInProgress ||
        ref.read(appControllerProvider).capturePurpose !=
            CapturePurpose.cameraPreparation) {
      return;
    }
    final dependencies = ref.read(appDependenciesProvider);
    final camera = dependencies.camera;
    final pipeline = dependencies.visualPipeline;
    if (camera is! LiveCameraAnalysisPort || pipeline == null) return;
    final liveCamera = camera as LiveCameraAnalysisPort;
    _automaticRegionAttempted = true;
    _automaticRegionInProgress = true;
    if (mounted) setState(() {});
    String? framePath;
    try {
      final capturedPath = await liveCamera.captureAnalysisFrame();
      framePath = capturedPath;
      final suggestion = await pipeline.prepare(
        evidenceId: 'camera-region-suggestion',
        evidencePath: capturedPath,
      );
      if (!mounted) return;
      final candidates = suggestion.dialCandidates;
      var suggestedDial = suggestion.configuration.selectedDial;
      if (force && candidates.isNotEmpty) {
        var alternatives = candidates
            .where(
              (candidate) =>
                  !_triedSuggestionIds.contains(candidate.id) &&
                  !_sameCircle(
                    candidate.geometry,
                    _visionConfiguration.selectedDial,
                  ),
            )
            .toList();
        if (alternatives.isEmpty) {
          _triedSuggestionIds.clear();
          alternatives = candidates
              .where(
                (candidate) => !_sameCircle(
                  candidate.geometry,
                  _visionConfiguration.selectedDial,
                ),
              )
              .toList();
        }
        if (alternatives.isNotEmpty) {
          final next = alternatives.first;
          _triedSuggestionIds.add(next.id);
          suggestedDial = next.geometry;
        }
      }
      setState(() {
        _visionConfiguration = DialVisionConfiguration(
          totalizerRegion: suggestion.configuration.totalizerRegion,
          selectedDial: suggestedDial,
          zeroAngleDegrees: _visionConfiguration.zeroAngleDegrees,
          clockwise: _visionConfiguration.clockwise,
          litersPerRevolution: _visionConfiguration.litersPerRevolution,
          multiplier: _visionConfiguration.multiplier,
          source: DialConfigurationSource.manual,
          totalizerConfiguration: _visionConfiguration.totalizerConfiguration,
        );
        _suggestedDials = suggestion.dialCandidates;
      });
    } catch (_) {
      // La sugerencia es opcional; la selecciÃ³n manual siempre permanece.
    } finally {
      await liveCamera.stopAnalysisFrames();
      if (framePath != null) {
        try {
          await File(framePath).delete();
        } catch (_) {
          // Archivo temporal ya retirado por el sistema.
        }
      }
      _automaticRegionInProgress = false;
      if (mounted) setState(() {});
    }
  }

  bool _sameCircle(NormalizedCircle a, NormalizedCircle b) =>
      (a.centerX - b.centerX).abs() < .01 &&
      (a.centerY - b.centerY).abs() < .01 &&
      (a.radius - b.radius).abs() < .01;

  Widget _buildLiveCameraPreparation(AppViewState state) {
    final camera = ref.read(appDependenciesProvider).camera;
    if (camera == null || !_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      key: const Key('live-camera-preparation'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Ajuste las guías directamente sobre la cámara. Esta etapa no toma ni guarda una fotografía.',
          style: TextStyle(color: AppColors.muted),
        ),
        if (_maximumZoom > _minimumZoom)
          Row(
            children: [
              IconButton(
                key: const Key('live-camera-zoom-out'),
                tooltip: 'Disminuir zoom',
                onPressed: _zoomLevel <= _minimumZoom
                    ? null
                    : () => _stepZoom(-1),
                icon: const Icon(Icons.zoom_out, size: 18),
              ),
              Expanded(
                child: Slider(
                  key: const Key('live-camera-zoom'),
                  value: _zoomLevel,
                  min: _minimumZoom,
                  max: _maximumZoom,
                  onChanged: _setZoom,
                ),
              ),
              IconButton(
                key: const Key('live-camera-zoom-in'),
                tooltip: 'Aumentar zoom',
                onPressed: _zoomLevel >= _maximumZoom
                    ? null
                    : () => _stepZoom(1),
                icon: const Icon(Icons.zoom_in, size: 18),
              ),
            ],
          ),
        const Text(
          'Las regiones se usarán para presentar los recortes al terminar la prueba. No se realizará lectura automática.',
          style: TextStyle(color: AppColors.heading),
        ),
        const SizedBox(height: 8),
        SegmentedButton<MeterFaceEditTarget>(
          segments: const [
            ButtonSegment(
              value: MeterFaceEditTarget.totalizer,
              label: Text('TOTALIZADOR'),
            ),
            ButtonSegment(value: MeterFaceEditTarget.dial, label: Text('DIAL')),
          ],
          selected: {_editTarget},
          onSelectionChanged: (value) =>
              setState(() => _editTarget = value.single),
        ),
        const SizedBox(height: 8),
        if (_automaticRegionInProgress)
          const Text(
            'Buscando regiones sugeridas…',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        OutlinedButton.icon(
          key: const Key('refresh-camera-region-suggestions'),
          onPressed: _automaticRegionInProgress
              ? null
              : () => _attemptAutomaticRegions(force: true),
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('NUEVA SUGERENCIA DE REGIONES'),
        ),
        const SizedBox(height: 8),
        if (_suggestedDials.isNotEmpty)
          Wrap(
            spacing: 6,
            children: _suggestedDials
                .map(
                  (candidate) => ActionChip(
                    key: Key('live-dial-candidate-${candidate.id}'),
                    label: Text('DIAL ${candidate.id.split('-').last}'),
                    onPressed: () => setState(() {
                      _editTarget = MeterFaceEditTarget.dial;
                      _visionConfiguration = DialVisionConfiguration(
                        totalizerRegion: _visionConfiguration.totalizerRegion,
                        selectedDial: candidate.geometry,
                        zeroAngleDegrees: _visionConfiguration.zeroAngleDegrees,
                        clockwise: _visionConfiguration.clockwise,
                        litersPerRevolution:
                            _visionConfiguration.litersPerRevolution,
                        multiplier: _visionConfiguration.multiplier,
                        source: DialConfigurationSource.manual,
                        totalizerConfiguration:
                            _visionConfiguration.totalizerConfiguration,
                      );
                    }),
                  ),
                )
                .toList(),
          ),
        if (_suggestedDials.isNotEmpty) const SizedBox(height: 8),
        Expanded(
          child: Center(
            child: MeterFaceRegionEditor.live(
              preview: camera.buildPreview(),
              aspectRatio: camera.previewAspectRatio,
              configuration: _visionConfiguration,
              target: _editTarget,
              onChanged: (value) =>
                  setState(() => _visionConfiguration = value),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const Key('finish-live-camera-preparation'),
          onPressed: state.busy
              ? null
              : () => ref
                    .read(appControllerProvider.notifier)
                    .confirmLiveCameraPreparation(_visionConfiguration),
          icon: const Icon(Icons.check),
          label: const Text('FIJAR REGIONES'),
        ),
      ],
    );
  }

  Widget _buildRegionEditingMode(
    VisualReadingProposal proposal,
    AppViewState state,
  ) => Column(
    key: const Key('fixed-region-editor'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const StatusBanner(
        text:
            'MODO EDICIÓN: la fotografía queda fija. Arrastre cada selector o su control de tamaño.',
        color: AppColors.warning,
        icon: Icons.touch_app_outlined,
      ),
      const SizedBox(height: 8),
      const Text(
        'Rectángulo ámbar: solo los dígitos del totalizador. Círculo verde: el dial que utilizará.',
        style: TextStyle(color: AppColors.muted),
      ),
      const SizedBox(height: 8),
      Container(
        key: const Key('live-region-readings'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.heading.withValues(alpha: .12),
          border: Border.all(color: AppColors.heading.withValues(alpha: .7)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _LiveReadingValue(
                label: 'TOTALIZADOR',
                value: _liveTotalizerValue(proposal),
              ),
            ),
            Container(
              width: 1,
              height: 38,
              color: AppColors.heading.withValues(alpha: .45),
            ),
            Expanded(
              child: _LiveReadingValue(
                label: 'DIAL',
                value: proposal.needleLiters == null
                    ? 'NO DETECTADO'
                    : '${proposal.needleLiters!.toStringAsFixed(2)} L',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      SegmentedButton<MeterFaceEditTarget>(
        segments: const [
          ButtonSegment(
            value: MeterFaceEditTarget.totalizer,
            label: Text('TOTALIZADOR'),
          ),
          ButtonSegment(value: MeterFaceEditTarget.dial, label: Text('DIAL')),
        ],
        selected: {_editTarget},
        onSelectionChanged: (value) =>
            setState(() => _editTarget = value.single),
      ),
      if (proposal.dialCandidates.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: proposal.dialCandidates
              .map(
                (candidate) => ActionChip(
                  key: Key('dial-candidate-${candidate.id}'),
                  label: Text('DIAL ${candidate.id.split('-').last}'),
                  onPressed: () => setState(() {
                    _editTarget = MeterFaceEditTarget.dial;
                    _visionConfiguration = DialVisionConfiguration(
                      totalizerRegion: _visionConfiguration.totalizerRegion,
                      selectedDial: candidate.geometry,
                      zeroAngleDegrees: _visionConfiguration.zeroAngleDegrees,
                      clockwise: _visionConfiguration.clockwise,
                      litersPerRevolution:
                          _visionConfiguration.litersPerRevolution,
                      multiplier: _visionConfiguration.multiplier,
                      source: DialConfigurationSource.manual,
                      totalizerConfiguration:
                          _visionConfiguration.totalizerConfiguration,
                    );
                  }),
                ),
              )
              .toList(),
        ),
      ],
      const SizedBox(height: 8),
      Expanded(
        child: Center(
          child: MeterFaceRegionEditor(
            imagePath: proposal.evidencePath,
            configuration: _visionConfiguration,
            target: _editTarget,
            onChanged: (value) => setState(() => _visionConfiguration = value),
          ),
        ),
      ),
      const SizedBox(height: 8),
      FilledButton.icon(
        key: const Key('finish-region-editing'),
        onPressed: state.busy
            ? null
            : () {
                if (proposal.analysisCompleted) {
                  setState(() {
                    _editingRegions = false;
                    _adjustingRegions = false;
                  });
                  ref
                      .read(appControllerProvider.notifier)
                      .reanalyzeRegions(_visionConfiguration);
                } else {
                  setState(() => _editingRegions = false);
                }
              },
        icon: Icon(
          proposal.analysisCompleted
              ? Icons.document_scanner_outlined
              : Icons.check,
        ),
        label: Text(
          proposal.analysisCompleted
              ? 'APLICAR Y REANALIZAR'
              : 'FIJAR REGIONES',
        ),
      ),
    ],
  );

  String _liveTotalizerValue(VisualReadingProposal proposal) {
    final digits =
        proposal.totalizerReadingProposal?.candidate.digits ??
        proposal.odometerCandidates.firstOrNull?.digits;
    if (digits != null && digits.isNotEmpty) return digits;
    final value = proposal.odometerValue;
    return value == null ? 'NO DETECTADO' : value.toString();
  }
}

final class _LiveReadingValue extends StatelessWidget {
  const _LiveReadingValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        key: Key('live-reading-value-$label'),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.heading,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

// Legacy display retained for historical photo review only.
// ignore: unused_element
final class _LiveReadingsPanel extends StatelessWidget {
  const _LiveReadingsPanel({required this.proposal});

  final VisualReadingProposal? proposal;

  @override
  Widget build(BuildContext context) {
    final current = proposal;
    final configuredValue = current?.totalizerReadingProposal?.value;
    final digits = current?.odometerCandidates.firstOrNull?.digits;
    final totalizer = configuredValue != null
        ? '${configuredValue.toStringAsFixed(current!.totalizerReadingProposal!.configuration.decimalPlaces)} m³'
        : digits?.isNotEmpty == true
        ? digits!
        : current == null
        ? 'ANALIZANDO…'
        : 'NO DETECTADO';
    final dial = current?.needleLiters == null
        ? (current == null ? 'ANALIZANDO…' : 'NO DETECTADO')
        : '${current!.needleLiters!.toStringAsFixed(2)} L';
    return Container(
      key: const Key('live-camera-readings'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.heading.withValues(alpha: .12),
        border: Border.all(color: AppColors.heading.withValues(alpha: .7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LiveReadingValue(label: 'TOTALIZADOR', value: totalizer),
          ),
          Container(
            width: 1,
            height: 38,
            color: AppColors.heading.withValues(alpha: .45),
          ),
          Expanded(
            child: _LiveReadingValue(label: 'DIAL', value: dial),
          ),
        ],
      ),
    );
  }
}

// Kept temporarily as the Stage 4 reference implementation while the shared
// editor is exercised by both production capture and DEBUG calibration.
// ignore: unused_element
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
        final dialRadiusY = dial.radius * box.maxWidth / box.maxHeight;
        final dialDiameter = dial.radius * 2 * box.maxWidth;
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(imagePath), fit: BoxFit.contain),
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
                  child: const Align(
                    alignment: Alignment.topLeft,
                    child: ColoredBox(
                      color: Colors.amber,
                      child: Padding(
                        padding: EdgeInsets.all(3),
                        child: Text(
                          'TOTALIZADOR',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: (rect.left + rect.width) * box.maxWidth - 24,
              top: (rect.top + rect.height) * box.maxHeight - 24,
              width: 48,
              height: 48,
              child: GestureDetector(
                key: const Key('resize-totalizer-region'),
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  final maxWidth = math.max(.08, 1 - rect.left);
                  final width = (rect.width + details.delta.dx / box.maxWidth)
                      .clamp(.08, maxWidth);
                  final maxHeight = math.max(.04, 1 - rect.top);
                  final height =
                      (rect.height + details.delta.dy / box.maxHeight).clamp(
                        .04,
                        maxHeight,
                      );
                  onChanged(
                    _copy(
                      totalizer: TotalizerRegion(
                        NormalizedRect(rect.left, rect.top, width, height),
                      ),
                    ),
                  );
                },
                child: const Center(
                  child: Icon(
                    Icons.open_in_full,
                    color: Colors.black,
                    size: 22,
                    shadows: [Shadow(color: Colors.amber, blurRadius: 5)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: (dial.centerX - dial.radius) * box.maxWidth,
              top: dial.centerY * box.maxHeight - dial.radius * box.maxWidth,
              width: dialDiameter,
              height: dialDiameter,
              child: GestureDetector(
                key: const Key('move-dial-region'),
                onPanUpdate: (d) => onChanged(
                  _copy(
                    dial: NormalizedCircle(
                      (dial.centerX + d.delta.dx / box.maxWidth).clamp(
                        dial.radius,
                        1 - dial.radius,
                      ),
                      (dial.centerY + d.delta.dy / box.maxHeight).clamp(
                        dialRadiusY,
                        1 - dialRadiusY,
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
                  child: const Center(
                    child: Text(
                      'DIAL',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: (dial.centerX + dial.radius) * box.maxWidth - 24,
              top:
                  dial.centerY * box.maxHeight +
                  dial.radius * box.maxWidth -
                  24,
              width: 48,
              height: 48,
              child: GestureDetector(
                key: const Key('resize-dial-region'),
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  final delta = math.max(details.delta.dx, details.delta.dy);
                  final maxByX = math.min(dial.centerX, 1 - dial.centerX);
                  final maxByY =
                      math.min(dial.centerY, 1 - dial.centerY) *
                      box.maxHeight /
                      box.maxWidth;
                  final maxRadius = math.max(
                    .05,
                    math.min(.48, math.min(maxByX, maxByY)),
                  );
                  final radius = (dial.radius + delta / box.maxWidth)
                      .clamp(.05, maxRadius)
                      .toDouble();
                  onChanged(
                    _copy(
                      dial: NormalizedCircle(
                        dial.centerX,
                        dial.centerY,
                        radius,
                      ),
                    ),
                  );
                },
                child: const Center(
                  child: Icon(
                    Icons.open_in_full,
                    color: AppColors.success,
                    size: 22,
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
  CapturePurpose.cameraPreparation => 'PREPARACIÓN DE CÁMARA',
  CapturePurpose.start => 'Evidencia START',
  CapturePurpose.intermediate => 'Evidencia INTERMEDIATE',
  CapturePurpose.manualDiagnostic => 'Punto diagnóstico manual',
  CapturePurpose.finalEvidence => 'Evidencia FINAL',
  null => 'Cámara',
};

DialVisionConfiguration _copyConfiguration(
  DialVisionConfiguration value, {
  double? multiplier,
  double? litersPerRevolution,
  TotalizerConfiguration? totalizerConfiguration,
}) => DialVisionConfiguration(
  totalizerRegion: value.totalizerRegion,
  selectedDial: value.selectedDial,
  zeroAngleDegrees: value.zeroAngleDegrees,
  clockwise: value.clockwise,
  litersPerRevolution: litersPerRevolution ?? value.litersPerRevolution,
  multiplier: multiplier ?? value.multiplier,
  source: DialConfigurationSource.manual,
  totalizerConfiguration:
      totalizerConfiguration ?? value.totalizerConfiguration,
);

String _formatDialScale(double value) => value == value.truncateToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();
