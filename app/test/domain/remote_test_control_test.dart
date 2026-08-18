import 'package:ddr001_diag_view_app/domain/remote_test_control.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remote cannot begin outside the configured control flow range', () {
    expect(
      remoteTestAction(
        measurementStarted: false,
        controlFlowInRange: false,
        referenceLiters: 0,
      ),
      RemoteTestAction.none,
    );
  });

  test('remote begins in range and finishes only with reference volume', () {
    expect(
      remoteTestAction(
        measurementStarted: false,
        controlFlowInRange: true,
        referenceLiters: 0,
      ),
      RemoteTestAction.begin,
    );
    expect(
      remoteTestAction(
        measurementStarted: true,
        controlFlowInRange: true,
        referenceLiters: 0,
      ),
      RemoteTestAction.none,
    );
    expect(
      remoteTestAction(
        measurementStarted: true,
        controlFlowInRange: false,
        referenceLiters: 10,
      ),
      RemoteTestAction.finish,
    );
  });
}
