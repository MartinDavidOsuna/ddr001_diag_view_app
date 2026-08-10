import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/metrology/metrology.dart' as metrology;
import '../../../domain/models.dart' as domain;
import '../../../domain/repositories.dart';
import '../database/app_database.dart' as db;

DateTime _date(int value) =>
    DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
int _ms(DateTime value) => value.toUtc().millisecondsSinceEpoch;

final class LocalUserRepository implements UserRepository {
  LocalUserRepository(this.database);
  final db.AppDatabase database;

  @override
  Future<void> save(domain.User user) => database
      .into(database.users)
      .insertOnConflictUpdate(
        db.UsersCompanion.insert(
          id: user.id,
          email: user.email,
          phone: user.phone,
          displayName: Value(user.displayName),
          createdAtMs: _ms(user.createdAt),
          lastLoginAtMs: Value(
            user.lastLoginAt == null ? null : _ms(user.lastLoginAt!),
          ),
        ),
      );

  @override
  Future<domain.User?> getById(String id) async {
    final row = await (database.select(
      database.users,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _user(row);
  }

  @override
  Future<domain.User?> getByEmailAndPhone(String email, String phone) async {
    final normalizedEmail = domain.normalizeEmail(email);
    final normalizedPhone = domain.normalizePhone(phone);
    final row =
        await (database.select(database.users)..where(
              (t) =>
                  t.email.equals(normalizedEmail) &
                  t.phone.equals(normalizedPhone),
            ))
            .getSingleOrNull();
    return row == null ? null : _user(row);
  }

  domain.User _user(db.User row) => domain.User(
    id: row.id,
    email: row.email,
    phone: row.phone,
    displayName: row.displayName,
    createdAt: _date(row.createdAtMs),
    lastLoginAt: row.lastLoginAtMs == null ? null : _date(row.lastLoginAtMs!),
  );
}

final class LocalMeterRepository implements MeterRepository {
  LocalMeterRepository(this.database);
  final db.AppDatabase database;

  @override
  Future<void> save(domain.Meter meter) => database
      .into(database.meters)
      .insertOnConflictUpdate(
        db.MetersCompanion.insert(
          id: meter.id,
          externalStatus: meter.externalStatus.name,
          externalSnapshotJson: Value(meter.externalSnapshotJson),
          externalCheckedAtMs: Value(
            meter.externalCheckedAt == null
                ? null
                : _ms(meter.externalCheckedAt!),
          ),
          createdAtMs: _ms(meter.createdAt),
          updatedAtMs: _ms(meter.updatedAt),
        ),
      );

  @override
  Future<domain.Meter?> getById(String id) async {
    final row = await (database.select(
      database.meters,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null
        ? null
        : domain.Meter(
            id: row.id,
            externalStatus: domain.ExternalMeterStatus.values.byName(
              row.externalStatus,
            ),
            externalSnapshotJson: row.externalSnapshotJson,
            externalCheckedAt: row.externalCheckedAtMs == null
                ? null
                : _date(row.externalCheckedAtMs!),
            createdAt: _date(row.createdAtMs),
            updatedAt: _date(row.updatedAtMs),
          );
  }
}

final class LocalVerificationCaseRepository
    implements VerificationCaseRepository {
  LocalVerificationCaseRepository(this.database);
  final db.AppDatabase database;

  @override
  Future<void> create(domain.VerificationCase value) async {
    if (value.status != domain.VerificationCaseStatus.open ||
        value.overallVerdict != null ||
        value.closedAt != null ||
        value.checksum != null) {
      throw StateError('A new case must be OPEN and unfinished.');
    }
    await database
        .into(database.verificationCases)
        .insert(_caseCompanion(value));
  }

  @override
  Future<domain.VerificationCase?> getById(String id) async {
    final row = await (database.select(
      database.verificationCases,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : mapCase(row);
  }

  @override
  Future<domain.VerificationCase?> findOpenByMeter(String meterId) async {
    final query = database.select(database.verificationCases)
      ..where(
        (t) =>
            t.meterId.equals(meterId) &
            t.status.equals(domain.VerificationCaseStatus.open.name),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : mapCase(row);
  }

  @override
  Future<List<domain.VerificationCase>> listLocalCases() async =>
      (await (database.select(
            database.verificationCases,
          )..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)])).get())
          .map(mapCase)
          .toList(growable: false);

  @override
  Future<List<domain.VerificationCase>> listOpenCases() async =>
      (await (database.select(database.verificationCases)..where(
                (t) => t.status.equals(domain.VerificationCaseStatus.open.name),
              ))
              .get())
          .map(mapCase)
          .toList(growable: false);
}

db.VerificationCasesCompanion _caseCompanion(domain.VerificationCase value) =>
    db.VerificationCasesCompanion.insert(
      id: value.id,
      meterId: value.meterId,
      userId: value.userId,
      status: value.status.name,
      overallVerdict: Value(value.overallVerdict?.name),
      createdAtMs: _ms(value.createdAt),
      closedAtMs: Value(value.closedAt == null ? null : _ms(value.closedAt!)),
      reportVersion: Value(value.reportVersion),
      checksum: Value(value.checksum),
    );

domain.VerificationCase mapCase(db.VerificationCaseRow row) =>
    domain.VerificationCase(
      id: row.id,
      meterId: row.meterId,
      userId: row.userId,
      status: domain.VerificationCaseStatus.values.byName(row.status),
      overallVerdict: row.overallVerdict == null
          ? null
          : domain.OverallVerdict.values.byName(row.overallVerdict!),
      createdAt: _date(row.createdAtMs),
      closedAt: row.closedAtMs == null ? null : _date(row.closedAtMs!),
      reportVersion: row.reportVersion,
      checksum: row.checksum,
    );

final class LocalFlowPointRepository implements FlowPointRepository {
  LocalFlowPointRepository(this.database);
  final db.AppDatabase database;

  @override
  Future<void> create(domain.FlowPointRecord flowPoint) async {
    await _ensureCaseOpen(database, flowPoint.caseId);
    await database
        .into(database.flowPoints)
        .insert(
          db.FlowPointsCompanion.insert(
            id: flowPoint.id,
            caseId: flowPoint.caseId,
            code: flowPoint.code.name,
            lpsApprox: Value(flowPoint.lpsApprox),
            mpePct: flowPoint.mpePct,
            status: Value(flowPoint.status.name),
            createdAtMs: _ms(flowPoint.createdAt),
          ),
        );
  }

  @override
  Future<domain.FlowPointRecord?> getById(String id) async {
    final row = await (database.select(
      database.flowPoints,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : mapFlow(row);
  }

  @override
  Future<List<domain.FlowPointRecord>> listByCase(String caseId) async =>
      (await (database.select(
            database.flowPoints,
          )..where((t) => t.caseId.equals(caseId))).get())
          .map(mapFlow)
          .toList(growable: false);

  @override
  Future<metrology.FlowPointResult> summarize(String flowPointId) async {
    final flow = await getById(flowPointId);
    if (flow == null) throw StateError('Flow point not found.');
    final sampleRows =
        await (database.select(database.samples)
              ..where(
                (t) =>
                    t.flowPointId.equals(flowPointId) &
                    t.status.equals(domain.SampleStatus.closedValid.name),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.sampleNumber)]))
            .get();
    return metrology.FlowPointResult.summarize(
      flowPoint: flow.code,
      samples: sampleRows.map((row) => mapSample(row).result!).toList(),
      mpePct: flow.mpePct,
    );
  }
}

domain.FlowPointRecord mapFlow(db.FlowPointRow row) {
  final hasStats = row.statisticsN != null;
  return domain.FlowPointRecord(
    id: row.id,
    caseId: row.caseId,
    code: metrology.FlowPoint.values.byName(row.code),
    lpsApprox: row.lpsApprox,
    mpePct: row.mpePct,
    status: domain.FlowRecordStatus.values.byName(row.status),
    statistics: hasStats
        ? domain.PersistedFlowStatistics(
            n: row.statisticsN!,
            meanErrorPct: row.meanErrorPct!,
            minimumErrorPct: row.minimumErrorPct!,
            maximumErrorPct: row.maximumErrorPct!,
            dispersionPct: row.dispersionPct!,
            sampleStandardDeviationPct: row.sampleStdDevPct,
            repeatabilityStatus: metrology.RepeatabilityStatus.values.byName(
              row.repeatabilityStatus!,
            ),
          )
        : null,
    createdAt: _date(row.createdAtMs),
  );
}

final class LocalSampleRepository implements SampleRepository {
  LocalSampleRepository(this.database);
  final db.AppDatabase database;

  @override
  Future<domain.Sample> createDraft(domain.Sample sample) async {
    if (sample.status != domain.SampleStatus.draft) {
      throw StateError('createDraft requires a DRAFT sample.');
    }
    await _ensureCaseOpenForFlow(database, sample.flowPointId);
    final flow = await (database.select(
      database.flowPoints,
    )..where((t) => t.id.equals(sample.flowPointId))).getSingle();
    if (flow.code != sample.configuration.flowPoint.name ||
        flow.mpePct != sample.configuration.mpePct) {
      throw StateError(
        'Frozen sample configuration must match its flow point.',
      );
    }
    await database.into(database.samples).insert(_sampleCompanion(sample));
    return sample;
  }

  @override
  Future<domain.Sample?> getById(String id) async {
    final row = await (database.select(
      database.samples,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : mapSample(row);
  }

  @override
  Future<domain.Sample> start(
    String id, {
    required DateTime at,
    domain.GpsSnapshot? gps,
  }) => database.transaction(() async {
    final current = await _requiredSample(database, id);
    if (current.status != domain.SampleStatus.draft) {
      throw StateError('Only a DRAFT sample can start.');
    }
    await _ensureCaseOpenForFlow(database, current.flowPointId);
    await (database.update(
      database.samples,
    )..where((t) => t.id.equals(id))).write(
      db.SamplesCompanion(
        status: Value(domain.SampleStatus.running.name),
        startedAtMs: Value(_ms(at)),
        updatedAtMs: Value(_ms(at)),
        gpsLatitude: Value(gps?.latitude),
        gpsLongitude: Value(gps?.longitude),
        gpsAccuracyMeters: Value(gps?.accuracyMeters),
        gpsCapturedAtMs: Value(gps == null ? null : _ms(gps.capturedAt)),
      ),
    );
    return (await getById(id))!;
  });

  @override
  Future<domain.Sample> updateProgress({
    required String id,
    required int pulseCount,
    double? referenceLiters,
    domain.ConfirmedReading? initialReading,
    domain.ConfirmedReading? finalReading,
  }) => database.transaction(() async {
    final current = await _requiredSample(database, id);
    if (current.status != domain.SampleStatus.running) {
      throw StateError('Only a RUNNING sample can be updated.');
    }
    if (pulseCount < 0 || (referenceLiters != null && referenceLiters <= 0)) {
      throw ArgumentError('Invalid progress values.');
    }
    await (database.update(
      database.samples,
    )..where((t) => t.id.equals(id))).write(
      db.SamplesCompanion(
        pulseCount: Value(pulseCount),
        progressReferenceLiters: Value(
          referenceLiters ?? current.referenceLitersProgress,
        ),
        updatedAtMs: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
        initialOdometerUnits: initialReading == null
            ? const Value.absent()
            : Value(initialReading.reading.odometerUnits),
        initialNeedleLiters: initialReading == null
            ? const Value.absent()
            : Value(initialReading.reading.needleLiters),
        initialReadingSource: initialReading == null
            ? const Value.absent()
            : Value(initialReading.source.name),
        finalOdometerUnits: finalReading == null
            ? const Value.absent()
            : Value(finalReading.reading.odometerUnits),
        finalNeedleLiters: finalReading == null
            ? const Value.absent()
            : Value(finalReading.reading.needleLiters),
        finalReadingSource: finalReading == null
            ? const Value.absent()
            : Value(finalReading.source.name),
      ),
    );
    return (await getById(id))!;
  });

  @override
  Future<domain.Sample> markInvalidEvidence(
    String id, {
    required DateTime at,
  }) => database.transaction(() async {
    final current = await _requiredSample(database, id);
    if (current.status != domain.SampleStatus.running) {
      throw StateError('Only a RUNNING sample can become invalid.');
    }
    await (database.update(
      database.samples,
    )..where((t) => t.id.equals(id))).write(
      db.SamplesCompanion(
        status: Value(domain.SampleStatus.invalidEvidence.name),
        endedAtMs: Value(_ms(at)),
        updatedAtMs: Value(_ms(at)),
      ),
    );
    return (await getById(id))!;
  });

  @override
  Future<List<domain.Sample>> listByFlow(String flowPointId) async =>
      (await (database.select(database.samples)
                ..where((t) => t.flowPointId.equals(flowPointId))
                ..orderBy([(t) => OrderingTerm.asc(t.sampleNumber)]))
              .get())
          .map(mapSample)
          .toList(growable: false);

  @override
  Future<List<domain.Sample>> listIncomplete() async =>
      (await (database.select(database.samples)..where(
                (t) => t.status.isIn([
                  domain.SampleStatus.draft.name,
                  domain.SampleStatus.running.name,
                  domain.SampleStatus.invalidEvidence.name,
                ]),
              ))
              .get())
          .map(mapSample)
          .toList(growable: false);

  @override
  Future<domain.Sample?> getActiveByFlow(String flowPointId) async {
    final query = database.select(database.samples)
      ..where(
        (t) =>
            t.flowPointId.equals(flowPointId) &
            t.status.isIn([
              domain.SampleStatus.draft.name,
              domain.SampleStatus.running.name,
            ]),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.sampleNumber)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : mapSample(row);
  }
}

db.SamplesCompanion _sampleCompanion(domain.Sample sample) {
  final config = sample.configuration;
  return db.SamplesCompanion.insert(
    id: sample.id,
    flowPointId: sample.flowPointId,
    sampleNumber: sample.sampleNumber,
    status: sample.status.name,
    measurementMethod: config.measurementMethod.name,
    litersPerPulse: config.litersPerPulse,
    evidenceStepLiters: config.evidenceStepLiters,
    readingUncertaintyLiters: config.readingUncertaintyLiters,
    flowPointCode: config.flowPoint.name,
    mpePct: config.mpePct,
    lpsApprox: Value(config.lpsApprox),
    litersPerOdometerUnit: config.litersPerOdometerUnit,
    needleLitersPerRevolution: config.needleLitersPerRevolution,
    createdAtMs: _ms(sample.createdAt),
    updatedAtMs: _ms(sample.updatedAt),
    pulseCount: Value(sample.pulseCount),
    progressReferenceLiters: Value(sample.referenceLitersProgress),
  );
}

domain.Sample mapSample(db.SampleRow row) {
  final config = domain.SampleConfiguration(
    measurementMethod: metrology.MeasurementMethod.values.byName(
      row.measurementMethod,
    ),
    litersPerPulse: row.litersPerPulse,
    evidenceStepLiters: row.evidenceStepLiters,
    readingUncertaintyLiters: row.readingUncertaintyLiters,
    flowPoint: metrology.FlowPoint.values.byName(row.flowPointCode),
    mpePct: row.mpePct,
    lpsApprox: row.lpsApprox,
    litersPerOdometerUnit: row.litersPerOdometerUnit,
    needleLitersPerRevolution: row.needleLitersPerRevolution,
  );
  domain.ConfirmedReading? reading(
    double? odometer,
    double? needle,
    String? source,
  ) => odometer == null || needle == null || source == null
      ? null
      : domain.ConfirmedReading(
          reading: metrology.MeterReading(
            odometerUnits: odometer,
            needleLiters: needle,
            litersPerOdometerUnit: row.litersPerOdometerUnit,
            needleLitersPerRevolution: row.needleLitersPerRevolution,
          ),
          source: domain.ReadingSource.values.byName(source),
        );
  final hasResult = row.referenceLiters != null;
  return domain.Sample(
    id: row.id,
    flowPointId: row.flowPointId,
    sampleNumber: row.sampleNumber,
    status: domain.SampleStatus.values.byName(row.status),
    configuration: config,
    createdAt: _date(row.createdAtMs),
    updatedAt: _date(row.updatedAtMs),
    startedAt: row.startedAtMs == null ? null : _date(row.startedAtMs!),
    endedAt: row.endedAtMs == null ? null : _date(row.endedAtMs!),
    gps: row.gpsLatitude == null
        ? null
        : domain.GpsSnapshot(
            latitude: row.gpsLatitude!,
            longitude: row.gpsLongitude!,
            accuracyMeters: row.gpsAccuracyMeters!,
            capturedAt: _date(row.gpsCapturedAtMs!),
          ),
    pulseCount: row.pulseCount,
    referenceLitersProgress: row.progressReferenceLiters,
    initialReading: reading(
      row.initialOdometerUnits,
      row.initialNeedleLiters,
      row.initialReadingSource,
    ),
    finalReading: reading(
      row.finalOdometerUnits,
      row.finalNeedleLiters,
      row.finalReadingSource,
    ),
    result: !hasResult
        ? null
        : metrology.SampleResult(
            referenceLiters: row.referenceLiters!,
            indicatedLiters: row.indicatedLiters!,
            errorPct: row.errorPct!,
            uncertaintyPct: row.uncertaintyPct!,
            mpePct: row.resultMpePct!,
            decisionMetrics: metrology.DecisionMetrics(
              acceptanceMetricPct: row.acceptanceMetricPct!,
              rejectionMetricPct: row.rejectionMetricPct!,
            ),
            verdict: metrology.SampleVerdict.values.byName(row.verdict!),
          ),
    checksum: row.checksum,
  );
}

Future<domain.Sample> _requiredSample(
  db.AppDatabase database,
  String id,
) async {
  final row = await (database.select(
    database.samples,
  )..where((t) => t.id.equals(id))).getSingleOrNull();
  if (row == null) throw StateError('Sample not found.');
  return mapSample(row);
}

Future<void> _ensureCaseOpenForFlow(
  db.AppDatabase database,
  String flowId,
) async {
  final flow = await (database.select(
    database.flowPoints,
  )..where((t) => t.id.equals(flowId))).getSingleOrNull();
  if (flow == null) throw StateError('Flow point not found.');
  await _ensureCaseOpen(database, flow.caseId);
}

Future<void> _ensureCaseOpen(db.AppDatabase database, String caseId) async {
  final row = await (database.select(
    database.verificationCases,
  )..where((t) => t.id.equals(caseId))).getSingleOrNull();
  if (row == null) throw StateError('Verification case not found.');
  if (row.status != domain.VerificationCaseStatus.open.name) {
    throw StateError('Verification case is CLOSED.');
  }
}

final class LocalPointRepository implements PointRepository {
  LocalPointRepository(this.database);
  final db.AppDatabase database;

  @override
  Future<void> save(domain.TestPoint point) async {
    final sample = await _requiredSample(database, point.sampleId);
    if (sample.status == domain.SampleStatus.closedValid) {
      throw StateError('Closed sample points are immutable.');
    }
    await database
        .into(database.testPoints)
        .insert(
          db.TestPointsCompanion.insert(
            id: point.id,
            sampleId: point.sampleId,
            type: point.type.name,
            pulseCount: Value(point.pulseCount),
            referenceLiters: Value(point.referenceLiters),
            readingLiters: Value(point.readingLiters),
            indicatedLiters: Value(point.indicatedLiters),
            diagnosticErrorPct: Value(point.diagnosticErrorPct),
            needleLiters: Value(point.needleLiters),
            capturedAtMs: _ms(point.capturedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<List<domain.TestPoint>> listBySample(String sampleId) async =>
      (await (database.select(
            database.testPoints,
          )..where((t) => t.sampleId.equals(sampleId))).get())
          .map(
            (row) => domain.TestPoint(
              id: row.id,
              sampleId: row.sampleId,
              type: domain.PointType.values.byName(row.type),
              pulseCount: row.pulseCount,
              referenceLiters: row.referenceLiters,
              readingLiters: row.readingLiters,
              indicatedLiters: row.indicatedLiters,
              diagnosticErrorPct: row.diagnosticErrorPct,
              needleLiters: row.needleLiters,
              capturedAt: _date(row.capturedAtMs),
            ),
          )
          .toList(growable: false);
}

final class LocalEvidenceRepository implements EvidenceRepository {
  LocalEvidenceRepository(this.database);
  final db.AppDatabase database;

  @override
  Future<void> save(domain.Evidence evidence) async {
    final sample = await _requiredSample(database, evidence.sampleId);
    if (sample.status == domain.SampleStatus.closedValid) {
      throw StateError('Closed sample evidence is immutable.');
    }
    await database
        .into(database.evidenceItems)
        .insert(_evidenceCompanion(evidence), mode: InsertMode.insertOrReplace);
  }

  @override
  Future<domain.Evidence?> getById(String id) async {
    final row = await (database.select(
      database.evidenceItems,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : mapEvidence(row);
  }

  @override
  Future<List<domain.Evidence>> listBySample(String sampleId) async =>
      (await (database.select(
            database.evidenceItems,
          )..where((t) => t.sampleId.equals(sampleId))).get())
          .map(mapEvidence)
          .toList(growable: false);

  @override
  Future<bool> hasCompleteRequiredSet(String sampleId) async {
    final evidence = await listBySample(sampleId);
    bool valid(domain.Evidence item) =>
        item.required &&
        item.sha256 != null &&
        item.sha256!.length == 64 &&
        item.localPath.isNotEmpty;
    return evidence.any(
          (e) => e.type == domain.EvidenceType.start && valid(e),
        ) &&
        evidence.any(
          (e) => e.type == domain.EvidenceType.finalEvidence && valid(e),
        );
  }
}

db.EvidenceItemsCompanion _evidenceCompanion(domain.Evidence value) =>
    db.EvidenceItemsCompanion.insert(
      id: value.id,
      sampleId: value.sampleId,
      pointId: Value(value.pointId),
      type: value.type.name,
      required: value.required,
      volumeRefLiters: Value(value.volumeRefLiters),
      pulseCount: Value(value.pulseCount),
      capturedAtMs: _ms(value.capturedAt),
      sha256: Value(value.sha256),
      localPath: value.localPath,
      serverStorageKey: Value(value.serverStorageKey),
      syncStatus: value.syncStatus.name,
    );

domain.Evidence mapEvidence(db.EvidenceRow row) => domain.Evidence(
  id: row.id,
  sampleId: row.sampleId,
  pointId: row.pointId,
  type: domain.EvidenceType.values.byName(row.type),
  required: row.required,
  volumeRefLiters: row.volumeRefLiters,
  pulseCount: row.pulseCount,
  capturedAt: _date(row.capturedAtMs),
  sha256: row.sha256,
  localPath: row.localPath,
  serverStorageKey: row.serverStorageKey,
  syncStatus: domain.EvidenceSyncStatus.values.byName(row.syncStatus),
);

final class LocalSyncQueueRepository implements SyncQueueRepository {
  LocalSyncQueueRepository(this.database, [this._uuid = const Uuid()]);
  final db.AppDatabase database;
  final Uuid _uuid;

  @override
  Future<domain.SyncItem> enqueue({
    required String entityType,
    required String entityId,
    required String checksum,
    required DateTime at,
  }) => database.transaction(() async {
    final existing =
        await (database.select(database.syncItems)..where(
              (t) =>
                  t.entityType.equals(entityType) &
                  t.entityId.equals(entityId) &
                  t.checksum.equals(checksum),
            ))
            .getSingleOrNull();
    if (existing != null) return mapSync(existing);
    final id = _uuid.v4();
    await database
        .into(database.syncItems)
        .insert(
          db.SyncItemsCompanion.insert(
            id: id,
            entityType: entityType,
            entityId: entityId,
            checksum: checksum,
            state: domain.SyncState.pending.name,
            createdAtMs: _ms(at),
            updatedAtMs: _ms(at),
          ),
        );
    return mapSync(
      await (database.select(
        database.syncItems,
      )..where((t) => t.id.equals(id))).getSingle(),
    );
  });

  @override
  Future<List<domain.SyncItem>> listPending() async =>
      (await (database.select(database.syncItems)
                ..where(
                  (t) => t.state.isIn([
                    domain.SyncState.pending.name,
                    domain.SyncState.failed.name,
                  ]),
                )
                ..orderBy([(t) => OrderingTerm.asc(t.createdAtMs)]))
              .get())
          .map(mapSync)
          .toList(growable: false);

  @override
  Future<void> incrementAttempt(String id, {required DateTime at}) async {
    final row = await _syncRow(database, id);
    await (database.update(
      database.syncItems,
    )..where((t) => t.id.equals(id))).write(
      db.SyncItemsCompanion(
        attempts: Value(row.attempts + 1),
        state: Value(domain.SyncState.inProgress.name),
        updatedAtMs: Value(_ms(at)),
      ),
    );
  }

  @override
  Future<void> markFailed(
    String id, {
    required String error,
    required DateTime at,
    DateTime? nextRetryAt,
  }) async {
    await _syncRow(database, id);
    await (database.update(
      database.syncItems,
    )..where((t) => t.id.equals(id))).write(
      db.SyncItemsCompanion(
        state: Value(domain.SyncState.failed.name),
        lastError: Value(error),
        updatedAtMs: Value(_ms(at)),
        nextRetryAtMs: Value(nextRetryAt == null ? null : _ms(nextRetryAt)),
      ),
    );
  }

  @override
  Future<void> markSynced(String id, {required DateTime at}) async {
    await _syncRow(database, id);
    await (database.update(
      database.syncItems,
    )..where((t) => t.id.equals(id))).write(
      db.SyncItemsCompanion(
        state: Value(domain.SyncState.synced.name),
        lastError: const Value(null),
        updatedAtMs: Value(_ms(at)),
        nextRetryAtMs: const Value(null),
      ),
    );
  }
}

Future<db.SyncItemRow> _syncRow(db.AppDatabase database, String id) async {
  final row = await (database.select(
    database.syncItems,
  )..where((t) => t.id.equals(id))).getSingleOrNull();
  if (row == null) throw StateError('Sync item not found.');
  return row;
}

domain.SyncItem mapSync(db.SyncItemRow row) => domain.SyncItem(
  id: row.id,
  entityType: row.entityType,
  entityId: row.entityId,
  checksum: row.checksum,
  state: domain.SyncState.values.byName(row.state),
  attempts: row.attempts,
  lastError: row.lastError,
  createdAt: _date(row.createdAtMs),
  updatedAt: _date(row.updatedAtMs),
  nextRetryAt: row.nextRetryAtMs == null ? null : _date(row.nextRetryAtMs!),
);
