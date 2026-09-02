import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'models.dart';

String _field(String name, Object? value) {
  final text = value == null
      ? '<null>'
      : value is double
      ? value.toStringAsExponential(17)
      : value is DateTime
      ? value.toUtc().toIso8601String()
      : '$value';
  return '${name.length}:$name=${text.length}:$text;';
}

/// SHA-256 over an explicit, versioned and length-prefixed canonical sequence.
/// Lists are sorted by stable IDs before serialization; Maps are never encoded.
String calculateSampleChecksum({
  required Sample sample,
  required double referenceLiters,
  required double indicatedLiters,
  required double errorPct,
  required double uncertaintyPct,
  required double mpePct,
  required double acceptanceMetricPct,
  required double rejectionMetricPct,
  required String verdict,
  required DateTime endedAt,
  required List<Evidence> requiredEvidence,
}) {
  final evidence = [...requiredEvidence]..sort((a, b) => a.id.compareTo(b.id));
  final c = sample.configuration;
  final fields = <String>[
    _field('canonicalVersion', sampleCanonicalVersion(sample)),
    _field('sampleId', sample.id),
    _field('flowPointId', sample.flowPointId),
    _field('sampleNumber', sample.sampleNumber),
    _field('measurementMethod', c.measurementMethod.name),
    if (sample.isSimulation)
      _field('simulationScenario', sample.simulationScenario?.name),
    _field('litersPerPulse', c.litersPerPulse),
    _field('evidenceStepLiters', c.evidenceStepLiters),
    _field('readingUncertaintyLiters', c.readingUncertaintyLiters),
    _field('flowPoint', c.flowPoint.name),
    _field('configuredMpePct', c.mpePct),
    _field('lpsApprox', c.lpsApprox),
    _field('litersPerOdometerUnit', c.litersPerOdometerUnit),
    _field('needleLitersPerRevolution', c.needleLitersPerRevolution),
    if (c.minimumVolumeLiters != null)
      _field('minimumVolumeLiters', c.minimumVolumeLiters),
    if (c.maximumVolumeLiters != null)
      _field('maximumVolumeLiters', c.maximumVolumeLiters),
    if (c.controlStartMaximumLps.isFinite) ...[
      _field('controlStartMinimumLps', c.controlStartMinimumLps),
      _field('controlStartMaximumLps', c.controlStartMaximumLps),
      _field('hydrantLitersPerPulse', c.hydrantLitersPerPulse),
    ],
    _field('createdAt', sample.createdAt),
    _field('startedAt', sample.startedAt),
    _field('endedAt', endedAt),
    _field('pulseCount', sample.pulseCount),
    _field('referenceLitersProgress', sample.referenceLitersProgress),
    _field('gpsLatitude', sample.gps?.latitude),
    _field('gpsLongitude', sample.gps?.longitude),
    _field('gpsAccuracyMeters', sample.gps?.accuracyMeters),
    _field('gpsCapturedAt', sample.gps?.capturedAt),
    _field(
      'initialOdometerUnits',
      sample.initialReading?.reading.odometerUnits,
    ),
    _field('initialNeedleLiters', sample.initialReading?.reading.needleLiters),
    _field('initialReadingSource', sample.initialReading?.source.name),
    _field('initialReadingEvidenceId', sample.initialReading?.evidenceId),
    _field('finalOdometerUnits', sample.finalReading?.reading.odometerUnits),
    _field('finalNeedleLiters', sample.finalReading?.reading.needleLiters),
    _field('finalReadingSource', sample.finalReading?.source.name),
    _field('finalReadingEvidenceId', sample.finalReading?.evidenceId),
    if (sample.meterFaceConfiguration case final face?) ...[
      _field('meterFaceCanonicalVersion', 1),
      _field('totalizerLeft', face.totalizerLeft),
      _field('totalizerTop', face.totalizerTop),
      _field('totalizerWidth', face.totalizerWidth),
      _field('totalizerHeight', face.totalizerHeight),
      _field('dialCenterX', face.dialCenterX),
      _field('dialCenterY', face.dialCenterY),
      _field('dialRadius', face.dialRadius),
      _field('dialMultiplier', face.multiplier),
      _field('dialLitersPerRevolution', face.litersPerRevolution),
      _field('dialZeroAngleDegrees', face.zeroAngleDegrees),
      _field('dialClockwise', face.clockwise),
      _field('dialConfigurationSource', face.source.name),
      if (face.totalizerConfiguration case final totalizer?) ...[
        _field('totalizerFormatCanonicalVersion', 1),
        _field('totalizerDigitCount', totalizer.digitCount),
        _field('totalizerDecimalPlaces', totalizer.decimalPlaces),
        _field('totalizerUnit', totalizer.unit.name),
        _field('totalizerLeadingZerosAllowed', totalizer.leadingZerosAllowed),
        _field('totalizerConfigurationSource', totalizer.source.name),
      ],
    ],
    if (sample.pulseAcquisitionConfiguration case final acquisition?) ...[
      _field('pulseAcquisitionCanonicalVersion', 1),
      _field('bleDeviceId', acquisition.bleDeviceId),
      _field('bleDeviceName', acquisition.bleDeviceName),
      _field('bleServiceUuid', acquisition.bleServiceUuid),
      _field(
        'bleCounterCharacteristicUuid',
        acquisition.bleCounterCharacteristicUuid,
      ),
      _field('bleProtocolVersion', acquisition.bleProtocolVersion),
      _field('esp32CounterAtStart', acquisition.esp32CounterAtStart),
      _field('lastObservedEsp32Counter', acquisition.lastObservedEsp32Counter),
      _field('ledRoiLeft', acquisition.ledRoiLeft),
      _field('ledRoiTop', acquisition.ledRoiTop),
      _field('ledRoiWidth', acquisition.ledRoiWidth),
      _field('ledRoiHeight', acquisition.ledRoiHeight),
      _field('ledRisingDelta', acquisition.ledRisingDelta),
      _field('ledFallingDelta', acquisition.ledFallingDelta),
      _field('ledMinPulseIntervalMs', acquisition.ledMinPulseIntervalMs),
      _field('ledBaseline', acquisition.ledBaseline),
      _field('ledUsesBleReconciliation', acquisition.ledUsesBleReconciliation),
      _field(
        'acquisitionIntegrityStatus',
        sample.acquisitionIntegrity.status.name,
      ),
      _field('acquisitionIntegrityReason', sample.acquisitionIntegrity.reason),
      _field('acquisitionIntegrityAt', sample.acquisitionIntegrity.occurredAt),
      _field(
        'acquisitionIntegritySource',
        sample.acquisitionIntegrity.source?.name,
      ),
    ],
    _field('referenceLiters', referenceLiters),
    _field('indicatedLiters', indicatedLiters),
    _field('errorPct', errorPct),
    _field('uncertaintyPct', uncertaintyPct),
    _field('resultMpePct', mpePct),
    _field('acceptanceMetricPct', acceptanceMetricPct),
    _field('rejectionMetricPct', rejectionMetricPct),
    _field('verdict', verdict),
    for (final item in evidence) ...[
      _field('evidenceId', item.id),
      _field('evidenceType', item.type.name),
      _field('evidencePointId', item.pointId),
      _field('evidenceVolumeRefLiters', item.volumeRefLiters),
      _field('evidencePulseCount', item.pulseCount),
      _field('evidenceCapturedAt', item.capturedAt),
      _field('evidenceSha256', item.sha256),
    ],
  ];
  return sha256.convert(utf8.encode(fields.join())).toString();
}

