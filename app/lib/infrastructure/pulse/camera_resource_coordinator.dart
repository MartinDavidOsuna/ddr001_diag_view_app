enum CameraConsumer { evidence, ledDetector }

final class CameraCoordinationDecision {
  const CameraCoordinationDecision({
    required this.allowed,
    required this.compromised,
    this.message,
  });

  final bool allowed;
  final bool compromised;
  final String? message;
}

/// Owns the safety decision for the single Android camera resource.
///
/// The current camera adapter cannot take a full-resolution evidence photo
/// while its image stream observes an LED. Without a reconciliable ESP32
/// counter, stopping that stream could silently lose pulses, so the operation
/// is deliberately refused.
final class CameraResourceCoordinator {
  CameraConsumer? _owner;

  CameraConsumer? get owner => _owner;

  CameraCoordinationDecision acquire(CameraConsumer consumer) {
    final owner = _owner;
    if (owner == null || owner == consumer) {
      _owner = consumer;
      return const CameraCoordinationDecision(
        allowed: true,
        compromised: false,
      );
    }
    return const CameraCoordinationDecision(
      allowed: false,
      compromised: true,
      message:
          'No es seguro pausar la detección LED para capturar evidencia: podrían perderse pulsos sin reconciliación.',
    );
  }

  void release(CameraConsumer consumer) {
    if (_owner == consumer) _owner = null;
  }
}
