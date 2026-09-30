import 'dart:convert';
import 'dart:io';

import 'package:ddr001_diag_view_app/app/app_dependencies.dart';
import 'package:ddr001_diag_view_app/data/local/database/app_database.dart'
    hide Meter, User;
import 'package:ddr001_diag_view_app/data/local/filesystem/evidence_file_store.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:ddr001_diag_view_app/infrastructure/remote/remote_api.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/presentation_fixture.dart';

void main() {
  test('remote outage falls back to the persistent local login', () async {
    final fixture = await PresentationFixture.create();
    addTearDown(fixture.dispose);
    final credentials = _Credentials();
    final api = RemoteApiClient(
      baseUrl: 'https://test.invalid',
      credentials: credentials,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'code': 'UNAVAILABLE', 'message': 'offline'},
          }),
          503,
        ),
      ),
    );
    final auth = OfflineFirstRemoteAuthService(
      local: LocalAuthService(fixture.dependencies.users, fixture.session),
      users: fixture.dependencies.users,
      credentials: credentials,
      api: api,
      installationIds: const _InstallationIds(),
      deviceMetadata: const _DeviceMetadata(),
      appVersion: () async => '1.4.0+15',
    );

    final user = await auth.login(
      displayName: 'Técnico Offline',
      email: 'offline@example.com',
      phone: '4491234567',
    );

    expect(fixture.session.userId, user.id);
    expect(await fixture.dependencies.users.getById(user.id), isNotNull);
    expect(auth.remoteNotice, contains('Sesión local activa'));
  });

  test(
    'restored offline master authenticates for sync without replacing local identity',
    () async {
      final fixture = await PresentationFixture.create();
      addTearDown(fixture.dispose);
      final credentials = _Credentials();
      var starts = 0;
      var ends = 0;
      final api = RemoteApiClient(
        baseUrl: 'https://test.invalid',
        credentials: credentials,
        client: MockClient((request) async {
          if (request.url.path.endsWith('/start')) {
            starts++;
            final body = jsonDecode(request.body) as Map;
            expect(body['email'], MasterAccessIdentity.email);
            expect(body['phone'], MasterAccessIdentity.phone);
            expect(body['client_app'], functionalClientApp);
            return http.Response(
              jsonEncode({
                'sessionId': _sessionId,
                'userId': _remoteUserId,
                'accessToken': 'access',
                'refreshToken': 'refresh',
              }),
              201,
            );
          }
          if (request.url.path.endsWith('/end')) {
            ends++;
            return http.Response('', 204);
          }
          expect(request.url.path, endsWith('/me/access'));
          return _accessResponse();
        }),
      );
      final local = LocalAuthService(
        fixture.dependencies.users,
        fixture.session,
      );
      final remote = OfflineFirstRemoteAuthService(
        local: local,
        users: fixture.dependencies.users,
        credentials: credentials,
        api: api,
        installationIds: const _InstallationIds(),
        deviceMetadata: const _DeviceMetadata(),
        appVersion: () async => '1.7.5+24',
      );
      final auth = MasterAccessAuthService(
        primary: remote,
        local: local,
        users: fixture.dependencies.users,
        sessionStore: fixture.session,
        tokens: credentials,
      );
      final user = await auth.login(
        displayName: MasterAccessIdentity.displayName,
        email: MasterAccessIdentity.email,
        phone: MasterAccessIdentity.phone,
      );
      expect(starts, 0);
      expect(await credentials.readCredentials(), isNull);
      final restored = (await auth.restoreSession())!;
      await auth.ensureRemoteSession(restored);
      await auth.ensureRemoteSession(
        restored,
      ); // stale local User, same remote mapping
      expect(starts, 1);
      expect(fixture.session.userId, user.id);
      expect(
        (await fixture.dependencies.users.getById(user.id))!.remoteUserId,
        _remoteUserId,
      );
      expect(
        await fixture.database.select(fixture.database.users).get(),
        hasLength(1),
      );
      await auth.logout();
      expect(ends, 1);
      expect(credentials.value, isNull);
      expect(fixture.session.userId, isNull);
    },
  );

  for (final status in [401, 403, 503]) {
    test(
      'sync auth handles remote $status without discarding the local session',
      () async {
        final fixture = await PresentationFixture.create();
        addTearDown(fixture.dispose);
        final local = LocalAuthService(
          fixture.dependencies.users,
          fixture.session,
        );
        final user = await local.login(
          displayName: 'Técnico',
          email: 'tech@example.com',
          phone: '4491234567',
        );
        await fixture.dependencies.users.linkRemoteUser(user.id, _remoteUserId);
        final credentials = _Credentials()
          ..value = const RemoteCredentials(
            accessToken: 'old-access',
            refreshToken: 'old-refresh',
            sessionId: _sessionId,
            remoteUserId: _remoteUserId,
          );
        var starts = 0;
        final api = RemoteApiClient(
          baseUrl: 'https://test.invalid',
          credentials: credentials,
          client: MockClient((request) async {
            if (request.url.path.endsWith('/start')) {
              starts++;
              return http.Response(
                jsonEncode({
                  'sessionId': _sessionId,
                  'userId': _remoteUserId,
                  'accessToken': 'new-access',
                  'refreshToken': 'new-refresh',
                }),
                201,
              );
            }
            return http.Response(
              jsonEncode({
                'error': {'code': 'TEST_ERROR', 'message': 'remote failure'},
              }),
              status,
            );
          }),
        );
        final auth = OfflineFirstRemoteAuthService(
          local: local,
          users: fixture.dependencies.users,
          credentials: credentials,
          api: api,
          installationIds: const _InstallationIds(),
          deviceMetadata: const _DeviceMetadata(),
          appVersion: () async => '1.7.5+24',
        );
        if (status == 401) {
          await auth.ensureRemoteSession(user);
          expect(starts, 1);
          expect(credentials.value!.accessToken, 'new-access');
        } else {
          await expectLater(
            auth.ensureRemoteSession(user),
            throwsA(isA<RemoteApiException>()),
          );
          expect(starts, 0);
          expect(credentials.value!.accessToken, 'old-access');
        }
        expect(fixture.session.userId, user.id);
      },
    );
  }

  for (final refreshFails in [false, true]) {
    test(
      'logout and relogin preserve cases even with refresh 500: $refreshFails',
      () async {
        final directory = await Directory.systemTemp.createTemp('ddr001-auth-');
        final database = AppDatabase(NativeDatabase.memory());
        final session = MemorySessionStore();
        final dependencies = AppDependencies.compose(
          database: database,
          fileStore: LocalEvidenceFileStore(directory),
          sessionStore: session,
        );
        addTearDown(() async {
          await database.close();
          await directory.delete(recursive: true);
        });
        final credentials = _Credentials();
        final api = RemoteApiClient(
          baseUrl: 'https://test.invalid',
          credentials: credentials,
          client: MockClient((request) async {
            if (request.url.path.endsWith('/field-sessions/start')) {
              return http.Response(
                jsonEncode({
                  'sessionId': _sessionId,
                  'userId': _remoteUserId,
                  'accessToken': 'access',
                  'refreshToken': 'refresh',
                  'tokenId': _tokenId,
                }),
                201,
              );
            }
            if (request.url.path.endsWith('/me/access')) {
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
            }
            if (refreshFails) {
              return request.url.path.endsWith('/refresh')
                  ? http.Response(
                      '{"detail":"An unexpected error occurred."}',
                      500,
                    )
                  : http.Response('{}', 401);
            }
            return http.Response('', 204);
          }),
        );
        final auth = OfflineFirstRemoteAuthService(
          local: LocalAuthService(dependencies.users, session),
          users: dependencies.users,
          credentials: credentials,
          api: api,
          installationIds: const _InstallationIds(),
          deviceMetadata: const _DeviceMetadata(),
          appVersion: () async => '1.4.0+15',
        );
        final user = await auth.login(
          displayName: 'Técnico Online',
          email: 'online@example.com',
          phone: '4491234567',
        );
        await dependencies.meters.save(
          Meter(
            id: 'CUENTA-1',
            externalStatus: ExternalMeterStatus.unknownOffline,
            createdAt: _time,
          ),
        );
        await dependencies.cases.create(
          VerificationCase(
            id: _caseId,
            meterId: 'CUENTA-1',
            userId: user.id,
            status: VerificationCaseStatus.open,
            createdAt: _time,
            reportVersion: 1,
          ),
        );

        await auth.logout();

        expect(await credentials.readCredentials(), isNull);
        expect(session.userId, isNull);
        expect(await dependencies.cases.getById(_caseId), isNotNull);
        expect(
          (await dependencies.users.getById(user.id))?.remoteUserId,
          _remoteUserId,
        );
        final restored = await auth.login(
          displayName: 'Técnico Online',
          email: 'online@example.com',
          phone: '4491234567',
        );
        expect(restored.id, user.id);
        expect(await dependencies.cases.getById(_caseId), isNotNull);
        expect(await credentials.readCredentials(), isNotNull);
      },
    );
  }
}

