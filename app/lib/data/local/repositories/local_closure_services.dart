import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/metrology/metrology.dart' as metrology;
import '../../../domain/expected_evidence_plan.dart';
import '../../../domain/integrity_checksum.dart';
import '../../../domain/models.dart' as domain;
import '../../../domain/repositories.dart';
import '../database/app_database.dart' as db;
import '../filesystem/evidence_file_store.dart';
import 'local_repositories.dart';

int _ms(DateTime value) => value.toUtc().millisecondsSinceEpoch;

final class _FrozenMpePolicy implements metrology.MpePolicy {
  const _FrozenMpePolicy(this.value);
  final double value;

  @override
  double mpePctFor(metrology.FlowPoint flowPoint) => value;
}

final class LocalSampleClosureService implements SampleClosureService {
  LocalSampleClosureService(
    this.database,
    this.fileStore, [
    this._uuid = const Uuid(),
  ]);

  final db.AppDatabase database;
  final EvidenceFileStore fileStore;
  final Uuid _uuid;

  @override
  Future<domain.Sample> closeValid(
    String sampleId, {
    required DateTime at,
  }) => database.transaction(() async {
    final sampleRow = await (database.select(
      database.samples,
    )..where((t) => t.id.equals(sampleId))).getSingleOrNull();
    if (sampleRow == null) throw StateError('Sample not found.');
    final sample = await mapSampleWithSettings(database, sampleRow);
    if (sample.status != domain.SampleStatus.running) {
      throw StateError('Only a RUNNING sample can close.');
    }
    if (sample.acquisitionIntegrity.isCompromised) {
      throw StateError(
        'Conteo de pulsos no verificable. La prueba debe repetirse.',
      );
    }
    final hasEndpointReadings =
        sample.initialReading != null && sample.finalReading != null;
    final hasManualFinalReading =
        sample.manualIndicatedLiters != null && sample.finalReading != null;
    if (!hasEndpointReadings && !hasManualFinalReading) {
      throw StateError(
        'A confirmed FINAL reading and manual meter total are required.',
      );
    }

    final config = sample.configuration;
    final referenceLiters =
        config.measurementMethod == metrology.MeasurementMethod.visual
        ? sample.referenceLitersProgress
        : metrology.calculateReferenceVolume(
            pulseCount: sample.pulseCount,
            litersPerPulse: config.litersPerPulse,
          );
    if (referenceLiters == null || referenceLiters <= 0) {
      throw StateError('A positive reference volume is required.');
    }
    final evidenceRows = await (database.select(
      database.evidenceItems,
    )..where((t) => t.sampleId.equals(sampleId))).get();
    final evidence = evidenceRows.map(mapEvidence).toList(growable: false);
    final evidencePlan = ExpectedEvidencePlan.derive(
      evidenceStepLiters: config.evidenceStepLiters,
      finalVolumeLiters: referenceLiters,
    );
    if (!await _evidenceIsComplete(evidence, evidencePlan)) {
      await _markInvalid(sampleId, at);
      return mapSampleWithSettings(
        database,
        await (database.select(
          database.samples,
        )..where((t) => t.id.equals(sampleId))).getSingle(),
      );
    }
    final indicatedLiters =
        sample.manualIndicatedLiters ??
        metrology.calculateIndicatedVolume(
          initial: sample.initialReading!.reading,
          finalReading: sample.finalReading!.reading,
          referenceLiters: referenceLiters,
        );
    final engine = metrology.MetrologyEngine(
      mpePolicy: _FrozenMpePolicy(config.mpePct),
      uncertaintyPolicy: metrology.ReadingUncertaintyPolicy(
        readingUncertaintyLiters: config.readingUncertaintyLiters,
      ),
    );
    final result = engine.evaluate(
      flowPoint: config.flowPoint,
      referenceLiters: referenceLiters,
      indicatedLiters: indicatedLiters,
    );
    final requiredEvidence = evidence.where((item) => item.required).toList();
    final checksum = calculateSampleChecksum(
      sample: sample,
      referenceLiters: result.referenceLiters,
      indicatedLiters: result.indicatedLiters,
      errorPct: result.errorPct,
      uncertaintyPct: result.uncertaintyPct,
      mpePct: result.mpePct,
      acceptanceMetricPct: result.decisionMetrics.acceptanceMetricPct,
      rejectionMetricPct: result.decisionMetrics.rejectionMetricPct,
      verdict: result.verdict.name,
      endedAt: at,
      requiredEvidence: requiredEvidence,
    );
    final initialReadingLiters = sample.initialReading == null
        ? null
        : sample.initialReading!.reading.odometerUnits *
                  sample.initialReading!.reading.litersPerOdometerUnit +
              sample.initialReading!.reading.needleLiters;
    final finalReadingLiters =
        sample.finalReading!.reading.odometerUnits *
            sample.finalReading!.reading.litersPerOdometerUnit +
        sample.finalReading!.reading.needleLiters;
    if (initialReadingLiters != null) {
      await (database.update(database.testPoints)..where(
            (point) =>
                point.sampleId.equals(sampleId) &
                point.type.equals(domain.PointType.start.name),
          ))
          .write(
            db.TestPointsCompanion(
              readingLiters: Value(initialReadingLiters),
              indicatedLiters: const Value(0),
              needleLiters: Value(sample.initialReading!.reading.needleLiters),
            ),
          );
    }
    await (database.update(database.testPoints)..where(
          (point) =>
              point.sampleId.equals(sampleId) &
              point.type.equals(domain.PointType.finalPoint.name),
        ))
        .write(
          db.TestPointsCompanion(
            readingLiters: Value(finalReadingLiters),
            indicatedLiters: Value(result.indicatedLiters),
            diagnosticErrorPct: Value(result.errorPct),
            needleLiters: Value(sample.finalReading!.reading.needleLiters),
          ),
        );
    await (database.update(
      database.samples,
    )..where((t) => t.id.equals(sampleId))).write(
      db.SamplesCompanion(
        status: Value(domain.SampleStatus.closedValid.name),
        endedAtMs: Value(_ms(at)),
        updatedAtMs: Value(_ms(at)),
        referenceLiters: Value(result.referenceLiters),
        indicatedLiters: Value(result.indicatedLiters),
        errorPct: Value(result.errorPct),
        uncertaintyPct: Value(result.uncertaintyPct),
        resultMpePct: Value(result.mpePct),
        acceptanceMetricPct: Value(result.decisionMetrics.acceptanceMetricPct),
        rejectionMetricPct: Value(result.decisionMetrics.rejectionMetricPct),
        verdict: Value(result.verdict.name),
        checksum: Value(checksum),
      ),
    );
    await _enqueue(
      entityType: 'sample',
      entityId: sampleId,
      checksum: checksum,
      at: at,
    );
    for (final item in requiredEvidence) {
      await _enqueue(
        entityType: 'evidence',
        entityId: item.id,
        checksum: item.sha256!,
        at: at,
      );
    }
    return mapSampleWithSettings(
      database,
      await (database.select(
        database.samples,
      )..where((t) => t.id.equals(sampleId))).getSingle(),
    );
  });

