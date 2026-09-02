import '../core/metrology/metrology.dart';

String normalizeEmail(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty || !normalized.contains('@')) {
    throw ArgumentError.value(value, 'email');
  }
  return normalized;
}

String normalizePhone(String value) {
  final trimmed = value.trim();
  final hasLeadingPlus = trimmed.startsWith('+');
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 7) throw ArgumentError.value(value, 'phone');
  return '${hasLeadingPlus ? '+' : ''}$digits';
}

String normalizeDisplayName(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, 'displayName');
  return normalized;
}

String? normalizeOptionalDisplayName(String? value) {
  if (value == null) return null;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

enum ExternalMeterStatus {
  foundWithSurvey,
  foundNoSurvey,
  notFound,
  unknownOffline,
}

enum VerificationCaseStatus { open, closed }

enum OverallVerdict { approved, rejected, inconclusive }

enum FlowRecordStatus { open, pass, fail, inconclusive }

enum SampleStatus { draft, running, invalidEvidence, closedValid }

enum SimulationScenario { successful, failed, failThenPass }

extension SimulationScenarioContract on SimulationScenario {
  String get contractName => switch (this) {
    SimulationScenario.successful => 'SUCCESSFUL',
    SimulationScenario.failed => 'FAILED',
    SimulationScenario.failThenPass => 'FAIL_THEN_PASS',
  };
}

enum ReadingSource { autoConfirmed, manual }

enum PointType { start, intermediate, finalPoint, manualDiagnostic }

enum EvidenceType { start, intermediate, finalEvidence, extra }

enum EvidenceSyncStatus { local, pending, syncing, synced, conflict, error }

enum SyncState { pending, inProgress, failed, synced }

final class User {
  User({
    required this.id,
    required String email,
    required String phone,
    required this.createdAt,
    String? displayName,
    this.lastLoginAt,
  }) : email = normalizeEmail(email),
       phone = normalizePhone(phone),
       displayName = normalizeOptionalDisplayName(displayName);

  final String id;
  final String email;
  final String phone;
  final String? displayName;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
}

final class Meter {
  Meter({
    required this.id,
    required this.externalStatus,
    required this.createdAt,
    this.externalSnapshotJson,
    this.externalCheckedAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt {
    if (id.trim().isEmpty) throw ArgumentError.value(id, 'id');
  }

  final String id;
  final ExternalMeterStatus externalStatus;
  final String? externalSnapshotJson;
  final DateTime? externalCheckedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

final class VerificationCase {
  const VerificationCase({
    required this.id,
    required this.meterId,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.reportVersion,
    this.testBenchId = '',
    this.deviceId,
    this.androidVersion,
    this.deviceBrand,
    this.deviceModel,
    this.overallVerdict,
    this.closedAt,
    this.checksum,
  });

  final String id;
  final String meterId;
  final String userId;
  final VerificationCaseStatus status;
  final OverallVerdict? overallVerdict;
  final DateTime createdAt;
  final DateTime? closedAt;
  final int reportVersion;
  final String testBenchId;
  final String? deviceId;
  final String? androidVersion;
  final String? deviceBrand;
  final String? deviceModel;
  final String? checksum;
}

final class DeviceMetadata {
  const DeviceMetadata({this.id, this.androidVersion, this.brand, this.model});

  final String? id;
  final String? androidVersion;
  final String? brand;
  final String? model;
}

final class PersistedFlowStatistics {
  const PersistedFlowStatistics({
    required this.n,
    required this.meanErrorPct,
    required this.minimumErrorPct,
    required this.maximumErrorPct,
    required this.dispersionPct,
    this.sampleStandardDeviationPct,
    required this.repeatabilityStatus,
  });

  final int n;
  final double meanErrorPct;
  final double minimumErrorPct;
  final double maximumErrorPct;
  final double dispersionPct;
  final double? sampleStandardDeviationPct;
  final RepeatabilityStatus repeatabilityStatus;
}

final class FlowPointRecord {
  const FlowPointRecord({
    required this.id,
    required this.caseId,
    required this.code,
    required this.mpePct,
    required this.status,
    required this.createdAt,
    this.lpsApprox,
    this.statistics,
  });

  final String id;
  final String caseId;
  final FlowPoint code;
  final double? lpsApprox;
  final double mpePct;
  final FlowRecordStatus status;
  final PersistedFlowStatistics? statistics;
  final DateTime createdAt;
}

final class GpsSnapshot {
  const GpsSnapshot({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime capturedAt;
}

final class SampleConfiguration {
  const SampleConfiguration({
    required this.measurementMethod,
    required this.litersPerPulse,
    required this.evidenceStepLiters,
    required this.readingUncertaintyLiters,
    required this.flowPoint,
    required this.mpePct,
    required this.litersPerOdometerUnit,
    required this.needleLitersPerRevolution,
    this.lpsApprox,
    this.minimumVolumeLiters,
    this.maximumVolumeLiters,
    this.controlStartMinimumLps = 0,
    this.controlStartMaximumLps = double.infinity,
    this.hydrantLitersPerPulse = 1,
    this.cameraZoomLevel = 1,
  });

  final MeasurementMethod measurementMethod;
  final double litersPerPulse;
  final double evidenceStepLiters;
  final double readingUncertaintyLiters;
  final FlowPoint flowPoint;
  final double mpePct;
  final double? lpsApprox;
  final double litersPerOdometerUnit;
  final double needleLitersPerRevolution;
  final double? minimumVolumeLiters;
  final double? maximumVolumeLiters;
  final double controlStartMinimumLps;
  final double controlStartMaximumLps;
  final double hydrantLitersPerPulse;
  final double cameraZoomLevel;
}

enum DialConfigurationSource { autoConfirmed, manual }

enum TotalizerUnit { cubicMeters }

final class TotalizerConfiguration {
  const TotalizerConfiguration({
    required this.digitCount,
    required this.decimalPlaces,
    this.unit = TotalizerUnit.cubicMeters,
    this.leadingZerosAllowed = true,
    this.source = DialConfigurationSource.manual,
  }) : assert(digitCount > 0),
       assert(decimalPlaces >= 0),
       assert(decimalPlaces < digitCount);

  final int digitCount;
  final int decimalPlaces;
  final TotalizerUnit unit;
  final bool leadingZerosAllowed;
  final DialConfigurationSource source;

  String get pattern {
    final integerDigits = digitCount - decimalPlaces;
    final integerPattern = List.filled(integerDigits, '#').join();
    final fractionPattern = List.filled(decimalPlaces, '#').join();
    return decimalPlaces == 0
        ? integerPattern
        : '$integerPattern.$fractionPattern';
  }
}

/// Geometry is normalized to the oriented full evidence image, never screen pixels.
final class MeterFaceConfiguration {
  const MeterFaceConfiguration({
    required this.totalizerLeft,
    required this.totalizerTop,
    required this.totalizerWidth,
    required this.totalizerHeight,
    required this.dialCenterX,
    required this.dialCenterY,
    required this.dialRadius,
    required this.multiplier,
    required this.litersPerRevolution,
    required this.zeroAngleDegrees,
    required this.clockwise,
    required this.source,
    this.totalizerConfiguration,
  });

  final double totalizerLeft;
  final double totalizerTop;
  final double totalizerWidth;
  final double totalizerHeight;
  final double dialCenterX;
  final double dialCenterY;
  final double dialRadius;
  final double multiplier;
  final double litersPerRevolution;
  final double zeroAngleDegrees;
  final bool clockwise;
  final DialConfigurationSource source;
  final TotalizerConfiguration? totalizerConfiguration;
}

final class ConfirmedReading {
  const ConfirmedReading({
    required this.reading,
    required this.source,
    this.evidenceId,
  });

  final MeterReading reading;
  final ReadingSource source;
  final String? evidenceId;
}

enum AcquisitionIntegrityStatus { ok, compromised }

final class AcquisitionIntegrity {
  const AcquisitionIntegrity({
    this.status = AcquisitionIntegrityStatus.ok,
    this.reason,
    this.occurredAt,
    this.source,
  });

  final AcquisitionIntegrityStatus status;
  final String? reason;
  final DateTime? occurredAt;
  final MeasurementMethod? source;
  bool get isCompromised => status == AcquisitionIntegrityStatus.compromised;
}

final class PulseAcquisitionConfiguration {
  const PulseAcquisitionConfiguration({
    this.bleDeviceId,
    this.bleDeviceName,
    this.bleServiceUuid,
    this.bleCounterCharacteristicUuid,
    this.bleProtocolVersion,
    this.esp32CounterAtStart,
    this.lastObservedEsp32Counter,
    this.ledRoiLeft,
    this.ledRoiTop,
    this.ledRoiWidth,
    this.ledRoiHeight,
    this.ledRisingDelta,
    this.ledFallingDelta,
    this.ledMinPulseIntervalMs,
    this.ledBaseline,
    this.ledUsesBleReconciliation = false,
  });

  final String? bleDeviceId;
  final String? bleDeviceName;
  final String? bleServiceUuid;
  final String? bleCounterCharacteristicUuid;
  final int? bleProtocolVersion;
  final int? esp32CounterAtStart;
  final int? lastObservedEsp32Counter;
  final double? ledRoiLeft;
  final double? ledRoiTop;
  final double? ledRoiWidth;
  final double? ledRoiHeight;
  final double? ledRisingDelta;
  final double? ledFallingDelta;
  final int? ledMinPulseIntervalMs;
  final double? ledBaseline;
  final bool ledUsesBleReconciliation;
}

final class Sample {
  const Sample({
    required this.id,
    required this.flowPointId,
    required this.sampleNumber,
    required this.status,
    required this.configuration,
    required this.createdAt,
    required this.updatedAt,
    required this.pulseCount,
    this.referenceLitersProgress,
    this.manualIndicatedLiters,
    this.startedAt,
    this.endedAt,
    this.gps,
    this.initialReading,
    this.finalReading,
    this.meterFaceConfiguration,
    this.pulseAcquisitionConfiguration,
    this.acquisitionIntegrity = const AcquisitionIntegrity(),
    this.result,
    this.checksum,
    this.simulationScenario,
  });

  final String id;
  final String flowPointId;
  final int sampleNumber;
  final SampleStatus status;
  final SampleConfiguration configuration;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final GpsSnapshot? gps;
  final int pulseCount;
  final double? referenceLitersProgress;

  /// Technician-entered Vind for the manual FINAL-only reading workflow.
  final double? manualIndicatedLiters;
  final ConfirmedReading? initialReading;
  final ConfirmedReading? finalReading;
  final MeterFaceConfiguration? meterFaceConfiguration;
  final PulseAcquisitionConfiguration? pulseAcquisitionConfiguration;
  final AcquisitionIntegrity acquisitionIntegrity;
  final SampleResult? result;
  final String? checksum;
  final SimulationScenario? simulationScenario;

  bool get isSimulation =>
      configuration.measurementMethod == MeasurementMethod.simulation;

  Sample start({required DateTime at, GpsSnapshot? gps}) {
    if (status != SampleStatus.draft) {
      throw StateError('Only a DRAFT sample can start.');
    }
    return _copy(status: SampleStatus.running, startedAt: at, gps: gps);
  }

  Sample markInvalidEvidence({required DateTime at}) {
    if (status != SampleStatus.running) {
      throw StateError('Only a RUNNING sample can become invalid.');
    }
    return _copy(status: SampleStatus.invalidEvidence, endedAt: at);
  }

  Sample _copy({
    required SampleStatus status,
    DateTime? startedAt,
    DateTime? endedAt,
    GpsSnapshot? gps,
  }) => Sample(
    id: id,
    flowPointId: flowPointId,
    sampleNumber: sampleNumber,
    status: status,
    configuration: configuration,
    createdAt: createdAt,
    updatedAt: endedAt ?? startedAt ?? updatedAt,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    gps: gps ?? this.gps,
    pulseCount: pulseCount,
    referenceLitersProgress: referenceLitersProgress,
    manualIndicatedLiters: manualIndicatedLiters,
    initialReading: initialReading,
    finalReading: finalReading,
    meterFaceConfiguration: meterFaceConfiguration,
    pulseAcquisitionConfiguration: pulseAcquisitionConfiguration,
    acquisitionIntegrity: acquisitionIntegrity,
    result: result,
    checksum: checksum,
    simulationScenario: simulationScenario,
  );
}

final class TestPoint {
  const TestPoint({
    required this.id,
    required this.sampleId,
    required this.type,
    required this.capturedAt,
    this.pulseCount,
    this.referenceLiters,
    this.readingLiters,
    this.indicatedLiters,
    this.diagnosticErrorPct,
    this.needleLiters,
    this.meterUnderTestPulseCount,
    this.flowLps,
  });

  final String id;
  final String sampleId;
  final PointType type;
  final int? pulseCount;
  final double? referenceLiters;
  final double? readingLiters;
  final double? indicatedLiters;
  final double? diagnosticErrorPct;
  final double? needleLiters;
  final int? meterUnderTestPulseCount;
  final double? flowLps;
  final DateTime capturedAt;
}

final class PointFlowStatistics {
  const PointFlowStatistics({
    required this.minimumLps,
    required this.maximumLps,
    required this.averageLps,
    required this.count,
  });

  final double minimumLps;
  final double maximumLps;
  final double averageLps;
  final int count;

  static PointFlowStatistics? fromPoints(Iterable<TestPoint> points) {
    final values = points
        .map((point) => point.flowLps)
        .whereType<double>()
        .where((value) => value.isFinite && value >= 0)
        .toList(growable: false);
    if (values.isEmpty) return null;
    return PointFlowStatistics(
      minimumLps: values.reduce((a, b) => a < b ? a : b),
      maximumLps: values.reduce((a, b) => a > b ? a : b),
      averageLps: values.reduce((a, b) => a + b) / values.length,
      count: values.length,
    );
  }
}

final class Evidence {
  const Evidence({
    required this.id,
    required this.sampleId,
    required this.type,
    required this.required,
    required this.capturedAt,
    required this.localPath,
    required this.syncStatus,
    this.pointId,
    this.volumeRefLiters,
    this.pulseCount,
    this.sha256,
    this.serverStorageKey,
  });

  final String id;
  final String sampleId;
  final String? pointId;
  final EvidenceType type;
  final bool required;
  final double? volumeRefLiters;
  final int? pulseCount;
  final DateTime capturedAt;
  final String? sha256;
  final String localPath;
  final String? serverStorageKey;
  final EvidenceSyncStatus syncStatus;
}

final class SyncItem {
  const SyncItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.checksum,
    required this.state,
    required this.attempts,
    required this.createdAt,
    required this.updatedAt,
    this.lastError,
    this.nextRetryAt,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String checksum;
  final SyncState state;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? nextRetryAt;
}
