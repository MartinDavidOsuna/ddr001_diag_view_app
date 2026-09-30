import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models.dart';
import 'sync_point_identity.dart';

const functionalClientApp = 'ddr001_diag_view';

final class RemoteCredentials {
  const RemoteCredentials({
    required this.accessToken,
    required this.refreshToken,
    required this.sessionId,
    required this.remoteUserId,
  });

  final String accessToken;
  final String refreshToken;
  final String sessionId;
  final String remoteUserId;
}

abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

abstract interface class RemoteCredentialStore implements TokenStore {
  Future<RemoteCredentials?> readCredentials();
  Future<void> writeCredentials(RemoteCredentials credentials);
}

final class SecureRemoteCredentialStore implements RemoteCredentialStore {
  const SecureRemoteCredentialStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;
  static const _accessKey = 'ddr001_diag_view.access_token';
  static const _refreshKey = 'ddr001_diag_view.refresh_token';
  static const _sessionKey = 'ddr001_diag_view.work_session_id';
  static const _userKey = 'ddr001_diag_view.rv_user_id';

  @override
  Future<String?> read() => _storage.read(key: _accessKey);

  @override
  Future<void> write(String token) =>
      _storage.write(key: _accessKey, value: token);

  @override
  Future<RemoteCredentials?> readCredentials() async {
    final values = await Future.wait([
      _storage.read(key: _accessKey),
      _storage.read(key: _refreshKey),
      _storage.read(key: _sessionKey),
      _storage.read(key: _userKey),
    ]);
    if (values.any((value) => value == null || value.isEmpty)) return null;
    return RemoteCredentials(
      accessToken: values[0]!,
      refreshToken: values[1]!,
      sessionId: values[2]!,
      remoteUserId: values[3]!,
    );
  }

  @override
  Future<void> writeCredentials(RemoteCredentials credentials) async {
    await _storage.write(key: _accessKey, value: credentials.accessToken);
    await _storage.write(key: _refreshKey, value: credentials.refreshToken);
    await _storage.write(key: _sessionKey, value: credentials.sessionId);
    await _storage.write(key: _userKey, value: credentials.remoteUserId);
  }

  @override
  Future<void> clear() async {
    for (final key in [_accessKey, _refreshKey, _sessionKey, _userKey]) {
      await _storage.delete(key: key);
    }
  }
}

abstract interface class InstallationIdStore {
  Future<String> readOrCreate();
}

final class SecureInstallationIdStore implements InstallationIdStore {
  const SecureInstallationIdStore([
    this._storage = const FlutterSecureStorage(),
    this._uuid = const Uuid(),
  ]);

  final FlutterSecureStorage _storage;
  final Uuid _uuid;
  static const _key = 'ddr001_diag_view.installation_id';

  @override
  Future<String> readOrCreate() async {
    final existing = await _storage.read(key: _key);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = _uuid.v4();
    await _storage.write(key: _key, value: created);
    return created;
  }
}

final class RemoteDeviceRegistration {
  const RemoteDeviceRegistration({
    required this.installationId,
    required this.platform,
    required this.manufacturer,
    required this.model,
    required this.androidVersion,
    required this.appVersion,
  });

  final String installationId;
  final String platform;
  final String manufacturer;
  final String model;
  final String androidVersion;
  final String appVersion;
}

final class FunctionalAccess {
  const FunctionalAccess({
    required this.remoteUserId,
    required this.enabled,
    required this.policyVersion,
    this.manualCorrectionsReady = false,
  });

  final String remoteUserId;
  final bool enabled;
  final int policyVersion;
  final bool manualCorrectionsReady;
}

final class EvidenceUploadAck {
  const EvidenceUploadAck({required this.status, required this.storageKey});
  final String status;
  final String storageKey;
}

final class SyncItemAck {
  const SyncItemAck({
    required this.itemId,
    required this.entityType,
    required this.entityId,
    required this.status,
    required this.code,
    required this.retryable,
  });
  final String itemId;
  final String entityType;
  final String entityId;
  final String status;
  final String code;
  final bool retryable;
}

