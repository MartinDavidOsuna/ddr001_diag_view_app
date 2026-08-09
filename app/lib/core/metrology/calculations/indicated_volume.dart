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
