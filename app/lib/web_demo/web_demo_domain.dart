import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/metrology/metrology.dart';
import '../domain/simulation/simulation_values.dart';

enum WebDemoPage { home, setup, run, readings, result, report }

final class DemoSample {
  const DemoSample({
    required this.flowPoint,
    required this.startedAt,
    required this.endedAt,
    required this.pulseCount,
    required this.referenceLiters,
    required this.initialTotalizer,
    required this.initialNeedle,
    required this.finalTotalizer,
    required this.finalNeedle,
    required this.indicatedLiters,
    required this.errorPct,
    required this.uncertaintyPct,
    required this.mpePct,
    required this.verdict,
    required this.minimumFlowLps,
    required this.maximumFlowLps,
    required this.averageFlowLps,
    required this.evidence,
  });

  final FlowPoint flowPoint;
  final DateTime startedAt;
  final DateTime endedAt;
  final int pulseCount;
  final double referenceLiters;
  final double initialTotalizer;
  final double initialNeedle;
  final double finalTotalizer;
  final double finalNeedle;
  final double indicatedLiters;
  final double errorPct;
  final double uncertaintyPct;
  final double mpePct;
  final SampleVerdict verdict;
  final double minimumFlowLps;
  final double maximumFlowLps;
  final double averageFlowLps;
  final List<String> evidence;

  Map<String, Object?> toJson() => {
    'flowPoint': flowPoint.name,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'pulseCount': pulseCount,
    'referenceLiters': referenceLiters,
    'initialTotalizer': initialTotalizer,
    'initialNeedle': initialNeedle,
    'finalTotalizer': finalTotalizer,
    'finalNeedle': finalNeedle,
    'indicatedLiters': indicatedLiters,
    'errorPct': errorPct,
    'uncertaintyPct': uncertaintyPct,
    'mpePct': mpePct,
    'verdict': verdict.name,
    'minimumFlowLps': minimumFlowLps,
    'maximumFlowLps': maximumFlowLps,
    'averageFlowLps': averageFlowLps,
    'evidence': evidence,
  };

  factory DemoSample.fromJson(Map<String, Object?> json) => DemoSample(
    flowPoint: FlowPoint.values.byName(json['flowPoint']! as String),
    startedAt: DateTime.parse(json['startedAt']! as String),
    endedAt: DateTime.parse(json['endedAt']! as String),
    pulseCount: json['pulseCount']! as int,
    referenceLiters: (json['referenceLiters']! as num).toDouble(),
    initialTotalizer: (json['initialTotalizer']! as num).toDouble(),
    initialNeedle: (json['initialNeedle']! as num).toDouble(),
    finalTotalizer: (json['finalTotalizer']! as num).toDouble(),
    finalNeedle: (json['finalNeedle']! as num).toDouble(),
    indicatedLiters: (json['indicatedLiters']! as num).toDouble(),
    errorPct: (json['errorPct']! as num).toDouble(),
    uncertaintyPct: (json['uncertaintyPct']! as num).toDouble(),
    mpePct: (json['mpePct']! as num).toDouble(),
    verdict: SampleVerdict.values.byName(json['verdict']! as String),
    minimumFlowLps: (json['minimumFlowLps']! as num).toDouble(),
    maximumFlowLps: (json['maximumFlowLps']! as num).toDouble(),
    averageFlowLps: (json['averageFlowLps']! as num).toDouble(),
    evidence: (json['evidence']! as List).cast<String>(),
  );
}

final class DemoCase {
  const DemoCase({
    required this.id,
    required this.meterId,
    required this.testBenchId,
    required this.createdAt,
    required this.samples,
  });

  final String id;
  final String meterId;
  final String testBenchId;
  final DateTime createdAt;
  final List<DemoSample> samples;

  SampleVerdict get verdict =>
      samples.any((s) => s.verdict == SampleVerdict.fail)
      ? SampleVerdict.fail
      : samples.any((s) => s.verdict == SampleVerdict.inconclusive)
      ? SampleVerdict.inconclusive
      : SampleVerdict.pass;

  Map<String, Object?> toJson() => {
    'id': id,
    'meterId': meterId,
    'testBenchId': testBenchId,
    'createdAt': createdAt.toIso8601String(),
    'samples': samples.map((item) => item.toJson()).toList(),
  };

  factory DemoCase.fromJson(Map<String, Object?> json) => DemoCase(
    id: json['id']! as String,
    meterId: json['meterId']! as String,
    testBenchId: json['testBenchId']! as String,
    createdAt: DateTime.parse(json['createdAt']! as String),
    samples: (json['samples']! as List)
        .map(
          (item) => DemoSample.fromJson((item as Map).cast<String, Object?>()),
        )
        .toList(),
  );
}

final class WebDemoStore {
  static const _key = 'ddr001_web_demo_cases_v1';

  Future<List<DemoCase>> load() async {
    final encoded = (await SharedPreferences.getInstance()).getString(_key);
    if (encoded == null) return [];
    final items = jsonDecode(encoded) as List;
    return items
        .map((item) => DemoCase.fromJson((item as Map).cast<String, Object?>()))
        .toList();
  }

  Future<void> save(List<DemoCase> cases) async {
    await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode(cases.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    await (await SharedPreferences.getInstance()).remove(_key);
  }
}

final class WebDemoController extends ChangeNotifier {
  WebDemoController({WebDemoStore? store, Random? random})
    : _store = store ?? WebDemoStore(),
      _random = random ?? Random();

