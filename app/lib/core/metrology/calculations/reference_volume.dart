double calculateReferenceVolume({
  required int pulseCount,
  required double litersPerPulse,
}) {
  if (pulseCount < 0) {
    throw ArgumentError.value(pulseCount, 'pulseCount');
  }
  if (!litersPerPulse.isFinite || litersPerPulse <= 0) {
    throw ArgumentError.value(litersPerPulse, 'litersPerPulse');
  }
  return pulseCount * litersPerPulse;
}
