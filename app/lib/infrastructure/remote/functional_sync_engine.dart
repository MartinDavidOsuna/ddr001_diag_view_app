import 'dart:convert';

import '../../domain/models.dart';
import '../../domain/repositories.dart';
import 'functional_sync_serializer.dart';
import 'remote_api.dart';

enum FunctionalSyncOutcome { synced, conflict, pending, error, accessDenied }

final class FunctionalSyncResult {
  const FunctionalSyncResult(this.outcome, this.message);
  final FunctionalSyncOutcome outcome;
  final String message;
}

final class FunctionalSyncEngine {
  const FunctionalSyncEngine({
    required this.api,
    required this.installationIds,
    required this.users,
    required this.meters,
    required this.cases,
    required this.flows,
    required this.samples,
    required this.points,
    required this.evidence,
    required this.queue,
    required this.batches,
    this.serializer = const FunctionalSyncSerializer(),
  });

  final RemoteApiClient api;
  final InstallationIdStore installationIds;
  final UserRepository users;
  final MeterRepository meters;
  final VerificationCaseRepository cases;
  final FlowPointRepository flows;
  final SampleRepository samples;
  final PointRepository points;
  final EvidenceRepository evidence;
  final SyncQueueRepository queue;
  final SyncBatchRepository batches;
  final FunctionalSyncSerializer serializer;

