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
      testBenchId: Value(value.testBenchId),
      deviceId: Value(value.deviceId),
      androidVersion: Value(value.androidVersion),
      deviceBrand: Value(value.deviceBrand),
      deviceModel: Value(value.deviceModel),
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
      testBenchId: row.testBenchId,
      deviceId: row.deviceId,
      androidVersion: row.androidVersion,
      deviceBrand: row.deviceBrand,
      deviceModel: row.deviceModel,
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
  Future<void> updateLps(String id, double lpsApprox) async {
    final flow = await getById(id);
    if (flow == null) throw StateError('Flow point not found.');
    await _ensureCaseOpen(database, flow.caseId);
    await (database.update(database.flowPoints)
          ..where((table) => table.id.equals(id)))
        .write(db.FlowPointsCompanion(lpsApprox: Value(lpsApprox)));
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
    await database.transaction(() async {
      await database.into(database.samples).insert(_sampleCompanion(sample));
      final minimum = sample.configuration.minimumVolumeLiters;
      final maximum = sample.configuration.maximumVolumeLiters;
      if (minimum != null && maximum != null) {
        await database.customStatement(
          'INSERT INTO sample_operational_settings '
          '(sample_id, minimum_volume_liters, maximum_volume_liters, control_start_minimum_lps, control_start_maximum_lps, hydrant_liters_per_pulse) VALUES (?, ?, ?, ?, ?, ?)',
          [
            sample.id,
            minimum,
            maximum,
            sample.configuration.controlStartMinimumLps,
            sample.configuration.controlStartMaximumLps,
            sample.configuration.hydrantLitersPerPulse,
          ],
        );
      }
    });
    return sample;
  }

  @override
  Future<domain.Sample?> getById(String id) async {
    final row = await (database.select(
      database.samples,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : mapSampleWithSettings(database, row);
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
    double? manualIndicatedLiters,
    DateTime? firstPulseAt,
    domain.ConfirmedReading? initialReading,
    domain.ConfirmedReading? finalReading,
  }) => database.transaction(() async {
    final current = await _requiredSample(database, id);
    if (current.status != domain.SampleStatus.running) {
      throw StateError('Only a RUNNING sample can be updated.');
    }
    if (pulseCount < 0 ||
        (referenceLiters != null && referenceLiters <= 0) ||
        (manualIndicatedLiters != null && manualIndicatedLiters < 0)) {
      throw ArgumentError('Invalid progress values.');
    }
    await (database.update(
      database.samples,
    )..where((t) => t.id.equals(id))).write(
      db.SamplesCompanion(
        pulseCount: Value(pulseCount),
        startedAtMs: firstPulseAt != null && current.pulseCount == 0
            ? Value(_ms(firstPulseAt))
            : const Value.absent(),
        progressReferenceLiters: Value(
          referenceLiters ?? current.referenceLitersProgress,
        ),
        indicatedLiters: manualIndicatedLiters == null
            ? const Value.absent()
            : Value(manualIndicatedLiters),
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
        initialReadingEvidenceId: initialReading == null
            ? const Value.absent()
            : Value(initialReading.evidenceId),
        finalOdometerUnits: finalReading == null
            ? const Value.absent()
            : Value(finalReading.reading.odometerUnits),
        finalNeedleLiters: finalReading == null
            ? const Value.absent()
            : Value(finalReading.reading.needleLiters),
        finalReadingSource: finalReading == null
            ? const Value.absent()
            : Value(finalReading.source.name),
        finalReadingEvidenceId: finalReading == null
            ? const Value.absent()
            : Value(finalReading.evidenceId),
      ),
    );
    return (await getById(id))!;
  });

  @override
  Future<domain.Sample> updateMeterFaceConfiguration(
    String id,
    domain.MeterFaceConfiguration configuration,
  ) => database.transaction(() async {
    final current = await _requiredSample(database, id);
    if (current.status != domain.SampleStatus.running) {
      throw StateError('Only a RUNNING sample can be configured.');
    }
    await (database.update(
      database.samples,
    )..where((t) => t.id.equals(id))).write(
      db.SamplesCompanion(
        totalizerLeft: Value(configuration.totalizerLeft),
        totalizerTop: Value(configuration.totalizerTop),
        totalizerWidth: Value(configuration.totalizerWidth),
        totalizerHeight: Value(configuration.totalizerHeight),
        dialCenterX: Value(configuration.dialCenterX),
        dialCenterY: Value(configuration.dialCenterY),
        dialRadius: Value(configuration.dialRadius),
        dialMultiplier: Value(configuration.multiplier),
        dialLitersPerRevolution: Value(configuration.litersPerRevolution),
        dialZeroAngleDegrees: Value(configuration.zeroAngleDegrees),
        dialClockwise: Value(configuration.clockwise),
        dialConfigurationSource: Value(configuration.source.name),
        totalizerDigitCount: Value(
          configuration.totalizerConfiguration?.digitCount,
        ),
        totalizerDecimalPlaces: Value(
          configuration.totalizerConfiguration?.decimalPlaces,
        ),
        totalizerUnit: Value(configuration.totalizerConfiguration?.unit.name),
        totalizerLeadingZerosAllowed: Value(
          configuration.totalizerConfiguration?.leadingZerosAllowed,
        ),
        totalizerConfigurationSource: Value(
          configuration.totalizerConfiguration?.source.name,
        ),
        needleLitersPerRevolution: Value(configuration.litersPerRevolution),
        updatedAtMs: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
      ),
    );
    return (await getById(id))!;
  });

  @override
  Future<domain.Sample> updateCameraZoom(String id, double zoomLevel) =>
      database.transaction(() async {
        final current = await _requiredSample(database, id);
        if (current.status != domain.SampleStatus.running) {
          throw StateError('Only a RUNNING sample can update camera zoom.');
        }
        await (database.update(
          database.samples,
        )..where((table) => table.id.equals(id))).write(
          db.SamplesCompanion(
            cameraZoomLevel: Value(zoomLevel),
            updatedAtMs: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
          ),
        );
        return (await getById(id))!;
      });

  @override
  Future<domain.Sample> updatePulseAcquisition({
    required String id,
    required domain.PulseAcquisitionConfiguration configuration,
    required domain.AcquisitionIntegrity integrity,
  }) => database.transaction(() async {
    final current = await _requiredSample(database, id);
    if (current.status != domain.SampleStatus.running) {
      throw StateError('Only a RUNNING sample can update acquisition.');
    }
    await (database.update(
      database.samples,
    )..where((t) => t.id.equals(id))).write(
      db.SamplesCompanion(
        bleDeviceId: Value(configuration.bleDeviceId),
        bleDeviceName: Value(configuration.bleDeviceName),
        bleServiceUuid: Value(configuration.bleServiceUuid),
        bleCounterCharacteristicUuid: Value(
          configuration.bleCounterCharacteristicUuid,
        ),
        bleProtocolVersion: Value(configuration.bleProtocolVersion),
        esp32CounterAtStart: Value(configuration.esp32CounterAtStart),
        lastObservedEsp32Counter: Value(configuration.lastObservedEsp32Counter),
        ledRoiLeft: Value(configuration.ledRoiLeft),
        ledRoiTop: Value(configuration.ledRoiTop),
        ledRoiWidth: Value(configuration.ledRoiWidth),
        ledRoiHeight: Value(configuration.ledRoiHeight),
        ledRisingDelta: Value(configuration.ledRisingDelta),
        ledFallingDelta: Value(configuration.ledFallingDelta),
        ledMinPulseIntervalMs: Value(configuration.ledMinPulseIntervalMs),
        ledBaseline: Value(configuration.ledBaseline),
        ledUsesBleReconciliation: Value(configuration.ledUsesBleReconciliation),
        acquisitionIntegrityStatus: Value(integrity.status.name),
        acquisitionIntegrityReason: Value(integrity.reason),
        acquisitionIntegrityAtMs: Value(
          integrity.occurredAt?.millisecondsSinceEpoch,
        ),
        acquisitionIntegritySource: Value(integrity.source?.name),
        updatedAtMs: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
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
  Future<List<domain.Sample>> listByFlow(String flowPointId) async {
    final rows =
        await (database.select(database.samples)
              ..where((t) => t.flowPointId.equals(flowPointId))
              ..orderBy([(t) => OrderingTerm.asc(t.sampleNumber)]))
            .get();
    return Future.wait(rows.map((row) => mapSampleWithSettings(database, row)));
  }

  @override
  Future<List<domain.Sample>> listIncomplete() async {
    final rows =
        await (database.select(database.samples)
              ..where(
                (t) => t.status.isIn([
                  domain.SampleStatus.draft.name,
                  domain.SampleStatus.running.name,
                  domain.SampleStatus.invalidEvidence.name,
                ]),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAtMs)]))
            .get();
    return Future.wait(rows.map((row) => mapSampleWithSettings(database, row)));
  }

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
    return row == null ? null : mapSampleWithSettings(database, row);
  }

  @override
  Future<void> deleteOpen(String id) => database.transaction(() async {
    final sample = await _requiredSample(database, id);
    if (sample.status == domain.SampleStatus.closedValid) {
      throw StateError('A closed sample is immutable.');
    }
    await (database.delete(
      database.evidenceItems,
    )..where((table) => table.sampleId.equals(id))).go();
    await (database.delete(
      database.testPoints,
    )..where((table) => table.sampleId.equals(id))).go();
    await database.customStatement(
      'DELETE FROM sample_operational_settings WHERE sample_id = ?',
      [id],
    );
    await (database.delete(
      database.samples,
    )..where((table) => table.id.equals(id))).go();
  });
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
    cameraZoomLevel: Value(config.cameraZoomLevel),
    createdAtMs: _ms(sample.createdAt),
    updatedAtMs: _ms(sample.updatedAt),
    pulseCount: Value(sample.pulseCount),
    progressReferenceLiters: Value(sample.referenceLitersProgress),
    bleDeviceId: Value(sample.pulseAcquisitionConfiguration?.bleDeviceId),
    bleDeviceName: Value(sample.pulseAcquisitionConfiguration?.bleDeviceName),
    bleServiceUuid: Value(sample.pulseAcquisitionConfiguration?.bleServiceUuid),
    bleCounterCharacteristicUuid: Value(
      sample.pulseAcquisitionConfiguration?.bleCounterCharacteristicUuid,
    ),
    bleProtocolVersion: Value(
      sample.pulseAcquisitionConfiguration?.bleProtocolVersion,
    ),
    esp32CounterAtStart: Value(
      sample.pulseAcquisitionConfiguration?.esp32CounterAtStart,
    ),
    lastObservedEsp32Counter: Value(
      sample.pulseAcquisitionConfiguration?.lastObservedEsp32Counter,
    ),
    acquisitionIntegrityStatus: Value(sample.acquisitionIntegrity.status.name),
    acquisitionIntegrityReason: Value(sample.acquisitionIntegrity.reason),
    acquisitionIntegrityAtMs: Value(
      sample.acquisitionIntegrity.occurredAt?.millisecondsSinceEpoch,
    ),
    acquisitionIntegritySource: Value(sample.acquisitionIntegrity.source?.name),
  );
}

