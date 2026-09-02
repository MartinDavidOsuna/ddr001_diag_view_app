import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/filesystem/evidence_file_store.dart';
import '../../domain/models.dart';
import '../../domain/repositories.dart';

abstract interface class SimulationEvidenceCapturePort {
  Future<Evidence> capture({
    required String caseId,
    required Sample sample,
    required EvidenceType type,
    required double volumeRefLiters,
    required int pulseCount,
    required DateTime capturedAt,
  });
}

final class SimulationEvidenceCaptureAdapter
    implements SimulationEvidenceCapturePort {
  SimulationEvidenceCaptureAdapter(
    this.files,
    this.evidence, {
    Future<Uint8List> Function()? loadPlaceholder,
    this._uuid = const Uuid(),
  }) : _loadPlaceholder = loadPlaceholder ?? _loadBundledPlaceholder;

  static const assetPath =
      'assets/simulation/simulation_evidence_placeholder.png';

  final EvidenceFileStore files;
  final EvidenceRepository evidence;
  final Future<Uint8List> Function() _loadPlaceholder;
  final Uuid _uuid;

  static Future<Uint8List> _loadBundledPlaceholder() async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  @override
  Future<Evidence> capture({
    required String caseId,
    required Sample sample,
    required EvidenceType type,
    required double volumeRefLiters,
    required int pulseCount,
    required DateTime capturedAt,
  }) async {
    if (!sample.isSimulation) {
      throw StateError('Simulation Evidence requires a simulation Sample.');
    }
    final id = _uuid.v4();
    final path = await files.reservePath(
      caseId: caseId,
      sampleId: sample.id,
      evidenceId: id,
      extension: 'png',
    );
    final bytes = await _loadPlaceholder();
    await files.writeBytes(path, bytes);
    final hash = await files.calculateSha256(path);
    final item = Evidence(
      id: id,
      sampleId: sample.id,
      type: type,
      required: true,
      volumeRefLiters: volumeRefLiters,
      pulseCount: pulseCount,
      capturedAt: capturedAt,
      sha256: hash,
      localPath: path,
      syncStatus: EvidenceSyncStatus.local,
    );
    await evidence.save(item);
    return item;
  }
}
