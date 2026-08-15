import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'camera_models.dart';
import 'camera_port.dart';
import '../pulse/led_pulse_detector.dart';

final class FlutterCameraAdapter implements CameraPort, LedBrightnessPort {
  CameraController? _controller;
  final _brightness =
      StreamController<({double brightness, DateTime timestamp})>.broadcast();
  bool _streaming = false;
  int _framesReceived = 0;
  int _framesProcessed = 0;
  int _framesDropped = 0;
  DateTime? _streamStartedAt;
  bool _processingFrame = false;

  int get framesReceived => _framesReceived;
  int get framesProcessed => _framesProcessed;
  int get framesDropped => _framesDropped;
  double get effectiveFps {
    final started = _streamStartedAt;
    if (started == null) return 0;
    final seconds =
        DateTime.now().toUtc().difference(started).inMilliseconds / 1000;
    return seconds <= 0 ? 0 : _framesProcessed / seconds;
  }

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
      imageFormatGroup: ImageFormatGroup.yuv420,
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
  Stream<({double brightness, DateTime timestamp})> get samples =>
      _brightness.stream;

  @override
  Future<void> start(LedRegion region) async {
    var controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      await initialize();
      controller = _controller!;
    }
    if (_streaming) return;
    _streaming = true;
    _framesReceived = 0;
    _framesProcessed = 0;
    _framesDropped = 0;
    _streamStartedAt = DateTime.now().toUtc();
    await controller.startImageStream((image) {
      if (!_streaming || image.planes.isEmpty) return;
      _framesReceived++;
      if (_processingFrame) {
        _framesDropped++;
        return;
      }
      _processingFrame = true;
      final plane = image.planes.first;
      final value = calculateLumaRoiBrightness(
        bytes: plane.bytes,
        imageWidth: image.width,
        imageHeight: image.height,
        bytesPerRow: plane.bytesPerRow,
        bytesPerPixel: plane.bytesPerPixel ?? 1,
        region: region,
      );
      _framesProcessed++;
      if (!_brightness.isClosed) {
        _brightness.add((brightness: value, timestamp: DateTime.now().toUtc()));
      }
      _processingFrame = false;
    });
  }

  @override
  Future<void> stop() async {
    final controller = _controller;
    if (!_streaming || controller == null) return;
    _streaming = false;
    if (controller.value.isStreamingImages) await controller.stopImageStream();
    _processingFrame = false;
  }

  @override
  Future<void> pause() async {
    await stop();
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  @override
  Future<void> resume() => initialize();

  @override
  Future<void> dispose() async {
    await pause();
    await _brightness.close();
  }

  @override
  Future<bool> openSettings() => openAppSettings();
}
