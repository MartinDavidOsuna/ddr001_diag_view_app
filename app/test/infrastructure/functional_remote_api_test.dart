import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:ddr001_diag_view_app/infrastructure/remote/remote_api.dart';
import 'package:ddr001_diag_view_app/infrastructure/remote/sync_point_identity.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'installation_id is generated once and survives store recreation',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final first = await const SecureInstallationIdStore().readOrCreate();
      final second = await const SecureInstallationIdStore().readOrCreate();
      expect(second, first);
      expect(first, matches(RegExp(r'^[0-9a-f-]{36}$')));
    },
  );

  test(
    'Field login maps DDR001 multi-app contract and checks access',
    () async {
      final store = _MemoryCredentialStore();
      final requests = <http.Request>[];
      final client = RemoteApiClient(
        baseUrl: 'https://test.invalid',
        credentials: store,
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/field-sessions/start')) {
            return http.Response(
              jsonEncode({
                'sessionId': _sessionId,
                'userId': _remoteUserId,
                'accessToken': 'access-1',
                'refreshToken': 'refresh-1',
                'tokenId': _tokenId,
              }),
              201,
            );
          }
          return http.Response(
            jsonEncode({
              'data': {
                'userId': _remoteUserId,
                'clientApp': functionalClientApp,
                'accessEnabled': true,
                'policyVersion': 1,
                'updatedAt': '2026-09-02T00:00:00.000Z',
              },
            }),
            200,
          );
        }),
      );
      await client.login(
        displayName: 'Técnico DDR001',
        email: 'field@example.com',
        phone: '+52 449 123 4567',
        device: const RemoteDeviceRegistration(
          installationId: _installationId,
          platform: 'android',
          manufacturer: 'Google',
          model: 'Pixel 7 Pro',
          androidVersion: '16',
          appVersion: '1.4.0+15',
        ),
      );
      final access = await client.access();
      final loginBody = jsonDecode(requests.first.body) as Map<String, Object?>;
      expect(loginBody['client_app'], functionalClientApp);
      expect(loginBody['phone'], '4491234567');
      expect(
        (loginBody['device'] as Map<String, Object?>)['installationId'],
        _installationId,
      );
      expect(access.enabled, isTrue);
      expect((await store.readCredentials())?.remoteUserId, _remoteUserId);
    },
  );

  test('one 401 rotates refresh token and retries the request once', () async {
    final store = _MemoryCredentialStore.seeded();
    var accessCalls = 0;
    var refreshCalls = 0;
    final client = RemoteApiClient(
      baseUrl: 'https://test.invalid',
      credentials: store,
      client: MockClient((request) async {
        if (request.url.path.endsWith('/field-sessions/refresh')) {
          refreshCalls++;
          return http.Response(
            jsonEncode({
              'accessToken': 'access-2',
              'refreshToken': 'refresh-2',
              'tokenId': _tokenId,
            }),
            200,
          );
        }
        accessCalls++;
        if (accessCalls == 1) return http.Response('{}', 401);
        expect(request.headers['authorization'], 'Bearer access-2');
        return http.Response(
          jsonEncode({
            'data': {
              'userId': _remoteUserId,
              'clientApp': functionalClientApp,
              'accessEnabled': true,
              'policyVersion': 1,
              'updatedAt': '2026-09-02T00:00:00.000Z',
            },
          }),
          200,
        );
      }),
    );

    expect((await client.access()).enabled, isTrue);
    expect(refreshCalls, 1);
    expect(accessCalls, 2);
    expect((await store.readCredentials())?.refreshToken, 'refresh-2');
  });

  test('a second 401 does not enter a refresh loop', () async {
    final store = _MemoryCredentialStore.seeded();
    var refreshCalls = 0;
    final client = RemoteApiClient(
      baseUrl: 'https://test.invalid',
      credentials: store,
      client: MockClient((request) async {
        if (request.url.path.endsWith('/field-sessions/refresh')) {
          refreshCalls++;
          return http.Response(
            jsonEncode({
              'accessToken': 'access-2',
              'refreshToken': 'refresh-2',
              'tokenId': _tokenId,
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'error': {'code': 'TOKEN_EXPIRED', 'message': 'expired'},
          }),
          401,
        );
      }),
    );

    await expectLater(
      client.access(),
      throwsA(
        isA<RemoteApiException>().having(
          (error) => error.kind,
          'kind',
          RemoteFailureKind.unauthorized,
        ),
      ),
    );
    expect(refreshCalls, 1);
    expect(await store.readCredentials(), isNull);
  });

  test('network timeout is typed retryable', () async {
    final store = _MemoryCredentialStore.seeded();
    final client = RemoteApiClient(
      baseUrl: 'https://test.invalid',
      credentials: store,
      jsonTimeout: const Duration(milliseconds: 10),
      client: MockClient((_) => Completer<http.Response>().future),
    );
    await expectLater(
      client.access(),
      throwsA(
        isA<RemoteApiException>()
            .having((error) => error.retryable, 'retryable', isTrue)
            .having((error) => error.code, 'code', 'NETWORK_TIMEOUT'),
      ),
    );
  });

  for (final status in const [429, 500, 502, 503, 504]) {
    test(
      'HTTP $status is typed retryable without clearing credentials',
      () async {
        final store = _MemoryCredentialStore.seeded();
        final client = RemoteApiClient(
          baseUrl: 'https://test.invalid',
          credentials: store,
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'error': {'code': 'REMOTE_RETRYABLE', 'message': 'retry later'},
              }),
              status,
            ),
          ),
        );

        await expectLater(
          client.access(),
          throwsA(
            isA<RemoteApiException>().having(
              (error) => error.retryable,
              'retryable',
              isTrue,
            ),
          ),
        );
        expect(await store.readCredentials(), isNotNull);
      },
    );
  }

  test(
    'Field problem JSON retains login stage, detail and request ID',
    () async {
      final store = _MemoryCredentialStore();
      final paths = <String>[];
      final api = RemoteApiClient(
        baseUrl: 'http://test.invalid',
        credentials: store,
        client: MockClient((request) async {
          paths.add(request.url.path);
          return http.Response(
            jsonEncode({
              'title': 'Internal server error',
              'detail': 'An unexpected error occurred.',
              'requestId': _tokenId,
            }),
            500,
            headers: {'content-type': 'application/problem+json'},
          );
        }),
      );
      await expectLater(
        api.login(
          displayName: 'Test Operator',
          email: 'test@example.invalid',
          phone: '4491234567',
          device: const RemoteDeviceRegistration(
            installationId: _installationId,
            platform: 'android',
            manufacturer: 'Google',
            model: 'Pixel 7 Pro',
            androidVersion: '16',
            appVersion: '1.7.3+22',
          ),
        ),
        throwsA(
          isA<RemoteApiException>()
              .having(
                (e) => e.message,
                'detail',
                'An unexpected error occurred.',
              )
              .having((e) => e.operation, 'operation', 'Inicio de sesión')
              .having((e) => e.requestId, 'requestId', _tokenId)
              .having(
                (e) => e.diagnosticMessage,
                'visible diagnostic',
                contains('HTTP 500'),
              )
              .having((e) => e.retryable, 'retryable', isTrue),
        ),
      );
      expect(paths, ['/api/v1/field-sessions/start']);
      expect(await store.readCredentials(), isNull);
    },
  );

  test(
    'refresh 500 identifies refresh rather than the original access request',
    () async {
      final store = _MemoryCredentialStore.seeded();
      final api = RemoteApiClient(
        baseUrl: 'http://test.invalid',
        credentials: store,
        client: MockClient(
          (request) async => request.url.path.endsWith('/refresh')
              ? http.Response(
                  jsonEncode({'detail': 'Refresh unavailable'}),
                  500,
                  headers: {'x-request-id': _tokenId},
                )
              : http.Response('{}', 401),
        ),
      );
      await expectLater(
        api.access(),
        throwsA(
          isA<RemoteApiException>()
              .having((e) => e.operation, 'operation', 'Renovación de sesión')
              .having((e) => e.requestId, 'requestId', _tokenId),
        ),
      );
      expect((await store.readCredentials())?.accessToken, 'access-1');
    },
  );

  for (final body in [
    '<html>private proxy details</html>',
    '[1,2]',
    '{"error":"bad"}',
    '',
  ]) {
    test('non-contract HTTP 500 remains retryable: $body', () async {
      final store = _MemoryCredentialStore.seeded();
      final api = RemoteApiClient(
        baseUrl: 'http://test.invalid',
        credentials: store,
        client: MockClient((_) async => http.Response(body, 500)),
      );
      await expectLater(
        api.access(),
        throwsA(
          isA<RemoteApiException>()
              .having((e) => e.retryable, 'retryable', isTrue)
              .having((e) => e.message, 'safe message', 'HTTP 500')
              .having(
                (e) => e.operation,
                'operation',
                'Verificación de acceso',
              ),
        ),
      );
      expect(await store.readCredentials(), isNotNull);
    });
  }

  test(
    'nested errors retain code and request ID on batch submission',
    () async {
      final api = RemoteApiClient(
        baseUrl: 'http://test.invalid',
        credentials: _MemoryCredentialStore.seeded(),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {
                'code': 'INTERNAL_ERROR',
                'message': 'Server unavailable',
                'requestId': _tokenId,
              },
            }),
            500,
          ),
        ),
      );
      await expectLater(
        api.pushSync({}),
        throwsA(
          isA<RemoteApiException>()
              .having((e) => e.code, 'code', 'INTERNAL_ERROR')
              .having((e) => e.requestId, 'requestId', _tokenId)
              .having((e) => e.operation, 'operation', 'Envío del expediente'),
        ),
      );
    },
  );

  for (final fieldFormat in [false, true]) {
    test(
      '422 exposes field paths without received values: $fieldFormat',
      () async {
        final issues = [
          {
            'path': ['items', 4, 'payload', 'testBenchId'],
            'code': 'too_small',
            'message': 'private received value',
            'received': 'private received value',
          },
          {
            'path': ['items', 7, 'payload', 'meterFace', 'dial', 'radius'],
            'code': 'invalid_type',
          },
        ];
        final body = fieldFormat
            ? {'detail': 'One or more fields are invalid.', 'errors': issues}
            : {
                'error': {
                  'code': 'VALIDATION_FAILED',
                  'message': 'One or more fields are invalid.',
                  'details': {'issues': issues},
                },
              };
        final api = RemoteApiClient(
          baseUrl: 'http://test.invalid',
          credentials: _MemoryCredentialStore.seeded(),
          client: MockClient((_) async => http.Response(jsonEncode(body), 422)),
        );
        await expectLater(
          api.pushSync({}),
          throwsA(
            isA<RemoteApiException>()
                .having((e) => e.validationIssues, 'field issues', [
                  'items[4].payload.testBenchId (too_small)',
                  'items[7].payload.meterFace.dial.radius (invalid_type)',
                ])
                .having(
                  (e) => e.diagnosticMessage,
                  'no received values',
                  isNot(contains('private received value')),
                )
                .having(
                  (e) => e.retryable,
                  'not retryable without correction',
                  isFalse,
                ),
          ),
        );
      },
    );
  }

  test('canonical payload hash is independent of map key order', () {
    expect(
      canonicalSha256({'b': 2, 'a': 1}),
      canonicalSha256({'a': 1, 'b': 2}),
    );
  });

  test('canonical numbers match JavaScript JSON.stringify semantics', () {
    expect(
      canonicalJson({'a': 2.0, 'b': -0.0, 'c': -0.9142135623731094}),
      '{"a":2,"b":0,"c":-0.9142135623731094}',
    );
    expect(
      canonicalSha256({'a': 2.0, 'b': -0.0, 'c': -0.9142135623731094}),
      'eab998d4ecd6e41e8647cea483fa559ff03d33758cbb8da988d44a5bc0759d66',
    );
  });

  test('Evidence upload declares MIME detected from image bytes', () async {
    final file = File('assets/simulation/simulation_evidence_placeholder.png');
    final bytes = await file.readAsBytes();
    final transport = _CapturingMultipartClient();
    final client = RemoteApiClient(
      baseUrl: 'https://test.invalid',
      credentials: _MemoryCredentialStore.seeded(),
      client: transport,
    );
    await client.uploadEvidence(
      Evidence(
        id: '55555555-5555-4555-8555-555555555555',
        sampleId: '66666666-6666-4666-8666-666666666666',
        pointId: 'point-55555555-5555-4555-8555-555555555555',
        type: EvidenceType.start,
        required: true,
        capturedAt: DateTime.utc(2026, 9, 2),
        sha256: sha256.convert(bytes).toString(),
        localPath: file.path,
        syncStatus: EvidenceSyncStatus.pending,
      ),
    );
    expect(transport.contentType, 'image/png');
    expect(
      transport.metadata?['pointId'],
      syncPointId(
        '66666666-6666-4666-8666-666666666666',
        'point-55555555-5555-4555-8555-555555555555',
      ),
    );
  });
}

