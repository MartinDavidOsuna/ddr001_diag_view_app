import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'camera_models.dart';
import 'camera_port.dart';
import '../pulse/led_pulse_detector.dart';

final class FlutterCameraAdapter
    implements CameraPort, LedBrightnessPort, LiveCameraAnalysisPort {
  CameraController? _controller;
  final _brightness =
      StreamController<({double brightness, DateTime timestamp})>.broadcast();
  bool _streaming = false;
  int _framesReceived = 0;
  int _framesProcessed = 0;
  int _framesDropped = 0;
  DateTime? _streamStartedAt;
  bool _processingFrame = false;
  bool _analysisStreaming = false;
  Completer<String>? _analysisFrameCompleter;
  double _desiredZoomLevel = 1;
  Offset _desiredFocusPoint = const Offset(.5, .5);
  Timer? _focusMaintenanceTimer;
  bool _restoringOptics = false;

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
    final existing = _controller;
    if (existing != null && existing.value.isInitialized) {
      await _restoreOptics();
      _startFocusMaintenance();
      return;
    }
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
    final minimumZoom = await controller.getMinZoomLevel();
    final maximumZoom = await controller.getMaxZoomLevel();
    _desiredZoomLevel = _desiredZoomLevel.clamp(minimumZoom, maximumZoom);
    _controller = controller;
    await _restoreOptics();
    _startFocusMaintenance();
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
  double get previewAspectRatio =>
      1 / (_controller?.value.aspectRatio ?? (4 / 3));

  @override
  Future<double> getMinZoomLevel() async =>
      await _controller?.getMinZoomLevel() ?? 1;

  @override
  Future<double> getMaxZoomLevel() async =>
      await _controller?.getMaxZoomLevel() ?? 1;

  @override
  Future<void> setZoomLevel(double zoomLevel) async {
    _desiredZoomLevel = zoomLevel;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final minimum = await controller.getMinZoomLevel();
    final maximum = await controller.getMaxZoomLevel();
    await controller.setZoomLevel(zoomLevel.clamp(minimum, maximum));
  }

  @override
  Future<void> focusAt({required double x, required double y}) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final point = Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
    _desiredFocusPoint = point;
    try {
      await controller.setFocusPoint(point);
      await controller.setExposurePoint(point);
    } on CameraException {
      // Some Android camera implementations expose auto focus without
      // metering points. The preview remains usable in that case.
    }
  }

  @override
  Future<CapturedPhoto> capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('La cámara no está lista.');
    }
    await stopAnalysisFrames();
    await _restoreOptics();
    await Future<void>.delayed(const Duration(milliseconds: 250));
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
  Future<String> captureAnalysisFrame() async {
    var controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      await initialize();
      controller = _controller!;
    }
    final pending = _analysisFrameCompleter;
    if (pending != null) return pending.future;
    final completer = Completer<String>();
    _analysisFrameCompleter = completer;
    if (!_analysisStreaming) {
      if (controller.value.isStreamingImages) {
        throw StateError('La cámara está ocupada con otro flujo de frames.');
      }
      _analysisStreaming = true;
      await controller.startImageStream(_onAnalysisImage);
    }
    return completer.future;
  }

  void _onAnalysisImage(CameraImage cameraImage) {
    final completer = _analysisFrameCompleter;
    if (completer == null || completer.isCompleted) return;
    _analysisFrameCompleter = null;
    final planes = cameraImage.planes
        .map(
          (plane) => _CameraPlaneCopy(
            bytes: Uint8List.fromList(plane.bytes),
            bytesPerRow: plane.bytesPerRow,
            bytesPerPixel: plane.bytesPerPixel ?? 1,
          ),
        )
        .toList(growable: false);
    final sensorOrientation = _controller?.description.sensorOrientation ?? 90;
    () async {
      try {
        final encoded = await compute(
          _encodeCameraFrame,
          _CameraFrameCopy(
            width: cameraImage.width,
            height: cameraImage.height,
            planes: planes,
            rotationDegrees: sensorOrientation,
          ),
        );
        final directory = await getTemporaryDirectory();
        final path =
            '${directory.path}${Platform.pathSeparator}ddr001-live-${DateTime.now().microsecondsSinceEpoch}.jpg';
        await File(path).writeAsBytes(encoded, flush: true);
        if (!completer.isCompleted) completer.complete(path);
      } catch (error, stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      }
    }();
  }

  @override
  Future<void> stopAnalysisFrames() async {
    final controller = _controller;
    _analysisFrameCompleter?.completeError(
      StateError('Análisis de cámara detenido.'),
    );
    _analysisFrameCompleter = null;
    if (!_analysisStreaming || controller == null) return;
    _analysisStreaming = false;
    if (controller.value.isStreamingImages) await controller.stopImageStream();
  }

  @override
  Future<void> pause() async {
    _focusMaintenanceTimer?.cancel();
    _focusMaintenanceTimer = null;
    await stopAnalysisFrames();
    await stop();
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  @override
  Future<void> resume() => initialize();

  void _startFocusMaintenance() {
    _focusMaintenanceTimer?.cancel();
    _focusMaintenanceTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      unawaited(_restoreOptics());
    });
  }

  Future<void> _restoreOptics() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _restoringOptics) {
      return;
    }
    _restoringOptics = true;
    try {
      final minimum = await controller.getMinZoomLevel();
      final maximum = await controller.getMaxZoomLevel();
      await controller.setZoomLevel(_desiredZoomLevel.clamp(minimum, maximum));
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
      await controller.setFocusPoint(_desiredFocusPoint);
      await controller.setExposurePoint(_desiredFocusPoint);
    } on CameraException {
      // Fixed-focus devices still retain the full uncropped camera frame.
    } finally {
      _restoringOptics = false;
    }
  }

  @override
  Future<void> dispose() async {
    await pause();
    await _brightness.close();
  }

  @override
  Future<bool> openSettings() => openAppSettings();
}