int sampleCanonicalVersion(Sample sample) {
  final c = sample.configuration;
  return sample.isSimulation
      ? 6
      : c.controlStartMaximumLps.isFinite
      ? 5
      : sample.pulseAcquisitionConfiguration != null
      ? 4
      : sample.meterFaceConfiguration?.totalizerConfiguration != null
      ? 3
      : sample.meterFaceConfiguration == null
      ? 1
      : 2;
}

int caseCanonicalVersion(VerificationCase verificationCase) =>
    verificationCase.testBenchId.isNotEmpty ||
        verificationCase.deviceId != null ||
        verificationCase.androidVersion != null ||
        verificationCase.deviceBrand != null ||
        verificationCase.deviceModel != null
    ? 2
    : 1;

String calculateCaseChecksum({
  required VerificationCase verificationCase,
  required OverallVerdict verdict,
  required DateTime closedAt,
  required Set<String> requiredFlowCodes,
  required List<
    ({String id, String code, String status, List<String> sampleChecksums})
  >
  flows,
}) {
  final sortedFlows = [...flows]..sort((a, b) => a.code.compareTo(b.code));
  final sortedRequired = requiredFlowCodes.toList()..sort();
  final hasDeviceProvenance = caseCanonicalVersion(verificationCase) == 2;
  final fields = <String>[
    _field('canonicalVersion', hasDeviceProvenance ? 2 : 1),
    _field('caseId', verificationCase.id),
    _field('meterId', verificationCase.meterId),
    _field('userId', verificationCase.userId),
    _field('createdAt', verificationCase.createdAt),
    _field('closedAt', closedAt),
    _field('reportVersion', verificationCase.reportVersion),
    if (hasDeviceProvenance) ...[
      _field('testBenchId', verificationCase.testBenchId),
      _field('deviceId', verificationCase.deviceId),
      _field('androidVersion', verificationCase.androidVersion),
      _field('deviceBrand', verificationCase.deviceBrand),
      _field('deviceModel', verificationCase.deviceModel),
    ],
    _field('verdict', verdict.name),
    for (final code in sortedRequired) _field('requiredFlow', code),
    for (final flow in sortedFlows) ...[
      _field('flowId', flow.id),
      _field('flowCode', flow.code),
      _field('flowStatus', flow.status),
      for (final checksum in ([...flow.sampleChecksums]..sort()))
        _field('sampleChecksum', checksum),
    ],
  ];
  return sha256.convert(utf8.encode(fields.join())).toString();
}
