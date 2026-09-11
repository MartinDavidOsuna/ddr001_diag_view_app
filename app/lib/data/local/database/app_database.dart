import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().unique()();
  TextColumn get phone => text()();
  TextColumn get displayName => text().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get lastLoginAtMs => integer().nullable()();
  TextColumn get remoteUserId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Meters extends Table {
  TextColumn get id => text()();
  TextColumn get externalStatus => text()();
  TextColumn get externalSnapshotJson => text().nullable()();
  IntColumn get externalCheckedAtMs => integer().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (external_status IN ('foundWithSurvey','foundNoSurvey','notFound','unknownOffline'))",
  ];
}

@DataClassName('VerificationCaseRow')
class VerificationCases extends Table {
  TextColumn get id => text()();
  TextColumn get meterId => text().references(Meters, #id)();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get status => text()();
  TextColumn get overallVerdict => text().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get closedAtMs => integer().nullable()();
  IntColumn get reportVersion => integer().withDefault(const Constant(1))();
  TextColumn get testBenchId => text().withDefault(const Constant(''))();
  TextColumn get deviceId => text().nullable()();
  TextColumn get androidVersion => text().nullable()();
  TextColumn get deviceBrand => text().nullable()();
  TextColumn get deviceModel => text().nullable()();
  TextColumn get checksum => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (status IN ('open','closed'))",
    "CHECK (overall_verdict IS NULL OR overall_verdict IN ('approved','rejected','inconclusive'))",
  ];
}

@DataClassName('FlowPointRow')
class FlowPoints extends Table {
  TextColumn get id => text()();
  TextColumn get caseId => text().references(VerificationCases, #id)();
  TextColumn get code => text()();
  RealColumn get lpsApprox => real().nullable()();
  RealColumn get mpePct => real()();
  TextColumn get status => text().withDefault(const Constant('open'))();
  IntColumn get statisticsN => integer().nullable()();
  RealColumn get meanErrorPct => real().nullable()();
  RealColumn get minimumErrorPct => real().nullable()();
  RealColumn get maximumErrorPct => real().nullable()();
  RealColumn get dispersionPct => real().nullable()();
  RealColumn get sampleStdDevPct => real().nullable()();
  TextColumn get repeatabilityStatus => text().nullable()();
  IntColumn get createdAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {caseId, code},
  ];

  @override
  List<String> get customConstraints => [
    "CHECK (code IN ('q1','q2','q3','q4'))",
    "CHECK (mpe_pct > 0)",
    "CHECK (status IN ('open','pass','fail','inconclusive'))",
  ];
}

