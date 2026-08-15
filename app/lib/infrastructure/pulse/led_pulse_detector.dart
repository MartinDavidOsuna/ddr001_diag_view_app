import 'dart:async';

import '../../domain/pulse/pulse_source.dart';

enum LedLevel { dark, bright }

final class LedRegion {
  const LedRegion({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  }) : assert(left >= 0 && top >= 0 && width > 0 && height > 0),
       assert(left + width <= 1 && top + height <= 1);

  final double left;
  final double top;
  final double width;
  final double height;
}

double calculateLumaRoiBrightness({
  required List<int> bytes,
  required int imageWidth,
  required int imageHeight,
  required int bytesPerRow,
  required int bytesPerPixel,
  required LedRegion region,
  int sampleStride = 2,
}) {
  final left = (region.left * imageWidth).floor();
  final top = (region.top * imageHeight).floor();
  final right = ((region.left + region.width) * imageWidth).ceil();
  final bottom = ((region.top + region.height) * imageHeight).ceil();
  var sum = 0;
  var count = 0;
  for (var y = top; y < bottom; y += sampleStride) {
    final row = y * bytesPerRow;
    for (var x = left; x < right; x += sampleStride) {
      final index = row + x * bytesPerPixel;
      if (index < bytes.length) {
        sum += bytes[index];
        count++;
      }
    }
  }
  return count == 0 ? 0 : sum / count;
}

final class LedDetectorConfiguration {
  const LedDetectorConfiguration({
    required this.region,
    this.risingDelta = 35,
    this.fallingDelta = 20,
    this.minPulseInterval = const Duration(milliseconds: 150),
  }) : assert(risingDelta > fallingDelta),
       assert(fallingDelta >= 0);

  final LedRegion region;
  final double risingDelta;
  final double fallingDelta;
  final Duration minPulseInterval;
}

final class LedPulseDetector {
  LedPulseDetector(this.configuration);

  final LedDetectorConfiguration configuration;
  double? _baseline;
  LedLevel _level = LedLevel.dark;
  DateTime? _lastPulse;

  double? get baseline => _baseline;
  LedLevel get level => _level;

  void calibrate(Iterable<double> darkSamples) {
    final values = darkSamples.where((value) => value.isFinite).toList();
    if (values.isEmpty) throw ArgumentError('Baseline samples are required.');
    _baseline = values.reduce((a, b) => a + b) / values.length;
    _level = LedLevel.dark;
    _lastPulse = null;
  }

  bool process({required double brightness, required DateTime timestamp}) {
    final baseline = _baseline;
    if (baseline == null || !brightness.isFinite) return false;
    final rising = baseline + configuration.risingDelta;
    final falling = baseline + configuration.fallingDelta;
    if (_level == LedLevel.dark && brightness >= rising) {
      _level = LedLevel.bright;
      final previous = _lastPulse;
      if (previous == null ||
          timestamp.difference(previous) >= configuration.minPulseInterval) {
        _lastPulse = timestamp;
        return true;
      }
    } else if (_level == LedLevel.bright && brightness <= falling) {
      _level = LedLevel.dark;
    }
    return false;
  }
}

abstract interface class LedBrightnessPort {
  Stream<({double brightness, DateTime timestamp})> get samples;
  Future<void> start(LedRegion region);
  Future<void> stop();
}

final class LedPulseSource implements PulseSource {
  LedPulseSource(this._frames, this._detector);

  final LedBrightnessPort _frames;
  final LedPulseDetector _detector;
  final _events = StreamController<PulseEvent>.broadcast();
  final _states = StreamController<PulseSourceState>.broadcast();
  StreamSubscription<({double brightness, DateTime timestamp})>? _subscription;
  PulseSourceState _state = const PulseSourceState(
    status: PulseSourceStatus.disconnected,
  );
  int _eventId = 0;
  bool _disposed = false;

  @override
  PulseSourceType get type => PulseSourceType.led;
  @override
  Stream<PulseEvent> get events => _events.stream;
  @override
  Stream<PulseSourceState> get states => _states.stream;
  @override
  PulseSourceState get currentState => _state;

  void _set(
    PulseSourceStatus status, {
    String? message,
    bool compromised = false,
  }) {
    if (_disposed) return;
    _state = PulseSourceState(
      status: status,
      message: message,
      compromised: compromised,
    );
    _states.add(_state);
  }

  @override
  Future<void> start() async {
    if (_detector.baseline == null) {
      throw StateError('LED baseline must be calibrated before start.');
    }
    await _subscription?.cancel();
    _set(PulseSourceStatus.preparing);
    await _frames.start(_detector.configuration.region);
    _subscription = _frames.samples.listen(
      (sample) {
        if (_detector.process(
          brightness: sample.brightness,
          timestamp: sample.timestamp,
        )) {
          _events.add(
            PulseEvent(
              id: 'led-${_eventId++}',
              source: PulseSourceType.led,
              occurredAt: sample.timestamp,
              receivedAt: DateTime.now().toUtc(),
              diagnostics: 'brightness=${sample.brightness.toStringAsFixed(2)}',
            ),
          );
        }
      },
      onError: (Object error, StackTrace stack) {
        _set(
          PulseSourceStatus.error,
          compromised: true,
          message: 'Falla de cámara LED: $error',
        );
      },
    );
    _set(PulseSourceStatus.detecting);
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _frames.stop();
    _set(PulseSourceStatus.stopped);
  }

  @override
  Future<void> pause() async {
    await stop();
    _set(
      PulseSourceStatus.cameraUnavailable,
      compromised: true,
      message:
          'Detector LED detenido: no se puede garantizar el conteo durante la pausa.',
    );
  }

  @override
  Future<void> resume() => start();
  @override
  Future<void> dispose() async {
    await stop();
    _disposed = true;
    await _events.close();
    await _states.close();
  }
}
