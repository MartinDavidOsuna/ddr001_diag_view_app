import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'camera_models.dart';
import 'camera_port.dart';

final class FlutterCameraAdapter implements CameraPort {
  CameraController? _controller;

  @override
  Future<CameraPermissionState> requestPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) return CameraPermissionState.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return CameraPermissionState.permanentlyDenied;
    }
    return CameraPermissionState.denied;
  }

  @override
  Future<void> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw StateError('Cámara no disponible.');
    final selected = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      selected,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    try {
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
    } on CameraException {
      // Some devices expose fixed modes; capture remains available.
    }
    _controller = controller;
  }

  @override
  Widget buildPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    return CameraPreview(controller);
  }

  @override
  Future<CapturedPhoto> capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('La cámara no está lista.');
    }
    final file = await controller.takePicture();
    return CapturedPhoto(path: file.path, capturedAt: DateTime.now().toUtc());
  }

  @override
  Future<void> pause() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  @override
  Future<void> resume() => initialize();

  @override
  Future<void> dispose() => pause();

  @override
  Future<bool> openSettings() => openAppSettings();
}
