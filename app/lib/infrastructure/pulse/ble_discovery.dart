import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/pulse/esp32_counter_protocol.dart';

final class BleDeviceCandidate {
  const BleDeviceCandidate({
    required this.id,
    required this.name,
    required this.rssi,
  });
  final String id;
  final String name;
  final int rssi;
}

final class BleDiscoveryService {
  static bool isDdr001Esp32Advertisement({
    required String name,
    required Iterable<String> serviceUuids,
  }) {
    final normalizedServices = serviceUuids.map((uuid) => uuid.toLowerCase());
    return name.startsWith(Ddr001BleContract.advertisedNamePrefix) &&
        normalizedServices.contains(Ddr001BleContract.serviceUuid);
  }

  Future<List<BleDeviceCandidate>> scan() async {
    final permissions = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    if (permissions.values.any((status) => !status.isGranted)) {
      throw StateError('Se requieren permisos Bluetooth para buscar el ESP32.');
    }
    final found = <String, BleDeviceCandidate>{};
    final subscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        final name = result.advertisementData.advName;
        if (isDdr001Esp32Advertisement(
          name: name,
          serviceUuids: result.advertisementData.serviceUuids.map(
            (uuid) => uuid.toString(),
          ),
        )) {
          found[result.device.remoteId.str] = BleDeviceCandidate(
            id: result.device.remoteId.str,
            name: name.isEmpty ? 'DDR001 ESP32' : name,
            rssi: result.rssi,
          );
        }
      }
    });
    await FlutterBluePlus.startScan(
      withServices: [Guid(Ddr001BleContract.serviceUuid)],
      timeout: const Duration(seconds: 6),
    );
    await FlutterBluePlus.isScanning.where((value) => !value).first;
    await subscription.cancel();
    final validated = <BleDeviceCandidate>[];
    for (final candidate in found.values) {
      if (await _validateGattContract(candidate)) validated.add(candidate);
    }
    final values = validated..sort((a, b) => b.rssi.compareTo(a.rssi));
    return values;
  }

  Future<bool> _validateGattContract(BleDeviceCandidate candidate) async {
    final device = BluetoothDevice.fromId(candidate.id);
    final wasConnected = device.isConnected;
    try {
      if (!wasConnected) {
        await device.connect(timeout: const Duration(seconds: 8));
      }
      final services = await device.discoverServices();
      final service = services
          .where(
            (item) =>
                item.uuid.toString().toLowerCase() ==
                Ddr001BleContract.serviceUuid,
          )
          .firstOrNull;
      if (service == null) return false;
      final counter = service.characteristics
          .where(
            (item) =>
                item.uuid.toString().toLowerCase() ==
                Ddr001BleContract.counterCharacteristicUuid,
          )
          .firstOrNull;
      if (counter == null) return false;
      return const Esp32CounterProtocol().parse(await counter.read()) != null;
    } catch (_) {
      return false;
    } finally {
      if (!wasConnected && device.isConnected) await device.disconnect();
    }
  }
}
