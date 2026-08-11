enum CameraPermissionState { granted, denied, permanentlyDenied, unavailable }

enum CameraOperationState {
  idle,
  capturing,
  processing,
  proposalReady,
  manualCorrection,
  confirmed,
  error,
}

final class CapturedPhoto {
  const CapturedPhoto({required this.path, required this.capturedAt});

  final String path;
  final DateTime capturedAt;
}