  final WebDemoStore _store;
  final Random _random;
  final List<DemoCase> history = [];
  final List<DemoSample> _currentSamples = [];
  WebDemoPage page = WebDemoPage.home;
  FlowPoint flowPoint = FlowPoint.q1;
  String meterId = '';
  String testBenchId = '';
  double flowLps = 6;
  int pulseCount = 0;
  bool measurementStarted = false;
  DateTime? startedAt;
  Duration elapsed = Duration.zero;
  DemoSample? latestSample;
  DemoCase? selectedCase;
  Timer? _timer;
  late SimulationFlowGenerator _flowGenerator;
  final List<double> _flowReadings = [];
  double _pulseRemainder = 0;
  DateTime? _lastTick;

  Future<void> initialize() async {
    history
      ..clear()
      ..addAll(await _store.load());
    notifyListeners();
  }

  void startSetup() {
    _stopTimer();
    page = WebDemoPage.setup;
    notifyListeners();
  }

  void beginCase({required String meter, required String bench}) {
    meterId = meter.trim().isEmpty ? 'DEMO-0001' : meter.trim();
    testBenchId = bench.trim().isEmpty ? 'BANCO-DEMO' : bench.trim();
    _currentSamples.clear();
    flowPoint = FlowPoint.q1;
    _prepareRun();
  }

  void _prepareRun() {
    _stopTimer();
    pulseCount = 0;
    _pulseRemainder = 0;
    elapsed = Duration.zero;
    startedAt = null;
    measurementStarted = false;
    _flowReadings.clear();
    _flowGenerator = SimulationFlowGenerator(
      flowPoint: flowPoint,
      randomValue: _random.nextDouble,
    );
    flowLps = _flowGenerator.next();
    page = WebDemoPage.run;
    _lastTick = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 250), _tick);
    notifyListeners();
  }

  void _tick(Timer _) {
    final now = DateTime.now();
    final previous = _lastTick ?? now;
    _lastTick = now;
    final seconds = now.difference(previous).inMicroseconds / 1000000;
    if (now.millisecond < 300) flowLps = _flowGenerator.next();
    if (measurementStarted) {
      _pulseRemainder += flowLps * seconds;
      final wholePulses = _pulseRemainder.floor();
      if (wholePulses > 0) {
        pulseCount += wholePulses;
        _pulseRemainder -= wholePulses;
      }
      _flowReadings.add(flowLps);
      elapsed = now.difference(startedAt!);
    }
    notifyListeners();
  }

  void startMeasurement() {
    if (measurementStarted) return;
    pulseCount = 0;
    _pulseRemainder = 0;
    _flowReadings.clear();
    startedAt = DateTime.now();
    _lastTick = startedAt;
    measurementStarted = true;
    notifyListeners();
  }

  void finishMeasurement() {
    if (!measurementStarted || pulseCount == 0) return;
    measurementStarted = false;
    _stopTimer();
    page = WebDemoPage.readings;
    notifyListeners();
  }

  Future<void> calculate({
    required double initialTotalizer,
    required double initialNeedle,
    required double finalTotalizer,
    required double finalNeedle,
  }) async {
    final initial = MeterReading(
      odometerUnits: initialTotalizer,
      needleLiters: initialNeedle,
      litersPerOdometerUnit: 1000,
    );
    final finalReading = MeterReading(
      odometerUnits: finalTotalizer,
      needleLiters: finalNeedle,
      litersPerOdometerUnit: 1000,
    );
    final indicated = calculateDirectReadingAdvance(
      initial: initial,
      finalReading: finalReading,
    );
    final result = const MetrologyEngine().evaluate(
      flowPoint: flowPoint,
      referenceLiters: pulseCount.toDouble(),
      indicatedLiters: indicated,
    );
    final ended = DateTime.now();
    final readings = _flowReadings.isEmpty ? [flowLps] : _flowReadings;
    final evidence = <String>['START'];
    for (var volume = 25; volume < pulseCount; volume += 25) {
      evidence.add('INTERMEDIATE $volume L');
    }
    evidence.add('FINAL');
    latestSample = DemoSample(
      flowPoint: flowPoint,
      startedAt: startedAt!,
      endedAt: ended,
      pulseCount: pulseCount,
      referenceLiters: pulseCount.toDouble(),
      initialTotalizer: initialTotalizer,
      initialNeedle: initialNeedle,
      finalTotalizer: finalTotalizer,
      finalNeedle: finalNeedle,
      indicatedLiters: result.indicatedLiters,
      errorPct: result.errorPct,
      uncertaintyPct: result.uncertaintyPct,
      mpePct: result.mpePct,
      verdict: result.verdict,
      minimumFlowLps: readings.reduce(min),
      maximumFlowLps: readings.reduce(max),
      averageFlowLps: readings.reduce((a, b) => a + b) / readings.length,
      evidence: evidence,
    );
    _currentSamples.add(latestSample!);
    page = WebDemoPage.result;
    notifyListeners();
  }

  void startQ2() {
    flowPoint = FlowPoint.q2;
    _prepareRun();
  }

  Future<void> finishCase() async {
    final item = DemoCase(
      id: 'DEMO-${DateTime.now().microsecondsSinceEpoch}',
      meterId: meterId,
      testBenchId: testBenchId,
      createdAt: _currentSamples.first.startedAt,
      samples: List.unmodifiable(_currentSamples),
    );
    history.insert(0, item);
    selectedCase = item;
    await _store.save(history);
    page = WebDemoPage.report;
    notifyListeners();
  }

  void openReport(DemoCase item) {
    selectedCase = item;
    page = WebDemoPage.report;
    notifyListeners();
  }

  void showHistory() {
    _stopTimer();
    page = WebDemoPage.home;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _stopTimer();
    history.clear();
    _currentSamples.clear();
    latestSample = null;
    selectedCase = null;
    await _store.clear();
    page = WebDemoPage.home;
    notifyListeners();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
