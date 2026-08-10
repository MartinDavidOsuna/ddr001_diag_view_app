import 'dart:io';

import 'package:drift/native.dart';
import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:ddr001_diag_view_app/data/local/database/app_database.dart'
    hide Meter, User;
import 'package:ddr001_diag_view_app/data/local/filesystem/evidence_file_store.dart';
import 'package:ddr001_diag_view_app/data/local/repositories/local_closure_services.dart';
import 'package:ddr001_diag_view_app/data/local/repositories/local_repositories.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:ddr001_diag_view_app/domain/expected_evidence_plan.dart';

final fixedTime = DateTime.utc(2026, 8, 9, 12);

AppDatabase memoryDatabase() => AppDatabase(NativeDatabase.memory());

final class OfflineFixture {
  OfflineFixture(this.database, this.directory)
    : users = LocalUserRepository(database),
      meters = LocalMeterRepository(database),
      cases = LocalVerificationCaseRepository(database),
      flows = LocalFlowPointRepository(database),
      samples = LocalSampleRepository(database),
      points = LocalPointRepository(database),
      evidence = LocalEvidenceRepository(database),
      sync = LocalSyncQueueRepository(database),
      fileStore = LocalEvidenceFileStore(directory) {
    sampleClosure = LocalSampleClosureService(database, fileStore);
    caseClosure = LocalVerificationCaseClosureService(database);
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
  final LocalSyncQueueRepository sync;
  final LocalEvidenceFileStore fileStore;
  late final LocalSampleClosureService sampleClosure;
  late final LocalVerificationCaseClosureService caseClosure;

  Future<void> seed({FlowPoint flowPoint = FlowPoint.q3}) async {
    await users.save(
      User(
        id: 'user-1',
        email: 'TECH@example.com',
        phone: '+52 449 123 4567',
        createdAt: fixedTime,
      ),
    );
    await meters.save(
      Meter(
        id: 'meter-1',
        externalStatus: ExternalMeterStatus.unknownOffline,
        createdAt: fixedTime,
      ),
    );
    await cases.create(
      VerificationCase(
        id: 'case-1',
        meterId: 'meter-1',
        userId: 'user-1',
        status: VerificationCaseStatus.open,
        createdAt: fixedTime,
        reportVersion: 1,
      ),
    );
    await flows.create(
      FlowPointRecord(
        id: 'flow-${flowPoint.name}',
        caseId: 'case-1',
        code: flowPoint,
        mpePct: const Class2WaterMpePolicy().mpePctFor(flowPoint),
        status: FlowRecordStatus.open,
        createdAt: fixedTime,
      ),
    );
  }

  Sample draft({
    String id = 'sample-1',
    String flowId = 'flow-q3',
    int number = 1,
    FlowPoint flowPoint = FlowPoint.q3,
    MeasurementMethod method = MeasurementMethod.manual,
    double uncertaintyLiters = 1,
  }) => Sample(
    id: id,
    flowPointId: flowId,
    sampleNumber: number,
    status: SampleStatus.draft,
    configuration: SampleConfiguration(
      measurementMethod: method,
      litersPerPulse: 1,
      evidenceStepLiters: 25,
      readingUncertaintyLiters: uncertaintyLiters,
      flowPoint: flowPoint,
      mpePct: const Class2WaterMpePolicy().mpePctFor(flowPoint),
      lpsApprox: 10,
      litersPerOdometerUnit: 1000,
      needleLitersPerRevolution: 100,
    ),
    createdAt: fixedTime,
    updatedAt: fixedTime,
    pulseCount: 0,
  );

  Future<Sample> running({
    String id = 'sample-1',
    String flowId = 'flow-q3',
    int number = 1,
    FlowPoint flowPoint = FlowPoint.q3,
    MeasurementMethod method = MeasurementMethod.manual,
    double uncertaintyLiters = 1,
  }) async {
    await samples.createDraft(
      draft(
        id: id,
        flowId: flowId,
        number: number,
        flowPoint: flowPoint,
        method: method,
        uncertaintyLiters: uncertaintyLiters,
      ),
    );
    return samples.start(id, at: fixedTime.add(const Duration(seconds: 1)));
  }

  Future<void> addEvidence({
    required String sampleId,
    required String id,
    required EvidenceType type,
    String? pointId,
    bool required = true,
    bool missingFile = false,
    bool corruptHash = false,
    double? volumeRefLiters,
  }) async {
    final path = await fileStore.reservePath(
      caseId: 'case-1',
      sampleId: sampleId,
      evidenceId: id,
      extension: 'jpg',
    );
    if (!missingFile) await File(path).writeAsString('content-$id');
    final hash = missingFile
        ? List.filled(64, '0').join()
        : corruptHash
        ? List.filled(64, 'f').join()
        : await fileStore.calculateSha256(path);
    await evidence.save(
      Evidence(
        id: id,
        sampleId: sampleId,
        pointId: pointId,
        type: type,
        required: required,
        volumeRefLiters: volumeRefLiters,
        capturedAt: fixedTime,
        sha256: hash,
        localPath: path,
        syncStatus: EvidenceSyncStatus.local,
      ),
    );
  }

  Future<Sample> prepareClosable({
    String sampleId = 'sample-1',
    String flowId = 'flow-q3',
    int number = 1,
    FlowPoint flowPoint = FlowPoint.q3,
    MeasurementMethod method = MeasurementMethod.manual,
    int pulseCount = 200,
    double? visualReferenceLiters,
    double finalNeedle = 0,
    double uncertaintyLiters = 1,
    Set<double> omittedEvidenceVolumes = const {},
  }) async {
    await running(
      id: sampleId,
      flowId: flowId,
      number: number,
      flowPoint: flowPoint,
      method: method,
      uncertaintyLiters: uncertaintyLiters,
    );
    await samples.updateProgress(
      id: sampleId,
      pulseCount: pulseCount,
      referenceLiters: visualReferenceLiters,
      initialReading: ConfirmedReading(
        reading: MeterReading(odometerUnits: 47, needleLiters: 0),
        source: ReadingSource.manual,
      ),
      finalReading: ConfirmedReading(
        reading: MeterReading(odometerUnits: 47, needleLiters: finalNeedle),
        source: ReadingSource.manual,
      ),
    );
    final finalVolume = visualReferenceLiters ?? pulseCount.toDouble();
    final plan = ExpectedEvidencePlan.derive(
      evidenceStepLiters: 25,
      finalVolumeLiters: finalVolume,
    );
    for (final (index, requirement) in plan.requirements.indexed) {
      if (omittedEvidenceVolumes.contains(requirement.volumeRefLiters)) {
        continue;
      }
      await addEvidence(
        sampleId: sampleId,
        id: '$sampleId-evidence-$index',
        type: requirement.type,
        volumeRefLiters: requirement.volumeRefLiters,
      );
    }
    return (await samples.getById(sampleId))!;
  }
}
