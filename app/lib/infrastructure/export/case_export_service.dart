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
        'diagnostic_error_pct',
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
          point.diagnosticErrorPct,
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
<title>DDR001 · Evidencia de verificación</title><style>
body{font-family:Arial,sans-serif;color:#162235;margin:0;background:#eef2f6}main{max-width:960px;margin:auto;background:white;padding:28px}
h1{color:#173e68;margin:0 0 6px}.muted{color:#617286}.grid{display:grid;grid-template-columns:repeat(2,1fr);gap:8px 24px}.card{border:1px solid #b9c8d8;border-radius:10px;padding:16px;margin:18px 0}table{border-collapse:collapse;width:100%;font-size:13px}th,td{border:1px solid #aab9c8;padding:7px;text-align:right}th:first-child,td:first-child{text-align:left}th{background:#173e68;color:white}.verdict{font-size:25px;font-weight:bold}.photo{page-break-inside:avoid;margin:14px 0}.photo img{display:block;max-width:100%;max-height:580px;margin:8px auto;border:1px solid #8091a3}.seal{border-top:2px solid #173e68;margin-top:24px;padding-top:10px;font-size:12px}button{padding:12px 18px;background:#1f5c99;color:white;border:0;border-radius:8px;font-weight:bold}@media print{button{display:none}body{background:white}main{max-width:none;padding:0}}
</style></head><body><main><h1>DDR001 · Evidencia de verificación</h1><p class="muted">Expediente ${_h(bundle.verificationCase.id)}</p>
<button onclick="window.print()">Descargar PDF</button><section class="card"><h2>Identificación</h2><div class="grid">
<div><b>Medidor:</b> ${_h(bundle.meter.id)}</div><div><b>Operador:</b> ${_h(bundle.user.displayName ?? '')}</div>
<div><b>Fecha:</b> ${_h(bundle.verificationCase.createdAt.toLocal().toString())}</div><div><b>Estado:</b> ${_h(bundle.verificationCase.status.name.toUpperCase())}</div>
</div></section>''');
    for (final sample in samples) {
      final flow = _flowFor(bundle, sample);
      final result = sample.result!;
      out.write(
        '''<section class="card"><h2>Muestra ${sample.sampleNumber} · ${flow.code.name.toUpperCase()}</h2>
<div class="grid"><div><b>Caudal:</b> ${flow.code.name.toUpperCase()}</div><div><b>LPS aprox.:</b> ${flow.lpsApprox ?? '—'}</div>
<div><b>Método:</b> ${sample.configuration.measurementMethod.name.toUpperCase()}</div><div><b>GPS:</b> ${_gps(sample.gps)}</div></div>
<h3>Registro</h3>${_pointsTable(bundle.pointsBySample[sample.id] ?? const [])}
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
    out.write(
      '<footer class="seal"><b>Sello DDR001</b><br>Generado ${DateTime.now().toUtc().toIso8601String()} · checksums de muestras: ${samples.map((s) => _h(s.checksum ?? '—')).join(' · ')}</footer></main></body></html>',
    );
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
          'DDR001 - Evidencia de verificacion',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        build: (_) => [
          pw.Text('Medidor: ${bundle.meter.id}'),
          pw.Text('Operador: ${bundle.user.displayName ?? ''}'),
          pw.Text('Expediente: ${bundle.verificationCase.id}'),
          for (final sample in samples) ...[
            pw.SizedBox(height: 16),
            pw.Header(
              level: 1,
              text:
                  'Muestra ${sample.sampleNumber} - ${_flowFor(bundle, sample).code.name.toUpperCase()}',
            ),
            pw.Text(
              '${_verdict(sample.result!.verdict)} - E ${sample.result!.errorPct.toStringAsFixed(3)} % - U ${sample.result!.uncertaintyPct.toStringAsFixed(3)} % - MPE +/-${sample.result!.mpePct.toStringAsFixed(2)} %',
            ),
            pw.Text(
              'Vref ${sample.result!.referenceLiters.toStringAsFixed(3)} L - Vind ${sample.result!.indicatedLiters.toStringAsFixed(3)} L - GPS ${_gpsPdf(sample.gps)}',
            ),
            _pdfPoints(bundle.pointsBySample[sample.id] ?? const []),
            ...evidenceWidgets[sample.id]!,
          ],
          pw.Divider(),
          pw.Text(
            'Sello DDR001 - ${DateTime.now().toUtc().toIso8601String()}',
            style: const pw.TextStyle(fontSize: 9),
          ),
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
            'captured_at': point.capturedAt.toUtc().toIso8601String(),
          },
        )
        .toList(),
    'evidence': (bundle.evidenceBySample[sample.id] ?? const [])
        .map(
          (item) => {
            'evidence_id': item.id,
            'type': item.type.name.toUpperCase(),
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
    return '<div class="photo"><b>${item.type.name.toUpperCase()}</b> · ${item.volumeRefLiters?.toStringAsFixed(1) ?? '—'} L · pulso ${item.pulseCount ?? 'N/A'} · ${_h(item.capturedAt.toLocal().toString())}<img alt="${item.type.name}" src="data:$mime;base64,${base64Encode(bytes)}"></div>';
  }

  Future<List<pw.Widget>> _pdfEvidence(Evidence item) async {
    final widgets = <pw.Widget>[
      pw.SizedBox(height: 8),
      pw.Text(
        '${item.type.name.toUpperCase()} - ${item.volumeRefLiters?.toStringAsFixed(1) ?? '-'} L - ${item.capturedAt.toLocal()}',
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

  pw.Widget _pdfPoints(List<TestPoint> points) => pw.TableHelper.fromTextArray(
    headers: const [
      'Punto',
      'Timestamp',
      'Pulsos',
      'V.patrón',
      'Lectura',
      'V.mec',
      'Error %',
    ],
    data: _orderedPoints(points)
        .map(
          (p) => [
            _pointName(p.type),
            p.capturedAt.toLocal().toIso8601String(),
            p.pulseCount ?? '-',
            p.referenceLiters?.toStringAsFixed(2) ?? '-',
            p.readingLiters?.toStringAsFixed(2) ?? '-',
            p.indicatedLiters?.toStringAsFixed(2) ?? '-',
            p.diagnosticErrorPct?.toStringAsFixed(2) ?? '-',
          ],
        )
        .toList(),
  );

  String _pointsTable(List<TestPoint> points) =>
      '<table><tr><th>Punto</th><th>Timestamp</th><th>Pulsos</th><th>V.patrón L</th><th>Lectura L</th><th>V.mec L</th><th>Error %</th></tr>${_orderedPoints(points).map((p) => '<tr><td>${_pointName(p.type)}</td><td>${_h(p.capturedAt.toLocal().toIso8601String())}</td><td>${p.pulseCount ?? '—'}</td><td>${p.referenceLiters?.toStringAsFixed(2) ?? '—'}</td><td>${p.readingLiters?.toStringAsFixed(2) ?? '—'}</td><td>${p.indicatedLiters?.toStringAsFixed(2) ?? '—'}</td><td>${p.diagnosticErrorPct?.toStringAsFixed(2) ?? '—'}</td></tr>').join()}</table>';

  List<Sample> _orderedSamples(CaseExportBundle b) =>
      [...b.samples]..sort((a, z) {
        final flow = a.flowPointId.compareTo(z.flowPointId);
        return flow != 0 ? flow : a.sampleNumber.compareTo(z.sampleNumber);
      });
  List<TestPoint> _orderedPoints(List<TestPoint> values) =>
      [...values]..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
  List<Evidence> _orderedEvidence(List<Evidence> values) =>
      [...values]..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
  FlowPointRecord _flowFor(CaseExportBundle b, Sample s) =>
      b.flows.firstWhere((f) => f.id == s.flowPointId);
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