@DataClassName('SampleRow')
class Samples extends Table {
  TextColumn get id => text()();
  TextColumn get flowPointId => text().references(FlowPoints, #id)();
  IntColumn get sampleNumber => integer()();
  TextColumn get status => text()();
  TextColumn get measurementMethod => text()();
  TextColumn get simulationScenario => text().nullable()();
  RealColumn get litersPerPulse => real()();
  RealColumn get evidenceStepLiters => real()();
  RealColumn get readingUncertaintyLiters => real()();
  TextColumn get flowPointCode => text()();
  RealColumn get mpePct => real()();
  RealColumn get lpsApprox => real().nullable()();
  RealColumn get litersPerOdometerUnit => real()();
  RealColumn get needleLitersPerRevolution => real()();
  RealColumn get cameraZoomLevel => real().nullable()();
  RealColumn get totalizerLeft => real().nullable()();
  RealColumn get totalizerTop => real().nullable()();
  RealColumn get totalizerWidth => real().nullable()();
  RealColumn get totalizerHeight => real().nullable()();
  RealColumn get dialCenterX => real().nullable()();
  RealColumn get dialCenterY => real().nullable()();
  RealColumn get dialRadius => real().nullable()();
  RealColumn get dialMultiplier => real().nullable()();
  RealColumn get dialLitersPerRevolution => real().nullable()();
  RealColumn get dialZeroAngleDegrees => real().nullable()();
  BoolColumn get dialClockwise => boolean().nullable()();
  TextColumn get dialConfigurationSource => text().nullable()();
  IntColumn get totalizerDigitCount => integer().nullable()();
  IntColumn get totalizerDecimalPlaces => integer().nullable()();
  TextColumn get totalizerUnit => text().nullable()();
  BoolColumn get totalizerLeadingZerosAllowed => boolean().nullable()();
  TextColumn get totalizerConfigurationSource => text().nullable()();
  TextColumn get bleDeviceId => text().nullable()();
  TextColumn get bleDeviceName => text().nullable()();
  TextColumn get bleServiceUuid => text().nullable()();
  TextColumn get bleCounterCharacteristicUuid => text().nullable()();
  IntColumn get bleProtocolVersion => integer().nullable()();
  IntColumn get esp32CounterAtStart => integer().nullable()();
  IntColumn get lastObservedEsp32Counter => integer().nullable()();
  RealColumn get ledRoiLeft => real().nullable()();
  RealColumn get ledRoiTop => real().nullable()();
  RealColumn get ledRoiWidth => real().nullable()();
  RealColumn get ledRoiHeight => real().nullable()();
  RealColumn get ledRisingDelta => real().nullable()();
  RealColumn get ledFallingDelta => real().nullable()();
  IntColumn get ledMinPulseIntervalMs => integer().nullable()();
  RealColumn get ledBaseline => real().nullable()();
  BoolColumn get ledUsesBleReconciliation => boolean().nullable()();
  TextColumn get acquisitionIntegrityStatus => text().nullable()();
  TextColumn get acquisitionIntegrityReason => text().nullable()();
  IntColumn get acquisitionIntegrityAtMs => integer().nullable()();
  TextColumn get acquisitionIntegritySource => text().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get startedAtMs => integer().nullable()();
  IntColumn get endedAtMs => integer().nullable()();
  RealColumn get gpsLatitude => real().nullable()();
  RealColumn get gpsLongitude => real().nullable()();
  RealColumn get gpsAccuracyMeters => real().nullable()();
  IntColumn get gpsCapturedAtMs => integer().nullable()();
  IntColumn get pulseCount => integer().withDefault(const Constant(0))();
  RealColumn get progressReferenceLiters => real().nullable()();
  RealColumn get initialOdometerUnits => real().nullable()();
  RealColumn get initialNeedleLiters => real().nullable()();
  TextColumn get initialReadingSource => text().nullable()();
  @ReferenceName('initialReadingEvidence')
  TextColumn get initialReadingEvidenceId =>
      text().nullable().references(EvidenceItems, #id)();
  RealColumn get finalOdometerUnits => real().nullable()();
  RealColumn get finalNeedleLiters => real().nullable()();
  TextColumn get finalReadingSource => text().nullable()();
  @ReferenceName('finalReadingEvidence')
  TextColumn get finalReadingEvidenceId =>
      text().nullable().references(EvidenceItems, #id)();
  RealColumn get referenceLiters => real().nullable()();
  RealColumn get indicatedLiters => real().nullable()();
  RealColumn get errorPct => real().nullable()();
  RealColumn get uncertaintyPct => real().nullable()();
  RealColumn get resultMpePct => real().nullable()();
  RealColumn get acceptanceMetricPct => real().nullable()();
  RealColumn get rejectionMetricPct => real().nullable()();
  TextColumn get verdict => text().nullable()();
  TextColumn get checksum => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {flowPointId, sampleNumber},
  ];

  @override
  List<String> get customConstraints => [
    "CHECK (sample_number >= 1)",
    "CHECK (status IN ('draft','running','invalidEvidence','closedValid'))",
    "CHECK (measurement_method IN ('visual','manual','led','ble','simulation'))",
    "CHECK ((measurement_method = 'simulation' AND simulation_scenario IN ('successful','failed','failThenPass','operatorControlled')) OR (measurement_method != 'simulation' AND simulation_scenario IS NULL))",
    'CHECK (liters_per_pulse > 0)',
    'CHECK (evidence_step_liters > 0)',
    'CHECK (reading_uncertainty_liters >= 0)',
    "CHECK (flow_point_code IN ('q1','q2','q3','q4'))",
    'CHECK (mpe_pct > 0)',
    'CHECK (liters_per_odometer_unit > 0)',
    'CHECK (needle_liters_per_revolution > 0)',
    'CHECK (pulse_count >= 0)',
  ];
}

@DataClassName('PointRow')
class TestPoints extends Table {
  TextColumn get id => text()();
  TextColumn get sampleId => text().references(Samples, #id)();
  TextColumn get type => text()();
  IntColumn get pulseCount => integer().nullable()();
  RealColumn get referenceLiters => real().nullable()();
  RealColumn get readingLiters => real().nullable()();
  RealColumn get indicatedLiters => real().nullable()();
  RealColumn get diagnosticErrorPct => real().nullable()();
  RealColumn get needleLiters => real().nullable()();
  IntColumn get meterUnderTestPulseCount => integer().nullable()();
  RealColumn get flowLps => real().nullable()();
  IntColumn get capturedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (type IN ('start','intermediate','finalPoint','manualDiagnostic'))",
    'CHECK (pulse_count IS NULL OR pulse_count >= 0)',
  ];
}

@DataClassName('EvidenceRow')
class EvidenceItems extends Table {
  TextColumn get id => text()();
  TextColumn get sampleId => text().references(Samples, #id)();
  TextColumn get pointId => text().nullable().references(TestPoints, #id)();
  TextColumn get type => text()();
  BoolColumn get required => boolean()();
  RealColumn get volumeRefLiters => real().nullable()();
  IntColumn get pulseCount => integer().nullable()();
  IntColumn get capturedAtMs => integer()();
  TextColumn get sha256 => text().nullable()();
  TextColumn get localPath => text()();
  TextColumn get serverStorageKey => text().nullable()();
  TextColumn get syncStatus => text()();
  IntColumn get serverConfirmedAtMs => integer().nullable()();
  TextColumn get lastSyncError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (type IN ('start','intermediate','finalEvidence','extra'))",
    'CHECK (pulse_count IS NULL OR pulse_count >= 0)',
    "CHECK (sync_status IN ('local','pending','syncing','synced','conflict','error'))",
  ];
}

@DataClassName('SyncBatchRow')
class SyncBatches extends Table {
  TextColumn get id => text()();
  TextColumn get caseId => text().references(VerificationCases, #id)();
  TextColumn get requestJson => text()();
  TextColumn get requestSha256 => text()();
  TextColumn get state => text()();
  TextColumn get receiptId => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get nextRetryAtMs => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (state IN ('pending','sending','ambiguous','synced','conflict','failed'))",
    'CHECK (attempts >= 0)',
  ];
}

@DataClassName('SyncItemRow')
class SyncItems extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get checksum => text()();
  TextColumn get state => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get nextRetryAtMs => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {entityType, entityId, checksum},
  ];

  @override
  List<String> get customConstraints => [
    "CHECK (state IN ('pending','inProgress','failed','synced'))",
    'CHECK (attempts >= 0)',
  ];
}

@DriftDatabase(
  tables: [
    Users,
    Meters,
    VerificationCases,
    FlowPoints,
    Samples,
    TestPoints,
    EvidenceItems,
    SyncItems,
    SyncBatches,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults()
    : super(driftDatabase(name: 'ddr001', native: const DriftNativeOptions()));

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createProtectionTriggers();
      await _createIndexes();
      await _createOperationalSettingsTable();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 1) {
        await migrator.createAll();
        await _createProtectionTriggers();
        await _createIndexes();
      }
      if (from < 2) {
        final existingColumns = (await customSelect(
          'PRAGMA table_info(samples)',
        ).get()).map((row) => row.read<String>('name')).toSet();
        if (!existingColumns.contains('initial_reading_evidence_id')) {
          await migrator.addColumn(samples, samples.initialReadingEvidenceId);
        }
        if (!existingColumns.contains('final_reading_evidence_id')) {
          await migrator.addColumn(samples, samples.finalReadingEvidenceId);
        }
      }
      if (from < 3) {
        final visualColumns = <GeneratedColumn<Object>>[
          samples.totalizerLeft,
          samples.totalizerTop,
          samples.totalizerWidth,
          samples.totalizerHeight,
          samples.dialCenterX,
          samples.dialCenterY,
          samples.dialRadius,
          samples.dialMultiplier,
          samples.dialLitersPerRevolution,
          samples.dialZeroAngleDegrees,
          samples.dialClockwise,
          samples.dialConfigurationSource,
        ];
        final existingColumns = (await customSelect(
          'PRAGMA table_info(samples)',
        ).get()).map((row) => row.read<String>('name')).toSet();
        for (final column in visualColumns) {
          if (!existingColumns.contains(column.$name)) {
            await migrator.addColumn(samples, column);
          }
        }
      }
      if (from < 4) {
        final formatColumns = <GeneratedColumn<Object>>[
          samples.totalizerDigitCount,
          samples.totalizerDecimalPlaces,
          samples.totalizerUnit,
          samples.totalizerLeadingZerosAllowed,
          samples.totalizerConfigurationSource,
        ];
        final existingColumns = (await customSelect(
          'PRAGMA table_info(samples)',
        ).get()).map((row) => row.read<String>('name')).toSet();
        for (final column in formatColumns) {
          if (!existingColumns.contains(column.$name)) {
            await migrator.addColumn(samples, column);
          }
        }
      }
      if (from < 5) {
        final acquisitionColumns = <GeneratedColumn<Object>>[
          samples.bleDeviceId,
          samples.bleDeviceName,
          samples.bleServiceUuid,
          samples.bleCounterCharacteristicUuid,
          samples.bleProtocolVersion,
          samples.esp32CounterAtStart,
          samples.lastObservedEsp32Counter,
          samples.ledRoiLeft,
          samples.ledRoiTop,
          samples.ledRoiWidth,
          samples.ledRoiHeight,
          samples.ledRisingDelta,
          samples.ledFallingDelta,
          samples.ledMinPulseIntervalMs,
          samples.ledBaseline,
          samples.ledUsesBleReconciliation,
          samples.acquisitionIntegrityStatus,
          samples.acquisitionIntegrityReason,
          samples.acquisitionIntegrityAtMs,
          samples.acquisitionIntegritySource,
        ];
        final existingColumns = (await customSelect(
          'PRAGMA table_info(samples)',
        ).get()).map((row) => row.read<String>('name')).toSet();
        for (final column in acquisitionColumns) {
          if (!existingColumns.contains(column.$name)) {
            await migrator.addColumn(samples, column);
          }
        }
      }
      if (from < 6) {
        await _createOperationalSettingsTable();
      }
      if (from < 7) await _ensureOperationalSettingsColumns();
      if (from < 8) {
        final existingColumns = (await customSelect(
          'PRAGMA table_info(samples)',
        ).get()).map((row) => row.read<String>('name')).toSet();
        if (!existingColumns.contains('camera_zoom_level')) {
          await migrator.addColumn(samples, samples.cameraZoomLevel);
        }
      }
      if (from < 9) {
        final existingColumns = (await customSelect(
          'PRAGMA table_info(test_points)',
        ).get()).map((row) => row.read<String>('name')).toSet();
        if (!existingColumns.contains('meter_under_test_pulse_count')) {
          await migrator.addColumn(
            testPoints,
            testPoints.meterUnderTestPulseCount,
          );
        }
      }
      if (from < 10) {
        final existingColumns = (await customSelect(
          'PRAGMA table_info(test_points)',
        ).get()).map((row) => row.read<String>('name')).toSet();
        if (!existingColumns.contains('flow_lps')) {
          await migrator.addColumn(testPoints, testPoints.flowLps);
        }
      }
      if (from < 11) {
        final existingColumns = (await customSelect(
          'PRAGMA table_info(verification_cases)',
        ).get()).map((row) => row.read<String>('name')).toSet();
        final columns = <GeneratedColumn<Object>>[
          verificationCases.testBenchId,
          verificationCases.deviceId,
          verificationCases.androidVersion,
          verificationCases.deviceBrand,
          verificationCases.deviceModel,
        ];
        for (final column in columns) {
          if (!existingColumns.contains(column.$name)) {
            await migrator.addColumn(verificationCases, column);
          }
        }
      }
      if (from < 12) {
        await migrator.alterTable(
          TableMigration(
            samples,
            columnTransformer: {
              samples.simulationScenario: const CustomExpression<String>(
                'NULL',
              ),
            },
          ),
        );
      }
      if (from < 13) {
        final userColumns = (await customSelect(
          'PRAGMA table_info(users)',
        ).get()).map((row) => row.read<String>('name')).toSet();
        if (!userColumns.contains('remote_user_id')) {
          await migrator.addColumn(users, users.remoteUserId);
        }
        final evidenceColumns = (await customSelect(
          'PRAGMA table_info(evidence_items)',
        ).get()).map((row) => row.read<String>('name')).toSet();
        if (!evidenceColumns.contains('server_confirmed_at_ms')) {
          await migrator.addColumn(
            evidenceItems,
            evidenceItems.serverConfirmedAtMs,
          );
        }
        if (!evidenceColumns.contains('last_sync_error')) {
          await migrator.addColumn(evidenceItems, evidenceItems.lastSyncError);
        }
        await migrator.createTable(syncBatches);
        await customStatement(
          'DROP TRIGGER IF EXISTS protect_closed_sample_evidence_update',
        );
        await _createEvidenceUpdateProtectionTrigger();
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sync_batches_case_state ON sync_batches(case_id, state, created_at_ms)',
        );
      }
      if (from < 14) {
        await migrator.alterTable(
          TableMigration(
            samples,
            columnTransformer: {
              samples.simulationScenario: const CustomExpression<String>(
                'simulation_scenario',
              ),
            },
          ),
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _createOperationalSettingsTable();
      await _ensureOperationalSettingsColumns();
    },
  );

