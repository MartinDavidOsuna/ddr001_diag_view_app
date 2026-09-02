import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../core/metrology/metrology.dart';
import '../../infrastructure/simulation/simulation_evidence_capture.dart';
import '../expected_evidence_plan.dart';
import '../models.dart';
import '../pulse/pulse_source.dart';
import '../repositories.dart';
import 'simulation_values.dart';

typedef SimulationProgressCallback = FutureOr<void> Function(Sample sample);

final class SimulationWorkflowService {
  SimulationWorkflowService({
    required this.samples,
    required this.points,
    required this.evidence,
    required this.pulseProgress,
    required this.sampleClosure,
    required this.simulationEvidence,
    this.pulseInterval = const Duration(milliseconds: 25),
    this._uuid = const Uuid(),
  });

  final SampleRepository samples;
  final PointRepository points;
  final EvidenceRepository evidence;
  final PulseProgressPort pulseProgress;
  final SampleClosureService sampleClosure;
  final SimulationEvidenceCapturePort simulationEvidence;
  final Duration pulseInterval;
  final Uuid _uuid;

  Future<Sample> run({
    required String caseId,
    required Sample runningSample,
    required bool shouldPass,
    SimulationProgressCallback? onProgress,
  }) async {
    if (!runningSample.isSimulation ||
        runningSample.status != SampleStatus.running ||
        runningSample.simulationScenario == null) {
      throw StateError('A persisted RUNNING simulation Sample is required.');
    }
    var sample = (await samples.getById(runningSample.id))!;
    final values = SimulationValues.forSample(
      sample: sample,
      shouldPass: shouldPass,
    );
    final targetPulses =
        (values.referenceLiters / sample.configuration.litersPerPulse).round();
    var existingEvidence = await evidence.listBySample(sample.id);
    if (!existingEvidence.any((item) => item.type == EvidenceType.start)) {
      final at = DateTime.now().toUtc();
      final start = await simulationEvidence.capture(
        caseId: caseId,
        sample: sample,
        type: EvidenceType.start,
        volumeRefLiters: 0,
        pulseCount: 0,
        capturedAt: at,
      );
      await points.save(
        TestPoint(
          id: _uuid.v4(),
          sampleId: sample.id,
          type: PointType.start,
          pulseCount: 0,
          referenceLiters: 0,
          meterUnderTestPulseCount: 0,
          flowLps: values.flowLps,
          capturedAt: start.capturedAt,
        ),
      );
      existingEvidence = [...existingEvidence, start];
    }

    final plan = ExpectedEvidencePlan.derive(
      evidenceStepLiters: sample.configuration.evidenceStepLiters,
      finalVolumeLiters: values.referenceLiters,
    );
    for (
      var sequence = sample.pulseCount + 1;
      sequence <= targetPulses;
      sequence++
    ) {
      if (pulseInterval > Duration.zero) {
        await Future<void>.delayed(pulseInterval);
      }
      final at = DateTime.now().toUtc();
      await pulseProgress.acceptPulse(
        sample.id,
        PulseEvent(
          id: 'simulation-${sample.id}-$sequence',
          source: PulseSourceType.simulation,
          occurredAt: at,
          receivedAt: at,
          sequence: sequence,
          diagnostics: 'deterministic simulation',
        ),
      );
      sample = (await samples.getById(sample.id))!;
      final volume = sample.pulseCount * sample.configuration.litersPerPulse;
      for (final requirement in plan.requirements.where(
        (item) => item.type == EvidenceType.intermediate,
      )) {
        final due =
            volume + ExpectedEvidencePlan.comparisonEpsilon >=
            requirement.volumeRefLiters;
        final captured = existingEvidence.any(
          (item) =>
              item.type == requirement.type &&
              item.volumeRefLiters != null &&
              plan.volumeMatches(
                item.volumeRefLiters!,
                requirement.volumeRefLiters,
              ),
        );
        if (due && !captured) {
          final item = await simulationEvidence.capture(
            caseId: caseId,
            sample: sample,
            type: requirement.type,
            volumeRefLiters: requirement.volumeRefLiters,
            pulseCount: sample.pulseCount,
            capturedAt: at,
          );
          await points.save(
            TestPoint(
              id: _uuid.v4(),
              sampleId: sample.id,
              type: PointType.intermediate,
              pulseCount: sample.pulseCount,
              referenceLiters: requirement.volumeRefLiters,
              meterUnderTestPulseCount: sample.pulseCount,
              flowLps: values.flowLps,
              capturedAt: at,
            ),
          );
          existingEvidence = [...existingEvidence, item];
        }
      }
      await onProgress?.call(sample);
    }

    final finalAt = DateTime.now().toUtc();
    Evidence? finalEvidence;
    for (final item in existingEvidence) {
      if (item.type == EvidenceType.finalEvidence &&
          item.volumeRefLiters != null &&
          plan.volumeMatches(item.volumeRefLiters!, values.referenceLiters)) {
        finalEvidence = item;
        break;
      }
    }
    if (finalEvidence == null) {
      finalEvidence = await simulationEvidence.capture(
        caseId: caseId,
        sample: sample,
        type: EvidenceType.finalEvidence,
        volumeRefLiters: values.referenceLiters,
        pulseCount: targetPulses,
        capturedAt: finalAt,
      );
      await points.save(
        TestPoint(
          id: _uuid.v4(),
          sampleId: sample.id,
          type: PointType.finalPoint,
          pulseCount: targetPulses,
          referenceLiters: values.referenceLiters,
          meterUnderTestPulseCount: targetPulses,
          flowLps: values.flowLps,
          capturedAt: finalAt,
        ),
      );
    }
    final initialOdometer = 10.0;
    final finalOdometer =
        initialOdometer +
        values.indicatedLiters / sample.configuration.litersPerOdometerUnit;
    sample = await samples.updateProgress(
      id: sample.id,
      pulseCount: targetPulses,
      referenceLiters: values.referenceLiters,
      manualIndicatedLiters: values.indicatedLiters,
      initialReading: ConfirmedReading(
        reading: MeterReading(
          odometerUnits: initialOdometer,
          needleLiters: 0,
          litersPerOdometerUnit: sample.configuration.litersPerOdometerUnit,
          needleLitersPerRevolution:
              sample.configuration.needleLitersPerRevolution,
        ),
        source: ReadingSource.manual,
        evidenceId: existingEvidence
            .firstWhere((item) => item.type == EvidenceType.start)
            .id,
      ),
      finalReading: ConfirmedReading(
        reading: MeterReading(
          odometerUnits: finalOdometer,
          needleLiters: 0,
          litersPerOdometerUnit: sample.configuration.litersPerOdometerUnit,
          needleLitersPerRevolution:
              sample.configuration.needleLitersPerRevolution,
        ),
        source: ReadingSource.manual,
        evidenceId: finalEvidence.id,
      ),
    );
    final closed = await sampleClosure.closeValid(
      sample.id,
      at: finalAt.add(const Duration(milliseconds: 1)),
    );
    await onProgress?.call(closed);
    return closed;
  }
}
