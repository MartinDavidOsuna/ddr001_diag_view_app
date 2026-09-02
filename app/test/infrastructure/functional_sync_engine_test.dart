import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:ddr001_diag_view_app/data/local/database/app_database.dart'
    hide Meter, User;
import 'package:ddr001_diag_view_app/data/local/filesystem/evidence_file_store.dart';
import 'package:ddr001_diag_view_app/data/local/repositories/local_closure_services.dart';
import 'package:ddr001_diag_view_app/data/local/repositories/local_repositories.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:ddr001_diag_view_app/infrastructure/remote/functional_sync_engine.dart';
import 'package:ddr001_diag_view_app/infrastructure/remote/remote_api.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory directory;
  late AppDatabase database;
  late _SyncFixture fixture;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'ddr001-functional-sync-',
    );
    database = AppDatabase(NativeDatabase.memory());
    fixture = _SyncFixture(database, directory);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test(
    'Evidence is uploaded before sync and successful ACK clears queue',
    () async {
      await fixture.seedClosedCase();
      final calls = <String>[];
      final engine = fixture.engine((request) async {
        calls.add(request.url.path);
        if (request.url.path.endsWith('/me/access')) return _access();
        if (request.url.path.endsWith('/evidence')) return _evidenceAck();
        if (request.url.path.endsWith('/sync/push')) return _receipt(request);
        throw StateError('Unexpected route ${request.url}');
      });

      final result = await engine.syncCase(
        caseId: _caseId,
        localUserId: _userId,
      );

      expect(
        result.outcome,
        FunctionalSyncOutcome.synced,
        reason: result.message,
      );
      expect(calls.where((path) => path.endsWith('/evidence')), hasLength(2));
      expect(calls.last, '/api/v1/functional-diagnostics/sync/push');
      expect(await fixture.queue.listPending(), isEmpty);
      expect(
        (await fixture.evidence.listBySample(
          _sampleId,
        )).map((item) => item.syncStatus),
        everyElement(EvidenceSyncStatus.synced),
      );
    },
  );

  test('an already-synced Case produces no remote requests', () async {
    await fixture.seedClosedCase();
    var remoteCalls = 0;
    final firstEngine = fixture.engine((request) async {
      if (request.url.path.endsWith('/me/access')) return _access();
      if (request.url.path.endsWith('/evidence')) return _evidenceAck();
      if (request.url.path.endsWith('/sync/push')) return _receipt(request);
      throw StateError('Unexpected route ${request.url}');
    });
    expect(
      (await firstEngine.syncCase(
        caseId: _caseId,
        localUserId: _userId,
      )).outcome,
      FunctionalSyncOutcome.synced,
    );

    final secondEngine = fixture.engine((_) async {
      remoteCalls++;
      throw StateError('A confirmed Case must not reach the network.');
    });
    final repeated = await secondEngine.syncCase(
      caseId: _caseId,
      localUserId: _userId,
    );

    expect(repeated.outcome, FunctionalSyncOutcome.synced);
    expect(remoteCalls, 0);
    expect((await fixture.batches.latestForCase(_caseId))?.attempts, 1);
  });

  test(
    'lost ACK is recovered by receipt without creating another batch',
    () async {
      await fixture.seedClosedCase();
      Map<String, Object?>? sentRequest;
      var pushCalls = 0;
      var statusCalls = 0;
      final engine = fixture.engine((request) async {
        if (request.url.path.endsWith('/me/access')) return _access();
        if (request.url.path.endsWith('/evidence')) return _evidenceAck();
        if (request.url.path.endsWith('/sync/push')) {
          pushCalls++;
          sentRequest = jsonDecode(request.body) as Map<String, Object?>;
          return Completer<http.Response>().future;
        }
        if (request.url.path.endsWith('/sync/status')) {
          statusCalls++;
          return _receiptFor(sentRequest!);
        }
        throw StateError('Unexpected route ${request.url}');
      }, timeout: const Duration(milliseconds: 10));

      final first = await engine.syncCase(
        caseId: _caseId,
        localUserId: _userId,
      );
      expect(first.outcome, FunctionalSyncOutcome.pending);
      final persisted = await fixture.batches.unresolvedForCase(_caseId);
      expect(persisted?.state, SyncBatchState.ambiguous);
      expect(persisted?.requestJson, jsonEncode(sentRequest));

      final second = await engine.syncCase(
        caseId: _caseId,
        localUserId: _userId,
      );
      expect(second.outcome, FunctionalSyncOutcome.synced);
      expect(pushCalls, 1);
      expect(statusCalls, 1);
      expect(await fixture.batches.unresolvedForCase(_caseId), isNull);
    },
  );

  test(
    'rejected legacy payload hashes are repaired with the same batch ID',
    () async {
      await fixture.seedClosedCase();
      final batchIds = <String>[];
      var pushCalls = 0;
      final engine = fixture.engine((request) async {
        if (request.url.path.endsWith('/me/access')) return _access();
        if (request.url.path.endsWith('/evidence')) return _evidenceAck();
        if (request.url.path.endsWith('/sync/push')) {
          pushCalls++;
          final body = jsonDecode(request.body) as Map<String, Object?>;
          batchIds.add(body['batchId']! as String);
          if (pushCalls == 1) {
            return http.Response(
              jsonEncode({
                'error': {
                  'code': 'PAYLOAD_HASH_MISMATCH',
                  'message':
                      'payloadSha256 does not match the canonical item payload.',
                },
              }),
              422,
              headers: {'content-type': 'application/json'},
            );
          }
          return _receipt(request);
        }
        throw StateError('Unexpected route ${request.url}');
      });

      final first = await engine.syncCase(
        caseId: _caseId,
        localUserId: _userId,
      );
      expect(first.outcome, FunctionalSyncOutcome.error);
      expect(
        (await fixture.batches.unresolvedForCase(_caseId))?.state,
        SyncBatchState.failed,
      );

      final second = await engine.syncCase(
        caseId: _caseId,
        localUserId: _userId,
      );
      expect(second.outcome, FunctionalSyncOutcome.synced);
      expect(pushCalls, 2);
      expect(batchIds.toSet(), hasLength(1));
    },
  );

  test(
    '409 receipt preserves local case, checksum and evidence files',
    () async {
      final sample = await fixture.seedClosedCase();
      final paths = (await fixture.evidence.listBySample(
        _sampleId,
      )).map((item) => item.localPath).toList();
      final engine = fixture.engine((request) async {
        if (request.url.path.endsWith('/me/access')) return _access();
        if (request.url.path.endsWith('/evidence')) return _evidenceAck();
        if (request.url.path.endsWith('/sync/push')) {
          return _receipt(request, conflict: true);
        }
        throw StateError('Unexpected route ${request.url}');
      });

      final result = await engine.syncCase(
        caseId: _caseId,
        localUserId: _userId,
      );
      expect(result.outcome, FunctionalSyncOutcome.conflict);
      expect(
        (await fixture.samples.getById(_sampleId))?.checksum,
        sample.checksum,
      );
      expect(await fixture.cases.getById(_caseId), isNotNull);
      for (final path in paths) {
        expect(await File(path).exists(), isTrue);
      }
    },
  );

  test(
    'missing Evidence file keeps metadata and reports integrity error',
    () async {
      await fixture.seedClosedCase();
      final item = (await fixture.evidence.listBySample(_sampleId)).first;
      await File(item.localPath).delete();
      final engine = fixture.engine((request) async {
        if (request.url.path.endsWith('/me/access')) return _access();
        throw StateError('No upload should be sent for a missing file.');
      });

      final result = await engine.syncCase(
        caseId: _caseId,
        localUserId: _userId,
      );
      expect(result.outcome, FunctionalSyncOutcome.error);
      final persisted = await fixture.evidence.getById(item.id);
      expect(persisted, isNotNull);
      expect(persisted?.syncStatus, EvidenceSyncStatus.error);
      expect(persisted?.lastSyncError, contains('LOCAL_EVIDENCE_MISSING'));
    },
  );

  test('disabled access leaves queue and all local work pending', () async {
    await fixture.seedClosedCase();
    final before = await fixture.queue.listPending();
    final engine = fixture.engine((_) async => _access(enabled: false));
    final result = await engine.syncCase(caseId: _caseId, localUserId: _userId);
    expect(result.outcome, FunctionalSyncOutcome.accessDenied);
    expect(await fixture.queue.listPending(), hasLength(before.length));
    expect(await fixture.cases.getById(_caseId), isNotNull);
  });

  test('HTTP 403 leaves queue and all local work pending', () async {
    await fixture.seedClosedCase();
    final before = await fixture.queue.listPending();
    final engine = fixture.engine(
      (_) async => http.Response(
        jsonEncode({
          'error': {
            'code': 'FUNCTIONAL_ACCESS_DISABLED',
            'message': 'Functional access is disabled.',
          },
        }),
        403,
      ),
    );

    final result = await engine.syncCase(caseId: _caseId, localUserId: _userId);

    expect(result.outcome, FunctionalSyncOutcome.accessDenied);
    expect(await fixture.queue.listPending(), hasLength(before.length));
    expect(await fixture.cases.getById(_caseId), isNotNull);
    expect(await fixture.samples.getById(_sampleId), isNotNull);
    expect(await fixture.evidence.listBySample(_sampleId), hasLength(2));
  });

  test('one failed Case does not block the next queued Case', () async {
    await fixture.seedClosedCase();
    final engine = fixture.engine((request) async {
      if (request.url.path.endsWith('/me/access')) return _access();
      if (request.url.path.endsWith('/evidence')) return _evidenceAck();
      if (request.url.path.endsWith('/sync/push')) return _receipt(request);
      throw StateError('Unexpected route ${request.url}');
    });
    final results = await engine.syncCases(
      caseIds: const ['aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', _caseId],
      localUserId: _userId,
    );
    expect(results.first.outcome, FunctionalSyncOutcome.error);
    expect(results.last.outcome, FunctionalSyncOutcome.synced);
  });
}

