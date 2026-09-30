import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/metrology/metrology.dart';
import '../../domain/integrity_checksum.dart';
import '../../domain/models.dart';
import 'remote_api.dart';
import 'sync_point_identity.dart';

final class FunctionalCaseBundle {
  const FunctionalCaseBundle({
    required this.user,
    required this.meter,
    required this.verificationCase,
    required this.flows,
    required this.samples,
    required this.pointsBySample,
    required this.evidenceBySample,
  });

  final User user;
  final Meter meter;
  final VerificationCase verificationCase;
  final List<FlowPointRecord> flows;
  final List<Sample> samples;
  final Map<String, List<TestPoint>> pointsBySample;
  final Map<String, List<Evidence>> evidenceBySample;
}

final class SerializedSyncBatch {
  const SerializedSyncBatch({
    required this.id,
    required this.request,
    required this.requestJson,
    required this.requestSha256,
  });
  final String id;
  final Map<String, Object?> request;
  final String requestJson;
  final String requestSha256;
}

final class FunctionalSyncSerializer {
  const FunctionalSyncSerializer([this._uuid = const Uuid()]);
  final Uuid _uuid;

  SerializedSyncBatch serialize({
    required FunctionalCaseBundle bundle,
    required String installationId,
    required DateTime generatedAt,
    String? batchId,
  }) {
    final id = batchId ?? _uuid.v4();
    final items = <Map<String, Object?>>[];
    void add(
      String type,
      String entityId,
      String? parentId,
      String? checksum,
      Map<String, Object?> payload,
    ) {
      final item = <String, Object?>{
        'itemId': _uuid.v4(),
        'entityType': type,
        'entityId': entityId,
        'payloadSha256': canonicalSha256(payload),
        'payload': payload,
      };
      if (parentId != null) item['parentId'] = parentId;
      if (checksum != null) item['entityChecksum'] = checksum;
      items.add(item);
    }

    final meter = bundle.meter;
    add('METER', meter.id, null, null, {
      'meterId': meter.id,
      'externalStatus': switch (meter.externalStatus) {
        ExternalMeterStatus.foundWithSurvey ||
        ExternalMeterStatus.foundNoSurvey => 'FOUND',
        ExternalMeterStatus.notFound => 'NOT_FOUND',
        ExternalMeterStatus.unknownOffline => 'UNKNOWN_OFFLINE',
      },
      if (meter.externalSnapshotJson case final snapshot?)
        'externalSnapshot': _jsonSnapshot(snapshot),
      if (meter.externalCheckedAt case final checked?)
        'externalCheckedAt': _instant(checked),
      'createdAt': _instant(meter.createdAt),
      'updatedAt': _instant(meter.updatedAt),
    });

    final verificationCase = bundle.verificationCase;
    add('CASE', verificationCase.id, null, verificationCase.checksum, {
      'schema': 'ddr001.verification.case/v2',
      'caseId': verificationCase.id,
      'meterId': verificationCase.meterId,
      'clientUserId': bundle.user.id,
      'status': verificationCase.status == VerificationCaseStatus.closed
          ? 'CLOSED'
          : 'OPEN',
      if (verificationCase.overallVerdict != null)
        'overallVerdict': _overallVerdict(verificationCase.overallVerdict!),
      'createdAt': _instant(verificationCase.createdAt),
      if (verificationCase.closedAt case final closed?)
        'closedAt': _instant(closed),
      'reportVersion': verificationCase.reportVersion,
      'testBenchId': verificationCase.testBenchId,
      'device': {
        if (verificationCase.deviceId != null) 'id': verificationCase.deviceId,
        if (verificationCase.androidVersion != null)
          'androidVersion': verificationCase.androidVersion,
        if (verificationCase.deviceBrand != null)
          'brand': verificationCase.deviceBrand,
        if (verificationCase.deviceModel != null)
          'model': verificationCase.deviceModel,
      },
      if (verificationCase.checksum != null)
        'checksum': verificationCase.checksum,
      if (verificationCase.status == VerificationCaseStatus.closed)
        'canonicalVersion': caseCanonicalVersion(verificationCase),
    });

    for (final flow in bundle.flows) {
      add('FLOW_POINT', flow.id, verificationCase.id, null, {
        'flowPointId': flow.id,
        'caseId': verificationCase.id,
        'code': flow.code.name.toUpperCase(),
        if (flow.lpsApprox != null) 'lpsApprox': flow.lpsApprox,
        'mpePct': flow.mpePct,
        'status': flow.status.name.toUpperCase(),
        'createdAt': _instant(flow.createdAt),
        if (flow.statistics case final stats?)
          'statistics': {
            'n': stats.n,
            'meanErrorPct': stats.meanErrorPct,
            'minimumErrorPct': stats.minimumErrorPct,
            'maximumErrorPct': stats.maximumErrorPct,
            'dispersionPct': stats.dispersionPct,
            if (stats.sampleStandardDeviationPct != null)
              'sampleStdDevPct': stats.sampleStandardDeviationPct,
            'repeatabilityStatus': switch (stats.repeatabilityStatus) {
              RepeatabilityStatus.pass => 'PASS',
              RepeatabilityStatus.fail => 'FAIL',
              RepeatabilityStatus.notEvaluable => 'NOT_APPLICABLE',
            },
          },
      });
    }

    for (final sample in bundle.samples) {
      add('SAMPLE', sample.id, sample.flowPointId, sample.checksum, {
        'schema': 'ddr001.verification.sample/v9',
        'sampleId': sample.id,
        'flowPointId': sample.flowPointId,
        'sampleNumber': sample.sampleNumber,
        'status': sample.status == SampleStatus.closedValid
            ? 'CLOSED_VALID'
            : 'INVALID_EVIDENCE',
        'measurementSource': sample.configuration.measurementMethod.name
            .toUpperCase(),
        'isSimulation': sample.isSimulation,
        if (sample.simulationScenario != null)
          'simulationScenario': _simulationScenario(sample),
        'createdAt': _instant(sample.createdAt),
        'updatedAt': _instant(sample.updatedAt),
        if (sample.startedAt case final started?)
          'startedAt': _instant(started),
        if (sample.endedAt case final ended?) 'endedAt': _instant(ended),
        if (sample.gps case final gps?)
          'gps': {
            'latitude': gps.latitude,
            'longitude': gps.longitude,
            'accuracyMeters': gps.accuracyMeters,
            'capturedAt': _instant(gps.capturedAt),
          },
        'pulseCount': sample.pulseCount,
        if (sample.referenceLitersProgress != null)
          'progressReferenceL': sample.referenceLitersProgress,
        if (sample.initialReading case final reading?)
          'startReading': _reading(reading),
        if (sample.finalReading case final reading?)
          'endReading': _reading(reading),
        if (sample.result case final result?) 'result': _result(result),
        'acquisitionIntegrity': {
          'status': sample.acquisitionIntegrity.status.name.toUpperCase(),
          if (sample.acquisitionIntegrity.reason != null)
            'reason': sample.acquisitionIntegrity.reason,
          if (sample.acquisitionIntegrity.occurredAt case final at?)
            'occurredAt': _instant(at),
          if (sample.acquisitionIntegrity.source case final source?)
            'source': source.name.toUpperCase(),
        },
        if (sample.checksum != null) 'checksum': sample.checksum,
        if (sample.status == SampleStatus.closedValid)
          'canonicalVersion': sampleCanonicalVersion(sample),
        if (sample.status == SampleStatus.closedValid)
          'algorithmVersion': 'ddr001.metrology.endpoint-guard-band/v1',
      });

      add(
        'OPERATIONAL_SETTINGS',
        sample.id,
        sample.id,
        sample.checksum,
        _settings(sample),
      );
      for (final point in bundle.pointsBySample[sample.id] ?? const []) {
        add(
          'POINT',
          syncPointId(sample.id, point.id),
          sample.id,
          null,
          _point(point),
        );
      }
      for (final evidence in bundle.evidenceBySample[sample.id] ?? const []) {
        add('EVIDENCE_REF', evidence.id, sample.id, null, {
          'evidenceId': evidence.id,
          'sampleId': sample.id,
          if (evidence.pointId != null)
            'pointId': syncPointId(evidence.sampleId, evidence.pointId!),
          'type': _evidenceType(evidence.type),
          'required': evidence.required,
          if (evidence.volumeRefLiters != null)
            'volumeRefL': evidence.volumeRefLiters,
          if (evidence.pulseCount != null) 'pulseCount': evidence.pulseCount,
          'capturedAt': _instant(evidence.capturedAt),
          'clientSha256': evidence.sha256,
        });
      }
    }

    final request = <String, Object?>{
      'schema': 'functional-diagnostics.sync/v1',
      'batchId': id,
      'installationId': installationId,
      'clientGeneratedAt': _instant(generatedAt),
      'items': items,
    };
    return SerializedSyncBatch(
      id: id,
      request: request,
      requestJson: jsonEncode(request),
      requestSha256: canonicalSha256(request),
    );
  }
}

