import 'package:flutter/widgets.dart';

import 'camera_models.dart';

abstract interface class CameraPort {
  Future<CameraPermissionState> requestPermission();
  Future<void> initialize();
  Widget buildPreview();
  double get previewAspectRatio;
  Future<double> getMinZoomLevel();
  Future<double> getMaxZoomLevel();
  Future<void> setZoomLevel(double zoomLevel);
  Future<void> focusAt({required double x, required double y});
  Future<CapturedPhoto> capture();
  Future<void> pause();
  Future<void> resume();
  Future<void> dispose();
  Future<bool> openSettings();
}

abstract interface class LiveCameraAnalysisPort {
  Future<String> captureAnalysisFrame();
  Future<void> stopAnalysisFrames();
}
