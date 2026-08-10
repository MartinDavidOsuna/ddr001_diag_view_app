import 'models.dart';

final class ExpectedEvidenceRequirement {
  const ExpectedEvidenceRequirement({
    required this.type,
    required this.volumeRefLiters,
  });

  final EvidenceType type;
  final double volumeRefLiters;
}

/// Pure evidence schedule over sample-relative reference volume.
///
/// START is at [originLiters]. INTERMEDIATE requirements are step multiples
/// strictly before [finalVolumeLiters]. FINAL is always at the final volume, so
/// an exact multiple is represented once as FINAL, without a duplicate photo.
final class ExpectedEvidencePlan {
  ExpectedEvidencePlan._(List<ExpectedEvidenceRequirement> requirements)
    : requirements = List.unmodifiable(requirements);

  factory ExpectedEvidencePlan.derive({
    double originLiters = 0,
    required double evidenceStepLiters,
    required double finalVolumeLiters,
  }) {
    if (!originLiters.isFinite || originLiters < 0) {
      throw ArgumentError.value(originLiters, 'originLiters');
    }
    if (!evidenceStepLiters.isFinite || evidenceStepLiters <= 0) {
      throw ArgumentError.value(evidenceStepLiters, 'evidenceStepLiters');
    }
    if (!finalVolumeLiters.isFinite || finalVolumeLiters <= originLiters) {
      throw ArgumentError.value(finalVolumeLiters, 'finalVolumeLiters');
    }

    final requirements = <ExpectedEvidenceRequirement>[
      ExpectedEvidenceRequirement(
        type: EvidenceType.start,
        volumeRefLiters: originLiters,
      ),
    ];
    for (
      var volume = originLiters + evidenceStepLiters;
      volume < finalVolumeLiters - comparisonEpsilon;
      volume += evidenceStepLiters
    ) {
      requirements.add(
        ExpectedEvidenceRequirement(
          type: EvidenceType.intermediate,
          volumeRefLiters: volume,
        ),
      );
    }
    requirements.add(
      ExpectedEvidenceRequirement(
        type: EvidenceType.finalEvidence,
        volumeRefLiters: finalVolumeLiters,
      ),
    );
    return ExpectedEvidencePlan._(requirements);
  }

  static const double comparisonEpsilon = 1e-9;

  final List<ExpectedEvidenceRequirement> requirements;

  bool volumeMatches(double actual, double expected) =>
      (actual - expected).abs() <= comparisonEpsilon;
}
