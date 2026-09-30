import 'dart:async';

import 'package:camera/camera.dart';
import 'package:ddr001_diag_view_app/infrastructure/camera/flutter_camera_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'warm capture dispatches immediately without refocus, zoom or settling delay',
    () async {
      final native = _Camera();
      final adapter = FlutterCameraAdapter.withController(native);
      final capture = adapter.capture();
      // The native shutter must be requested before the first async suspension.
      expect(native.shutters, 1);
      expect(native.opticsCalls, 0);
      native.photo.complete(XFile('/tmp/camera-test.jpg'));
      expect((await capture).path, '/tmp/camera-test.jpg');
      await adapter.dispose();
    },
  );

  test('resuming a warm camera does not run another focus cycle', () async {
    final native = _Camera();
    final adapter = FlutterCameraAdapter.withController(native);
    await adapter.resume();
    await adapter.resume();
    expect(native.opticsCalls, 0);
    expect(native.shutters, 0);
    await adapter.dispose();
  });

  test(
    'pause waits for the in-flight photograph and rejects a second capture',
    () async {
      final native = _Camera();
      final adapter = FlutterCameraAdapter.withController(native);
      final capture = adapter.capture();
      await expectLater(adapter.capture(), throwsStateError);
      final pause = adapter.pause();
      await Future<void>.delayed(Duration.zero);
      expect(native.disposals, 0);
      native.photo.complete(XFile('/tmp/camera-test.jpg'));
      await capture;
      await pause;
      expect(native.shutters, 1);
      expect(native.disposals, 1);
      await expectLater(adapter.capture(), throwsStateError);
      await adapter.dispose();
    },
  );
}

final class _Camera extends CameraController {
  _Camera()
    : super(
        const CameraDescription(
          name: 'test',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
        ResolutionPreset.high,
        enableAudio: false,
      ) {
    value = value.copyWith(isInitialized: true);
  }
  final photo = Completer<XFile>();
  int shutters = 0;
  int opticsCalls = 0;
  int disposals = 0;
  @override
  Future<XFile> takePicture() {
    shutters++;
    return photo.future;
  }

  @override
  Future<double> getMinZoomLevel() async {
    opticsCalls++;
    return 1;
  }

  @override
  Future<double> getMaxZoomLevel() async {
    opticsCalls++;
    return 8;
  }

  @override
  Future<void> setZoomLevel(double zoom) async {
    opticsCalls++;
  }

  @override
  Future<void> setFocusMode(FocusMode mode) async {
    opticsCalls++;
  }

  @override
  Future<void> dispose() async {
    disposals++;
    await super.dispose();
  }
}