Object? _jsonSnapshot(String value) {
  try {
    return jsonDecode(value);
  } catch (_) {
    return value;
  }
}

String _instant(DateTime value) => value.toUtc().toIso8601String();

String _overallVerdict(OverallVerdict value) => switch (value) {
  OverallVerdict.approved => 'APROBADO',
  OverallVerdict.rejected => 'RECHAZADO',
  OverallVerdict.inconclusive => 'NO_CONCLUYENTE',
};

String _simulationScenario(Sample sample) =>
    switch (sample.simulationScenario!) {
      SimulationScenario.successful => 'PASS',
      SimulationScenario.failed => 'FAIL',
      SimulationScenario.failThenPass => switch (sample.result?.verdict) {
        SampleVerdict.pass => 'PASS',
        SampleVerdict.fail => 'FAIL',
        SampleVerdict.inconclusive || null => 'INCONCLUSIVE',
      },
      SimulationScenario.operatorControlled => switch (sample.result?.verdict) {
        SampleVerdict.pass => 'PASS',
        SampleVerdict.fail => 'FAIL',
        SampleVerdict.inconclusive || null => 'INCONCLUSIVE',
      },
    };

Map<String, Object?> _reading(ConfirmedReading value) => {
  'odometerUnits': value.reading.odometerUnits,
  'needleL': value.reading.needleLiters,
  'source': value.source == ReadingSource.autoConfirmed
      ? 'AUTO_CONFIRMED'
      : 'MANUAL',
  if (value.evidenceId != null) 'evidenceId': value.evidenceId,
};

