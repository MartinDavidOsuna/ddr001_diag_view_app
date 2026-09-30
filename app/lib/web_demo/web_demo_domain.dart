import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/metrology/metrology.dart';
import '../app/app_assets.dart';
import '../domain/models.dart';
import '../domain/expected_evidence_plan.dart';
import '../domain/simulation/simulation_values.dart';
import 'web_demo_records.dart';
export 'web_demo_records.dart';

enum WebDemoPage {
  home,
  identification,
  method,
  setup,
  run,
  readings,
  result,
  summary,
  report,
  history,
  settings,
  manual,
  recovery,
}

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
    this.settings,
    this.photos = const [],
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
  final DemoSettings? settings;
  final List<DemoEvidence> photos;
  DemoSettings get configuration => settings ?? DemoSettings();
  double get initialReadingLiters =>
      initialTotalizer * configuration.value('odometerScale') + initialNeedle;
  double get finalReadingLiters =>
      finalTotalizer * configuration.value('odometerScale') + finalNeedle;
  SampleResult get result => SampleResult(
    referenceLiters: referenceLiters,
    indicatedLiters: indicatedLiters,
    errorPct: errorPct,
    uncertaintyPct: uncertaintyPct,
    mpePct: mpePct,
    verdict: verdict,
    decisionMetrics: const GuardBandDecisionRule()
        .evaluate(
          errorPct: errorPct,
          uncertaintyPct: uncertaintyPct,
          mpePct: mpePct,
        )
        .metrics,
  );

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
    'settings': configuration.values,
    'photos': photos.map((photo) => photo.toJson()).toList(),
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
    settings: DemoSettings.fromJson(json['settings']),
    photos: List.unmodifiable(
      ((json['photos'] as List?) ?? []).map(
        (photo) =>
            DemoEvidence.fromJson((photo as Map).cast<String, Object?>()),
      ),
    ),
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

  int sampleNumber(int index) => samples
      .take(index + 1)
      .where((sample) => sample.flowPoint == samples[index].flowPoint)
      .length;

  List<FlowPointResult> get flows => [
    for (final flow in [FlowPoint.q1, FlowPoint.q2])
      FlowPointResult.summarize(
        flowPoint: flow,
        samples: samples
            .where((sample) => sample.flowPoint == flow)
            .map((sample) => sample.result)
            .toList(),
        mpePct: 2,
      ),
  ];

  SampleVerdict get verdict =>
      flows.any((flow) => flow.status == FlowPointStatus.fail)
      ? SampleVerdict.fail
      : flows.every((flow) => flow.status == FlowPointStatus.pass)
      ? SampleVerdict.pass
      : SampleVerdict.inconclusive;

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
    final saved = await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode(cases.map((item) => item.toJson()).toList()),
    );
    if (!saved) throw StateError('No se pudo guardar el historial local.');
  }

  Future<void> clear() async {
    final cleared = await (await SharedPreferences.getInstance()).remove(_key);
    if (!cleared) throw StateError('No se pudo borrar el historial local.');
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
  final List<DemoEvidence> _photos = [];
  final Set<int> selectedSamples = {};
  WebDemoPage page = WebDemoPage.home;
  WebDemoPage _resumePage = WebDemoPage.run;
  FlowPoint flowPoint = FlowPoint.q1;
  String meterId = '';
  String testBenchId = '';
  String? error;
  DemoSettings settings = DemoSettings();
  DemoSettings _frozen = DemoSettings();
  double flowLps = 6;
  int pulseCount = 0;
  bool measurementStarted = false;
  bool hasDraft = false;
  bool caseClosed = false;
  DateTime? startedAt;
  DateTime? endedAt;
  Duration elapsed = Duration.zero;
  DemoSample? latestSample;
  DemoCase? selectedCase;
  Timer? _timer;
  SimulationFlowGenerator? _flowGenerator;
  double _pulseRemainder = 0;
  Duration _flowElapsed = Duration.zero;
  DateTime? _lastTick;
  String? _imageHash;
  String? _caseId;
  Future<void> _writes = Future.value();
  String? _persistenceError;
  bool _disposed = false;

  List<DemoEvidence> get photos => List.unmodifiable(_photos);
  List<DemoSample> get samples => List.unmodifiable(_currentSamples);
  DemoSettings get runSettings => _frozen;
  double get referenceLiters => pulseCount * _frozen.value('k');
  double get hydrantLiters => pulseCount * _frozen.value('hydrantK');
  double get hydrantFlowLps =>
      flowLps * _frozen.value('hydrantK') / _frozen.value('k');
  bool get indicatorsVisible => page == WebDemoPage.run;
  bool get canGoBack => !const [
    WebDemoPage.home,
    WebDemoPage.run,
    WebDemoPage.result,
    WebDemoPage.recovery,
  ].contains(page);
  DemoCase get currentCase => DemoCase(
    id: _caseId ?? 'DEMO-DRAFT',
    meterId: meterId,
    testBenchId: testBenchId,
    createdAt: _currentSamples.isEmpty
        ? DateTime.now()
        : _currentSamples.first.startedAt,
    samples: samples,
  );

  Future<void> initialize() async {
    final image = await rootBundle.load(AppAssets.demoMeterFace);
    _imageHash = sha256
        .convert(
          image.buffer.asUint8List(image.offsetInBytes, image.lengthInBytes),
        )
        .toString();
    history
      ..clear()
      ..addAll(await _store.load());
    final preferences = await SharedPreferences.getInstance();
    final savedSettings = preferences.getString('ddr001_web_demo_settings_v1');
    if (savedSettings != null) {
      settings = DemoSettings.fromJson(jsonDecode(savedSettings));
    }
    final draft = preferences.getString('ddr001_web_demo_draft_v1');
    if (draft != null) {
      final data = (jsonDecode(draft) as Map).cast<String, Object?>();
      _caseId = data['caseId'] as String?;
      if (!history.any((item) => item.id == _caseId)) {
        meterId = data['meter']! as String;
        testBenchId = data['bench']! as String;
        flowPoint = FlowPoint.values.byName(data['flow']! as String);
        _frozen = DemoSettings.fromJson(data['settings']);
        pulseCount = data['pulses']! as int;
        flowLps = (data['flowLps']! as num).toDouble();
        _pulseRemainder = (data['remainder']! as num).toDouble();
        elapsed = Duration(microseconds: data['elapsed']! as int);
        startedAt = data['startedAt'] == null
            ? null
            : DateTime.parse(data['startedAt']! as String);
        endedAt = data['endedAt'] == null
            ? null
            : DateTime.parse(data['endedAt']! as String);
        measurementStarted = data['running']! as bool;
        _resumePage = WebDemoPage.values.byName(data['page']! as String);
        _photos.addAll(
          (data['photos']! as List).map(
            (photo) =>
                DemoEvidence.fromJson((photo as Map).cast<String, Object?>()),
          ),
        );
        _currentSamples.addAll(
          (data['samples']! as List).map(
            (sample) =>
                DemoSample.fromJson((sample as Map).cast<String, Object?>()),
          ),
        );
        latestSample = _currentSamples.lastOrNull;
        hasDraft = true;
        page = WebDemoPage.recovery;
      }
    }
    if (!_disposed) notifyListeners();
  }

  void navigate(WebDemoPage destination) {
    page = destination;
    notifyListeners();
  }

  void goBack() => navigate(switch (page) {
    WebDemoPage.identification => WebDemoPage.home,
    WebDemoPage.method => WebDemoPage.identification,
    WebDemoPage.setup => WebDemoPage.method,
    WebDemoPage.readings => WebDemoPage.home,
    WebDemoPage.summary =>
      caseClosed ? WebDemoPage.history : WebDemoPage.result,
    WebDemoPage.report => WebDemoPage.summary,
    WebDemoPage.manual => WebDemoPage.settings,
    _ => WebDemoPage.home,
  });

  void startSetup() {
    if (hasDraft) {
      navigate(WebDemoPage.recovery);
      return;
    }
    meterId = '';
    testBenchId = '';
    navigate(WebDemoPage.identification);
  }

  void identify({required String meter, required String bench}) {
    if (meter.trim().isEmpty || bench.trim().isEmpty) {
      throw ArgumentError('Captura el medidor y el banco de pruebas.');
    }
    meterId = meter.trim();
    testBenchId = bench.trim();
    navigate(WebDemoPage.method);
  }

  Future<void> saveSettings(DemoSettings value) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      'ddr001_web_demo_settings_v1',
      jsonEncode(value.values),
    );
    if (!saved) throw StateError('No se pudieron guardar los ajustes.');
    settings = value;
    notifyListeners();
  }

  void beginCase({required String meter, required String bench}) {
    if (hasDraft) {
      throw StateError('Reanuda el expediente abierto antes de crear otro.');
    }
    if (meter.trim().isEmpty || bench.trim().isEmpty) {
      throw ArgumentError('Identificación obligatoria.');
    }
    meterId = meter.trim();
    testBenchId = bench.trim();
    _caseId = 'DEMO-${DateTime.now().microsecondsSinceEpoch}';
    _currentSamples.clear();
    selectedSamples.clear();
    selectedCase = null;
    caseClosed = false;
    hasDraft = true;
    _frozen = settings;
    flowPoint = FlowPoint.q1;
    _prepareRun();
  }

  void _prepareRun() {
    _stopTimer();
    pulseCount = 0;
    _pulseRemainder = 0;
    _flowElapsed = Duration.zero;
    elapsed = Duration.zero;
    startedAt = null;
    endedAt = null;
    measurementStarted = false;
    _photos.clear();
    error = null;
    _startTimer();
    page = WebDemoPage.run;
    _resumePage = page;
    _persistDraft();
    notifyListeners();
  }

  void _startTimer() {
    _flowGenerator = SimulationFlowGenerator(
      flowPoint: flowPoint,
      randomValue: _random.nextDouble,
    );
    flowLps = _flowGenerator!.next();
    _lastTick = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final now = DateTime.now();
      final delta = now.difference(_lastTick!);
      _lastTick = now;
      advanceSimulation(delta);
    });
  }

  void advanceSimulation(Duration delta) {
    if (endedAt != null || !hasDraft || delta <= Duration.zero) return;
    _flowElapsed += delta;
    if (_flowElapsed >= const Duration(seconds: 1)) {
      flowLps = _flowGenerator!.next();
      _flowElapsed = Duration.zero;
    }
    if (measurementStarted) {
      _pulseRemainder +=
          flowLps * delta.inMicroseconds / 1000000 / _frozen.value('k');
      final wholePulses = _pulseRemainder.floor();
      pulseCount += wholePulses;
      _pulseRemainder -= wholePulses;
      elapsed += delta;
      _captureIntermediates();
      _persistDraft();
    }
    notifyListeners();
  }

  void _capture(EvidenceType type, double volume, int pulses) {
    if (_imageHash == null) {
      throw StateError('La fotografía simulada no está disponible.');
    }
    _photos.add(
      DemoEvidence(
        type: type,
        volume: volume,
        pulses: pulses,
        flowLps: flowLps,
        at: DateTime.now(),
        hash: _imageHash!,
      ),
    );
  }

  void _captureIntermediates() {
    final step = _frozen.value('step');
    final lastVolume =
        _photos
            .where((photo) => photo.type == EvidenceType.intermediate)
            .lastOrNull
            ?.volume ??
        0;
    for (
      var volume = lastVolume + step;
      volume < referenceLiters - ExpectedEvidencePlan.comparisonEpsilon;
      volume += step
    ) {
      _capture(
        EvidenceType.intermediate,
        volume,
        (volume / _frozen.value('k')).ceil(),
      );
    }
  }

  void startMeasurement() {
    if (measurementStarted || endedAt != null || page != WebDemoPage.run) {
      return;
    }
    if (_imageHash == null) {
      throw StateError('Fotografía simulada no disponible.');
    }
    pulseCount = 0;
    _pulseRemainder = 0;
    elapsed = Duration.zero;
    startedAt = DateTime.now();
    _lastTick = startedAt;
    _capture(EvidenceType.start, 0, 0);
    measurementStarted = true;
    _persistDraft();
    notifyListeners();
  }

  void finishMeasurement() {
    if (!measurementStarted || pulseCount == 0) return;
    measurementStarted = false;
    endedAt = DateTime.now();
    _stopTimer();
    _capture(EvidenceType.finalEvidence, referenceLiters, pulseCount);
    page = WebDemoPage.readings;
    _resumePage = page;
    _persistDraft();
    notifyListeners();
  }

  Future<void> calculate({
    required double initialTotalizer,
    required double initialNeedle,
    required double finalTotalizer,
    required double finalNeedle,
  }) async {
    if (page != WebDemoPage.readings || endedAt == null) {
      throw StateError('Finaliza la adquisición antes de calcular.');
    }
    final plan = ExpectedEvidencePlan.derive(
      evidenceStepLiters: _frozen.value('step'),
      finalVolumeLiters: referenceLiters,
    );
    if (!plan.requirements.every(
      (required) => _photos.any(
        (photo) =>
            photo.type == required.type &&
            plan.volumeMatches(photo.volume, required.volumeRefLiters) &&
            photo.hash == _imageHash,
      ),
    )) {
      throw StateError('Evidencia incompleta. Debe repetirse la prueba.');
    }
    for (final value in [
      initialTotalizer,
      initialNeedle,
      finalTotalizer,
      finalNeedle,
    ]) {
      if (!value.isFinite || value < 0) throw ArgumentError('Valor inválido.');
    }
    final scale = _frozen.value('odometerScale');
    final indicated = calculateDirectReadingAdvance(
      initial: MeterReading(
        odometerUnits: initialTotalizer,
        needleLiters: initialNeedle,
        litersPerOdometerUnit: scale,
      ),
      finalReading: MeterReading(
        odometerUnits: finalTotalizer,
        needleLiters: finalNeedle,
        litersPerOdometerUnit: scale,
      ),
    );
    final result =
        MetrologyEngine(
          uncertaintyPolicy: ReadingUncertaintyPolicy(
            readingUncertaintyLiters: _frozen.value('uncertainty'),
          ),
        ).evaluate(
          flowPoint: flowPoint,
          referenceLiters: referenceLiters,
          indicatedLiters: indicated,
        );
    final readings = _photos.map((photo) => photo.flowLps).toList();
    latestSample = DemoSample(
      flowPoint: flowPoint,
      startedAt: startedAt!,
      endedAt: endedAt!,
      pulseCount: pulseCount,
      referenceLiters: referenceLiters,
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
      averageFlowLps:
          readings.reduce((previous, value) => previous + value) /
          readings.length,
      evidence: List.unmodifiable(_photos.map((photo) => photo.label)),
      photos: photos,
      settings: _frozen,
    );
    final previousSample = _currentSamples.lastOrNull;
    _currentSamples.add(latestSample!);
    selectedSamples.add(_currentSamples.length - 1);
    page = WebDemoPage.result;
    _resumePage = page;
    _persistDraft();
    try {
      await flush();
    } catch (_) {
      _currentSamples.removeLast();
      selectedSamples.remove(_currentSamples.length);
      latestSample = previousSample;
      page = WebDemoPage.readings;
      _resumePage = page;
      notifyListeners();
      rethrow;
    }
    notifyListeners();
  }

  void repeatSample() {
    if (caseClosed || !hasDraft) return;
    _prepareRun();
  }

  void startQ2() {
    if (caseClosed || latestSample == null) return;
    flowPoint = FlowPoint.q2;
    _prepareRun();
  }

  void showSummary() {
    if (!caseClosed) selectedCase = currentCase;
    selectedSamples
      ..clear()
      ..addAll(List.generate(selectedCase!.samples.length, (index) => index));
    navigate(WebDemoPage.summary);
  }

  void toggleSample(int index, bool selected) {
    if (selected) {
      selectedSamples.add(index);
    } else {
      selectedSamples.remove(index);
    }
    notifyListeners();
  }

  Future<void> finishCase() async {
    if (caseClosed) return;
    if (measurementStarted ||
        page == WebDemoPage.readings ||
        _currentSamples.isEmpty) {
      throw StateError('Termina la prueba antes de cerrar el expediente.');
    }
    final item = currentCase;
    final updated = [item, ...history];
    await _store.save(updated);
    history
      ..clear()
      ..addAll(updated);
    selectedCase = item;
    caseClosed = true;
    hasDraft = false;
    await flush();
    await (await SharedPreferences.getInstance()).remove(
      'ddr001_web_demo_draft_v1',
    );
    selectedSamples
      ..clear()
      ..addAll(List.generate(item.samples.length, (index) => index));
    page = WebDemoPage.summary;
    notifyListeners();
  }

  void openReport(DemoCase item) {
    selectedCase = item;
    caseClosed = true;
    selectedSamples
      ..clear()
      ..addAll(List.generate(item.samples.length, (index) => index));
    navigate(WebDemoPage.summary);
  }

  void showHistory() => navigate(WebDemoPage.history);

  void pauseToHome() {
    _stopTimer();
    _resumePage = page;
    _persistDraft();
    navigate(WebDemoPage.home);
  }

  void resume() {
    if (!hasDraft) return;
    caseClosed = false;
    if (_resumePage == WebDemoPage.run) _startTimer();
    navigate(_resumePage);
  }

  void _persistDraft() {
    if (!hasDraft) return;
    final encoded = jsonEncode({
      'caseId': _caseId,
      'meter': meterId,
      'bench': testBenchId,
      'flow': flowPoint.name,
      'settings': _frozen.values,
      'pulses': pulseCount,
      'remainder': _pulseRemainder,
      'flowLps': flowLps,
      'elapsed': elapsed.inMicroseconds,
      'running': measurementStarted,
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'page': _resumePage.name,
      'photos': _photos.map((photo) => photo.toJson()).toList(),
      'samples': _currentSamples.map((sample) => sample.toJson()).toList(),
    });
    _writes = _writes
        .then((_) async {
          final saved = await (await SharedPreferences.getInstance()).setString(
            'ddr001_web_demo_draft_v1',
            encoded,
          );
          if (!saved) throw StateError('Almacenamiento local no disponible.');
          _persistenceError = null;
          error = null;
        })
        .catchError((Object failure) {
          error = 'No fue posible guardar el avance local: $failure';
          _persistenceError = error;
          if (!_disposed) notifyListeners();
        });
  }

  Future<void> flush() async {
    await _writes;
    if (_persistenceError != null) throw StateError(_persistenceError!);
  }

  Future<void> clearHistory() async {
    await _store.clear();
    history.clear();
    if (!hasDraft) {
      selectedCase = null;
      latestSample = null;
      _currentSamples.clear();
    }
    navigate(WebDemoPage.history);
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTimer();
    super.dispose();
  }
}
