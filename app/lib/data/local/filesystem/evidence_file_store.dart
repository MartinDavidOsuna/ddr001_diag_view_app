import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract interface class EvidenceFileStore {
  Future<String> reservePath({
    required String caseId,
    required String sampleId,
    required String evidenceId,
    required String extension,
  });
  Future<String> importExistingFile({
    required String sourcePath,
    required String caseId,
    required String sampleId,
    required String evidenceId,
  });
  Future<String> calculateSha256(String filePath);
  Future<void> writeBytes(String filePath, Uint8List bytes);
  Future<bool> exists(String filePath);
  Future<bool> verify(String filePath, String expectedSha256);
  Future<void> deleteTemporary(String filePath, {required bool sampleClosed});
}

final class LocalEvidenceFileStore implements EvidenceFileStore {
  LocalEvidenceFileStore(this.rootDirectory);

  static Future<LocalEvidenceFileStore> createDefault() async {
    final documents = await getApplicationDocumentsDirectory();
    return LocalEvidenceFileStore(documents);
  }

  final Directory rootDirectory;

  @override
  Future<String> reservePath({
    required String caseId,
    required String sampleId,
    required String evidenceId,
    required String extension,
  }) async {
    _validateId(caseId, 'caseId');
    _validateId(sampleId, 'sampleId');
    _validateId(evidenceId, 'evidenceId');
    final normalizedExtension = extension.replaceFirst(RegExp(r'^\.'), '');
    if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(normalizedExtension)) {
      throw ArgumentError.value(extension, 'extension');
    }
    final directory = Directory(
      p.join(rootDirectory.path, 'evidence', caseId, sampleId),
    );
    await directory.create(recursive: true);
    return p.join(directory.path, '$evidenceId.$normalizedExtension');
  }

  @override
  Future<String> importExistingFile({
    required String sourcePath,
    required String caseId,
    required String sampleId,
    required String evidenceId,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) throw StateError('Evidence source is missing.');
    final extension = p.extension(sourcePath).replaceFirst('.', '');
    if (extension.isEmpty) {
      throw ArgumentError.value(sourcePath, 'sourcePath', 'Missing extension.');
    }
    final destination = await reservePath(
      caseId: caseId,
      sampleId: sampleId,
      evidenceId: evidenceId,
      extension: extension,
    );
    await source.copy(destination);
    return destination;
  }

  @override
  Future<String> calculateSha256(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw StateError('Evidence file is missing.');
    return sha256.bind(file.openRead()).first.then((digest) => '$digest');
  }

  @override
  Future<void> writeBytes(String filePath, Uint8List bytes) async {
    final resolvedRoot = p.normalize(p.absolute(rootDirectory.path));
    final resolvedFile = p.normalize(p.absolute(filePath));
    if (!p.isWithin(resolvedRoot, resolvedFile)) {
      throw ArgumentError('File is outside the evidence storage root.');
    }
    await File(resolvedFile).writeAsBytes(bytes, flush: true);
  }

  @override
  Future<bool> exists(String filePath) => File(filePath).exists();

  @override
  Future<bool> verify(String filePath, String expectedSha256) async {
    if (!await exists(filePath)) return false;
    return await calculateSha256(filePath) == expectedSha256.toLowerCase();
  }

  @override
  Future<void> deleteTemporary(
    String filePath, {
    required bool sampleClosed,
  }) async {
    if (sampleClosed) {
      throw StateError('Evidence for a closed sample cannot be deleted.');
    }
    final resolvedRoot = p.normalize(p.absolute(rootDirectory.path));
    final resolvedFile = p.normalize(p.absolute(filePath));
    if (!p.isWithin(resolvedRoot, resolvedFile)) {
      throw ArgumentError('File is outside the evidence storage root.');
    }
    final file = File(resolvedFile);
    if (await file.exists()) await file.delete();
  }

  void _validateId(String value, String name) {
    if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(value)) {
      throw ArgumentError.value(value, name);
    }
  }
}
