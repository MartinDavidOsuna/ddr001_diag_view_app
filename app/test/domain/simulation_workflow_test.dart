import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:ddr001_diag_view_app/domain/pulse/pulse_progress_service.dart';
import 'package:ddr001_diag_view_app/domain/pulse/pulse_source.dart';
import 'package:ddr001_diag_view_app/domain/simulation/simulation_values.dart';
import 'package:ddr001_diag_view_app/domain/simulation/simulation_workflow_service.dart';
import 'package:ddr001_diag_view_app/infrastructure/export/case_export_service.dart';
import 'package:ddr001_diag_view_app/infrastructure/simulation/simulation_evidence_capture.dart';
import 'package:ddr001_diag_view_app/presentation/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/presentation_fixture.dart';

void main() {
  late PresentationFixture fixture;
  late SimulationWorkflowService simulation;

  setUp(() async {
    fixture = await PresentationFixture.create();
    simulation = _fastSimulation(fixture);
  });

  tearDown(() => fixture.dispose());

  test('bundled simulation Evidence placeholder exists physically', () async {
    final placeholder = File(SimulationEvidenceCaptureAdapter.assetPath);
    expect(await placeholder.exists(), isTrue);
    final bytes = await placeholder.readAsBytes();
    expect(bytes.length, greaterThan(1000));
    expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
  });

  test(
    'successful needs no BLE/backend and uses real engine and Evidence',
    () async {
      expect(fixture.dependencies.bleDiscovery, isNull);
      expect(fixture.dependencies.remoteApi, isNull);
      expect(fixture.dependencies.camera, isNull);
      final sample = await _runningSimulation(
        fixture,
        SimulationScenario.successful,
      );
      final closed = await simulation.run(
        caseId: 'case-simulation',
        runningSample: sample,
        shouldPass: true,
      );

      expect(closed.result?.verdict, SampleVerdict.pass);
      expect(closed.result?.errorPct, closeTo(.5, 1e-9));
      final evidence = await fixture.dependencies.evidence.listBySample(
        closed.id,
      );
      expect(evidence.map((item) => item.type), [
        EvidenceType.start,
        EvidenceType.intermediate,
        EvidenceType.intermediate,
        EvidenceType.intermediate,
        EvidenceType.finalEvidence,
      ]);
      for (final item in evidence) {
        expect(await File(item.localPath).exists(), isTrue);
        expect(
          await fixture.dependencies.fileStore.verify(
            item.localPath,
            item.sha256!,
          ),
          isTrue,
        );
      }
      expect(closed.checksum, hasLength(64));
    },
  );

  test('failed uses real guard-band engine and rejects', () async {
    final sample = await _runningSimulation(fixture, SimulationScenario.failed);
    final closed = await simulation.run(
      caseId: 'case-simulation',
      runningSample: sample,
      shouldPass: false,
    );

    expect(closed.result?.verdict, SampleVerdict.fail);
    expect(closed.result!.errorPct, greaterThan(closed.result!.mpePct));
  });

  test(
    'mixed controller preserves failed Sample then creates passing Sample',
    () async {
      final controller = AppController(
        fixture.dependencies.copyWith(simulationWorkflow: simulation),
      );
      await controller.login('QA Simulación', 'qa@aquafim.mx', '4491234567');
      await controller.identifyMeter(
        meterId: 'SIM-MIXED',
        testBenchId: 'SIMULATION',
      );
      controller.selectMethod(MeasurementMethod.simulation);
      controller.selectSimulationScenario(SimulationScenario.failThenPass);

      await controller.startSample();

      final samples = await fixture.dependencies.samples.listByFlow(
        controller.state.flow!.id,
      );
      expect(samples, hasLength(2));
      expect(samples[0].result?.verdict, SampleVerdict.fail);
      expect(samples[1].result?.verdict, SampleVerdict.pass);
      expect(samples.every((sample) => sample.isSimulation), isTrue);
      expect(
        samples.every(
          (sample) =>
              sample.simulationScenario == SimulationScenario.failThenPass,
        ),
        isTrue,
      );
      expect(controller.state.page, AppPage.result);
      expect(controller.state.selectedBleDevice, isNull);
      expect(controller.state.hardwareState, HardwareState.notConnected);
      expect(controller.dependencies.backendSyncConfigured, isFalse);

      final bundle = await _bundle(fixture, samples);
      final output = Directory('${fixture.directory.path}/mixed-exports');
      final exported = await CaseExportService(
        outputDirectory: output,
      ).export(bundle);
      final csv = await File(exported.csvPath).readAsString();
      final json =
          jsonDecode(await File(exported.jsonPath).readAsString()) as Map;
      expect(csv, contains('FAIL_THEN_PASS'));
      expect(RegExp(r'true,FAIL_THEN_PASS').allMatches(csv), hasLength(10));
      final exportedSamples =
          ((((json['flow_points'] as List).first as Map)['samples']) as List);
      expect(exportedSamples, hasLength(2));
      expect(
        exportedSamples.map((item) => (item as Map)['result']['verdict']),
        ['RECHAZA', 'APRUEBA'],
      );
    },
  );

  test('simulation export uses real CSV JSON HTML PDF generators', () async {
    final sample = await _runningSimulation(
      fixture,
      SimulationScenario.successful,
    );
    final closed = await simulation.run(
      caseId: 'case-simulation',
      runningSample: sample,
      shouldPass: true,
    );
    final bundle = await _bundle(fixture, [closed]);
    final output = Directory('${fixture.directory.path}/exports');
    final exported = await CaseExportService(
      outputDirectory: output,
    ).export(bundle);
    final csv = await File(exported.csvPath).readAsString();
    final json =
        jsonDecode(await File(exported.jsonPath).readAsString()) as Map;
    final html = await File(exported.htmlPath).readAsString();
    final pdf = await File(exported.pdfPath).readAsBytes();

    expect(csv, contains('is_simulation,simulation_scenario'));
    expect(csv, contains('true,SUCCESSFUL'));
    expect(json['schema'], 'ddr001.verification.export/v2');
    final sampleJson =
        ((json['flow_points'] as List).single as Map)['samples'] as List;
    expect((sampleJson.single as Map)['is_simulation'], isTrue);
    expect(html, contains('PRUEBA SIMULADA'));
    expect(html, contains('data:image/png;base64,'));
    expect(pdf.take(4), '%PDF'.codeUnits);
    expect(pdf.length, greaterThan(1000));
  });

  test(
    'successful completes Q1 and Q2 and real case closure approves',
    () async {
      final controller = AppController(
        fixture.dependencies.copyWith(simulationWorkflow: simulation),
      );
      await controller.login('QA Global', 'global@aquafim.mx', '4497654321');
      await controller.identifyMeter(
        meterId: 'SIM-GLOBAL',
        testBenchId: 'SIMULATION',
      );
      controller.selectMethod(MeasurementMethod.simulation);
      controller.selectSimulationScenario(SimulationScenario.successful);

      await controller.startSample();
      expect(controller.state.sample?.configuration.flowPoint, FlowPoint.q1);
      expect(controller.state.sample?.result?.verdict, SampleVerdict.pass);
      await controller.anotherSample();
      expect(controller.state.flow?.code, FlowPoint.q2);
      await controller.startSample();
      expect(controller.state.sample?.result?.verdict, SampleVerdict.pass);
      await controller.showCaseSummary();
      await controller.closeCase();

      expect(
        controller.state.activeCase?.status,
        VerificationCaseStatus.closed,
      );
      expect(
        controller.state.activeCase?.overallVerdict,
        OverallVerdict.approved,
      );
    },
  );

  test(
    'Q-specific generator is deterministic and does not reuse one flow',
    () async {
      final q1 = await _runningSimulation(
        fixture,
        SimulationScenario.successful,
      );
      final q1Values = SimulationValues.forSample(sample: q1, shouldPass: true);
      final q2 = Sample(
        id: 'q2',
        flowPointId: q1.flowPointId,
        sampleNumber: 2,
        status: SampleStatus.running,
        configuration: SampleConfiguration(
          measurementMethod: MeasurementMethod.simulation,
          litersPerPulse: 1,
          evidenceStepLiters: 25,
          readingUncertaintyLiters: .1,
          flowPoint: FlowPoint.q2,
          mpePct: 2,
          litersPerOdometerUnit: 1000,
          needleLitersPerRevolution: 100,
        ),
        createdAt: DateTime.utc(2026, 9, 1),
        updatedAt: DateTime.utc(2026, 9, 1),
        pulseCount: 0,
        simulationScenario: SimulationScenario.successful,
      );
      final q2Values = SimulationValues.forSample(sample: q2, shouldPass: true);
      expect(q1Values.flowLps, 1.5);
      expect(q2Values.flowLps, 1.0);
      expect(q1Values.indicatedLiters, q2Values.indicatedLiters);
    },
  );

  test(
    'RUNNING simulation scenario and progress recover from SQLite',
    () async {
      final sample = await _runningSimulation(
        fixture,
        SimulationScenario.failed,
      );
      await fixture.dependencies.pulseProgress.acceptPulse(
        sample.id,
        PulseEvent(
          id: 'recovery-1',
          source: PulseSourceType.simulation,
          occurredAt: DateTime.utc(2026, 9, 1),
          receivedAt: DateTime.utc(2026, 9, 1),
          sequence: 1,
        ),
      );

      final recovered =
          (await fixture.dependencies.samples.listIncomplete()).single;
      expect(recovered.status, SampleStatus.running);
      expect(recovered.pulseCount, 1);
      expect(recovered.simulationScenario, SimulationScenario.failed);
      final closed = await simulation.run(
        caseId: 'case-simulation',
        runningSample: recovered,
        shouldPass: false,
      );
      expect(closed.status, SampleStatus.closedValid);
      expect(closed.result?.verdict, SampleVerdict.fail);
    },
  );
}