domain.Sample mapSample(
  db.SampleRow row, {
  double? minimumVolumeLiters,
  double? maximumVolumeLiters,
  double? controlStartMinimumLps,
  double? controlStartMaximumLps,
  double? hydrantLitersPerPulse,
}) {
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
    minimumVolumeLiters: minimumVolumeLiters,
    maximumVolumeLiters: maximumVolumeLiters,
    controlStartMinimumLps: controlStartMinimumLps ?? 0,
    controlStartMaximumLps: controlStartMaximumLps ?? double.infinity,
    hydrantLitersPerPulse: hydrantLitersPerPulse ?? 1,
    cameraZoomLevel: row.cameraZoomLevel ?? 1,
  );
  domain.ConfirmedReading? reading(
    double? odometer,
    double? needle,
    String? source,
    String? evidenceId,
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
          evidenceId: evidenceId,
        );
  final hasResult = row.referenceLiters != null;
  final meterFace = row.totalizerLeft == null
      ? null
      : domain.MeterFaceConfiguration(
          totalizerLeft: row.totalizerLeft!,
          totalizerTop: row.totalizerTop!,
          totalizerWidth: row.totalizerWidth!,
          totalizerHeight: row.totalizerHeight!,
          dialCenterX: row.dialCenterX!,
          dialCenterY: row.dialCenterY!,
          dialRadius: row.dialRadius!,
          multiplier: row.dialMultiplier!,
          litersPerRevolution: row.dialLitersPerRevolution!,
          zeroAngleDegrees: row.dialZeroAngleDegrees!,
          clockwise: row.dialClockwise!,
          source: domain.DialConfigurationSource.values.byName(
            row.dialConfigurationSource!,
          ),
          totalizerConfiguration: row.totalizerDigitCount == null
              ? null
              : domain.TotalizerConfiguration(
                  digitCount: row.totalizerDigitCount!,
                  decimalPlaces: row.totalizerDecimalPlaces!,
                  unit: domain.TotalizerUnit.values.byName(row.totalizerUnit!),
                  leadingZerosAllowed: row.totalizerLeadingZerosAllowed!,
                  source: domain.DialConfigurationSource.values.byName(
                    row.totalizerConfigurationSource!,
                  ),
                ),
        );
  final acquisitionConfiguration =
      row.bleDeviceId == null && row.ledRoiLeft == null
      ? null
      : domain.PulseAcquisitionConfiguration(
          bleDeviceId: row.bleDeviceId,
          bleDeviceName: row.bleDeviceName,
          bleServiceUuid: row.bleServiceUuid,
          bleCounterCharacteristicUuid: row.bleCounterCharacteristicUuid,
          bleProtocolVersion: row.bleProtocolVersion,
          esp32CounterAtStart: row.esp32CounterAtStart,
          lastObservedEsp32Counter: row.lastObservedEsp32Counter,
          ledRoiLeft: row.ledRoiLeft,
          ledRoiTop: row.ledRoiTop,
          ledRoiWidth: row.ledRoiWidth,
          ledRoiHeight: row.ledRoiHeight,
          ledRisingDelta: row.ledRisingDelta,
          ledFallingDelta: row.ledFallingDelta,
          ledMinPulseIntervalMs: row.ledMinPulseIntervalMs,
          ledBaseline: row.ledBaseline,
          ledUsesBleReconciliation: row.ledUsesBleReconciliation ?? false,
        );
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
    manualIndicatedLiters: row.indicatedLiters,
    initialReading: reading(
      row.initialOdometerUnits,
      row.initialNeedleLiters,
      row.initialReadingSource,
      row.initialReadingEvidenceId,
    ),
    finalReading: reading(
      row.finalOdometerUnits,
      row.finalNeedleLiters,
      row.finalReadingSource,
      row.finalReadingEvidenceId,
    ),
    meterFaceConfiguration: meterFace,
    pulseAcquisitionConfiguration: acquisitionConfiguration,
    acquisitionIntegrity: domain.AcquisitionIntegrity(
      status: row.acquisitionIntegrityStatus == null
          ? domain.AcquisitionIntegrityStatus.ok
          : domain.AcquisitionIntegrityStatus.values.byName(
              row.acquisitionIntegrityStatus!,
            ),
      reason: row.acquisitionIntegrityReason,
      occurredAt: row.acquisitionIntegrityAtMs == null
          ? null
          : _date(row.acquisitionIntegrityAtMs!),
      source: row.acquisitionIntegritySource == null
          ? null
          : metrology.MeasurementMethod.values.byName(
              row.acquisitionIntegritySource!,
            ),
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
  return mapSampleWithSettings(database, row);
}

