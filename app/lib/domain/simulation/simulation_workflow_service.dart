import 'package:uuid/uuid.dart';

import '../../infrastructure/simulation/simulation_evidence_capture.dart';
import '../models.dart';
import '../repositories.dart';

final class SimulationWorkflowService {
  SimulationWorkflowService({
    required this.points,
    required this.evidence,
    required this.simulationEvidence,
    this._uuid = const Uuid(),
  });

  final PointRepository points;
  final EvidenceRepository evidence;
  final SimulationEvidenceCapturePort simulationEvidence;
  final Uuid _uuid;

  Future<Evidence> captureStart({
    required String caseId,
    required Sample sample,
    required double flowLps,
    required DateTime at,
  }) => _capture(
    caseId: caseId,
    sample: sample,
    evidenceType: EvidenceType.start,
    pointType: PointType.start,
    volumeRefLiters: 0,
    pulseCount: 0,
    flowLps: flowLps,
    at: at,
  );

  Future<Evidence> captureIntermediate({
    required String caseId,
    required Sample sample,
    required double volumeRefLiters,
    required int pulseCount,
    required double flowLps,
    required DateTime at,
  }) => _capture(
    caseId: caseId,
    sample: sample,
    evidenceType: EvidenceType.intermediate,
    pointType: PointType.intermediate,
    volumeRefLiters: volumeRefLiters,
    pulseCount: pulseCount,
    flowLps: flowLps,
    at: at,
  );

  Future<Evidence> captureFinal({
    required String caseId,
    required Sample sample,
    required double volumeRefLiters,
    required int pulseCount,
    required double flowLps,
    required DateTime at,
  }) => _capture(
    caseId: caseId,
    sample: sample,
    evidenceType: EvidenceType.finalEvidence,
    pointType: PointType.finalPoint,
    volumeRefLiters: volumeRefLiters,
    pulseCount: pulseCount,
    flowLps: flowLps,
    at: at,
  );

  Future<Evidence> _capture({
    required String caseId,
    required Sample sample,
    required EvidenceType evidenceType,
    required PointType pointType,
    required double volumeRefLiters,
    required int pulseCount,
    required double flowLps,
    required DateTime at,
  }) async {
    final existingEvidence = await evidence.listBySample(sample.id);
    Evidence? existing;
    for (final candidate in existingEvidence) {
      if (candidate.type == evidenceType &&
          candidate.volumeRefLiters != null &&
          (candidate.volumeRefLiters! - volumeRefLiters).abs() <= 1e-7) {
        existing = candidate;
        break;
      }
    }
    final item =
        existing ??
        await simulationEvidence.capture(
          caseId: caseId,
          sample: sample,
          type: evidenceType,
          volumeRefLiters: volumeRefLiters,
          pulseCount: pulseCount,
          capturedAt: at,
        );
    final existingPoints = await points.listBySample(sample.id);
    final hasPoint = existingPoints.any(
      (point) =>
          point.type == pointType &&
          point.referenceLiters != null &&
          (point.referenceLiters! - volumeRefLiters).abs() <= 1e-7,
    );
    if (!hasPoint) {
      await points.save(
        TestPoint(
          id: _uuid.v4(),
          sampleId: sample.id,
          type: pointType,
          pulseCount: pulseCount,
          referenceLiters: volumeRefLiters,
          meterUnderTestPulseCount: pulseCount,
          flowLps: flowLps,
          capturedAt: at,
        ),
      );
    }
    return item;
  }
}
