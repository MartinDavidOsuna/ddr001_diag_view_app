import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/local/database/app_database.dart' hide User;
import '../data/local/filesystem/evidence_file_store.dart';
import '../data/local/repositories/local_closure_services.dart';
import '../data/local/repositories/local_repositories.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';

abstract interface class SessionStore {
  Future<String?> readActiveUserId();
  Future<void> saveActiveUserId(String userId);
  Future<void> clear();
}

final class SharedPreferencesSessionStore implements SessionStore {
  static const _activeUserKey = 'active_user_id';

  @override
  Future<String?> readActiveUserId() async =>
      (await SharedPreferences.getInstance()).getString(_activeUserKey);

  @override
  Future<void> saveActiveUserId(String userId) async {
    await (await SharedPreferences.getInstance()).setString(
      _activeUserKey,
      userId,
    );
  }

  @override
  Future<void> clear() async {
    await (await SharedPreferences.getInstance()).remove(_activeUserKey);
  }
}

abstract interface class AuthService {
  Future<User?> restoreSession();
  Future<User> login({
    required String displayName,
    required String email,
    required String phone,
  });
  Future<void> logout();
}

final class LocalAuthService implements AuthService {
  LocalAuthService(this.users, this.sessionStore, [this._uuid = const Uuid()]);

  final UserRepository users;
  final SessionStore sessionStore;
  final Uuid _uuid;

  @override
  Future<User?> restoreSession() async {
    final userId = await sessionStore.readActiveUserId();
    return userId == null ? null : users.getById(userId);
  }

  @override
  Future<User> login({
    required String displayName,
    required String email,
    required String phone,
  }) async {
    final normalizedDisplayName = normalizeDisplayName(displayName);
    final normalizedEmail = normalizeEmail(email);
    final normalizedPhone = normalizePhone(phone);
    final now = DateTime.now().toUtc();
    final existing = await users.getByEmailAndPhone(
      normalizedEmail,
      normalizedPhone,
    );
    final user = User(
      id: existing?.id ?? _uuid.v4(),
      email: normalizedEmail,
      phone: normalizedPhone,
      // An existing identity wins. The captured name only fills legacy rows
      // that predate required display names; it is not an auth credential.
      displayName: existing?.displayName ?? normalizedDisplayName,
      createdAt: existing?.createdAt ?? now,
      lastLoginAt: now,
    );
    await users.save(user);
    await sessionStore.saveActiveUserId(user.id);
    return user;
  }

  @override
  Future<void> logout() => sessionStore.clear();
}

abstract interface class EvidenceCapturePort {
  Future<Evidence> capture({
    required String caseId,
    required Sample sample,
    required EvidenceType type,
    required double volumeRefLiters,
    int? pulseCount,
  });
}

/// Development-only adapter. It creates a deterministic local placeholder file
/// and then uses the real Stage 2 hashing and metadata paths.
final class DevelopmentEvidenceCaptureAdapter implements EvidenceCapturePort {
  DevelopmentEvidenceCaptureAdapter(
    this.files,
    this.evidence, [
    this._uuid = const Uuid(),
  ]);

  final EvidenceFileStore files;
  final EvidenceRepository evidence;
  final Uuid _uuid;

  @override
  Future<Evidence> capture({
    required String caseId,
    required Sample sample,
    required EvidenceType type,
    required double volumeRefLiters,
    int? pulseCount,
  }) async {
    final id = _uuid.v4();
    final path = await files.reservePath(
      caseId: caseId,
      sampleId: sample.id,
      evidenceId: id,
      extension: 'jpg',
    );
    await File(path).writeAsString(
      'DDR001 DEVELOPMENT EVIDENCE\n${sample.id}\n${type.name}\n$volumeRefLiters',
      flush: true,
    );
    final hash = await files.calculateSha256(path);
    final item = Evidence(
      id: id,
      sampleId: sample.id,
      type: type,
      required: true,
      volumeRefLiters: volumeRefLiters,
      pulseCount: pulseCount,
      capturedAt: DateTime.now().toUtc(),
      sha256: hash,
      localPath: path,
      syncStatus: EvidenceSyncStatus.local,
    );
    await evidence.save(item);
    return item;
  }
}

final class AppDependencies {
  AppDependencies({
    required this.database,
    required this.fileStore,
    required this.users,
    required this.meters,
    required this.cases,
    required this.flows,
    required this.samples,
    required this.points,
    required this.evidence,
    required this.sync,
    required this.sampleClosure,
    required this.caseClosure,
    required this.auth,
    required this.evidenceCapture,
  });

  static Future<AppDependencies> createLocal() async {
    final database = AppDatabase.defaults();
    final fileStore = await LocalEvidenceFileStore.createDefault();
    return compose(
      database: database,
      fileStore: fileStore,
      sessionStore: SharedPreferencesSessionStore(),
    );
  }

  static AppDependencies compose({
    required AppDatabase database,
    required EvidenceFileStore fileStore,
    required SessionStore sessionStore,
  }) {
    final users = LocalUserRepository(database);
    final meters = LocalMeterRepository(database);
    final cases = LocalVerificationCaseRepository(database);
    final flows = LocalFlowPointRepository(database);
    final samples = LocalSampleRepository(database);
    final points = LocalPointRepository(database);
    final evidence = LocalEvidenceRepository(database);
    final sync = LocalSyncQueueRepository(database);
    return AppDependencies(
      database: database,
      fileStore: fileStore,
      users: users,
      meters: meters,
      cases: cases,
      flows: flows,
      samples: samples,
      points: points,
      evidence: evidence,
      sync: sync,
      sampleClosure: LocalSampleClosureService(database, fileStore),
      caseClosure: LocalVerificationCaseClosureService(database),
      auth: LocalAuthService(users, sessionStore),
      evidenceCapture: DevelopmentEvidenceCaptureAdapter(fileStore, evidence),
    );
  }

  final AppDatabase database;
  final EvidenceFileStore fileStore;
  final UserRepository users;
  final MeterRepository meters;
  final VerificationCaseRepository cases;
  final FlowPointRepository flows;
  final SampleRepository samples;
  final PointRepository points;
  final EvidenceRepository evidence;
  final SyncQueueRepository sync;
  final SampleClosureService sampleClosure;
  final VerificationCaseClosureService caseClosure;
  final AuthService auth;
  final EvidenceCapturePort evidenceCapture;
}
