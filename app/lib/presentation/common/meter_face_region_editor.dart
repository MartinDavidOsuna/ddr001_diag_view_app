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
final class MeterFaceRegionEditor extends StatelessWidget {
  const MeterFaceRegionEditor({
    required this.imagePath,
    required this.configuration,
    required this.onChanged,
    super.key,
    this.target = MeterFaceEditTarget.totalizer,
  });

  final String imagePath;
  final DialVisionConfiguration configuration;
  final ValueChanged<DialVisionConfiguration> onChanged;
  final MeterFaceEditTarget target;

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
            Image.file(
              File(imagePath),
              fit: BoxFit.fill,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Colors.black,
                child: Center(child: Text('No se pudo abrir la fotografía.')),
              ),
            ),
            Positioned(
              left: rect.left * box.maxWidth,
              top: rect.top * box.maxHeight,
              width: rect.width * box.maxWidth,
              height: rect.height * box.maxHeight,
              child: GestureDetector(
                key: const Key('move-totalizer-region'),
                behavior: HitTestBehavior.opaque,
                onPanUpdate: target != MeterFaceEditTarget.totalizer
                    ? null
                    : (details) => onChanged(
                        _copy(
                          totalizer: TotalizerRegion(
                            NormalizedRect(
                              (rect.left + details.delta.dx / box.maxWidth)
                                  .clamp(0, math.max(0, 1 - rect.width)),
                              (rect.top + details.delta.dy / box.maxHeight)
                                  .clamp(0, math.max(0, 1 - rect.height)),
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
              left: (rect.left + rect.width) * box.maxWidth - 28,
              top: (rect.top + rect.height) * box.maxHeight - 28,
              width: 56,
              height: 56,
              child: GestureDetector(
                key: const Key('resize-totalizer-region'),
                behavior: HitTestBehavior.opaque,
                onPanUpdate: target != MeterFaceEditTarget.totalizer
                    ? null
                    : (details) {
                        final maxWidth = math.max(.08, 1 - rect.left);
                        final maxHeight = math.max(.04, 1 - rect.top);
                        onChanged(
                          _copy(
                            totalizer: TotalizerRegion(
                              NormalizedRect(
                                rect.left,
                                rect.top,
                                (rect.width + details.delta.dx / box.maxWidth)
                                    .clamp(.08, maxWidth),
                                (rect.height + details.delta.dy / box.maxHeight)
                                    .clamp(.04, maxHeight),
                              ),
                            ),
                          ),
                        );
                      },
                child: const Center(
                  child: Icon(
                    Icons.open_in_full,
                    color: Colors.black,
                    size: 25,
                    shadows: [Shadow(color: Colors.amber, blurRadius: 6)],
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
                behavior: HitTestBehavior.opaque,
                onPanUpdate: target != MeterFaceEditTarget.dial
                    ? null
                    : (details) => onChanged(
                        _copy(
                          dial: NormalizedCircle(
                            (dial.centerX + details.delta.dx / box.maxWidth)
                                .clamp(dial.radius, 1 - dial.radius),
                            (dial.centerY + details.delta.dy / box.maxHeight)
                                .clamp(dialRadiusY, 1 - dialRadiusY),
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
              left: (dial.centerX + dial.radius) * box.maxWidth - 28,
              top:
                  dial.centerY * box.maxHeight +
                  dial.radius * box.maxWidth -
                  28,
              width: 56,
              height: 56,
              child: GestureDetector(
                key: const Key('resize-dial-region'),
                behavior: HitTestBehavior.opaque,
                onPanUpdate: target != MeterFaceEditTarget.dial
                    ? null
                    : (details) {
                        final delta = math.max(
                          details.delta.dx,
                          details.delta.dy,
                        );
                        final maxByX = math.min(dial.centerX, 1 - dial.centerX);
                        final maxByY =
                            math.min(dial.centerY, 1 - dial.centerY) *
                            box.maxHeight /
                            box.maxWidth;
                        final maxRadius = math.max(
                          .05,
                          math.min(.48, math.min(maxByX, maxByY)),
                        );
                        onChanged(
                          _copy(
                            dial: NormalizedCircle(
                              dial.centerX,
                              dial.centerY,
                              (dial.radius + delta / box.maxWidth)
                                  .clamp(.05, maxRadius)
                                  .toDouble(),
                            ),
                          ),
                        );
                      },
                child: const Center(
                  child: Icon(
                    Icons.open_in_full,
                    color: AppColors.success,
                    size: 25,
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
