import 'dart:async';
import 'dart:convert';

import 'package:ddr001_diag_view_app/infrastructure/remote/remote_api.dart';
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

  test('canonical payload hash is independent of map key order', () {
    expect(
      canonicalSha256({'b': 2, 'a': 1}),
      canonicalSha256({'a': 1, 'b': 2}),
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
