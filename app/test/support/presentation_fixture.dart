import 'dart:io';

import 'package:ddr001_diag_view_app/app/app_dependencies.dart';
import 'package:ddr001_diag_view_app/data/local/database/app_database.dart'
    hide User;
import 'package:ddr001_diag_view_app/data/local/filesystem/evidence_file_store.dart';
import 'package:ddr001_diag_view_app/domain/models.dart';
import 'package:drift/native.dart';

final class MemorySessionStore implements SessionStore {
  String? userId;

  @override
  Future<void> clear() async => userId = null;

  @override
  Future<String?> readActiveUserId() async => userId;

  @override
  Future<void> saveActiveUserId(String value) async => userId = value;
}

final class PresentationFixture {
  PresentationFixture._(
    this.database,
    this.directory,
    this.session,
    this.dependencies,
  );

  static Future<PresentationFixture> create() async {
    final database = AppDatabase(NativeDatabase.memory());
    final directory = await Directory.systemTemp.createTemp('ddr001-stage3-');
    final session = MemorySessionStore();
    final dependencies = AppDependencies.compose(
      database: database,
      fileStore: LocalEvidenceFileStore(directory),
      sessionStore: session,
    );
    return PresentationFixture._(database, directory, session, dependencies);
  }

  final AppDatabase database;
  final Directory directory;
  final MemorySessionStore session;
  final AppDependencies dependencies;

  Future<User> seedSession() async {
    final user = User(
      id: 'user-stage3',
      email: 'field@aquafim.mx',
      phone: '+524491234567',
      displayName: 'Técnico de Campo',
      createdAt: DateTime.utc(2026, 8, 10),
    );
    await dependencies.users.save(user);
    await session.saveActiveUserId(user.id);
    return user;
  }

  Future<void> dispose() async {
    await database.close();
    await directory.delete(recursive: true);
  }
}