final class SyncReceiptAck {
  const SyncReceiptAck({
    required this.receiptId,
    required this.status,
    required this.items,
    this.appliedCorrectionIds = const [],
    this.caseChecksum,
  });
  final List<String> appliedCorrectionIds;
  final String? caseChecksum;
  final String receiptId;
  final String status;
  final List<SyncItemAck> items;

  bool get hasConflict => items.any((item) => item.status == 'conflict');
  bool get hasRejected => items.any((item) => item.status == 'rejected');
  bool get hasRetryableRejection =>
      items.any((item) => item.status == 'rejected' && item.retryable);
}

enum RemoteFailureKind {
  unauthorized,
  forbidden,
  conflict,
  validation,
  rateLimited,
  transient,
  notFound,
  permanent,
}

final class RemoteApiException implements Exception {
  const RemoteApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.code,
    this.operation,
    this.requestId,
    this.validationIssues = const [],
  });

  final RemoteFailureKind kind;
  final String message;
  final int? statusCode;
  final String? code;
  final String? operation;
  final String? requestId;
  final List<String> validationIssues;

  String get diagnosticMessage => [
    ?operation,
    if (statusCode != null && message != 'HTTP $statusCode') 'HTTP $statusCode',
    message,
    if (validationIssues.isNotEmpty) 'Campos: ${validationIssues.join('; ')}',
    if (requestId != null) 'Ref. $requestId',
  ].join(' · ');

  bool get retryable => switch (kind) {
    RemoteFailureKind.rateLimited || RemoteFailureKind.transient => true,
    _ => false,
  };

  @override
  String toString() => message;
}

final class RemoteApiClient {
  RemoteApiClient({
    required String baseUrl,
    required this.credentials,
    http.Client? client,
    this.jsonTimeout = const Duration(seconds: 20),
    this.uploadTimeout = const Duration(minutes: 2),
  }) : baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
       _client = client ?? http.Client();

  final String baseUrl;
  final RemoteCredentialStore credentials;
  final http.Client _client;
  final Duration jsonTimeout;
  final Duration uploadTimeout;

