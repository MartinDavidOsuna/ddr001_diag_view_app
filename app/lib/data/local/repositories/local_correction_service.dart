import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/metrology/metrology.dart';
import '../../../domain/models.dart' as domain;
import '../../../domain/expected_evidence_plan.dart';
import '../../../domain/repositories.dart';
import '../database/app_database.dart' as db;
import '../filesystem/evidence_file_store.dart';
import 'local_closure_services.dart';
import 'local_repositories.dart';

/// Explicit corrections are the only exception to closed-record immutability.
/// Original rows and derived results are retained in an atomic audit record.
final class LocalCorrectionService implements CorrectionSyncState {
  LocalCorrectionService(this.database, this.fileStore);
  final db.AppDatabase database;
  final EvidenceFileStore fileStore;

  @override
  Future<bool> hasPending(String caseId) async =>
      (await database
              .customSelect(
                'SELECT 1 FROM case_corrections WHERE case_id = ? AND acknowledged = 0 LIMIT 1',
                variables: [Variable(caseId)],
              )
              .get())
          .isNotEmpty;

  @override
  Future<bool> requiresRemoteRevision(String caseId) async =>
      (await database
              .customSelect(
                'SELECT 1 FROM case_corrections WHERE case_id = ? AND requires_remote_revision = 1 AND acknowledged = 0 LIMIT 1',
                variables: [Variable(caseId)],
              )
              .get())
          .isNotEmpty;

  @override
  Future<void> acknowledge(
    String caseId,
    Iterable<String> correctionIds,
  ) => database.transaction(() async {
    for (final id in correctionIds) {
      await database.customStatement(
        'UPDATE case_corrections SET acknowledged = 1 WHERE case_id = ? AND id = ?',
        [caseId, id],
      );
    }
  });

  @override
  Future<List<Map<String, Object?>>> pendingPayloads(String caseId) async {
    final result = <Map<String, Object?>>[];
    for (final entry in await history(caseId)) {
      if (entry['acknowledged'] == 1) continue;
      final before = jsonDecode(entry['before_json'] as String) as Map;
      final after = jsonDecode(entry['after_json'] as String) as Map;
      final beforeCase = (before['case'] as List).single as Map;
      final afterCase = (after['case'] as List).single as Map;
      final sampleId = entry['sample_id'];
      final sample = sampleId == null
          ? null
          : (after['samples'] as List).cast<Map>().singleWhere(
              (s) => s['id'] == sampleId,
            );
      final settings = (after['operationalSettings'] as List? ?? [])
          .cast<Map>()
          .where((s) => s['sample_id'] == sampleId)
          .firstOrNull;
      result.add({
        'correctionId': entry['id'],
        'caseId': caseId,
        'sampleId': sampleId,
        'baseCaseChecksum': beforeCase['checksum'],
        'resultCaseChecksum': afterCase['checksum'],
        'reportVersion': afterCase['report_version'],
        'correctedAt': DateTime.fromMillisecondsSinceEpoch(
          entry['corrected_at_ms'] as int,
          isUtc: true,
        ).toIso8601String(),
        'reason': entry['reason'],
        'manualValues': {
          'meterId': afterCase['meter_id'],
          'testBenchId': afterCase['test_bench_id'],
          if (sample != null) ...{
            'initialOdometerUnits': sample['initial_odometer_units'],
            'initialNeedleLiters': sample['initial_needle_liters'],
            'finalOdometerUnits': sample['final_odometer_units'],
            'finalNeedleLiters': sample['final_needle_liters'],
            'litersPerPulse': sample['liters_per_pulse'],
            'hydrantLitersPerPulse': settings?['hydrant_liters_per_pulse'] ?? 1,
            'readingUncertaintyLiters': sample['reading_uncertainty_liters'],
            'litersPerOdometerUnit': sample['liters_per_odometer_unit'],
            'needleLitersPerRevolution': sample['needle_liters_per_revolution'],
            if (sample['measurement_method'] == 'visual')
              'visualReferenceLiters': sample['reference_liters'],
            ...((after['manualInput'] as Map?)?.cast<String, Object?>() ?? {}),
          },
        },
      });
    }
    return result;
  }

