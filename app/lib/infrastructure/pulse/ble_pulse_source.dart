import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uuid/uuid.dart' as ids;

import '../../domain/pulse/pulse_source.dart';
import '../../domain/pulse/esp32_counter_protocol.dart';

final class BlePulseConfiguration {
  const BlePulseConfiguration({
    required this.deviceId,
    required this.serviceUuid,
    required this.characteristicUuid,
    this.deviceName,
    this.lastObservedCounter,
  });

  final String deviceId;
  final String? deviceName;
  final String serviceUuid;
  final String characteristicUuid;
  final int? lastObservedCounter;
}

final class BlePulseSource implements PulseSource {
  BlePulseSource(
    this._configuration, [
    this._protocol = const Esp32CounterProtocol(),
    this._uuid = const ids.Uuid(),
  ]);

  final BlePulseConfiguration _configuration;
  final Esp32CounterProtocol _protocol;
  late final Esp32CounterReconciler _reconciler = Esp32CounterReconciler(
    lastObservedCounter: _configuration.lastObservedCounter,
  );
  final ids.Uuid _uuid;
  final _events = StreamController<PulseEvent>.broadcast();
  final _states = StreamController<PulseSourceState>.broadcast();
  final _counters = StreamController<int>.broadcast();
  StreamSubscription<BluetoothConnectionState>? _connection;
  StreamSubscription<List<int>>? _notifications;
  BluetoothDevice? _device;
  Timer? _reconnectTimer;
  bool _disposed = false;
  bool _stopping = false;
  PulseSourceState _state = const PulseSourceState(
    status: PulseSourceStatus.disconnected,
  );

  @override
  PulseSourceType get type => PulseSourceType.ble;
  @override
  Stream<PulseEvent> get events => _events.stream;
  @override
  Stream<PulseSourceState> get states => _states.stream;
  @override
  PulseSourceState get currentState => _state;
  Stream<int> get counters => _counters.stream;
  int? get lastObservedCounter => _reconciler.lastObservedCounter;

  void _set(
    PulseSourceStatus status, {
    String? message,
    bool compromised = false,
  }) {
    if (_disposed) return;
    _state = PulseSourceState(
      status: status,
      message: message,
      deviceId: _configuration.deviceId,
      deviceName: _configuration.deviceName,
      compromised: compromised,
    );
    _states.add(_state);
  }

  @override
  Future<void> start() async {
    if (_disposed) throw StateError('BLE source already disposed.');
    _stopping = false;
    await _connection?.cancel();
    await _notifications?.cancel();
    _set(PulseSourceStatus.connecting);
    final device = BluetoothDevice.fromId(_configuration.deviceId);
    _device = device;
    _connection = device.connectionState.listen(
      _onConnection,
      onError: _onConnectionError,
    );
    await device.connect(timeout: const Duration(seconds: 12));
  }

  Future<void> _onConnection(BluetoothConnectionState connectionState) async {
    if (_disposed || _stopping) return;
    switch (connectionState) {
      case BluetoothConnectionState.connected:
        _set(PulseSourceStatus.connected);
        await _notifications?.cancel();
        final services = await _device!.discoverServices();
        final serviceUuid = Guid(_configuration.serviceUuid);
        final characteristicUuid = Guid(_configuration.characteristicUuid);
        final service = services
            .where((item) => item.uuid == serviceUuid)
            .firstOrNull;
        if (service == null) {
          _set(PulseSourceStatus.error, message: 'Servicio BLE no encontrado.');
          return;
        }
        final characteristic = service.characteristics
            .where((item) => item.uuid == characteristicUuid)
            .firstOrNull;
        if (characteristic == null) {
          _set(
            PulseSourceStatus.error,
            message: 'Característica BLE no encontrada.',
          );
          return;
        }
        _notifications = characteristic.onValueReceived.listen(
          _onPayload,
          onError: _onNotificationError,
        );
        await characteristic.setNotifyValue(true);
        _set(PulseSourceStatus.ready);
        _onPayload(await characteristic.read());
      case BluetoothConnectionState.disconnected:
        _set(
          PulseSourceStatus.reconnecting,
          message: 'Conexión perdida; reconciliando contador ESP32.',
        );
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(const Duration(seconds: 2), () {
          if (!_disposed && !_stopping) unawaited(start());
        });
      default:
        _set(PulseSourceStatus.connecting);
    }
  }

  static const _loss =
      'Conexión perdida. No se puede garantizar que los pulsos ocurridos durante la desconexión hayan sido registrados.';

  void _onPayload(List<int> payload) {
    if (_disposed || _state.status != PulseSourceStatus.ready) return;
    final parsed = _protocol.parse(payload);
    if (parsed == null) return;
    final observation = _reconciler.observe(parsed.counter);
    _counters.add(parsed.counter);
    if (observation.status == CounterObservationStatus.rollback) {
      _set(
        PulseSourceStatus.error,
        compromised: true,
        message: 'El contador ESP32 retrocedió; el conteo no es verificable.',
      );
      return;
    }
    final now = DateTime.now().toUtc();
    for (var offset = 0; offset < observation.delta; offset++) {
      final sequence = parsed.counter - observation.delta + offset + 1;
      _events.add(
        PulseEvent(
          id: _uuid.v4(),
          source: PulseSourceType.ble,
          occurredAt: now,
          receivedAt: now,
          sequence: sequence & 0xffffffff,
          diagnostics: 'esp32Counter=${parsed.counter}',
        ),
      );
    }
  }

  void _onConnectionError(Object error, StackTrace stackTrace) => _set(
    PulseSourceStatus.error,
    compromised: true,
    message: 'Error BLE: $error. $_loss',
  );

  void _onNotificationError(Object error, StackTrace stackTrace) => _set(
    PulseSourceStatus.error,
    compromised: true,
    message: 'Suscripción BLE interrumpida: $error. $_loss',
  );

  @override
  Future<void> pause() => stop();
  @override
  Future<void> resume() => start();

  @override
  Future<void> stop() async {
    _stopping = true;
    _reconnectTimer?.cancel();
    await _notifications?.cancel();
    _notifications = null;
    await _connection?.cancel();
    _connection = null;
    await _device?.disconnect();
    _device = null;
    _set(PulseSourceStatus.stopped);
  }

  @override
  Future<void> dispose() async {
    await stop();
    _disposed = true;
    await _events.close();
    await _states.close();
    await _counters.close();
  }
}