final class _SyncFixture {
  _SyncFixture(this.database, this.directory)
    : users = LocalUserRepository(database),
      meters = LocalMeterRepository(database),
      cases = LocalVerificationCaseRepository(database),
      flows = LocalFlowPointRepository(database),
      samples = LocalSampleRepository(database),
      points = LocalPointRepository(database),
      evidence = LocalEvidenceRepository(database),
      queue = LocalSyncQueueRepository(database),
      batches = LocalSyncBatchRepository(database),
      fileStore = LocalEvidenceFileStore(directory) {
    closure = LocalSampleClosureService(database, fileStore);
  }

  final AppDatabase database;
  final Directory directory;
  final LocalUserRepository users;
  final LocalMeterRepository meters;
  final LocalVerificationCaseRepository cases;
  final LocalFlowPointRepository flows;
  final LocalSampleRepository samples;
  final LocalPointRepository points;
  final LocalEvidenceRepository evidence;
  final LocalSyncQueueRepository queue;
  final LocalSyncBatchRepository batches;
  final LocalEvidenceFileStore fileStore;
  late final LocalSampleClosureService closure;

  Future<Sample> seedClosedCase() async {
    final evidenceBytes = await File(
      'assets/simulation/simulation_evidence_placeholder.png',
    ).readAsBytes();
    await users.save(
      User(
        id: _userId,
        email: 'field@example.com',
        phone: '4491234567',
        displayName: 'Técnico',
        createdAt: _time,
        remoteUserId: _remoteUserId,
      ),
    );
    await meters.save(
      Meter(
        id: 'CUENTA-1',
        externalStatus: ExternalMeterStatus.unknownOffline,
        createdAt: _time,
      ),
    );
    await cases.create(
      VerificationCase(
        id: _caseId,
        meterId: 'CUENTA-1',
        userId: _userId,
        status: VerificationCaseStatus.open,
        createdAt: _time,
        reportVersion: 1,
        testBenchId: 'BANCO-1',
      ),
    );
    await flows.create(
      FlowPointRecord(
        id: _flowId,
        caseId: _caseId,
        code: FlowPoint.q1,
        mpePct: 2,
        status: FlowRecordStatus.open,
        createdAt: _time,
      ),
    );
    await samples.createDraft(
      Sample(
        id: _sampleId,
        flowPointId: _flowId,
        sampleNumber: 1,
        status: SampleStatus.draft,
        configuration: const SampleConfiguration(
          measurementMethod: MeasurementMethod.manual,
          litersPerPulse: 1,
          evidenceStepLiters: 25,
          readingUncertaintyLiters: 0.1,
          flowPoint: FlowPoint.q1,
          mpePct: 2,
          litersPerOdometerUnit: 1000,
          needleLitersPerRevolution: 100,
        ),
        createdAt: _time,
        updatedAt: _time,
        pulseCount: 0,
      ),
    );
    await samples.start(_sampleId, at: _time.add(const Duration(seconds: 1)));
    await samples.updateProgress(
      id: _sampleId,
      pulseCount: 20,
      initialReading: ConfirmedReading(
        reading: MeterReading(odometerUnits: 47, needleLiters: 0),
        source: ReadingSource.manual,
      ),
      finalReading: ConfirmedReading(
        reading: MeterReading(odometerUnits: 47, needleLiters: 20),
        source: ReadingSource.manual,
      ),
    );
    for (final entry in const [
      (_startEvidenceId, EvidenceType.start, 0.0),
      (_finalEvidenceId, EvidenceType.finalEvidence, 20.0),
    ]) {
      final path = await fileStore.reservePath(
        caseId: _caseId,
        sampleId: _sampleId,
        evidenceId: entry.$1,
        extension: 'png',
      );
      await File(path).writeAsBytes(evidenceBytes);
      await evidence.save(
        Evidence(
          id: entry.$1,
          sampleId: _sampleId,
          type: entry.$2,
          required: true,
          volumeRefLiters: entry.$3,
          pulseCount: entry.$3.toInt(),
          capturedAt: _time,
          sha256: sha256.convert(evidenceBytes).toString(),
          localPath: path,
          syncStatus: EvidenceSyncStatus.local,
        ),
      );
    }
    return closure.closeValid(
      _sampleId,
      at: _time.add(const Duration(minutes: 1)),
    );
  }

