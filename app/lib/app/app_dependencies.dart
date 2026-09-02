import 'dart:async';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_id/android_id.dart';
import 'package:uuid/uuid.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/local/database/app_database.dart' hide User;
import '../data/local/filesystem/evidence_file_store.dart';
import '../data/local/repositories/local_closure_services.dart';
import '../data/local/repositories/local_repositories.dart';
import '../domain/models.dart';
import '../domain/pulse/pulse_progress_service.dart';
import '../domain/pulse/pulse_source.dart';
import '../domain/repositories.dart';
import '../infrastructure/camera/camera_port.dart';
import '../infrastructure/camera/flutter_camera_adapter.dart';
import '../infrastructure/vision/needle_detector.dart';
import '../infrastructure/vision/odometer_reader.dart';
import '../infrastructure/vision/vision_pipeline.dart';
import '../infrastructure/pulse/ble_discovery.dart';
import '../infrastructure/export/case_export_service.dart';
import '../infrastructure/remote/remote_api.dart';
import '../infrastructure/remote/functional_sync_engine.dart';
import '../domain/simulation/simulation_workflow_service.dart';
import '../infrastructure/simulation/simulation_evidence_capture.dart';

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

abstract interface class LocationPort {
  Future<GpsSnapshot> capture();
}

abstract interface class DeviceMetadataPort {
  Future<DeviceMetadata> read();
}

final class AndroidDeviceMetadataAdapter implements DeviceMetadataPort {
  @override
  Future<DeviceMetadata> read() async {
    if (!Platform.isAndroid) return const DeviceMetadata();
    final info = await DeviceInfoPlugin().androidInfo;
    return DeviceMetadata(
      id: await const AndroidId().getId(),
      androidVersion: info.version.release,
      brand: info.brand,
      model: info.model,
    );
  }
}

enum LocationFailureKind {
  serviceDisabled,
  denied,
  permanentlyDenied,
  timeout,
  unavailable,
}

final class LocationFailure implements Exception {
  const LocationFailure(this.kind, this.message);
  final LocationFailureKind kind;
  final String message;
  @override
  String toString() => message;
}

final class GeolocatorLocationAdapter implements LocationPort {
  @override
  Future<GpsSnapshot> capture() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(
        LocationFailureKind.serviceDisabled,
        'Los servicios de ubicación están desactivados. Actívalos para obtener GPS.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw LocationFailure(
        permission == LocationPermission.deniedForever
            ? LocationFailureKind.permanentlyDenied
            : LocationFailureKind.denied,
        permission == LocationPermission.deniedForever
            ? 'Permiso de ubicación denegado permanentemente. Habilítalo en Ajustes de Android.'
            : 'Permiso de ubicación denegado. La prueba puede continuar sin GPS.',
      );
    }
    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      throw const LocationFailure(
        LocationFailureKind.timeout,
        'GPS tardó demasiado. Intenta nuevamente en un lugar con mejor recepción.',
      );
    } catch (_) {
      throw const LocationFailure(
        LocationFailureKind.unavailable,
        'No fue posible obtener la ubicación. La prueba puede continuar sin GPS.',
      );
    }
    return GpsSnapshot(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      capturedAt: position.timestamp.toUtc(),
    );
  }
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

final class OfflineFirstRemoteAuthService implements AuthService {
  OfflineFirstRemoteAuthService({
    required this.local,
    required this.users,
    required this.credentials,
    required this.api,
    required this.installationIds,
    required this.deviceMetadata,
    required this.appVersion,
  });

  final LocalAuthService local;
  final UserRepository users;
  final RemoteCredentialStore credentials;
  final RemoteApiClient api;
  final InstallationIdStore installationIds;
  final DeviceMetadataPort deviceMetadata;
  final Future<String> Function() appVersion;
  String? remoteNotice;

  @override
  Future<User?> restoreSession() => local.restoreSession();