Future<domain.Sample> mapSampleWithSettings(
  db.AppDatabase database,
  db.SampleRow row,
) async {
  final setting = await database
      .customSelect(
        'SELECT minimum_volume_liters, maximum_volume_liters, control_start_minimum_lps, control_start_maximum_lps, hydrant_liters_per_pulse '
        'FROM sample_operational_settings WHERE sample_id = ?',
        variables: [Variable<String>(row.id)],
      )
      .getSingleOrNull();
  return mapSample(
    row,
    minimumVolumeLiters: setting?.read<double>('minimum_volume_liters'),
    maximumVolumeLiters: setting?.read<double>('maximum_volume_liters'),
    controlStartMinimumLps: setting?.read<double>('control_start_minimum_lps'),
    controlStartMaximumLps: setting?.read<double>('control_start_maximum_lps'),
    hydrantLitersPerPulse: setting?.read<double>('hydrant_liters_per_pulse'),
  );
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
            meterUnderTestPulseCount: Value(point.meterUnderTestPulseCount),
            flowLps: Value(point.flowLps),
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
              meterUnderTestPulseCount: row.meterUnderTestPulseCount,
              flowLps: row.flowLps,
              capturedAt: _date(row.capturedAtMs),
            ),
          )
          .toList(growable: false);

  @override
  Future<void> deleteByTypeFromOpenSample(
    String sampleId,
    domain.PointType type,
  ) async {
    final sample = await _requiredSample(database, sampleId);
    if (sample.status == domain.SampleStatus.closedValid) {
      throw StateError('Closed sample points are immutable.');
    }
    await (database.delete(database.testPoints)..where(
          (table) =>
              table.sampleId.equals(sampleId) & table.type.equals(type.name),
        ))
        .go();
  }
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

  @override
  Future<void> deleteFromOpenSample(String evidenceId) async {
    final item = await getById(evidenceId);
    if (item == null) return;
    final sample = await _requiredSample(database, item.sampleId);
    if (sample.status == domain.SampleStatus.closedValid) {
      throw StateError('Closed sample evidence is immutable.');
    }
    await (database.delete(
      database.evidenceItems,
    )..where((table) => table.id.equals(evidenceId))).go();
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
