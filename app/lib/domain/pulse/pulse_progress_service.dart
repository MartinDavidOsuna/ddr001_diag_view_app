import '../models.dart';
import '../repositories.dart';
import '../../core/metrology/metrology.dart';
import 'pulse_source.dart';

/// The only operation that turns MANUAL/LED/BLE/SIMULATION events into
/// persisted volume.
final class PulseProgressService implements PulseProgressPort {
  PulseProgressService(this.samples);

  final SampleRepository samples;
  final Set<String> _uncertainSamples = <String>{};
  final Set<String> _acceptedKeys = <String>{};
  Future<void> _tail = Future<void>.value();

  @override
  Future<int> acceptPulse(String sampleId, PulseEvent event) {
    final operation = _tail.then((_) async {
      if (_uncertainSamples.contains(sampleId)) {
        throw StateError(
          'Pulse persistence outcome is uncertain; repeat the sample.',
        );
      }
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
      if (_acceptedKeys.contains(key)) return sample.pulseCount;
      final count = sample.pulseCount + 1;
      try {
        await samples.updateProgress(
          id: sample.id,
          pulseCount: count,
          referenceLiters: count * sample.configuration.litersPerPulse,
          firstPulseAt: sample.pulseCount == 0 ? event.receivedAt : null,
        );
      } catch (error, stack) {
        // A repository may fail after committing. Read back before allowing a
        // retry to consume this sequence twice. No estimate or blind replay.
        Sample? saved;
        try {
          saved = await samples.getById(sampleId);
        } catch (_) {
          _uncertainSamples.add(sampleId);
          Error.throwWithStackTrace(error, stack);
        }
        if (saved?.pulseCount == count &&
            saved?.referenceLitersProgress ==
                count * sample.configuration.litersPerPulse) {
          _acceptedKeys.add(key);
          return count;
        }
        if (saved?.pulseCount != sample.pulseCount ||
            saved?.referenceLitersProgress != sample.referenceLitersProgress) {
          _uncertainSamples.add(sampleId);
        }
        Error.throwWithStackTrace(error, stack);
      }
      // A failed write must never consume the sequence/deduplication key.
      _acceptedKeys.add(key);
      return count;
    });
    // The caller still receives the error. Keep later samples operable instead
    // of permanently poisoning this process-wide persistence queue.
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }
}