Map<String, Object?> _result(SampleResult value) => {
  'vRefL': value.referenceLiters,
  'vIndL': value.indicatedLiters,
  'errorPct': value.errorPct,
  'uncertaintyPct': value.uncertaintyPct,
  'mpePct': value.mpePct,
  'acceptanceMetricPct': value.decisionMetrics.acceptanceMetricPct,
  'rejectionMetricPct': value.decisionMetrics.rejectionMetricPct,
  'verdict': switch (value.verdict) {
    SampleVerdict.pass => 'APRUEBA',
    SampleVerdict.fail => 'RECHAZA',
    SampleVerdict.inconclusive => 'NO_CONCLUYENTE',
  },
};

Map<String, Object?> _settings(Sample sample) {
  final c = sample.configuration;
  final result = <String, Object?>{
    'sampleId': sample.id,
    'litersPerPulse': c.litersPerPulse,
    'evidenceStepL': c.evidenceStepLiters,
    'readingUncertaintyL': c.readingUncertaintyLiters,
    'flowPointCode': c.flowPoint.name.toUpperCase(),
    'configuredMpePct': c.mpePct,
    if (c.lpsApprox != null) 'lpsApprox': c.lpsApprox,
    'litersPerOdometerUnit': c.litersPerOdometerUnit,
    'needleLitersPerRevolution': c.needleLitersPerRevolution,
    if (c.minimumVolumeLiters != null) 'minimumVolumeL': c.minimumVolumeLiters,
    if (c.maximumVolumeLiters != null) 'maximumVolumeL': c.maximumVolumeLiters,
    'controlStartMinimumLps': c.controlStartMinimumLps,
    if (c.controlStartMaximumLps.isFinite)
      'controlStartMaximumLps': c.controlStartMaximumLps,
    'hydrantLitersPerPulse': c.hydrantLitersPerPulse,
    'cameraZoomLevel': c.cameraZoomLevel,
  };
  if (sample.meterFaceConfiguration case final face?) {
    result['meterFace'] = {
      'totalizer': {
        'left': face.totalizerLeft,
        'top': face.totalizerTop,
        'width': face.totalizerWidth,
        'height': face.totalizerHeight,
      },
      'dial': {
        'centerX': face.dialCenterX,
        'centerY': face.dialCenterY,
        'radius': face.dialRadius,
        'multiplier': face.multiplier,
        'litersPerRevolution': face.litersPerRevolution,
        'zeroAngleDegrees': face.zeroAngleDegrees,
        'clockwise': face.clockwise,
        'source': face.source == DialConfigurationSource.autoConfirmed
            ? 'AUTO_CONFIRMED'
            : 'MANUAL',
      },
      if (face.totalizerConfiguration case final format?)
        'totalizerFormat': {
          'digitCount': format.digitCount,
          'decimalPlaces': format.decimalPlaces,
          'unit': 'M3',
          'leadingZerosAllowed': format.leadingZerosAllowed,
          'source': format.source == DialConfigurationSource.autoConfirmed
              ? 'AUTO_CONFIRMED'
              : 'MANUAL',
        },
    };
  }
  if (sample.pulseAcquisitionConfiguration case final acquisition?) {
    result['acquisition'] = {
      if (acquisition.bleDeviceId != null)
        'bleDeviceId': acquisition.bleDeviceId,
      if (acquisition.bleDeviceName != null)
        'bleDeviceName': acquisition.bleDeviceName,
      if (acquisition.bleServiceUuid != null)
        'serviceUuid': acquisition.bleServiceUuid,
      if (acquisition.bleCounterCharacteristicUuid != null)
        'counterCharacteristicUuid': acquisition.bleCounterCharacteristicUuid,
      if (acquisition.bleProtocolVersion != null)
        'protocolVersion': acquisition.bleProtocolVersion,
      if (acquisition.esp32CounterAtStart != null)
        'baselineCounter': acquisition.esp32CounterAtStart,
      if (acquisition.lastObservedEsp32Counter != null)
        'lastCounter': acquisition.lastObservedEsp32Counter,
      if (acquisition.ledRoiLeft != null)
        'ledRoi': {
          'left': acquisition.ledRoiLeft,
          'top': acquisition.ledRoiTop,
          'width': acquisition.ledRoiWidth,
          'height': acquisition.ledRoiHeight,
        },
      if (acquisition.ledRisingDelta != null)
        'ledRisingDelta': acquisition.ledRisingDelta,
      if (acquisition.ledFallingDelta != null)
        'ledFallingDelta': acquisition.ledFallingDelta,
      if (acquisition.ledMinPulseIntervalMs != null)
        'ledMinPulseIntervalMs': acquisition.ledMinPulseIntervalMs,
      if (acquisition.ledBaseline != null)
        'ledBaseline': acquisition.ledBaseline,
      'usesBleReconciliation': acquisition.ledUsesBleReconciliation,
    };
  }
  return result;
}

