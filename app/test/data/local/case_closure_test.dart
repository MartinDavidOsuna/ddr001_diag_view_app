import 'dart:io';

import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:ddr001_diag_view_app/data/local/database/app_database.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/offline_fixture.dart';

void main() {
  late Directory directory;
  late AppDatabase database;
  late OfflineFixture fixture;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ddr001-case-');
    database = memoryDatabase();
    fixture = OfflineFixture(database, directory);
    await fixture.seed();
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  Future<void> closeQ3({double finalNeedle = 0, int number = 1}) async {
    final id = 'sample-$number';
    await fixture.prepareClosable(
      sampleId: id,
      number: number,
      finalNeedle: finalNeedle,
    );
    final closed = await fixture.sampleClosure.closeValid(id, at: fixedTime);
    expect(closed.status, SampleStatus.closedValid);
  }

  test(
    'all required flows PASS closes case APPROVED with sync checksum',
    () async {
      await closeQ3();
      final closed = await fixture.caseClosure.closeCase(
        caseId: 'case-1',
        requiredFlowPoints: {FlowPoint.q3},
        at: fixedTime,
      );
      expect(closed.status, VerificationCaseStatus.closed);
      expect(closed.overallVerdict, OverallVerdict.approved);
      expect(closed.checksum, hasLength(64));
      final sync = await fixture.sync.listPending();
      expect(sync.map((item) => item.entityType), contains('verificationCase'));
    },
  );

  test('one persisted FAIL makes case REJECTED', () async {
    await closeQ3(finalNeedle: 6);
    final closed = await fixture.caseClosure.closeCase(
      caseId: 'case-1',
      requiredFlowPoints: {FlowPoint.q3},
      at: fixedTime,
    );
    expect(closed.overallVerdict, OverallVerdict.rejected);
  });

  test('one persisted INCONCLUSIVE makes case INCONCLUSIVE', () async {
    await closeQ3(finalNeedle: 3.4);
    final closed = await fixture.caseClosure.closeCase(
      caseId: 'case-1',
      requiredFlowPoints: {FlowPoint.q3},
      at: fixedTime,
    );
    expect(closed.overallVerdict, OverallVerdict.inconclusive);
  });

  test('missing explicitly required flow makes case INCONCLUSIVE', () async {
    await closeQ3();
    final closed = await fixture.caseClosure.closeCase(
      caseId: 'case-1',
      requiredFlowPoints: {FlowPoint.q1, FlowPoint.q3},
      at: fixedTime,
    );
    expect(closed.overallVerdict, OverallVerdict.inconclusive);
  });

  test('multiple persisted samples produce Stage 1 flow statistics', () async {
    await closeQ3(number: 1);
    await closeQ3(number: 2, finalNeedle: 1);
    await closeQ3(number: 3, finalNeedle: 2);
    final result = await fixture.flows.summarize('flow-q3');
    expect(result.samples, hasLength(3));
    expect(result.statistics!.n, 3);
    expect(result.statistics!.meanErrorPct, closeTo(0.5, 1e-12));
  });

  test('CLOSED case cannot reopen accept flows or samples', () async {
    await closeQ3();
    await fixture.caseClosure.closeCase(
      caseId: 'case-1',
      requiredFlowPoints: {FlowPoint.q3},
      at: fixedTime,
    );
    expect(
      () => fixture.caseClosure.closeCase(
        caseId: 'case-1',
        requiredFlowPoints: {FlowPoint.q3},
        at: fixedTime,
      ),
      throwsStateError,
    );
    expect(
      () => fixture.flows.create(
        FlowPointRecord(
          id: 'flow-q1',
          caseId: 'case-1',
          code: FlowPoint.q1,
          mpePct: 5,
          status: FlowRecordStatus.open,
          createdAt: fixedTime,
        ),
      ),
      throwsStateError,
    );
    expect(
      () => fixture.samples.createDraft(fixture.draft(id: 'later', number: 2)),
      throwsStateError,
    );
    expect(
      () => database.customStatement(
        "UPDATE verification_cases SET status = 'open' WHERE id = 'case-1'",
      ),
      throwsA(anything),
    );
  });
}
