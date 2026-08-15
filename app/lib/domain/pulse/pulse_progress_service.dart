import '../models.dart';
import '../repositories.dart';
import '../../core/metrology/metrology.dart';
import 'pulse_source.dart';

/// The only operation that turns MANUAL/LED/BLE events into persisted volume.
final class PulseProgressService implements PulseProgressPort {
  PulseProgressService(this.samples);

  final SampleRepository samples;
  final Set<String> _acceptedKeys = <String>{};
  Future<void> _tail = Future<void>.value();

  @override
  Future<int> acceptPulse(String sampleId, PulseEvent event) {
    final result = <int>[];
    _tail = _tail.then((_) async {
      final key = '$sampleId:${event.deduplicationKey}';
      final sample = await samples.getById(sampleId);
      if (sample == null || sample.status != SampleStatus.running) {
        throw StateError('Pulse received without a RUNNING sample.');
      }
      if (!sample.configuration.measurementMethod.isPulseEventSource) {
        throw StateError('VISUAL cannot accept pulse events.');
      }
      if (sample.configuration.measurementMethod.name != event.source.name) {
        throw StateError(
          'Pulse source does not match the frozen sample method.',
        );
      }
      if (!_acceptedKeys.add(key)) {
        result.add(sample.pulseCount);
        return;
      }
      final count = sample.pulseCount + 1;
      await samples.updateProgress(
        id: sample.id,
        pulseCount: count,
        referenceLiters: count * sample.configuration.litersPerPulse,
      );
      result.add(count);
    });
    return _tail.then((_) => result.single);
  }
}
