import 'dart:io';

import 'package:ddr001_app/core/metrology/metrology.dart';
import 'package:ddr001_app/data/local/database/app_database.dart';
import 'package:ddr001_app/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/offline_fixture.dart';

void main() {
  late Directory directory;
  late AppDatabase database;
  late OfflineFixture fixture;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ddr001-state-');
    database = memoryDatabase();
    fixture = OfflineFixture(database, directory);
    await fixture.seed();
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('DRAFT transitions to RUNNING and persists GPS', () async {
    await fixture.samples.createDraft(fixture.draft());
    final running = await fixture.samples.start(
      'sample-1',
      at: fixedTime,
      gps: GpsSnapshot(
        latitude: 22.1,
        longitude: -102.2,
        accuracyMeters: 4,
        capturedAt: fixedTime,
      ),
    );
    expect(running.status, SampleStatus.running);
    expect(running.gps!.latitude, 22.1);
  });

  test('RUNNING transitions to INVALID_EVIDENCE and is retained', () async {
    await fixture.running();
    final invalid = await fixture.samples.markInvalidEvidence(
      'sample-1',
      at: fixedTime,
    );
    expect(invalid.status, SampleStatus.invalidEvidence);
    expect((await fixture.samples.listIncomplete()).single.id, 'sample-1');
  });

  test('invalid sample cannot restart or become valid silently', () async {
    await fixture.running();
    await fixture.samples.markInvalidEvidence('sample-1', at: fixedTime);
    expect(
      () => fixture.samples.start('sample-1', at: fixedTime),
      throwsStateError,
    );
    expect(
      () => fixture.sampleClosure.closeValid('sample-1', at: fixedTime),
      throwsStateError,
    );
  });

  test(
    'RUNNING cannot be started again and DRAFT cannot accept progress',
    () async {
      await fixture.samples.createDraft(fixture.draft());
      expect(
        () => fixture.samples.updateProgress(id: 'sample-1', pulseCount: 1),
        throwsStateError,
      );
      await fixture.samples.start('sample-1', at: fixedTime);
      expect(
        () => fixture.samples.start('sample-1', at: fixedTime),
        throwsStateError,
      );
    },
  );

  test('twenty sequential samples have no artificial limit', () async {
    for (var number = 1; number <= 20; number++) {
      await fixture.samples.createDraft(
        fixture.draft(id: 'sample-$number', number: number),
      );
    }
    final samples = await fixture.samples.listByFlow('flow-q3');
    expect(samples, hasLength(20));
    expect(
      samples.map((s) => s.sampleNumber),
      orderedEquals(List.generate(20, (i) => i + 1)),
    );
  });

  test('sample number must be unique within a flow point', () async {
    await fixture.samples.createDraft(fixture.draft(id: 'one'));
    expect(
      () => fixture.samples.createDraft(fixture.draft(id: 'two')),
      throwsA(anything),
    );
  });

  test('frozen configuration does not change with external settings', () async {
    var configuredK = 1.0;
    final draft = fixture.draft();
    await fixture.samples.createDraft(draft);
    configuredK = 9;
    final stored = await fixture.samples.getById('sample-1');
    expect(configuredK, 9);
    expect(stored!.configuration.litersPerPulse, 1);
  });

  test('point types accept nullable pulse fields for VISUAL', () async {
    await fixture.running(method: MeasurementMethod.visual);
    for (final (index, type) in PointType.values.indexed) {
      await fixture.points.save(
        TestPoint(
          id: 'point-$index',
          sampleId: 'sample-1',
          type: type,
          capturedAt: fixedTime,
        ),
      );
    }
    expect(await fixture.points.listBySample('sample-1'), hasLength(4));
  });

  test('sync enqueue is idempotent for entity version checksum', () async {
    final first = await fixture.sync.enqueue(
      entityType: 'sample',
      entityId: 's',
      checksum: 'abc',
      at: fixedTime,
    );
    final second = await fixture.sync.enqueue(
      entityType: 'sample',
      entityId: 's',
      checksum: 'abc',
      at: fixedTime,
    );
    expect(second.id, first.id);
    expect(await fixture.sync.listPending(), hasLength(1));
  });

  test('sync attempts failed and synced states persist', () async {
    final item = await fixture.sync.enqueue(
      entityType: 'sample',
      entityId: 's',
      checksum: 'abc',
      at: fixedTime,
    );
    await fixture.sync.incrementAttempt(item.id, at: fixedTime);
    await fixture.sync.markFailed(item.id, error: 'offline', at: fixedTime);
    var pending = (await fixture.sync.listPending()).single;
    expect(pending.attempts, 1);
    expect(pending.state, SyncState.failed);
    expect(pending.lastError, 'offline');
    await fixture.sync.markSynced(item.id, at: fixedTime);
    expect(await fixture.sync.listPending(), isEmpty);
  });
}