  Future<FunctionalSyncResult> syncCase({
    required String caseId,
    required String localUserId,
  }) async {
    try {
      final access = await api.access();
      if (!access.enabled) {
        return const FunctionalSyncResult(
          FunctionalSyncOutcome.accessDenied,
          'Sin acceso remoto · el expediente permanece local',
        );
      }
      final bundle = await _bundle(caseId, localUserId);
      for (final sample in bundle.samples) {
        for (final item in bundle.evidenceBySample[sample.id] ?? const []) {
          final uploadResult = await _uploadEvidence(item);
          if (uploadResult != null) return uploadResult;
        }
      }

      var batch = await batches.unresolvedForCase(caseId);
      if (batch != null &&
          batch.state == SyncBatchState.failed &&
          _isPayloadHashFailure(batch.lastError)) {
        batch = await _repairPayloadHashes(batch);
      }
      if (batch?.state == SyncBatchState.conflict) {
        return FunctionalSyncResult(
          FunctionalSyncOutcome.conflict,
          batch!.lastError ?? 'Conflicto remoto',
        );
      }
      if (batch?.state == SyncBatchState.ambiguous) {
        final recovered = await api.syncStatus(batch!.receiptId ?? batch.id);
        if (recovered != null) return _applyReceipt(batch, recovered);
      }
      if (batch == null) {
        final now = DateTime.now().toUtc();
        final serialized = serializer.serialize(
          bundle: bundle,
          installationId: await installationIds.readOrCreate(),
          generatedAt: now,
        );
        batch = await batches.savePending(
          SyncBatch(
            id: serialized.id,
            caseId: caseId,
            requestJson: serialized.requestJson,
            requestSha256: serialized.requestSha256,
            state: SyncBatchState.pending,
            attempts: 0,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      final now = DateTime.now().toUtc();
      await batches.markSending(batch.id, at: now);
      try {
        final request = (jsonDecode(batch.requestJson) as Map)
            .cast<String, Object?>();
        final receipt = await api.pushSync(request);
        return _applyReceipt(batch, receipt);
      } on RemoteApiException catch (error) {
        if (error.kind == RemoteFailureKind.conflict) {
          await batches.markConflict(
            batch.id,
            error: error.message,
            at: DateTime.now().toUtc(),
          );
          return FunctionalSyncResult(
            FunctionalSyncOutcome.conflict,
            'Conflicto · ${error.message}',
          );
        }
        if (error.retryable) {
          await batches.markAmbiguous(
            batch.id,
            error: error.message,
            at: DateTime.now().toUtc(),
          );
          return const FunctionalSyncResult(
            FunctionalSyncOutcome.pending,
            'Pendiente · se confirmará el ACK al reintentar',
          );
        }
        await batches.markFailed(
          batch.id,
          error: '${error.code ?? error.kind.name}: ${error.message}',
          at: DateTime.now().toUtc(),
        );
        return FunctionalSyncResult(
          FunctionalSyncOutcome.error,
          'Error · ${error.message}',
        );
      }
    } on RemoteApiException catch (error) {
      if (error.kind == RemoteFailureKind.forbidden) {
        return FunctionalSyncResult(
          FunctionalSyncOutcome.accessDenied,
          'Sin acceso remoto · ${error.message}',
        );
      }
      return FunctionalSyncResult(
        error.retryable
            ? FunctionalSyncOutcome.pending
            : FunctionalSyncOutcome.error,
        '${error.retryable ? 'Pendiente' : 'Error'} · ${error.message}',
      );
    } catch (error) {
      return FunctionalSyncResult(
        FunctionalSyncOutcome.error,
        'Error · $error',
      );
    }
  }

  Future<SyncBatch> _repairPayloadHashes(SyncBatch batch) async {
    final request = (jsonDecode(batch.requestJson) as Map)
        .cast<String, Object?>();
    final items = (request['items']! as List<Object?>)
        .cast<Map<String, Object?>>();
    for (final item in items) {
      item['payloadSha256'] = canonicalSha256(item['payload']);
    }
    final requestJson = jsonEncode(request);
    return batches.repairFailedRequest(
      id: batch.id,
      requestJson: requestJson,
      requestSha256: canonicalSha256(request),
      at: DateTime.now().toUtc(),
    );
  }

  Future<List<FunctionalSyncResult>> syncCases({
    required Iterable<String> caseIds,
    required String localUserId,
  }) async {
    final results = <FunctionalSyncResult>[];
    for (final caseId in caseIds) {
      results.add(await syncCase(caseId: caseId, localUserId: localUserId));
    }
    return results;
  }

  Future<FunctionalCaseBundle> _bundle(
    String caseId,
    String localUserId,
  ) async {
    final verificationCase = await cases.getById(caseId);
    if (verificationCase == null) throw StateError('Case local no encontrado.');
    if (verificationCase.userId != localUserId) {
      throw StateError('El expediente pertenece a otra identidad local.');
    }
    final user = await users.getById(verificationCase.userId);
    final meter = await meters.getById(verificationCase.meterId);
    if (user == null || meter == null) {
      throw StateError('Falta identidad o medidor local del expediente.');
    }
    final caseFlows = await flows.listByCase(caseId);
    final closedSamples = <Sample>[];
    final pointsBySample = <String, List<TestPoint>>{};
    final evidenceBySample = <String, List<Evidence>>{};
    for (final flow in caseFlows) {
      for (final sample in await samples.listByFlow(flow.id)) {
        if (sample.status != SampleStatus.closedValid &&
            sample.status != SampleStatus.invalidEvidence) {
          continue;
        }
        closedSamples.add(sample);
        pointsBySample[sample.id] = await points.listBySample(sample.id);
        evidenceBySample[sample.id] = await evidence.listBySample(sample.id);
      }
    }
    if (closedSamples.isEmpty) {
      throw StateError(
        'El expediente no tiene muestras cerradas para sincronizar.',
      );
    }
    return FunctionalCaseBundle(
      user: user,
      meter: meter,
      verificationCase: verificationCase,
      flows: caseFlows,
      samples: closedSamples,
      pointsBySample: pointsBySample,
      evidenceBySample: evidenceBySample,
    );
  }

  Future<FunctionalSyncResult?> _uploadEvidence(Evidence item) async {
    if (item.syncStatus == EvidenceSyncStatus.synced) return null;
    await evidence.updateRemoteState(
      evidenceId: item.id,
      status: EvidenceSyncStatus.syncing,
    );
    try {
      final ack = await api.uploadEvidence(item);
      await evidence.updateRemoteState(
        evidenceId: item.id,
        status: EvidenceSyncStatus.synced,
        serverStorageKey: ack.storageKey,
        confirmedAt: DateTime.now().toUtc(),
      );
      return null;
    } on RemoteApiException catch (error) {
      final conflict = error.kind == RemoteFailureKind.conflict;
      await evidence.updateRemoteState(
        evidenceId: item.id,
        status: conflict
            ? EvidenceSyncStatus.conflict
            : EvidenceSyncStatus.error,
        error: '${error.code ?? error.kind.name}: ${error.message}',
      );
      return FunctionalSyncResult(
        conflict
            ? FunctionalSyncOutcome.conflict
            : error.retryable
            ? FunctionalSyncOutcome.pending
            : FunctionalSyncOutcome.error,
        '${conflict
            ? 'Conflicto'
            : error.retryable
            ? 'Pendiente'
            : 'Error'} · ${error.message}',
      );
    }
  }

  Future<FunctionalSyncResult> _applyReceipt(
    SyncBatch batch,
    SyncReceiptAck receipt,
  ) async {
    final now = DateTime.now().toUtc();
    if (receipt.hasConflict) {
      final conflicts = receipt.items
          .where((item) => item.status == 'conflict')
          .map((item) => '${item.entityType}:${item.entityId}:${item.code}')
          .join(', ');
      await batches.markConflict(batch.id, error: conflicts, at: now);
      return FunctionalSyncResult(
        FunctionalSyncOutcome.conflict,
        'Conflicto · $conflicts',
      );
    }
    if (receipt.hasRejected) {
      final rejected = receipt.items
          .where((item) => item.status == 'rejected')
          .map((item) => '${item.entityType}:${item.entityId}:${item.code}')
          .join(', ');
      await batches.markFailed(
        batch.id,
        error: rejected,
        at: now,
        nextRetryAt: receipt.hasRetryableRejection
            ? now.add(const Duration(minutes: 2))
            : null,
      );
      return FunctionalSyncResult(
        receipt.hasRetryableRejection
            ? FunctionalSyncOutcome.pending
            : FunctionalSyncOutcome.error,
        '${receipt.hasRetryableRejection ? 'Pendiente' : 'Error'} · $rejected',
      );
    }
    await batches.markSynced(batch.id, receiptId: receipt.receiptId, at: now);
    final ids = receipt.items.map((item) => item.entityId).toSet();
    for (final item in await queue.listPending()) {
      if (ids.contains(item.entityId)) await queue.markSynced(item.id, at: now);
    }
    return const FunctionalSyncResult(
      FunctionalSyncOutcome.synced,
      'Sincronizado',
    );
  }
}

bool _isPayloadHashFailure(String? error) =>
    error?.contains('PAYLOAD_HASH_MISMATCH') == true ||
    error?.contains('payloadSha256 does not match') == true;
