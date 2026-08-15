import 'dart:async';

import 'package:ddr001_diag_view_app/domain/pulse/esp32_counter_protocol.dart';
import 'package:ddr001_diag_view_app/domain/pulse/pulse_source.dart';
import 'package:ddr001_diag_view_app/infrastructure/pulse/led_pulse_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ESP32 counter protocol', () {
    const protocol = Esp32CounterProtocol();

    test('parses v1 uint32 little endian', () {
      final value = protocol.parse([1, 0x78, 0x56, 0x34, 0x12]);
      expect(value!.version, 1);
      expect(value.counter, 0x12345678);
    });

    test('rejects invalid version and length', () {
      expect(protocol.parse([]), isNull);
      expect(protocol.parse([2, 0, 0, 0, 0]), isNull);
      expect(protocol.parse([1, 0, 0, 0]), isNull);
    });

    test('baseline duplicate skip and rollback are explicit', () {
      final reconciler = Esp32CounterReconciler();
      expect(reconciler.observe(100).status, CounterObservationStatus.baseline);
      expect(
        reconciler.observe(100).status,
        CounterObservationStatus.duplicate,
      );
      expect(reconciler.observe(107).delta, 7);
      expect(reconciler.observe(3).status, CounterObservationStatus.rollback);
    });

    test('uint32 wrap reconciles forward delta', () {
      final reconciler = Esp32CounterReconciler(
        lastObservedCounter: 0xfffffffe,
      );
      expect(reconciler.observe(1).delta, 3);
    });

    test('sample delta is calculated from frozen baseline', () {
      expect(esp32CounterDelta(baseline: 100, current: 107), 7);
      expect(esp32CounterDelta(baseline: 0xfffffffe, current: 1), 3);
    });

    test('sample delta rejects an unexplained rollback', () {
      expect(
        () => esp32CounterDelta(baseline: 100, current: 7),
        throwsStateError,
      );
    });
  });

  group('LedPulseDetector', () {
    final base = DateTime.utc(2026, 8, 11);
    LedPulseDetector detector({Duration interval = Duration.zero}) {
      final value = LedPulseDetector(
        LedDetectorConfiguration(
          region: const LedRegion(left: .4, top: .4, width: .2, height: .2),
          minPulseInterval: interval,
        ),
      );
      value.calibrate([10, 10, 11]);
      return value;
    }

    int pulses(
      LedPulseDetector detector,
      List<double> values, {
      int stepMs = 200,
    }) {
      var count = 0;
      for (var index = 0; index < values.length; index++) {
        if (detector.process(
          brightness: values[index],
          timestamp: base.add(Duration(milliseconds: index * stepMs)),
        )) {
          count++;
        }
      }
      return count;
    }

    test('dark bright sustained dark produces one pulse', () {
      expect(pulses(detector(), [10, 10, 11, 70, 75, 72, 12]), 1);
    });

    test('two valid flashes produce two pulses', () {
      expect(pulses(detector(), [10, 70, 10, 70, 10]), 2);
    });

    test('ambient noise below rising threshold produces no pulse', () {
      expect(pulses(detector(), [10, 15, 20, 18, 22]), 0);
    });

    test('sustained bright produces at most one pulse', () {
      expect(pulses(detector(), [80, 82, 79, 81]), 1);
    });

    test('hysteresis prevents bounce in the transition band', () {
      expect(pulses(detector(), [10, 70, 40, 50, 42, 29, 70]), 2);
    });

    test('minimum interval rejects a rapid second rising edge', () {
      expect(
        pulses(detector(interval: const Duration(milliseconds: 150)), [
          10,
          70,
          10,
          70,
          10,
        ], stepMs: 40),
        1,
      );
    });

    test('baseline is the mean of valid dark samples', () {
      final value = detector();
      expect(value.baseline, closeTo(10.333333, .00001));
    });

    test('ROI brightness ignores pixels outside the normalized region', () {
      final bytes = List<int>.filled(16, 10);
      bytes[10] = 90;
      expect(
        calculateLumaRoiBrightness(
          bytes: bytes,
          imageWidth: 4,
          imageHeight: 4,
          bytesPerRow: 4,
          bytesPerPixel: 1,
          region: const LedRegion(left: .5, top: .5, width: .25, height: .25),
          sampleStride: 1,
        ),
        90,
      );
    });

    test('integrated source emits one live event per physical flash', () async {
      final frames = _FakeLedBrightnessPort();
      final value = detector();
      final source = LedPulseSource(frames, value);
      final events = <PulseEvent>[];
      final subscription = source.events.listen(events.add);
      await source.start();
      frames.addAll([10, 70, 75, 10, 70, 10]);
      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(2));
      expect(
        events.every((event) => event.source == PulseSourceType.led),
        isTrue,
      );
      await subscription.cancel();
      await source.dispose();
    });
  });
}

final class _FakeLedBrightnessPort implements LedBrightnessPort {
  final _samples =
      StreamController<({double brightness, DateTime timestamp})>.broadcast();
  var _index = 0;

  @override
  Stream<({double brightness, DateTime timestamp})> get samples =>
      _samples.stream;

  void addAll(List<double> values) {
    for (final value in values) {
      _samples.add((
        brightness: value,
        timestamp: DateTime.utc(
          2026,
          8,
          12,
        ).add(Duration(milliseconds: 200 * _index++)),
      ));
    }
  }

  @override
  Future<void> start(LedRegion region) async {}

  @override
  Future<void> stop() async {}
}
