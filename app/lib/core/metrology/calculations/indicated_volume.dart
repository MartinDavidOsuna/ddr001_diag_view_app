import '../models/meter_reading.dart';

/// Reconstructs the physical advance of a cyclic fine dial.
///
/// Without a reference, [completedNeedleTurns] must be supplied because two
/// endpoint positions cannot distinguish one turn from several. With
/// [referenceLiters], the integer turn count nearest the reference is selected,
/// following ADR-002 and METROLOGY_RULES. Ties use Dart's half-away-from-zero
/// rounding and should be resolved by the acquisition layer if physically
/// ambiguous.
double calculateIndicatedVolume({
  required MeterReading initial,
  required MeterReading finalReading,
  double? referenceLiters,
  int? completedNeedleTurns,
}) {
  if (initial.litersPerOdometerUnit != finalReading.litersPerOdometerUnit ||
      initial.needleLitersPerRevolution !=
          finalReading.needleLitersPerRevolution) {
    throw ArgumentError('Initial and final reading scales must match.');
  }
  if (referenceLiters != null && completedNeedleTurns != null) {
    throw ArgumentError(
      'Provide either referenceLiters or completedNeedleTurns, not both.',
    );
  }
  if (referenceLiters == null && completedNeedleTurns == null) {
    throw ArgumentError(
      'A reference or an explicit completed turn count is required.',
    );
  }
  if (referenceLiters != null &&
      (!referenceLiters.isFinite || referenceLiters < 0)) {
    throw ArgumentError.value(referenceLiters, 'referenceLiters');
  }
  if (completedNeedleTurns != null && completedNeedleTurns < 0) {
    throw ArgumentError.value(completedNeedleTurns, 'completedNeedleTurns');
  }

  final revolution = initial.needleLitersPerRevolution;
  if (initial.needleLiters >= revolution ||
      finalReading.needleLiters >= revolution) {
    throw ArgumentError(
      'Cyclic reconstruction requires needle positions inside one revolution.',
    );
  }
  final coarseAdvance =
      (finalReading.odometerUnits - initial.odometerUnits) *
      initial.litersPerOdometerUnit;
  final fineAdvance = finalReading.needleLiters - initial.needleLiters;
  final baseAdvance = coarseAdvance + fineAdvance;
  final turns =
      completedNeedleTurns ??
      ((referenceLiters! - baseAdvance) / revolution).round();
  final result = baseAdvance + revolution * turns;
  if (!result.isFinite || result < 0) {
    throw StateError('The readings and turn count produce a negative advance.');
  }
  return result;
}

/// Calculates an endpoint advance when the captured needle value is an
/// unrestricted liter observation rather than a cyclic position.
///
/// This is the representation used by BLE and SIMULATION manual review. The
/// totalizer remains expressed in its configured unit and the needle remains
/// expressed in liters, so 10.345 -> 10.547 m3 produces 202 L.
double calculateDirectReadingAdvance({
  required MeterReading initial,
  required MeterReading finalReading,
}) {
  if (initial.litersPerOdometerUnit != finalReading.litersPerOdometerUnit) {
    throw ArgumentError('Reading scales must match.');
  }
  final initialLiters =
      initial.odometerUnits * initial.litersPerOdometerUnit +
      initial.needleLiters;
  final finalLiters =
      finalReading.odometerUnits * finalReading.litersPerOdometerUnit +
      finalReading.needleLiters;
  final advance = finalLiters - initialLiters;
  if (!advance.isFinite || advance < 0) {
    throw ArgumentError(
      'Final reading must not be lower than initial reading.',
    );
  }
  return advance;
}
