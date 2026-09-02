import 'dart:async';

enum PulseSourceType { manual, led, ble, simulation }

enum PulseSourceStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  ready,
  detecting,
  reconnecting,
  preparing,
  cameraUnavailable,
  error,
  stopped,
}

final class PulseEvent {
  const PulseEvent({
    required this.id,
    required this.source,
    required this.occurredAt,
    required this.receivedAt,
    this.sequence,
    this.diagnostics,
  });

  final String id;
  final PulseSourceType source;
  final DateTime occurredAt;
  final DateTime receivedAt;
  final int? sequence;
  final String? diagnostics;

  String get deduplicationKey => sequence == null
      ? '${source.name}:$id'
      : '${source.name}:sequence:$sequence';
}

final class PulseSourceState {
  const PulseSourceState({
    required this.status,
    this.message,
    this.deviceId,
    this.deviceName,
    this.compromised = false,
  });

  final PulseSourceStatus status;
  final String? message;
  final String? deviceId;
  final String? deviceName;
  final bool compromised;
}

abstract interface class PulseSource {
  PulseSourceType get type;
  Stream<PulseEvent> get events;
  Stream<PulseSourceState> get states;
  PulseSourceState get currentState;

  Future<void> start();
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();
  Future<void> dispose();
}

abstract interface class PulseProgressPort {
  Future<int> acceptPulse(String sampleId, PulseEvent event);
}
