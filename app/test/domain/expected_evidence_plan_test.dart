import 'package:ddr001_diag_view_app/domain/expected_evidence_plan.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('step 25 and final 125 derives START 25 50 75 100 FINAL', () {
    final plan = ExpectedEvidencePlan.derive(
      evidenceStepLiters: 25,
      finalVolumeLiters: 125,
    );
    expect(
      plan.requirements
          .map((item) => (item.type, item.volumeRefLiters))
          .toList(),
      [
        (EvidenceType.start, 0),
        (EvidenceType.intermediate, 25),
        (EvidenceType.intermediate, 50),
        (EvidenceType.intermediate, 75),
        (EvidenceType.intermediate, 100),
        (EvidenceType.finalEvidence, 125),
      ],
    );
  });

  test('final below one step requires only START and FINAL', () {
    final plan = ExpectedEvidencePlan.derive(
      evidenceStepLiters: 25,
      finalVolumeLiters: 20,
    );
    expect(plan.requirements, hasLength(2));
    expect(plan.requirements.first.type, EvidenceType.start);
    expect(plan.requirements.last.type, EvidenceType.finalEvidence);
  });

  test('FINAL exact step multiple is not duplicated as INTERMEDIATE', () {
    final plan = ExpectedEvidencePlan.derive(
      evidenceStepLiters: 25,
      finalVolumeLiters: 125,
    );
    expect(
      plan.requirements.where((item) => item.volumeRefLiters == 125),
      hasLength(1),
    );
    expect(plan.requirements.last.type, EvidenceType.finalEvidence);
  });
}
