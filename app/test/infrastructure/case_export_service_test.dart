import 'dart:convert';
import 'dart:io';

import 'package:ddr001_diag_view_app/core/metrology/metrology.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:ddr001_diag_view_app/infrastructure/export/case_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'exports self-contained HTML, structured JSON, CSV and readable PDF',
    () async {
      final root = await Directory.systemTemp.createTemp('ddr001-export-');
      addTearDown(() => root.delete(recursive: true));
      final photo = File('${root.path}/start.png');
      await photo.writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
      final at = DateTime.utc(2026, 8, 15, 18);
      final result = SampleResult(
        referenceLiters: 100,
        indicatedLiters: 100,
        errorPct: 0,
        uncertaintyPct: .5,
        mpePct: 2,
        decisionMetrics: const DecisionMetrics(
          acceptanceMetricPct: .5,
          rejectionMetricPct: -.5,
        ),
        verdict: SampleVerdict.pass,
      );
      final sample = Sample(
        id: 'sample-1',
        flowPointId: 'flow-1',
        sampleNumber: 1,
        status: SampleStatus.closedValid,
        configuration: const SampleConfiguration(
          measurementMethod: MeasurementMethod.manual,
          litersPerPulse: 1,
          evidenceStepLiters: 25,
          readingUncertaintyLiters: 1,
          flowPoint: FlowPoint.q3,
          mpePct: 2,
          litersPerOdometerUnit: 1000,
          needleLitersPerRevolution: 100,
        ),
        createdAt: at,
        updatedAt: at.add(const Duration(seconds: 30)),
        startedAt: at,
        endedAt: at.add(const Duration(seconds: 30)),
        gps: GpsSnapshot(
          latitude: 29.1024,
          longitude: -111.0495,
          accuracyMeters: 8,
          capturedAt: at,
        ),
        pulseCount: 100,
        initialReading: ConfirmedReading(
          reading: MeterReading(odometerUnits: 1, needleLiters: 0),
          source: ReadingSource.manual,
          evidenceId: 'evidence-1',
        ),
        finalReading: ConfirmedReading(
          reading: MeterReading(odometerUnits: 1, needleLiters: 0),
          source: ReadingSource.manual,
          evidenceId: 'evidence-1',
        ),
        result: result,
        checksum: 'abc123',
      );
      final evidence = Evidence(
        id: 'evidence-1',
        sampleId: sample.id,
        type: EvidenceType.start,
        required: true,
        capturedAt: at,
        localPath: photo.path,
        syncStatus: EvidenceSyncStatus.local,
        volumeRefLiters: 0,
        pulseCount: 0,
        sha256: 'hash',
      );
      final bundle = CaseExportBundle(
        user: User(
          id: 'user-1',
          displayName: 'Operador Prueba',
          email: 'test@example.com',
          phone: '+521234567890',
          createdAt: at,
        ),
        meter: Meter(
          id: 'H-016',
          externalStatus: ExternalMeterStatus.unknownOffline,
          createdAt: at,
        ),
        verificationCase: VerificationCase(
          id: 'case-1',
          meterId: 'H-016',
          userId: 'user-1',
          status: VerificationCaseStatus.closed,
          overallVerdict: OverallVerdict.approved,
          createdAt: at,
          closedAt: at.add(const Duration(minutes: 1)),
          reportVersion: 1,
          checksum: 'casehash',
        ),
        flows: [
          FlowPointRecord(
            id: 'flow-1',
            caseId: 'case-1',
            code: FlowPoint.q3,
            mpePct: 2,
            status: FlowRecordStatus.pass,
            createdAt: at,
          ),
        ],
        samples: [sample],
        pointsBySample: {
          sample.id: [
            TestPoint(
              id: 'point-1',
              sampleId: sample.id,
              type: PointType.start,
              capturedAt: at,
              pulseCount: 0,
              referenceLiters: 0,
              meterUnderTestPulseCount: 2,
              flowLps: 1.25,
            ),
          ],
        },
        evidenceBySample: {
          sample.id: [evidence],
        },
      );

      final service = CaseExportService(outputDirectory: root);
      final files = await service.export(bundle);
      final html = await File(files.htmlPath).readAsString();
      final json = jsonDecode(await File(files.jsonPath).readAsString()) as Map;
      final csv = await File(files.csvPath).readAsString();
      final pdf = await File(files.pdfPath).readAsBytes();

      expect(html, contains('Evidencia de verificación'));
      expect(html, contains('Operador Prueba'));
      expect(html, contains('29.102400, -111.049500'));
      expect(html, contains('data:image/png;base64,'));
      expect(html, contains('Descargar PDF'));
      expect(html, contains('<th>Tiempo</th>'));
      expect(html, isNot(contains('Sello DDR001')));
      expect(html, isNot(contains('Expediente ')));
      expect(html, contains('INICIO'));
      expect(html, contains('Configuración metrológica'));
      expect(html, contains('Repetibilidad del caudal'));
      expect(html, contains('Mapa de ubicación'));
      expect(html, contains('Abrir mapa detallado'));
      expect(html, contains('1.25'));
      expect(html, isNot(contains('src="http')));
      expect(json['schema'], 'ddr001.verification.export/v1');
      expect(csv, contains('diagnostic_error_pct'));
      expect(pdf.take(4), orderedEquals('%PDF'.codeUnits));
      expect(pdf.length, greaterThan(1000));
    },
  );
}
