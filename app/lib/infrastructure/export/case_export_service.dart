import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/metrology/metrology.dart';
import '../../domain/models.dart';

final class CaseExportBundle {
  const CaseExportBundle({
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

final class ExportedCaseFiles {
  const ExportedCaseFiles({
    required this.csvPath,
    required this.jsonPath,
    required this.htmlPath,
    required this.pdfPath,
  });

  final String csvPath;
  final String jsonPath;
  final String htmlPath;
  final String pdfPath;
}

final class CaseExportService {
  CaseExportService({this.outputDirectory});

  final Directory? outputDirectory;

  Future<ExportedCaseFiles> export(CaseExportBundle bundle) async {
    final root =
        outputDirectory ??
        Directory(
          p.join((await getApplicationDocumentsDirectory()).path, 'exports'),
        );
    await root.create(recursive: true);
    final stem = _safe(
      'DDR001_${bundle.meter.id}_${bundle.verificationCase.id}',
    );
    final csvPath = p.join(root.path, '$stem.csv');
    final jsonPath = p.join(root.path, '$stem.json');
    final htmlPath = p.join(root.path, '$stem.html');
    final pdfPath = p.join(root.path, '$stem.pdf');
    await File(csvPath).writeAsString(toCsv(bundle), flush: true);
    await File(jsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(toJson(bundle)),
      flush: true,
    );
    await File(htmlPath).writeAsString(await toHtml(bundle), flush: true);
    await File(pdfPath).writeAsBytes(await toPdf(bundle), flush: true);
    return ExportedCaseFiles(
      csvPath: csvPath,
      jsonPath: jsonPath,
      htmlPath: htmlPath,
      pdfPath: pdfPath,
    );
  }

  String toCsv(CaseExportBundle bundle) {
    final rows = <List<Object?>>[
      const [
        'case_id',
        'meter_id',
        'operator',
        'flow',
        'sample',
        'method',
        'point',
        'pulse_count',
        'v_ref_l',
        'reading_l',
        'v_ind_l',
        'meter_under_test_l',
        'diagnostic_error_pct',
        'flow_lps',
        'captured_at',
      ],
    ];
    for (final sample in _orderedSamples(bundle)) {
      final flow = _flowFor(bundle, sample);
      for (final point in _orderedPoints(
        bundle.pointsBySample[sample.id] ?? const [],
      )) {
        rows.add([
          bundle.verificationCase.id,
          bundle.meter.id,
          bundle.user.displayName ?? '',
          flow.code.name.toUpperCase(),
          sample.sampleNumber,
          sample.configuration.measurementMethod.name.toUpperCase(),
          _pointName(point.type),
          point.pulseCount,
          point.referenceLiters,
          point.readingLiters,
          point.indicatedLiters,
          point.meterUnderTestPulseCount == null
              ? null
              : point.meterUnderTestPulseCount! *
                    sample.configuration.hydrantLitersPerPulse,
          point.diagnosticErrorPct,
          point.flowLps,
          point.capturedAt.toUtc().toIso8601String(),
        ]);
      }
    }
    return '${rows.map((row) => row.map(_csvCell).join(',')).join('\r\n')}\r\n';
  }

  Map<String, Object?> toJson(CaseExportBundle bundle) => {
    'schema': 'ddr001.verification.export/v1',
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'case': {
      'case_id': bundle.verificationCase.id,
      'meter_id': bundle.meter.id,
      'user_id': bundle.user.id,
      'operator': bundle.user.displayName,
      'status': bundle.verificationCase.status.name.toUpperCase(),
      'overall_verdict': bundle.verificationCase.overallVerdict?.name
          .toUpperCase(),
      'created_at': bundle.verificationCase.createdAt.toUtc().toIso8601String(),
      'closed_at': bundle.verificationCase.closedAt?.toUtc().toIso8601String(),
      'checksum': bundle.verificationCase.checksum,
      'report_version': bundle.verificationCase.reportVersion,
      'test_bench_id': bundle.verificationCase.testBenchId,
      'device': {
        'id': bundle.verificationCase.deviceId,
        'android_version': bundle.verificationCase.androidVersion,
        'brand': bundle.verificationCase.deviceBrand,
        'model': bundle.verificationCase.deviceModel,
      },
    },
    'meter': {
      'meter_id': bundle.meter.id,
      'external_status': bundle.meter.externalStatus.name.toUpperCase(),
      'external_snapshot': bundle.meter.externalSnapshotJson == null
          ? null
          : jsonDecode(bundle.meter.externalSnapshotJson!),
    },
    'flow_points': bundle.flows
        .map(
          (flow) => {
            'flow_point_id': flow.id,
            'code': flow.code.name.toUpperCase(),
            'lps_approx': flow.lpsApprox,
            'mpe_pct': flow.mpePct,
            'status': flow.status.name.toUpperCase(),
            'samples': _orderedSamples(bundle)
                .where((sample) => sample.flowPointId == flow.id)
                .map((sample) => _sampleJson(bundle, sample))
                .toList(),
          },
        )
        .toList(),
  };

  Future<String> toHtml(CaseExportBundle bundle) async {
    final samples = _orderedSamples(
      bundle,
    ).where((sample) => sample.status == SampleStatus.closedValid).toList();
    final out = StringBuffer('''<!doctype html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Evidencia de verificación</title><style>
body{font-family:Arial,sans-serif;color:#162235;margin:0;background:#eef2f6}main{max-width:960px;margin:auto;background:white;padding:28px}
h1{color:#173e68;margin:0 0 6px}.muted{color:#617286}.grid{display:grid;grid-template-columns:repeat(2,1fr);gap:8px 24px}.card{border:1px solid #b9c8d8;border-radius:10px;padding:16px;margin:18px 0}table{border-collapse:collapse;width:100%;font-size:13px}th,td{border:1px solid #aab9c8;padding:7px;text-align:right}th:first-child,td:first-child{text-align:left}th{background:#173e68;color:white}.verdict{font-size:25px;font-weight:bold}.photo{page-break-inside:avoid;margin:14px 0}.photo img{display:block;max-width:100%;max-height:580px;margin:8px auto;border:1px solid #8091a3}.seal{border-top:2px solid #173e68;margin-top:24px;padding-top:10px;font-size:12px}button{padding:12px 18px;background:#1f5c99;color:white;border:0;border-radius:8px;font-weight:bold}@media print{button{display:none}body{background:white}main{max-width:none;padding:0}}
</style></head><body><main><h1>Evidencia de verificación</h1>
<button onclick="window.print()">Descargar PDF</button><section class="card"><h2>Identificación</h2><div class="grid">
<div><b>Medidor:</b> ${_h(bundle.meter.id)}</div><div><b>Operador:</b> ${_h(bundle.user.displayName ?? '')}</div>
<div><b>ID / banco de pruebas:</b> ${_h(bundle.verificationCase.testBenchId)}</div>
<div><b>Fecha:</b> ${_date(bundle.verificationCase.createdAt)}</div><div><b>Estado:</b> ${_caseStatus(bundle.verificationCase.status)}</div>
</div></section>''');
    for (final sample in samples) {
      final flow = _flowFor(bundle, sample);
      final result = sample.result!;
      out.write(
        '''<section class="card"><h2>${_sampleLabel(bundle, sample)}</h2>
<div class="grid"><div><b>Fecha:</b> ${_date(sample.createdAt)}</div><div><b>Caudal:</b> ${flow.code.name.toUpperCase()}</div>
<div><b>Método:</b> ${_methodName(sample.configuration.measurementMethod)}</div><div><b>GPS:</b> ${_gps(sample.gps)}</div>
<div><b>Caudal mínimo:</b> ${_flowStatistics(bundle, sample).minimum}</div><div><b>Caudal máximo:</b> ${_flowStatistics(bundle, sample).maximum}</div>
<div><b>Caudal promedio:</b> ${_flowStatistics(bundle, sample).average}</div></div>
<h3>Configuración metrológica</h3><div class="grid">
<div><b>K patrón:</b> ${sample.configuration.litersPerPulse.toStringAsFixed(3)} L/pulso</div><div><b>K hidrante:</b> ${sample.configuration.hydrantLitersPerPulse.toStringAsFixed(3)} L/pulso</div>
<div><b>Paso de evidencias:</b> ${sample.configuration.evidenceStepLiters.toStringAsFixed(2)} L</div><div><b>Incertidumbre de lectura:</b> ${sample.configuration.readingUncertaintyLiters.toStringAsFixed(3)} L</div>
<div><b>MPE aplicado:</b> ±${sample.configuration.mpePct.toStringAsFixed(2)} %</div></div>
<h3>ESP32</h3><div class="grid"><div><b>Nombre:</b> ${_h(sample.pulseAcquisitionConfiguration?.bleDeviceName ?? 'No registrado')}</div>
<div><b>ID:</b> ${_h(sample.pulseAcquisitionConfiguration?.bleDeviceId ?? 'No registrado')}</div>
<div><b>Protocolo:</b> ${sample.pulseAcquisitionConfiguration?.bleProtocolVersion ?? 'No registrado'}</div></div>
<h3>Repetibilidad del caudal</h3>${_repeatabilityHtml(bundle, sample)}
${_locationMapHtml(sample.gps)}
<h3>Registro</h3>${_pointsTable(bundle.pointsBySample[sample.id] ?? const [], sample.configuration.hydrantLitersPerPulse)}
<h3>Resultado (odómetro + aguja)</h3><p class="verdict">${_verdict(result.verdict)} · ${result.errorPct.toStringAsFixed(2)} % ±${result.uncertaintyPct.toStringAsFixed(2)} %</p>
<table><tr><th>Concepto</th><th>Valor</th></tr>
<tr><td>Lectura inicial</td><td>${_reading(sample.initialReading)}</td></tr><tr><td>Lectura final</td><td>${_reading(sample.finalReading)}</td></tr>
<tr><td>Avance / Vind</td><td>${result.indicatedLiters.toStringAsFixed(3)} L</td></tr><tr><td>Volumen patrón</td><td>${result.referenceLiters.toStringAsFixed(3)} L</td></tr>
<tr><td>Error</td><td>${result.errorPct.toStringAsFixed(6)} %</td></tr><tr><td>Incertidumbre U</td><td>${result.uncertaintyPct.toStringAsFixed(6)} %</td></tr>
<tr><td>MPE</td><td>±${result.mpePct.toStringAsFixed(2)} %</td></tr><tr><td>Regla aplicada</td><td>APRUEBA si |E|+U≤MPE; RECHAZA si |E|−U&gt;MPE; otro caso NO CONCLUYENTE</td></tr>
<tr><td>Duración</td><td>${_duration(sample)}</td></tr></table><h3>Imágenes</h3>''',
      );
      for (final evidence in _orderedEvidence(
        bundle.evidenceBySample[sample.id] ?? const [],
      )) {
        out.write(await _evidenceHtml(evidence));
      }
      out.write('</section>');
    }
    out.write('</main></body></html>');
    return out.toString();
  }

  Future<Uint8List> toPdf(CaseExportBundle bundle) async {
    final document = pw.Document();
    final samples = _orderedSamples(
      bundle,
    ).where((s) => s.status == SampleStatus.closedValid).toList();
    final evidenceWidgets = <String, List<pw.Widget>>{};
    for (final sample in samples) {
      final widgets = <pw.Widget>[];
      for (final evidence in _orderedEvidence(
        bundle.evidenceBySample[sample.id] ?? const [],
      )) {
        widgets.addAll(await _pdfEvidence(evidence));
      }
      evidenceWidgets[sample.id] = widgets;
    }
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (_) => pw.Text(
          'Evidencia de verificación',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        build: (_) => [
          pw.Text('Medidor: ${bundle.meter.id}'),
          pw.Text('Operador: ${bundle.user.displayName ?? ''}'),
          pw.Text(
            'ID / banco de pruebas: ${bundle.verificationCase.testBenchId}',
          ),
          for (final sample in samples) ...[
            pw.SizedBox(height: 16),
            pw.Header(level: 1, text: _sampleLabel(bundle, sample)),
            pw.Text('Fecha: ${_date(sample.createdAt)}'),
            pw.Text(
              'Caudal mínimo ${_flowStatistics(bundle, sample).minimum} - máximo ${_flowStatistics(bundle, sample).maximum} - promedio ${_flowStatistics(bundle, sample).average}',
            ),
            pw.Text(
              'Configuración: K patrón ${sample.configuration.litersPerPulse.toStringAsFixed(3)} L/pulso - K hidrante ${sample.configuration.hydrantLitersPerPulse.toStringAsFixed(3)} L/pulso - paso ${sample.configuration.evidenceStepLiters.toStringAsFixed(2)} L - incertidumbre ${sample.configuration.readingUncertaintyLiters.toStringAsFixed(3)} L - MPE +/-${sample.configuration.mpePct.toStringAsFixed(2)} %',
            ),
            pw.Text(
              'ESP32: ${sample.pulseAcquisitionConfiguration?.bleDeviceName ?? 'No registrado'} - ID ${sample.pulseAcquisitionConfiguration?.bleDeviceId ?? 'No registrado'} - protocolo ${sample.pulseAcquisitionConfiguration?.bleProtocolVersion ?? 'No registrado'}',
            ),
            pw.Text(_repeatabilityText(bundle, sample)),
            if (sample.gps != null) ...[
              pw.SizedBox(height: 8),
              pw.Text('Mapa de ubicación'),
              pw.SvgImage(svg: _locationSvg(sample.gps!), height: 150),
              pw.Text(_gpsPdf(sample.gps)),
              pw.UrlLink(
                destination: _mapUrl(sample.gps!),
                child: pw.Text('Abrir mapa detallado'),
              ),
            ],
            pw.Text(
              '${_verdict(sample.result!.verdict)} - E ${sample.result!.errorPct.toStringAsFixed(3)} % - U ${sample.result!.uncertaintyPct.toStringAsFixed(3)} % - MPE +/-${sample.result!.mpePct.toStringAsFixed(2)} %',
            ),
            pw.Text(
              'Vref ${sample.result!.referenceLiters.toStringAsFixed(3)} L - Vind ${sample.result!.indicatedLiters.toStringAsFixed(3)} L - GPS ${_gpsPdf(sample.gps)}',
            ),
            _pdfPoints(
              bundle.pointsBySample[sample.id] ?? const [],
              sample.configuration.hydrantLitersPerPulse,
            ),
            ...evidenceWidgets[sample.id]!,
          ],
        ],
      ),
    );
    return document.save();
  }

  Map<String, Object?> _sampleJson(CaseExportBundle bundle, Sample sample) => {
    'sample_id': sample.id,
    'sample_number': sample.sampleNumber,
    'status': sample.status.name.toUpperCase(),
    'measurement_source': sample.configuration.measurementMethod.name
        .toUpperCase(),
    'started_at': sample.startedAt?.toUtc().toIso8601String(),
    'ended_at': sample.endedAt?.toUtc().toIso8601String(),
    'gps': sample.gps == null
        ? null
        : {
            'latitude': sample.gps!.latitude,
            'longitude': sample.gps!.longitude,
            'accuracy_m': sample.gps!.accuracyMeters,
            'captured_at': sample.gps!.capturedAt.toUtc().toIso8601String(),
          },
    'configuration': {
      'k_l_per_pulse': sample.configuration.litersPerPulse,
      if (sample.configuration.controlStartMaximumLps.isFinite) ...{
        'control_start_minimum_lps':
            sample.configuration.controlStartMinimumLps,
        'control_start_maximum_lps':
            sample.configuration.controlStartMaximumLps,
        'hydrant_k_l_per_pulse': sample.configuration.hydrantLitersPerPulse,
      },
      'evidence_step_l': sample.configuration.evidenceStepLiters,
      'reading_uncertainty_l': sample.configuration.readingUncertaintyLiters,
      'mpe_pct': sample.configuration.mpePct,
    },
    'pulse_count': sample.pulseCount,
    'flow_statistics_lps': {
      'minimum': _flowValues(bundle, sample).minimum,
      'maximum': _flowValues(bundle, sample).maximum,
      'average': _flowValues(bundle, sample).average,
    },
    'acquisition_integrity': {
      'status': sample.acquisitionIntegrity.status.name.toUpperCase(),
      'reason': sample.acquisitionIntegrity.reason,
      'source': sample.acquisitionIntegrity.source?.name.toUpperCase(),
    },
    'result': sample.result == null
        ? null
        : {
            'v_ref_l': sample.result!.referenceLiters,
            'v_ind_l': sample.result!.indicatedLiters,
            'error_pct': sample.result!.errorPct,
            'uncertainty_pct': sample.result!.uncertaintyPct,
            'mpe_pct': sample.result!.mpePct,
            'verdict': _verdict(sample.result!.verdict),
          },
    'points': (bundle.pointsBySample[sample.id] ?? const [])
        .map(
          (point) => {
            'point_id': point.id,
            'type': _pointName(point.type),
            'pulse_count': point.pulseCount,
            'v_ref_l': point.referenceLiters,
            'reading_l': point.readingLiters,
            'v_ind_l': point.indicatedLiters,
            'diagnostic_error_pct': point.diagnosticErrorPct,
            'flow_lps': point.flowLps,
            'meter_under_test_pulse_count': point.meterUnderTestPulseCount,
            'meter_under_test_liters': point.meterUnderTestPulseCount == null
                ? null
                : point.meterUnderTestPulseCount! *
                      sample.configuration.hydrantLitersPerPulse,
            'captured_at': point.capturedAt.toUtc().toIso8601String(),
          },
        )
        .toList(),
    'evidence': (bundle.evidenceBySample[sample.id] ?? const [])
        .map(
          (item) => {
            'evidence_id': item.id,
            'type': _evidenceName(item.type),
            'required': item.required,
            'volume_ref_l': item.volumeRefLiters,
            'pulse_count': item.pulseCount,
            'captured_at': item.capturedAt.toUtc().toIso8601String(),
            'sha256': item.sha256,
            'local_path': item.localPath,
            'sync_status': item.syncStatus.name.toUpperCase(),
          },
        )
        .toList(),
    'checksum': sample.checksum,
  };

  Future<String> _evidenceHtml(Evidence item) async {
    final file = File(item.localPath);
    final bytes = await file.readAsBytes();
    final mime = item.localPath.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
    return '<div class="photo"><b>${_evidenceName(item.type)}</b> · ${item.volumeRefLiters?.toStringAsFixed(1) ?? '—'} L · pulso ${item.pulseCount ?? 'No disponible'} · ${_time(item.capturedAt)}<img alt="Evidencia ${_evidenceName(item.type)}" src="data:$mime;base64,${base64Encode(bytes)}"></div>';
  }

  Future<List<pw.Widget>> _pdfEvidence(Evidence item) async {
    final widgets = <pw.Widget>[
      pw.SizedBox(height: 8),
      pw.Text(
        '${_evidenceName(item.type)} - ${item.volumeRefLiters?.toStringAsFixed(1) ?? '-'} L - ${_time(item.capturedAt)}',
      ),
    ];
    try {
      final bytes = await File(item.localPath).readAsBytes();
      widgets.add(
        pw.Image(pw.MemoryImage(bytes), height: 280, fit: pw.BoxFit.contain),
      );
    } catch (_) {
      widgets.add(pw.Text('Imagen no disponible'));
    }
    return widgets;
  }

  pw.Widget _pdfPoints(List<TestPoint> points, double hydrantLitersPerPulse) =>
      pw.TableHelper.fromTextArray(
        headers: const [
          'Punto',
          'Tiempo',
          'Pulsos',
          'V.patrón',
          'Lectura',
          'V.mec',
          'Error %',
          'Caudal L/s',
        ],
        data: _orderedPoints(points)
            .map(
              (p) => [
                _pointName(p.type),
                _time(p.capturedAt),
                p.pulseCount ?? '-',
                p.referenceLiters?.toStringAsFixed(2) ?? '-',
                p.readingLiters?.toStringAsFixed(2) ?? '-',
                p.meterUnderTestPulseCount == null
                    ? '-'
                    : (p.meterUnderTestPulseCount! * hydrantLitersPerPulse)
                          .toStringAsFixed(2),
                p.diagnosticErrorPct?.toStringAsFixed(2) ?? '-',
                p.flowLps?.toStringAsFixed(2) ?? '-',
              ],
            )
            .toList(),
      );

  String _pointsTable(List<TestPoint> points, double hydrantLitersPerPulse) =>
      '<table><tr><th>Punto</th><th>Tiempo</th><th>Pulsos</th><th>V.patrón L</th><th>Lectura L</th><th>V.mec L</th><th>Error %</th><th>Caudal L/s</th></tr>${_orderedPoints(points).map((p) => '<tr><td>${_pointName(p.type)}</td><td>${_time(p.capturedAt)}</td><td>${p.pulseCount ?? '—'}</td><td>${p.referenceLiters?.toStringAsFixed(2) ?? '—'}</td><td>${p.readingLiters?.toStringAsFixed(2) ?? '—'}</td><td>${p.meterUnderTestPulseCount == null ? '—' : (p.meterUnderTestPulseCount! * hydrantLitersPerPulse).toStringAsFixed(2)}</td><td>${p.diagnosticErrorPct?.toStringAsFixed(2) ?? '—'}</td><td>${p.flowLps?.toStringAsFixed(2) ?? '—'}</td></tr>').join()}</table>';

  List<Sample> _orderedSamples(CaseExportBundle b) =>
      [...b.samples]..sort((a, z) => a.createdAt.compareTo(z.createdAt));
  List<TestPoint> _orderedPoints(List<TestPoint> values) =>
      [...values]..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
  List<Evidence> _orderedEvidence(List<Evidence> values) =>
      [...values]..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
  FlowPointRecord _flowFor(CaseExportBundle b, Sample s) =>
      b.flows.firstWhere((f) => f.id == s.flowPointId);
  String _sampleLabel(CaseExportBundle bundle, Sample sample) {
    final flow = _flowFor(bundle, sample).code.name.toUpperCase();
    final count = bundle.samples
        .where((item) => item.flowPointId == sample.flowPointId)
        .length;
    return count == 1 ? flow : '$flow-${sample.sampleNumber}';
  }

  String _reading(ConfirmedReading? value) => value == null
      ? '—'
      : '${(value.reading.odometerUnits * value.reading.litersPerOdometerUnit + value.reading.needleLiters).toStringAsFixed(3)} L';
  String _duration(Sample s) => s.startedAt == null || s.endedAt == null
      ? '—'
      : '${s.endedAt!.difference(s.startedAt!).inSeconds} s';
  String _gps(GpsSnapshot? gps) => gps == null
      ? 'No disponible'
      : '${gps.latitude.toStringAsFixed(6)}, ${gps.longitude.toStringAsFixed(6)} (±${gps.accuracyMeters.toStringAsFixed(0)} m)';
  String _gpsPdf(GpsSnapshot? gps) => gps == null
      ? 'No disponible'
      : '${gps.latitude.toStringAsFixed(6)}, ${gps.longitude.toStringAsFixed(6)} (+/-${gps.accuracyMeters.toStringAsFixed(0)} m)';
  String _verdict(SampleVerdict value) => switch (value) {
    SampleVerdict.pass => 'APRUEBA',
    SampleVerdict.fail => 'RECHAZA',
    SampleVerdict.inconclusive => 'NO CONCLUYENTE',
  };
  String _pointName(PointType value) => switch (value) {
    PointType.start => 'INICIO',
    PointType.intermediate => 'INTERMEDIO',
    PointType.finalPoint => 'FINAL',
    PointType.manualDiagnostic => 'DIAGNÓSTICO MANUAL',
  };
  String _evidenceName(EvidenceType value) => switch (value) {
    EvidenceType.start => 'INICIO',
    EvidenceType.intermediate => 'INTERMEDIA',
    EvidenceType.finalEvidence => 'FINAL',
    EvidenceType.extra => 'ADICIONAL',
  };
  String _methodName(MeasurementMethod value) => switch (value) {
    MeasurementMethod.visual => 'LECTURA VISUAL',
    MeasurementMethod.manual => 'MANUAL',
    MeasurementMethod.led => 'LED',
    MeasurementMethod.ble => 'BLUETOOTH',
  };
  String _caseStatus(VerificationCaseStatus value) => switch (value) {
    VerificationCaseStatus.open => 'ABIERTO',
    VerificationCaseStatus.closed => 'CERRADO',
  };
  String _date(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}';
  }

  String _time(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }

  ({double? minimum, double? maximum, double? average}) _flowValues(
    CaseExportBundle bundle,
    Sample sample,
  ) {
    final values = (bundle.pointsBySample[sample.id] ?? const <TestPoint>[])
        .map((point) => point.flowLps)
        .whereType<double>()
        .toList();
    if (values.isEmpty) return (minimum: null, maximum: null, average: null);
    values.sort();
    return (
      minimum: values.first,
      maximum: values.last,
      average: values.reduce((a, b) => a + b) / values.length,
    );
  }

  ({String minimum, String maximum, String average}) _flowStatistics(
    CaseExportBundle bundle,
    Sample sample,
  ) {
    final values = _flowValues(bundle, sample);
    String display(double? value) =>
        value == null ? '—' : '${value.toStringAsFixed(3)} L/s';
    return (
      minimum: display(values.minimum),
      maximum: display(values.maximum),
      average: display(values.average),
    );
  }

  FlowPointResult _repeatability(CaseExportBundle bundle, Sample sample) {
    final results = bundle.samples
        .where(
          (item) =>
              item.flowPointId == sample.flowPointId && item.result != null,
        )
        .map((item) => item.result!)
        .toList();
    return FlowPointResult.summarize(
      flowPoint: sample.configuration.flowPoint,
      samples: results,
      mpePct: sample.configuration.mpePct,
    );
  }

  String _repeatabilityHtml(CaseExportBundle bundle, Sample sample) {
    final stats = _repeatability(bundle, sample).statistics!;
    return '<div class="grid"><div><b>Muestras:</b> ${stats.n}</div><div><b>Error promedio:</b> ${stats.meanErrorPct.toStringAsFixed(3)} %</div><div><b>Dispersión:</b> ${stats.dispersionPct.toStringAsFixed(3)} %</div><div><b>Desviación estándar:</b> ${stats.sampleStandardDeviationPct?.toStringAsFixed(3) ?? '—'} %</div><div><b>Resultado:</b> ${_repeatabilityName(stats.repeatabilityStatus)}</div></div>';
  }

  String _repeatabilityText(CaseExportBundle bundle, Sample sample) {
    final stats = _repeatability(bundle, sample).statistics!;
    return 'Repetibilidad: n ${stats.n} - error promedio ${stats.meanErrorPct.toStringAsFixed(3)} % - dispersión ${stats.dispersionPct.toStringAsFixed(3)} % - desviación estándar ${stats.sampleStandardDeviationPct?.toStringAsFixed(3) ?? '—'} % - ${_repeatabilityName(stats.repeatabilityStatus)}';
  }

  String _repeatabilityName(RepeatabilityStatus value) => switch (value) {
    RepeatabilityStatus.notEvaluable => 'NO EVALUABLE',
    RepeatabilityStatus.pass => 'CUMPLE',
    RepeatabilityStatus.fail => 'NO CUMPLE',
  };
  String _locationMapHtml(GpsSnapshot? gps) {
    if (gps == null) {
      return '<h3>Mapa de ubicación</h3><p>Ubicación no registrada.</p>';
    }
    return '<h3>Mapa de ubicación</h3>${_locationSvg(gps)}<p>${_gps(gps)} · <a href="${_mapUrl(gps)}">Abrir mapa detallado</a></p>';
  }

  String _mapUrl(GpsSnapshot gps) =>
      'https://www.openstreetmap.org/?mlat=${gps.latitude}&mlon=${gps.longitude}#map=18/${gps.latitude}/${gps.longitude}';
  String _locationSvg(GpsSnapshot gps) {
    final x = ((gps.longitude + 180) / 360 * 720).clamp(8, 712);
    final y = ((90 - gps.latitude) / 180 * 300).clamp(8, 292);
    return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 720 300" role="img" aria-label="Mapa de ubicación de la prueba">
<rect width="720" height="300" rx="12" fill="#e8eef5" stroke="#173e68"/>
<path d="M180 0V300M360 0V300M540 0V300M0 75H720M0 150H720M0 225H720" stroke="#b9c8d8" stroke-width="1"/>
<text x="8" y="18" font-family="Arial" font-size="12" fill="#617286">90° N</text><text x="8" y="292" font-family="Arial" font-size="12" fill="#617286">90° S</text>
<text x="650" y="292" font-family="Arial" font-size="12" fill="#617286">180° E</text>
<circle cx="$x" cy="$y" r="10" fill="#b03a2e" stroke="white" stroke-width="4"/><circle cx="$x" cy="$y" r="3" fill="white"/>
<text x="${(x + 15).clamp(15, 575)}" y="${(y - 12).clamp(18, 285)}" font-family="Arial" font-size="13" font-weight="bold" fill="#162235">${gps.latitude.toStringAsFixed(6)}, ${gps.longitude.toStringAsFixed(6)}</text>
</svg>''';
  }

  String _safe(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
  String _h(Object? value) =>
      const HtmlEscape(HtmlEscapeMode.element).convert('$value');
  String _csvCell(Object? value) {
    final text = value?.toString() ?? '';
    return RegExp('[",\r\n]').hasMatch(text)
        ? '"${text.replaceAll('"', '""')}"'
        : text;
  }
}