  FunctionalSyncEngine engine(
    Future<http.Response> Function(http.Request) handler, {
    Duration timeout = const Duration(seconds: 1),
  }) {
    final credentials = _Credentials();
    final api = RemoteApiClient(
      baseUrl: 'https://test.invalid',
      credentials: credentials,
      client: MockClient(handler),
      jsonTimeout: timeout,
      uploadTimeout: timeout,
    );
    return FunctionalSyncEngine(
      api: api,
      installationIds: const _InstallationIds(),
      users: users,
      meters: meters,
      cases: cases,
      flows: flows,
      samples: samples,
      points: points,
      evidence: evidence,
      queue: queue,
      batches: batches,
    );
  }
}

http.Response _access({bool enabled = true}) => http.Response(
  jsonEncode({
    'data': {
      'userId': _remoteUserId,
      'clientApp': functionalClientApp,
      'accessEnabled': enabled,
      'policyVersion': 1,
      'updatedAt': _time.toIso8601String(),
    },
  }),
  200,
);

http.Response _evidenceAck() => http.Response(
  jsonEncode({
    'data': {'status': 'created', 'storageKey': 'opaque-evidence-key'},
  }),
  201,
);

http.Response _receipt(http.Request request, {bool conflict = false}) =>
    _receiptFor(
      jsonDecode(request.body) as Map<String, Object?>,
      conflict: conflict,
    );

