import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../domain/models.dart';

final class RemoteUserSession {
  const RemoteUserSession({required this.token, required this.user});
  final String token;
  final User user;
}

abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

final class SecureTokenStore implements TokenStore {
  const SecureTokenStore([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;
  static const _key = 'ddr001_api_token';
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}

final class RemoteApiClient {
  RemoteApiClient({required String baseUrl, http.Client? client})
    : baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
      _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<RemoteUserSession> login({
    required String displayName,
    required String email,
    required String phone,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'display_name': displayName,
        'email': email,
        'phone': phone,
      }),
    );
    final body = _decode(response);
    final user = body['user'] as Map<String, Object?>;
    return RemoteUserSession(
      token: body['token']! as String,
      user: User(
        id: user['user_id']! as String,
        displayName: user['display_name'] as String?,
        email: user['email']! as String,
        phone: user['phone']! as String,
        createdAt: DateTime.now().toUtc(),
        lastLoginAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> logout(String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/auth/logout'),
      headers: _headers(token),
    );
    if (response.statusCode != 204) _decode(response);
  }

  Future<Meter> lookupMeter(String meterId, String token) async {
    final response = await _client.get(
      Uri.parse(
        '$baseUrl/api/v1/external/hydrants/accounts/${Uri.encodeComponent(meterId)}',
      ),
      headers: _headers(token),
    );
    final body = _decode(response);
    final status = switch (body['status']) {
      'FOUND_WITH_SURVEY' => ExternalMeterStatus.foundWithSurvey,
      'FOUND_NO_SURVEY' => ExternalMeterStatus.foundNoSurvey,
      'NOT_FOUND' => ExternalMeterStatus.notFound,
      _ => ExternalMeterStatus.unknownOffline,
    };
    final now = DateTime.now().toUtc();
    return Meter(
      id: meterId,
      externalStatus: status,
      externalSnapshotJson: jsonEncode(body['data']),
      externalCheckedAt: now,
      createdAt: now,
    );
  }

  Future<void> postJson(String path, String token, Object payload) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
      body: jsonEncode(payload),
    );
    _decode(response);
  }

  Future<void> uploadEvidence({
    required String token,
    required Evidence evidence,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/v1/evidence'),
    )..headers['authorization'] = 'Bearer $token';
    request.fields['metadata'] = jsonEncode({
      'evidence_id': evidence.id,
      'sample_id': evidence.sampleId,
      'type': evidence.type.name.toUpperCase(),
      'required': evidence.required,
      'volume_ref_l': evidence.volumeRefLiters,
      'pulse_count': evidence.pulseCount,
      'captured_at': evidence.capturedAt.toUtc().toIso8601String(),
      'sha256': evidence.sha256,
    });
    request.files.add(
      await http.MultipartFile.fromPath('file', evidence.localPath),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _decode(response);
  }

  Map<String, Object?> _decode(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, Object?>{}
        : jsonDecode(response.body) as Map<String, Object?>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'] as Map<String, Object?>?;
      throw HttpException(
        error?['message'] as String? ?? 'HTTP ${response.statusCode}',
        uri: response.request?.url,
      );
    }
    return decoded;
  }

  Map<String, String> _headers(String token) => {
    'content-type': 'application/json',
    'authorization': 'Bearer $token',
  };
}
