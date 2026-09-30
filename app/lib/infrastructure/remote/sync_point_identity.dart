import 'dart:convert';

import 'package:uuid/uuid.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Transport identity only. Local point IDs and frozen checksums never change.
/// Keep this namespace and name encoding stable across releases/retries.
String syncPointId(String sampleId, String localPointId) =>
    _uuidPattern.hasMatch(localPointId)
    ? localPointId
    : const Uuid().v5(
        '6ba7b811-9dad-11d1-80b4-00c04fd430c8',
        jsonEncode([
          'ddr001.functional.point/v1',
          sampleId.toLowerCase(),
          localPointId,
        ]),
      );

/// Narrow repair of a request explicitly rejected before any receipt exists.
/// Returns true only when a transport point identity was changed.
bool normalizeSyncPointIds(Map<String, Object?> request) {
  var changed = false;
  final items = request['items'] as List;
  for (final raw in items) {
    final item = raw as Map<String, Object?>;
    if (item['entityType'] != 'POINT' && item['entityType'] != 'EVIDENCE_REF') {
      continue;
    }
    final payload = item['payload'] as Map<String, Object?>;
    final pointId = payload['pointId'];
    final sampleId = payload['sampleId'];
    if (pointId is! String || sampleId is! String) continue;
    final remoteId = syncPointId(sampleId, pointId);
    if (remoteId == pointId) continue;
    if (item['entityType'] == 'POINT' && item['entityId'] != pointId) {
      throw StateError('Point identity does not match its payload.');
    }
    payload['pointId'] = remoteId;
    if (item['entityType'] == 'POINT') item['entityId'] = remoteId;
    changed = true;
  }
  return changed;
}
