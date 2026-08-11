import 'package:flutter/widgets.dart';

import 'camera_models.dart';

abstract interface class CameraPort {
  Future<CameraPermissionState> requestPermission();
  Future<void> initialize();
  Widget buildPreview();
  Future<CapturedPhoto> capture();
  Future<void> pause();
  Future<void> resume();
  Future<void> dispose();
  Future<bool> openSettings();
}
