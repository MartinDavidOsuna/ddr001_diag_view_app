import 'dart:io';

import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:ddr001_diag_view_app/data/local/database/app_database.dart'
    hide Meter, User;
import 'package:ddr001_diag_view_app/data/local/repositories/local_repositories.dart';
import 'package:ddr001_diag_view_app/domain/integrity_checksum.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/offline_fixture.dart';

void main() {
  late Directory directory;
  late AppDatabase database;
  late OfflineFixture fixture;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ddr001-domain-');
    database = memoryDatabase();
    fixture = OfflineFixture(database, directory);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test(
    'schema version 6 creates domain and operational settings tables',
    () async {
      expect(database.schemaVersion, 7);
      final rows = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      expect(
        rows.map((r) => r.read<String>('name')).toSet(),
        containsAll({
          'users',
          'meters',
          'verification_cases',
          'flow_points',
          'samples',
          'test_points',
          'evidence_items',
          'sync_items',
          'sample_operational_settings',
        }),
      );
      final sampleColumns = await database
          .customSelect('PRAGMA table_info(samples)')
          .get();
      expect(
        sampleColumns.map((row) => row.read<String>('name')),
        containsAll({
          'initial_reading_evidence_id',
          'final_reading_evidence_id',
          'totalizer_left',
          'dial_center_x',
          'dial_multiplier',
          'dial_configuration_source',
        }),
      );
    },
  );

  test('user normalizes email and phone and supports lookup', () async {
    final user = User(
      id: 'u',
      email: ' Tech@Example.COM ',
      phone: '+52 (449) 123-4567',
      createdAt: fixedTime,
    );
    await fixture.users.save(user);
    final found = await fixture.users.getByEmailAndPhone(
      'TECH@example.com',
      '+52 4491234567',
    );
    expect(found!.email, 'tech@example.com');
    expect(found.phone, '+524491234567');
  });

  test('user persistence has no password column', () async {
    final columns = await database
        .customSelect('PRAGMA table_info(users)')
        .get();
    expect(
      columns.map((r) => r.read<String>('name')),
      isNot(contains('password')),
    );
  });

  test(
    'all external meter states and a new not-found meter are accepted',
    () async {
      for (final (index, status) in ExternalMeterStatus.values.indexed) {
        await fixture.meters.save(
          Meter(id: 'm$index', externalStatus: status, createdAt: fixedTime),
        );
        expect(
          (await fixture.meters.getById('m$index'))!.externalStatus,
          status,
        );
      }
    },
  );

  test('foreign keys reject a case with missing parents', () async {
    expect(
      () => fixture.cases.create(
        VerificationCase(
          id: 'orphan',
          meterId: 'missing',
          userId: 'missing',
          status: VerificationCaseStatus.open,
          createdAt: fixedTime,
          reportVersion: 1,
        ),
      ),
      throwsA(anything),
    );
  });

  test('case is created OPEN and can be recovered', () async {
    await fixture.seed();
    final result = await fixture.cases.getById('case-1');
    expect(result!.status, VerificationCaseStatus.open);
    expect((await fixture.cases.listOpenCases()).single.id, 'case-1');
  });

  test('Q1 Q2 Q3 Q4 persist frozen MPE and duplicate code fails', () async {
    await fixture.seed(flowPoint: FlowPoint.q1);
    for (final point in [FlowPoint.q2, FlowPoint.q3, FlowPoint.q4]) {
      await fixture.flows.create(
        FlowPointRecord(
          id: 'flow-${point.name}',
          caseId: 'case-1',
          code: point,
          mpePct: const Class2WaterMpePolicy().mpePctFor(point),
          status: FlowRecordStatus.open,
          createdAt: fixedTime,
        ),
      );
    }
    final values = await fixture.flows.listByCase('case-1');
    expect(values.map((f) => f.mpePct), containsAll([5, 2, 2, 2]));
    expect(() => fixture.flows.create(values.first), throwsA(anything));
  });

  test('database file reopens with persisted content', () async {
    await database.close();
    final path = '${directory.path}${Platform.pathSeparator}offline.sqlite';
    var diskDb = AppDatabase(NativeDatabase(File(path)));
    var diskFixture = OfflineFixture(diskDb, directory);
    await diskFixture.seed();
    await diskDb.close();
    diskDb = AppDatabase(NativeDatabase(File(path)));
    diskFixture = OfflineFixture(diskDb, directory);
    expect((await diskFixture.cases.getById('case-1'))!.meterId, 'meter-1');
    await diskDb.close();
    database = memoryDatabase();
  });

  test(
    'v1 to v2 migration preserves Stage 3 data and adds traceability',
    () async {
      await database.close();
      final path = '${directory.path}${Platform.pathSeparator}migration.sqlite';
      var diskDb = AppDatabase(NativeDatabase(File(path)));
      final diskFixture = OfflineFixture(diskDb, directory);
      await diskFixture.seed();
      await diskDb.customStatement(
        'ALTER TABLE samples DROP COLUMN initial_reading_evidence_id',
      );
      await diskDb.customStatement(
        'ALTER TABLE samples DROP COLUMN final_reading_evidence_id',
      );
      await diskDb.customStatement('PRAGMA user_version = 1');
      await diskDb.close();

      diskDb = AppDatabase(NativeDatabase(File(path)));
      expect(
        (await LocalVerificationCaseRepository(
          diskDb,
        ).getById('case-1'))?.meterId,
        'meter-1',
      );
      final columns = await diskDb
          .customSelect('PRAGMA table_info(samples)')
          .get();
      expect(
        columns.map((row) => row.read<String>('name')),
        containsAll({
          'initial_reading_evidence_id',
          'final_reading_evidence_id',
        }),
      );
      await diskDb.close();
      database = memoryDatabase();
    },
  );

  test(
    'schema 4 persists and recovers frozen meter-face and totalizer format',
    () async {
      await fixture.seed();
      await fixture.running();
      final configured = await fixture.samples.updateMeterFaceConfiguration(
        'sample-1',
        const MeterFaceConfiguration(
          totalizerLeft: .2,
          totalizerTop: .1,
          totalizerWidth: .5,
          totalizerHeight: .2,
          dialCenterX: .5,
          dialCenterY: .65,
          dialRadius: .2,
          multiplier: .01,
          litersPerRevolution: 1,
          zeroAngleDegrees: -90,
          clockwise: true,
          source: DialConfigurationSource.manual,
          totalizerConfiguration: TotalizerConfiguration(
            digitCount: 3,
            decimalPlaces: 1,
            source: DialConfigurationSource.autoConfirmed,
          ),
        ),
      );
      expect(configured.meterFaceConfiguration!.multiplier, .01);
      expect(configured.configuration.needleLitersPerRevolution, 1);
      expect(
        configured
            .meterFaceConfiguration!
            .totalizerConfiguration!
            .decimalPlaces,
        1,
      );
      expect(
        (await fixture.samples.getById(
          'sample-1',
        ))!.meterFaceConfiguration!.dialRadius,
        .2,
      );
    },
  );

  test('sample checksum changes with totalizer format', () async {
    await fixture.seed();
    await fixture.running();
    Future<String> checksum(int decimals) async {
      final sample = await fixture.samples.updateMeterFaceConfiguration(
        'sample-1',
        MeterFaceConfiguration(
          totalizerLeft: .2,
          totalizerTop: .1,
          totalizerWidth: .5,
          totalizerHeight: .2,
          dialCenterX: .5,
          dialCenterY: .65,
          dialRadius: .2,
          multiplier: .1,
          litersPerRevolution: 10,
          zeroAngleDegrees: -90,
          clockwise: true,
          source: DialConfigurationSource.manual,
          totalizerConfiguration: TotalizerConfiguration(
            digitCount: 3,
            decimalPlaces: decimals,
          ),
        ),
      );
      return calculateSampleChecksum(
        sample: sample,
        referenceLiters: 10,
        indicatedLiters: 10,
        errorPct: 0,
        uncertaintyPct: 0,
        mpePct: 2,
        acceptanceMetricPct: 0,
        rejectionMetricPct: 0,
        verdict: 'pass',
        endedAt: DateTime.utc(2026, 8, 11),
        requiredEvidence: const [],
      );
    }

    expect(await checksum(1), isNot(await checksum(2)));
  });

  test('canonical v4 checksum includes frozen ESP32 counters', () async {
    await fixture.seed();
    await fixture.running(method: MeasurementMethod.ble);
    Future<String> checksum(int lastCounter) async {
      final sample = await fixture.samples.updatePulseAcquisition(
        id: 'sample-1',
        configuration: PulseAcquisitionConfiguration(
          bleDeviceId: 'device',
          bleProtocolVersion: 1,
          esp32CounterAtStart: 10,
          lastObservedEsp32Counter: lastCounter,
        ),
        integrity: const AcquisitionIntegrity(),
      );
      return calculateSampleChecksum(
        sample: sample,
        referenceLiters: 10,
        indicatedLiters: 10,
        errorPct: 0,
        uncertaintyPct: 0,
        mpePct: 2,
        acceptanceMetricPct: 0,
        rejectionMetricPct: 0,
        verdict: 'pass',
        endedAt: DateTime.utc(2026, 8, 11),
        requiredEvidence: const [],
      );
    }

    expect(await checksum(11), isNot(await checksum(12)));
  });

  test('v3 to v4 migration is additive and preserves Stage 4 rows', () async {
    await database.close();
    final path =
        '${directory.path}${Platform.pathSeparator}migration-v4.sqlite';
    var diskDb = AppDatabase(NativeDatabase(File(path)));
    final diskFixture = OfflineFixture(diskDb, directory);
    await diskFixture.seed();
    await diskFixture.running();
    for (final column in [
      'totalizer_digit_count',
      'totalizer_decimal_places',
      'totalizer_unit',
      'totalizer_leading_zeros_allowed',
      'totalizer_configuration_source',
    ]) {
      await diskDb.customStatement('ALTER TABLE samples DROP COLUMN $column');
    }
    await diskDb.customStatement('PRAGMA user_version = 3');
    await diskDb.close();
    diskDb = AppDatabase(NativeDatabase(File(path)));
    expect(
      (await LocalSampleRepository(diskDb).getById('sample-1'))?.id,
      'sample-1',
    );
    final columns = await diskDb
        .customSelect('PRAGMA table_info(samples)')
        .get();
    expect(
      columns.map((row) => row.read<String>('name')),
      contains('totalizer_decimal_places'),
    );
    await diskDb.close();
    database = memoryDatabase();
  });

  test(
    'v4 to v5 migration preserves rows and adds acquisition fields',
    () async {
      await database.close();
      final path =
          '${directory.path}${Platform.pathSeparator}migration-v5.sqlite';
      var diskDb = AppDatabase(NativeDatabase(File(path)));
      final diskFixture = OfflineFixture(diskDb, directory);
      await diskFixture.seed();
      await diskFixture.running();
      for (final column in [
        'ble_device_id',
        'ble_device_name',
        'ble_service_uuid',
        'ble_counter_characteristic_uuid',
        'ble_protocol_version',
        'esp32_counter_at_start',
        'last_observed_esp32_counter',
        'led_roi_left',
        'led_roi_top',
        'led_roi_width',
        'led_roi_height',
        'led_rising_delta',
        'led_falling_delta',
        'led_min_pulse_interval_ms',
        'led_baseline',
        'led_uses_ble_reconciliation',
        'acquisition_integrity_status',
        'acquisition_integrity_reason',
        'acquisition_integrity_at_ms',
        'acquisition_integrity_source',
      ]) {
        await diskDb.customStatement('ALTER TABLE samples DROP COLUMN $column');
      }
      await diskDb.customStatement('PRAGMA user_version = 4');
      await diskDb.close();
      diskDb = AppDatabase(NativeDatabase(File(path)));
      expect(
        (await LocalSampleRepository(diskDb).getById('sample-1'))?.id,
        'sample-1',
      );
      final names =
          (await diskDb.customSelect('PRAGMA table_info(samples)').get()).map(
            (row) => row.read<String>('name'),
          );
      expect(
        names,
        containsAll([
          'ble_device_id',
          'last_observed_esp32_counter',
          'acquisition_integrity_status',
        ]),
      );
      await diskDb.close();
      database = memoryDatabase();
    },
  );

  test('v2 to v3 migration is additive and preserves Stage 4 rows', () async {
    await database.close();
    final path =
        '${directory.path}${Platform.pathSeparator}migration-v3.sqlite';
    var diskDb = AppDatabase(NativeDatabase(File(path)));
    final diskFixture = OfflineFixture(diskDb, directory);
    await diskFixture.seed();
    await diskFixture.running();
    for (final column in [
      'totalizer_left',
      'totalizer_top',
      'totalizer_width',
      'totalizer_height',
      'dial_center_x',
      'dial_center_y',
      'dial_radius',
      'dial_multiplier',
      'dial_liters_per_revolution',
      'dial_zero_angle_degrees',
      'dial_clockwise',
      'dial_configuration_source',
    ]) {
      await diskDb.customStatement('ALTER TABLE samples DROP COLUMN $column');
    }
    await diskDb.customStatement('PRAGMA user_version = 2');
    await diskDb.close();
    diskDb = AppDatabase(NativeDatabase(File(path)));
    expect(
      (await LocalSampleRepository(diskDb).getById('sample-1'))?.id,
      'sample-1',
    );
    final columns = await diskDb
        .customSelect('PRAGMA table_info(samples)')
        .get();
    expect(
      columns.map((row) => row.read<String>('name')),
      containsAll([
        'totalizer_left',
        'dial_center_x',
        'dial_configuration_source',
      ]),
    );
    await diskDb.close();
    database = memoryDatabase();
  });
}
