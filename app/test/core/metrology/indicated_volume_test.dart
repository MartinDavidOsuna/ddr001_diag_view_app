import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:flutter_test/flutter_test.dart';

MeterReading reading(double needle, {double odometer = 47}) =>
    MeterReading(odometerUnits: odometer, needleLiters: needle);

void main() {
  test('BLE and SIMULATION allow an unbounded captured needle reading', () {
    expect(MeasurementMethod.ble.allowsUnboundedNeedleReading, isTrue);
    expect(MeasurementMethod.simulation.allowsUnboundedNeedleReading, isTrue);
    expect(MeasurementMethod.visual.allowsUnboundedNeedleReading, isFalse);
    expect(MeasurementMethod.manual.allowsUnboundedNeedleReading, isFalse);
    expect(MeasurementMethod.led.allowsUnboundedNeedleReading, isFalse);
    expect(reading(1000).needleLiters, 1000);
  });

  test('direct reading advance converts cubic meters to liters exactly', () {
    final advance = calculateDirectReadingAdvance(
      initial: MeterReading(
        odometerUnits: 10.345,
        needleLiters: 0,
        litersPerOdometerUnit: 1000,
      ),
      finalReading: MeterReading(
        odometerUnits: 10.547,
        needleLiters: 0,
        litersPerOdometerUnit: 1000,
      ),
    );

    expect(advance, closeTo(202, 1e-9));
  });

  group('needle turn reconstruction', () {
    test('90 to 10 crosses zero', () {
      expect(
        calculateIndicatedVolume(
          initial: reading(90),
          finalReading: reading(10),
          completedNeedleTurns: 1,
        ),
        20,
      );
    });
    test('80 to 20 crosses zero', () {
      expect(
        calculateIndicatedVolume(
          initial: reading(80),
          finalReading: reading(20),
          completedNeedleTurns: 1,
        ),
        40,
      );
    });
    test('99 to 01 crosses zero', () {
      expect(
        calculateIndicatedVolume(
          initial: reading(99),
          finalReading: reading(1),
          completedNeedleTurns: 1,
        ),
        2,
      );
    });
    test('one complete turn at same position is retained', () {
      expect(
        calculateIndicatedVolume(
          initial: reading(25),
          finalReading: reading(25),
          completedNeedleTurns: 1,
        ),
        100,
      );
    });
    test('two complete turns at same position are retained', () {
      expect(
        calculateIndicatedVolume(
          initial: reading(25),
          finalReading: reading(25),
          completedNeedleTurns: 2,
        ),
        200,
      );
    });
    test('three complete turns at same position are retained', () {
      expect(
        calculateIndicatedVolume(
          initial: reading(25),
          finalReading: reading(25),
          completedNeedleTurns: 3,
        ),
        300,
      );
    });
    test('odometer advance combines with fine dial', () {
      expect(
        calculateIndicatedVolume(
          initial: reading(90, odometer: 47),
          finalReading: reading(10, odometer: 48),
          completedNeedleTurns: 1,
        ),
        1020,
      );
    });
    test('reference chooses one turn', () {
      expect(
        calculateIndicatedVolume(
          initial: reading(90),
          finalReading: reading(10),
          referenceLiters: 20,
        ),
        20,
      );
    });
    test('reference chooses two turns', () {
      expect(
        calculateIndicatedVolume(
          initial: reading(80),
          finalReading: reading(20),
          referenceLiters: 140,
        ),
        140,
      );
    });
    test('reference chooses three turns', () {
      expect(
        calculateIndicatedVolume(
          initial: reading(99),
          finalReading: reading(1),
          referenceLiters: 202,
        ),
        202,
      );
    });
    test('missing disambiguation is rejected', () {
      expect(
        () => calculateIndicatedVolume(
          initial: reading(10),
          finalReading: reading(20),
        ),
        throwsArgumentError,
      );
    });
    test('cyclic reconstruction rejects an unbounded observation', () {
      expect(
        () => calculateIndicatedVolume(
          initial: reading(0),
          finalReading: reading(250),
          referenceLiters: 250,
        ),
        throwsArgumentError,
      );
    });
  });
}
