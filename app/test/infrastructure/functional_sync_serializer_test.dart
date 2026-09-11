import 'dart:convert';

import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:ddr001_diag_view_app/infrastructure/remote/functional_sync_serializer.dart';
import 'package:ddr001_diag_view_app/infrastructure/remote/remote_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('complete Q1 case serializes to the implemented sync/v1 contract', () {
    final serialized = const FunctionalSyncSerializer().serialize(
      bundle: _bundle(),
      installationId: _installationId,
      generatedAt: _time,
      batchId: _batchId,
    );
    final request = serialized.request;
    expect(request['schema'], 'functional-diagnostics.sync/v1');
    expect(request['batchId'], _batchId);
    final items = (request['items']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(
      items.map((item) => item['entityType']),
      orderedEquals([
        'METER',
        'CASE',
        'FLOW_POINT',
        'SAMPLE',
        'OPERATIONAL_SETTINGS',
        'POINT',
        'EVIDENCE_REF',
        'EVIDENCE_REF',
      ]),
    );
    for (final item in items) {
      expect(item['payloadSha256'], canonicalSha256(item['payload']));
    }
    final casePayload = _payload(items, 'CASE');
    expect(casePayload['schema'], 'ddr001.verification.case/v2');
    expect(casePayload['clientUserId'], _localUserId);
    expect(casePayload, isNot(contains('userId')));
    final sample = _payload(items, 'SAMPLE');
    expect(sample['status'], 'CLOSED_VALID');
    expect(sample['measurementSource'], 'MANUAL');
    expect(sample['result'], {
      'vRefL': 100.0,
      'vIndL': 99.0,
      'errorPct': -1.0,
      'uncertaintyPct': 0.5,
      'mpePct': 2.0,
      'acceptanceMetricPct': 1.5,
      'rejectionMetricPct': 0.5,
      'verdict': 'APRUEBA',
    });
    expect(jsonDecode(serialized.requestJson), request);
  });

  test('simulation marker and scenario survive contract serialization', () {
    final serialized = const FunctionalSyncSerializer().serialize(
      bundle: _bundle(simulation: true),
      installationId: _installationId,
      generatedAt: _time,
      batchId: _batchId,
    );
    final sample = _payload(
      (serialized.request['items']! as List<Object?>)
          .cast<Map<String, Object?>>(),
      'SAMPLE',
    );
    expect(sample['measurementSource'], 'SIMULATION');
    expect(sample['isSimulation'], isTrue);
    expect(sample['simulationScenario'], 'PASS');
    expect(sample['canonicalVersion'], 6);
  });
}

Map<String, Object?> _payload(List<Map<String, Object?>> items, String type) =>
    items.singleWhere((item) => item['entityType'] == type)['payload']!
        as Map<String, Object?>;