final class _Credentials implements RemoteCredentialStore {
  RemoteCredentials? value;
  @override
  Future<void> clear() async => value = null;
  @override
  Future<String?> read() async => value?.accessToken;
  @override
  Future<RemoteCredentials?> readCredentials() async => value;
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> writeCredentials(RemoteCredentials credentials) async =>
      value = credentials;
}

final class _InstallationIds implements InstallationIdStore {
  const _InstallationIds();
  @override
  Future<String> readOrCreate() async => _installationId;
}

final class _DeviceMetadata implements DeviceMetadataPort {
  const _DeviceMetadata();
  @override
  Future<DeviceMetadata> read() async => const DeviceMetadata(
    androidVersion: '16',
    brand: 'Google',
    model: 'Pixel 7 Pro',
  );
}

final _time = DateTime.utc(2026, 9, 2);
const _installationId = '11111111-1111-4111-8111-111111111111';
const _sessionId = '22222222-2222-4222-8222-222222222222';
const _remoteUserId = '33333333-3333-4333-8333-333333333333';
const _tokenId = '44444444-4444-4444-8444-444444444444';
const _caseId = '55555555-5555-4555-8555-555555555555';

http.Response _accessResponse() => http.Response(
  jsonEncode({
    'data': {
      'userId': _remoteUserId,
      'clientApp': functionalClientApp,
      'accessEnabled': true,
      'policyVersion': 1,
    },
  }),
  200,
);