  Future<List<Map<String, Object?>>> history(String caseId) async =>
      (await database
              .customSelect(
                'SELECT * FROM case_corrections WHERE case_id = ? ORDER BY corrected_at_ms, rowid',
                variables: [Variable(caseId)],
              )
              .get())
          .map((r) => r.data)
          .toList();

  Future<void> correct({
    required String caseId,
    required String actorId,
    required String expectedChecksum,
    required String reason,
    String? sampleId,
    double? initialOdometer,
    double? initialNeedle,
    double? finalOdometer,
    double? finalNeedle,
    double? initialTotalLiters,
    double? finalTotalLiters,
    double? litersPerPulse,
    double? hydrantLitersPerPulse,
    double? readingUncertaintyLiters,
    double? litersPerOdometerUnit,
    double? needleLitersPerRevolution,
    double? visualReferenceLiters,
    String? meterId,
    String? testBenchId,
  }) => database.transaction(() async {
    if (reason.trim().isEmpty) {
      throw ArgumentError('Indica el motivo de la corrección.');
    }
    final cases = LocalVerificationCaseRepository(database);
    final verification = await cases.getById(caseId);
    if (verification == null ||
        verification.status != domain.VerificationCaseStatus.closed) {
      throw StateError('Sólo se corrigen verificaciones finalizadas.');
    }
    if (verification.userId != actorId) {
      throw StateError('El expediente pertenece a otro usuario.');
    }
    if (verification.checksum != expectedChecksum) {
      throw StateError(
        'El expediente cambió. Ábrelo nuevamente antes de corregir.',
      );
    }
    final identificationUnchanged =
        (meterId == null || meterId.trim() == verification.meterId) &&
        (testBenchId == null || testBenchId.trim() == verification.testBenchId);
    if (sampleId == null && identificationUnchanged) {
      throw ArgumentError('No hay cambios para guardar.');
    }
    final flows = await LocalFlowPointRepository(database).listByCase(caseId);
    final before = await _snapshot(caseId);
    final latest = await LocalSyncBatchRepository(
      database,
    ).latestForCase(caseId);
    if (latest?.state == domain.SyncBatchState.sending) {
      throw StateError(
        'Espera a que termine la sincronización antes de editar.',
      );
    }
    // Any prior request may have reached the server, including lost ACKs.
    final remoteRevision =
        latest != null || await requiresRemoteRevision(caseId);
    await database.customStatement(
      'INSERT INTO correction_write_scope(case_id, sample_id) VALUES (?, ?)',
      [caseId, sampleId],
    );
    await database.customStatement(
      "INSERT OR IGNORE INTO correction_superseded_queue(sync_item_id) SELECT id FROM sync_items WHERE state != 'synced' AND ((entity_type = 'verificationCase' AND entity_id = ?) OR (entity_type = 'sample' AND entity_id = ?))",
      [caseId, sampleId],
    );
    if (sampleId != null) {
      final sample = await LocalSampleRepository(database).getById(sampleId);
      if (sample == null ||
          !flows.any((f) => f.id == sample.flowPointId) ||
          sample.status != domain.SampleStatus.closedValid ||
          sample.acquisitionIntegrity.isCompromised) {
        throw StateError('La muestra no permite corregir lecturas.');
      }
      if (initialOdometer == null ||
          initialNeedle == null ||
          finalOdometer == null ||
          finalNeedle == null) {
        throw ArgumentError('Completa las lecturas INICIO y FINAL.');
      }
      final c = sample.configuration;
      final k = litersPerPulse ?? c.litersPerPulse;
      final hydrantK = hydrantLitersPerPulse ?? c.hydrantLitersPerPulse;
      final uncertainty =
          readingUncertaintyLiters ?? c.readingUncertaintyLiters;
      final odometerScale = litersPerOdometerUnit ?? c.litersPerOdometerUnit;
      final needleScale =
          needleLitersPerRevolution ?? c.needleLitersPerRevolution;
      if ([
            k,
            hydrantK,
            odometerScale,
            needleScale,
          ].any((n) => !n.isFinite || n <= 0) ||
          !uncertainty.isFinite ||
          uncertainty < 0) {
        throw ArgumentError(
          'K y escalas deben ser mayores que cero; incertidumbre no negativa.',
        );
      }
      final reference = c.measurementMethod == MeasurementMethod.visual
          ? visualReferenceLiters ?? sample.result!.referenceLiters
          : sample.pulseCount * k;
      if (!reference.isFinite || reference <= 0) {
        throw ArgumentError('Vref debe ser finito y mayor que cero.');
      }
      final prior = await history(caseId);
      final originalRows = prior.isEmpty
          ? before
          : jsonDecode(prior.first['before_json'] as String) as Map;
      final original = (originalRows['samples'] as List)
          .cast<Map>()
          .singleWhere((r) => r['id'] == sampleId);
      final originalEvidencePlan = ExpectedEvidencePlan.derive(
        evidenceStepLiters: (original['evidence_step_liters'] as num)
            .toDouble(),
        finalVolumeLiters: (original['reference_liters'] as num).toDouble(),
      );
      final initial = MeterReading(
        odometerUnits: initialOdometer,
        needleLiters: initialNeedle,
        litersPerOdometerUnit: odometerScale,
        needleLitersPerRevolution: needleScale,
      );
      final finalReading = MeterReading(
        odometerUnits: finalOdometer,
        needleLiters: finalNeedle,
        litersPerOdometerUnit: odometerScale,
        needleLitersPerRevolution: needleScale,
      );
      final double indicated;
      if (c.measurementMethod.allowsUnboundedNeedleReading) {
        indicated = calculateDirectReadingAdvance(
          initial: initial,
          finalReading: finalReading,
        );
      } else {
        if (initialNeedle >= needleScale ||
            finalNeedle >= needleScale ||
            initialTotalLiters == null ||
            finalTotalLiters == null ||
            !initialTotalLiters.isFinite ||
            !finalTotalLiters.isFinite ||
            initialTotalLiters < 0 ||
            finalTotalLiters < initialTotalLiters) {
          throw ArgumentError('Revisa aguja y totales INICIO/FINAL en litros.');
        }
        indicated = finalTotalLiters - initialTotalLiters;
      }
      if (identificationUnchanged &&
          initialOdometer == sample.initialReading?.reading.odometerUnits &&
          initialNeedle == sample.initialReading?.reading.needleLiters &&
          finalOdometer == sample.finalReading?.reading.odometerUnits &&
          finalNeedle == sample.finalReading?.reading.needleLiters &&
          indicated == sample.result!.indicatedLiters &&
          reference == sample.result!.referenceLiters &&
          k == c.litersPerPulse &&
          hydrantK == c.hydrantLitersPerPulse &&
          uncertainty == c.readingUncertaintyLiters &&
          odometerScale == c.litersPerOdometerUnit &&
          needleScale == c.needleLitersPerRevolution) {
        throw ArgumentError('No hay cambios para guardar.');
      }
      await (database.update(
        database.samples,
      )..where((s) => s.id.equals(sampleId))).write(
        db.SamplesCompanion(
          litersPerPulse: Value(k),
          readingUncertaintyLiters: Value(uncertainty),
          litersPerOdometerUnit: Value(odometerScale),
          needleLitersPerRevolution: Value(needleScale),
          progressReferenceLiters: Value(reference),
          initialOdometerUnits: Value(initialOdometer),
          initialNeedleLiters: Value(initialNeedle),
          finalOdometerUnits: Value(finalOdometer),
          finalNeedleLiters: Value(finalNeedle),
          initialReadingSource: Value(domain.ReadingSource.manual.name),
          finalReadingSource: Value(domain.ReadingSource.manual.name),
          indicatedLiters: Value(indicated),
        ),
      );
      if (hydrantK != c.hydrantLitersPerPulse) {
        await database.customStatement(
          'INSERT INTO sample_operational_settings(sample_id, minimum_volume_liters, maximum_volume_liters, control_start_minimum_lps, control_start_maximum_lps, hydrant_liters_per_pulse) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT(sample_id) DO UPDATE SET hydrant_liters_per_pulse = excluded.hydrant_liters_per_pulse',
          [
            sampleId,
            c.minimumVolumeLiters ?? 100,
            c.maximumVolumeLiters ?? 300,
            c.controlStartMinimumLps,
            c.controlStartMaximumLps.isFinite
                ? c.controlStartMaximumLps
                : 1.0e308,
            hydrantK,
          ],
        );
      }
      final ratio = reference / sample.result!.referenceLiters;
      if (ratio != 1) {
        await database.customStatement(
          'UPDATE test_points SET reference_liters = reference_liters * ?, flow_lps = flow_lps * ?, diagnostic_error_pct = CASE WHEN reference_liters > 0 AND indicated_liters IS NOT NULL THEN (indicated_liters - reference_liters * ?) / (reference_liters * ?) * 100 ELSE diagnostic_error_pct END WHERE sample_id = ?',
          [ratio, ratio, ratio, ratio, sampleId],
        );
      }
      await LocalSampleClosureService(database, fileStore).recalculate(
        sampleId,
        at: sample.endedAt!,
        originalEvidencePlan: originalEvidencePlan,
      );
      await (database.update(
        database.samples,
      )..where((s) => s.id.equals(sampleId))).write(
        db.SamplesCompanion(
          updatedAtMs: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        ),
      );
    }
    if (meterId != null && meterId.trim().isEmpty ||
        testBenchId != null && testBenchId.trim().isEmpty) {
      throw ArgumentError('Cuenta y banco de pruebas son obligatorios.');
    }
    if (meterId != null && meterId.trim() != verification.meterId) {
      final id = meterId.trim();
      final meters = LocalMeterRepository(database);
      if (await meters.getById(id) == null) {
        await meters.save(
          domain.Meter(
            id: id,
            externalStatus: domain.ExternalMeterStatus.unknownOffline,
            createdAt: DateTime.now().toUtc(),
          ),
        );
      }
    }
    await (database.update(
      database.verificationCases,
    )..where((c) => c.id.equals(caseId))).write(
      db.VerificationCasesCompanion(
        meterId: meterId == null ? const Value.absent() : Value(meterId.trim()),
        testBenchId: testBenchId == null
            ? const Value.absent()
            : Value(testBenchId.trim()),
        reportVersion: Value(verification.reportVersion + 1),
      ),
    );
    await LocalVerificationCaseClosureService(database).recalculate(
      caseId: caseId,
      requiredFlowPoints: flows.map((f) => f.code).toSet(),
      at: verification.closedAt!,
    );
    // Reverting to an earlier value can reproduce a prior checksum. Restore
    // its queue entry instead of leaving the current snapshot superseded.
    await database.customStatement(
      "DELETE FROM correction_superseded_queue WHERE sync_item_id IN (SELECT q.id FROM sync_items q JOIN samples s ON q.entity_id = s.id AND q.checksum = s.checksum WHERE q.entity_type = 'sample' AND s.id = ?)",
      [sampleId],
    );
    await database.customStatement(
      'INSERT INTO case_corrections '
      '(id, case_id, sample_id, actor_id, corrected_at_ms, reason, before_json, after_json, requires_remote_revision) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        const Uuid().v4(),
        caseId,
        sampleId,
        actorId,
        DateTime.now().toUtc().millisecondsSinceEpoch,
        reason.trim(),
        jsonEncode(before),
        jsonEncode({
          ...await _snapshot(caseId),
          'manualInput': {
            'initialTotalLiters': initialTotalLiters,
            'finalTotalLiters': finalTotalLiters,
          },
        }),
        remoteRevision ? 1 : 0,
      ],
    );
    await database.customStatement(
      'DELETE FROM correction_write_scope WHERE case_id = ?',
      [caseId],
    );
  });

  Future<Map<String, Object?>> _snapshot(String caseId) async {
    Future<List<Map<String, Object?>>> rows(String sql) async =>
        (await database.customSelect(sql, variables: [Variable(caseId)]).get())
            .map((r) => r.data)
            .toList();
    return {
      'case': await rows('SELECT * FROM verification_cases WHERE id = ?'),
      'flows': await rows('SELECT * FROM flow_points WHERE case_id = ?'),
      'samples': await rows(
        'SELECT s.* FROM samples s JOIN flow_points f ON f.id = s.flow_point_id WHERE f.case_id = ?',
      ),
      'operationalSettings': await rows(
        'SELECT o.* FROM sample_operational_settings o JOIN samples s ON s.id = o.sample_id JOIN flow_points f ON f.id = s.flow_point_id WHERE f.case_id = ?',
      ),
      'points': await rows(
        'SELECT p.* FROM test_points p JOIN samples s ON s.id = p.sample_id JOIN flow_points f ON f.id = s.flow_point_id WHERE f.case_id = ?',
      ),
    };
  }
}