FunctionalCaseBundle _bundle({bool simulation = false}) {
  const startEvidenceId = '77777777-7777-4777-8777-777777777777';
  const finalEvidenceId = '88888888-8888-4888-8888-888888888888';
  final configuration = SampleConfiguration(
    measurementMethod: simulation
        ? MeasurementMethod.simulation
        : MeasurementMethod.manual,
    litersPerPulse: 1,
    evidenceStepLiters: 25,
    readingUncertaintyLiters: 0.5,
    flowPoint: FlowPoint.q1,
    mpePct: 2,
    lpsApprox: 1.5,
    litersPerOdometerUnit: 1000,
    needleLitersPerRevolution: 100,
    minimumVolumeLiters: 100,
    maximumVolumeLiters: 300,
    controlStartMinimumLps: 0.5,
    controlStartMaximumLps: 50,
    hydrantLitersPerPulse: 1,
  );
  final sample = Sample(
    id: _sampleId,
    flowPointId: _flowId,
    sampleNumber: 1,
    status: SampleStatus.closedValid,
    configuration: configuration,
    createdAt: _time,
    updatedAt: _time.add(const Duration(minutes: 2)),
    startedAt: _time.add(const Duration(seconds: 1)),
    endedAt: _time.add(const Duration(minutes: 2)),
    pulseCount: 100,
    referenceLitersProgress: 100,
    initialReading: ConfirmedReading(
      reading: MeterReading(odometerUnits: 47, needleLiters: 0),
      source: ReadingSource.manual,
      evidenceId: startEvidenceId,
    ),
    finalReading: ConfirmedReading(
      reading: MeterReading(odometerUnits: 47, needleLiters: 99),
      source: ReadingSource.manual,
      evidenceId: finalEvidenceId,
    ),
    result: const SampleResult(
      referenceLiters: 100,
      indicatedLiters: 99,
      errorPct: -1,
      uncertaintyPct: 0.5,
      mpePct: 2,
      decisionMetrics: DecisionMetrics(
        acceptanceMetricPct: 1.5,
        rejectionMetricPct: 0.5,
      ),
      verdict: SampleVerdict.pass,
    ),
    checksum: _checksum,
    simulationScenario: simulation
        ? SimulationScenario.operatorControlled
        : null,
  );
  final evidence = [
    Evidence(
      id: startEvidenceId,
      sampleId: _sampleId,
      pointId: _pointId,
      type: EvidenceType.start,
      required: true,
      volumeRefLiters: 0,
      pulseCount: 0,
      capturedAt: _time,
      sha256: _checksum,
      localPath: '/local/start.jpg',
      syncStatus: EvidenceSyncStatus.synced,
    ),
    Evidence(
      id: finalEvidenceId,
      sampleId: _sampleId,
      type: EvidenceType.finalEvidence,
      required: true,
      volumeRefLiters: 100,
      pulseCount: 100,
      capturedAt: _time.add(const Duration(minutes: 2)),
      sha256: _checksum,
      localPath: '/local/final.jpg',
      syncStatus: EvidenceSyncStatus.synced,
    ),
  ];
  return FunctionalCaseBundle(
    user: User(
      id: _localUserId,
      email: 'field@example.com',
      phone: '4491234567',
      displayName: 'Técnico',
      createdAt: _time,
      remoteUserId: _remoteUserId,
    ),
    meter: Meter(
      id: 'CUENTA-001',
      externalStatus: ExternalMeterStatus.unknownOffline,
      createdAt: _time,
    ),
    verificationCase: VerificationCase(
      id: _caseId,
      meterId: 'CUENTA-001',
      userId: _localUserId,
      status: VerificationCaseStatus.closed,
      overallVerdict: OverallVerdict.approved,
      createdAt: _time,
      closedAt: _time,
      reportVersion: 1,
      testBenchId: 'BANCO-1',
      checksum: _checksum,
    ),
    flows: [
      FlowPointRecord(
        id: _flowId,
        caseId: _caseId,
        code: FlowPoint.q1,
        lpsApprox: 1.5,
        mpePct: 2,
        status: FlowRecordStatus.pass,
        createdAt: _time,
      ),
    ],
    samples: [sample],
    pointsBySample: {
      _sampleId: [
        TestPoint(
          id: _pointId,
          sampleId: _sampleId,
          type: PointType.start,
          pulseCount: 0,
          referenceLiters: 0,
          capturedAt: _time,
        ),
      ],
    },
    evidenceBySample: {_sampleId: evidence},
  );
}

final _time = DateTime.utc(2026, 9, 2, 12);
const _installationId = '11111111-1111-4111-8111-111111111111';
const _batchId = '22222222-2222-4222-8222-222222222222';
const _localUserId = '33333333-3333-4333-8333-333333333333';
const _remoteUserId = '44444444-4444-4444-8444-444444444444';
const _caseId = '55555555-5555-4555-8555-555555555555';
const _flowId = '66666666-6666-4666-8666-666666666666';
const _sampleId = '99999999-9999-4999-8999-999999999999';
const _pointId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _checksum =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