  Future<RemoteCredentials> login({
    required String displayName,
    required String email,
    required String phone,
    required RemoteDeviceRegistration device,
  }) async {
    final response = await _network(
      () => _client
          .post(
            Uri.parse('$baseUrl/api/v1/field-sessions/start'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'name': displayName,
              'email': email,
              'phone': ddrPhone(phone),
              'client_app': functionalClientApp,
              'device': {
                'installationId': device.installationId,
                'platform': device.platform,
                'manufacturer': device.manufacturer,
                'model': device.model,
                'androidVersion': device.androidVersion,
                'appVersion': device.appVersion,
              },
            }),
          )
          .timeout(jsonTimeout),
    );
    final body = _decode(response, operation: 'Inicio de sesión');
    final result = RemoteCredentials(
      accessToken: body['accessToken']! as String,
      refreshToken: body['refreshToken']! as String,
      sessionId: body['sessionId']! as String,
      remoteUserId: body['userId']! as String,
    );
    await credentials.writeCredentials(result);
    return result;
  }

  Future<FunctionalAccess> access() async {
    final body = await _authorizedJson(
      'GET',
      '/api/v1/functional-diagnostics/me/access',
    );
    final data = body['data']! as Map<String, Object?>;
    return FunctionalAccess(
      remoteUserId: data['userId']! as String,
      enabled: data['accessEnabled']! as bool,
      policyVersion: data['policyVersion']! as int,
      manualCorrectionsReady: _supportsManualCorrections(data['capabilities']),
    );
  }

  Future<void> logout() async {
    final current = await credentials.readCredentials();
    if (current == null) return;
    await _authorizedJson(
      'POST',
      '/api/v1/field-sessions/${current.sessionId}/end',
    );
  }

  Future<EvidenceUploadAck> uploadEvidence(Evidence evidence) async {
    final file = File(evidence.localPath);
    if (!await file.exists()) {
      throw const RemoteApiException(
        kind: RemoteFailureKind.permanent,
        message: 'Falta el archivo local de la evidencia.',
        code: 'LOCAL_EVIDENCE_MISSING',
      );
    }
    final declaredHash = evidence.sha256;
    if (declaredHash == null || declaredHash.length != 64) {
      throw const RemoteApiException(
        kind: RemoteFailureKind.validation,
        message: 'La evidencia no tiene SHA-256 válido.',
        code: 'LOCAL_EVIDENCE_HASH_MISSING',
      );
    }
    final bytes = await file.readAsBytes();
    final actualHash = sha256.convert(bytes).toString();
    if (actualHash != declaredHash) {
      throw const RemoteApiException(
        kind: RemoteFailureKind.conflict,
        message: 'La evidencia local no coincide con su SHA-256 congelado.',
        code: 'LOCAL_EVIDENCE_HASH_MISMATCH',
      );
    }
    final length = await file.length();
    final mediaType = _evidenceMediaType(bytes);
    Future<http.Response> send(String token) async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/functional-diagnostics/evidence'),
      )..headers['authorization'] = 'Bearer $token';
      request.fields['metadata'] = jsonEncode({
        'schema': 'functional-diagnostics.evidence/v1',
        'evidenceId': evidence.id,
        'sampleId': evidence.sampleId,
        if (evidence.pointId != null)
          'pointId': syncPointId(evidence.sampleId, evidence.pointId!),
        'type': _evidenceType(evidence.type),
        'required': evidence.required,
        if (evidence.volumeRefLiters != null)
          'volumeRefL': evidence.volumeRefLiters,
        if (evidence.pulseCount != null) 'pulseCount': evidence.pulseCount,
        'capturedAt': evidence.capturedAt.toUtc().toIso8601String(),
        'sha256': declaredHash,
        'sizeBytes': length,
      });
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.uri.pathSegments.last,
          contentType: mediaType,
        ),
      );
      return http.Response.fromStream(
        await _client.send(request).timeout(uploadTimeout),
      );
    }

    final response = await _authorized(send);
    final data =
        _decode(response, operation: 'Subida de fotografía')['data']!
            as Map<String, Object?>;
    return EvidenceUploadAck(
      status: data['status']! as String,
      storageKey: data['storageKey']! as String,
    );
  }

  Future<SyncReceiptAck> pushSync(Map<String, Object?> request) async {
    final body = await _authorizedJson(
      'POST',
      '/api/v1/functional-diagnostics/sync/push',
      body: request,
    );
    return _receipt(body['data']! as Map<String, Object?>);
  }

  Future<SyncReceiptAck?> syncStatus(String receiptId) async {
    try {
      final body = await _authorizedJson(
        'GET',
        '/api/v1/functional-diagnostics/sync/status?receiptId=${Uri.encodeQueryComponent(receiptId)}',
      );
      return _receipt(body['data']! as Map<String, Object?>);
    } on RemoteApiException catch (error) {
      if (error.kind == RemoteFailureKind.notFound) return null;
      rethrow;
    }
  }

  Future<Map<String, Object?>> listCases({int limit = 50}) => _authorizedJson(
    'GET',
    '/api/v1/functional-diagnostics/cases?limit=$limit',
  );

  Future<Map<String, Object?>> caseDetail(String caseId) => _authorizedJson(
    'GET',
    '/api/v1/functional-diagnostics/cases/${Uri.encodeComponent(caseId)}',
  );

  Future<Map<String, Object?>> _authorizedJson(
    String method,
    String path, {
    Object? body,
  }) async {
    final response = await _authorized((token) {
      final uri = Uri.parse('$baseUrl$path');
      final headers = {
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      };
      return switch (method) {
        'GET' => _client.get(uri, headers: headers).timeout(jsonTimeout),
        'POST' =>
          _client
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(jsonTimeout),
        _ => throw ArgumentError.value(method, 'method'),
      };
    });
    return _decode(response, operation: _operationFor(path));
  }

  Future<http.Response> _authorized(
    Future<http.Response> Function(String token) send,
  ) async {
    var current = await credentials.readCredentials();
    if (current == null) {
      throw const RemoteApiException(
        kind: RemoteFailureKind.unauthorized,
        message: 'No existe una sesión remota activa.',
        code: 'REMOTE_SESSION_REQUIRED',
      );
    }
    var response = await _network(() => send(current!.accessToken));
    if (response.statusCode != 401) return response;
    try {
      current = await _refresh(current);
    } on RemoteApiException catch (error) {
      if (error.kind == RemoteFailureKind.unauthorized) {
        await credentials.clear();
      }
      rethrow;
    }
    response = await _network(() => send(current!.accessToken));
    if (response.statusCode == 401) await credentials.clear();
    return response;
  }

  Future<RemoteCredentials> _refresh(RemoteCredentials current) async {
    final response = await _network(
      () => _client
          .post(
            Uri.parse('$baseUrl/api/v1/field-sessions/refresh'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({'refreshToken': current.refreshToken}),
          )
          .timeout(jsonTimeout),
    );
    final body = _decode(response, operation: 'Renovación de sesión');
    final refreshed = RemoteCredentials(
      accessToken: body['accessToken']! as String,
      refreshToken: body['refreshToken']! as String,
      sessionId: current.sessionId,
      remoteUserId: current.remoteUserId,
    );
    await credentials.writeCredentials(refreshed);
    return refreshed;
  }

  Future<T> _network<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on TimeoutException {
      throw const RemoteApiException(
        kind: RemoteFailureKind.transient,
        message: 'La solicitud remota agotó el tiempo de espera.',
        code: 'NETWORK_TIMEOUT',
      );
    } on SocketException {
      throw const RemoteApiException(
        kind: RemoteFailureKind.transient,
        message: 'No fue posible conectar con DDR001.',
        code: 'NETWORK_UNAVAILABLE',
      );
    } on http.ClientException {
      throw const RemoteApiException(
        kind: RemoteFailureKind.transient,
        message: 'No fue posible completar la solicitud remota.',
        code: 'NETWORK_CLIENT_ERROR',
      );
    }
  }

  static String _operationFor(String path) {
    if (path.contains('/me/access')) return 'Verificación de acceso';
    if (path.contains('/sync/push')) return 'Envío del expediente';
    if (path.contains('/sync/status')) return 'Confirmación del envío';
    if (path.contains('/field-sessions/')) return 'Cierre de sesión';
    return 'Consulta remota';
  }

  Map<String, Object?> _decode(
    http.Response response, {
    required String operation,
  }) {
    Map<String, Object?> decoded = {};
    var validObject = false;
    try {
      final value = jsonDecode(response.body);
      if (value is Map<String, Object?>) {
        decoded = value;
        validObject = true;
      }
    } on FormatException {
      // HTML/plain-text proxy errors must retain their HTTP failure category.
      // Never display the raw response body, which can contain internal data.
    }
    final success = response.statusCode >= 200 && response.statusCode < 300;
    if (success) {
      if (validObject || response.body.isEmpty) return decoded;
      throw RemoteApiException(
        kind: RemoteFailureKind.transient,
        message: 'El servidor devolvió una respuesta no válida.',
        statusCode: response.statusCode,
        code: 'REMOTE_INVALID_RESPONSE',
        operation: operation,
      );
    }
    String? text(Object? value) {
      if (value is! String || value.trim().isEmpty) return null;
      final clean = value.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), ' ').trim();
      return clean.length > 240 ? '${clean.substring(0, 240)}…' : clean;
    }

    final nested = decoded['error'];
    final error = nested is Map<String, Object?> ? nested : null;
    final code =
        text(error?['code']) ??
        text(decoded['code']) ??
        text(decoded['domainCode']);
    final message =
        text(error?['message']) ??
        text(decoded['detail']) ??
        text(decoded['title']) ??
        'HTTP ${response.statusCode}';
    String? requestId;
    for (final value in [
      error?['requestId'],
      decoded['requestId'],
      response.headers['x-request-id'],
    ]) {
      if (value is String &&
          RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
          ).hasMatch(value)) {
        requestId = value;
        break;
      }
    }
    final details = error?['details'];
    final issuesValue = details is Map<String, Object?>
        ? details['issues']
        : null;
    final rawIssues = issuesValue ?? decoded['errors'];
    final validationIssues = <String>[];
    if (rawIssues is List) {
      for (final issue in rawIssues.take(8)) {
        if (issue is! Map<String, Object?>) continue;
        final path = issue['path'];
        if (path is! List) continue;
        final segments = <String>[];
        for (final segment in path.take(12)) {
          if (segment is int && segment >= 0) {
            segments.add('[$segment]');
          } else if (segment is String &&
              RegExp(r'^[A-Za-z_][A-Za-z0-9_]{0,63}$').hasMatch(segment)) {
            segments.add('${segments.isEmpty ? '' : '.'}$segment');
          }
        }
        final field = segments.isEmpty ? 'lote' : segments.join();
        final issueCode = issue['code'];
        final safeCode =
            issueCode is String && RegExp(r'^[a-z_]{1,40}$').hasMatch(issueCode)
            ? issueCode
            : 'invalid';
        // Only paths and classification: never echo received values or raw bodies.
        validationIssues.add('$field ($safeCode)');
      }
      if (rawIssues.length > 8) {
        validationIssues.add('y ${rawIssues.length - 8} más');
      }
    }
    final kind = switch (response.statusCode) {
      401 => RemoteFailureKind.unauthorized,
      403 => RemoteFailureKind.forbidden,
      404 => RemoteFailureKind.notFound,
      409 => RemoteFailureKind.conflict,
      422 || 413 || 415 => RemoteFailureKind.validation,
      429 => RemoteFailureKind.rateLimited,
      500 || 502 || 503 || 504 => RemoteFailureKind.transient,
      _ => RemoteFailureKind.permanent,
    };
    throw RemoteApiException(
      kind: kind,
      message: message,
      statusCode: response.statusCode,
      code: code,
      operation: operation,
      requestId: requestId,
      validationIssues: List.unmodifiable(validationIssues),
    );
  }
}

