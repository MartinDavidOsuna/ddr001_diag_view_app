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
    _field('canonicalVersion', 1),
    _field('sampleId', sample.id),
    _field('flowPointId', sample.flowPointId),
    _field('sampleNumber', sample.sampleNumber),
    _field('measurementMethod', c.measurementMethod.name),
    _field('litersPerPulse', c.litersPerPulse),
    _field('evidenceStepLiters', c.evidenceStepLiters),
    _field('readingUncertaintyLiters', c.readingUncertaintyLiters),
    _field('flowPoint', c.flowPoint.name),
    _field('configuredMpePct', c.mpePct),
    _field('lpsApprox', c.lpsApprox),
    _field('litersPerOdometerUnit', c.litersPerOdometerUnit),
    _field('needleLitersPerRevolution', c.needleLitersPerRevolution),
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
    _field('finalOdometerUnits', sample.finalReading?.reading.odometerUnits),
    _field('finalNeedleLiters', sample.finalReading?.reading.needleLiters),
    _field('finalReadingSource', sample.finalReading?.source.name),
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
  final fields = <String>[
    _field('canonicalVersion', 1),
    _field('caseId', verificationCase.id),
    _field('meterId', verificationCase.meterId),
    _field('userId', verificationCase.userId),
    _field('createdAt', verificationCase.createdAt),
    _field('closedAt', closedAt),
    _field('reportVersion', verificationCase.reportVersion),
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
