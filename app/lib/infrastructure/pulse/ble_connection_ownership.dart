import 'dart:async';

/// Coordinates ownership, not GATT operations (the plugin serializes those).
final class BleConnectionOwnership {
  static final shared = BleConnectionOwnership();
  final Map<String, Object> _owners = {};
  final Map<String, Completer<void>> _validations = {};

  bool isOwned(String id) => _owners.containsKey(id);

  Future<void> claim(String id, Object owner) {
    final previous = _owners[id];
    if (previous != null && !identical(previous, owner)) {
      throw StateError('El transporte BLE ya tiene propietario.');
    }
    _owners[id] = owner;
    return _validations[id]?.future ?? Future<void>.value();
  }

  void release(String id, Object owner) {
    if (identical(_owners[id], owner)) _owners.remove(id);
  }

  Future<bool> validate(String id, Future<bool> Function() operation) async {
    if (isOwned(id) || _validations.containsKey(id)) return false;
    final done = Completer<void>();
    _validations[id] = done;
    try {
      return await operation();
    } finally {
      _validations.remove(id);
      done.complete();
    }
  }
}