  Future<void> _createOperationalSettingsTable() => customStatement('''
    CREATE TABLE IF NOT EXISTS sample_operational_settings (
      sample_id TEXT PRIMARY KEY REFERENCES samples(id),
      minimum_volume_liters REAL NOT NULL,
      maximum_volume_liters REAL NOT NULL,
      control_start_minimum_lps REAL NOT NULL DEFAULT 0,
      control_start_maximum_lps REAL NOT NULL DEFAULT 1.0e308,
      hydrant_liters_per_pulse REAL NOT NULL DEFAULT 1,
      CHECK (minimum_volume_liters > 0),
      CHECK (maximum_volume_liters >= minimum_volume_liters)
    )
  ''');

  Future<void> _ensureOperationalSettingsColumns() async {
    final columns = (await customSelect(
      'PRAGMA table_info(sample_operational_settings)',
    ).get()).map((row) => row.read<String>('name')).toSet();
    for (final entry in <String, String>{
      'control_start_minimum_lps': 'REAL NOT NULL DEFAULT 0',
      'control_start_maximum_lps': 'REAL NOT NULL DEFAULT 1.0e308',
      'hydrant_liters_per_pulse': 'REAL NOT NULL DEFAULT 1',
    }.entries) {
      if (!columns.contains(entry.key)) {
        await customStatement(
          'ALTER TABLE sample_operational_settings ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
  }

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX idx_cases_meter_status ON verification_cases(meter_id, status)',
    );
    await customStatement(
      'CREATE INDEX idx_samples_flow_status ON samples(flow_point_id, status)',
    );
    await customStatement(
      'CREATE INDEX idx_evidence_sample ON evidence_items(sample_id)',
    );
    await customStatement(
      'CREATE INDEX idx_sync_state_created ON sync_items(state, created_at_ms)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_batches_case_state ON sync_batches(case_id, state, created_at_ms)',
    );
  }

  Future<void> _createProtectionTriggers() async {
    await customStatement('''
      CREATE TRIGGER protect_closed_sample_update
      BEFORE UPDATE ON samples
      WHEN OLD.status = 'closedValid'
      BEGIN SELECT RAISE(ABORT, 'closed sample is immutable'); END
    ''');
    await customStatement('''
      CREATE TRIGGER protect_closed_sample_delete
      BEFORE DELETE ON samples
      WHEN OLD.status = 'closedValid'
      BEGIN SELECT RAISE(ABORT, 'closed sample cannot be deleted'); END
    ''');
    await customStatement('''
      CREATE TRIGGER protect_closed_sample_evidence_insert
      BEFORE INSERT ON evidence_items
      WHEN (SELECT status FROM samples WHERE id = NEW.sample_id) = 'closedValid'
      BEGIN SELECT RAISE(ABORT, 'closed sample evidence is immutable'); END
    ''');
    await _createEvidenceUpdateProtectionTrigger();
    await customStatement('''
      CREATE TRIGGER protect_closed_sample_evidence_delete
      BEFORE DELETE ON evidence_items
      WHEN (SELECT status FROM samples WHERE id = OLD.sample_id) = 'closedValid'
      BEGIN SELECT RAISE(ABORT, 'closed sample evidence is immutable'); END
    ''');
    await customStatement('''
      CREATE TRIGGER protect_closed_sample_point_insert
      BEFORE INSERT ON test_points
      WHEN (SELECT status FROM samples WHERE id = NEW.sample_id) = 'closedValid'
      BEGIN SELECT RAISE(ABORT, 'closed sample points are immutable'); END
    ''');
    await customStatement('''
      CREATE TRIGGER protect_closed_sample_point_update
      BEFORE UPDATE ON test_points
      WHEN (SELECT status FROM samples WHERE id = OLD.sample_id) = 'closedValid'
      BEGIN SELECT RAISE(ABORT, 'closed sample points are immutable'); END
    ''');
    await customStatement('''
      CREATE TRIGGER protect_closed_sample_point_delete
      BEFORE DELETE ON test_points
      WHEN (SELECT status FROM samples WHERE id = OLD.sample_id) = 'closedValid'
      BEGIN SELECT RAISE(ABORT, 'closed sample points are immutable'); END
    ''');
    await customStatement('''
      CREATE TRIGGER protect_closed_case_update
      BEFORE UPDATE ON verification_cases
      WHEN OLD.status = 'closed'
      BEGIN SELECT RAISE(ABORT, 'closed case is immutable'); END
    ''');
    await customStatement('''
      CREATE TRIGGER protect_closed_case_delete
      BEFORE DELETE ON verification_cases
      WHEN OLD.status = 'closed'
      BEGIN SELECT RAISE(ABORT, 'closed case cannot be deleted'); END
    ''');
    await customStatement('''
      CREATE TRIGGER reject_flow_for_closed_case
      BEFORE INSERT ON flow_points
      WHEN (SELECT status FROM verification_cases WHERE id = NEW.case_id) = 'closed'
      BEGIN SELECT RAISE(ABORT, 'closed case cannot accept flow points'); END
    ''');
    await customStatement('''
      CREATE TRIGGER reject_sample_for_closed_case
      BEFORE INSERT ON samples
      WHEN (SELECT c.status FROM verification_cases c JOIN flow_points f ON f.case_id = c.id WHERE f.id = NEW.flow_point_id) = 'closed'
      BEGIN SELECT RAISE(ABORT, 'closed case cannot accept samples'); END
    ''');
  }

  Future<void> _createEvidenceUpdateProtectionTrigger() => customStatement('''
    CREATE TRIGGER protect_closed_sample_evidence_update
    BEFORE UPDATE ON evidence_items
    WHEN (SELECT status FROM samples WHERE id = OLD.sample_id) = 'closedValid'
      AND (
        OLD.id IS NOT NEW.id OR OLD.sample_id IS NOT NEW.sample_id OR
        OLD.point_id IS NOT NEW.point_id OR OLD.type IS NOT NEW.type OR
        OLD.required IS NOT NEW.required OR
        OLD.volume_ref_liters IS NOT NEW.volume_ref_liters OR
        OLD.pulse_count IS NOT NEW.pulse_count OR
        OLD.captured_at_ms IS NOT NEW.captured_at_ms OR
        OLD.sha256 IS NOT NEW.sha256 OR OLD.local_path IS NOT NEW.local_path
      )
    BEGIN SELECT RAISE(ABORT, 'closed sample evidence is immutable'); END
  ''');
}
