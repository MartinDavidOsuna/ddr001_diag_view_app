import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Android 12 split Bluetooth permissions; older Android scans use location.
final class BlePermissions {
  static Future<int>? _sdk;
  static Future<bool> get _modern async =>
      await (_sdk ??= DeviceInfoPlugin().androidInfo.then(
        (info) => info.version.sdkInt,
      )) >=
      31;

  static Future<bool> canConnect() async =>
      !await _modern || await Permission.bluetoothConnect.isGranted;

  static Future<bool> requestScan() async {
    final permissions =
        await (await _modern
                ? [Permission.bluetoothScan, Permission.bluetoothConnect]
                : [Permission.locationWhenInUse])
            .request();
    return permissions.values.every((status) => status.isGranted);
  }
}