MediaType _evidenceMediaType(List<int> bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return MediaType('image', 'jpeg');
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a) {
    return MediaType('image', 'png');
  }
  throw const RemoteApiException(
    kind: RemoteFailureKind.validation,
    message: 'La evidencia local no es una imagen JPEG o PNG válida.',
    code: 'LOCAL_EVIDENCE_MIME_UNSUPPORTED',
  );
}

SyncReceiptAck _receipt(Map<String, Object?> data) => SyncReceiptAck(
  receiptId: data['receiptId']! as String,
  appliedCorrectionIds:
      (data['appliedCorrectionIds'] as List?)?.whereType<String>().toList() ??
      const [],
  caseChecksum: data['caseChecksum'] as String?,
  status: data['status']! as String,
  items: (data['items']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .map(
        (item) => SyncItemAck(
          itemId: item['itemId']! as String,
          entityType: item['entityType']! as String,
          entityId: item['entityId']! as String,
          status: item['status']! as String,
          code: item['code']! as String,
          retryable: item['retryable']! as bool,
        ),
      )
      .toList(growable: false),
);

String canonicalJson(Object? value) {
  if (value == null || value is bool || value is String) {
    return jsonEncode(value);
  }
  if (value is num) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'Non-finite JSON number');
    }
    // Match JSON.stringify, used by ddr001_api: JavaScript does not preserve
    // Dart's lexical distinction between an integral double (2.0) and 2.
    if (value == 0) return '0';
    if (value is double && value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return jsonEncode(value);
  }
  if (value is List<Object?>) {
    return '[${value.map(canonicalJson).join(',')}]';
  }
  if (value is Map<String, Object?>) {
    final keys = value.keys.toList()..sort();
    return '{${keys.map((key) => '${jsonEncode(key)}:${canonicalJson(value[key])}').join(',')}}';
  }
  throw ArgumentError.value(value, 'value', 'Unsupported canonical JSON value');
}

String canonicalSha256(Object? value) =>
    sha256.convert(utf8.encode(canonicalJson(value))).toString();

String ddrPhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 10) throw ArgumentError.value(value, 'phone');
  return digits.substring(digits.length - 10);
}

String _evidenceType(EvidenceType type) => switch (type) {
  EvidenceType.start => 'START',
  EvidenceType.intermediate => 'INTERMEDIATE',
  EvidenceType.finalEvidence => 'FINAL',
  EvidenceType.extra => 'EXTRA',
};

// Explicit protocol negotiation: a server version number alone is insufficient.
bool _supportsManualCorrections(Object? capabilities) {
  if (capabilities is! Map) return false;
  final capability = capabilities['manualCorrections'];
  return capability is Map &&
      capability['ready'] == true &&
      capability['schema'] == 'functional-diagnostics.corrections/v1';
}
