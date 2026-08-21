import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../infrastructure/vision/vision_models.dart';

enum MeterFaceEditTarget { totalizer, dial }

/// Touch editor for the two technician-authorized crops over one Evidence.
///
/// This widget deliberately owns no scrolling. Its parent must place it in a
/// fixed viewport while gestures are active.
final class MeterFaceRegionEditor extends StatefulWidget {
  const MeterFaceRegionEditor({
    required this.imagePath,
    required this.configuration,
    required this.onChanged,
    super.key,
    this.target = MeterFaceEditTarget.totalizer,
  }) : livePreview = null,
       liveAspectRatio = null;

  const MeterFaceRegionEditor.live({
    required Widget preview,
    required double aspectRatio,
    required this.configuration,
    required this.onChanged,
    super.key,
    this.target = MeterFaceEditTarget.totalizer,
  }) : imagePath = null,
       livePreview = preview,
       liveAspectRatio = aspectRatio;

  final String? imagePath;
  final Widget? livePreview;
  final double? liveAspectRatio;
  final DialVisionConfiguration configuration;
  final ValueChanged<DialVisionConfiguration> onChanged;
  final MeterFaceEditTarget target;

  @override
  State<MeterFaceRegionEditor> createState() => _MeterFaceRegionEditorState();
}

final class _MeterFaceRegionEditorState extends State<MeterFaceRegionEditor> {
  NormalizedRect? _totalizerAtScaleStart;
  NormalizedCircle? _dialAtScaleStart;
  Offset? _focalPointAtScaleStart;

  @override
  Widget build(BuildContext context) {
    final background =
        widget.livePreview ??
        Image.file(
          File(widget.imagePath!),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: Colors.black,
            child: Center(child: Text('No se pudo abrir la fotografía.')),
          ),
        );
    Widget editor(double aspectRatio) => AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, box) {
          final rect = widget.configuration.totalizerRegion.geometry;
          final dial = widget.configuration.selectedDial;
          final dialDiameter = dial.radius * 2 * box.maxWidth;
          return Stack(
            fit: StackFit.expand,
            children: [
              background,
              Positioned(
                left: rect.left * box.maxWidth,
                top: rect.top * box.maxHeight,
                width: rect.width * box.maxWidth,
                height: rect.height * box.maxHeight,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber, width: 3),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: (dial.centerX - dial.radius) * box.maxWidth,
                top: dial.centerY * box.maxHeight - dial.radius * box.maxWidth,
                width: dialDiameter,
                height: dialDiameter,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.success, width: 3),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add,
                        color: AppColors.success,
                        size: 26,
                        shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  key: Key(
                    widget.target == MeterFaceEditTarget.totalizer
                        ? 'move-totalizer-region'
                        : 'move-dial-region',
                  ),
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: (details) {
                    _totalizerAtScaleStart = rect;
                    _dialAtScaleStart = dial;
                    _focalPointAtScaleStart = details.localFocalPoint;
                  },
                  onScaleUpdate: (details) {
                    if (widget.target == MeterFaceEditTarget.totalizer) {
                      _scaleTotalizer(details, box);
                    } else {
                      _scaleDial(details, box);
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
    final liveRatio = widget.liveAspectRatio;
    if (liveRatio != null) return editor(liveRatio);
    return _FileAspectRatio(imagePath: widget.imagePath!, builder: editor);
  }

  void _scaleTotalizer(ScaleUpdateDetails details, BoxConstraints box) {
    final start = _totalizerAtScaleStart;
    final focalStart = _focalPointAtScaleStart;
    if (start == null || focalStart == null) return;
    final gestureScale = details.pointerCount > 1 ? details.scale : 1.0;
    final width = (start.width * gestureScale).clamp(.08, .95).toDouble();
    final height = (start.height * gestureScale).clamp(.04, .70).toDouble();
    final dx = (details.localFocalPoint.dx - focalStart.dx) / box.maxWidth;
    final dy = (details.localFocalPoint.dy - focalStart.dy) / box.maxHeight;
    final centerX = (start.left + start.width / 2 + dx).clamp(
      width / 2,
      1 - width / 2,
    );
    final centerY = (start.top + start.height / 2 + dy).clamp(
      height / 2,
      1 - height / 2,
    );
    widget.onChanged(
      _copy(
        totalizer: TotalizerRegion(
          NormalizedRect(
            centerX - width / 2,
            centerY - height / 2,
            width,
            height,
          ),
        ),
      ),
    );
  }

  void _scaleDial(ScaleUpdateDetails details, BoxConstraints box) {
    final start = _dialAtScaleStart;
    final focalStart = _focalPointAtScaleStart;
    if (start == null || focalStart == null) return;
    final dx = (details.localFocalPoint.dx - focalStart.dx) / box.maxWidth;
    final dy = (details.localFocalPoint.dy - focalStart.dy) / box.maxHeight;
    var centerX = start.centerX + dx;
    var centerY = start.centerY + dy;
    final maxRadius = math.min(
      .48,
      math.min(
        math.min(centerX, 1 - centerX),
        math.min(centerY, 1 - centerY) * box.maxHeight / box.maxWidth,
      ),
    );
    final gestureScale = details.pointerCount > 1 ? details.scale : 1.0;
    final radius = (start.radius * gestureScale)
        .clamp(.05, math.max(.05, maxRadius))
        .toDouble();
    final radiusY = radius * box.maxWidth / box.maxHeight;
    centerX = centerX.clamp(radius, 1 - radius);
    centerY = centerY.clamp(radiusY, 1 - radiusY);
    widget.onChanged(_copy(dial: NormalizedCircle(centerX, centerY, radius)));
  }

  DialVisionConfiguration _copy({
    TotalizerRegion? totalizer,
    NormalizedCircle? dial,
  }) => DialVisionConfiguration(
    totalizerRegion: totalizer ?? widget.configuration.totalizerRegion,
    selectedDial: dial ?? widget.configuration.selectedDial,
    zeroAngleDegrees: widget.configuration.zeroAngleDegrees,
    clockwise: widget.configuration.clockwise,
    litersPerRevolution: widget.configuration.litersPerRevolution,
    multiplier: widget.configuration.multiplier,
    source: DialConfigurationSource.manual,
    totalizerConfiguration: widget.configuration.totalizerConfiguration,
  );
}

final class _FileAspectRatio extends StatefulWidget {
  const _FileAspectRatio({required this.imagePath, required this.builder});

  final String imagePath;
  final Widget Function(double aspectRatio) builder;

  @override
  State<_FileAspectRatio> createState() => _FileAspectRatioState();
}

final class _FileAspectRatioState extends State<_FileAspectRatio> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double _aspectRatio = 3 / 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _FileAspectRatio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) _resolveImage();
  }

  void _resolveImage() {
    if (_listener != null) _stream?.removeListener(_listener!);
    final stream = FileImage(
      File(widget.imagePath),
    ).resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((image, _) {
      final ratio = image.image.width / image.image.height;
      if (mounted && ratio.isFinite && ratio > 0 && ratio != _aspectRatio) {
        setState(() => _aspectRatio = ratio);
      }
    });
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_aspectRatio);
}