  @override
  Future<User> login({
    required String displayName,
    required String email,
    required String phone,
  }) async {
    final user = await local.login(
      displayName: displayName,
      email: email,
      phone: phone,
    );
    remoteNotice = null;
    final previousCredentials = await credentials.readCredentials();
    if (previousCredentials != null &&
        (user.remoteUserId == null ||
            previousCredentials.remoteUserId.toLowerCase() !=
                user.remoteUserId!.toLowerCase())) {
      await credentials.clear();
    }
    try {
      final metadata = await deviceMetadata.read();
      final remote = await api.login(
        displayName: user.displayName ?? displayName,
        email: user.email,
        phone: user.phone,
        device: RemoteDeviceRegistration(
          installationId: await installationIds.readOrCreate(),
          platform: 'android',
          manufacturer: metadata.brand ?? 'unknown',
          model: metadata.model ?? 'unknown',
          androidVersion: metadata.androidVersion ?? 'unknown',
          appVersion: await appVersion(),
        ),
      );
      await users.linkRemoteUser(user.id, remote.remoteUserId);
      final access = await api.access();
      if (!access.enabled) {
        remoteNotice =
            'Sin acceso remoto. La captura local continúa disponible.';
      }
    } on RemoteApiException catch (error) {
      remoteNotice =
          'Sesión local activa. Sin conexión remota: ${error.message}';
    }
    return (await users.getById(user.id))!;
  }

  @override
  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {
      // Logout local is authoritative even when remote revocation is offline.
    }
    await credentials.clear();
    await local.logout();
  }
}

abstract final class MasterAccessIdentity {
  static const displayName = 'Martin Osuna';
  static const email = 'martinosuna@agrienlace.com';
  static const phone = '9999999999';
  static const identities =
      <({String displayName, String email, String phone})>[
        (displayName: displayName, email: email, phone: phone),
        (
          displayName: 'Rene',
          email: 'renelopez@agrienlace.com',
          phone: '9999999999',
        ),
        (
          displayName: 'Omar',
          email: 'omarpizano@aquafim.com',
          phone: '9999999999',
        ),
      ];

  static ({String displayName, String email, String phone})? find({
    required String displayName,
    required String email,
    required String phone,
  }) {
    final name = normalizeDisplayName(displayName).toLowerCase();
    final normalizedEmail = normalizeEmail(email);
    final normalizedPhone = normalizePhone(phone);
    for (final identity in identities) {
      if (identity.displayName.toLowerCase() == name &&
          identity.email == normalizedEmail &&
          identity.phone == normalizedPhone) {
        return identity;
      }
    }
    return null;
  }

  static bool matches({
    required String displayName,
    required String email,
    required String phone,
  }) => find(displayName: displayName, email: email, phone: phone) != null;
}

/// Allows the documented field master identity to establish a local session
/// without making an API request. Every other identity follows the configured
/// production authentication path unchanged.
final class MasterAccessAuthService implements AuthService {
  MasterAccessAuthService({
    required this.primary,
    required this.local,
    required this.users,
    required this.sessionStore,
    required this.tokens,
  });

  final AuthService primary;
  final LocalAuthService local;
  final UserRepository users;
  final SessionStore sessionStore;
  final TokenStore tokens;

  @override
  Future<User?> restoreSession() => primary.restoreSession();

  @override
  Future<User> login({
    required String displayName,
    required String email,
    required String phone,
  }) async {
    final identity = MasterAccessIdentity.find(
      displayName: displayName,
      email: email,
      phone: phone,
    );
    if (identity != null) {
      await tokens.clear();
      return local.login(
        displayName: identity.displayName,
        email: identity.email,
        phone: identity.phone,
      );
    }
    return primary.login(displayName: displayName, email: email, phone: phone);
  }

  @override
  Future<void> logout() async {
    final userId = await sessionStore.readActiveUserId();
    final user = userId == null ? null : await users.getById(userId);
    if (user != null &&
        MasterAccessIdentity.matches(
          displayName: user.displayName ?? '',
          email: user.email,
          phone: user.phone,
        )) {
      await tokens.clear();
      await local.logout();
      return;
    }
    await primary.logout();
  }
}

