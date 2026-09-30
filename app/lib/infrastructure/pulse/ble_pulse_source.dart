import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'ble_permissions.dart';

import 'ble_connection_ownership.dart';
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

final class BlePulseSource with WidgetsBindingObserver implements PulseSource {
  BlePulseSource(
    this._configuration, [
    this._protocol = const Esp32CounterProtocol(),
    this._uuid = const ids.Uuid(),
  ]);

  @visibleForTesting
  BlePulseSource.withDevice(
    this._configuration,
    BluetoothDevice device, {
    this.hasPermission,
    this.adapterState,
  }) : _device = device,
       _testDevice = true,
       _protocol = const Esp32CounterProtocol(),
       _uuid = const ids.Uuid();

  final BlePulseConfiguration _configuration;
  final Esp32CounterProtocol _protocol;
  late final Esp32CounterReconciler _reconciler = Esp32CounterReconciler(
    lastObservedCounter: _configuration.lastObservedCounter,
  );
  final ids.Uuid _uuid;
  final _events = StreamController<PulseEvent>.broadcast(sync: true);
  final _states = StreamController<PulseSourceState>.broadcast();
  final _counters = StreamController<int>.broadcast();
  final _meterUnderTestCounters = StreamController<int>.broadcast();
  StreamSubscription<BluetoothConnectionState>? _connection;
  StreamSubscription<List<int>>? _notifications;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _counterCharacteristic;
  Timer? _keepAliveTimer;
  Future<bool> Function()? hasPermission;
  Future<BluetoothAdapterState> Function()? adapterState;
  bool _testDevice = false;
  bool _observingLifecycle = false;
  int _receivedPayloads = 0;
  StreamSubscription<BluetoothAdapterState>? _adapter;
  bool _recovering = false;
  bool _disposed = false;
  bool _stopping = false;
  bool _integrityFailed = false;
  int _generation = 0;
  int _gattGeneration = 0;
  Future<void>? _ownershipTask;
  Future<void>? _startTask;
  Future<void>? _connectTask;
  Future<void>? _recoveryTask;
  Future<void>? _probeTask;
  Future<void>? _stopTask;
  Future<void>? _disposeTask;
  Timer? _retryTimer;
  Completer<void>? _retryWaiter;
  int? _lastPublishedMeterUnderTestCounter;
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
  Stream<int> get meterUnderTestCounters => _meterUnderTestCounters.stream;
  int? get lastObservedCounter => _reconciler.lastObservedCounter;
  String get deviceId => _configuration.deviceId;

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
    _log('BLE_STATE', 'counter=$lastObservedCounter');
    _states.add(_state);
  }

  bool _active(int generation) =>
      !_disposed &&
      !_stopping &&
      !_integrityFailed &&
      generation == _generation;

  void _log(String event, [String detail = '']) {
    debugPrintSynchronously(
      'DDR001 ${DateTime.now().toUtc().toIso8601String()} '
      'session=$_generation gatt=$_gattGeneration state=${_state.status.name} '
      '$event $detail',
    );
  }

  @override
  Future<void> start() {
    if (_disposed || _disposeTask != null) {
      return Future.error(StateError('BLE source already disposed.'));
    }
    return _startTask ??= _start(
      _generation,
    ).whenComplete(() => _startTask = null);
  }

  Future<void> _start(int requestedGeneration) async {
    await _stopTask;
    if (requestedGeneration != _generation ||
        _disposed ||
        _disposeTask != null ||
        _integrityFailed ||
        _recovering ||
        _state.status == PulseSourceStatus.ready) {
      return;
    }
    _stopping = false;
    final generation = ++_generation;
    await (_ownershipTask = BleConnectionOwnership.shared
        .claim(deviceId, this)
        .whenComplete(() => _ownershipTask = null));
    if (!_active(generation)) return;
    if (!_observingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
    }
    if (!_testDevice) {
      await _adapter?.cancel();
      if (!_active(generation)) return;
      _adapter = FlutterBluePlus.adapterState.listen(
        (state) {
          if (!_active(generation)) return;
          if (state == BluetoothAdapterState.on) {
            unawaited(verifyConnection());
          } else if (state != BluetoothAdapterState.unknown) {
            ++_gattGeneration;
            _keepAliveTimer?.cancel();
            _set(
              PulseSourceStatus.error,
              message: 'Bluetooth apagado o no disponible. Active Bluetooth.',
            );
          }
        },
        onError: (Object error) {
          if (_active(generation)) {
            _set(
              PulseSourceStatus.error,
              message: 'Revise los permisos Bluetooth.',
            );
          }
        },
      );
    }
    await _connection?.cancel();
    if (!_active(generation)) return;
    _set(PulseSourceStatus.connecting);
    final device = _device ??= BluetoothDevice.fromId(_configuration.deviceId);
    _connection = device.connectionState.listen(
      (state) {
        if (_active(generation)) _onConnection(state);
      },
      onError: (Object error, StackTrace stack) {
        if (_active(generation)) unawaited(_recoverConnection(error));
      },
      onDone: () {
        if (_active(generation)) {
          unawaited(_recoverConnection('Flujo de conexión cerrado'));
        }
      },
    );
    try {
      await _connect(device, generation);
    } catch (error) {
      if (_active(generation)) unawaited(_recoverConnection(error));
    }
  }

  Future<void> _connect(BluetoothDevice device, int generation) =>
      _connectTask ??= _prepareGatt(
        device,
        generation,
      ).whenComplete(() => _connectTask = null);

  Future<void> _prepareGatt(BluetoothDevice device, int generation) async {
    await _notifications?.cancel();
    _notifications = null;
    _counterCharacteristic = null;
    if (!_active(generation)) return;
    if (!await _environmentAvailable() || !_active(generation)) return;
    _log('BLE_CONNECT_START');
    if (!device.isConnected) {
      await device.connect(timeout: const Duration(seconds: 12));
    }
    if (!_active(generation)) return;
    final gattGeneration = ++_gattGeneration;
    void ensureCurrent() {
      if (!_active(generation) ||
          gattGeneration != _gattGeneration ||
          !device.isConnected) {
        throw StateError('La operación GATT ya no pertenece al enlace activo.');
      }
    }

    ensureCurrent();
    _set(PulseSourceStatus.connected);
    _log('BLE_GATT_DISCOVERY');
    final services = await device.discoverServices();
    ensureCurrent();
    final service = services
        .where((item) => item.uuid == Guid(_configuration.serviceUuid))
        .firstOrNull;
    if (service == null) throw StateError('Servicio BLE no encontrado.');
    final characteristic = service.characteristics
        .where((item) => item.uuid == Guid(_configuration.characteristicUuid))
        .firstOrNull;
    if (characteristic == null) {
      throw StateError('Característica BLE no encontrada.');
    }
    _counterCharacteristic = characteristic;
    List<List<int>>? pendingPayloads = [];
    _notifications = characteristic.onValueReceived.listen(
      (payload) {
        if (_active(generation) && gattGeneration == _gattGeneration) {
          ++_receivedPayloads;
          if (pendingPayloads != null) {
            pendingPayloads.add(List<int>.of(payload));
          } else {
            _onPayload(payload);
          }
        }
      },
      onError: (Object error, StackTrace stack) {
        if (_active(generation) && gattGeneration == _gattGeneration) {
          ++_gattGeneration;
          unawaited(_recoverConnection(error));
        }
      },
      onDone: () {
        if (_active(generation) && gattGeneration == _gattGeneration) {
          ++_gattGeneration;
          unawaited(_recoverConnection('Notificaciones cerradas'));
        }
      },
    );
    if (!await characteristic.setNotifyValue(true)) {
      throw StateError('No se pudo activar NOTIFY.');
    }
    ensureCurrent();
    _log('BLE_NOTIFY_READY');
    final payload = await characteristic.read();
    ensureCurrent();
    if (_protocol.parse(payload) == null) {
      throw StateError('No se pudo leer un contador ESP32 válido.');
    }
    // The plugin emits READ through onValueReceived before completing read().
    // Consume that ordered stream once; the returned value may already be old.
    final buffered = pendingPayloads;
    pendingPayloads = null;
    for (final value in buffered.isEmpty ? [payload] : buffered) {
      _onPayload(value, initialRead: true);
    }
    if (!_active(generation)) return;
    _set(PulseSourceStatus.ready);
    _log('BLE_GATT_READY', 'read=valid counter=$lastObservedCounter');
    _startKeepAlive();
  }

  void _onConnection(BluetoothConnectionState connectionState) {
    if (_disposed || _stopping || _integrityFailed) return;
    if (connectionState == BluetoothConnectionState.disconnected &&
        _device?.isConnected != true) {
      ++_gattGeneration;
      _keepAliveTimer?.cancel();
      if (_connectTask == null || _state.status == PulseSourceStatus.ready) {
        _log('BLE_LINK_LOST');
        unawaited(_recoverConnection('ESP32 no disponible'));
      }
    }
  }

  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(_probe());
    });
  }

  Future<void> _probe() =>
      _probeTask ??= _probeKeepAlive().whenComplete(() => _probeTask = null);

  Future<bool> _environmentAvailable() async {
    final generation = _generation;
    final permitted =
        await (hasPermission?.call() ??
            (_testDevice ? Future.value(true) : BlePermissions.canConnect()));
    if (!_active(generation)) return false;
    if (!permitted) {
      _keepAliveTimer?.cancel();
      ++_gattGeneration;
      _set(
        PulseSourceStatus.error,
        message:
            'Permiso Bluetooth denegado. Habilítelo en Ajustes y vuelva a la app.',
      );
      return false;
    }
    final adapter =
        await (adapterState?.call() ??
            (_testDevice
                ? Future.value(BluetoothAdapterState.on)
                : FlutterBluePlus.adapterState.first));
    if (!_active(generation)) return false;
    if (adapter != BluetoothAdapterState.on) {
      _keepAliveTimer?.cancel();
      ++_gattGeneration;
      _set(
        PulseSourceStatus.error,
        message: 'Bluetooth apagado o no disponible. Active Bluetooth.',
      );
      return false;
    }
    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _log('BLE_LIFECYCLE', state.name);
    if (state == AppLifecycleState.resumed) unawaited(verifyConnection());
  }

  Future<void> verifyConnection() async {
    final generation = _generation;
    if (!_active(generation) ||
        _startTask != null ||
        _connectTask != null ||
        _recovering) {
      return;
    }
    try {
      if (!await _environmentAvailable() || !_active(generation)) return;
      if (_device?.isConnected == true &&
          _state.status == PulseSourceStatus.ready) {
        await _probe();
      } else {
        await _recoverConnection('Verificación de enlace al reanudar');
      }
    } catch (error) {
      if (_active(generation)) unawaited(_recoverConnection(error));
    }
  }

  Future<void> _probeKeepAlive() async {
    final characteristic = _counterCharacteristic;
    final generation = _generation;
    final gattGeneration = _gattGeneration;
    if (!_active(generation) || characteristic == null || _recovering) return;
    final receivedBeforeRead = _receivedPayloads;
    final watch = Stopwatch()..start();
    try {
      final payload = await characteristic.read();
      if (!_active(generation) || gattGeneration != _gattGeneration) return;
      if (_protocol.parse(payload) == null) {
        throw StateError('Keepalive sin contador ESP32 válido.');
      }
      if (_receivedPayloads == receivedBeforeRead) _onPayload(payload);
      if (watch.elapsedMilliseconds > 10000) {
        _log('BLE_KEEPALIVE_SLOW', 'ms=${watch.elapsedMilliseconds}');
      }
    } catch (error) {
      if (_active(generation) && gattGeneration == _gattGeneration) {
        _log(
          'BLE_KEEPALIVE_FAILED',
          'ms=${watch.elapsedMilliseconds} type=${error.runtimeType}',
        );
        unawaited(_recoverConnection(error));
      }
    }
  }

  Future<void> _recoverConnection(Object reason) {
    if (!_active(_generation)) return Future.value();
    return _recoveryTask ??= _recover(
      reason,
    ).whenComplete(() => _recoveryTask = null);
  }

  Future<void> _recover(Object reason) async {
    _log(
      'BLE_RECOVERY',
      'reason=${reason is String ? reason : reason.runtimeType}',
    );
    _recovering = true;
    final generation = _generation;
    ++_gattGeneration;
    _keepAliveTimer?.cancel();
    _set(
      PulseSourceStatus.reconnecting,
      message: 'ESP32 sin respuesta; recuperando conexión y contador.',
    );
    try {
      try {
        await _connectTask;
        await _probeTask;
      } catch (_) {}
      const delays = [1, 2, 4, 8, 15, 30];
      var attempt = 0;
      var connectedGattFailures = 0;
      while (_active(generation)) {
        if (!await _environmentAvailable() || !_active(generation)) return;
        final delay =
            delays[attempt < delays.length ? attempt : delays.length - 1];
        final waiter = Completer<void>();
        _retryWaiter = waiter;
        _retryTimer = Timer(Duration(seconds: delay), waiter.complete);
        await waiter.future;
        _retryTimer = null;
        _retryWaiter = null;
        if (!_active(generation)) return;
        attempt++;
        _log('BLE_RECONNECT_ATTEMPT', 'attempt=$attempt');
        try {
          final device = _device ??= BluetoothDevice.fromId(
            _configuration.deviceId,
          );
          await _connect(device, generation);
          if (!_active(generation)) return;
          if (_state.status == PulseSourceStatus.ready) {
            _log('BLE_RECONNECTED');
            return;
          }
        } catch (error) {
          if (!_active(generation)) return;
          _log('BLE_RECONNECT_FAILED', 'type=${error.runtimeType}');
          // Three complete GATT preparations failed on a still-connected link.
          // A single read failure never forces a physical disconnect.
          connectedGattFailures = _device?.isConnected == true
              ? connectedGattFailures + 1
              : 0;
          if (connectedGattFailures >= 3) {
            connectedGattFailures = 0;
            _log('BLE_GATT_RESET', 'attempt=$attempt');
            await _device!.disconnect();
            if (!_active(generation)) return;
          }
          _set(
            PulseSourceStatus.reconnecting,
            message: 'ESP32 en recuperación (intento $attempt). $error',
          );
        }
      }
    } catch (error) {
      if (_active(generation)) {
        _log('BLE_ENVIRONMENT_FAILED', 'type=${error.runtimeType}');
        _set(
          PulseSourceStatus.error,
          message: 'Bluetooth no disponible. Revise Bluetooth y permisos.',
        );
      }
    } finally {
      _recovering = false;
    }
  }

  void _onPayload(List<int> payload, {bool initialRead = false}) {
    if (!_active(_generation) ||
        (!initialRead && _state.status != PulseSourceStatus.ready)) {
      return;
    }
    final parsed = _protocol.parse(payload);
    if (parsed == null) return;
    final observation = _reconciler.observe(parsed.counter);
    if (observation.status == CounterObservationStatus.rollback) {
      _integrityFailed = true;
      _keepAliveTimer?.cancel();
      _log('BLE_COUNTER_ROLLBACK');
      _set(
        PulseSourceStatus.error,
        compromised: true,
        message: 'El contador ESP32 retrocedió; el conteo no es verificable.',
      );
      return;
    }
    if (initialRead && observation.delta > 0) {
      _log('BLE_COUNTER_RECONCILED', 'delta=${observation.delta}');
    }
    final meterCounter = parsed.meterUnderTestCounter;
    if (meterCounter != null &&
        meterCounter != _lastPublishedMeterUnderTestCounter) {
      _lastPublishedMeterUnderTestCounter = meterCounter;
      _meterUnderTestCounters.add(meterCounter);
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
    // Queue progress before its persisted counter checkpoint.
    if (observation.status != CounterObservationStatus.duplicate) {
      _counters.add(parsed.counter);
    }
  }

  @override
  Future<void> pause() => stop();
  @override
  Future<void> resume() => start();

  @override
  Future<void> stop() =>
      _stopTask ??= _stop().whenComplete(() => _stopTask = null);

  Future<void> _stop() async {
    _log('BLE_STOP_REQUEST');
    _stopping = true;
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _observingLifecycle = false;
    }
    ++_generation;
    ++_gattGeneration;
    await _adapter?.cancel();
    _adapter = null;
    _retryTimer?.cancel();
    if (_retryWaiter?.isCompleted == false) _retryWaiter!.complete();
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    _counterCharacteristic = null;
    await _notifications?.cancel();
    _notifications = null;
    await _connection?.cancel();
    _connection = null;
    await _ownershipTask;
    try {
      await _device?.disconnect();
    } catch (_) {
      _log('BLE_STOP_DISCONNECT_FAILED');
    }
    try {
      await _connectTask;
      await _probeTask;
      await _recoveryTask;
    } catch (_) {}
    if (_device?.isConnected == true) {
      try {
        await _device?.disconnect();
      } catch (_) {
        _log('BLE_STOP_DISCONNECT_FAILED');
      }
    }
    BleConnectionOwnership.shared.release(deviceId, this);
    _log('BLE_STOPPED');
    _set(PulseSourceStatus.stopped);
  }

  @override
  Future<void> dispose() => _disposeTask ??= _dispose();

  Future<void> _dispose() async {
    await stop();
    _disposed = true;
    await _events.close();
    await _states.close();
    await _counters.close();
    await _meterUnderTestCounters.close();
  }
}
