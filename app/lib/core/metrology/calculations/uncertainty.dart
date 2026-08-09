import 'dart:math' as math;

abstract interface class UncertaintyPolicy {
  double calculatePct({required double referenceLiters});
}

final class ReadingUncertaintyPolicy implements UncertaintyPolicy {
  const ReadingUncertaintyPolicy({this.readingUncertaintyLiters = 1});

  final double readingUncertaintyLiters;

  @override
  double calculatePct({required double referenceLiters}) {
    if (!readingUncertaintyLiters.isFinite || readingUncertaintyLiters < 0) {
      throw ArgumentError.value(
        readingUncertaintyLiters,
        'readingUncertaintyLiters',
      );
    }
    if (!referenceLiters.isFinite || referenceLiters <= 0) {
      throw ArgumentError.value(referenceLiters, 'referenceLiters');
    }
    return (readingUncertaintyLiters * math.sqrt(2) / referenceLiters) * 100;
  }
}