abstract interface class EvidenceCapturePort {
  Future<Evidence> capture({
    required String caseId,
    required Sample sample,
    required EvidenceType type,
    required double volumeRefLiters,
    int? pulseCount,
  });
  Future<Evidence> captureExisting({
    required String sourcePath,
    required String caseId,
    required Sample sample,
    required EvidenceType type,
    required double volumeRefLiters,
    int? pulseCount,
  });
}

/// Development-only adapter. It creates a deterministic local placeholder file
/// and then uses the real Stage 2 hashing and metadata paths.
class DevelopmentEvidenceCaptureAdapter implements EvidenceCapturePort {
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

  @override
  Future<Evidence> captureExisting({
    required String sourcePath,
    required String caseId,
    required Sample sample,
    required EvidenceType type,
    required double volumeRefLiters,
    int? pulseCount,
  }) => _persistExisting(
    sourcePath: sourcePath,
    caseId: caseId,
    sample: sample,
    type: type,
    volumeRefLiters: volumeRefLiters,
    pulseCount: pulseCount,
  );

  Future<Evidence> _persistExisting({
    required String sourcePath,
    required String caseId,
    required Sample sample,
    required EvidenceType type,
    required double volumeRefLiters,
    int? pulseCount,
  }) async {
    final id = _uuid.v4();
    final path = await files.importExistingFile(
      sourcePath: sourcePath,
      caseId: caseId,
      sampleId: sample.id,
      evidenceId: id,
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

final class CameraEvidenceCaptureAdapter
    extends DevelopmentEvidenceCaptureAdapter {
  CameraEvidenceCaptureAdapter(super.files, super.evidence);

  @override
  Future<Evidence> capture({
    required String caseId,
    required Sample sample,
    required EvidenceType type,
    required double volumeRefLiters,
    int? pulseCount,
  }) => throw StateError('Se requiere una fotografía real confirmada.');
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
    required this.syncBatches,
    required this.sampleClosure,
    required this.caseClosure,
    required this.auth,
    required this.sessionStore,
    required this.evidenceCapture,
    required this.pulseProgress,
    required this.caseExport,
    required this.simulationWorkflow,
    this.bleDiscovery,
    this.location,
    this.deviceMetadata,
    this.remoteApi,
    this.syncEngine,
    this.installationIdStore,
    this.tokenStore,
    this.camera,
    this.visualPipeline,
  });

  static Future<AppDependencies> createLocal() async {
    final database = AppDatabase.defaults();
    final fileStore = await LocalEvidenceFileStore.createDefault();
    final base = compose(
      database: database,
      fileStore: fileStore,
      sessionStore: SharedPreferencesSessionStore(),
    );
    const apiBaseUrl = String.fromEnvironment('DDR001_API_BASE_URL');
    const tokenStore = SecureRemoteCredentialStore();
    const installationIdStore = SecureInstallationIdStore();
    final remoteApi = apiBaseUrl.isEmpty
        ? null
        : RemoteApiClient(baseUrl: apiBaseUrl, credentials: tokenStore);
    final localAuth = LocalAuthService(base.users, base.sessionStore);
    final primaryAuth = remoteApi == null
        ? localAuth
        : OfflineFirstRemoteAuthService(
            local: localAuth,
            users: base.users,
            credentials: tokenStore,
            api: remoteApi,
            installationIds: installationIdStore,
            deviceMetadata: AndroidDeviceMetadataAdapter(),
            appVersion: () async {
              final info = await PackageInfo.fromPlatform();
              return '${info.version}+${info.buildNumber}';
            },
          );
    return base.copyWith(
      evidenceCapture: CameraEvidenceCaptureAdapter(fileStore, base.evidence),
      camera: FlutterCameraAdapter(),
      visualPipeline: OnDeviceVisualReadingPipeline(
        odometer: MlKitOdometerRecognitionAdapter(),
        needle: const RedNeedleDetector(),
      ),
      bleDiscovery: BleDiscoveryService(),
      location: GeolocatorLocationAdapter(),
      deviceMetadata: AndroidDeviceMetadataAdapter(),
      auth: MasterAccessAuthService(
        primary: primaryAuth,
        local: LocalAuthService(base.users, base.sessionStore),
        users: base.users,
        sessionStore: base.sessionStore,
        tokens: tokenStore,
      ),
      remoteApi: remoteApi,
      tokenStore: tokenStore,
      installationIdStore: installationIdStore,
      syncEngine: remoteApi == null
          ? null
          : FunctionalSyncEngine(
              api: remoteApi,
              installationIds: installationIdStore,
              users: base.users,
              meters: base.meters,
              cases: base.cases,
              flows: base.flows,
              samples: base.samples,
              points: base.points,
              evidence: base.evidence,
              queue: base.sync,
              batches: base.syncBatches,
            ),
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
    final syncBatches = LocalSyncBatchRepository(database);
    final simulationEvidence = SimulationEvidenceCaptureAdapter(
      fileStore,
      evidence,
    );
    final pulseProgress = PulseProgressService(samples);
    final sampleClosure = LocalSampleClosureService(database, fileStore);
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
      syncBatches: syncBatches,
      sampleClosure: sampleClosure,
      caseClosure: LocalVerificationCaseClosureService(database),
      auth: LocalAuthService(users, sessionStore),
      sessionStore: sessionStore,
      evidenceCapture: DevelopmentEvidenceCaptureAdapter(fileStore, evidence),
      pulseProgress: pulseProgress,
      caseExport: CaseExportService(),
      simulationWorkflow: SimulationWorkflowService(
        samples: samples,
        points: points,
        evidence: evidence,
        pulseProgress: pulseProgress,
        sampleClosure: sampleClosure,
        simulationEvidence: simulationEvidence,
      ),
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
  final SyncBatchRepository syncBatches;
  final SampleClosureService sampleClosure;
  final VerificationCaseClosureService caseClosure;
  final AuthService auth;
  final SessionStore sessionStore;
  final EvidenceCapturePort evidenceCapture;
  final PulseProgressPort pulseProgress;
  final CaseExportService caseExport;
  final SimulationWorkflowService simulationWorkflow;
  final BleDiscoveryService? bleDiscovery;
  final LocationPort? location;
  final DeviceMetadataPort? deviceMetadata;
  final RemoteApiClient? remoteApi;
  final FunctionalSyncEngine? syncEngine;
  final InstallationIdStore? installationIdStore;
  final TokenStore? tokenStore;
  final CameraPort? camera;
  final VisualReadingPipeline? visualPipeline;

  bool get backendSyncConfigured => remoteApi != null;
  bool get hydrantLookupConfigured => false;
  bool get locationAvailable => location != null;

  AppDependencies copyWith({
    EvidenceCapturePort? evidenceCapture,
    CameraPort? camera,
    VisualReadingPipeline? visualPipeline,
    PulseProgressPort? pulseProgress,
    BleDiscoveryService? bleDiscovery,
    LocationPort? location,
    DeviceMetadataPort? deviceMetadata,
    AuthService? auth,
    RemoteApiClient? remoteApi,
    FunctionalSyncEngine? syncEngine,
    InstallationIdStore? installationIdStore,
    TokenStore? tokenStore,
    SimulationWorkflowService? simulationWorkflow,
  }) => AppDependencies(
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
    syncBatches: syncBatches,
    sampleClosure: sampleClosure,
    caseClosure: caseClosure,
    auth: auth ?? this.auth,
    sessionStore: sessionStore,
    evidenceCapture: evidenceCapture ?? this.evidenceCapture,
    pulseProgress: pulseProgress ?? this.pulseProgress,
    caseExport: caseExport,
    simulationWorkflow: simulationWorkflow ?? this.simulationWorkflow,
    bleDiscovery: bleDiscovery ?? this.bleDiscovery,
    location: location ?? this.location,
    deviceMetadata: deviceMetadata ?? this.deviceMetadata,
    remoteApi: remoteApi ?? this.remoteApi,
    syncEngine: syncEngine ?? this.syncEngine,
    installationIdStore: installationIdStore ?? this.installationIdStore,
    tokenStore: tokenStore ?? this.tokenStore,
    camera: camera ?? this.camera,
    visualPipeline: visualPipeline ?? this.visualPipeline,
  );
}
