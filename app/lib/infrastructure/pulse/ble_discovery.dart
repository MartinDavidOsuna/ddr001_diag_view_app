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
        final hasService = result.advertisementData.serviceUuids.any(
          (uuid) =>
              uuid.toString().toLowerCase() == Ddr001BleContract.serviceUuid,
        );
        if (hasService ||
            name.startsWith(Ddr001BleContract.advertisedNamePrefix)) {
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
    final values = found.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    return values;
  }
}
