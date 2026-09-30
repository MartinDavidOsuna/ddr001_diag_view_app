import 'dart:convert';
import 'dart:io';

import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:ddr001_diag_view_app/data/local/database/app_database.dart';
import 'package:ddr001_diag_view_app/data/local/repositories/local_correction_service.dart';
import 'package:ddr001_diag_view_app/data/local/repositories/local_repositories.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/offline_fixture.dart';

void main() {
  late Directory directory;
  late AppDatabase database;
  late OfflineFixture fixture;
  late LocalCorrectionService corrections;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ddr-corrections-');
    database = memoryDatabase();
    fixture = OfflineFixture(database, directory);
    await fixture.seed();
    corrections = LocalCorrectionService(database, fixture.fileStore);
    await fixture.prepareClosable();
    await fixture.points.save(
      TestPoint(
        id: 'point-start',
        sampleId: 'sample-1',
        type: PointType.start,
        capturedAt: fixedTime,
        pulseCount: 0,
        referenceLiters: 0,
      ),
    );
    await fixture.points.save(
      TestPoint(
        id: 'point-final',
        sampleId: 'sample-1',
        type: PointType.finalPoint,
        capturedAt: fixedTime,
        pulseCount: 200,
        referenceLiters: 200,
      ),
    );
    await fixture.sampleClosure.closeValid('sample-1', at: fixedTime);
    await fixture.caseClosure.closeCase(
      caseId: 'case-1',
      requiredFlowPoints: {FlowPoint.q3},
      at: fixedTime,
    );
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  Future<void> edit({
    double total = 210,
    String actor = 'user-1',
    String? checksum,
  }) async => corrections.correct(
    caseId: 'case-1',
    actorId: actor,
    expectedChecksum:
        checksum ?? (await fixture.cases.getById('case-1'))!.checksum!,
    reason: 'Error de dedo',
    sampleId: 'sample-1',
    initialOdometer: 47,
    initialNeedle: 0,
    finalOdometer: 47,
    finalNeedle: 10,
    initialTotalLiters: 47000,
    finalTotalLiters: 47000 + total,
  );

  test(
    'correction recalculates endpoints, flow, verdict and checksums without changing acquisition',
    () async {
      final before = (await fixture.samples.getById('sample-1'))!;
      final originalCase = (await fixture.cases.getById('case-1'))!;
      final evidence = await fixture.evidence.listBySample('sample-1');
      await edit();
      final sample = (await fixture.samples.getById('sample-1'))!;
      final changedCase = (await fixture.cases.getById('case-1'))!;
      expect(sample.result!.indicatedLiters, 210);
      expect(sample.result!.errorPct, 5);
      expect(sample.result!.verdict, SampleVerdict.fail);
      expect(changedCase.overallVerdict, OverallVerdict.rejected);
      expect(changedCase.reportVersion, 2);
      expect(sample.checksum, isNot(before.checksum));
      expect(changedCase.checksum, isNot(originalCase.checksum));
      expect(sample.pulseCount, before.pulseCount);
      expect(
        sample.configuration.litersPerPulse,
        before.configuration.litersPerPulse,
      );
      expect(sample.startedAt, before.startedAt);
      expect(sample.endedAt, before.endedAt);
      expect(changedCase.closedAt, originalCase.closedAt);
      expect(
        (await fixture.flows.getById('flow-q3'))!.statistics!.meanErrorPct,
        5,
      );
      final points = await fixture.points.listBySample(sample.id);
      expect(points.last.indicatedLiters, 210);
      expect(points.last.pulseCount, 200);
      expect(
        (await fixture.evidence.listBySample(sample.id)).map((e) => e.sha256),
        evidence.map((e) => e.sha256),
      );
      final audit = await corrections.history('case-1');
      expect(audit, hasLength(1));
      final savedBefore =
          jsonDecode(audit.single['before_json'] as String) as Map;
      expect(
        (savedBefore['samples'] as List).single['checksum'],
        before.checksum,
      );
      expect(await corrections.hasPending('case-1'), isTrue);
      expect(await corrections.requiresRemoteRevision('case-1'), isFalse);
      final queue = await fixture.sync.listPending();
      expect(
        queue.where((q) => q.entityId == sample.id).single.checksum,
        sample.checksum,
      );
      expect(
        (await database
            .customSelect('SELECT * FROM correction_write_scope')
            .get()),
        isEmpty,
      );
      expect(
        () => database.customStatement(
          "UPDATE samples SET pulse_count = 1 WHERE id = 'sample-1'",
        ),
        throwsA(anything),
      );
      expect(
        () => fixture.sampleClosure.recalculate('sample-1', at: fixedTime),
        throwsStateError,
      );
    },
  );

  test(
    'changing K recalculates volume and uncertainty from stored pulses, preserving original evidence',
    () async {
      final oldEvidence = await fixture.evidence.listBySample('sample-1');
      Future<void> setK(double k) async => corrections.correct(
        caseId: 'case-1',
        actorId: 'user-1',
        expectedChecksum: (await fixture.cases.getById('case-1'))!.checksum!,
        reason: 'Constante transcrita',
        sampleId: 'sample-1',
        initialOdometer: 47,
        initialNeedle: 0,
        finalOdometer: 47,
        finalNeedle: 10,
        initialTotalLiters: 47000,
        finalTotalLiters: 47400,
        litersPerPulse: k,
        hydrantLitersPerPulse: 10,
        readingUncertaintyLiters: .5,
      );
      await setK(2);
      final sample = (await fixture.samples.getById('sample-1'))!;
      expect(sample.pulseCount, 200);
      expect(sample.result!.referenceLiters, 400);
      expect(sample.result!.indicatedLiters, 400);
      expect(sample.result!.verdict, SampleVerdict.pass);
      expect(sample.configuration.hydrantLitersPerPulse, 10);
      expect(sample.result!.uncertaintyPct, closeTo(.176776695, 1e-8));
      expect(
        (await fixture.points.listBySample('sample-1')).last.referenceLiters,
        400,
      );
      expect(
        (await fixture.evidence.listBySample(
          'sample-1',
        )).map((e) => e.volumeRefLiters),
        oldEvidence.map((e) => e.volumeRefLiters),
      );
      await setK(4);
      expect(
        (await fixture.samples.getById('sample-1'))!.result!.referenceLiters,
        800,
      );
      expect(await corrections.history('case-1'), hasLength(2));
      final checksum = (await fixture.samples.getById('sample-1'))!.checksum;
      await expectLater(setK(double.nan), throwsArgumentError);
      expect((await fixture.samples.getById('sample-1'))!.checksum, checksum);
    },
  );

  test(
    'invalid correction and stale/foreign edits leave all data intact',
    () async {
      final checksum = (await fixture.cases.getById('case-1'))!.checksum!;
      await expectLater(edit(total: -1), throwsArgumentError);
      await expectLater(edit(actor: 'other'), throwsStateError);
      await expectLater(edit(checksum: 'stale'), throwsStateError);
      expect((await fixture.cases.getById('case-1'))!.checksum, checksum);
      expect(await corrections.history('case-1'), isEmpty);
      expect(
        await database
            .customSelect('SELECT * FROM correction_write_scope')
            .get(),
        isEmpty,
      );
      expect(
        await database
            .customSelect('SELECT * FROM correction_superseded_queue')
            .get(),
        isEmpty,
      );
    },
  );

  test(
    'transaction rolls back sample, case, points and queue if audit persistence fails',
    () async {
      await database.customStatement(
        "CREATE TRIGGER fail_correction BEFORE INSERT ON case_corrections BEGIN SELECT RAISE(ABORT, 'disk failure'); END",
      );
      final checksum = (await fixture.samples.getById('sample-1'))!.checksum;
      await expectLater(edit(), throwsA(anything));
      expect((await fixture.samples.getById('sample-1'))!.checksum, checksum);
      expect((await fixture.cases.getById('case-1'))!.reportVersion, 1);
      expect(
        await database
            .customSelect('SELECT * FROM correction_write_scope')
            .get(),
        isEmpty,
      );
      expect(
        await database
            .customSelect('SELECT * FROM correction_superseded_queue')
            .get(),
        isEmpty,
      );
    },
  );

  test(
    'previous synced or ambiguous request requires API revision and keeps receipt intact',
    () async {
      final batches = LocalSyncBatchRepository(database);
      await batches.savePending(
        SyncBatch(
          id: 'batch',
          caseId: 'case-1',
          requestJson: '{}',
          requestSha256: 'hash',
          state: SyncBatchState.pending,
          attempts: 0,
          createdAt: fixedTime,
          updatedAt: fixedTime,
        ),
      );
      await batches.markSynced('batch', receiptId: 'receipt', at: fixedTime);
      await edit();
      expect(await corrections.requiresRemoteRevision('case-1'), isTrue);
      await corrections.acknowledge('case-1', const []);
      expect(await corrections.hasPending('case-1'), isTrue);
      expect((await batches.latestForCase('case-1'))!.receiptId, 'receipt');
      await edit(total: 200);
      expect(await corrections.history('case-1'), hasLength(2));
      expect(
        (await fixture.cases.getById('case-1'))!.overallVerdict,
        OverallVerdict.approved,
      );
    },
  );

  test(
    'identification correction relinks only this case and preserves the original meter',
    () async {
      await corrections.correct(
        caseId: 'case-1',
        actorId: 'user-1',
        expectedChecksum: (await fixture.cases.getById('case-1'))!.checksum!,
        reason: 'Cuenta transcrita',
        meterId: 'meter-corrected',
        testBenchId: 'Banco 2',
      );
      expect(
        (await fixture.cases.getById('case-1'))!.meterId,
        'meter-corrected',
      );
      expect(await fixture.meters.getById('meter-1'), isNotNull);
      expect((await fixture.cases.getById('case-1'))!.testBenchId, 'Banco 2');
    },
  );

  test(
    'migration from v14 preserves closed sample checksums and enables audited corrections',
    () async {
      final path = '${directory.path}/migration.sqlite';
      var disk = AppDatabase(NativeDatabase(File(path)));
      var seed = OfflineFixture(disk, directory);
      await seed.seed();
      await seed.prepareClosable();
      await seed.sampleClosure.closeValid('sample-1', at: fixedTime);
      await seed.caseClosure.closeCase(
        caseId: 'case-1',
        requiredFlowPoints: {FlowPoint.q3},
        at: fixedTime,
      );
      final checksum = (await seed.cases.getById('case-1'))!.checksum!;
      await disk.customStatement('DROP TABLE case_corrections');
      await disk.customStatement('DROP TABLE correction_write_scope');
      await disk.customStatement('DROP TABLE correction_superseded_queue');
      await disk.customStatement('PRAGMA user_version = 14');
      await disk.close();
      disk = AppDatabase(NativeDatabase(File(path)));
      seed = OfflineFixture(disk, directory);
      expect((await seed.cases.getById('case-1'))!.checksum, checksum);
      await LocalCorrectionService(disk, seed.fileStore).correct(
        caseId: 'case-1',
        actorId: 'user-1',
        expectedChecksum: checksum,
        reason: 'Banco',
        testBenchId: 'Banco 2',
      );
      expect((await seed.cases.getById('case-1'))!.reportVersion, 2);
      await disk.close();
    },
  );
}
