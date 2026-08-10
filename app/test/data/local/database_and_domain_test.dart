import 'dart:io';

import 'package:ddr001_app/core/metrology/metrology.dart';
import 'package:ddr001_app/data/local/database/app_database.dart'
    hide Meter, User;
import 'package:ddr001_app/domain/models.dart';
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

  test('schema version 1 creates all eight domain tables', () async {
    expect(database.schemaVersion, 1);
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
      }),
    );
  });

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
}
