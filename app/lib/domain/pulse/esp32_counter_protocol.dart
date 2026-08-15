import 'dart:typed_data';

abstract final class Ddr001BleContract {
  static const protocolVersion = 1;
  static const serviceUuid = '7b3a0001-6d5f-4f3c-9a21-4d4452303031';
  static const counterCharacteristicUuid =
      '7b3a0002-6d5f-4f3c-9a21-4d4452303031';
  static const statusCharacteristicUuid =
      '7b3a0003-6d5f-4f3c-9a21-4d4452303031';
  static const advertisedNamePrefix = 'DDR001-PULSE-';
}

final class Esp32CounterPayload {
  const Esp32CounterPayload({required this.version, required this.counter});
  final int version;
  final int counter;
}

final class Esp32CounterProtocol {
  const Esp32CounterProtocol();

  Esp32CounterPayload? parse(List<int> payload) {
    if (payload.length != 5 ||
        payload.first != Ddr001BleContract.protocolVersion) {
      return null;
    }
    final data = ByteData.sublistView(Uint8List.fromList(payload));
    return Esp32CounterPayload(
      version: payload.first,
      counter: data.getUint32(1, Endian.little),
    );
  }
}

enum CounterObservationStatus { baseline, duplicate, advanced, rollback }

final class CounterObservation {
  const CounterObservation({required this.status, required this.delta});
  final CounterObservationStatus status;
  final int delta;
}

final class Esp32CounterReconciler {
  Esp32CounterReconciler({int? lastObservedCounter})
    : _last = lastObservedCounter;

  int? _last;
  int? get lastObservedCounter => _last;

  CounterObservation observe(int current) {
    if (current < 0 || current > 0xffffffff) {
      throw ArgumentError.value(current, 'current');
    }
    final previous = _last;
    _last = current;
    if (previous == null) {
      return const CounterObservation(
        status: CounterObservationStatus.baseline,
        delta: 0,
      );
    }
    if (current == previous) {
      return const CounterObservation(
        status: CounterObservationStatus.duplicate,
        delta: 0,
      );
    }
    if (current > previous) {
      return CounterObservation(
        status: CounterObservationStatus.advanced,
        delta: current - previous,
      );
    }
    // Accept only the unmistakable uint32 wrap window. Other rollback means
    // reboot/different device and compromises acquisition.
    if (previous >= 0xffff0000 && current <= 0x0000ffff) {
      return CounterObservation(
        status: CounterObservationStatus.advanced,
        delta: (0x100000000 - previous) + current,
      );
    }
    return const CounterObservation(
      status: CounterObservationStatus.rollback,
      delta: 0,
    );
  }
}

int esp32CounterDelta({required int baseline, required int current}) {
  if (baseline < 0 || baseline > 0xffffffff) {
    throw ArgumentError.value(baseline, 'baseline');
  }
  if (current < 0 || current > 0xffffffff) {
    throw ArgumentError.value(current, 'current');
  }
  if (current >= baseline) return current - baseline;
  if (baseline >= 0xffff0000 && current <= 0x0000ffff) {
    return (0x100000000 - baseline) + current;
  }
  throw StateError('ESP32 counter rollback cannot be reconciled.');
}
