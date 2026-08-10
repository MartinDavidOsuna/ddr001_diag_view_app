import 'dart:io';

import 'package:ddr001_diag_view_app/data/local/database/app_database.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/offline_fixture.dart';

void main() {
  late Directory directory;
  late AppDatabase database;
  late OfflineFixture fixture;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ddr001-evidence-');
    database = memoryDatabase();
    fixture = OfflineFixture(database, directory);
    await fixture.seed();
    await fixture.running();
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('reserve path uses opaque case sample and evidence IDs', () async {
    final path = await fixture.fileStore.reservePath(
      caseId: 'case-1',
      sampleId: 'sample-1',
      evidenceId: 'ev-1',
      extension: '.jpg',
    );
    expect(
      path,
      endsWith(
        'evidence${Platform.pathSeparator}case-1${Platform.pathSeparator}sample-1${Platform.pathSeparator}ev-1.jpg',
      ),
    );
  });

  test('existing file imports and verifies SHA-256 integrity', () async {
    final source = File('${directory.path}${Platform.pathSeparator}source.jpg');
    await source.writeAsString('photo');
    final imported = await fixture.fileStore.importExistingFile(
      sourcePath: source.path,
      caseId: 'case-1',
      sampleId: 'sample-1',
      evidenceId: 'ev',
    );
    final hash = await fixture.fileStore.calculateSha256(imported);
    expect(await fixture.fileStore.verify(imported, hash), isTrue);
    await File(imported).writeAsString('tampered');
    expect(await fixture.fileStore.verify(imported, hash), isFalse);
  });

  test('missing evidence file is reported without device plugin', () async {
    expect(
      await fixture.fileStore.exists('${directory.path}/missing.jpg'),
      isFalse,
    );
    expect(
      await fixture.fileStore.verify(
        '${directory.path}/missing.jpg',
        List.filled(64, '0').join(),
      ),
      isFalse,
    );
  });

  test('START INTERMEDIATE FINAL and EXTRA metadata persist', () async {
    for (final (index, type) in EvidenceType.values.indexed) {
      await fixture.addEvidence(
        sampleId: 'sample-1',
        id: 'ev-$index',
        type: type,
        required: type != EvidenceType.extra,
      );
    }
    expect(await fixture.evidence.listBySample('sample-1'), hasLength(4));
    expect(await fixture.evidence.hasCompleteRequiredSet('sample-1'), isTrue);
  });

  test('temporary evidence can be deleted only for an open sample', () async {
    final path = await fixture.fileStore.reservePath(
      caseId: 'case-1',
      sampleId: 'sample-1',
      evidenceId: 'temp',
      extension: 'jpg',
    );
    await File(path).writeAsString('temp');
    await fixture.fileStore.deleteTemporary(path, sampleClosed: false);
    expect(File(path).existsSync(), isFalse);
    expect(
      () => fixture.fileStore.deleteTemporary(path, sampleClosed: true),
      throwsStateError,
    );
  });
}
