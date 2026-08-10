import 'dart:io';

import 'package:ddr001_app/core/metrology/metrology.dart';
import 'package:ddr001_app/data/local/database/app_database.dart';
import 'package:ddr001_app/domain/models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/offline_fixture.dart';

void main() {
  late Directory directory;
  late AppDatabase database;
  late OfflineFixture fixture;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ddr001-close-');
    database = memoryDatabase();
    fixture = OfflineFixture(database, directory);
    await fixture.seed();
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('valid Q3 close persists result checksum and sync atomically', () async {
    await fixture.prepareClosable();
    final closed = await fixture.sampleClosure.closeValid(
      'sample-1',
      at: fixedTime.add(const Duration(minutes: 3)),
    );
    expect(closed.status, SampleStatus.closedValid);
    expect(closed.result!.mpePct, 2);
    expect(closed.result!.verdict, SampleVerdict.pass);
    expect(closed.checksum, hasLength(64));
    final sync = (await fixture.sync.listPending()).singleWhere(
      (item) => item.entityType == 'sample',
    );
    expect(sync.entityId, 'sample-1');
    expect(sync.checksum, closed.checksum);
  });

  test('Q1 closure uses frozen 5 percent MPE through Stage 1 engine', () async {
    await database.close();
    database = memoryDatabase();
    fixture = OfflineFixture(database, directory);
    await fixture.seed(flowPoint: FlowPoint.q1);
    await fixture.prepareClosable(
      flowId: 'flow-q1',
      flowPoint: FlowPoint.q1,
      finalNeedle: 8,
    );
    final closed = await fixture.sampleClosure.closeValid(
      'sample-1',
      at: fixedTime,
    );
    expect(closed.result!.mpePct, 5);
    expect(closed.result!.errorPct, closeTo(4, 1e-12));
    expect(closed.result!.verdict, SampleVerdict.pass);
  });

  test('VISUAL closes with explicit Vref and no fictitious pulses', () async {
    await fixture.prepareClosable(
      method: MeasurementMethod.visual,
      pulseCount: 0,
      visualReferenceLiters: 200,
    );
    final closed = await fixture.sampleClosure.closeValid(
      'sample-1',
      at: fixedTime,
    );
    expect(closed.pulseCount, 0);
    expect(closed.result!.referenceLiters, 200);
  });

  test(
    'step 25 final 125 closes when the complete derived plan exists',
    () async {
      await fixture.prepareClosable(pulseCount: 125, finalNeedle: 25);
      final evidence = await fixture.evidence.listBySample('sample-1');
      expect(evidence, hasLength(6));
      expect(
        evidence.where((item) => item.volumeRefLiters == 125),
        hasLength(1),
      );
      expect(
        (await fixture.sampleClosure.closeValid(
          'sample-1',
          at: fixedTime,
        )).status,
        SampleStatus.closedValid,
      );
    },
  );

  test('final below one step closes with only START and FINAL', () async {
    await fixture.prepareClosable(pulseCount: 20, finalNeedle: 20);
    expect(await fixture.evidence.listBySample('sample-1'), hasLength(2));
    expect(
      (await fixture.sampleClosure.closeValid(
        'sample-1',
        at: fixedTime,
      )).status,
      SampleStatus.closedValid,
    );
  });

  test(
    'missing START marks sample INVALID_EVIDENCE and does not enqueue',
    () async {
      await fixture.prepareClosable(omittedEvidenceVolumes: {0});
      final result = await fixture.sampleClosure.closeValid(
        'sample-1',
        at: fixedTime,
      );
      expect(result.status, SampleStatus.invalidEvidence);
      expect(await fixture.sync.listPending(), isEmpty);
    },
  );

  test('missing FINAL marks sample INVALID_EVIDENCE', () async {
    await fixture.prepareClosable(omittedEvidenceVolumes: {200});
    expect(
      (await fixture.sampleClosure.closeValid(
        'sample-1',
        at: fixedTime,
      )).status,
      SampleStatus.invalidEvidence,
    );
  });

  test(
    'missing 75 L evidence without a Point still invalidates sample',
    () async {
      await fixture.prepareClosable(
        pulseCount: 125,
        finalNeedle: 25,
        omittedEvidenceVolumes: {75},
      );
      expect(
        (await fixture.sampleClosure.closeValid(
          'sample-1',
          at: fixedTime,
        )).status,
        SampleStatus.invalidEvidence,
      );
    },
  );

  test(
    'persisted evidence with missing physical file invalidates sample',
    () async {
      await fixture.prepareClosable(pulseCount: 125, finalNeedle: 25);
      final item = (await fixture.evidence.listBySample(
        'sample-1',
      )).firstWhere((evidence) => evidence.volumeRefLiters == 75);
      await File(item.localPath).delete();
      expect(
        (await fixture.sampleClosure.closeValid(
          'sample-1',
          at: fixedTime,
        )).status,
        SampleStatus.invalidEvidence,
      );
    },
  );

  test('persisted evidence with incorrect hash invalidates sample', () async {
    await fixture.prepareClosable(pulseCount: 125, finalNeedle: 25);
    final item = (await fixture.evidence.listBySample(
      'sample-1',
    )).firstWhere((evidence) => evidence.volumeRefLiters == 75);
    await File(item.localPath).writeAsString('tampered-after-hash');
    expect(
      (await fixture.sampleClosure.closeValid(
        'sample-1',
        at: fixedTime,
      )).status,
      SampleStatus.invalidEvidence,
    );
  });

  test('confirmed readings are mandatory before metrological close', () async {
    await fixture.running();
    expect(
      () => fixture.sampleClosure.closeValid('sample-1', at: fixedTime),
      throwsStateError,
    );
    expect(
      (await fixture.samples.getById('sample-1'))!.status,
      SampleStatus.running,
    );
  });

  test(
    'closed sample and evidence are immutable in repository and SQLite',
    () async {
      await fixture.prepareClosable();
      await fixture.points.save(
        TestPoint(
          id: 'start-point',
          sampleId: 'sample-1',
          type: PointType.start,
          pulseCount: 0,
          capturedAt: fixedTime,
        ),
      );
      final closed = await fixture.sampleClosure.closeValid(
        'sample-1',
        at: fixedTime,
      );
      expect(
        () => fixture.samples.updateProgress(id: 'sample-1', pulseCount: 201),
        throwsStateError,
      );
      final evidence = (await fixture.evidence.listBySample('sample-1')).first;
      expect(() => fixture.evidence.save(evidence), throwsStateError);
      expect(
        () => database.customStatement(
          "UPDATE samples SET pulse_count = 201 WHERE id = 'sample-1'",
        ),
        throwsA(anything),
      );
      expect(
        () => database.customStatement(
          "UPDATE test_points SET pulse_count = 1 WHERE id = 'start-point'",
        ),
        throwsA(anything),
      );
      expect(
        (await fixture.samples.getById('sample-1'))!.checksum,
        closed.checksum,
      );
    },
  );

  test('RUNNING sample progress survives database close and reopen', () async {
    await database.close();
    final path = '${directory.path}${Platform.pathSeparator}resume.sqlite';
    var diskDb = AppDatabase(NativeDatabase(File(path)));
    var diskFixture = OfflineFixture(diskDb, directory);
    await diskFixture.seed();
    await diskFixture.running();
    await diskFixture.samples.updateProgress(
      id: 'sample-1',
      pulseCount: 87,
      initialReading: ConfirmedReading(
        reading: MeterReading(odometerUnits: 47, needleLiters: 12),
        source: ReadingSource.manual,
      ),
    );
    await diskDb.close();
    diskDb = AppDatabase(NativeDatabase(File(path)));
    diskFixture = OfflineFixture(diskDb, directory);
    final resumed = (await diskFixture.samples.listIncomplete()).single;
    expect(resumed.status, SampleStatus.running);
    expect(resumed.pulseCount, 87);
    expect(resumed.initialReading!.reading.needleLiters, 12);
    await diskDb.close();
    database = memoryDatabase();
  });
}
