import '../app/app_assets.dart';
import '../core/metrology/metrology.dart';
import '../domain/models.dart';

final class DemoSettings {
  DemoSettings([Map<String, num> values = const {}])
    : values = Map.unmodifiable({...defaults, ...values}) {
    for (final entry in this.values.entries) {
      if (!defaults.containsKey(entry.key) ||
          !entry.value.isFinite ||
          entry.value < 0 ||
          (entry.value == 0 &&
              !const [
                'uncertainty',
                'startMin',
                'decimals',
              ].contains(entry.key))) {
        throw ArgumentError('Configuración inválida: ${entry.key}');
      }
    }
    if (value('maximum') < value('minimum') ||
        value('startMax') < value('startMin') ||
        value('integers') != value('integers').roundToDouble() ||
        value('decimals') != value('decimals').roundToDouble() ||
        value('decimals') > 3) {
      throw ArgumentError('Revisa los rangos y el formato del odómetro.');
    }
  }

  static const defaults = <String, num>{
    'k': 1,
    'step': 25,
    'uncertainty': 1,
    'minimum': 100,
    'maximum': 300,
    'startMin': .5,
    'startMax': 50,
    'hydrantK': 1,
    'odometerScale': 1000,
    'needleScale': 100,
    'integers': 5,
    'decimals': 0,
  };
  final Map<String, num> values;
  double value(String key) => values[key]!.toDouble();

  SampleConfiguration configuration(FlowPoint flow) => SampleConfiguration(
    measurementMethod: MeasurementMethod.simulation,
    litersPerPulse: value('k'),
    evidenceStepLiters: value('step'),
    readingUncertaintyLiters: value('uncertainty'),
    flowPoint: flow,
    mpePct: 2,
    litersPerOdometerUnit: value('odometerScale'),
    needleLitersPerRevolution: value('needleScale'),
    minimumVolumeLiters: value('minimum'),
    maximumVolumeLiters: value('maximum'),
    controlStartMinimumLps: value('startMin'),
    controlStartMaximumLps: value('startMax'),
    hydrantLitersPerPulse: value('hydrantK'),
  );

  factory DemoSettings.fromJson(Object? json) =>
      DemoSettings(json == null ? const {} : (json as Map).cast<String, num>());
}

final class DemoEvidence {
  const DemoEvidence({
    required this.type,
    required this.volume,
    required this.pulses,
    required this.flowLps,
    required this.at,
    required this.hash,
    this.asset = AppAssets.demoMeterFace,
  });

  final EvidenceType type;
  final double volume;
  final int pulses;
  final double flowLps;
  final DateTime at;
  final String hash;
  final String asset;

  double hydrantLiters(DemoSettings settings) =>
      pulses * settings.value('hydrantK');

  double? diagnosticErrorPct(DemoSettings settings) =>
      volume <= 0 || pulses == 0
      ? null
      : (hydrantLiters(settings) - volume) / volume * 100;

  String get label => switch (type) {
    EvidenceType.start => 'INICIO',
    EvidenceType.intermediate => 'INTERMEDIA',
    EvidenceType.finalEvidence => 'FINAL',
    EvidenceType.extra => 'ADICIONAL',
  };

  Map<String, Object?> toJson() => {
    'type': type.name,
    'volume': volume,
    'pulses': pulses,
    'flowLps': flowLps,
    'at': at.toIso8601String(),
    'hash': hash,
    'asset': asset,
  };

  factory DemoEvidence.fromJson(Map<String, Object?> json) => DemoEvidence(
    type: EvidenceType.values.byName(json['type']! as String),
    volume: (json['volume']! as num).toDouble(),
    pulses: json['pulses']! as int,
    flowLps: (json['flowLps']! as num).toDouble(),
    at: DateTime.parse(json['at']! as String),
    hash: json['hash']! as String,
    asset: json['asset']! as String,
  );
}

PointFlowStatistics? demoPhotoStatistics(Iterable<DemoEvidence> photos) =>
    PointFlowStatistics.fromPoints(
      photos.map(
        (photo) => TestPoint(
          id: '',
          sampleId: '',
          type: PointType.intermediate,
          capturedAt: photo.at,
          flowLps: photo.flowLps,
        ),
      ),
    );