const _installationId = '11111111-1111-4111-8111-111111111111';
const _sessionId = '22222222-2222-4222-8222-222222222222';
const _remoteUserId = '33333333-3333-4333-8333-333333333333';
const _tokenId = '44444444-4444-4444-8444-444444444444';

final class _MemoryCredentialStore implements RemoteCredentialStore {
  _MemoryCredentialStore();
  _MemoryCredentialStore.seeded()
    : value = const RemoteCredentials(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        sessionId: _sessionId,
        remoteUserId: _remoteUserId,
      );

  RemoteCredentials? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value?.accessToken;

  @override
  Future<RemoteCredentials?> readCredentials() async => value;

  @override
  Future<void> write(String token) async {
    final current = value;
    if (current == null) return;
    value = RemoteCredentials(
      accessToken: token,
      refreshToken: current.refreshToken,
      sessionId: current.sessionId,
      remoteUserId: current.remoteUserId,
    );
  }

  @override
  Future<void> writeCredentials(RemoteCredentials credentials) async {
    value = credentials;
  }
}

final class _CapturingMultipartClient extends http.BaseClient {
  String? contentType;
  Map<String, Object?>? metadata;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final multipart = request as http.MultipartRequest;
    contentType = multipart.files.single.contentType.toString();
    metadata =
        jsonDecode(multipart.fields['metadata']!) as Map<String, Object?>;
    await request.finalize().drain<void>();
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          jsonEncode({
            'data': {
              'status': 'created',
              'storageKey': '55555555-5555-4555-8555-555555555555',
            },
          }),
        ),
      ),
      201,
      headers: {'content-type': 'application/json'},
    );
  }
}