final class _CameraPlaneCopy {
  const _CameraPlaneCopy({
    required this.bytes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  });

  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;
}

final class _CameraFrameCopy {
  const _CameraFrameCopy({
    required this.width,
    required this.height,
    required this.planes,
    required this.rotationDegrees,
  });

  final int width;
  final int height;
  final List<_CameraPlaneCopy> planes;
  final int rotationDegrees;
}

Uint8List _encodeCameraFrame(_CameraFrameCopy frame) => _encodeYuv420Jpeg(
  width: frame.width,
  height: frame.height,
  planes: frame.planes,
  rotationDegrees: frame.rotationDegrees,
);

Uint8List _encodeYuv420Jpeg({
  required int width,
  required int height,
  required List<_CameraPlaneCopy> planes,
  required int rotationDegrees,
}) {
  if (planes.length < 3) throw StateError('Frame YUV420 incompleto.');
  final output = img.Image(width: width, height: height);
  final yPlane = planes[0];
  final uPlane = planes[1];
  final vPlane = planes[2];
  for (var y = 0; y < height; y++) {
    final uvY = y >> 1;
    for (var x = 0; x < width; x++) {
      final uvX = x >> 1;
      final yValue = yPlane.bytes[y * yPlane.bytesPerRow + x];
      final uvOffset = uvY * uPlane.bytesPerRow + uvX * uPlane.bytesPerPixel;
      final u = uPlane.bytes[uvOffset] - 128;
      final v = vPlane.bytes[uvOffset] - 128;
      final red = (yValue + 1.402 * v).round().clamp(0, 255);
      final green = (yValue - .344136 * u - .714136 * v).round().clamp(0, 255);
      final blue = (yValue + 1.772 * u).round().clamp(0, 255);
      output.setPixelRgba(x, y, red, green, blue, 255);
    }
  }
  final normalizedRotation = rotationDegrees % 360;
  final oriented = normalizedRotation == 0
      ? output
      : img.copyRotate(output, angle: normalizedRotation);
  return Uint8List.fromList(img.encodeJpg(oriented, quality: 88));
}