http.Response _receiptFor(
  Map<String, Object?> request, {
  bool conflict = false,
}) {
  final items = (request['items']! as List<Object?>)
      .cast<Map<String, Object?>>();
  return http.Response(
    jsonEncode({
      'data': {
        'receiptId': request['batchId'],
        'status': conflict ? 'partial' : 'complete',
        'receivedAt': _time.toIso8601String(),
        'completedAt': _time.toIso8601String(),
        'items': [
          for (var index = 0; index < items.length; index++)
            {
              'itemId': items[index]['itemId'],
              'entityType': items[index]['entityType'],
              'entityId': items[index]['entityId'],
              'status': conflict && index == 1 ? 'conflict' : 'created',
              'code': conflict && index == 1 ? 'CHECKSUM_CONFLICT' : 'OK',
              'retryable': false,
              'serverChecksum': null,
              'details': <String, Object?>{},
            },
        ],
      },
    }),
    200,
  );
}

final class _Credentials implements RemoteCredentialStore {
  RemoteCredentials? value = const RemoteCredentials(
    accessToken: 'access',
    refreshToken: 'refresh',
    sessionId: _sessionId,
    remoteUserId: _remoteUserId,
  );

  @override
  Future<void> clear() async => value = null;
  @override
  Future<String?> read() async => value?.accessToken;
  @override
  Future<RemoteCredentials?> readCredentials() async => value;
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> writeCredentials(RemoteCredentials credentials) async =>
      value = credentials;
}

final class _InstallationIds implements InstallationIdStore {
  const _InstallationIds();
  @override
  Future<String> readOrCreate() async => _installationId;
}

final _time = DateTime.utc(2026, 9, 2, 12);
const _installationId = '11111111-1111-4111-8111-111111111111';
const _sessionId = '22222222-2222-4222-8222-222222222222';
const _remoteUserId = '33333333-3333-4333-8333-333333333333';
const _userId = '44444444-4444-4444-8444-444444444444';
const _caseId = '55555555-5555-4555-8555-555555555555';
const _flowId = '66666666-6666-4666-8666-666666666666';
const _sampleId = '77777777-7777-4777-8777-777777777777';
const _startEvidenceId = '88888888-8888-4888-8888-888888888888';
const _finalEvidenceId = '99999999-9999-4999-8999-999999999999';