Map<String, Object?> _point(TestPoint point) => {
  'pointId': syncPointId(point.sampleId, point.id),
  'sampleId': point.sampleId,
  'type': switch (point.type) {
    PointType.start => 'START',
    PointType.intermediate => 'INTERMEDIATE',
    PointType.finalPoint => 'FINAL',
    PointType.manualDiagnostic => 'MANUAL_DIAGNOSTIC',
  },
  if (point.pulseCount != null) 'pulseCount': point.pulseCount,
  if (point.referenceLiters != null) 'vRefL': point.referenceLiters,
  if (point.readingLiters != null) 'readingL': point.readingLiters,
  if (point.indicatedLiters != null) 'vIndL': point.indicatedLiters,
  if (point.diagnosticErrorPct != null)
    'diagnosticErrorPct': point.diagnosticErrorPct,
  if (point.needleLiters != null) 'needleL': point.needleLiters,
  if (point.meterUnderTestPulseCount != null)
    'meterUnderTestPulseCount': point.meterUnderTestPulseCount,
  if (point.flowLps != null) 'flowLps': point.flowLps,
  'capturedAt': _instant(point.capturedAt),
};

String _evidenceType(EvidenceType type) => switch (type) {
  EvidenceType.start => 'START',
  EvidenceType.intermediate => 'INTERMEDIATE',
  EvidenceType.finalEvidence => 'FINAL',
  EvidenceType.extra => 'EXTRA',
};
