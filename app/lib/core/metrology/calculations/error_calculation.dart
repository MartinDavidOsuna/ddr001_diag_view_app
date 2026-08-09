double calculateEndpointErrorPct({
  required double referenceLiters,
  required double indicatedLiters,
}) {
  if (!referenceLiters.isFinite || referenceLiters <= 0) {
    throw ArgumentError.value(referenceLiters, 'referenceLiters');
  }
  if (!indicatedLiters.isFinite || indicatedLiters < 0) {
    throw ArgumentError.value(indicatedLiters, 'indicatedLiters');
  }
  return ((indicatedLiters - referenceLiters) / referenceLiters) * 100;
}

/// Optional point-level diagnostic; never used as the official sample error.
double calculateDiagnosticPointErrorPct({
  required double referenceLiters,
  required double indicatedLiters,
}) => calculateEndpointErrorPct(
  referenceLiters: referenceLiters,
  indicatedLiters: indicatedLiters,
);
