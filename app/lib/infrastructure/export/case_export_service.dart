import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'case_report_renderer.dart';
export 'case_report_renderer.dart' show CaseExportBundle;

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

final class CaseExportService extends CaseReportRenderer {
  CaseExportService({this.outputDirectory})
    : super(readEvidence: (evidence) => File(evidence.localPath).readAsBytes());

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

  String _safe(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
}
