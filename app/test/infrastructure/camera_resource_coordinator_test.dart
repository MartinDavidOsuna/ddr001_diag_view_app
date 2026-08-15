import 'package:ddr001_diag_view_app/infrastructure/pulse/camera_resource_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('same camera consumer can retain the resource', () {
    final coordinator = CameraResourceCoordinator();
    expect(coordinator.acquire(CameraConsumer.ledDetector).allowed, isTrue);
    expect(coordinator.acquire(CameraConsumer.ledDetector).allowed, isTrue);
  });

  test('evidence is refused while LED owns camera without reconciliation', () {
    final coordinator = CameraResourceCoordinator();
    coordinator.acquire(CameraConsumer.ledDetector);
    final decision = coordinator.acquire(CameraConsumer.evidence);
    expect(decision.allowed, isFalse);
    expect(decision.compromised, isTrue);
    expect(decision.message, contains('perderse pulsos'));
  });

  test('resource can transfer only after explicit release', () {
    final coordinator = CameraResourceCoordinator();
    coordinator.acquire(CameraConsumer.ledDetector);
    coordinator.release(CameraConsumer.ledDetector);
    expect(coordinator.acquire(CameraConsumer.evidence).allowed, isTrue);
  });
}
