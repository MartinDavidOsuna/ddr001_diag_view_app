import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../domain/models.dart';

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
  });

  final String remoteUserId;
  final bool enabled;
  final int policyVersion;
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
  });
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
  });

  final RemoteFailureKind kind;
  final String message;
  final int? statusCode;
  final String? code;
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
    final body = _decode(response);
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
    final actualHash = sha256.convert(await file.readAsBytes()).toString();
    if (actualHash != declaredHash) {
      throw const RemoteApiException(
        kind: RemoteFailureKind.conflict,
        message: 'La evidencia local no coincide con su SHA-256 congelado.',
        code: 'LOCAL_EVIDENCE_HASH_MISMATCH',
      );
    }
    final length = await file.length();
    Future<http.Response> send(String token) async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/functional-diagnostics/evidence'),
      )..headers['authorization'] = 'Bearer $token';
      request.fields['metadata'] = jsonEncode({
        'schema': 'functional-diagnostics.evidence/v1',
        'evidenceId': evidence.id,
        'sampleId': evidence.sampleId,
        if (evidence.pointId != null) 'pointId': evidence.pointId,
        'type': _evidenceType(evidence.type),
        'required': evidence.required,
        if (evidence.volumeRefLiters != null)
          'volumeRefL': evidence.volumeRefLiters,
        if (evidence.pulseCount != null) 'pulseCount': evidence.pulseCount,
        'capturedAt': evidence.capturedAt.toUtc().toIso8601String(),
        'sha256': declaredHash,
        'sizeBytes': length,
      });
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      return http.Response.fromStream(
        await _client.send(request).timeout(uploadTimeout),
      );
    }

    final response = await _authorized(send);
    final data = _decode(response)['data']! as Map<String, Object?>;
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
    return _decode(response);
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
    final body = _decode(response);
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

  Map<String, Object?> _decode(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, Object?>{}
        : jsonDecode(response.body) as Map<String, Object?>;
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;
    final error = decoded['error'] as Map<String, Object?>?;
    final code = error?['code'] as String?;
    final message =
        error?['message'] as String? ?? 'HTTP ${response.statusCode}';
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
    );
  }
}

SyncReceiptAck _receipt(Map<String, Object?> data) => SyncReceiptAck(
  receiptId: data['receiptId']! as String,
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
  if (value == null || value is bool || value is String || value is num) {
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