  Future<bool> _evidenceIsComplete(
    List<domain.Evidence> evidence,
    ExpectedEvidencePlan plan,
  ) async {
    Future<bool> valid(domain.Evidence item) async =>
        item.required &&
        item.sha256 != null &&
        item.sha256!.length == 64 &&
        await fileStore.verify(item.localPath, item.sha256!);

    for (final requirement in plan.requirements) {
      final matches = evidence.where(
        (e) =>
            e.type == requirement.type &&
            e.volumeRefLiters != null &&
            plan.volumeMatches(e.volumeRefLiters!, requirement.volumeRefLiters),
      );
      if (!await _anyValid(matches, valid)) return false;
    }
    return true;
  }

  Future<bool> _anyValid(
    Iterable<domain.Evidence> items,
    Future<bool> Function(domain.Evidence) valid,
  ) async {
    for (final item in items) {
      if (await valid(item)) return true;
    }
    return false;
  }

  Future<void> _markInvalid(String sampleId, DateTime at) =>
      (database.update(
        database.samples,
      )..where((t) => t.id.equals(sampleId))).write(
        db.SamplesCompanion(
          status: Value(domain.SampleStatus.invalidEvidence.name),
          endedAtMs: Value(_ms(at)),
          updatedAtMs: Value(_ms(at)),
        ),
      );

  Future<void> _enqueue({
    required String entityType,
    required String entityId,
    required String checksum,
    required DateTime at,
  }) async {
    final existing =
        await (database.select(database.syncItems)..where(
              (t) =>
                  t.entityType.equals(entityType) &
                  t.entityId.equals(entityId) &
                  t.checksum.equals(checksum),
            ))
            .getSingleOrNull();
    if (existing != null) return;
    await database
        .into(database.syncItems)
        .insert(
          db.SyncItemsCompanion.insert(
            id: _uuid.v4(),
            entityType: entityType,
            entityId: entityId,
            checksum: checksum,
            state: domain.SyncState.pending.name,
            createdAtMs: _ms(at),
            updatedAtMs: _ms(at),
          ),
        );
  }
}

