import 'dart:math' as math;

import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:ddr001_diag_view_app/infrastructure/vision/needle_detector.dart';
import 'package:ddr001_diag_view_app/infrastructure/vision/odometer_parser.dart';
import 'package:ddr001_diag_view_app/infrastructure/vision/vision_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  const parser = OdometerParser();

  group('odometer parser', () {
    test('accepts integer and decimal candidates', () {
      expect(parser.parse('001234').single.value, 1234);
      expect(parser.parse('00123.4').single.value, 123.4);
      expect(parser.parse('00123.4').single.digits, '001234');
    });

    test('applies explicit totalizer decimal format', () {
      final candidate = parser.parse('482').single;
      for (final item in <(int, double)>[(0, 482), (1, 48.2), (2, 4.82)]) {
        final proposal = parser.applyConfiguration(
          candidate,
          TotalizerConfiguration(digitCount: 3, decimalPlaces: item.$1),
        );
        expect(proposal?.value, closeTo(item.$2, .0001));
      }
    });

    test('validates digit count and leading zero policy', () {
      final candidate = parser.parse('482').single;
      expect(
        parser.applyConfiguration(
          candidate,
          const TotalizerConfiguration(digitCount: 2, decimalPlaces: 1),
        ),
        isNull,
      );
      expect(
        parser.applyConfiguration(
          candidate,
          const TotalizerConfiguration(
            digitCount: 4,
            decimalPlaces: 1,
            leadingZerosAllowed: false,
          ),
        ),
        isNull,
      );
      final padded = parser.applyConfiguration(
        candidate,
        const TotalizerConfiguration(digitCount: 4, decimalPlaces: 1),
      );
      expect(padded?.value, 48.2);
      expect(padded?.requiresConfirmation, isTrue);
    });

    test('digits with or without decimal share configured meaning', () {
      const configuration = TotalizerConfiguration(
        digitCount: 3,
        decimalPlaces: 1,
      );
      expect(
        parser
            .applyConfiguration(parser.parse('482').single, configuration)
            ?.value,
        48.2,
      );
      expect(
        parser
            .applyConfiguration(parser.parse('48.2').single, configuration)
            ?.value,
        48.2,
      );
    });

    test('configured leading zero is trimmed only with confirmation', () {
      final proposal = parser.applyConfiguration(
        parser.parse('0482').single,
        const TotalizerConfiguration(digitCount: 3, decimalPlaces: 1),
      );
      expect(proposal?.value, 48.2);
      expect(proposal?.requiresConfirmation, isTrue);
      expect(
        parser.applyConfiguration(
          parser.parse('0482').single,
          const TotalizerConfiguration(
            digitCount: 3,
            decimalPlaces: 1,
            leadingZerosAllowed: false,
          ),
        ),
        isNull,
      );
    });

    test('joins OCR digits separated only by whitespace and line breaks', () {
      final candidate = parser.parse('4\n8\n2').single;
      expect(candidate.digits, '482');
      expect(
        parser
            .applyConfiguration(
              candidate,
              const TotalizerConfiguration(digitCount: 3, decimalPlaces: 1),
            )
            ?.value,
        48.2,
      );
    });

    test('rejects any automatic candidate containing letters', () {
      expect(parser.parse('0O1234'), isEmpty);
      expect(parser.parse('R160'), isEmpty);
      expect(parser.parse('DN100'), isEmpty);
      expect(parser.parse('2024A'), isEmpty);
      expect(parser.parse('00482').single.digits, '00482');
    });

    test('returns no candidate for unrelated text', () {
      expect(parser.parse('MEDIDOR AGUA'), isEmpty);
    });

    test('multiple candidates are not selected automatically', () {
      final candidates = parser.parse('001234\n005678');
      expect(candidates, hasLength(2));
      expect(parser.select(candidates), isNull);
    });
  });

  test('normalized ROI maps proportionally and stays inside image', () {
    const roi = NormalizedRect(.1, .2, .5, .4);
    expect(roi.pixels(1000, 500), (x: 100, y: 100, width: 500, height: 200));
  });

  test('totalizer region remains relative across image sizes', () {
    const region = TotalizerRegion(NormalizedRect(.2, .1, .5, .2));
    expect(region.geometry.pixels(1000, 500), (
      x: 200,
      y: 50,
      width: 500,
      height: 100,
    ));
    expect(region.geometry.pixels(2000, 1000), (
      x: 400,
      y: 100,
      width: 1000,
      height: 200,
    ));
  });

  test('dial circle produces a square pixel crop on portrait images', () {
    const circle = NormalizedCircle(.5, .5, .2);
    expect(circle.squarePixels(1000, 2000), (
      x: 300,
      y: 800,
      width: 400,
      height: 400,
    ));
  });

  test('dial selection uses metrological resolution, not physical size', () {
    const candidates = [
      DialCandidate(
        id: 'large',
        geometry: NormalizedCircle(.5, .5, .3),
        confidence: .99,
        multiplier: 1,
        litersPerRevolution: 100,
      ),
      DialCandidate(
        id: 'small',
        geometry: NormalizedCircle(.2, .2, .1),
        confidence: .7,
        multiplier: .01,
        litersPerRevolution: 1,
      ),
    ];
    expect(selectHighestMetrologicalResolution(candidates)?.id, 'small');
  });

  test('unknown or tied dial scale is never selected silently', () {
    const unknown = [
      DialCandidate(
        id: 'a',
        geometry: NormalizedCircle(.2, .2, .1),
        confidence: .8,
      ),
    ];
    expect(selectHighestMetrologicalResolution(unknown), isNull);
    const tied = [
      DialCandidate(
        id: 'a',
        geometry: NormalizedCircle(.2, .2, .1),
        confidence: .8,
        litersPerRevolution: 1,
      ),
      DialCandidate(
        id: 'b',
        geometry: NormalizedCircle(.7, .7, .2),
        confidence: .9,
        litersPerRevolution: 1,
      ),
    ];
    expect(selectHighestMetrologicalResolution(tied), isNull);
  });

  test('supported multiplier OCR parsing includes x1 through x0.001', () {
    expect(parseDialMultiplier('x1'), 1);
    expect(parseDialMultiplier('×0,1'), .1);
    expect(parseDialMultiplier('X 0.01'), .01);
    expect(parseDialMultiplier('x0.001'), .001);
    expect(parseDialMultiplier('escala desconocida'), isNull);
  });

  test('liters per revolution is canonical for legacy and 1000 L scales', () {
    expect(dialMultiplierForLitersPerRevolution(1000), 10);
    expect(dialMultiplierForLitersPerRevolution(100), 1);
    expect(dialMultiplierForLitersPerRevolution(10), .1);
    expect(dialMultiplierForLitersPerRevolution(1), .01);
    expect(dialMultiplierForLitersPerRevolution(.1), .001);
    expect(() => dialMultiplierForLitersPerRevolution(0), throwsArgumentError);
  });

  group('angle mapping', () {
    const config = DialVisionConfiguration(zeroAngleDegrees: -90);
    test('normalizes wrap', () {
      expect(normalizeAngleDegrees(-1), 359);
      expect(normalizeAngleDegrees(361), 1);
    });
    test('maps cardinal angles to liters', () {
      expect(angleToLiters(-90, config), closeTo(0, .001));
      expect(angleToLiters(0, config), closeTo(25, .001));
      expect(angleToLiters(90, config), closeTo(50, .001));
      expect(angleToLiters(180, config), closeTo(75, .001));
      expect(angleToLiters(269, config), closeTo(99.72, .02));
      expect(angleToLiters(-89, config), closeTo(.278, .02));
    });
    test('mapping changes with liters per revolution', () {
      const oneLiter = DialVisionConfiguration(litersPerRevolution: 1);
      const tenLiters = DialVisionConfiguration(litersPerRevolution: 10);
      expect(angleToLiters(0, oneLiter), closeTo(.25, .001));
      expect(angleToLiters(0, tenLiters), closeTo(2.5, .001));
    });
  });

  group('red needle detector', () {
    const detector = RedNeedleDetector(minimumRedPixels: 8);
    const config = DialVisionConfiguration();

    for (final item in <(double, double)>[
      (-90, 0),
      (0, 25),
      (90, 50),
      (180, 75),
    ]) {
      test('detects ${item.$2}% position', () async {
        final result = await detector.detect(_dial(item.$1), config);
        expect(result, isNotNull);
        expect(result!.liters, closeTo(item.$2, 2));
      });
    }

    test('detects a faint red needle', () async {
      final result = await detector.detect(
        _dial(0, color: img.ColorRgb8(150, 55, 55)),
        config,
      );
      expect(result?.liters, closeTo(25, 2));
    });

    test('detects the centerline of a broad painted red pointer', () async {
      final result = await detector.detect(_dial(35, thickness: 25), config);
      expect(result, isNotNull);
      expect(result!.angleDegrees, closeTo(35, 4));
    });

    test(
      'uses the physical red axis in an off-center non-square crop',
      () async {
        const tenLiterConfig = DialVisionConfiguration(litersPerRevolution: 10);
        for (final item in <(double, double)>[
          (-90, 0),
          (-54, 1),
          (0, 2.5),
          (90, 5),
          (180, 7.5),
          (234, 9),
        ]) {
          final result = await detector.detect(
            _dial(item.$1, width: 240, height: 360, centerX: 105, centerY: 190),
            tenLiterConfig,
          );
          expect(result?.liters, closeTo(item.$2, .12));
        }
      },
    );

    test('rejects image without red needle', () async {
      final image = img.Image(width: 300, height: 300);
      img.fill(image, color: img.ColorRgb8(230, 230, 230));
      expect(await detector.detect(image, config), isNull);
    });

    test('rejects black line, reflection, screw, mark and shadow', () async {
      final image = img.Image(width: 300, height: 300);
      img.fill(image, color: img.ColorRgb8(220, 220, 220));
      img.drawLine(
        image,
        x1: 150,
        y1: 150,
        x2: 280,
        y2: 40,
        color: img.ColorRgb8(15, 15, 15),
        thickness: 9,
      );
      img.drawCircle(
        image,
        x: 150,
        y: 150,
        radius: 13,
        color: img.ColorRgb8(90, 90, 90),
      );
      img.fillRect(
        image,
        x1: 30,
        y1: 40,
        x2: 70,
        y2: 260,
        color: img.ColorRgb8(245, 245, 245),
      );
      expect(await detector.detect(image, config), isNull);
    });

    test('ignores red noise outside radial processing area', () async {
      final image = img.Image(width: 300, height: 300);
      img.fill(image, color: img.ColorRgb8(230, 230, 230));
      for (var x = 0; x < 40; x += 3) {
        image.setPixel(x, 5, img.ColorRgb8(255, 0, 0));
      }
      expect(await detector.detect(image, config), isNull);
    });
  });

  test('proposal confirmation records evidence and origin', () {
    final proposal = VisualReadingProposal(
      evidenceId: 'evidence-1',
      evidencePath: '/evidence/1.jpg',
      odometerRaw: '001234',
      odometerValue: 1234,
      needleLiters: 25,
      needleAngle: 0,
      needleConfidence: .8,
      warnings: const [],
      createdAt: DateTime.utc(2026, 8, 10),
    );
    final automatic = proposal.confirm(
      odometerValue: 1234,
      needleLiters: 25,
      litersPerOdometerUnit: 1000,
      needleLitersPerRevolution: 100,
      corrected: false,
    );
    final corrected = proposal.confirm(
      odometerValue: 1235,
      needleLiters: 26,
      litersPerOdometerUnit: 1000,
      needleLitersPerRevolution: 100,
      corrected: true,
    );
    expect(automatic.source, ReadingSource.autoConfirmed);
    expect(corrected.source, ReadingSource.manual);
    expect(corrected.evidenceId, 'evidence-1');
  });
}

img.Image _dial(
  double degrees, {
  img.Color? color,
  int width = 300,
  int height = 300,
  int? centerX,
  int? centerY,
  int thickness = 7,
}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(235, 235, 235));
  final cx = centerX ?? width ~/ 2;
  final cy = centerY ?? height ~/ 2;
  final length = math.min(width, height) * .38;
  final radians = degrees * math.pi / 180;
  final x = cx + (length * math.cos(radians)).round();
  final y = cy + (length * math.sin(radians)).round();
  img.drawLine(
    image,
    x1: cx,
    y1: cy,
    x2: x,
    y2: y,
    color: color ?? img.ColorRgb8(230, 20, 20),
    thickness: thickness,
  );
  return image;
}
