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

  test('logout clears remote secrets but preserves local cases', () async {
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
  });
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
