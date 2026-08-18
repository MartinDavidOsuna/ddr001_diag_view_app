import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../infrastructure/camera/camera_models.dart';
import '../../infrastructure/vision/vision_models.dart';
import '../app_controller.dart';
import '../common/app_scaffold.dart';
import '../common/meter_face_region_editor.dart';

final class VisualCalibrationScreen extends ConsumerStatefulWidget {
  const VisualCalibrationScreen({super.key});
  @override
  ConsumerState<VisualCalibrationScreen> createState() =>
      _VisualCalibrationScreenState();
}

final class _VisualCalibrationScreenState
    extends ConsumerState<VisualCalibrationScreen> {
  final _knownNeedle = TextEditingController();
  final _knownOdometer = TextEditingController();
  // Debug-only starting geometry measured from the current simulator framing.
  // Production defaults and persisted Sample configurations are untouched.
  var _configuration = const DialVisionConfiguration(
    totalizerRegion: TotalizerRegion(NormalizedRect(.24, .185, .40, .065)),
    selectedDial: NormalizedCircle(.453, .332, .14),
    litersPerRevolution: 10,
  );
  var _ready = false;
  var _busy = false;
  String? _error;
  VisualReadingProposal? _proposal;
  String? _capturedPath;
  MeterFaceEditTarget _editTarget = MeterFaceEditTarget.totalizer;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (!kDebugMode) return;
    try {
      final camera = ref.read(appDependenciesProvider).camera!;
      if (await camera.requestPermission() != CameraPermissionState.granted) {
        throw StateError('Permiso de cámara no concedido.');
      }
      await camera.initialize();
      if (mounted) setState(() => _ready = true);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _capture() async {
    final knownNeedle = double.tryParse(_knownNeedle.text);
    final knownOdometer = double.tryParse(_knownOdometer.text);
    if (knownNeedle == null && knownOdometer == null) {
      setState(() => _error = 'Capture al menos un valor real conocido.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final dependencies = ref.read(appDependenciesProvider);
    try {
      final photo = await dependencies.camera!.capture();
      await dependencies.camera!.pause();
      if (mounted) {
        setState(() {
          _capturedPath = photo.path;
          _proposal = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'No se pudo capturar: $error');
      try {
        await dependencies.camera!.resume();
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _analyze() async {
    final path = _capturedPath;
    if (path == null) return;
    final knownNeedle = double.tryParse(_knownNeedle.text);
    final knownOdometer = double.tryParse(_knownOdometer.text);
    final knownTotalizerText = _knownOdometer.text.trim().replaceAll(',', '.');
    final knownDigits = knownTotalizerText.replaceAll(RegExp(r'\D'), '');
    final separator = knownTotalizerText.indexOf('.');
    if (knownDigits.isNotEmpty) {
      _configuration = _copy(
        totalizerConfiguration: TotalizerConfiguration(
          digitCount: knownDigits.length,
          decimalPlaces: separator < 0
              ? 0
              : knownTotalizerText.length - separator - 1,
          source: DialConfigurationSource.manual,
        ),
      );
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final dependencies = ref.read(appDependenciesProvider);
    try {
      var proposal = await dependencies.visualPipeline!.analyze(
        evidenceId: 'debug-cal-${DateTime.now().microsecondsSinceEpoch}',
        evidencePath: path,
        configuration: _configuration,
      );
      if (knownNeedle != null && proposal.needleAngle != null) {
        final revolution = _configuration.litersPerRevolution;
        final knownFraction = (knownNeedle % revolution) / revolution;
        final calibratedZero = _configuration.clockwise
            ? proposal.needleAngle! - knownFraction * 360
            : proposal.needleAngle! + knownFraction * 360;
        _configuration = _copy(zeroAngle: calibratedZero);
        proposal = await dependencies.visualPipeline!.analyze(
          evidenceId: 'debug-cal-${DateTime.now().microsecondsSinceEpoch}',
          evidencePath: path,
          configuration: _configuration,
        );
      }
      _index++;
      final record = <String, Object?>{
        'tag': 'DDR001_CALIBRATION',
        'index': _index,
        'knownNeedle': knownNeedle,
        'knownOdometer': knownOdometer,
        'needleAngle': proposal.needleAngle,
        'needleLiters': proposal.needleLiters,
        'needleError': knownNeedle == null || proposal.needleLiters == null
            ? null
            : proposal.needleLiters! - knownNeedle,
        'needleConfidence': proposal.needleConfidence,
        'redPixels': proposal.needleCandidatePixelCount,
        'ocrRaw': proposal.odometerRaw,
        'ocrCandidates': proposal.odometerCandidates
            .map(
              (c) => {'raw': c.raw, 'value': c.value, 'ambiguous': c.ambiguous},
            )
            .toList(),
        'ocrSelected': proposal.odometerValue,
        'centerX': _configuration.selectedDial.centerX,
        'centerY': _configuration.selectedDial.centerY,
        'radius': _configuration.selectedDial.radius,
        'zeroAngle': _configuration.zeroAngleDegrees,
        'clockwise': _configuration.clockwise,
        'litersPerRevolution': _configuration.litersPerRevolution,
        'totalizerRoi': [
          _configuration.totalizerRegion.geometry.left,
          _configuration.totalizerRegion.geometry.top,
          _configuration.totalizerRegion.geometry.width,
          _configuration.totalizerRegion.geometry.height,
        ],
        'path': path,
      };
      debugPrint(jsonEncode(record), wrapWidth: 4096);
      if (mounted) setState(() => _proposal = proposal);
    } catch (error) {
      if (mounted) setState(() => _error = 'No se pudo analizar: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _repeatPhoto() async {
    final camera = ref.read(appDependenciesProvider).camera!;
    setState(() {
      _capturedPath = null;
      _proposal = null;
      _error = null;
    });
    try {
      await camera.resume();
      if (mounted) setState(() => _ready = true);
    } catch (error) {
      if (mounted) setState(() => _error = 'No se pudo reabrir la cámara.');
    }
  }

  @override
  void dispose() {
    _knownNeedle.dispose();
    _knownOdometer.dispose();
    // AppDependencies owns the shared camera. Disposing it here made later
    // production captures reuse a closed controller and surface a red Flutter
    // error screen. Calibration only releases the active preview.
    unawaited(ref.read(appDependenciesProvider).camera?.pause());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final circle = _configuration.selectedDial;
    final roi = _configuration.totalizerRegion.geometry;
    if (_capturedPath != null && _proposal == null) {
      return AppScaffold(
        title: 'Calibración visual · DEBUG',
        scrollable: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatusBanner(
              text:
                  'Seleccione sobre la fotografía el totalizador y el dial que se calibrarán.',
              color: AppColors.warning,
              icon: Icons.crop_free,
            ),
            const SizedBox(height: 8),
            SegmentedButton<MeterFaceEditTarget>(
              segments: const [
                ButtonSegment(
                  value: MeterFaceEditTarget.totalizer,
                  label: Text('TOTALIZADOR'),
                ),
                ButtonSegment(
                  value: MeterFaceEditTarget.dial,
                  label: Text('DIAL'),
                ),
              ],
              selected: {_editTarget},
              onSelectionChanged: (value) =>
                  setState(() => _editTarget = value.single),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: MeterFaceRegionEditor(
                  imagePath: _capturedPath!,
                  configuration: _configuration,
                  target: _editTarget,
                  onChanged: (value) => setState(() => _configuration = value),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('calibration-analyze-regions'),
              onPressed: _busy ? null : _analyze,
              icon: const Icon(Icons.document_scanner_outlined),
              label: Text(_busy ? 'ANALIZANDO…' : 'ANALIZAR REGIONES'),
            ),
            TextButton(
              onPressed: _busy ? null : _repeatPhoto,
              child: const Text('REPETIR FOTO'),
            ),
          ],
        ),
      );
    }
    return AppScaffold(
      title: 'Calibración visual · DEBUG',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: _capturedPath != null
                    ? Image.file(File(_capturedPath!), fit: BoxFit.cover)
                    : _ready
                    ? ref.read(appDependenciesProvider).camera!.buildPreview()
                    : const ColoredBox(color: Colors.black),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _knownNeedle,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Aguja real conocida (L)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _knownOdometer,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Totalizador real conocido',
              ),
            ),
            _slider(
              'Centro X dial',
              circle.centerX,
              .1,
              .9,
              (v) => _setCircle(v, circle.centerY, circle.radius),
            ),
            _slider(
              'Centro Y dial',
              circle.centerY,
              .1,
              .9,
              (v) => _setCircle(circle.centerX, v, circle.radius),
            ),
            _slider(
              'Radio dial',
              circle.radius,
              .08,
              .45,
              (v) => _setCircle(circle.centerX, circle.centerY, v),
            ),
            _slider(
              'Zero angle',
              _configuration.zeroAngleDegrees,
              -180,
              180,
              (v) => setState(() => _configuration = _copy(zeroAngle: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sentido horario'),
              value: _configuration.clockwise,
              onChanged: (value) =>
                  setState(() => _configuration = _copy(clockwise: value)),
            ),
            _slider(
              'Totalizador X',
              roi.left,
              0,
              .8,
              (v) => _setRoi(v, roi.top, roi.width, roi.height),
            ),
            _slider(
              'Totalizador Y',
              roi.top,
              0,
              .8,
              (v) => _setRoi(roi.left, v, roi.width, roi.height),
            ),
            _slider(
              'Ancho totalizador',
              roi.width,
              .1,
              .9,
              (v) => _setRoi(roi.left, roi.top, v, roi.height),
            ),
            _slider(
              'Alto totalizador',
              roi.height,
              .05,
              .5,
              (v) => _setRoi(roi.left, roi.top, roi.width, v),
            ),
            FilledButton.icon(
              onPressed: _ready && !_busy && _capturedPath == null
                  ? _capture
                  : null,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(
                _busy ? 'ANALIZANDO…' : 'CAPTURAR MEDICIÓN ${_index + 1}',
              ),
            ),
            if (_proposal case final p?) ...[
              const SizedBox(height: 12),
              if (p.totalizerCrop != null)
                Image.memory(p.totalizerCrop!, height: 90),
              Text(
                'OCR raw: ${p.odometerRaw.isEmpty ? '<vacío>' : p.odometerRaw}',
              ),
              Text('OCR seleccionado: ${p.odometerValue ?? '<ninguno>'}'),
              if (p.dialCrop != null) Image.memory(p.dialCrop!, height: 180),
              Text(
                'Ángulo: ${p.needleAngle?.toStringAsFixed(3) ?? '<fallo>'}°',
              ),
              Text(
                'Aguja: ${p.needleLiters?.toStringAsFixed(3) ?? '<fallo>'} L',
              ),
              Text(
                'Confianza: ${p.needleConfidence?.toStringAsFixed(4) ?? '<n/a>'} · píxeles rojos: ${p.needleCandidatePixelCount ?? '<n/a>'}',
              ),
              FilledButton.tonal(
                onPressed: _repeatPhoto,
                child: const Text('NUEVA FOTOGRAFÍA'),
              ),
            ],
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
        ),
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> changed,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label: ${value.toStringAsFixed(4)}'),
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        onChanged: (v) => setState(() => changed(v)),
      ),
    ],
  );

  void _setCircle(double x, double y, double radius) {
    final safeRadius = radius.clamp(.08, .45).toDouble();
    _configuration = _copy(
      circle: NormalizedCircle(
        x.clamp(safeRadius, 1 - safeRadius).toDouble(),
        y.clamp(safeRadius, 1 - safeRadius).toDouble(),
        safeRadius,
      ),
    );
  }

  void _setRoi(double left, double top, double width, double height) {
    final safeLeft = left.clamp(0, .9).toDouble();
    final safeTop = top.clamp(0, .9).toDouble();
    _configuration = _copy(
      totalizer: TotalizerRegion(
        NormalizedRect(
          safeLeft,
          safeTop,
          width.clamp(.05, 1 - safeLeft).toDouble(),
          height.clamp(.05, 1 - safeTop).toDouble(),
        ),
      ),
    );
  }

  DialVisionConfiguration _copy({
    NormalizedCircle? circle,
    TotalizerRegion? totalizer,
    double? zeroAngle,
    bool? clockwise,
    TotalizerConfiguration? totalizerConfiguration,
  }) => DialVisionConfiguration(
    selectedDial: circle ?? _configuration.selectedDial,
    totalizerRegion: totalizer ?? _configuration.totalizerRegion,
    zeroAngleDegrees: zeroAngle ?? _configuration.zeroAngleDegrees,
    clockwise: clockwise ?? _configuration.clockwise,
    litersPerRevolution: _configuration.litersPerRevolution,
    multiplier: _configuration.multiplier,
    source: DialConfigurationSource.manual,
    totalizerConfiguration:
        totalizerConfiguration ?? _configuration.totalizerConfiguration,
  );
}
