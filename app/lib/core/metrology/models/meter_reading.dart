/// A confirmed meter reading, independent from OCR/camera acquisition.
///
/// [odometerUnits] are scaled by [litersPerOdometerUnit]. [needleLiters] is a
/// position within one fine-dial revolution, not an accumulated volume.
final class MeterReading {
  MeterReading({
    required this.odometerUnits,
    required this.needleLiters,
    this.litersPerOdometerUnit = 1000,
    this.needleLitersPerRevolution = 100,
  }) {
    if (!odometerUnits.isFinite || odometerUnits < 0) {
      throw ArgumentError.value(odometerUnits, 'odometerUnits');
    }
    if (!litersPerOdometerUnit.isFinite || litersPerOdometerUnit <= 0) {
      throw ArgumentError.value(litersPerOdometerUnit, 'litersPerOdometerUnit');
    }
    if (!needleLitersPerRevolution.isFinite || needleLitersPerRevolution <= 0) {
      throw ArgumentError.value(
        needleLitersPerRevolution,
        'needleLitersPerRevolution',
      );
    }
    if (!needleLiters.isFinite ||
        needleLiters < 0 ||
        needleLiters >= needleLitersPerRevolution) {
      throw ArgumentError.value(needleLiters, 'needleLiters');
    }
  }

  final double odometerUnits;
  final double needleLiters;
  final double litersPerOdometerUnit;
  final double needleLitersPerRevolution;
}
