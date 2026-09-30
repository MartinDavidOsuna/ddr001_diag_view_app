import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../core/metrology/metrology.dart';
import '../domain/models.dart';
import '../infrastructure/export/case_report_renderer.dart';
import 'web_demo_domain.dart';

final class DemoExport {
  static CaseReportRenderer get renderer {
    final images = <(String, String?), Future<Uint8List>>{};
    return CaseReportRenderer(
      readEvidence: (evidence) => images.putIfAbsent((
        evidence.localPath,
        evidence.sha256,
      ), () => _readEvidence(evidence)),
    );
  }

  static Future<Uint8List> _readEvidence(Evidence evidence) async {
    final data = await rootBundle
        .load(evidence.localPath)
        .timeout(const Duration(seconds: 15));
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    if (sha256.convert(bytes).toString() != evidence.sha256) {
      throw StateError(
        'La fotografía simulada no coincide con su integridad registrada.',
      );
    }
    return bytes;
  }

  static CaseExportBundle bundle(
    DemoCase item,
    Set<int> selection, {
    bool closed = true,
  }) {
    final samples = <Sample>[];
    final points = <String, List<TestPoint>>{};
    final evidence = <String, List<Evidence>>{};
    final numbers = <FlowPoint, int>{};
    for (var index = 0; index < item.samples.length; index++) {
      final source = item.samples[index];
      final number = (numbers[source.flowPoint] ?? 0) + 1;
      numbers[source.flowPoint] = number;
      if (!selection.contains(index)) continue;
      final id = '${item.id}-sample-$index';
      final configuration = source.configuration.configuration(
        source.flowPoint,
      );
      ConfirmedReading reading(
        double totalizer,
        double needle,
        String? evidenceId,
      ) => ConfirmedReading(
        reading: MeterReading(
          odometerUnits: totalizer,
          needleLiters: needle,
          litersPerOdometerUnit: configuration.litersPerOdometerUnit,
        ),
        source: ReadingSource.manual,
        evidenceId: evidenceId,
      );
      samples.add(
        Sample(
          id: id,
          flowPointId: '${item.id}-${source.flowPoint.name}',
          sampleNumber: number,
          status: SampleStatus.closedValid,
          configuration: configuration,
          createdAt: source.startedAt,
          updatedAt: source.endedAt,
          startedAt: source.startedAt,
          endedAt: source.endedAt,
          pulseCount: source.pulseCount,
          referenceLitersProgress: source.referenceLiters,
          manualIndicatedLiters: source.indicatedLiters,
          initialReading: reading(
            source.initialTotalizer,
            source.initialNeedle,
            source.photos.isEmpty ? null : '$id-evidence-0',
          ),
          finalReading: reading(
            source.finalTotalizer,
            source.finalNeedle,
            source.photos.isEmpty
                ? null
                : '$id-evidence-${source.photos.length - 1}',
          ),
          result: source.result,
          simulationScenario: SimulationScenario.operatorControlled,
          checksum: sha256
              .convert(utf8.encode(jsonEncode(source.toJson())))
              .toString(),
        ),
      );
      points[id] = [];
      evidence[id] = [];
      for (
        var photoIndex = 0;
        photoIndex < source.photos.length;
        photoIndex++
      ) {
        final photo = source.photos[photoIndex];
        final initial = photo.type == EvidenceType.start;
        final finalPoint = photo.type == EvidenceType.finalEvidence;
        final readingLiters = initial
            ? source.initialTotalizer * configuration.litersPerOdometerUnit +
                  source.initialNeedle
            : finalPoint
            ? source.finalTotalizer * configuration.litersPerOdometerUnit +
                  source.finalNeedle
            : null;
        final pointId = '$id-point-$photoIndex';
        points[id]!.add(
          TestPoint(
            id: pointId,
            sampleId: id,
            type: initial
                ? PointType.start
                : finalPoint
                ? PointType.finalPoint
                : PointType.intermediate,
            capturedAt: photo.at,
            pulseCount: photo.pulses,
            referenceLiters: photo.volume,
            meterUnderTestPulseCount: photo.pulses,
            flowLps: photo.flowLps,
            readingLiters: readingLiters,
            indicatedLiters: finalPoint ? source.indicatedLiters : null,
            diagnosticErrorPct: photo.volume <= 0
                ? null
                : (photo.pulses * configuration.hydrantLitersPerPulse -
                          photo.volume) /
                      photo.volume *
                      100,
          ),
        );
        evidence[id]!.add(
          Evidence(
            id: '$id-evidence-$photoIndex',
            sampleId: id,
            pointId: pointId,
            type: photo.type,
            required: true,
            capturedAt: photo.at,
            localPath: photo.asset,
            syncStatus: EvidenceSyncStatus.local,
            volumeRefLiters: photo.volume,
            pulseCount: photo.pulses,
            sha256: photo.hash,
          ),
        );
      }
    }
    return CaseExportBundle(
      user: User(
        id: 'local-demo-operator',
        email: 'demo@example.invalid',
        phone: '0000000000',
        displayName: 'Operador de simulación',
        createdAt: item.createdAt,
      ),
      meter: Meter(
        id: item.meterId,
        externalStatus: ExternalMeterStatus.unknownOffline,
        createdAt: item.createdAt,
      ),
      verificationCase: VerificationCase(
        id: item.id,
        meterId: item.meterId,
        userId: 'local-demo-operator',
        status: closed
            ? VerificationCaseStatus.closed
            : VerificationCaseStatus.open,
        createdAt: item.createdAt,
        closedAt: closed ? item.samples.lastOrNull?.endedAt : null,
        testBenchId: item.testBenchId,
        reportVersion: 1,
        overallVerdict: switch (item.verdict) {
          SampleVerdict.pass => OverallVerdict.approved,
          SampleVerdict.fail => OverallVerdict.rejected,
          SampleVerdict.inconclusive => OverallVerdict.inconclusive,
        },
      ),
      flows: [
        for (final flow in item.flows)
          FlowPointRecord(
            id: '${item.id}-${flow.flowPoint.name}',
            caseId: item.id,
            code: flow.flowPoint,
            mpePct: 2,
            status: switch (flow.status) {
              FlowPointStatus.pass => FlowRecordStatus.pass,
              FlowPointStatus.fail => FlowRecordStatus.fail,
              FlowPointStatus.inconclusive => FlowRecordStatus.inconclusive,
              FlowPointStatus.pending => FlowRecordStatus.open,
            },
            createdAt: item.createdAt,
          ),
      ],
      samples: samples,
      pointsBySample: points,
      evidenceBySample: evidence,
    );
  }

  static Future<Map<String, Uint8List>> generate(
    DemoCase item,
    Set<int> selection, {
    bool closed = true,
    void Function(String stage)? onProgress,
  }) async {
    if (selection.isEmpty) throw StateError('Selecciona al menos una prueba.');
    final data = bundle(item, selection, closed: closed);
    final renderer = DemoExport.renderer;
    onProgress?.call('PREPARANDO HTML…');
    await Future<void>.delayed(Duration.zero);
    final html = await renderer.toHtml(data);
    onProgress?.call('GENERANDO PDF…');
    await Future<void>.delayed(Duration.zero);
    final pdf = await renderer.toPdf(data);
    onProgress?.call('PREPARANDO ARCHIVOS…');
    await Future<void>.delayed(Duration.zero);
    return {
      'csv': Uint8List.fromList(utf8.encode(renderer.toCsv(data))),
      'json': Uint8List.fromList(
        utf8.encode(
          const JsonEncoder.withIndent('  ').convert(renderer.toJson(data)),
        ),
      ),
      'html': Uint8List.fromList(utf8.encode(html)),
      'pdf': pdf,
    };
  }
}
