import '../core/metrology/metrology.dart';
import 'models.dart';

abstract interface class UserRepository {
  Future<void> save(User user);
  Future<User?> getById(String id);
  Future<User?> getByEmailAndPhone(String email, String phone);
  Future<void> linkRemoteUser(String localUserId, String remoteUserId);
}

abstract interface class MeterRepository {
  Future<void> save(Meter meter);
  Future<Meter?> getById(String id);
}

abstract interface class VerificationCaseRepository {
  Future<void> create(VerificationCase verificationCase);
  Future<VerificationCase?> getById(String id);
  Future<VerificationCase?> findOpenByMeter(String meterId);
  Future<List<VerificationCase>> listLocalCases();
  Future<List<VerificationCase>> listOpenCases();
}

abstract interface class FlowPointRepository {
  Future<void> create(FlowPointRecord flowPoint);
  Future<void> updateLps(String id, double lpsApprox);
  Future<FlowPointRecord?> getById(String id);
  Future<List<FlowPointRecord>> listByCase(String caseId);
  Future<FlowPointResult> summarize(String flowPointId);
}

abstract interface class SampleRepository {
  Future<Sample> createDraft(Sample sample);
  Future<Sample?> getById(String id);
  Future<Sample> start(String id, {required DateTime at, GpsSnapshot? gps});
  Future<Sample> updateProgress({
    required String id,
    required int pulseCount,
    double? referenceLiters,
    double? manualIndicatedLiters,
    DateTime? firstPulseAt,
    ConfirmedReading? initialReading,
    ConfirmedReading? finalReading,
  });
  Future<Sample> updateMeterFaceConfiguration(
    String id,
    MeterFaceConfiguration configuration,
  );
  Future<Sample> updateCameraZoom(String id, double zoomLevel);
  Future<Sample> updatePulseAcquisition({
    required String id,
    required PulseAcquisitionConfiguration configuration,
    required AcquisitionIntegrity integrity,
  });
  Future<Sample> markInvalidEvidence(String id, {required DateTime at});
  Future<List<Sample>> listByFlow(String flowPointId);
  Future<List<Sample>> listIncomplete();
  Future<Sample?> getActiveByFlow(String flowPointId);
  Future<void> deleteOpen(String id);
}

abstract interface class PointRepository {
  Future<void> save(TestPoint point);
  Future<List<TestPoint>> listBySample(String sampleId);
  Future<void> deleteByTypeFromOpenSample(String sampleId, PointType type);
}

abstract interface class EvidenceRepository {
  Future<void> save(Evidence evidence);
  Future<Evidence?> getById(String id);
  Future<List<Evidence>> listBySample(String sampleId);
  Future<bool> hasCompleteRequiredSet(String sampleId);
  Future<void> deleteFromOpenSample(String evidenceId);
  Future<void> updateRemoteState({
    required String evidenceId,
    required EvidenceSyncStatus status,
    String? serverStorageKey,
    DateTime? confirmedAt,
    String? error,
  });
}

abstract interface class SyncBatchRepository {
  Future<SyncBatch> savePending(SyncBatch batch);
  Future<SyncBatch?> unresolvedForCase(String caseId);
  Future<SyncBatch?> latestForCase(String caseId);
  Future<List<SyncBatch>> listRunnable({DateTime? at});
  Future<void> markSending(String id, {required DateTime at});
  Future<void> markAmbiguous(
    String id, {
    required String error,
    required DateTime at,
  });
  Future<void> markFailed(
    String id, {
    required String error,
    required DateTime at,
    DateTime? nextRetryAt,
  });
  Future<void> markConflict(
    String id, {
    required String error,
    required DateTime at,
  });
  Future<void> markSynced(
    String id, {
    required String receiptId,
    required DateTime at,
  });
}

abstract interface class SyncQueueRepository {
  Future<SyncItem> enqueue({
    required String entityType,
    required String entityId,
    required String checksum,
    required DateTime at,
  });
  Future<List<SyncItem>> listPending();
  Future<void> incrementAttempt(String id, {required DateTime at});
  Future<void> markFailed(
    String id, {
    required String error,
    required DateTime at,
    DateTime? nextRetryAt,
  });
  Future<void> markSynced(String id, {required DateTime at});
}

abstract interface class SampleClosureService {
  Future<Sample> closeValid(String sampleId, {required DateTime at});
}

abstract interface class VerificationCaseClosureService {
  Future<VerificationCase> closeCase({
    required String caseId,
    required Set<FlowPoint> requiredFlowPoints,
    required DateTime at,
  });
}
