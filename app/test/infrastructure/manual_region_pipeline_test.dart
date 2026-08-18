import 'dart:io';

import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:ddr001_diag_view_app/infrastructure/vision/needle_detector.dart';
import 'package:ddr001_diag_view_app/infrastructure/vision/odometer_reader.dart';
import 'package:ddr001_diag_view_app/infrastructure/vision/vision_models.dart';
import 'package:ddr001_diag_view_app/infrastructure/vision/vision_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  late Directory directory;
  late String photoPath;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ddr001-regions-');
    photoPath = '${directory.path}/face.png';
    final face = img.Image(width: 800, height: 800);
    img.fill(face, color: img.ColorRgb8(10, 10, 10));
    img.fillRect(
      face,
      x1: 0,
      y1: 0,
      x2: 399,
      y2: 399,
      color: img.ColorRgb8(240, 20, 20),
    );
    img.fillRect(
      face,
      x1: 400,
      y1: 0,
      x2: 799,
      y2: 399,
      color: img.ColorRgb8(20, 240, 20),
    );
    img.fillRect(
      face,
      x1: 0,
      y1: 400,
      x2: 399,
      y2: 799,
      color: img.ColorRgb8(20, 20, 240),
    );
    img.fillRect(
      face,
      x1: 400,
      y1: 400,
      x2: 799,
      y2: 799,
      color: img.ColorRgb8(240, 220, 20),
    );
    await File(photoPath).writeAsBytes(img.encodePng(face));
  });

  tearDown(() async => directory.delete(recursive: true));

  test(
    'prepare is manual-first and never invokes OCR or needle analysis',
    () async {
      final ocr = _RecordingOcr();
      final needle = _RecordingNeedle();
      final pipeline = OnDeviceVisualReadingPipeline(
        odometer: ocr,
        needle: needle,
      );
      final proposal = await pipeline.prepare(
        evidenceId: 'start',
        evidencePath: photoPath,
      );
      expect(proposal.analysisCompleted, isFalse);
      expect(ocr.calls, 0);
      expect(needle.calls, 0);
    },
  );

  test('OCR and needle receive only technician-selected crops', () async {
    final ocr = _RecordingOcr();
    final needle = _RecordingNeedle();
    final pipeline = OnDeviceVisualReadingPipeline(
      odometer: ocr,
      needle: needle,
    );
    const configuration = DialVisionConfiguration(
      totalizerRegion: TotalizerRegion(NormalizedRect(.05, .55, .35, .35)),
      selectedDial: NormalizedCircle(.75, .75, .18),
      totalizerConfiguration: TotalizerConfiguration(
        digitCount: 3,
        decimalPlaces: 1,
      ),
    );
    final proposal = await pipeline.analyze(
      evidenceId: 'selected',
      evidencePath: photoPath,
      configuration: configuration,
    );
    expect(ocr.calls, greaterThanOrEqualTo(4));
    expect(ocr.firstCenter!.b, greaterThan(ocr.firstCenter!.r));
    expect(needle.calls, 1);
    expect(needle.center!.r, greaterThan(200));
    expect(needle.center!.g, greaterThan(180));
    expect(proposal.dialCandidates, hasLength(1));
    expect(proposal.dialCandidates.single.id, 'configured');
  });

  test('selection supports top, bottom, left, right and an edge dial', () {
    const layouts = <DialVisionConfiguration>[
      DialVisionConfiguration(
        totalizerRegion: TotalizerRegion(NormalizedRect(.2, .05, .5, .15)),
        selectedDial: NormalizedCircle(.5, .75, .15),
      ),
      DialVisionConfiguration(
        totalizerRegion: TotalizerRegion(NormalizedRect(.2, .8, .5, .15)),
        selectedDial: NormalizedCircle(.5, .2, .15),
      ),
      DialVisionConfiguration(
        totalizerRegion: TotalizerRegion(NormalizedRect(.05, .4, .35, .15)),
        selectedDial: NormalizedCircle(.75, .5, .15),
      ),
      DialVisionConfiguration(selectedDial: NormalizedCircle(.9, .5, .1)),
    ];
    for (final layout in layouts) {
      final totalizer = layout.totalizerRegion.geometry.pixels(800, 800);
      final dial = layout.selectedDial.squarePixels(800, 800);
      expect(totalizer.x, greaterThanOrEqualTo(0));
      expect(totalizer.x + totalizer.width, lessThanOrEqualTo(800));
      expect(dial.x, greaterThanOrEqualTo(0));
      expect(dial.x + dial.width, lessThanOrEqualTo(800));
    }
  });

  test('mechanical drum fallback reconstructs configured digits', () async {
    final pipeline = OnDeviceVisualReadingPipeline(
      odometer: _SequenceOcr(['', '', '', '1', '2', '3']),
      needle: _RecordingNeedle(),
    );
    final proposal = await pipeline.analyze(
      evidenceId: 'drums',
      evidencePath: photoPath,
      configuration: const DialVisionConfiguration(
        totalizerRegion: TotalizerRegion(NormalizedRect(.05, .05, .9, .25)),
        selectedDial: NormalizedCircle(.75, .75, .18),
        totalizerConfiguration: TotalizerConfiguration(
          digitCount: 3,
          decimalPlaces: 1,
        ),
      ),
    );
    expect(proposal.odometerValue, 12.3);
  });

  test(
    'rolling drum keeps the upper digit during a 2 to 3 transition',
    () async {
      final pipeline = OnDeviceVisualReadingPipeline(
        odometer: _SequenceOcr(['', '', '', '0', '0', '0', '1', '2\n3']),
        needle: _RecordingNeedle(),
      );
      final proposal = await pipeline.analyze(
        evidenceId: 'rolling-drum',
        evidencePath: photoPath,
        configuration: const DialVisionConfiguration(
          totalizerRegion: TotalizerRegion(NormalizedRect(.05, .05, .9, .25)),
          selectedDial: NormalizedCircle(.75, .75, .18),
          totalizerConfiguration: TotalizerConfiguration(
            digitCount: 5,
            decimalPlaces: 0,
          ),
        ),
      );
      expect(proposal.odometerValue, 12);
      expect(proposal.warnings, contains(contains('Tambor en transición')));
    },
  );
}

final class _RecordingOcr implements OdometerRecognitionPort {
  int calls = 0;
  img.Pixel? center;
  img.Pixel? firstCenter;

  @override
  Future<String> recognize(String imagePath) async {
    calls++;
    final image = img.decodeImage(await File(imagePath).readAsBytes())!;
    center = image.getPixel(image.width ~/ 2, image.height ~/ 2);
    firstCenter ??= center;
    return '482';
  }

  @override
  Future<void> dispose() async {}
}

final class _SequenceOcr implements OdometerRecognitionPort {
  _SequenceOcr(this.values);
  final List<String> values;
  var index = 0;

  @override
  Future<String> recognize(String imagePath) async => values[index++];

  @override
  Future<void> dispose() async {}
}

final class _RecordingNeedle implements NeedleDetectionPort {
  int calls = 0;
  img.Pixel? center;

  @override
  Future<NeedleDetection?> detect(
    img.Image image,
    DialVisionConfiguration configuration,
  ) async {
    calls++;
    center = image.getPixel(image.width ~/ 2, image.height ~/ 2);
    return null;
  }
}