final class LocalVerificationCaseClosureService
    implements VerificationCaseClosureService {
  LocalVerificationCaseClosureService(
    this.database, [
    this._uuid = const Uuid(),
  ]);

  final db.AppDatabase database;
  final Uuid _uuid;

  @override
  Future<domain.VerificationCase> closeCase({
    required String caseId,
    required Set<metrology.FlowPoint> requiredFlowPoints,
    required DateTime at,
  }) => database.transaction(() async {
    if (requiredFlowPoints.isEmpty) {
      throw ArgumentError('At least one required flow point is needed.');
    }
    final caseRow = await (database.select(
      database.verificationCases,
    )..where((t) => t.id.equals(caseId))).getSingleOrNull();
    if (caseRow == null) throw StateError('Verification case not found.');
    final verificationCase = mapCase(caseRow);
    if (verificationCase.status != domain.VerificationCaseStatus.open) {
      throw StateError('Verification case is already CLOSED.');
    }
    final flowRows = await (database.select(
      database.flowPoints,
    )..where((t) => t.caseId.equals(caseId))).get();
    final results = <metrology.FlowPointResult>[];
    final checksumFlows =
        <
          ({
            String id,
            String code,
            String status,
            List<String> sampleChecksums,
          })
        >[];
    for (final flowRow in flowRows) {
      final sampleRows =
          await (database.select(database.samples)..where(
                (t) =>
                    t.flowPointId.equals(flowRow.id) &
                    t.status.equals(domain.SampleStatus.closedValid.name),
              ))
              .get();
      final samples = await Future.wait(
        sampleRows.map((row) => mapSampleWithSettings(database, row)),
      );
      final result = metrology.FlowPointResult.summarize(
        flowPoint: metrology.FlowPoint.values.byName(flowRow.code),
        samples: samples.map((s) => s.result!).toList(),
        mpePct: flowRow.mpePct,
      );
      results.add(result);
      final statistics = result.statistics;
      await (database.update(
        database.flowPoints,
      )..where((t) => t.id.equals(flowRow.id))).write(
        db.FlowPointsCompanion(
          status: Value(_flowStatus(result.status).name),
          statisticsN: Value(statistics?.n),
          meanErrorPct: Value(statistics?.meanErrorPct),
          minimumErrorPct: Value(statistics?.minimumErrorPct),
          maximumErrorPct: Value(statistics?.maximumErrorPct),
          dispersionPct: Value(statistics?.dispersionPct),
          sampleStdDevPct: Value(statistics?.sampleStandardDeviationPct),
          repeatabilityStatus: Value(statistics?.repeatabilityStatus.name),
        ),
      );
      checksumFlows.add((
        id: flowRow.id,
        code: flowRow.code,
        status: result.status.name,
        sampleChecksums: samples.map((s) => s.checksum!).toList(),
      ));
    }
    final caseVerdict = metrology.calculateCaseVerdict(
      requiredFlowPoints: requiredFlowPoints,
      flowResults: results,
    );
    final overall = switch (caseVerdict) {
      metrology.CaseVerdict.approved => domain.OverallVerdict.approved,
      metrology.CaseVerdict.rejected => domain.OverallVerdict.rejected,
      metrology.CaseVerdict.inconclusive => domain.OverallVerdict.inconclusive,
    };
    final checksum = calculateCaseChecksum(
      verificationCase: verificationCase,
      verdict: overall,
      closedAt: at,
      requiredFlowCodes: requiredFlowPoints.map((p) => p.name).toSet(),
      flows: checksumFlows,
    );
    await (database.update(
      database.verificationCases,
    )..where((t) => t.id.equals(caseId))).write(
      db.VerificationCasesCompanion(
        status: Value(domain.VerificationCaseStatus.closed.name),
        overallVerdict: Value(overall.name),
        closedAtMs: Value(_ms(at)),
        checksum: Value(checksum),
      ),
    );
    final existing =
        await (database.select(database.syncItems)..where(
              (t) =>
                  t.entityType.equals('verificationCase') &
                  t.entityId.equals(caseId) &
                  t.checksum.equals(checksum),
            ))
            .getSingleOrNull();
    if (existing == null) {
      await database
          .into(database.syncItems)
          .insert(
            db.SyncItemsCompanion.insert(
              id: _uuid.v4(),
              entityType: 'verificationCase',
              entityId: caseId,
              checksum: checksum,
              state: domain.SyncState.pending.name,
              createdAtMs: _ms(at),
              updatedAtMs: _ms(at),
            ),
          );
    }
    return mapCase(
      await (database.select(
        database.verificationCases,
      )..where((t) => t.id.equals(caseId))).getSingle(),
    );
  });

  domain.FlowRecordStatus _flowStatus(metrology.FlowPointStatus status) =>
      switch (status) {
        metrology.FlowPointStatus.pending => domain.FlowRecordStatus.open,
        metrology.FlowPointStatus.pass => domain.FlowRecordStatus.pass,
        metrology.FlowPointStatus.fail => domain.FlowRecordStatus.fail,
        metrology.FlowPointStatus.inconclusive =>
          domain.FlowRecordStatus.inconclusive,
      };
}