SimulationWorkflowService _fastSimulation(PresentationFixture fixture) {
  final capture = SimulationEvidenceCaptureAdapter(
    fixture.dependencies.fileStore,
    fixture.dependencies.evidence,
    loadPlaceholder: () async => Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    ),
  );
  return SimulationWorkflowService(
    samples: fixture.dependencies.samples,
    points: fixture.dependencies.points,
    evidence: fixture.dependencies.evidence,
    pulseProgress: PulseProgressService(fixture.dependencies.samples),
    sampleClosure: fixture.dependencies.sampleClosure,
    simulationEvidence: capture,
    pulseInterval: Duration.zero,
  );
}

Future<Sample> _runningSimulation(
  PresentationFixture fixture,
  SimulationScenario scenario,
) async {
  final at = DateTime.utc(2026, 9, 1);
  await fixture.dependencies.users.save(
    User(
      id: 'user-simulation',
      email: 'simulation@aquafim.mx',
      phone: '4491234567',
      displayName: 'QA Simulación',
      createdAt: at,
    ),
  );
  await fixture.dependencies.meters.save(
    Meter(
      id: 'meter-simulation',
      externalStatus: ExternalMeterStatus.unknownOffline,
      createdAt: at,
    ),
  );
  if (await fixture.dependencies.cases.getById('case-simulation') == null) {
    await fixture.dependencies.cases.create(
      VerificationCase(
        id: 'case-simulation',
        meterId: 'meter-simulation',
        userId: 'user-simulation',
        status: VerificationCaseStatus.open,
        createdAt: at,
        reportVersion: 1,
        testBenchId: 'SIMULATION',
      ),
    );
    await fixture.dependencies.flows.create(
      FlowPointRecord(
        id: 'flow-simulation',
        caseId: 'case-simulation',
        code: FlowPoint.q1,
        mpePct: 2,
        status: FlowRecordStatus.open,
        createdAt: at,
      ),
    );
  }
  final draft = Sample(
    id: 'sample-${scenario.name}',
    flowPointId: 'flow-simulation',
    sampleNumber:
        (await fixture.dependencies.samples.listByFlow(
          'flow-simulation',
        )).length +
        1,
    status: SampleStatus.draft,
    configuration: const SampleConfiguration(
      measurementMethod: MeasurementMethod.simulation,
      litersPerPulse: 1,
      evidenceStepLiters: 25,
      readingUncertaintyLiters: .1,
      flowPoint: FlowPoint.q1,
      mpePct: 2,
      litersPerOdometerUnit: 1000,
      needleLitersPerRevolution: 100,
      minimumVolumeLiters: 100,
      maximumVolumeLiters: 300,
    ),
    createdAt: at,
    updatedAt: at,
    pulseCount: 0,
    simulationScenario: scenario,
  );
  await fixture.dependencies.samples.createDraft(draft);
  return fixture.dependencies.samples.start(draft.id, at: at);
}

Future<CaseExportBundle> _bundle(
  PresentationFixture fixture,
  List<Sample> samples,
) async {
  final flow = (await fixture.dependencies.flows.getById(
    samples.first.flowPointId,
  ))!;
  final verificationCase = (await fixture.dependencies.cases.getById(
    flow.caseId,
  ))!;
  final points = <String, List<TestPoint>>{};
  final evidence = <String, List<Evidence>>{};
  for (final sample in samples) {
    points[sample.id] = await fixture.dependencies.points.listBySample(
      sample.id,
    );
    evidence[sample.id] = await fixture.dependencies.evidence.listBySample(
      sample.id,
    );
  }
  return CaseExportBundle(
    user: (await fixture.dependencies.users.getById(verificationCase.userId))!,
    meter: (await fixture.dependencies.meters.getById(
      verificationCase.meterId,
    ))!,
    verificationCase: verificationCase,
    flows: await fixture.dependencies.flows.listByCase(verificationCase.id),
    samples: samples,
    pointsBySample: points,
    evidenceBySample: evidence,
  );
}
