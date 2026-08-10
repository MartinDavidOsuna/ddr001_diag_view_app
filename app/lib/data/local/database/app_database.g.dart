// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastLoginAtMsMeta = const VerificationMeta(
    'lastLoginAtMs',
  );
  @override
  late final GeneratedColumn<int> lastLoginAtMs = GeneratedColumn<int>(
    'last_login_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    email,
    phone,
    displayName,
    createdAtMs,
    lastLoginAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('last_login_at_ms')) {
      context.handle(
        _lastLoginAtMsMeta,
        lastLoginAtMs.isAcceptableOrUnknown(
          data['last_login_at_ms']!,
          _lastLoginAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      lastLoginAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_login_at_ms'],
      ),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String email;
  final String phone;
  final String? displayName;
  final int createdAtMs;
  final int? lastLoginAtMs;
  const User({
    required this.id,
    required this.email,
    required this.phone,
    this.displayName,
    required this.createdAtMs,
    this.lastLoginAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    map['phone'] = Variable<String>(phone);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    if (!nullToAbsent || lastLoginAtMs != null) {
      map['last_login_at_ms'] = Variable<int>(lastLoginAtMs);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      email: Value(email),
      phone: Value(phone),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      createdAtMs: Value(createdAtMs),
      lastLoginAtMs: lastLoginAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLoginAtMs),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      phone: serializer.fromJson<String>(json['phone']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      lastLoginAtMs: serializer.fromJson<int?>(json['lastLoginAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'phone': serializer.toJson<String>(phone),
      'displayName': serializer.toJson<String?>(displayName),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'lastLoginAtMs': serializer.toJson<int?>(lastLoginAtMs),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? phone,
    Value<String?> displayName = const Value.absent(),
    int? createdAtMs,
    Value<int?> lastLoginAtMs = const Value.absent(),
  }) => User(
    id: id ?? this.id,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    displayName: displayName.present ? displayName.value : this.displayName,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    lastLoginAtMs: lastLoginAtMs.present
        ? lastLoginAtMs.value
        : this.lastLoginAtMs,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      lastLoginAtMs: data.lastLoginAtMs.present
          ? data.lastLoginAtMs.value
          : this.lastLoginAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('displayName: $displayName, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('lastLoginAtMs: $lastLoginAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, email, phone, displayName, createdAtMs, lastLoginAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.displayName == this.displayName &&
          other.createdAtMs == this.createdAtMs &&
          other.lastLoginAtMs == this.lastLoginAtMs);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> email;
  final Value<String> phone;
  final Value<String?> displayName;
  final Value<int> createdAtMs;
  final Value<int?> lastLoginAtMs;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.displayName = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.lastLoginAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String email,
    required String phone,
    this.displayName = const Value.absent(),
    required int createdAtMs,
    this.lastLoginAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       email = Value(email),
       phone = Value(phone),
       createdAtMs = Value(createdAtMs);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? displayName,
    Expression<int>? createdAtMs,
    Expression<int>? lastLoginAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (displayName != null) 'display_name': displayName,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (lastLoginAtMs != null) 'last_login_at_ms': lastLoginAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String>? email,
    Value<String>? phone,
    Value<String?>? displayName,
    Value<int>? createdAtMs,
    Value<int?>? lastLoginAtMs,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      lastLoginAtMs: lastLoginAtMs ?? this.lastLoginAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (lastLoginAtMs.present) {
      map['last_login_at_ms'] = Variable<int>(lastLoginAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('displayName: $displayName, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('lastLoginAtMs: $lastLoginAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MetersTable extends Meters with TableInfo<$MetersTable, Meter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalStatusMeta = const VerificationMeta(
    'externalStatus',
  );
  @override
  late final GeneratedColumn<String> externalStatus = GeneratedColumn<String>(
    'external_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalSnapshotJsonMeta =
      const VerificationMeta('externalSnapshotJson');
  @override
  late final GeneratedColumn<String> externalSnapshotJson =
      GeneratedColumn<String>(
        'external_snapshot_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _externalCheckedAtMsMeta =
      const VerificationMeta('externalCheckedAtMs');
  @override
  late final GeneratedColumn<int> externalCheckedAtMs = GeneratedColumn<int>(
    'external_checked_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    externalStatus,
    externalSnapshotJson,
    externalCheckedAtMs,
    createdAtMs,
    updatedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Meter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('external_status')) {
      context.handle(
        _externalStatusMeta,
        externalStatus.isAcceptableOrUnknown(
          data['external_status']!,
          _externalStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_externalStatusMeta);
    }
    if (data.containsKey('external_snapshot_json')) {
      context.handle(
        _externalSnapshotJsonMeta,
        externalSnapshotJson.isAcceptableOrUnknown(
          data['external_snapshot_json']!,
          _externalSnapshotJsonMeta,
        ),
      );
    }
    if (data.containsKey('external_checked_at_ms')) {
      context.handle(
        _externalCheckedAtMsMeta,
        externalCheckedAtMs.isAcceptableOrUnknown(
          data['external_checked_at_ms']!,
          _externalCheckedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Meter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Meter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      externalStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_status'],
      )!,
      externalSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_snapshot_json'],
      ),
      externalCheckedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}external_checked_at_ms'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
    );
  }

  @override
  $MetersTable createAlias(String alias) {
    return $MetersTable(attachedDatabase, alias);
  }
}

class Meter extends DataClass implements Insertable<Meter> {
  final String id;
  final String externalStatus;
  final String? externalSnapshotJson;
  final int? externalCheckedAtMs;
  final int createdAtMs;
  final int updatedAtMs;
  const Meter({
    required this.id,
    required this.externalStatus,
    this.externalSnapshotJson,
    this.externalCheckedAtMs,
    required this.createdAtMs,
    required this.updatedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['external_status'] = Variable<String>(externalStatus);
    if (!nullToAbsent || externalSnapshotJson != null) {
      map['external_snapshot_json'] = Variable<String>(externalSnapshotJson);
    }
    if (!nullToAbsent || externalCheckedAtMs != null) {
      map['external_checked_at_ms'] = Variable<int>(externalCheckedAtMs);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    return map;
  }

  MetersCompanion toCompanion(bool nullToAbsent) {
    return MetersCompanion(
      id: Value(id),
      externalStatus: Value(externalStatus),
      externalSnapshotJson: externalSnapshotJson == null && nullToAbsent
          ? const Value.absent()
          : Value(externalSnapshotJson),
      externalCheckedAtMs: externalCheckedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(externalCheckedAtMs),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
    );
  }

  factory Meter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Meter(
      id: serializer.fromJson<String>(json['id']),
      externalStatus: serializer.fromJson<String>(json['externalStatus']),
      externalSnapshotJson: serializer.fromJson<String?>(
        json['externalSnapshotJson'],
      ),
      externalCheckedAtMs: serializer.fromJson<int?>(
        json['externalCheckedAtMs'],
      ),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'externalStatus': serializer.toJson<String>(externalStatus),
      'externalSnapshotJson': serializer.toJson<String?>(externalSnapshotJson),
      'externalCheckedAtMs': serializer.toJson<int?>(externalCheckedAtMs),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
    };
  }

  Meter copyWith({
    String? id,
    String? externalStatus,
    Value<String?> externalSnapshotJson = const Value.absent(),
    Value<int?> externalCheckedAtMs = const Value.absent(),
    int? createdAtMs,
    int? updatedAtMs,
  }) => Meter(
    id: id ?? this.id,
    externalStatus: externalStatus ?? this.externalStatus,
    externalSnapshotJson: externalSnapshotJson.present
        ? externalSnapshotJson.value
        : this.externalSnapshotJson,
    externalCheckedAtMs: externalCheckedAtMs.present
        ? externalCheckedAtMs.value
        : this.externalCheckedAtMs,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
  );
  Meter copyWithCompanion(MetersCompanion data) {
    return Meter(
      id: data.id.present ? data.id.value : this.id,
      externalStatus: data.externalStatus.present
          ? data.externalStatus.value
          : this.externalStatus,
      externalSnapshotJson: data.externalSnapshotJson.present
          ? data.externalSnapshotJson.value
          : this.externalSnapshotJson,
      externalCheckedAtMs: data.externalCheckedAtMs.present
          ? data.externalCheckedAtMs.value
          : this.externalCheckedAtMs,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Meter(')
          ..write('id: $id, ')
          ..write('externalStatus: $externalStatus, ')
          ..write('externalSnapshotJson: $externalSnapshotJson, ')
          ..write('externalCheckedAtMs: $externalCheckedAtMs, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    externalStatus,
    externalSnapshotJson,
    externalCheckedAtMs,
    createdAtMs,
    updatedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Meter &&
          other.id == this.id &&
          other.externalStatus == this.externalStatus &&
          other.externalSnapshotJson == this.externalSnapshotJson &&
          other.externalCheckedAtMs == this.externalCheckedAtMs &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs);
}

class MetersCompanion extends UpdateCompanion<Meter> {
  final Value<String> id;
  final Value<String> externalStatus;
  final Value<String?> externalSnapshotJson;
  final Value<int?> externalCheckedAtMs;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int> rowid;
  const MetersCompanion({
    this.id = const Value.absent(),
    this.externalStatus = const Value.absent(),
    this.externalSnapshotJson = const Value.absent(),
    this.externalCheckedAtMs = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetersCompanion.insert({
    required String id,
    required String externalStatus,
    this.externalSnapshotJson = const Value.absent(),
    this.externalCheckedAtMs = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       externalStatus = Value(externalStatus),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<Meter> custom({
    Expression<String>? id,
    Expression<String>? externalStatus,
    Expression<String>? externalSnapshotJson,
    Expression<int>? externalCheckedAtMs,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (externalStatus != null) 'external_status': externalStatus,
      if (externalSnapshotJson != null)
        'external_snapshot_json': externalSnapshotJson,
      if (externalCheckedAtMs != null)
        'external_checked_at_ms': externalCheckedAtMs,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetersCompanion copyWith({
    Value<String>? id,
    Value<String>? externalStatus,
    Value<String?>? externalSnapshotJson,
    Value<int?>? externalCheckedAtMs,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int>? rowid,
  }) {
    return MetersCompanion(
      id: id ?? this.id,
      externalStatus: externalStatus ?? this.externalStatus,
      externalSnapshotJson: externalSnapshotJson ?? this.externalSnapshotJson,
      externalCheckedAtMs: externalCheckedAtMs ?? this.externalCheckedAtMs,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (externalStatus.present) {
      map['external_status'] = Variable<String>(externalStatus.value);
    }
    if (externalSnapshotJson.present) {
      map['external_snapshot_json'] = Variable<String>(
        externalSnapshotJson.value,
      );
    }
    if (externalCheckedAtMs.present) {
      map['external_checked_at_ms'] = Variable<int>(externalCheckedAtMs.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetersCompanion(')
          ..write('id: $id, ')
          ..write('externalStatus: $externalStatus, ')
          ..write('externalSnapshotJson: $externalSnapshotJson, ')
          ..write('externalCheckedAtMs: $externalCheckedAtMs, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VerificationCasesTable extends VerificationCases
    with TableInfo<$VerificationCasesTable, VerificationCaseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VerificationCasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meterIdMeta = const VerificationMeta(
    'meterId',
  );
  @override
  late final GeneratedColumn<String> meterId = GeneratedColumn<String>(
    'meter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES meters (id)',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _overallVerdictMeta = const VerificationMeta(
    'overallVerdict',
  );
  @override
  late final GeneratedColumn<String> overallVerdict = GeneratedColumn<String>(
    'overall_verdict',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedAtMsMeta = const VerificationMeta(
    'closedAtMs',
  );
  @override
  late final GeneratedColumn<int> closedAtMs = GeneratedColumn<int>(
    'closed_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reportVersionMeta = const VerificationMeta(
    'reportVersion',
  );
  @override
  late final GeneratedColumn<int> reportVersion = GeneratedColumn<int>(
    'report_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    meterId,
    userId,
    status,
    overallVerdict,
    createdAtMs,
    closedAtMs,
    reportVersion,
    checksum,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'verification_cases';
  @override
  VerificationContext validateIntegrity(
    Insertable<VerificationCaseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('meter_id')) {
      context.handle(
        _meterIdMeta,
        meterId.isAcceptableOrUnknown(data['meter_id']!, _meterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_meterIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('overall_verdict')) {
      context.handle(
        _overallVerdictMeta,
        overallVerdict.isAcceptableOrUnknown(
          data['overall_verdict']!,
          _overallVerdictMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('closed_at_ms')) {
      context.handle(
        _closedAtMsMeta,
        closedAtMs.isAcceptableOrUnknown(
          data['closed_at_ms']!,
          _closedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('report_version')) {
      context.handle(
        _reportVersionMeta,
        reportVersion.isAcceptableOrUnknown(
          data['report_version']!,
          _reportVersionMeta,
        ),
      );
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VerificationCaseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VerificationCaseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      meterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meter_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      overallVerdict: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overall_verdict'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      closedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}closed_at_ms'],
      ),
      reportVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}report_version'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      ),
    );
  }

  @override
  $VerificationCasesTable createAlias(String alias) {
    return $VerificationCasesTable(attachedDatabase, alias);
  }
}

class VerificationCaseRow extends DataClass
    implements Insertable<VerificationCaseRow> {
  final String id;
  final String meterId;
  final String userId;
  final String status;
  final String? overallVerdict;
  final int createdAtMs;
  final int? closedAtMs;
  final int reportVersion;
  final String? checksum;
  const VerificationCaseRow({
    required this.id,
    required this.meterId,
    required this.userId,
    required this.status,
    this.overallVerdict,
    required this.createdAtMs,
    this.closedAtMs,
    required this.reportVersion,
    this.checksum,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['meter_id'] = Variable<String>(meterId);
    map['user_id'] = Variable<String>(userId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || overallVerdict != null) {
      map['overall_verdict'] = Variable<String>(overallVerdict);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    if (!nullToAbsent || closedAtMs != null) {
      map['closed_at_ms'] = Variable<int>(closedAtMs);
    }
    map['report_version'] = Variable<int>(reportVersion);
    if (!nullToAbsent || checksum != null) {
      map['checksum'] = Variable<String>(checksum);
    }
    return map;
  }

  VerificationCasesCompanion toCompanion(bool nullToAbsent) {
    return VerificationCasesCompanion(
      id: Value(id),
      meterId: Value(meterId),
      userId: Value(userId),
      status: Value(status),
      overallVerdict: overallVerdict == null && nullToAbsent
          ? const Value.absent()
          : Value(overallVerdict),
      createdAtMs: Value(createdAtMs),
      closedAtMs: closedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAtMs),
      reportVersion: Value(reportVersion),
      checksum: checksum == null && nullToAbsent
          ? const Value.absent()
          : Value(checksum),
    );
  }

  factory VerificationCaseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VerificationCaseRow(
      id: serializer.fromJson<String>(json['id']),
      meterId: serializer.fromJson<String>(json['meterId']),
      userId: serializer.fromJson<String>(json['userId']),
      status: serializer.fromJson<String>(json['status']),
      overallVerdict: serializer.fromJson<String?>(json['overallVerdict']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      closedAtMs: serializer.fromJson<int?>(json['closedAtMs']),
      reportVersion: serializer.fromJson<int>(json['reportVersion']),
      checksum: serializer.fromJson<String?>(json['checksum']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'meterId': serializer.toJson<String>(meterId),
      'userId': serializer.toJson<String>(userId),
      'status': serializer.toJson<String>(status),
      'overallVerdict': serializer.toJson<String?>(overallVerdict),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'closedAtMs': serializer.toJson<int?>(closedAtMs),
      'reportVersion': serializer.toJson<int>(reportVersion),
      'checksum': serializer.toJson<String?>(checksum),
    };
  }

  VerificationCaseRow copyWith({
    String? id,
    String? meterId,
    String? userId,
    String? status,
    Value<String?> overallVerdict = const Value.absent(),
    int? createdAtMs,
    Value<int?> closedAtMs = const Value.absent(),
    int? reportVersion,
    Value<String?> checksum = const Value.absent(),
  }) => VerificationCaseRow(
    id: id ?? this.id,
    meterId: meterId ?? this.meterId,
    userId: userId ?? this.userId,
    status: status ?? this.status,
    overallVerdict: overallVerdict.present
        ? overallVerdict.value
        : this.overallVerdict,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    closedAtMs: closedAtMs.present ? closedAtMs.value : this.closedAtMs,
    reportVersion: reportVersion ?? this.reportVersion,
    checksum: checksum.present ? checksum.value : this.checksum,
  );
  VerificationCaseRow copyWithCompanion(VerificationCasesCompanion data) {
    return VerificationCaseRow(
      id: data.id.present ? data.id.value : this.id,
      meterId: data.meterId.present ? data.meterId.value : this.meterId,
      userId: data.userId.present ? data.userId.value : this.userId,
      status: data.status.present ? data.status.value : this.status,
      overallVerdict: data.overallVerdict.present
          ? data.overallVerdict.value
          : this.overallVerdict,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      closedAtMs: data.closedAtMs.present
          ? data.closedAtMs.value
          : this.closedAtMs,
      reportVersion: data.reportVersion.present
          ? data.reportVersion.value
          : this.reportVersion,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VerificationCaseRow(')
          ..write('id: $id, ')
          ..write('meterId: $meterId, ')
          ..write('userId: $userId, ')
          ..write('status: $status, ')
          ..write('overallVerdict: $overallVerdict, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('closedAtMs: $closedAtMs, ')
          ..write('reportVersion: $reportVersion, ')
          ..write('checksum: $checksum')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    meterId,
    userId,
    status,
    overallVerdict,
    createdAtMs,
    closedAtMs,
    reportVersion,
    checksum,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VerificationCaseRow &&
          other.id == this.id &&
          other.meterId == this.meterId &&
          other.userId == this.userId &&
          other.status == this.status &&
          other.overallVerdict == this.overallVerdict &&
          other.createdAtMs == this.createdAtMs &&
          other.closedAtMs == this.closedAtMs &&
          other.reportVersion == this.reportVersion &&
          other.checksum == this.checksum);
}

class VerificationCasesCompanion extends UpdateCompanion<VerificationCaseRow> {
  final Value<String> id;
  final Value<String> meterId;
  final Value<String> userId;
  final Value<String> status;
  final Value<String?> overallVerdict;
  final Value<int> createdAtMs;
  final Value<int?> closedAtMs;
  final Value<int> reportVersion;
  final Value<String?> checksum;
  final Value<int> rowid;
  const VerificationCasesCompanion({
    this.id = const Value.absent(),
    this.meterId = const Value.absent(),
    this.userId = const Value.absent(),
    this.status = const Value.absent(),
    this.overallVerdict = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.closedAtMs = const Value.absent(),
    this.reportVersion = const Value.absent(),
    this.checksum = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VerificationCasesCompanion.insert({
    required String id,
    required String meterId,
    required String userId,
    required String status,
    this.overallVerdict = const Value.absent(),
    required int createdAtMs,
    this.closedAtMs = const Value.absent(),
    this.reportVersion = const Value.absent(),
    this.checksum = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       meterId = Value(meterId),
       userId = Value(userId),
       status = Value(status),
       createdAtMs = Value(createdAtMs);
  static Insertable<VerificationCaseRow> custom({
    Expression<String>? id,
    Expression<String>? meterId,
    Expression<String>? userId,
    Expression<String>? status,
    Expression<String>? overallVerdict,
    Expression<int>? createdAtMs,
    Expression<int>? closedAtMs,
    Expression<int>? reportVersion,
    Expression<String>? checksum,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (meterId != null) 'meter_id': meterId,
      if (userId != null) 'user_id': userId,
      if (status != null) 'status': status,
      if (overallVerdict != null) 'overall_verdict': overallVerdict,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (closedAtMs != null) 'closed_at_ms': closedAtMs,
      if (reportVersion != null) 'report_version': reportVersion,
      if (checksum != null) 'checksum': checksum,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VerificationCasesCompanion copyWith({
    Value<String>? id,
    Value<String>? meterId,
    Value<String>? userId,
    Value<String>? status,
    Value<String?>? overallVerdict,
    Value<int>? createdAtMs,
    Value<int?>? closedAtMs,
    Value<int>? reportVersion,
    Value<String?>? checksum,
    Value<int>? rowid,
  }) {
    return VerificationCasesCompanion(
      id: id ?? this.id,
      meterId: meterId ?? this.meterId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      overallVerdict: overallVerdict ?? this.overallVerdict,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      closedAtMs: closedAtMs ?? this.closedAtMs,
      reportVersion: reportVersion ?? this.reportVersion,
      checksum: checksum ?? this.checksum,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (meterId.present) {
      map['meter_id'] = Variable<String>(meterId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (overallVerdict.present) {
      map['overall_verdict'] = Variable<String>(overallVerdict.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (closedAtMs.present) {
      map['closed_at_ms'] = Variable<int>(closedAtMs.value);
    }
    if (reportVersion.present) {
      map['report_version'] = Variable<int>(reportVersion.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VerificationCasesCompanion(')
          ..write('id: $id, ')
          ..write('meterId: $meterId, ')
          ..write('userId: $userId, ')
          ..write('status: $status, ')
          ..write('overallVerdict: $overallVerdict, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('closedAtMs: $closedAtMs, ')
          ..write('reportVersion: $reportVersion, ')
          ..write('checksum: $checksum, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FlowPointsTable extends FlowPoints
    with TableInfo<$FlowPointsTable, FlowPointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlowPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caseIdMeta = const VerificationMeta('caseId');
  @override
  late final GeneratedColumn<String> caseId = GeneratedColumn<String>(
    'case_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES verification_cases (id)',
    ),
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lpsApproxMeta = const VerificationMeta(
    'lpsApprox',
  );
  @override
  late final GeneratedColumn<double> lpsApprox = GeneratedColumn<double>(
    'lps_approx',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mpePctMeta = const VerificationMeta('mpePct');
  @override
  late final GeneratedColumn<double> mpePct = GeneratedColumn<double>(
    'mpe_pct',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  static const VerificationMeta _statisticsNMeta = const VerificationMeta(
    'statisticsN',
  );
  @override
  late final GeneratedColumn<int> statisticsN = GeneratedColumn<int>(
    'statistics_n',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _meanErrorPctMeta = const VerificationMeta(
    'meanErrorPct',
  );
  @override
  late final GeneratedColumn<double> meanErrorPct = GeneratedColumn<double>(
    'mean_error_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minimumErrorPctMeta = const VerificationMeta(
    'minimumErrorPct',
  );
  @override
  late final GeneratedColumn<double> minimumErrorPct = GeneratedColumn<double>(
    'minimum_error_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maximumErrorPctMeta = const VerificationMeta(
    'maximumErrorPct',
  );
  @override
  late final GeneratedColumn<double> maximumErrorPct = GeneratedColumn<double>(
    'maximum_error_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dispersionPctMeta = const VerificationMeta(
    'dispersionPct',
  );
  @override
  late final GeneratedColumn<double> dispersionPct = GeneratedColumn<double>(
    'dispersion_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sampleStdDevPctMeta = const VerificationMeta(
    'sampleStdDevPct',
  );
  @override
  late final GeneratedColumn<double> sampleStdDevPct = GeneratedColumn<double>(
    'sample_std_dev_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatabilityStatusMeta =
      const VerificationMeta('repeatabilityStatus');
  @override
  late final GeneratedColumn<String> repeatabilityStatus =
      GeneratedColumn<String>(
        'repeatability_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    caseId,
    code,
    lpsApprox,
    mpePct,
    status,
    statisticsN,
    meanErrorPct,
    minimumErrorPct,
    maximumErrorPct,
    dispersionPct,
    sampleStdDevPct,
    repeatabilityStatus,
    createdAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flow_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<FlowPointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('case_id')) {
      context.handle(
        _caseIdMeta,
        caseId.isAcceptableOrUnknown(data['case_id']!, _caseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_caseIdMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('lps_approx')) {
      context.handle(
        _lpsApproxMeta,
        lpsApprox.isAcceptableOrUnknown(data['lps_approx']!, _lpsApproxMeta),
      );
    }
    if (data.containsKey('mpe_pct')) {
      context.handle(
        _mpePctMeta,
        mpePct.isAcceptableOrUnknown(data['mpe_pct']!, _mpePctMeta),
      );
    } else if (isInserting) {
      context.missing(_mpePctMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('statistics_n')) {
      context.handle(
        _statisticsNMeta,
        statisticsN.isAcceptableOrUnknown(
          data['statistics_n']!,
          _statisticsNMeta,
        ),
      );
    }
    if (data.containsKey('mean_error_pct')) {
      context.handle(
        _meanErrorPctMeta,
        meanErrorPct.isAcceptableOrUnknown(
          data['mean_error_pct']!,
          _meanErrorPctMeta,
        ),
      );
    }
    if (data.containsKey('minimum_error_pct')) {
      context.handle(
        _minimumErrorPctMeta,
        minimumErrorPct.isAcceptableOrUnknown(
          data['minimum_error_pct']!,
          _minimumErrorPctMeta,
        ),
      );
    }
    if (data.containsKey('maximum_error_pct')) {
      context.handle(
        _maximumErrorPctMeta,
        maximumErrorPct.isAcceptableOrUnknown(
          data['maximum_error_pct']!,
          _maximumErrorPctMeta,
        ),
      );
    }
    if (data.containsKey('dispersion_pct')) {
      context.handle(
        _dispersionPctMeta,
        dispersionPct.isAcceptableOrUnknown(
          data['dispersion_pct']!,
          _dispersionPctMeta,
        ),
      );
    }
    if (data.containsKey('sample_std_dev_pct')) {
      context.handle(
        _sampleStdDevPctMeta,
        sampleStdDevPct.isAcceptableOrUnknown(
          data['sample_std_dev_pct']!,
          _sampleStdDevPctMeta,
        ),
      );
    }
    if (data.containsKey('repeatability_status')) {
      context.handle(
        _repeatabilityStatusMeta,
        repeatabilityStatus.isAcceptableOrUnknown(
          data['repeatability_status']!,
          _repeatabilityStatusMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {caseId, code},
  ];
  @override
  FlowPointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FlowPointRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      caseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}case_id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      lpsApprox: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lps_approx'],
      ),
      mpePct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mpe_pct'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      statisticsN: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}statistics_n'],
      ),
      meanErrorPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mean_error_pct'],
      ),
      minimumErrorPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}minimum_error_pct'],
      ),
      maximumErrorPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}maximum_error_pct'],
      ),
      dispersionPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dispersion_pct'],
      ),
      sampleStdDevPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sample_std_dev_pct'],
      ),
      repeatabilityStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeatability_status'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
    );
  }

  @override
  $FlowPointsTable createAlias(String alias) {
    return $FlowPointsTable(attachedDatabase, alias);
  }
}

class FlowPointRow extends DataClass implements Insertable<FlowPointRow> {
  final String id;
  final String caseId;
  final String code;
  final double? lpsApprox;
  final double mpePct;
  final String status;
  final int? statisticsN;
  final double? meanErrorPct;
  final double? minimumErrorPct;
  final double? maximumErrorPct;
  final double? dispersionPct;
  final double? sampleStdDevPct;
  final String? repeatabilityStatus;
  final int createdAtMs;
  const FlowPointRow({
    required this.id,
    required this.caseId,
    required this.code,
    this.lpsApprox,
    required this.mpePct,
    required this.status,
    this.statisticsN,
    this.meanErrorPct,
    this.minimumErrorPct,
    this.maximumErrorPct,
    this.dispersionPct,
    this.sampleStdDevPct,
    this.repeatabilityStatus,
    required this.createdAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['case_id'] = Variable<String>(caseId);
    map['code'] = Variable<String>(code);
    if (!nullToAbsent || lpsApprox != null) {
      map['lps_approx'] = Variable<double>(lpsApprox);
    }
    map['mpe_pct'] = Variable<double>(mpePct);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || statisticsN != null) {
      map['statistics_n'] = Variable<int>(statisticsN);
    }
    if (!nullToAbsent || meanErrorPct != null) {
      map['mean_error_pct'] = Variable<double>(meanErrorPct);
    }
    if (!nullToAbsent || minimumErrorPct != null) {
      map['minimum_error_pct'] = Variable<double>(minimumErrorPct);
    }
    if (!nullToAbsent || maximumErrorPct != null) {
      map['maximum_error_pct'] = Variable<double>(maximumErrorPct);
    }
    if (!nullToAbsent || dispersionPct != null) {
      map['dispersion_pct'] = Variable<double>(dispersionPct);
    }
    if (!nullToAbsent || sampleStdDevPct != null) {
      map['sample_std_dev_pct'] = Variable<double>(sampleStdDevPct);
    }
    if (!nullToAbsent || repeatabilityStatus != null) {
      map['repeatability_status'] = Variable<String>(repeatabilityStatus);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  FlowPointsCompanion toCompanion(bool nullToAbsent) {
    return FlowPointsCompanion(
      id: Value(id),
      caseId: Value(caseId),
      code: Value(code),
      lpsApprox: lpsApprox == null && nullToAbsent
          ? const Value.absent()
          : Value(lpsApprox),
      mpePct: Value(mpePct),
      status: Value(status),
      statisticsN: statisticsN == null && nullToAbsent
          ? const Value.absent()
          : Value(statisticsN),
      meanErrorPct: meanErrorPct == null && nullToAbsent
          ? const Value.absent()
          : Value(meanErrorPct),
      minimumErrorPct: minimumErrorPct == null && nullToAbsent
          ? const Value.absent()
          : Value(minimumErrorPct),
      maximumErrorPct: maximumErrorPct == null && nullToAbsent
          ? const Value.absent()
          : Value(maximumErrorPct),
      dispersionPct: dispersionPct == null && nullToAbsent
          ? const Value.absent()
          : Value(dispersionPct),
      sampleStdDevPct: sampleStdDevPct == null && nullToAbsent
          ? const Value.absent()
          : Value(sampleStdDevPct),
      repeatabilityStatus: repeatabilityStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatabilityStatus),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory FlowPointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FlowPointRow(
      id: serializer.fromJson<String>(json['id']),
      caseId: serializer.fromJson<String>(json['caseId']),
      code: serializer.fromJson<String>(json['code']),
      lpsApprox: serializer.fromJson<double?>(json['lpsApprox']),
      mpePct: serializer.fromJson<double>(json['mpePct']),
      status: serializer.fromJson<String>(json['status']),
      statisticsN: serializer.fromJson<int?>(json['statisticsN']),
      meanErrorPct: serializer.fromJson<double?>(json['meanErrorPct']),
      minimumErrorPct: serializer.fromJson<double?>(json['minimumErrorPct']),
      maximumErrorPct: serializer.fromJson<double?>(json['maximumErrorPct']),
      dispersionPct: serializer.fromJson<double?>(json['dispersionPct']),
      sampleStdDevPct: serializer.fromJson<double?>(json['sampleStdDevPct']),
      repeatabilityStatus: serializer.fromJson<String?>(
        json['repeatabilityStatus'],
      ),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'caseId': serializer.toJson<String>(caseId),
      'code': serializer.toJson<String>(code),
      'lpsApprox': serializer.toJson<double?>(lpsApprox),
      'mpePct': serializer.toJson<double>(mpePct),
      'status': serializer.toJson<String>(status),
      'statisticsN': serializer.toJson<int?>(statisticsN),
      'meanErrorPct': serializer.toJson<double?>(meanErrorPct),
      'minimumErrorPct': serializer.toJson<double?>(minimumErrorPct),
      'maximumErrorPct': serializer.toJson<double?>(maximumErrorPct),
      'dispersionPct': serializer.toJson<double?>(dispersionPct),
      'sampleStdDevPct': serializer.toJson<double?>(sampleStdDevPct),
      'repeatabilityStatus': serializer.toJson<String?>(repeatabilityStatus),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
    };
  }

  FlowPointRow copyWith({
    String? id,
    String? caseId,
    String? code,
    Value<double?> lpsApprox = const Value.absent(),
    double? mpePct,
    String? status,
    Value<int?> statisticsN = const Value.absent(),
    Value<double?> meanErrorPct = const Value.absent(),
    Value<double?> minimumErrorPct = const Value.absent(),
    Value<double?> maximumErrorPct = const Value.absent(),
    Value<double?> dispersionPct = const Value.absent(),
    Value<double?> sampleStdDevPct = const Value.absent(),
    Value<String?> repeatabilityStatus = const Value.absent(),
    int? createdAtMs,
  }) => FlowPointRow(
    id: id ?? this.id,
    caseId: caseId ?? this.caseId,
    code: code ?? this.code,
    lpsApprox: lpsApprox.present ? lpsApprox.value : this.lpsApprox,
    mpePct: mpePct ?? this.mpePct,
    status: status ?? this.status,
    statisticsN: statisticsN.present ? statisticsN.value : this.statisticsN,
    meanErrorPct: meanErrorPct.present ? meanErrorPct.value : this.meanErrorPct,
    minimumErrorPct: minimumErrorPct.present
        ? minimumErrorPct.value
        : this.minimumErrorPct,
    maximumErrorPct: maximumErrorPct.present
        ? maximumErrorPct.value
        : this.maximumErrorPct,
    dispersionPct: dispersionPct.present
        ? dispersionPct.value
        : this.dispersionPct,
    sampleStdDevPct: sampleStdDevPct.present
        ? sampleStdDevPct.value
        : this.sampleStdDevPct,
    repeatabilityStatus: repeatabilityStatus.present
        ? repeatabilityStatus.value
        : this.repeatabilityStatus,
    createdAtMs: createdAtMs ?? this.createdAtMs,
  );
  FlowPointRow copyWithCompanion(FlowPointsCompanion data) {
    return FlowPointRow(
      id: data.id.present ? data.id.value : this.id,
      caseId: data.caseId.present ? data.caseId.value : this.caseId,
      code: data.code.present ? data.code.value : this.code,
      lpsApprox: data.lpsApprox.present ? data.lpsApprox.value : this.lpsApprox,
      mpePct: data.mpePct.present ? data.mpePct.value : this.mpePct,
      status: data.status.present ? data.status.value : this.status,
      statisticsN: data.statisticsN.present
          ? data.statisticsN.value
          : this.statisticsN,
      meanErrorPct: data.meanErrorPct.present
          ? data.meanErrorPct.value
          : this.meanErrorPct,
      minimumErrorPct: data.minimumErrorPct.present
          ? data.minimumErrorPct.value
          : this.minimumErrorPct,
      maximumErrorPct: data.maximumErrorPct.present
          ? data.maximumErrorPct.value
          : this.maximumErrorPct,
      dispersionPct: data.dispersionPct.present
          ? data.dispersionPct.value
          : this.dispersionPct,
      sampleStdDevPct: data.sampleStdDevPct.present
          ? data.sampleStdDevPct.value
          : this.sampleStdDevPct,
      repeatabilityStatus: data.repeatabilityStatus.present
          ? data.repeatabilityStatus.value
          : this.repeatabilityStatus,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FlowPointRow(')
          ..write('id: $id, ')
          ..write('caseId: $caseId, ')
          ..write('code: $code, ')
          ..write('lpsApprox: $lpsApprox, ')
          ..write('mpePct: $mpePct, ')
          ..write('status: $status, ')
          ..write('statisticsN: $statisticsN, ')
          ..write('meanErrorPct: $meanErrorPct, ')
          ..write('minimumErrorPct: $minimumErrorPct, ')
          ..write('maximumErrorPct: $maximumErrorPct, ')
          ..write('dispersionPct: $dispersionPct, ')
          ..write('sampleStdDevPct: $sampleStdDevPct, ')
          ..write('repeatabilityStatus: $repeatabilityStatus, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    caseId,
    code,
    lpsApprox,
    mpePct,
    status,
    statisticsN,
    meanErrorPct,
    minimumErrorPct,
    maximumErrorPct,
    dispersionPct,
    sampleStdDevPct,
    repeatabilityStatus,
    createdAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlowPointRow &&
          other.id == this.id &&
          other.caseId == this.caseId &&
          other.code == this.code &&
          other.lpsApprox == this.lpsApprox &&
          other.mpePct == this.mpePct &&
          other.status == this.status &&
          other.statisticsN == this.statisticsN &&
          other.meanErrorPct == this.meanErrorPct &&
          other.minimumErrorPct == this.minimumErrorPct &&
          other.maximumErrorPct == this.maximumErrorPct &&
          other.dispersionPct == this.dispersionPct &&
          other.sampleStdDevPct == this.sampleStdDevPct &&
          other.repeatabilityStatus == this.repeatabilityStatus &&
          other.createdAtMs == this.createdAtMs);
}

class FlowPointsCompanion extends UpdateCompanion<FlowPointRow> {
  final Value<String> id;
  final Value<String> caseId;
  final Value<String> code;
  final Value<double?> lpsApprox;
  final Value<double> mpePct;
  final Value<String> status;
  final Value<int?> statisticsN;
  final Value<double?> meanErrorPct;
  final Value<double?> minimumErrorPct;
  final Value<double?> maximumErrorPct;
  final Value<double?> dispersionPct;
  final Value<double?> sampleStdDevPct;
  final Value<String?> repeatabilityStatus;
  final Value<int> createdAtMs;
  final Value<int> rowid;
  const FlowPointsCompanion({
    this.id = const Value.absent(),
    this.caseId = const Value.absent(),
    this.code = const Value.absent(),
    this.lpsApprox = const Value.absent(),
    this.mpePct = const Value.absent(),
    this.status = const Value.absent(),
    this.statisticsN = const Value.absent(),
    this.meanErrorPct = const Value.absent(),
    this.minimumErrorPct = const Value.absent(),
    this.maximumErrorPct = const Value.absent(),
    this.dispersionPct = const Value.absent(),
    this.sampleStdDevPct = const Value.absent(),
    this.repeatabilityStatus = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FlowPointsCompanion.insert({
    required String id,
    required String caseId,
    required String code,
    this.lpsApprox = const Value.absent(),
    required double mpePct,
    this.status = const Value.absent(),
    this.statisticsN = const Value.absent(),
    this.meanErrorPct = const Value.absent(),
    this.minimumErrorPct = const Value.absent(),
    this.maximumErrorPct = const Value.absent(),
    this.dispersionPct = const Value.absent(),
    this.sampleStdDevPct = const Value.absent(),
    this.repeatabilityStatus = const Value.absent(),
    required int createdAtMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       caseId = Value(caseId),
       code = Value(code),
       mpePct = Value(mpePct),
       createdAtMs = Value(createdAtMs);
  static Insertable<FlowPointRow> custom({
    Expression<String>? id,
    Expression<String>? caseId,
    Expression<String>? code,
    Expression<double>? lpsApprox,
    Expression<double>? mpePct,
    Expression<String>? status,
    Expression<int>? statisticsN,
    Expression<double>? meanErrorPct,
    Expression<double>? minimumErrorPct,
    Expression<double>? maximumErrorPct,
    Expression<double>? dispersionPct,
    Expression<double>? sampleStdDevPct,
    Expression<String>? repeatabilityStatus,
    Expression<int>? createdAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (caseId != null) 'case_id': caseId,
      if (code != null) 'code': code,
      if (lpsApprox != null) 'lps_approx': lpsApprox,
      if (mpePct != null) 'mpe_pct': mpePct,
      if (status != null) 'status': status,
      if (statisticsN != null) 'statistics_n': statisticsN,
      if (meanErrorPct != null) 'mean_error_pct': meanErrorPct,
      if (minimumErrorPct != null) 'minimum_error_pct': minimumErrorPct,
      if (maximumErrorPct != null) 'maximum_error_pct': maximumErrorPct,
      if (dispersionPct != null) 'dispersion_pct': dispersionPct,
      if (sampleStdDevPct != null) 'sample_std_dev_pct': sampleStdDevPct,
      if (repeatabilityStatus != null)
        'repeatability_status': repeatabilityStatus,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FlowPointsCompanion copyWith({
    Value<String>? id,
    Value<String>? caseId,
    Value<String>? code,
    Value<double?>? lpsApprox,
    Value<double>? mpePct,
    Value<String>? status,
    Value<int?>? statisticsN,
    Value<double?>? meanErrorPct,
    Value<double?>? minimumErrorPct,
    Value<double?>? maximumErrorPct,
    Value<double?>? dispersionPct,
    Value<double?>? sampleStdDevPct,
    Value<String?>? repeatabilityStatus,
    Value<int>? createdAtMs,
    Value<int>? rowid,
  }) {
    return FlowPointsCompanion(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      code: code ?? this.code,
      lpsApprox: lpsApprox ?? this.lpsApprox,
      mpePct: mpePct ?? this.mpePct,
      status: status ?? this.status,
      statisticsN: statisticsN ?? this.statisticsN,
      meanErrorPct: meanErrorPct ?? this.meanErrorPct,
      minimumErrorPct: minimumErrorPct ?? this.minimumErrorPct,
      maximumErrorPct: maximumErrorPct ?? this.maximumErrorPct,
      dispersionPct: dispersionPct ?? this.dispersionPct,
      sampleStdDevPct: sampleStdDevPct ?? this.sampleStdDevPct,
      repeatabilityStatus: repeatabilityStatus ?? this.repeatabilityStatus,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (caseId.present) {
      map['case_id'] = Variable<String>(caseId.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (lpsApprox.present) {
      map['lps_approx'] = Variable<double>(lpsApprox.value);
    }
    if (mpePct.present) {
      map['mpe_pct'] = Variable<double>(mpePct.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (statisticsN.present) {
      map['statistics_n'] = Variable<int>(statisticsN.value);
    }
    if (meanErrorPct.present) {
      map['mean_error_pct'] = Variable<double>(meanErrorPct.value);
    }
    if (minimumErrorPct.present) {
      map['minimum_error_pct'] = Variable<double>(minimumErrorPct.value);
    }
    if (maximumErrorPct.present) {
      map['maximum_error_pct'] = Variable<double>(maximumErrorPct.value);
    }
    if (dispersionPct.present) {
      map['dispersion_pct'] = Variable<double>(dispersionPct.value);
    }
    if (sampleStdDevPct.present) {
      map['sample_std_dev_pct'] = Variable<double>(sampleStdDevPct.value);
    }
    if (repeatabilityStatus.present) {
      map['repeatability_status'] = Variable<String>(repeatabilityStatus.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlowPointsCompanion(')
          ..write('id: $id, ')
          ..write('caseId: $caseId, ')
          ..write('code: $code, ')
          ..write('lpsApprox: $lpsApprox, ')
          ..write('mpePct: $mpePct, ')
          ..write('status: $status, ')
          ..write('statisticsN: $statisticsN, ')
          ..write('meanErrorPct: $meanErrorPct, ')
          ..write('minimumErrorPct: $minimumErrorPct, ')
          ..write('maximumErrorPct: $maximumErrorPct, ')
          ..write('dispersionPct: $dispersionPct, ')
          ..write('sampleStdDevPct: $sampleStdDevPct, ')
          ..write('repeatabilityStatus: $repeatabilityStatus, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SamplesTable extends Samples with TableInfo<$SamplesTable, SampleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _flowPointIdMeta = const VerificationMeta(
    'flowPointId',
  );
  @override
  late final GeneratedColumn<String> flowPointId = GeneratedColumn<String>(
    'flow_point_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES flow_points (id)',
    ),
  );
  static const VerificationMeta _sampleNumberMeta = const VerificationMeta(
    'sampleNumber',
  );
  @override
  late final GeneratedColumn<int> sampleNumber = GeneratedColumn<int>(
    'sample_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _measurementMethodMeta = const VerificationMeta(
    'measurementMethod',
  );
  @override
  late final GeneratedColumn<String> measurementMethod =
      GeneratedColumn<String>(
        'measurement_method',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _litersPerPulseMeta = const VerificationMeta(
    'litersPerPulse',
  );
  @override
  late final GeneratedColumn<double> litersPerPulse = GeneratedColumn<double>(
    'liters_per_pulse',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceStepLitersMeta =
      const VerificationMeta('evidenceStepLiters');
  @override
  late final GeneratedColumn<double> evidenceStepLiters =
      GeneratedColumn<double>(
        'evidence_step_liters',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _readingUncertaintyLitersMeta =
      const VerificationMeta('readingUncertaintyLiters');
  @override
  late final GeneratedColumn<double> readingUncertaintyLiters =
      GeneratedColumn<double>(
        'reading_uncertainty_liters',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _flowPointCodeMeta = const VerificationMeta(
    'flowPointCode',
  );
  @override
  late final GeneratedColumn<String> flowPointCode = GeneratedColumn<String>(
    'flow_point_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mpePctMeta = const VerificationMeta('mpePct');
  @override
  late final GeneratedColumn<double> mpePct = GeneratedColumn<double>(
    'mpe_pct',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lpsApproxMeta = const VerificationMeta(
    'lpsApprox',
  );
  @override
  late final GeneratedColumn<double> lpsApprox = GeneratedColumn<double>(
    'lps_approx',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _litersPerOdometerUnitMeta =
      const VerificationMeta('litersPerOdometerUnit');
  @override
  late final GeneratedColumn<double> litersPerOdometerUnit =
      GeneratedColumn<double>(
        'liters_per_odometer_unit',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _needleLitersPerRevolutionMeta =
      const VerificationMeta('needleLitersPerRevolution');
  @override
  late final GeneratedColumn<double> needleLitersPerRevolution =
      GeneratedColumn<double>(
        'needle_liters_per_revolution',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMsMeta = const VerificationMeta(
    'startedAtMs',
  );
  @override
  late final GeneratedColumn<int> startedAtMs = GeneratedColumn<int>(
    'started_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endedAtMsMeta = const VerificationMeta(
    'endedAtMs',
  );
  @override
  late final GeneratedColumn<int> endedAtMs = GeneratedColumn<int>(
    'ended_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gpsLatitudeMeta = const VerificationMeta(
    'gpsLatitude',
  );
  @override
  late final GeneratedColumn<double> gpsLatitude = GeneratedColumn<double>(
    'gps_latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gpsLongitudeMeta = const VerificationMeta(
    'gpsLongitude',
  );
  @override
  late final GeneratedColumn<double> gpsLongitude = GeneratedColumn<double>(
    'gps_longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gpsAccuracyMetersMeta = const VerificationMeta(
    'gpsAccuracyMeters',
  );
  @override
  late final GeneratedColumn<double> gpsAccuracyMeters =
      GeneratedColumn<double>(
        'gps_accuracy_meters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _gpsCapturedAtMsMeta = const VerificationMeta(
    'gpsCapturedAtMs',
  );
  @override
  late final GeneratedColumn<int> gpsCapturedAtMs = GeneratedColumn<int>(
    'gps_captured_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pulseCountMeta = const VerificationMeta(
    'pulseCount',
  );
  @override
  late final GeneratedColumn<int> pulseCount = GeneratedColumn<int>(
    'pulse_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _progressReferenceLitersMeta =
      const VerificationMeta('progressReferenceLiters');
  @override
  late final GeneratedColumn<double> progressReferenceLiters =
      GeneratedColumn<double>(
        'progress_reference_liters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _initialOdometerUnitsMeta =
      const VerificationMeta('initialOdometerUnits');
  @override
  late final GeneratedColumn<double> initialOdometerUnits =
      GeneratedColumn<double>(
        'initial_odometer_units',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _initialNeedleLitersMeta =
      const VerificationMeta('initialNeedleLiters');
  @override
  late final GeneratedColumn<double> initialNeedleLiters =
      GeneratedColumn<double>(
        'initial_needle_liters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _initialReadingSourceMeta =
      const VerificationMeta('initialReadingSource');
  @override
  late final GeneratedColumn<String> initialReadingSource =
      GeneratedColumn<String>(
        'initial_reading_source',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _finalOdometerUnitsMeta =
      const VerificationMeta('finalOdometerUnits');
  @override
  late final GeneratedColumn<double> finalOdometerUnits =
      GeneratedColumn<double>(
        'final_odometer_units',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _finalNeedleLitersMeta = const VerificationMeta(
    'finalNeedleLiters',
  );
  @override
  late final GeneratedColumn<double> finalNeedleLiters =
      GeneratedColumn<double>(
        'final_needle_liters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _finalReadingSourceMeta =
      const VerificationMeta('finalReadingSource');
  @override
  late final GeneratedColumn<String> finalReadingSource =
      GeneratedColumn<String>(
        'final_reading_source',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _referenceLitersMeta = const VerificationMeta(
    'referenceLiters',
  );
  @override
  late final GeneratedColumn<double> referenceLiters = GeneratedColumn<double>(
    'reference_liters',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _indicatedLitersMeta = const VerificationMeta(
    'indicatedLiters',
  );
  @override
  late final GeneratedColumn<double> indicatedLiters = GeneratedColumn<double>(
    'indicated_liters',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorPctMeta = const VerificationMeta(
    'errorPct',
  );
  @override
  late final GeneratedColumn<double> errorPct = GeneratedColumn<double>(
    'error_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uncertaintyPctMeta = const VerificationMeta(
    'uncertaintyPct',
  );
  @override
  late final GeneratedColumn<double> uncertaintyPct = GeneratedColumn<double>(
    'uncertainty_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resultMpePctMeta = const VerificationMeta(
    'resultMpePct',
  );
  @override
  late final GeneratedColumn<double> resultMpePct = GeneratedColumn<double>(
    'result_mpe_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _acceptanceMetricPctMeta =
      const VerificationMeta('acceptanceMetricPct');
  @override
  late final GeneratedColumn<double> acceptanceMetricPct =
      GeneratedColumn<double>(
        'acceptance_metric_pct',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rejectionMetricPctMeta =
      const VerificationMeta('rejectionMetricPct');
  @override
  late final GeneratedColumn<double> rejectionMetricPct =
      GeneratedColumn<double>(
        'rejection_metric_pct',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _verdictMeta = const VerificationMeta(
    'verdict',
  );
  @override
  late final GeneratedColumn<String> verdict = GeneratedColumn<String>(
    'verdict',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    flowPointId,
    sampleNumber,
    status,
    measurementMethod,
    litersPerPulse,
    evidenceStepLiters,
    readingUncertaintyLiters,
    flowPointCode,
    mpePct,
    lpsApprox,
    litersPerOdometerUnit,
    needleLitersPerRevolution,
    createdAtMs,
    updatedAtMs,
    startedAtMs,
    endedAtMs,
    gpsLatitude,
    gpsLongitude,
    gpsAccuracyMeters,
    gpsCapturedAtMs,
    pulseCount,
    progressReferenceLiters,
    initialOdometerUnits,
    initialNeedleLiters,
    initialReadingSource,
    finalOdometerUnits,
    finalNeedleLiters,
    finalReadingSource,
    referenceLiters,
    indicatedLiters,
    errorPct,
    uncertaintyPct,
    resultMpePct,
    acceptanceMetricPct,
    rejectionMetricPct,
    verdict,
    checksum,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<SampleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('flow_point_id')) {
      context.handle(
        _flowPointIdMeta,
        flowPointId.isAcceptableOrUnknown(
          data['flow_point_id']!,
          _flowPointIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_flowPointIdMeta);
    }
    if (data.containsKey('sample_number')) {
      context.handle(
        _sampleNumberMeta,
        sampleNumber.isAcceptableOrUnknown(
          data['sample_number']!,
          _sampleNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sampleNumberMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('measurement_method')) {
      context.handle(
        _measurementMethodMeta,
        measurementMethod.isAcceptableOrUnknown(
          data['measurement_method']!,
          _measurementMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_measurementMethodMeta);
    }
    if (data.containsKey('liters_per_pulse')) {
      context.handle(
        _litersPerPulseMeta,
        litersPerPulse.isAcceptableOrUnknown(
          data['liters_per_pulse']!,
          _litersPerPulseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_litersPerPulseMeta);
    }
    if (data.containsKey('evidence_step_liters')) {
      context.handle(
        _evidenceStepLitersMeta,
        evidenceStepLiters.isAcceptableOrUnknown(
          data['evidence_step_liters']!,
          _evidenceStepLitersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evidenceStepLitersMeta);
    }
    if (data.containsKey('reading_uncertainty_liters')) {
      context.handle(
        _readingUncertaintyLitersMeta,
        readingUncertaintyLiters.isAcceptableOrUnknown(
          data['reading_uncertainty_liters']!,
          _readingUncertaintyLitersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_readingUncertaintyLitersMeta);
    }
    if (data.containsKey('flow_point_code')) {
      context.handle(
        _flowPointCodeMeta,
        flowPointCode.isAcceptableOrUnknown(
          data['flow_point_code']!,
          _flowPointCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_flowPointCodeMeta);
    }
    if (data.containsKey('mpe_pct')) {
      context.handle(
        _mpePctMeta,
        mpePct.isAcceptableOrUnknown(data['mpe_pct']!, _mpePctMeta),
      );
    } else if (isInserting) {
      context.missing(_mpePctMeta);
    }
    if (data.containsKey('lps_approx')) {
      context.handle(
        _lpsApproxMeta,
        lpsApprox.isAcceptableOrUnknown(data['lps_approx']!, _lpsApproxMeta),
      );
    }
    if (data.containsKey('liters_per_odometer_unit')) {
      context.handle(
        _litersPerOdometerUnitMeta,
        litersPerOdometerUnit.isAcceptableOrUnknown(
          data['liters_per_odometer_unit']!,
          _litersPerOdometerUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_litersPerOdometerUnitMeta);
    }
    if (data.containsKey('needle_liters_per_revolution')) {
      context.handle(
        _needleLitersPerRevolutionMeta,
        needleLitersPerRevolution.isAcceptableOrUnknown(
          data['needle_liters_per_revolution']!,
          _needleLitersPerRevolutionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_needleLitersPerRevolutionMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    if (data.containsKey('started_at_ms')) {
      context.handle(
        _startedAtMsMeta,
        startedAtMs.isAcceptableOrUnknown(
          data['started_at_ms']!,
          _startedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('ended_at_ms')) {
      context.handle(
        _endedAtMsMeta,
        endedAtMs.isAcceptableOrUnknown(data['ended_at_ms']!, _endedAtMsMeta),
      );
    }
    if (data.containsKey('gps_latitude')) {
      context.handle(
        _gpsLatitudeMeta,
        gpsLatitude.isAcceptableOrUnknown(
          data['gps_latitude']!,
          _gpsLatitudeMeta,
        ),
      );
    }
    if (data.containsKey('gps_longitude')) {
      context.handle(
        _gpsLongitudeMeta,
        gpsLongitude.isAcceptableOrUnknown(
          data['gps_longitude']!,
          _gpsLongitudeMeta,
        ),
      );
    }
    if (data.containsKey('gps_accuracy_meters')) {
      context.handle(
        _gpsAccuracyMetersMeta,
        gpsAccuracyMeters.isAcceptableOrUnknown(
          data['gps_accuracy_meters']!,
          _gpsAccuracyMetersMeta,
        ),
      );
    }
    if (data.containsKey('gps_captured_at_ms')) {
      context.handle(
        _gpsCapturedAtMsMeta,
        gpsCapturedAtMs.isAcceptableOrUnknown(
          data['gps_captured_at_ms']!,
          _gpsCapturedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('pulse_count')) {
      context.handle(
        _pulseCountMeta,
        pulseCount.isAcceptableOrUnknown(data['pulse_count']!, _pulseCountMeta),
      );
    }
    if (data.containsKey('progress_reference_liters')) {
      context.handle(
        _progressReferenceLitersMeta,
        progressReferenceLiters.isAcceptableOrUnknown(
          data['progress_reference_liters']!,
          _progressReferenceLitersMeta,
        ),
      );
    }
    if (data.containsKey('initial_odometer_units')) {
      context.handle(
        _initialOdometerUnitsMeta,
        initialOdometerUnits.isAcceptableOrUnknown(
          data['initial_odometer_units']!,
          _initialOdometerUnitsMeta,
        ),
      );
    }
    if (data.containsKey('initial_needle_liters')) {
      context.handle(
        _initialNeedleLitersMeta,
        initialNeedleLiters.isAcceptableOrUnknown(
          data['initial_needle_liters']!,
          _initialNeedleLitersMeta,
        ),
      );
    }
    if (data.containsKey('initial_reading_source')) {
      context.handle(
        _initialReadingSourceMeta,
        initialReadingSource.isAcceptableOrUnknown(
          data['initial_reading_source']!,
          _initialReadingSourceMeta,
        ),
      );
    }
    if (data.containsKey('final_odometer_units')) {
      context.handle(
        _finalOdometerUnitsMeta,
        finalOdometerUnits.isAcceptableOrUnknown(
          data['final_odometer_units']!,
          _finalOdometerUnitsMeta,
        ),
      );
    }
    if (data.containsKey('final_needle_liters')) {
      context.handle(
        _finalNeedleLitersMeta,
        finalNeedleLiters.isAcceptableOrUnknown(
          data['final_needle_liters']!,
          _finalNeedleLitersMeta,
        ),
      );
    }
    if (data.containsKey('final_reading_source')) {
      context.handle(
        _finalReadingSourceMeta,
        finalReadingSource.isAcceptableOrUnknown(
          data['final_reading_source']!,
          _finalReadingSourceMeta,
        ),
      );
    }
    if (data.containsKey('reference_liters')) {
      context.handle(
        _referenceLitersMeta,
        referenceLiters.isAcceptableOrUnknown(
          data['reference_liters']!,
          _referenceLitersMeta,
        ),
      );
    }
    if (data.containsKey('indicated_liters')) {
      context.handle(
        _indicatedLitersMeta,
        indicatedLiters.isAcceptableOrUnknown(
          data['indicated_liters']!,
          _indicatedLitersMeta,
        ),
      );
    }
    if (data.containsKey('error_pct')) {
      context.handle(
        _errorPctMeta,
        errorPct.isAcceptableOrUnknown(data['error_pct']!, _errorPctMeta),
      );
    }
    if (data.containsKey('uncertainty_pct')) {
      context.handle(
        _uncertaintyPctMeta,
        uncertaintyPct.isAcceptableOrUnknown(
          data['uncertainty_pct']!,
          _uncertaintyPctMeta,
        ),
      );
    }
    if (data.containsKey('result_mpe_pct')) {
      context.handle(
        _resultMpePctMeta,
        resultMpePct.isAcceptableOrUnknown(
          data['result_mpe_pct']!,
          _resultMpePctMeta,
        ),
      );
    }
    if (data.containsKey('acceptance_metric_pct')) {
      context.handle(
        _acceptanceMetricPctMeta,
        acceptanceMetricPct.isAcceptableOrUnknown(
          data['acceptance_metric_pct']!,
          _acceptanceMetricPctMeta,
        ),
      );
    }
    if (data.containsKey('rejection_metric_pct')) {
      context.handle(
        _rejectionMetricPctMeta,
        rejectionMetricPct.isAcceptableOrUnknown(
          data['rejection_metric_pct']!,
          _rejectionMetricPctMeta,
        ),
      );
    }
    if (data.containsKey('verdict')) {
      context.handle(
        _verdictMeta,
        verdict.isAcceptableOrUnknown(data['verdict']!, _verdictMeta),
      );
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {flowPointId, sampleNumber},
  ];
  @override
  SampleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SampleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      flowPointId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flow_point_id'],
      )!,
      sampleNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_number'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      measurementMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measurement_method'],
      )!,
      litersPerPulse: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}liters_per_pulse'],
      )!,
      evidenceStepLiters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}evidence_step_liters'],
      )!,
      readingUncertaintyLiters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reading_uncertainty_liters'],
      )!,
      flowPointCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flow_point_code'],
      )!,
      mpePct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mpe_pct'],
      )!,
      lpsApprox: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lps_approx'],
      ),
      litersPerOdometerUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}liters_per_odometer_unit'],
      )!,
      needleLitersPerRevolution: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}needle_liters_per_revolution'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      startedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at_ms'],
      ),
      endedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at_ms'],
      ),
      gpsLatitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gps_latitude'],
      ),
      gpsLongitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gps_longitude'],
      ),
      gpsAccuracyMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gps_accuracy_meters'],
      ),
      gpsCapturedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gps_captured_at_ms'],
      ),
      pulseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pulse_count'],
      )!,
      progressReferenceLiters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress_reference_liters'],
      ),
      initialOdometerUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}initial_odometer_units'],
      ),
      initialNeedleLiters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}initial_needle_liters'],
      ),
      initialReadingSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}initial_reading_source'],
      ),
      finalOdometerUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}final_odometer_units'],
      ),
      finalNeedleLiters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}final_needle_liters'],
      ),
      finalReadingSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}final_reading_source'],
      ),
      referenceLiters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reference_liters'],
      ),
      indicatedLiters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}indicated_liters'],
      ),
      errorPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}error_pct'],
      ),
      uncertaintyPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}uncertainty_pct'],
      ),
      resultMpePct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}result_mpe_pct'],
      ),
      acceptanceMetricPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}acceptance_metric_pct'],
      ),
      rejectionMetricPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rejection_metric_pct'],
      ),
      verdict: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verdict'],
      ),
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      ),
    );
  }

  @override
  $SamplesTable createAlias(String alias) {
    return $SamplesTable(attachedDatabase, alias);
  }
}

class SampleRow extends DataClass implements Insertable<SampleRow> {
  final String id;
  final String flowPointId;
  final int sampleNumber;
  final String status;
  final String measurementMethod;
  final double litersPerPulse;
  final double evidenceStepLiters;
  final double readingUncertaintyLiters;
  final String flowPointCode;
  final double mpePct;
  final double? lpsApprox;
  final double litersPerOdometerUnit;
  final double needleLitersPerRevolution;
  final int createdAtMs;
  final int updatedAtMs;
  final int? startedAtMs;
  final int? endedAtMs;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final double? gpsAccuracyMeters;
  final int? gpsCapturedAtMs;
  final int pulseCount;
  final double? progressReferenceLiters;
  final double? initialOdometerUnits;
  final double? initialNeedleLiters;
  final String? initialReadingSource;
  final double? finalOdometerUnits;
  final double? finalNeedleLiters;
  final String? finalReadingSource;
  final double? referenceLiters;
  final double? indicatedLiters;
  final double? errorPct;
  final double? uncertaintyPct;
  final double? resultMpePct;
  final double? acceptanceMetricPct;
  final double? rejectionMetricPct;
  final String? verdict;
  final String? checksum;
  const SampleRow({
    required this.id,
    required this.flowPointId,
    required this.sampleNumber,
    required this.status,
    required this.measurementMethod,
    required this.litersPerPulse,
    required this.evidenceStepLiters,
    required this.readingUncertaintyLiters,
    required this.flowPointCode,
    required this.mpePct,
    this.lpsApprox,
    required this.litersPerOdometerUnit,
    required this.needleLitersPerRevolution,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.startedAtMs,
    this.endedAtMs,
    this.gpsLatitude,
    this.gpsLongitude,
    this.gpsAccuracyMeters,
    this.gpsCapturedAtMs,
    required this.pulseCount,
    this.progressReferenceLiters,
    this.initialOdometerUnits,
    this.initialNeedleLiters,
    this.initialReadingSource,
    this.finalOdometerUnits,
    this.finalNeedleLiters,
    this.finalReadingSource,
    this.referenceLiters,
    this.indicatedLiters,
    this.errorPct,
    this.uncertaintyPct,
    this.resultMpePct,
    this.acceptanceMetricPct,
    this.rejectionMetricPct,
    this.verdict,
    this.checksum,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['flow_point_id'] = Variable<String>(flowPointId);
    map['sample_number'] = Variable<int>(sampleNumber);
    map['status'] = Variable<String>(status);
    map['measurement_method'] = Variable<String>(measurementMethod);
    map['liters_per_pulse'] = Variable<double>(litersPerPulse);
    map['evidence_step_liters'] = Variable<double>(evidenceStepLiters);
    map['reading_uncertainty_liters'] = Variable<double>(
      readingUncertaintyLiters,
    );
    map['flow_point_code'] = Variable<String>(flowPointCode);
    map['mpe_pct'] = Variable<double>(mpePct);
    if (!nullToAbsent || lpsApprox != null) {
      map['lps_approx'] = Variable<double>(lpsApprox);
    }
    map['liters_per_odometer_unit'] = Variable<double>(litersPerOdometerUnit);
    map['needle_liters_per_revolution'] = Variable<double>(
      needleLitersPerRevolution,
    );
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    if (!nullToAbsent || startedAtMs != null) {
      map['started_at_ms'] = Variable<int>(startedAtMs);
    }
    if (!nullToAbsent || endedAtMs != null) {
      map['ended_at_ms'] = Variable<int>(endedAtMs);
    }
    if (!nullToAbsent || gpsLatitude != null) {
      map['gps_latitude'] = Variable<double>(gpsLatitude);
    }
    if (!nullToAbsent || gpsLongitude != null) {
      map['gps_longitude'] = Variable<double>(gpsLongitude);
    }
    if (!nullToAbsent || gpsAccuracyMeters != null) {
      map['gps_accuracy_meters'] = Variable<double>(gpsAccuracyMeters);
    }
    if (!nullToAbsent || gpsCapturedAtMs != null) {
      map['gps_captured_at_ms'] = Variable<int>(gpsCapturedAtMs);
    }
    map['pulse_count'] = Variable<int>(pulseCount);
    if (!nullToAbsent || progressReferenceLiters != null) {
      map['progress_reference_liters'] = Variable<double>(
        progressReferenceLiters,
      );
    }
    if (!nullToAbsent || initialOdometerUnits != null) {
      map['initial_odometer_units'] = Variable<double>(initialOdometerUnits);
    }
    if (!nullToAbsent || initialNeedleLiters != null) {
      map['initial_needle_liters'] = Variable<double>(initialNeedleLiters);
    }
    if (!nullToAbsent || initialReadingSource != null) {
      map['initial_reading_source'] = Variable<String>(initialReadingSource);
    }
    if (!nullToAbsent || finalOdometerUnits != null) {
      map['final_odometer_units'] = Variable<double>(finalOdometerUnits);
    }
    if (!nullToAbsent || finalNeedleLiters != null) {
      map['final_needle_liters'] = Variable<double>(finalNeedleLiters);
    }
    if (!nullToAbsent || finalReadingSource != null) {
      map['final_reading_source'] = Variable<String>(finalReadingSource);
    }
    if (!nullToAbsent || referenceLiters != null) {
      map['reference_liters'] = Variable<double>(referenceLiters);
    }
    if (!nullToAbsent || indicatedLiters != null) {
      map['indicated_liters'] = Variable<double>(indicatedLiters);
    }
    if (!nullToAbsent || errorPct != null) {
      map['error_pct'] = Variable<double>(errorPct);
    }
    if (!nullToAbsent || uncertaintyPct != null) {
      map['uncertainty_pct'] = Variable<double>(uncertaintyPct);
    }
    if (!nullToAbsent || resultMpePct != null) {
      map['result_mpe_pct'] = Variable<double>(resultMpePct);
    }
    if (!nullToAbsent || acceptanceMetricPct != null) {
      map['acceptance_metric_pct'] = Variable<double>(acceptanceMetricPct);
    }
    if (!nullToAbsent || rejectionMetricPct != null) {
      map['rejection_metric_pct'] = Variable<double>(rejectionMetricPct);
    }
    if (!nullToAbsent || verdict != null) {
      map['verdict'] = Variable<String>(verdict);
    }
    if (!nullToAbsent || checksum != null) {
      map['checksum'] = Variable<String>(checksum);
    }
    return map;
  }

  SamplesCompanion toCompanion(bool nullToAbsent) {
    return SamplesCompanion(
      id: Value(id),
      flowPointId: Value(flowPointId),
      sampleNumber: Value(sampleNumber),
      status: Value(status),
      measurementMethod: Value(measurementMethod),
      litersPerPulse: Value(litersPerPulse),
      evidenceStepLiters: Value(evidenceStepLiters),
      readingUncertaintyLiters: Value(readingUncertaintyLiters),
      flowPointCode: Value(flowPointCode),
      mpePct: Value(mpePct),
      lpsApprox: lpsApprox == null && nullToAbsent
          ? const Value.absent()
          : Value(lpsApprox),
      litersPerOdometerUnit: Value(litersPerOdometerUnit),
      needleLitersPerRevolution: Value(needleLitersPerRevolution),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      startedAtMs: startedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAtMs),
      endedAtMs: endedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAtMs),
      gpsLatitude: gpsLatitude == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsLatitude),
      gpsLongitude: gpsLongitude == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsLongitude),
      gpsAccuracyMeters: gpsAccuracyMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsAccuracyMeters),
      gpsCapturedAtMs: gpsCapturedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsCapturedAtMs),
      pulseCount: Value(pulseCount),
      progressReferenceLiters: progressReferenceLiters == null && nullToAbsent
          ? const Value.absent()
          : Value(progressReferenceLiters),
      initialOdometerUnits: initialOdometerUnits == null && nullToAbsent
          ? const Value.absent()
          : Value(initialOdometerUnits),
      initialNeedleLiters: initialNeedleLiters == null && nullToAbsent
          ? const Value.absent()
          : Value(initialNeedleLiters),
      initialReadingSource: initialReadingSource == null && nullToAbsent
          ? const Value.absent()
          : Value(initialReadingSource),
      finalOdometerUnits: finalOdometerUnits == null && nullToAbsent
          ? const Value.absent()
          : Value(finalOdometerUnits),
      finalNeedleLiters: finalNeedleLiters == null && nullToAbsent
          ? const Value.absent()
          : Value(finalNeedleLiters),
      finalReadingSource: finalReadingSource == null && nullToAbsent
          ? const Value.absent()
          : Value(finalReadingSource),
      referenceLiters: referenceLiters == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceLiters),
      indicatedLiters: indicatedLiters == null && nullToAbsent
          ? const Value.absent()
          : Value(indicatedLiters),
      errorPct: errorPct == null && nullToAbsent
          ? const Value.absent()
          : Value(errorPct),
      uncertaintyPct: uncertaintyPct == null && nullToAbsent
          ? const Value.absent()
          : Value(uncertaintyPct),
      resultMpePct: resultMpePct == null && nullToAbsent
          ? const Value.absent()
          : Value(resultMpePct),
      acceptanceMetricPct: acceptanceMetricPct == null && nullToAbsent
          ? const Value.absent()
          : Value(acceptanceMetricPct),
      rejectionMetricPct: rejectionMetricPct == null && nullToAbsent
          ? const Value.absent()
          : Value(rejectionMetricPct),
      verdict: verdict == null && nullToAbsent
          ? const Value.absent()
          : Value(verdict),
      checksum: checksum == null && nullToAbsent
          ? const Value.absent()
          : Value(checksum),
    );
  }

  factory SampleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SampleRow(
      id: serializer.fromJson<String>(json['id']),
      flowPointId: serializer.fromJson<String>(json['flowPointId']),
      sampleNumber: serializer.fromJson<int>(json['sampleNumber']),
      status: serializer.fromJson<String>(json['status']),
      measurementMethod: serializer.fromJson<String>(json['measurementMethod']),
      litersPerPulse: serializer.fromJson<double>(json['litersPerPulse']),
      evidenceStepLiters: serializer.fromJson<double>(
        json['evidenceStepLiters'],
      ),
      readingUncertaintyLiters: serializer.fromJson<double>(
        json['readingUncertaintyLiters'],
      ),
      flowPointCode: serializer.fromJson<String>(json['flowPointCode']),
      mpePct: serializer.fromJson<double>(json['mpePct']),
      lpsApprox: serializer.fromJson<double?>(json['lpsApprox']),
      litersPerOdometerUnit: serializer.fromJson<double>(
        json['litersPerOdometerUnit'],
      ),
      needleLitersPerRevolution: serializer.fromJson<double>(
        json['needleLitersPerRevolution'],
      ),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      startedAtMs: serializer.fromJson<int?>(json['startedAtMs']),
      endedAtMs: serializer.fromJson<int?>(json['endedAtMs']),
      gpsLatitude: serializer.fromJson<double?>(json['gpsLatitude']),
      gpsLongitude: serializer.fromJson<double?>(json['gpsLongitude']),
      gpsAccuracyMeters: serializer.fromJson<double?>(
        json['gpsAccuracyMeters'],
      ),
      gpsCapturedAtMs: serializer.fromJson<int?>(json['gpsCapturedAtMs']),
      pulseCount: serializer.fromJson<int>(json['pulseCount']),
      progressReferenceLiters: serializer.fromJson<double?>(
        json['progressReferenceLiters'],
      ),
      initialOdometerUnits: serializer.fromJson<double?>(
        json['initialOdometerUnits'],
      ),
      initialNeedleLiters: serializer.fromJson<double?>(
        json['initialNeedleLiters'],
      ),
      initialReadingSource: serializer.fromJson<String?>(
        json['initialReadingSource'],
      ),
      finalOdometerUnits: serializer.fromJson<double?>(
        json['finalOdometerUnits'],
      ),
      finalNeedleLiters: serializer.fromJson<double?>(
        json['finalNeedleLiters'],
      ),
      finalReadingSource: serializer.fromJson<String?>(
        json['finalReadingSource'],
      ),
      referenceLiters: serializer.fromJson<double?>(json['referenceLiters']),
      indicatedLiters: serializer.fromJson<double?>(json['indicatedLiters']),
      errorPct: serializer.fromJson<double?>(json['errorPct']),
      uncertaintyPct: serializer.fromJson<double?>(json['uncertaintyPct']),
      resultMpePct: serializer.fromJson<double?>(json['resultMpePct']),
      acceptanceMetricPct: serializer.fromJson<double?>(
        json['acceptanceMetricPct'],
      ),
      rejectionMetricPct: serializer.fromJson<double?>(
        json['rejectionMetricPct'],
      ),
      verdict: serializer.fromJson<String?>(json['verdict']),
      checksum: serializer.fromJson<String?>(json['checksum']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'flowPointId': serializer.toJson<String>(flowPointId),
      'sampleNumber': serializer.toJson<int>(sampleNumber),
      'status': serializer.toJson<String>(status),
      'measurementMethod': serializer.toJson<String>(measurementMethod),
      'litersPerPulse': serializer.toJson<double>(litersPerPulse),
      'evidenceStepLiters': serializer.toJson<double>(evidenceStepLiters),
      'readingUncertaintyLiters': serializer.toJson<double>(
        readingUncertaintyLiters,
      ),
      'flowPointCode': serializer.toJson<String>(flowPointCode),
      'mpePct': serializer.toJson<double>(mpePct),
      'lpsApprox': serializer.toJson<double?>(lpsApprox),
      'litersPerOdometerUnit': serializer.toJson<double>(litersPerOdometerUnit),
      'needleLitersPerRevolution': serializer.toJson<double>(
        needleLitersPerRevolution,
      ),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'startedAtMs': serializer.toJson<int?>(startedAtMs),
      'endedAtMs': serializer.toJson<int?>(endedAtMs),
      'gpsLatitude': serializer.toJson<double?>(gpsLatitude),
      'gpsLongitude': serializer.toJson<double?>(gpsLongitude),
      'gpsAccuracyMeters': serializer.toJson<double?>(gpsAccuracyMeters),
      'gpsCapturedAtMs': serializer.toJson<int?>(gpsCapturedAtMs),
      'pulseCount': serializer.toJson<int>(pulseCount),
      'progressReferenceLiters': serializer.toJson<double?>(
        progressReferenceLiters,
      ),
      'initialOdometerUnits': serializer.toJson<double?>(initialOdometerUnits),
      'initialNeedleLiters': serializer.toJson<double?>(initialNeedleLiters),
      'initialReadingSource': serializer.toJson<String?>(initialReadingSource),
      'finalOdometerUnits': serializer.toJson<double?>(finalOdometerUnits),
      'finalNeedleLiters': serializer.toJson<double?>(finalNeedleLiters),
      'finalReadingSource': serializer.toJson<String?>(finalReadingSource),
      'referenceLiters': serializer.toJson<double?>(referenceLiters),
      'indicatedLiters': serializer.toJson<double?>(indicatedLiters),
      'errorPct': serializer.toJson<double?>(errorPct),
      'uncertaintyPct': serializer.toJson<double?>(uncertaintyPct),
      'resultMpePct': serializer.toJson<double?>(resultMpePct),
      'acceptanceMetricPct': serializer.toJson<double?>(acceptanceMetricPct),
      'rejectionMetricPct': serializer.toJson<double?>(rejectionMetricPct),
      'verdict': serializer.toJson<String?>(verdict),
      'checksum': serializer.toJson<String?>(checksum),
    };
  }

  SampleRow copyWith({
    String? id,
    String? flowPointId,
    int? sampleNumber,
    String? status,
    String? measurementMethod,
    double? litersPerPulse,
    double? evidenceStepLiters,
    double? readingUncertaintyLiters,
    String? flowPointCode,
    double? mpePct,
    Value<double?> lpsApprox = const Value.absent(),
    double? litersPerOdometerUnit,
    double? needleLitersPerRevolution,
    int? createdAtMs,
    int? updatedAtMs,
    Value<int?> startedAtMs = const Value.absent(),
    Value<int?> endedAtMs = const Value.absent(),
    Value<double?> gpsLatitude = const Value.absent(),
    Value<double?> gpsLongitude = const Value.absent(),
    Value<double?> gpsAccuracyMeters = const Value.absent(),
    Value<int?> gpsCapturedAtMs = const Value.absent(),
    int? pulseCount,
    Value<double?> progressReferenceLiters = const Value.absent(),
    Value<double?> initialOdometerUnits = const Value.absent(),
    Value<double?> initialNeedleLiters = const Value.absent(),
    Value<String?> initialReadingSource = const Value.absent(),
    Value<double?> finalOdometerUnits = const Value.absent(),
    Value<double?> finalNeedleLiters = const Value.absent(),
    Value<String?> finalReadingSource = const Value.absent(),
    Value<double?> referenceLiters = const Value.absent(),
    Value<double?> indicatedLiters = const Value.absent(),
    Value<double?> errorPct = const Value.absent(),
    Value<double?> uncertaintyPct = const Value.absent(),
    Value<double?> resultMpePct = const Value.absent(),
    Value<double?> acceptanceMetricPct = const Value.absent(),
    Value<double?> rejectionMetricPct = const Value.absent(),
    Value<String?> verdict = const Value.absent(),
    Value<String?> checksum = const Value.absent(),
  }) => SampleRow(
    id: id ?? this.id,
    flowPointId: flowPointId ?? this.flowPointId,
    sampleNumber: sampleNumber ?? this.sampleNumber,
    status: status ?? this.status,
    measurementMethod: measurementMethod ?? this.measurementMethod,
    litersPerPulse: litersPerPulse ?? this.litersPerPulse,
    evidenceStepLiters: evidenceStepLiters ?? this.evidenceStepLiters,
    readingUncertaintyLiters:
        readingUncertaintyLiters ?? this.readingUncertaintyLiters,
    flowPointCode: flowPointCode ?? this.flowPointCode,
    mpePct: mpePct ?? this.mpePct,
    lpsApprox: lpsApprox.present ? lpsApprox.value : this.lpsApprox,
    litersPerOdometerUnit: litersPerOdometerUnit ?? this.litersPerOdometerUnit,
    needleLitersPerRevolution:
        needleLitersPerRevolution ?? this.needleLitersPerRevolution,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    startedAtMs: startedAtMs.present ? startedAtMs.value : this.startedAtMs,
    endedAtMs: endedAtMs.present ? endedAtMs.value : this.endedAtMs,
    gpsLatitude: gpsLatitude.present ? gpsLatitude.value : this.gpsLatitude,
    gpsLongitude: gpsLongitude.present ? gpsLongitude.value : this.gpsLongitude,
    gpsAccuracyMeters: gpsAccuracyMeters.present
        ? gpsAccuracyMeters.value
        : this.gpsAccuracyMeters,
    gpsCapturedAtMs: gpsCapturedAtMs.present
        ? gpsCapturedAtMs.value
        : this.gpsCapturedAtMs,
    pulseCount: pulseCount ?? this.pulseCount,
    progressReferenceLiters: progressReferenceLiters.present
        ? progressReferenceLiters.value
        : this.progressReferenceLiters,
    initialOdometerUnits: initialOdometerUnits.present
        ? initialOdometerUnits.value
        : this.initialOdometerUnits,
    initialNeedleLiters: initialNeedleLiters.present
        ? initialNeedleLiters.value
        : this.initialNeedleLiters,
    initialReadingSource: initialReadingSource.present
        ? initialReadingSource.value
        : this.initialReadingSource,
    finalOdometerUnits: finalOdometerUnits.present
        ? finalOdometerUnits.value
        : this.finalOdometerUnits,
    finalNeedleLiters: finalNeedleLiters.present
        ? finalNeedleLiters.value
        : this.finalNeedleLiters,
    finalReadingSource: finalReadingSource.present
        ? finalReadingSource.value
        : this.finalReadingSource,
    referenceLiters: referenceLiters.present
        ? referenceLiters.value
        : this.referenceLiters,
    indicatedLiters: indicatedLiters.present
        ? indicatedLiters.value
        : this.indicatedLiters,
    errorPct: errorPct.present ? errorPct.value : this.errorPct,
    uncertaintyPct: uncertaintyPct.present
        ? uncertaintyPct.value
        : this.uncertaintyPct,
    resultMpePct: resultMpePct.present ? resultMpePct.value : this.resultMpePct,
    acceptanceMetricPct: acceptanceMetricPct.present
        ? acceptanceMetricPct.value
        : this.acceptanceMetricPct,
    rejectionMetricPct: rejectionMetricPct.present
        ? rejectionMetricPct.value
        : this.rejectionMetricPct,
    verdict: verdict.present ? verdict.value : this.verdict,
    checksum: checksum.present ? checksum.value : this.checksum,
  );
  SampleRow copyWithCompanion(SamplesCompanion data) {
    return SampleRow(
      id: data.id.present ? data.id.value : this.id,
      flowPointId: data.flowPointId.present
          ? data.flowPointId.value
          : this.flowPointId,
      sampleNumber: data.sampleNumber.present
          ? data.sampleNumber.value
          : this.sampleNumber,
      status: data.status.present ? data.status.value : this.status,
      measurementMethod: data.measurementMethod.present
          ? data.measurementMethod.value
          : this.measurementMethod,
      litersPerPulse: data.litersPerPulse.present
          ? data.litersPerPulse.value
          : this.litersPerPulse,
      evidenceStepLiters: data.evidenceStepLiters.present
          ? data.evidenceStepLiters.value
          : this.evidenceStepLiters,
      readingUncertaintyLiters: data.readingUncertaintyLiters.present
          ? data.readingUncertaintyLiters.value
          : this.readingUncertaintyLiters,
      flowPointCode: data.flowPointCode.present
          ? data.flowPointCode.value
          : this.flowPointCode,
      mpePct: data.mpePct.present ? data.mpePct.value : this.mpePct,
      lpsApprox: data.lpsApprox.present ? data.lpsApprox.value : this.lpsApprox,
      litersPerOdometerUnit: data.litersPerOdometerUnit.present
          ? data.litersPerOdometerUnit.value
          : this.litersPerOdometerUnit,
      needleLitersPerRevolution: data.needleLitersPerRevolution.present
          ? data.needleLitersPerRevolution.value
          : this.needleLitersPerRevolution,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      startedAtMs: data.startedAtMs.present
          ? data.startedAtMs.value
          : this.startedAtMs,
      endedAtMs: data.endedAtMs.present ? data.endedAtMs.value : this.endedAtMs,
      gpsLatitude: data.gpsLatitude.present
          ? data.gpsLatitude.value
          : this.gpsLatitude,
      gpsLongitude: data.gpsLongitude.present
          ? data.gpsLongitude.value
          : this.gpsLongitude,
      gpsAccuracyMeters: data.gpsAccuracyMeters.present
          ? data.gpsAccuracyMeters.value
          : this.gpsAccuracyMeters,
      gpsCapturedAtMs: data.gpsCapturedAtMs.present
          ? data.gpsCapturedAtMs.value
          : this.gpsCapturedAtMs,
      pulseCount: data.pulseCount.present
          ? data.pulseCount.value
          : this.pulseCount,
      progressReferenceLiters: data.progressReferenceLiters.present
          ? data.progressReferenceLiters.value
          : this.progressReferenceLiters,
      initialOdometerUnits: data.initialOdometerUnits.present
          ? data.initialOdometerUnits.value
          : this.initialOdometerUnits,
      initialNeedleLiters: data.initialNeedleLiters.present
          ? data.initialNeedleLiters.value
          : this.initialNeedleLiters,
      initialReadingSource: data.initialReadingSource.present
          ? data.initialReadingSource.value
          : this.initialReadingSource,
      finalOdometerUnits: data.finalOdometerUnits.present
          ? data.finalOdometerUnits.value
          : this.finalOdometerUnits,
      finalNeedleLiters: data.finalNeedleLiters.present
          ? data.finalNeedleLiters.value
          : this.finalNeedleLiters,
      finalReadingSource: data.finalReadingSource.present
          ? data.finalReadingSource.value
          : this.finalReadingSource,
      referenceLiters: data.referenceLiters.present
          ? data.referenceLiters.value
          : this.referenceLiters,
      indicatedLiters: data.indicatedLiters.present
          ? data.indicatedLiters.value
          : this.indicatedLiters,
      errorPct: data.errorPct.present ? data.errorPct.value : this.errorPct,
      uncertaintyPct: data.uncertaintyPct.present
          ? data.uncertaintyPct.value
          : this.uncertaintyPct,
      resultMpePct: data.resultMpePct.present
          ? data.resultMpePct.value
          : this.resultMpePct,
      acceptanceMetricPct: data.acceptanceMetricPct.present
          ? data.acceptanceMetricPct.value
          : this.acceptanceMetricPct,
      rejectionMetricPct: data.rejectionMetricPct.present
          ? data.rejectionMetricPct.value
          : this.rejectionMetricPct,
      verdict: data.verdict.present ? data.verdict.value : this.verdict,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SampleRow(')
          ..write('id: $id, ')
          ..write('flowPointId: $flowPointId, ')
          ..write('sampleNumber: $sampleNumber, ')
          ..write('status: $status, ')
          ..write('measurementMethod: $measurementMethod, ')
          ..write('litersPerPulse: $litersPerPulse, ')
          ..write('evidenceStepLiters: $evidenceStepLiters, ')
          ..write('readingUncertaintyLiters: $readingUncertaintyLiters, ')
          ..write('flowPointCode: $flowPointCode, ')
          ..write('mpePct: $mpePct, ')
          ..write('lpsApprox: $lpsApprox, ')
          ..write('litersPerOdometerUnit: $litersPerOdometerUnit, ')
          ..write('needleLitersPerRevolution: $needleLitersPerRevolution, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('endedAtMs: $endedAtMs, ')
          ..write('gpsLatitude: $gpsLatitude, ')
          ..write('gpsLongitude: $gpsLongitude, ')
          ..write('gpsAccuracyMeters: $gpsAccuracyMeters, ')
          ..write('gpsCapturedAtMs: $gpsCapturedAtMs, ')
          ..write('pulseCount: $pulseCount, ')
          ..write('progressReferenceLiters: $progressReferenceLiters, ')
          ..write('initialOdometerUnits: $initialOdometerUnits, ')
          ..write('initialNeedleLiters: $initialNeedleLiters, ')
          ..write('initialReadingSource: $initialReadingSource, ')
          ..write('finalOdometerUnits: $finalOdometerUnits, ')
          ..write('finalNeedleLiters: $finalNeedleLiters, ')
          ..write('finalReadingSource: $finalReadingSource, ')
          ..write('referenceLiters: $referenceLiters, ')
          ..write('indicatedLiters: $indicatedLiters, ')
          ..write('errorPct: $errorPct, ')
          ..write('uncertaintyPct: $uncertaintyPct, ')
          ..write('resultMpePct: $resultMpePct, ')
          ..write('acceptanceMetricPct: $acceptanceMetricPct, ')
          ..write('rejectionMetricPct: $rejectionMetricPct, ')
          ..write('verdict: $verdict, ')
          ..write('checksum: $checksum')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    flowPointId,
    sampleNumber,
    status,
    measurementMethod,
    litersPerPulse,
    evidenceStepLiters,
    readingUncertaintyLiters,
    flowPointCode,
    mpePct,
    lpsApprox,
    litersPerOdometerUnit,
    needleLitersPerRevolution,
    createdAtMs,
    updatedAtMs,
    startedAtMs,
    endedAtMs,
    gpsLatitude,
    gpsLongitude,
    gpsAccuracyMeters,
    gpsCapturedAtMs,
    pulseCount,
    progressReferenceLiters,
    initialOdometerUnits,
    initialNeedleLiters,
    initialReadingSource,
    finalOdometerUnits,
    finalNeedleLiters,
    finalReadingSource,
    referenceLiters,
    indicatedLiters,
    errorPct,
    uncertaintyPct,
    resultMpePct,
    acceptanceMetricPct,
    rejectionMetricPct,
    verdict,
    checksum,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SampleRow &&
          other.id == this.id &&
          other.flowPointId == this.flowPointId &&
          other.sampleNumber == this.sampleNumber &&
          other.status == this.status &&
          other.measurementMethod == this.measurementMethod &&
          other.litersPerPulse == this.litersPerPulse &&
          other.evidenceStepLiters == this.evidenceStepLiters &&
          other.readingUncertaintyLiters == this.readingUncertaintyLiters &&
          other.flowPointCode == this.flowPointCode &&
          other.mpePct == this.mpePct &&
          other.lpsApprox == this.lpsApprox &&
          other.litersPerOdometerUnit == this.litersPerOdometerUnit &&
          other.needleLitersPerRevolution == this.needleLitersPerRevolution &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.startedAtMs == this.startedAtMs &&
          other.endedAtMs == this.endedAtMs &&
          other.gpsLatitude == this.gpsLatitude &&
          other.gpsLongitude == this.gpsLongitude &&
          other.gpsAccuracyMeters == this.gpsAccuracyMeters &&
          other.gpsCapturedAtMs == this.gpsCapturedAtMs &&
          other.pulseCount == this.pulseCount &&
          other.progressReferenceLiters == this.progressReferenceLiters &&
          other.initialOdometerUnits == this.initialOdometerUnits &&
          other.initialNeedleLiters == this.initialNeedleLiters &&
          other.initialReadingSource == this.initialReadingSource &&
          other.finalOdometerUnits == this.finalOdometerUnits &&
          other.finalNeedleLiters == this.finalNeedleLiters &&
          other.finalReadingSource == this.finalReadingSource &&
          other.referenceLiters == this.referenceLiters &&
          other.indicatedLiters == this.indicatedLiters &&
          other.errorPct == this.errorPct &&
          other.uncertaintyPct == this.uncertaintyPct &&
          other.resultMpePct == this.resultMpePct &&
          other.acceptanceMetricPct == this.acceptanceMetricPct &&
          other.rejectionMetricPct == this.rejectionMetricPct &&
          other.verdict == this.verdict &&
          other.checksum == this.checksum);
}

class SamplesCompanion extends UpdateCompanion<SampleRow> {
  final Value<String> id;
  final Value<String> flowPointId;
  final Value<int> sampleNumber;
  final Value<String> status;
  final Value<String> measurementMethod;
  final Value<double> litersPerPulse;
  final Value<double> evidenceStepLiters;
  final Value<double> readingUncertaintyLiters;
  final Value<String> flowPointCode;
  final Value<double> mpePct;
  final Value<double?> lpsApprox;
  final Value<double> litersPerOdometerUnit;
  final Value<double> needleLitersPerRevolution;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int?> startedAtMs;
  final Value<int?> endedAtMs;
  final Value<double?> gpsLatitude;
  final Value<double?> gpsLongitude;
  final Value<double?> gpsAccuracyMeters;
  final Value<int?> gpsCapturedAtMs;
  final Value<int> pulseCount;
  final Value<double?> progressReferenceLiters;
  final Value<double?> initialOdometerUnits;
  final Value<double?> initialNeedleLiters;
  final Value<String?> initialReadingSource;
  final Value<double?> finalOdometerUnits;
  final Value<double?> finalNeedleLiters;
  final Value<String?> finalReadingSource;
  final Value<double?> referenceLiters;
  final Value<double?> indicatedLiters;
  final Value<double?> errorPct;
  final Value<double?> uncertaintyPct;
  final Value<double?> resultMpePct;
  final Value<double?> acceptanceMetricPct;
  final Value<double?> rejectionMetricPct;
  final Value<String?> verdict;
  final Value<String?> checksum;
  final Value<int> rowid;
  const SamplesCompanion({
    this.id = const Value.absent(),
    this.flowPointId = const Value.absent(),
    this.sampleNumber = const Value.absent(),
    this.status = const Value.absent(),
    this.measurementMethod = const Value.absent(),
    this.litersPerPulse = const Value.absent(),
    this.evidenceStepLiters = const Value.absent(),
    this.readingUncertaintyLiters = const Value.absent(),
    this.flowPointCode = const Value.absent(),
    this.mpePct = const Value.absent(),
    this.lpsApprox = const Value.absent(),
    this.litersPerOdometerUnit = const Value.absent(),
    this.needleLitersPerRevolution = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.startedAtMs = const Value.absent(),
    this.endedAtMs = const Value.absent(),
    this.gpsLatitude = const Value.absent(),
    this.gpsLongitude = const Value.absent(),
    this.gpsAccuracyMeters = const Value.absent(),
    this.gpsCapturedAtMs = const Value.absent(),
    this.pulseCount = const Value.absent(),
    this.progressReferenceLiters = const Value.absent(),
    this.initialOdometerUnits = const Value.absent(),
    this.initialNeedleLiters = const Value.absent(),
    this.initialReadingSource = const Value.absent(),
    this.finalOdometerUnits = const Value.absent(),
    this.finalNeedleLiters = const Value.absent(),
    this.finalReadingSource = const Value.absent(),
    this.referenceLiters = const Value.absent(),
    this.indicatedLiters = const Value.absent(),
    this.errorPct = const Value.absent(),
    this.uncertaintyPct = const Value.absent(),
    this.resultMpePct = const Value.absent(),
    this.acceptanceMetricPct = const Value.absent(),
    this.rejectionMetricPct = const Value.absent(),
    this.verdict = const Value.absent(),
    this.checksum = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SamplesCompanion.insert({
    required String id,
    required String flowPointId,
    required int sampleNumber,
    required String status,
    required String measurementMethod,
    required double litersPerPulse,
    required double evidenceStepLiters,
    required double readingUncertaintyLiters,
    required String flowPointCode,
    required double mpePct,
    this.lpsApprox = const Value.absent(),
    required double litersPerOdometerUnit,
    required double needleLitersPerRevolution,
    required int createdAtMs,
    required int updatedAtMs,
    this.startedAtMs = const Value.absent(),
    this.endedAtMs = const Value.absent(),
    this.gpsLatitude = const Value.absent(),
    this.gpsLongitude = const Value.absent(),
    this.gpsAccuracyMeters = const Value.absent(),
    this.gpsCapturedAtMs = const Value.absent(),
    this.pulseCount = const Value.absent(),
    this.progressReferenceLiters = const Value.absent(),
    this.initialOdometerUnits = const Value.absent(),
    this.initialNeedleLiters = const Value.absent(),
    this.initialReadingSource = const Value.absent(),
    this.finalOdometerUnits = const Value.absent(),
    this.finalNeedleLiters = const Value.absent(),
    this.finalReadingSource = const Value.absent(),
    this.referenceLiters = const Value.absent(),
    this.indicatedLiters = const Value.absent(),
    this.errorPct = const Value.absent(),
    this.uncertaintyPct = const Value.absent(),
    this.resultMpePct = const Value.absent(),
    this.acceptanceMetricPct = const Value.absent(),
    this.rejectionMetricPct = const Value.absent(),
    this.verdict = const Value.absent(),
    this.checksum = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       flowPointId = Value(flowPointId),
       sampleNumber = Value(sampleNumber),
       status = Value(status),
       measurementMethod = Value(measurementMethod),
       litersPerPulse = Value(litersPerPulse),
       evidenceStepLiters = Value(evidenceStepLiters),
       readingUncertaintyLiters = Value(readingUncertaintyLiters),
       flowPointCode = Value(flowPointCode),
       mpePct = Value(mpePct),
       litersPerOdometerUnit = Value(litersPerOdometerUnit),
       needleLitersPerRevolution = Value(needleLitersPerRevolution),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<SampleRow> custom({
    Expression<String>? id,
    Expression<String>? flowPointId,
    Expression<int>? sampleNumber,
    Expression<String>? status,
    Expression<String>? measurementMethod,
    Expression<double>? litersPerPulse,
    Expression<double>? evidenceStepLiters,
    Expression<double>? readingUncertaintyLiters,
    Expression<String>? flowPointCode,
    Expression<double>? mpePct,
    Expression<double>? lpsApprox,
    Expression<double>? litersPerOdometerUnit,
    Expression<double>? needleLitersPerRevolution,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? startedAtMs,
    Expression<int>? endedAtMs,
    Expression<double>? gpsLatitude,
    Expression<double>? gpsLongitude,
    Expression<double>? gpsAccuracyMeters,
    Expression<int>? gpsCapturedAtMs,
    Expression<int>? pulseCount,
    Expression<double>? progressReferenceLiters,
    Expression<double>? initialOdometerUnits,
    Expression<double>? initialNeedleLiters,
    Expression<String>? initialReadingSource,
    Expression<double>? finalOdometerUnits,
    Expression<double>? finalNeedleLiters,
    Expression<String>? finalReadingSource,
    Expression<double>? referenceLiters,
    Expression<double>? indicatedLiters,
    Expression<double>? errorPct,
    Expression<double>? uncertaintyPct,
    Expression<double>? resultMpePct,
    Expression<double>? acceptanceMetricPct,
    Expression<double>? rejectionMetricPct,
    Expression<String>? verdict,
    Expression<String>? checksum,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (flowPointId != null) 'flow_point_id': flowPointId,
      if (sampleNumber != null) 'sample_number': sampleNumber,
      if (status != null) 'status': status,
      if (measurementMethod != null) 'measurement_method': measurementMethod,
      if (litersPerPulse != null) 'liters_per_pulse': litersPerPulse,
      if (evidenceStepLiters != null)
        'evidence_step_liters': evidenceStepLiters,
      if (readingUncertaintyLiters != null)
        'reading_uncertainty_liters': readingUncertaintyLiters,
      if (flowPointCode != null) 'flow_point_code': flowPointCode,
      if (mpePct != null) 'mpe_pct': mpePct,
      if (lpsApprox != null) 'lps_approx': lpsApprox,
      if (litersPerOdometerUnit != null)
        'liters_per_odometer_unit': litersPerOdometerUnit,
      if (needleLitersPerRevolution != null)
        'needle_liters_per_revolution': needleLitersPerRevolution,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (startedAtMs != null) 'started_at_ms': startedAtMs,
      if (endedAtMs != null) 'ended_at_ms': endedAtMs,
      if (gpsLatitude != null) 'gps_latitude': gpsLatitude,
      if (gpsLongitude != null) 'gps_longitude': gpsLongitude,
      if (gpsAccuracyMeters != null) 'gps_accuracy_meters': gpsAccuracyMeters,
      if (gpsCapturedAtMs != null) 'gps_captured_at_ms': gpsCapturedAtMs,
      if (pulseCount != null) 'pulse_count': pulseCount,
      if (progressReferenceLiters != null)
        'progress_reference_liters': progressReferenceLiters,
      if (initialOdometerUnits != null)
        'initial_odometer_units': initialOdometerUnits,
      if (initialNeedleLiters != null)
        'initial_needle_liters': initialNeedleLiters,
      if (initialReadingSource != null)
        'initial_reading_source': initialReadingSource,
      if (finalOdometerUnits != null)
        'final_odometer_units': finalOdometerUnits,
      if (finalNeedleLiters != null) 'final_needle_liters': finalNeedleLiters,
      if (finalReadingSource != null)
        'final_reading_source': finalReadingSource,
      if (referenceLiters != null) 'reference_liters': referenceLiters,
      if (indicatedLiters != null) 'indicated_liters': indicatedLiters,
      if (errorPct != null) 'error_pct': errorPct,
      if (uncertaintyPct != null) 'uncertainty_pct': uncertaintyPct,
      if (resultMpePct != null) 'result_mpe_pct': resultMpePct,
      if (acceptanceMetricPct != null)
        'acceptance_metric_pct': acceptanceMetricPct,
      if (rejectionMetricPct != null)
        'rejection_metric_pct': rejectionMetricPct,
      if (verdict != null) 'verdict': verdict,
      if (checksum != null) 'checksum': checksum,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SamplesCompanion copyWith({
    Value<String>? id,
    Value<String>? flowPointId,
    Value<int>? sampleNumber,
    Value<String>? status,
    Value<String>? measurementMethod,
    Value<double>? litersPerPulse,
    Value<double>? evidenceStepLiters,
    Value<double>? readingUncertaintyLiters,
    Value<String>? flowPointCode,
    Value<double>? mpePct,
    Value<double?>? lpsApprox,
    Value<double>? litersPerOdometerUnit,
    Value<double>? needleLitersPerRevolution,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int?>? startedAtMs,
    Value<int?>? endedAtMs,
    Value<double?>? gpsLatitude,
    Value<double?>? gpsLongitude,
    Value<double?>? gpsAccuracyMeters,
    Value<int?>? gpsCapturedAtMs,
    Value<int>? pulseCount,
    Value<double?>? progressReferenceLiters,
    Value<double?>? initialOdometerUnits,
    Value<double?>? initialNeedleLiters,
    Value<String?>? initialReadingSource,
    Value<double?>? finalOdometerUnits,
    Value<double?>? finalNeedleLiters,
    Value<String?>? finalReadingSource,
    Value<double?>? referenceLiters,
    Value<double?>? indicatedLiters,
    Value<double?>? errorPct,
    Value<double?>? uncertaintyPct,
    Value<double?>? resultMpePct,
    Value<double?>? acceptanceMetricPct,
    Value<double?>? rejectionMetricPct,
    Value<String?>? verdict,
    Value<String?>? checksum,
    Value<int>? rowid,
  }) {
    return SamplesCompanion(
      id: id ?? this.id,
      flowPointId: flowPointId ?? this.flowPointId,
      sampleNumber: sampleNumber ?? this.sampleNumber,
      status: status ?? this.status,
      measurementMethod: measurementMethod ?? this.measurementMethod,
      litersPerPulse: litersPerPulse ?? this.litersPerPulse,
      evidenceStepLiters: evidenceStepLiters ?? this.evidenceStepLiters,
      readingUncertaintyLiters:
          readingUncertaintyLiters ?? this.readingUncertaintyLiters,
      flowPointCode: flowPointCode ?? this.flowPointCode,
      mpePct: mpePct ?? this.mpePct,
      lpsApprox: lpsApprox ?? this.lpsApprox,
      litersPerOdometerUnit:
          litersPerOdometerUnit ?? this.litersPerOdometerUnit,
      needleLitersPerRevolution:
          needleLitersPerRevolution ?? this.needleLitersPerRevolution,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      startedAtMs: startedAtMs ?? this.startedAtMs,
      endedAtMs: endedAtMs ?? this.endedAtMs,
      gpsLatitude: gpsLatitude ?? this.gpsLatitude,
      gpsLongitude: gpsLongitude ?? this.gpsLongitude,
      gpsAccuracyMeters: gpsAccuracyMeters ?? this.gpsAccuracyMeters,
      gpsCapturedAtMs: gpsCapturedAtMs ?? this.gpsCapturedAtMs,
      pulseCount: pulseCount ?? this.pulseCount,
      progressReferenceLiters:
          progressReferenceLiters ?? this.progressReferenceLiters,
      initialOdometerUnits: initialOdometerUnits ?? this.initialOdometerUnits,
      initialNeedleLiters: initialNeedleLiters ?? this.initialNeedleLiters,
      initialReadingSource: initialReadingSource ?? this.initialReadingSource,
      finalOdometerUnits: finalOdometerUnits ?? this.finalOdometerUnits,
      finalNeedleLiters: finalNeedleLiters ?? this.finalNeedleLiters,
      finalReadingSource: finalReadingSource ?? this.finalReadingSource,
      referenceLiters: referenceLiters ?? this.referenceLiters,
      indicatedLiters: indicatedLiters ?? this.indicatedLiters,
      errorPct: errorPct ?? this.errorPct,
      uncertaintyPct: uncertaintyPct ?? this.uncertaintyPct,
      resultMpePct: resultMpePct ?? this.resultMpePct,
      acceptanceMetricPct: acceptanceMetricPct ?? this.acceptanceMetricPct,
      rejectionMetricPct: rejectionMetricPct ?? this.rejectionMetricPct,
      verdict: verdict ?? this.verdict,
      checksum: checksum ?? this.checksum,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (flowPointId.present) {
      map['flow_point_id'] = Variable<String>(flowPointId.value);
    }
    if (sampleNumber.present) {
      map['sample_number'] = Variable<int>(sampleNumber.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (measurementMethod.present) {
      map['measurement_method'] = Variable<String>(measurementMethod.value);
    }
    if (litersPerPulse.present) {
      map['liters_per_pulse'] = Variable<double>(litersPerPulse.value);
    }
    if (evidenceStepLiters.present) {
      map['evidence_step_liters'] = Variable<double>(evidenceStepLiters.value);
    }
    if (readingUncertaintyLiters.present) {
      map['reading_uncertainty_liters'] = Variable<double>(
        readingUncertaintyLiters.value,
      );
    }
    if (flowPointCode.present) {
      map['flow_point_code'] = Variable<String>(flowPointCode.value);
    }
    if (mpePct.present) {
      map['mpe_pct'] = Variable<double>(mpePct.value);
    }
    if (lpsApprox.present) {
      map['lps_approx'] = Variable<double>(lpsApprox.value);
    }
    if (litersPerOdometerUnit.present) {
      map['liters_per_odometer_unit'] = Variable<double>(
        litersPerOdometerUnit.value,
      );
    }
    if (needleLitersPerRevolution.present) {
      map['needle_liters_per_revolution'] = Variable<double>(
        needleLitersPerRevolution.value,
      );
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (startedAtMs.present) {
      map['started_at_ms'] = Variable<int>(startedAtMs.value);
    }
    if (endedAtMs.present) {
      map['ended_at_ms'] = Variable<int>(endedAtMs.value);
    }
    if (gpsLatitude.present) {
      map['gps_latitude'] = Variable<double>(gpsLatitude.value);
    }
    if (gpsLongitude.present) {
      map['gps_longitude'] = Variable<double>(gpsLongitude.value);
    }
    if (gpsAccuracyMeters.present) {
      map['gps_accuracy_meters'] = Variable<double>(gpsAccuracyMeters.value);
    }
    if (gpsCapturedAtMs.present) {
      map['gps_captured_at_ms'] = Variable<int>(gpsCapturedAtMs.value);
    }
    if (pulseCount.present) {
      map['pulse_count'] = Variable<int>(pulseCount.value);
    }
    if (progressReferenceLiters.present) {
      map['progress_reference_liters'] = Variable<double>(
        progressReferenceLiters.value,
      );
    }
    if (initialOdometerUnits.present) {
      map['initial_odometer_units'] = Variable<double>(
        initialOdometerUnits.value,
      );
    }
    if (initialNeedleLiters.present) {
      map['initial_needle_liters'] = Variable<double>(
        initialNeedleLiters.value,
      );
    }
    if (initialReadingSource.present) {
      map['initial_reading_source'] = Variable<String>(
        initialReadingSource.value,
      );
    }
    if (finalOdometerUnits.present) {
      map['final_odometer_units'] = Variable<double>(finalOdometerUnits.value);
    }
    if (finalNeedleLiters.present) {
      map['final_needle_liters'] = Variable<double>(finalNeedleLiters.value);
    }
    if (finalReadingSource.present) {
      map['final_reading_source'] = Variable<String>(finalReadingSource.value);
    }
    if (referenceLiters.present) {
      map['reference_liters'] = Variable<double>(referenceLiters.value);
    }
    if (indicatedLiters.present) {
      map['indicated_liters'] = Variable<double>(indicatedLiters.value);
    }
    if (errorPct.present) {
      map['error_pct'] = Variable<double>(errorPct.value);
    }
    if (uncertaintyPct.present) {
      map['uncertainty_pct'] = Variable<double>(uncertaintyPct.value);
    }
    if (resultMpePct.present) {
      map['result_mpe_pct'] = Variable<double>(resultMpePct.value);
    }
    if (acceptanceMetricPct.present) {
      map['acceptance_metric_pct'] = Variable<double>(
        acceptanceMetricPct.value,
      );
    }
    if (rejectionMetricPct.present) {
      map['rejection_metric_pct'] = Variable<double>(rejectionMetricPct.value);
    }
    if (verdict.present) {
      map['verdict'] = Variable<String>(verdict.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SamplesCompanion(')
          ..write('id: $id, ')
          ..write('flowPointId: $flowPointId, ')
          ..write('sampleNumber: $sampleNumber, ')
          ..write('status: $status, ')
          ..write('measurementMethod: $measurementMethod, ')
          ..write('litersPerPulse: $litersPerPulse, ')
          ..write('evidenceStepLiters: $evidenceStepLiters, ')
          ..write('readingUncertaintyLiters: $readingUncertaintyLiters, ')
          ..write('flowPointCode: $flowPointCode, ')
          ..write('mpePct: $mpePct, ')
          ..write('lpsApprox: $lpsApprox, ')
          ..write('litersPerOdometerUnit: $litersPerOdometerUnit, ')
          ..write('needleLitersPerRevolution: $needleLitersPerRevolution, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('endedAtMs: $endedAtMs, ')
          ..write('gpsLatitude: $gpsLatitude, ')
          ..write('gpsLongitude: $gpsLongitude, ')
          ..write('gpsAccuracyMeters: $gpsAccuracyMeters, ')
          ..write('gpsCapturedAtMs: $gpsCapturedAtMs, ')
          ..write('pulseCount: $pulseCount, ')
          ..write('progressReferenceLiters: $progressReferenceLiters, ')
          ..write('initialOdometerUnits: $initialOdometerUnits, ')
          ..write('initialNeedleLiters: $initialNeedleLiters, ')
          ..write('initialReadingSource: $initialReadingSource, ')
          ..write('finalOdometerUnits: $finalOdometerUnits, ')
          ..write('finalNeedleLiters: $finalNeedleLiters, ')
          ..write('finalReadingSource: $finalReadingSource, ')
          ..write('referenceLiters: $referenceLiters, ')
          ..write('indicatedLiters: $indicatedLiters, ')
          ..write('errorPct: $errorPct, ')
          ..write('uncertaintyPct: $uncertaintyPct, ')
          ..write('resultMpePct: $resultMpePct, ')
          ..write('acceptanceMetricPct: $acceptanceMetricPct, ')
          ..write('rejectionMetricPct: $rejectionMetricPct, ')
          ..write('verdict: $verdict, ')
          ..write('checksum: $checksum, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TestPointsTable extends TestPoints
    with TableInfo<$TestPointsTable, PointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TestPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sampleIdMeta = const VerificationMeta(
    'sampleId',
  );
  @override
  late final GeneratedColumn<String> sampleId = GeneratedColumn<String>(
    'sample_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES samples (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pulseCountMeta = const VerificationMeta(
    'pulseCount',
  );
  @override
  late final GeneratedColumn<int> pulseCount = GeneratedColumn<int>(
    'pulse_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceLitersMeta = const VerificationMeta(
    'referenceLiters',
  );
  @override
  late final GeneratedColumn<double> referenceLiters = GeneratedColumn<double>(
    'reference_liters',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _readingLitersMeta = const VerificationMeta(
    'readingLiters',
  );
  @override
  late final GeneratedColumn<double> readingLiters = GeneratedColumn<double>(
    'reading_liters',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _indicatedLitersMeta = const VerificationMeta(
    'indicatedLiters',
  );
  @override
  late final GeneratedColumn<double> indicatedLiters = GeneratedColumn<double>(
    'indicated_liters',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diagnosticErrorPctMeta =
      const VerificationMeta('diagnosticErrorPct');
  @override
  late final GeneratedColumn<double> diagnosticErrorPct =
      GeneratedColumn<double>(
        'diagnostic_error_pct',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _needleLitersMeta = const VerificationMeta(
    'needleLiters',
  );
  @override
  late final GeneratedColumn<double> needleLiters = GeneratedColumn<double>(
    'needle_liters',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capturedAtMsMeta = const VerificationMeta(
    'capturedAtMs',
  );
  @override
  late final GeneratedColumn<int> capturedAtMs = GeneratedColumn<int>(
    'captured_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sampleId,
    type,
    pulseCount,
    referenceLiters,
    readingLiters,
    indicatedLiters,
    diagnosticErrorPct,
    needleLiters,
    capturedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'test_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<PointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sample_id')) {
      context.handle(
        _sampleIdMeta,
        sampleId.isAcceptableOrUnknown(data['sample_id']!, _sampleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sampleIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('pulse_count')) {
      context.handle(
        _pulseCountMeta,
        pulseCount.isAcceptableOrUnknown(data['pulse_count']!, _pulseCountMeta),
      );
    }
    if (data.containsKey('reference_liters')) {
      context.handle(
        _referenceLitersMeta,
        referenceLiters.isAcceptableOrUnknown(
          data['reference_liters']!,
          _referenceLitersMeta,
        ),
      );
    }
    if (data.containsKey('reading_liters')) {
      context.handle(
        _readingLitersMeta,
        readingLiters.isAcceptableOrUnknown(
          data['reading_liters']!,
          _readingLitersMeta,
        ),
      );
    }
    if (data.containsKey('indicated_liters')) {
      context.handle(
        _indicatedLitersMeta,
        indicatedLiters.isAcceptableOrUnknown(
          data['indicated_liters']!,
          _indicatedLitersMeta,
        ),
      );
    }
    if (data.containsKey('diagnostic_error_pct')) {
      context.handle(
        _diagnosticErrorPctMeta,
        diagnosticErrorPct.isAcceptableOrUnknown(
          data['diagnostic_error_pct']!,
          _diagnosticErrorPctMeta,
        ),
      );
    }
    if (data.containsKey('needle_liters')) {
      context.handle(
        _needleLitersMeta,
        needleLiters.isAcceptableOrUnknown(
          data['needle_liters']!,
          _needleLitersMeta,
        ),
      );
    }
    if (data.containsKey('captured_at_ms')) {
      context.handle(
        _capturedAtMsMeta,
        capturedAtMs.isAcceptableOrUnknown(
          data['captured_at_ms']!,
          _capturedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PointRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sampleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sample_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      pulseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pulse_count'],
      ),
      referenceLiters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reference_liters'],
      ),
      readingLiters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reading_liters'],
      ),
      indicatedLiters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}indicated_liters'],
      ),
      diagnosticErrorPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}diagnostic_error_pct'],
      ),
      needleLiters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}needle_liters'],
      ),
      capturedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}captured_at_ms'],
      )!,
    );
  }

  @override
  $TestPointsTable createAlias(String alias) {
    return $TestPointsTable(attachedDatabase, alias);
  }
}

class PointRow extends DataClass implements Insertable<PointRow> {
  final String id;
  final String sampleId;
  final String type;
  final int? pulseCount;
  final double? referenceLiters;
  final double? readingLiters;
  final double? indicatedLiters;
  final double? diagnosticErrorPct;
  final double? needleLiters;
  final int capturedAtMs;
  const PointRow({
    required this.id,
    required this.sampleId,
    required this.type,
    this.pulseCount,
    this.referenceLiters,
    this.readingLiters,
    this.indicatedLiters,
    this.diagnosticErrorPct,
    this.needleLiters,
    required this.capturedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sample_id'] = Variable<String>(sampleId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || pulseCount != null) {
      map['pulse_count'] = Variable<int>(pulseCount);
    }
    if (!nullToAbsent || referenceLiters != null) {
      map['reference_liters'] = Variable<double>(referenceLiters);
    }
    if (!nullToAbsent || readingLiters != null) {
      map['reading_liters'] = Variable<double>(readingLiters);
    }
    if (!nullToAbsent || indicatedLiters != null) {
      map['indicated_liters'] = Variable<double>(indicatedLiters);
    }
    if (!nullToAbsent || diagnosticErrorPct != null) {
      map['diagnostic_error_pct'] = Variable<double>(diagnosticErrorPct);
    }
    if (!nullToAbsent || needleLiters != null) {
      map['needle_liters'] = Variable<double>(needleLiters);
    }
    map['captured_at_ms'] = Variable<int>(capturedAtMs);
    return map;
  }

  TestPointsCompanion toCompanion(bool nullToAbsent) {
    return TestPointsCompanion(
      id: Value(id),
      sampleId: Value(sampleId),
      type: Value(type),
      pulseCount: pulseCount == null && nullToAbsent
          ? const Value.absent()
          : Value(pulseCount),
      referenceLiters: referenceLiters == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceLiters),
      readingLiters: readingLiters == null && nullToAbsent
          ? const Value.absent()
          : Value(readingLiters),
      indicatedLiters: indicatedLiters == null && nullToAbsent
          ? const Value.absent()
          : Value(indicatedLiters),
      diagnosticErrorPct: diagnosticErrorPct == null && nullToAbsent
          ? const Value.absent()
          : Value(diagnosticErrorPct),
      needleLiters: needleLiters == null && nullToAbsent
          ? const Value.absent()
          : Value(needleLiters),
      capturedAtMs: Value(capturedAtMs),
    );
  }

  factory PointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PointRow(
      id: serializer.fromJson<String>(json['id']),
      sampleId: serializer.fromJson<String>(json['sampleId']),
      type: serializer.fromJson<String>(json['type']),
      pulseCount: serializer.fromJson<int?>(json['pulseCount']),
      referenceLiters: serializer.fromJson<double?>(json['referenceLiters']),
      readingLiters: serializer.fromJson<double?>(json['readingLiters']),
      indicatedLiters: serializer.fromJson<double?>(json['indicatedLiters']),
      diagnosticErrorPct: serializer.fromJson<double?>(
        json['diagnosticErrorPct'],
      ),
      needleLiters: serializer.fromJson<double?>(json['needleLiters']),
      capturedAtMs: serializer.fromJson<int>(json['capturedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sampleId': serializer.toJson<String>(sampleId),
      'type': serializer.toJson<String>(type),
      'pulseCount': serializer.toJson<int?>(pulseCount),
      'referenceLiters': serializer.toJson<double?>(referenceLiters),
      'readingLiters': serializer.toJson<double?>(readingLiters),
      'indicatedLiters': serializer.toJson<double?>(indicatedLiters),
      'diagnosticErrorPct': serializer.toJson<double?>(diagnosticErrorPct),
      'needleLiters': serializer.toJson<double?>(needleLiters),
      'capturedAtMs': serializer.toJson<int>(capturedAtMs),
    };
  }

  PointRow copyWith({
    String? id,
    String? sampleId,
    String? type,
    Value<int?> pulseCount = const Value.absent(),
    Value<double?> referenceLiters = const Value.absent(),
    Value<double?> readingLiters = const Value.absent(),
    Value<double?> indicatedLiters = const Value.absent(),
    Value<double?> diagnosticErrorPct = const Value.absent(),
    Value<double?> needleLiters = const Value.absent(),
    int? capturedAtMs,
  }) => PointRow(
    id: id ?? this.id,
    sampleId: sampleId ?? this.sampleId,
    type: type ?? this.type,
    pulseCount: pulseCount.present ? pulseCount.value : this.pulseCount,
    referenceLiters: referenceLiters.present
        ? referenceLiters.value
        : this.referenceLiters,
    readingLiters: readingLiters.present
        ? readingLiters.value
        : this.readingLiters,
    indicatedLiters: indicatedLiters.present
        ? indicatedLiters.value
        : this.indicatedLiters,
    diagnosticErrorPct: diagnosticErrorPct.present
        ? diagnosticErrorPct.value
        : this.diagnosticErrorPct,
    needleLiters: needleLiters.present ? needleLiters.value : this.needleLiters,
    capturedAtMs: capturedAtMs ?? this.capturedAtMs,
  );
  PointRow copyWithCompanion(TestPointsCompanion data) {
    return PointRow(
      id: data.id.present ? data.id.value : this.id,
      sampleId: data.sampleId.present ? data.sampleId.value : this.sampleId,
      type: data.type.present ? data.type.value : this.type,
      pulseCount: data.pulseCount.present
          ? data.pulseCount.value
          : this.pulseCount,
      referenceLiters: data.referenceLiters.present
          ? data.referenceLiters.value
          : this.referenceLiters,
      readingLiters: data.readingLiters.present
          ? data.readingLiters.value
          : this.readingLiters,
      indicatedLiters: data.indicatedLiters.present
          ? data.indicatedLiters.value
          : this.indicatedLiters,
      diagnosticErrorPct: data.diagnosticErrorPct.present
          ? data.diagnosticErrorPct.value
          : this.diagnosticErrorPct,
      needleLiters: data.needleLiters.present
          ? data.needleLiters.value
          : this.needleLiters,
      capturedAtMs: data.capturedAtMs.present
          ? data.capturedAtMs.value
          : this.capturedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PointRow(')
          ..write('id: $id, ')
          ..write('sampleId: $sampleId, ')
          ..write('type: $type, ')
          ..write('pulseCount: $pulseCount, ')
          ..write('referenceLiters: $referenceLiters, ')
          ..write('readingLiters: $readingLiters, ')
          ..write('indicatedLiters: $indicatedLiters, ')
          ..write('diagnosticErrorPct: $diagnosticErrorPct, ')
          ..write('needleLiters: $needleLiters, ')
          ..write('capturedAtMs: $capturedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sampleId,
    type,
    pulseCount,
    referenceLiters,
    readingLiters,
    indicatedLiters,
    diagnosticErrorPct,
    needleLiters,
    capturedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PointRow &&
          other.id == this.id &&
          other.sampleId == this.sampleId &&
          other.type == this.type &&
          other.pulseCount == this.pulseCount &&
          other.referenceLiters == this.referenceLiters &&
          other.readingLiters == this.readingLiters &&
          other.indicatedLiters == this.indicatedLiters &&
          other.diagnosticErrorPct == this.diagnosticErrorPct &&
          other.needleLiters == this.needleLiters &&
          other.capturedAtMs == this.capturedAtMs);
}

class TestPointsCompanion extends UpdateCompanion<PointRow> {
  final Value<String> id;
  final Value<String> sampleId;
  final Value<String> type;
  final Value<int?> pulseCount;
  final Value<double?> referenceLiters;
  final Value<double?> readingLiters;
  final Value<double?> indicatedLiters;
  final Value<double?> diagnosticErrorPct;
  final Value<double?> needleLiters;
  final Value<int> capturedAtMs;
  final Value<int> rowid;
  const TestPointsCompanion({
    this.id = const Value.absent(),
    this.sampleId = const Value.absent(),
    this.type = const Value.absent(),
    this.pulseCount = const Value.absent(),
    this.referenceLiters = const Value.absent(),
    this.readingLiters = const Value.absent(),
    this.indicatedLiters = const Value.absent(),
    this.diagnosticErrorPct = const Value.absent(),
    this.needleLiters = const Value.absent(),
    this.capturedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TestPointsCompanion.insert({
    required String id,
    required String sampleId,
    required String type,
    this.pulseCount = const Value.absent(),
    this.referenceLiters = const Value.absent(),
    this.readingLiters = const Value.absent(),
    this.indicatedLiters = const Value.absent(),
    this.diagnosticErrorPct = const Value.absent(),
    this.needleLiters = const Value.absent(),
    required int capturedAtMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sampleId = Value(sampleId),
       type = Value(type),
       capturedAtMs = Value(capturedAtMs);
  static Insertable<PointRow> custom({
    Expression<String>? id,
    Expression<String>? sampleId,
    Expression<String>? type,
    Expression<int>? pulseCount,
    Expression<double>? referenceLiters,
    Expression<double>? readingLiters,
    Expression<double>? indicatedLiters,
    Expression<double>? diagnosticErrorPct,
    Expression<double>? needleLiters,
    Expression<int>? capturedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sampleId != null) 'sample_id': sampleId,
      if (type != null) 'type': type,
      if (pulseCount != null) 'pulse_count': pulseCount,
      if (referenceLiters != null) 'reference_liters': referenceLiters,
      if (readingLiters != null) 'reading_liters': readingLiters,
      if (indicatedLiters != null) 'indicated_liters': indicatedLiters,
      if (diagnosticErrorPct != null)
        'diagnostic_error_pct': diagnosticErrorPct,
      if (needleLiters != null) 'needle_liters': needleLiters,
      if (capturedAtMs != null) 'captured_at_ms': capturedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TestPointsCompanion copyWith({
    Value<String>? id,
    Value<String>? sampleId,
    Value<String>? type,
    Value<int?>? pulseCount,
    Value<double?>? referenceLiters,
    Value<double?>? readingLiters,
    Value<double?>? indicatedLiters,
    Value<double?>? diagnosticErrorPct,
    Value<double?>? needleLiters,
    Value<int>? capturedAtMs,
    Value<int>? rowid,
  }) {
    return TestPointsCompanion(
      id: id ?? this.id,
      sampleId: sampleId ?? this.sampleId,
      type: type ?? this.type,
      pulseCount: pulseCount ?? this.pulseCount,
      referenceLiters: referenceLiters ?? this.referenceLiters,
      readingLiters: readingLiters ?? this.readingLiters,
      indicatedLiters: indicatedLiters ?? this.indicatedLiters,
      diagnosticErrorPct: diagnosticErrorPct ?? this.diagnosticErrorPct,
      needleLiters: needleLiters ?? this.needleLiters,
      capturedAtMs: capturedAtMs ?? this.capturedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sampleId.present) {
      map['sample_id'] = Variable<String>(sampleId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (pulseCount.present) {
      map['pulse_count'] = Variable<int>(pulseCount.value);
    }
    if (referenceLiters.present) {
      map['reference_liters'] = Variable<double>(referenceLiters.value);
    }
    if (readingLiters.present) {
      map['reading_liters'] = Variable<double>(readingLiters.value);
    }
    if (indicatedLiters.present) {
      map['indicated_liters'] = Variable<double>(indicatedLiters.value);
    }
    if (diagnosticErrorPct.present) {
      map['diagnostic_error_pct'] = Variable<double>(diagnosticErrorPct.value);
    }
    if (needleLiters.present) {
      map['needle_liters'] = Variable<double>(needleLiters.value);
    }
    if (capturedAtMs.present) {
      map['captured_at_ms'] = Variable<int>(capturedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TestPointsCompanion(')
          ..write('id: $id, ')
          ..write('sampleId: $sampleId, ')
          ..write('type: $type, ')
          ..write('pulseCount: $pulseCount, ')
          ..write('referenceLiters: $referenceLiters, ')
          ..write('readingLiters: $readingLiters, ')
          ..write('indicatedLiters: $indicatedLiters, ')
          ..write('diagnosticErrorPct: $diagnosticErrorPct, ')
          ..write('needleLiters: $needleLiters, ')
          ..write('capturedAtMs: $capturedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EvidenceItemsTable extends EvidenceItems
    with TableInfo<$EvidenceItemsTable, EvidenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EvidenceItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sampleIdMeta = const VerificationMeta(
    'sampleId',
  );
  @override
  late final GeneratedColumn<String> sampleId = GeneratedColumn<String>(
    'sample_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES samples (id)',
    ),
  );
  static const VerificationMeta _pointIdMeta = const VerificationMeta(
    'pointId',
  );
  @override
  late final GeneratedColumn<String> pointId = GeneratedColumn<String>(
    'point_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES test_points (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requiredMeta = const VerificationMeta(
    'required',
  );
  @override
  late final GeneratedColumn<bool> required = GeneratedColumn<bool>(
    'required',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("required" IN (0, 1))',
    ),
  );
  static const VerificationMeta _volumeRefLitersMeta = const VerificationMeta(
    'volumeRefLiters',
  );
  @override
  late final GeneratedColumn<double> volumeRefLiters = GeneratedColumn<double>(
    'volume_ref_liters',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pulseCountMeta = const VerificationMeta(
    'pulseCount',
  );
  @override
  late final GeneratedColumn<int> pulseCount = GeneratedColumn<int>(
    'pulse_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capturedAtMsMeta = const VerificationMeta(
    'capturedAtMs',
  );
  @override
  late final GeneratedColumn<int> capturedAtMs = GeneratedColumn<int>(
    'captured_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverStorageKeyMeta = const VerificationMeta(
    'serverStorageKey',
  );
  @override
  late final GeneratedColumn<String> serverStorageKey = GeneratedColumn<String>(
    'server_storage_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sampleId,
    pointId,
    type,
    required,
    volumeRefLiters,
    pulseCount,
    capturedAtMs,
    sha256,
    localPath,
    serverStorageKey,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'evidence_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<EvidenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sample_id')) {
      context.handle(
        _sampleIdMeta,
        sampleId.isAcceptableOrUnknown(data['sample_id']!, _sampleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sampleIdMeta);
    }
    if (data.containsKey('point_id')) {
      context.handle(
        _pointIdMeta,
        pointId.isAcceptableOrUnknown(data['point_id']!, _pointIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('required')) {
      context.handle(
        _requiredMeta,
        required.isAcceptableOrUnknown(data['required']!, _requiredMeta),
      );
    } else if (isInserting) {
      context.missing(_requiredMeta);
    }
    if (data.containsKey('volume_ref_liters')) {
      context.handle(
        _volumeRefLitersMeta,
        volumeRefLiters.isAcceptableOrUnknown(
          data['volume_ref_liters']!,
          _volumeRefLitersMeta,
        ),
      );
    }
    if (data.containsKey('pulse_count')) {
      context.handle(
        _pulseCountMeta,
        pulseCount.isAcceptableOrUnknown(data['pulse_count']!, _pulseCountMeta),
      );
    }
    if (data.containsKey('captured_at_ms')) {
      context.handle(
        _capturedAtMsMeta,
        capturedAtMs.isAcceptableOrUnknown(
          data['captured_at_ms']!,
          _capturedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMsMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('server_storage_key')) {
      context.handle(
        _serverStorageKeyMeta,
        serverStorageKey.isAcceptableOrUnknown(
          data['server_storage_key']!,
          _serverStorageKeyMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EvidenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EvidenceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sampleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sample_id'],
      )!,
      pointId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}point_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      required: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}required'],
      )!,
      volumeRefLiters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}volume_ref_liters'],
      ),
      pulseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pulse_count'],
      ),
      capturedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}captured_at_ms'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      serverStorageKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_storage_key'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $EvidenceItemsTable createAlias(String alias) {
    return $EvidenceItemsTable(attachedDatabase, alias);
  }
}

class EvidenceRow extends DataClass implements Insertable<EvidenceRow> {
  final String id;
  final String sampleId;
  final String? pointId;
  final String type;
  final bool required;
  final double? volumeRefLiters;
  final int? pulseCount;
  final int capturedAtMs;
  final String? sha256;
  final String localPath;
  final String? serverStorageKey;
  final String syncStatus;
  const EvidenceRow({
    required this.id,
    required this.sampleId,
    this.pointId,
    required this.type,
    required this.required,
    this.volumeRefLiters,
    this.pulseCount,
    required this.capturedAtMs,
    this.sha256,
    required this.localPath,
    this.serverStorageKey,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sample_id'] = Variable<String>(sampleId);
    if (!nullToAbsent || pointId != null) {
      map['point_id'] = Variable<String>(pointId);
    }
    map['type'] = Variable<String>(type);
    map['required'] = Variable<bool>(required);
    if (!nullToAbsent || volumeRefLiters != null) {
      map['volume_ref_liters'] = Variable<double>(volumeRefLiters);
    }
    if (!nullToAbsent || pulseCount != null) {
      map['pulse_count'] = Variable<int>(pulseCount);
    }
    map['captured_at_ms'] = Variable<int>(capturedAtMs);
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    map['local_path'] = Variable<String>(localPath);
    if (!nullToAbsent || serverStorageKey != null) {
      map['server_storage_key'] = Variable<String>(serverStorageKey);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  EvidenceItemsCompanion toCompanion(bool nullToAbsent) {
    return EvidenceItemsCompanion(
      id: Value(id),
      sampleId: Value(sampleId),
      pointId: pointId == null && nullToAbsent
          ? const Value.absent()
          : Value(pointId),
      type: Value(type),
      required: Value(required),
      volumeRefLiters: volumeRefLiters == null && nullToAbsent
          ? const Value.absent()
          : Value(volumeRefLiters),
      pulseCount: pulseCount == null && nullToAbsent
          ? const Value.absent()
          : Value(pulseCount),
      capturedAtMs: Value(capturedAtMs),
      sha256: sha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(sha256),
      localPath: Value(localPath),
      serverStorageKey: serverStorageKey == null && nullToAbsent
          ? const Value.absent()
          : Value(serverStorageKey),
      syncStatus: Value(syncStatus),
    );
  }

  factory EvidenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EvidenceRow(
      id: serializer.fromJson<String>(json['id']),
      sampleId: serializer.fromJson<String>(json['sampleId']),
      pointId: serializer.fromJson<String?>(json['pointId']),
      type: serializer.fromJson<String>(json['type']),
      required: serializer.fromJson<bool>(json['required']),
      volumeRefLiters: serializer.fromJson<double?>(json['volumeRefLiters']),
      pulseCount: serializer.fromJson<int?>(json['pulseCount']),
      capturedAtMs: serializer.fromJson<int>(json['capturedAtMs']),
      sha256: serializer.fromJson<String?>(json['sha256']),
      localPath: serializer.fromJson<String>(json['localPath']),
      serverStorageKey: serializer.fromJson<String?>(json['serverStorageKey']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sampleId': serializer.toJson<String>(sampleId),
      'pointId': serializer.toJson<String?>(pointId),
      'type': serializer.toJson<String>(type),
      'required': serializer.toJson<bool>(required),
      'volumeRefLiters': serializer.toJson<double?>(volumeRefLiters),
      'pulseCount': serializer.toJson<int?>(pulseCount),
      'capturedAtMs': serializer.toJson<int>(capturedAtMs),
      'sha256': serializer.toJson<String?>(sha256),
      'localPath': serializer.toJson<String>(localPath),
      'serverStorageKey': serializer.toJson<String?>(serverStorageKey),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  EvidenceRow copyWith({
    String? id,
    String? sampleId,
    Value<String?> pointId = const Value.absent(),
    String? type,
    bool? required,
    Value<double?> volumeRefLiters = const Value.absent(),
    Value<int?> pulseCount = const Value.absent(),
    int? capturedAtMs,
    Value<String?> sha256 = const Value.absent(),
    String? localPath,
    Value<String?> serverStorageKey = const Value.absent(),
    String? syncStatus,
  }) => EvidenceRow(
    id: id ?? this.id,
    sampleId: sampleId ?? this.sampleId,
    pointId: pointId.present ? pointId.value : this.pointId,
    type: type ?? this.type,
    required: required ?? this.required,
    volumeRefLiters: volumeRefLiters.present
        ? volumeRefLiters.value
        : this.volumeRefLiters,
    pulseCount: pulseCount.present ? pulseCount.value : this.pulseCount,
    capturedAtMs: capturedAtMs ?? this.capturedAtMs,
    sha256: sha256.present ? sha256.value : this.sha256,
    localPath: localPath ?? this.localPath,
    serverStorageKey: serverStorageKey.present
        ? serverStorageKey.value
        : this.serverStorageKey,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  EvidenceRow copyWithCompanion(EvidenceItemsCompanion data) {
    return EvidenceRow(
      id: data.id.present ? data.id.value : this.id,
      sampleId: data.sampleId.present ? data.sampleId.value : this.sampleId,
      pointId: data.pointId.present ? data.pointId.value : this.pointId,
      type: data.type.present ? data.type.value : this.type,
      required: data.required.present ? data.required.value : this.required,
      volumeRefLiters: data.volumeRefLiters.present
          ? data.volumeRefLiters.value
          : this.volumeRefLiters,
      pulseCount: data.pulseCount.present
          ? data.pulseCount.value
          : this.pulseCount,
      capturedAtMs: data.capturedAtMs.present
          ? data.capturedAtMs.value
          : this.capturedAtMs,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      serverStorageKey: data.serverStorageKey.present
          ? data.serverStorageKey.value
          : this.serverStorageKey,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EvidenceRow(')
          ..write('id: $id, ')
          ..write('sampleId: $sampleId, ')
          ..write('pointId: $pointId, ')
          ..write('type: $type, ')
          ..write('required: $required, ')
          ..write('volumeRefLiters: $volumeRefLiters, ')
          ..write('pulseCount: $pulseCount, ')
          ..write('capturedAtMs: $capturedAtMs, ')
          ..write('sha256: $sha256, ')
          ..write('localPath: $localPath, ')
          ..write('serverStorageKey: $serverStorageKey, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sampleId,
    pointId,
    type,
    required,
    volumeRefLiters,
    pulseCount,
    capturedAtMs,
    sha256,
    localPath,
    serverStorageKey,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EvidenceRow &&
          other.id == this.id &&
          other.sampleId == this.sampleId &&
          other.pointId == this.pointId &&
          other.type == this.type &&
          other.required == this.required &&
          other.volumeRefLiters == this.volumeRefLiters &&
          other.pulseCount == this.pulseCount &&
          other.capturedAtMs == this.capturedAtMs &&
          other.sha256 == this.sha256 &&
          other.localPath == this.localPath &&
          other.serverStorageKey == this.serverStorageKey &&
          other.syncStatus == this.syncStatus);
}

class EvidenceItemsCompanion extends UpdateCompanion<EvidenceRow> {
  final Value<String> id;
  final Value<String> sampleId;
  final Value<String?> pointId;
  final Value<String> type;
  final Value<bool> required;
  final Value<double?> volumeRefLiters;
  final Value<int?> pulseCount;
  final Value<int> capturedAtMs;
  final Value<String?> sha256;
  final Value<String> localPath;
  final Value<String?> serverStorageKey;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const EvidenceItemsCompanion({
    this.id = const Value.absent(),
    this.sampleId = const Value.absent(),
    this.pointId = const Value.absent(),
    this.type = const Value.absent(),
    this.required = const Value.absent(),
    this.volumeRefLiters = const Value.absent(),
    this.pulseCount = const Value.absent(),
    this.capturedAtMs = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.localPath = const Value.absent(),
    this.serverStorageKey = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EvidenceItemsCompanion.insert({
    required String id,
    required String sampleId,
    this.pointId = const Value.absent(),
    required String type,
    required bool required,
    this.volumeRefLiters = const Value.absent(),
    this.pulseCount = const Value.absent(),
    required int capturedAtMs,
    this.sha256 = const Value.absent(),
    required String localPath,
    this.serverStorageKey = const Value.absent(),
    required String syncStatus,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sampleId = Value(sampleId),
       type = Value(type),
       required = Value(required),
       capturedAtMs = Value(capturedAtMs),
       localPath = Value(localPath),
       syncStatus = Value(syncStatus);
  static Insertable<EvidenceRow> custom({
    Expression<String>? id,
    Expression<String>? sampleId,
    Expression<String>? pointId,
    Expression<String>? type,
    Expression<bool>? required,
    Expression<double>? volumeRefLiters,
    Expression<int>? pulseCount,
    Expression<int>? capturedAtMs,
    Expression<String>? sha256,
    Expression<String>? localPath,
    Expression<String>? serverStorageKey,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sampleId != null) 'sample_id': sampleId,
      if (pointId != null) 'point_id': pointId,
      if (type != null) 'type': type,
      if (required != null) 'required': required,
      if (volumeRefLiters != null) 'volume_ref_liters': volumeRefLiters,
      if (pulseCount != null) 'pulse_count': pulseCount,
      if (capturedAtMs != null) 'captured_at_ms': capturedAtMs,
      if (sha256 != null) 'sha256': sha256,
      if (localPath != null) 'local_path': localPath,
      if (serverStorageKey != null) 'server_storage_key': serverStorageKey,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EvidenceItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? sampleId,
    Value<String?>? pointId,
    Value<String>? type,
    Value<bool>? required,
    Value<double?>? volumeRefLiters,
    Value<int?>? pulseCount,
    Value<int>? capturedAtMs,
    Value<String?>? sha256,
    Value<String>? localPath,
    Value<String?>? serverStorageKey,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return EvidenceItemsCompanion(
      id: id ?? this.id,
      sampleId: sampleId ?? this.sampleId,
      pointId: pointId ?? this.pointId,
      type: type ?? this.type,
      required: required ?? this.required,
      volumeRefLiters: volumeRefLiters ?? this.volumeRefLiters,
      pulseCount: pulseCount ?? this.pulseCount,
      capturedAtMs: capturedAtMs ?? this.capturedAtMs,
      sha256: sha256 ?? this.sha256,
      localPath: localPath ?? this.localPath,
      serverStorageKey: serverStorageKey ?? this.serverStorageKey,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sampleId.present) {
      map['sample_id'] = Variable<String>(sampleId.value);
    }
    if (pointId.present) {
      map['point_id'] = Variable<String>(pointId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (required.present) {
      map['required'] = Variable<bool>(required.value);
    }
    if (volumeRefLiters.present) {
      map['volume_ref_liters'] = Variable<double>(volumeRefLiters.value);
    }
    if (pulseCount.present) {
      map['pulse_count'] = Variable<int>(pulseCount.value);
    }
    if (capturedAtMs.present) {
      map['captured_at_ms'] = Variable<int>(capturedAtMs.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (serverStorageKey.present) {
      map['server_storage_key'] = Variable<String>(serverStorageKey.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EvidenceItemsCompanion(')
          ..write('id: $id, ')
          ..write('sampleId: $sampleId, ')
          ..write('pointId: $pointId, ')
          ..write('type: $type, ')
          ..write('required: $required, ')
          ..write('volumeRefLiters: $volumeRefLiters, ')
          ..write('pulseCount: $pulseCount, ')
          ..write('capturedAtMs: $capturedAtMs, ')
          ..write('sha256: $sha256, ')
          ..write('localPath: $localPath, ')
          ..write('serverStorageKey: $serverStorageKey, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncItemsTable extends SyncItems
    with TableInfo<$SyncItemsTable, SyncItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextRetryAtMsMeta = const VerificationMeta(
    'nextRetryAtMs',
  );
  @override
  late final GeneratedColumn<int> nextRetryAtMs = GeneratedColumn<int>(
    'next_retry_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    checksum,
    state,
    attempts,
    lastError,
    createdAtMs,
    updatedAtMs,
    nextRetryAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    if (data.containsKey('next_retry_at_ms')) {
      context.handle(
        _nextRetryAtMsMeta,
        nextRetryAtMs.isAcceptableOrUnknown(
          data['next_retry_at_ms']!,
          _nextRetryAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {entityType, entityId, checksum},
  ];
  @override
  SyncItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      nextRetryAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_retry_at_ms'],
      ),
    );
  }

  @override
  $SyncItemsTable createAlias(String alias) {
    return $SyncItemsTable(attachedDatabase, alias);
  }
}

class SyncItemRow extends DataClass implements Insertable<SyncItemRow> {
  final String id;
  final String entityType;
  final String entityId;
  final String checksum;
  final String state;
  final int attempts;
  final String? lastError;
  final int createdAtMs;
  final int updatedAtMs;
  final int? nextRetryAtMs;
  const SyncItemRow({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.checksum,
    required this.state,
    required this.attempts,
    this.lastError,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.nextRetryAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['checksum'] = Variable<String>(checksum);
    map['state'] = Variable<String>(state);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    if (!nullToAbsent || nextRetryAtMs != null) {
      map['next_retry_at_ms'] = Variable<int>(nextRetryAtMs);
    }
    return map;
  }

  SyncItemsCompanion toCompanion(bool nullToAbsent) {
    return SyncItemsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      checksum: Value(checksum),
      state: Value(state),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      nextRetryAtMs: nextRetryAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAtMs),
    );
  }

  factory SyncItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncItemRow(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      checksum: serializer.fromJson<String>(json['checksum']),
      state: serializer.fromJson<String>(json['state']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      nextRetryAtMs: serializer.fromJson<int?>(json['nextRetryAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'checksum': serializer.toJson<String>(checksum),
      'state': serializer.toJson<String>(state),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'nextRetryAtMs': serializer.toJson<int?>(nextRetryAtMs),
    };
  }

  SyncItemRow copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? checksum,
    String? state,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    int? createdAtMs,
    int? updatedAtMs,
    Value<int?> nextRetryAtMs = const Value.absent(),
  }) => SyncItemRow(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    checksum: checksum ?? this.checksum,
    state: state ?? this.state,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    nextRetryAtMs: nextRetryAtMs.present
        ? nextRetryAtMs.value
        : this.nextRetryAtMs,
  );
  SyncItemRow copyWithCompanion(SyncItemsCompanion data) {
    return SyncItemRow(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      state: data.state.present ? data.state.value : this.state,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      nextRetryAtMs: data.nextRetryAtMs.present
          ? data.nextRetryAtMs.value
          : this.nextRetryAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncItemRow(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('checksum: $checksum, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('nextRetryAtMs: $nextRetryAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    checksum,
    state,
    attempts,
    lastError,
    createdAtMs,
    updatedAtMs,
    nextRetryAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncItemRow &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.checksum == this.checksum &&
          other.state == this.state &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.nextRetryAtMs == this.nextRetryAtMs);
}

class SyncItemsCompanion extends UpdateCompanion<SyncItemRow> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> checksum;
  final Value<String> state;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int?> nextRetryAtMs;
  final Value<int> rowid;
  const SyncItemsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.checksum = const Value.absent(),
    this.state = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.nextRetryAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncItemsCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    required String checksum,
    required String state,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    this.nextRetryAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       checksum = Value(checksum),
       state = Value(state),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<SyncItemRow> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? checksum,
    Expression<String>? state,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? nextRetryAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (checksum != null) 'checksum': checksum,
      if (state != null) 'state': state,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (nextRetryAtMs != null) 'next_retry_at_ms': nextRetryAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? checksum,
    Value<String>? state,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int?>? nextRetryAtMs,
    Value<int>? rowid,
  }) {
    return SyncItemsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      checksum: checksum ?? this.checksum,
      state: state ?? this.state,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      nextRetryAtMs: nextRetryAtMs ?? this.nextRetryAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (nextRetryAtMs.present) {
      map['next_retry_at_ms'] = Variable<int>(nextRetryAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncItemsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('checksum: $checksum, ')
          ..write('state: $state, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('nextRetryAtMs: $nextRetryAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $MetersTable meters = $MetersTable(this);
  late final $VerificationCasesTable verificationCases =
      $VerificationCasesTable(this);
  late final $FlowPointsTable flowPoints = $FlowPointsTable(this);
  late final $SamplesTable samples = $SamplesTable(this);
  late final $TestPointsTable testPoints = $TestPointsTable(this);
  late final $EvidenceItemsTable evidenceItems = $EvidenceItemsTable(this);
  late final $SyncItemsTable syncItems = $SyncItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    meters,
    verificationCases,
    flowPoints,
    samples,
    testPoints,
    evidenceItems,
    syncItems,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required String id,
      required String email,
      required String phone,
      Value<String?> displayName,
      required int createdAtMs,
      Value<int?> lastLoginAtMs,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> id,
      Value<String> email,
      Value<String> phone,
      Value<String?> displayName,
      Value<int> createdAtMs,
      Value<int?> lastLoginAtMs,
      Value<int> rowid,
    });

final class $$UsersTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTable, User> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VerificationCasesTable, List<VerificationCaseRow>>
  _verificationCasesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.verificationCases,
        aliasName: 'users__id__verification_cases__user_id',
      );

  $$VerificationCasesTableProcessedTableManager get verificationCasesRefs {
    final manager = $$VerificationCasesTableTableManager(
      $_db,
      $_db.verificationCases,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _verificationCasesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastLoginAtMs => $composableBuilder(
    column: $table.lastLoginAtMs,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> verificationCasesRefs(
    Expression<bool> Function($$VerificationCasesTableFilterComposer f) f,
  ) {
    final $$VerificationCasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.verificationCases,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VerificationCasesTableFilterComposer(
            $db: $db,
            $table: $db.verificationCases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastLoginAtMs => $composableBuilder(
    column: $table.lastLoginAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastLoginAtMs => $composableBuilder(
    column: $table.lastLoginAtMs,
    builder: (column) => column,
  );

  Expression<T> verificationCasesRefs<T extends Object>(
    Expression<T> Function($$VerificationCasesTableAnnotationComposer a) f,
  ) {
    final $$VerificationCasesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.verificationCases,
          getReferencedColumn: (t) => t.userId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VerificationCasesTableAnnotationComposer(
                $db: $db,
                $table: $db.verificationCases,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, $$UsersTableReferences),
          User,
          PrefetchHooks Function({bool verificationCasesRefs})
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int?> lastLoginAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                email: email,
                phone: phone,
                displayName: displayName,
                createdAtMs: createdAtMs,
                lastLoginAtMs: lastLoginAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String email,
                required String phone,
                Value<String?> displayName = const Value.absent(),
                required int createdAtMs,
                Value<int?> lastLoginAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                email: email,
                phone: phone,
                displayName: displayName,
                createdAtMs: createdAtMs,
                lastLoginAtMs: lastLoginAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$UsersTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({verificationCasesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (verificationCasesRefs) db.verificationCases,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (verificationCasesRefs)
                    await $_getPrefetchedData<
                      User,
                      $UsersTable,
                      VerificationCaseRow
                    >(
                      currentTable: table,
                      referencedTable: $$UsersTableReferences
                          ._verificationCasesRefsTable(db),
                      managerFromTypedResult: (p0) => $$UsersTableReferences(
                        db,
                        table,
                        p0,
                      ).verificationCasesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.userId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, $$UsersTableReferences),
      User,
      PrefetchHooks Function({bool verificationCasesRefs})
    >;
typedef $$MetersTableCreateCompanionBuilder =
    MetersCompanion Function({
      required String id,
      required String externalStatus,
      Value<String?> externalSnapshotJson,
      Value<int?> externalCheckedAtMs,
      required int createdAtMs,
      required int updatedAtMs,
      Value<int> rowid,
    });
typedef $$MetersTableUpdateCompanionBuilder =
    MetersCompanion Function({
      Value<String> id,
      Value<String> externalStatus,
      Value<String?> externalSnapshotJson,
      Value<int?> externalCheckedAtMs,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int> rowid,
    });

final class $$MetersTableReferences
    extends BaseReferences<_$AppDatabase, $MetersTable, Meter> {
  $$MetersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VerificationCasesTable, List<VerificationCaseRow>>
  _verificationCasesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.verificationCases,
        aliasName: 'meters__id__verification_cases__meter_id',
      );

  $$VerificationCasesTableProcessedTableManager get verificationCasesRefs {
    final manager = $$VerificationCasesTableTableManager(
      $_db,
      $_db.verificationCases,
    ).filter((f) => f.meterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _verificationCasesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MetersTableFilterComposer
    extends Composer<_$AppDatabase, $MetersTable> {
  $$MetersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalStatus => $composableBuilder(
    column: $table.externalStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalSnapshotJson => $composableBuilder(
    column: $table.externalSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get externalCheckedAtMs => $composableBuilder(
    column: $table.externalCheckedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> verificationCasesRefs(
    Expression<bool> Function($$VerificationCasesTableFilterComposer f) f,
  ) {
    final $$VerificationCasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.verificationCases,
      getReferencedColumn: (t) => t.meterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VerificationCasesTableFilterComposer(
            $db: $db,
            $table: $db.verificationCases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MetersTableOrderingComposer
    extends Composer<_$AppDatabase, $MetersTable> {
  $$MetersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalStatus => $composableBuilder(
    column: $table.externalStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalSnapshotJson => $composableBuilder(
    column: $table.externalSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get externalCheckedAtMs => $composableBuilder(
    column: $table.externalCheckedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetersTable> {
  $$MetersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get externalStatus => $composableBuilder(
    column: $table.externalStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalSnapshotJson => $composableBuilder(
    column: $table.externalSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get externalCheckedAtMs => $composableBuilder(
    column: $table.externalCheckedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  Expression<T> verificationCasesRefs<T extends Object>(
    Expression<T> Function($$VerificationCasesTableAnnotationComposer a) f,
  ) {
    final $$VerificationCasesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.verificationCases,
          getReferencedColumn: (t) => t.meterId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VerificationCasesTableAnnotationComposer(
                $db: $db,
                $table: $db.verificationCases,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MetersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetersTable,
          Meter,
          $$MetersTableFilterComposer,
          $$MetersTableOrderingComposer,
          $$MetersTableAnnotationComposer,
          $$MetersTableCreateCompanionBuilder,
          $$MetersTableUpdateCompanionBuilder,
          (Meter, $$MetersTableReferences),
          Meter,
          PrefetchHooks Function({bool verificationCasesRefs})
        > {
  $$MetersTableTableManager(_$AppDatabase db, $MetersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> externalStatus = const Value.absent(),
                Value<String?> externalSnapshotJson = const Value.absent(),
                Value<int?> externalCheckedAtMs = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetersCompanion(
                id: id,
                externalStatus: externalStatus,
                externalSnapshotJson: externalSnapshotJson,
                externalCheckedAtMs: externalCheckedAtMs,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String externalStatus,
                Value<String?> externalSnapshotJson = const Value.absent(),
                Value<int?> externalCheckedAtMs = const Value.absent(),
                required int createdAtMs,
                required int updatedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => MetersCompanion.insert(
                id: id,
                externalStatus: externalStatus,
                externalSnapshotJson: externalSnapshotJson,
                externalCheckedAtMs: externalCheckedAtMs,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$MetersTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({verificationCasesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (verificationCasesRefs) db.verificationCases,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (verificationCasesRefs)
                    await $_getPrefetchedData<
                      Meter,
                      $MetersTable,
                      VerificationCaseRow
                    >(
                      currentTable: table,
                      referencedTable: $$MetersTableReferences
                          ._verificationCasesRefsTable(db),
                      managerFromTypedResult: (p0) => $$MetersTableReferences(
                        db,
                        table,
                        p0,
                      ).verificationCasesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.meterId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MetersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetersTable,
      Meter,
      $$MetersTableFilterComposer,
      $$MetersTableOrderingComposer,
      $$MetersTableAnnotationComposer,
      $$MetersTableCreateCompanionBuilder,
      $$MetersTableUpdateCompanionBuilder,
      (Meter, $$MetersTableReferences),
      Meter,
      PrefetchHooks Function({bool verificationCasesRefs})
    >;
typedef $$VerificationCasesTableCreateCompanionBuilder =
    VerificationCasesCompanion Function({
      required String id,
      required String meterId,
      required String userId,
      required String status,
      Value<String?> overallVerdict,
      required int createdAtMs,
      Value<int?> closedAtMs,
      Value<int> reportVersion,
      Value<String?> checksum,
      Value<int> rowid,
    });
typedef $$VerificationCasesTableUpdateCompanionBuilder =
    VerificationCasesCompanion Function({
      Value<String> id,
      Value<String> meterId,
      Value<String> userId,
      Value<String> status,
      Value<String?> overallVerdict,
      Value<int> createdAtMs,
      Value<int?> closedAtMs,
      Value<int> reportVersion,
      Value<String?> checksum,
      Value<int> rowid,
    });

final class $$VerificationCasesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $VerificationCasesTable,
          VerificationCaseRow
        > {
  $$VerificationCasesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MetersTable _meterIdTable(_$AppDatabase db) =>
      db.meters.createAlias('verification_cases__meter_id__meters__id');

  $$MetersTableProcessedTableManager get meterId {
    final $_column = $_itemColumn<String>('meter_id')!;

    final manager = $$MetersTableTableManager(
      $_db,
      $_db.meters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_meterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UsersTable _userIdTable(_$AppDatabase db) =>
      db.users.createAlias('verification_cases__user_id__users__id');

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FlowPointsTable, List<FlowPointRow>>
  _flowPointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.flowPoints,
    aliasName: 'verification_cases__id__flow_points__case_id',
  );

  $$FlowPointsTableProcessedTableManager get flowPointsRefs {
    final manager = $$FlowPointsTableTableManager(
      $_db,
      $_db.flowPoints,
    ).filter((f) => f.caseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_flowPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VerificationCasesTableFilterComposer
    extends Composer<_$AppDatabase, $VerificationCasesTable> {
  $$VerificationCasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overallVerdict => $composableBuilder(
    column: $table.overallVerdict,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get closedAtMs => $composableBuilder(
    column: $table.closedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reportVersion => $composableBuilder(
    column: $table.reportVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  $$MetersTableFilterComposer get meterId {
    final $$MetersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.meterId,
      referencedTable: $db.meters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MetersTableFilterComposer(
            $db: $db,
            $table: $db.meters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> flowPointsRefs(
    Expression<bool> Function($$FlowPointsTableFilterComposer f) f,
  ) {
    final $$FlowPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flowPoints,
      getReferencedColumn: (t) => t.caseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlowPointsTableFilterComposer(
            $db: $db,
            $table: $db.flowPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VerificationCasesTableOrderingComposer
    extends Composer<_$AppDatabase, $VerificationCasesTable> {
  $$VerificationCasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overallVerdict => $composableBuilder(
    column: $table.overallVerdict,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get closedAtMs => $composableBuilder(
    column: $table.closedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reportVersion => $composableBuilder(
    column: $table.reportVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  $$MetersTableOrderingComposer get meterId {
    final $$MetersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.meterId,
      referencedTable: $db.meters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MetersTableOrderingComposer(
            $db: $db,
            $table: $db.meters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VerificationCasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VerificationCasesTable> {
  $$VerificationCasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get overallVerdict => $composableBuilder(
    column: $table.overallVerdict,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get closedAtMs => $composableBuilder(
    column: $table.closedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reportVersion => $composableBuilder(
    column: $table.reportVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  $$MetersTableAnnotationComposer get meterId {
    final $$MetersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.meterId,
      referencedTable: $db.meters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MetersTableAnnotationComposer(
            $db: $db,
            $table: $db.meters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> flowPointsRefs<T extends Object>(
    Expression<T> Function($$FlowPointsTableAnnotationComposer a) f,
  ) {
    final $$FlowPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flowPoints,
      getReferencedColumn: (t) => t.caseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlowPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.flowPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VerificationCasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VerificationCasesTable,
          VerificationCaseRow,
          $$VerificationCasesTableFilterComposer,
          $$VerificationCasesTableOrderingComposer,
          $$VerificationCasesTableAnnotationComposer,
          $$VerificationCasesTableCreateCompanionBuilder,
          $$VerificationCasesTableUpdateCompanionBuilder,
          (VerificationCaseRow, $$VerificationCasesTableReferences),
          VerificationCaseRow,
          PrefetchHooks Function({
            bool meterId,
            bool userId,
            bool flowPointsRefs,
          })
        > {
  $$VerificationCasesTableTableManager(
    _$AppDatabase db,
    $VerificationCasesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VerificationCasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VerificationCasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VerificationCasesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> meterId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> overallVerdict = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int?> closedAtMs = const Value.absent(),
                Value<int> reportVersion = const Value.absent(),
                Value<String?> checksum = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VerificationCasesCompanion(
                id: id,
                meterId: meterId,
                userId: userId,
                status: status,
                overallVerdict: overallVerdict,
                createdAtMs: createdAtMs,
                closedAtMs: closedAtMs,
                reportVersion: reportVersion,
                checksum: checksum,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String meterId,
                required String userId,
                required String status,
                Value<String?> overallVerdict = const Value.absent(),
                required int createdAtMs,
                Value<int?> closedAtMs = const Value.absent(),
                Value<int> reportVersion = const Value.absent(),
                Value<String?> checksum = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VerificationCasesCompanion.insert(
                id: id,
                meterId: meterId,
                userId: userId,
                status: status,
                overallVerdict: overallVerdict,
                createdAtMs: createdAtMs,
                closedAtMs: closedAtMs,
                reportVersion: reportVersion,
                checksum: checksum,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VerificationCasesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({meterId = false, userId = false, flowPointsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (flowPointsRefs) db.flowPoints],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (meterId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.meterId,
                                    referencedTable:
                                        $$VerificationCasesTableReferences
                                            ._meterIdTable(db),
                                    referencedColumn:
                                        $$VerificationCasesTableReferences
                                            ._meterIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (userId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.userId,
                                    referencedTable:
                                        $$VerificationCasesTableReferences
                                            ._userIdTable(db),
                                    referencedColumn:
                                        $$VerificationCasesTableReferences
                                            ._userIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (flowPointsRefs)
                        await $_getPrefetchedData<
                          VerificationCaseRow,
                          $VerificationCasesTable,
                          FlowPointRow
                        >(
                          currentTable: table,
                          referencedTable: $$VerificationCasesTableReferences
                              ._flowPointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VerificationCasesTableReferences(
                                db,
                                table,
                                p0,
                              ).flowPointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.caseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VerificationCasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VerificationCasesTable,
      VerificationCaseRow,
      $$VerificationCasesTableFilterComposer,
      $$VerificationCasesTableOrderingComposer,
      $$VerificationCasesTableAnnotationComposer,
      $$VerificationCasesTableCreateCompanionBuilder,
      $$VerificationCasesTableUpdateCompanionBuilder,
      (VerificationCaseRow, $$VerificationCasesTableReferences),
      VerificationCaseRow,
      PrefetchHooks Function({bool meterId, bool userId, bool flowPointsRefs})
    >;
typedef $$FlowPointsTableCreateCompanionBuilder =
    FlowPointsCompanion Function({
      required String id,
      required String caseId,
      required String code,
      Value<double?> lpsApprox,
      required double mpePct,
      Value<String> status,
      Value<int?> statisticsN,
      Value<double?> meanErrorPct,
      Value<double?> minimumErrorPct,
      Value<double?> maximumErrorPct,
      Value<double?> dispersionPct,
      Value<double?> sampleStdDevPct,
      Value<String?> repeatabilityStatus,
      required int createdAtMs,
      Value<int> rowid,
    });
typedef $$FlowPointsTableUpdateCompanionBuilder =
    FlowPointsCompanion Function({
      Value<String> id,
      Value<String> caseId,
      Value<String> code,
      Value<double?> lpsApprox,
      Value<double> mpePct,
      Value<String> status,
      Value<int?> statisticsN,
      Value<double?> meanErrorPct,
      Value<double?> minimumErrorPct,
      Value<double?> maximumErrorPct,
      Value<double?> dispersionPct,
      Value<double?> sampleStdDevPct,
      Value<String?> repeatabilityStatus,
      Value<int> createdAtMs,
      Value<int> rowid,
    });

final class $$FlowPointsTableReferences
    extends BaseReferences<_$AppDatabase, $FlowPointsTable, FlowPointRow> {
  $$FlowPointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VerificationCasesTable _caseIdTable(_$AppDatabase db) => db
      .verificationCases
      .createAlias('flow_points__case_id__verification_cases__id');

  $$VerificationCasesTableProcessedTableManager get caseId {
    final $_column = $_itemColumn<String>('case_id')!;

    final manager = $$VerificationCasesTableTableManager(
      $_db,
      $_db.verificationCases,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_caseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SamplesTable, List<SampleRow>> _samplesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.samples,
    aliasName: 'flow_points__id__samples__flow_point_id',
  );

  $$SamplesTableProcessedTableManager get samplesRefs {
    final manager = $$SamplesTableTableManager(
      $_db,
      $_db.samples,
    ).filter((f) => f.flowPointId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_samplesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FlowPointsTableFilterComposer
    extends Composer<_$AppDatabase, $FlowPointsTable> {
  $$FlowPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lpsApprox => $composableBuilder(
    column: $table.lpsApprox,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get mpePct => $composableBuilder(
    column: $table.mpePct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statisticsN => $composableBuilder(
    column: $table.statisticsN,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get meanErrorPct => $composableBuilder(
    column: $table.meanErrorPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minimumErrorPct => $composableBuilder(
    column: $table.minimumErrorPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maximumErrorPct => $composableBuilder(
    column: $table.maximumErrorPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dispersionPct => $composableBuilder(
    column: $table.dispersionPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sampleStdDevPct => $composableBuilder(
    column: $table.sampleStdDevPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatabilityStatus => $composableBuilder(
    column: $table.repeatabilityStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  $$VerificationCasesTableFilterComposer get caseId {
    final $$VerificationCasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caseId,
      referencedTable: $db.verificationCases,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VerificationCasesTableFilterComposer(
            $db: $db,
            $table: $db.verificationCases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> samplesRefs(
    Expression<bool> Function($$SamplesTableFilterComposer f) f,
  ) {
    final $$SamplesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.samples,
      getReferencedColumn: (t) => t.flowPointId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SamplesTableFilterComposer(
            $db: $db,
            $table: $db.samples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FlowPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $FlowPointsTable> {
  $$FlowPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lpsApprox => $composableBuilder(
    column: $table.lpsApprox,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get mpePct => $composableBuilder(
    column: $table.mpePct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statisticsN => $composableBuilder(
    column: $table.statisticsN,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get meanErrorPct => $composableBuilder(
    column: $table.meanErrorPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minimumErrorPct => $composableBuilder(
    column: $table.minimumErrorPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maximumErrorPct => $composableBuilder(
    column: $table.maximumErrorPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dispersionPct => $composableBuilder(
    column: $table.dispersionPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sampleStdDevPct => $composableBuilder(
    column: $table.sampleStdDevPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatabilityStatus => $composableBuilder(
    column: $table.repeatabilityStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$VerificationCasesTableOrderingComposer get caseId {
    final $$VerificationCasesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caseId,
      referencedTable: $db.verificationCases,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VerificationCasesTableOrderingComposer(
            $db: $db,
            $table: $db.verificationCases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlowPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FlowPointsTable> {
  $$FlowPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<double> get lpsApprox =>
      $composableBuilder(column: $table.lpsApprox, builder: (column) => column);

  GeneratedColumn<double> get mpePct =>
      $composableBuilder(column: $table.mpePct, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get statisticsN => $composableBuilder(
    column: $table.statisticsN,
    builder: (column) => column,
  );

  GeneratedColumn<double> get meanErrorPct => $composableBuilder(
    column: $table.meanErrorPct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minimumErrorPct => $composableBuilder(
    column: $table.minimumErrorPct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maximumErrorPct => $composableBuilder(
    column: $table.maximumErrorPct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get dispersionPct => $composableBuilder(
    column: $table.dispersionPct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sampleStdDevPct => $composableBuilder(
    column: $table.sampleStdDevPct,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repeatabilityStatus => $composableBuilder(
    column: $table.repeatabilityStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  $$VerificationCasesTableAnnotationComposer get caseId {
    final $$VerificationCasesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.caseId,
          referencedTable: $db.verificationCases,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VerificationCasesTableAnnotationComposer(
                $db: $db,
                $table: $db.verificationCases,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> samplesRefs<T extends Object>(
    Expression<T> Function($$SamplesTableAnnotationComposer a) f,
  ) {
    final $$SamplesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.samples,
      getReferencedColumn: (t) => t.flowPointId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SamplesTableAnnotationComposer(
            $db: $db,
            $table: $db.samples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FlowPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FlowPointsTable,
          FlowPointRow,
          $$FlowPointsTableFilterComposer,
          $$FlowPointsTableOrderingComposer,
          $$FlowPointsTableAnnotationComposer,
          $$FlowPointsTableCreateCompanionBuilder,
          $$FlowPointsTableUpdateCompanionBuilder,
          (FlowPointRow, $$FlowPointsTableReferences),
          FlowPointRow,
          PrefetchHooks Function({bool caseId, bool samplesRefs})
        > {
  $$FlowPointsTableTableManager(_$AppDatabase db, $FlowPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlowPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlowPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlowPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> caseId = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<double?> lpsApprox = const Value.absent(),
                Value<double> mpePct = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> statisticsN = const Value.absent(),
                Value<double?> meanErrorPct = const Value.absent(),
                Value<double?> minimumErrorPct = const Value.absent(),
                Value<double?> maximumErrorPct = const Value.absent(),
                Value<double?> dispersionPct = const Value.absent(),
                Value<double?> sampleStdDevPct = const Value.absent(),
                Value<String?> repeatabilityStatus = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FlowPointsCompanion(
                id: id,
                caseId: caseId,
                code: code,
                lpsApprox: lpsApprox,
                mpePct: mpePct,
                status: status,
                statisticsN: statisticsN,
                meanErrorPct: meanErrorPct,
                minimumErrorPct: minimumErrorPct,
                maximumErrorPct: maximumErrorPct,
                dispersionPct: dispersionPct,
                sampleStdDevPct: sampleStdDevPct,
                repeatabilityStatus: repeatabilityStatus,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String caseId,
                required String code,
                Value<double?> lpsApprox = const Value.absent(),
                required double mpePct,
                Value<String> status = const Value.absent(),
                Value<int?> statisticsN = const Value.absent(),
                Value<double?> meanErrorPct = const Value.absent(),
                Value<double?> minimumErrorPct = const Value.absent(),
                Value<double?> maximumErrorPct = const Value.absent(),
                Value<double?> dispersionPct = const Value.absent(),
                Value<double?> sampleStdDevPct = const Value.absent(),
                Value<String?> repeatabilityStatus = const Value.absent(),
                required int createdAtMs,
                Value<int> rowid = const Value.absent(),
              }) => FlowPointsCompanion.insert(
                id: id,
                caseId: caseId,
                code: code,
                lpsApprox: lpsApprox,
                mpePct: mpePct,
                status: status,
                statisticsN: statisticsN,
                meanErrorPct: meanErrorPct,
                minimumErrorPct: minimumErrorPct,
                maximumErrorPct: maximumErrorPct,
                dispersionPct: dispersionPct,
                sampleStdDevPct: sampleStdDevPct,
                repeatabilityStatus: repeatabilityStatus,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FlowPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({caseId = false, samplesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (samplesRefs) db.samples],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (caseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.caseId,
                                referencedTable: $$FlowPointsTableReferences
                                    ._caseIdTable(db),
                                referencedColumn: $$FlowPointsTableReferences
                                    ._caseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (samplesRefs)
                    await $_getPrefetchedData<
                      FlowPointRow,
                      $FlowPointsTable,
                      SampleRow
                    >(
                      currentTable: table,
                      referencedTable: $$FlowPointsTableReferences
                          ._samplesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FlowPointsTableReferences(
                            db,
                            table,
                            p0,
                          ).samplesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.flowPointId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FlowPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FlowPointsTable,
      FlowPointRow,
      $$FlowPointsTableFilterComposer,
      $$FlowPointsTableOrderingComposer,
      $$FlowPointsTableAnnotationComposer,
      $$FlowPointsTableCreateCompanionBuilder,
      $$FlowPointsTableUpdateCompanionBuilder,
      (FlowPointRow, $$FlowPointsTableReferences),
      FlowPointRow,
      PrefetchHooks Function({bool caseId, bool samplesRefs})
    >;
typedef $$SamplesTableCreateCompanionBuilder =
    SamplesCompanion Function({
      required String id,
      required String flowPointId,
      required int sampleNumber,
      required String status,
      required String measurementMethod,
      required double litersPerPulse,
      required double evidenceStepLiters,
      required double readingUncertaintyLiters,
      required String flowPointCode,
      required double mpePct,
      Value<double?> lpsApprox,
      required double litersPerOdometerUnit,
      required double needleLitersPerRevolution,
      required int createdAtMs,
      required int updatedAtMs,
      Value<int?> startedAtMs,
      Value<int?> endedAtMs,
      Value<double?> gpsLatitude,
      Value<double?> gpsLongitude,
      Value<double?> gpsAccuracyMeters,
      Value<int?> gpsCapturedAtMs,
      Value<int> pulseCount,
      Value<double?> progressReferenceLiters,
      Value<double?> initialOdometerUnits,
      Value<double?> initialNeedleLiters,
      Value<String?> initialReadingSource,
      Value<double?> finalOdometerUnits,
      Value<double?> finalNeedleLiters,
      Value<String?> finalReadingSource,
      Value<double?> referenceLiters,
      Value<double?> indicatedLiters,
      Value<double?> errorPct,
      Value<double?> uncertaintyPct,
      Value<double?> resultMpePct,
      Value<double?> acceptanceMetricPct,
      Value<double?> rejectionMetricPct,
      Value<String?> verdict,
      Value<String?> checksum,
      Value<int> rowid,
    });
typedef $$SamplesTableUpdateCompanionBuilder =
    SamplesCompanion Function({
      Value<String> id,
      Value<String> flowPointId,
      Value<int> sampleNumber,
      Value<String> status,
      Value<String> measurementMethod,
      Value<double> litersPerPulse,
      Value<double> evidenceStepLiters,
      Value<double> readingUncertaintyLiters,
      Value<String> flowPointCode,
      Value<double> mpePct,
      Value<double?> lpsApprox,
      Value<double> litersPerOdometerUnit,
      Value<double> needleLitersPerRevolution,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int?> startedAtMs,
      Value<int?> endedAtMs,
      Value<double?> gpsLatitude,
      Value<double?> gpsLongitude,
      Value<double?> gpsAccuracyMeters,
      Value<int?> gpsCapturedAtMs,
      Value<int> pulseCount,
      Value<double?> progressReferenceLiters,
      Value<double?> initialOdometerUnits,
      Value<double?> initialNeedleLiters,
      Value<String?> initialReadingSource,
      Value<double?> finalOdometerUnits,
      Value<double?> finalNeedleLiters,
      Value<String?> finalReadingSource,
      Value<double?> referenceLiters,
      Value<double?> indicatedLiters,
      Value<double?> errorPct,
      Value<double?> uncertaintyPct,
      Value<double?> resultMpePct,
      Value<double?> acceptanceMetricPct,
      Value<double?> rejectionMetricPct,
      Value<String?> verdict,
      Value<String?> checksum,
      Value<int> rowid,
    });

final class $$SamplesTableReferences
    extends BaseReferences<_$AppDatabase, $SamplesTable, SampleRow> {
  $$SamplesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FlowPointsTable _flowPointIdTable(_$AppDatabase db) =>
      db.flowPoints.createAlias('samples__flow_point_id__flow_points__id');

  $$FlowPointsTableProcessedTableManager get flowPointId {
    final $_column = $_itemColumn<String>('flow_point_id')!;

    final manager = $$FlowPointsTableTableManager(
      $_db,
      $_db.flowPoints,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_flowPointIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TestPointsTable, List<PointRow>>
  _testPointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.testPoints,
    aliasName: 'samples__id__test_points__sample_id',
  );

  $$TestPointsTableProcessedTableManager get testPointsRefs {
    final manager = $$TestPointsTableTableManager(
      $_db,
      $_db.testPoints,
    ).filter((f) => f.sampleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_testPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EvidenceItemsTable, List<EvidenceRow>>
  _evidenceItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.evidenceItems,
    aliasName: 'samples__id__evidence_items__sample_id',
  );

  $$EvidenceItemsTableProcessedTableManager get evidenceItemsRefs {
    final manager = $$EvidenceItemsTableTableManager(
      $_db,
      $_db.evidenceItems,
    ).filter((f) => f.sampleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_evidenceItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SamplesTableFilterComposer
    extends Composer<_$AppDatabase, $SamplesTable> {
  $$SamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleNumber => $composableBuilder(
    column: $table.sampleNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measurementMethod => $composableBuilder(
    column: $table.measurementMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get litersPerPulse => $composableBuilder(
    column: $table.litersPerPulse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get evidenceStepLiters => $composableBuilder(
    column: $table.evidenceStepLiters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get readingUncertaintyLiters => $composableBuilder(
    column: $table.readingUncertaintyLiters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flowPointCode => $composableBuilder(
    column: $table.flowPointCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get mpePct => $composableBuilder(
    column: $table.mpePct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lpsApprox => $composableBuilder(
    column: $table.lpsApprox,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get litersPerOdometerUnit => $composableBuilder(
    column: $table.litersPerOdometerUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get needleLitersPerRevolution => $composableBuilder(
    column: $table.needleLitersPerRevolution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAtMs => $composableBuilder(
    column: $table.endedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gpsLatitude => $composableBuilder(
    column: $table.gpsLatitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gpsLongitude => $composableBuilder(
    column: $table.gpsLongitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gpsAccuracyMeters => $composableBuilder(
    column: $table.gpsAccuracyMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gpsCapturedAtMs => $composableBuilder(
    column: $table.gpsCapturedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pulseCount => $composableBuilder(
    column: $table.pulseCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progressReferenceLiters => $composableBuilder(
    column: $table.progressReferenceLiters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get initialOdometerUnits => $composableBuilder(
    column: $table.initialOdometerUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get initialNeedleLiters => $composableBuilder(
    column: $table.initialNeedleLiters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get initialReadingSource => $composableBuilder(
    column: $table.initialReadingSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get finalOdometerUnits => $composableBuilder(
    column: $table.finalOdometerUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get finalNeedleLiters => $composableBuilder(
    column: $table.finalNeedleLiters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finalReadingSource => $composableBuilder(
    column: $table.finalReadingSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get referenceLiters => $composableBuilder(
    column: $table.referenceLiters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get indicatedLiters => $composableBuilder(
    column: $table.indicatedLiters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get errorPct => $composableBuilder(
    column: $table.errorPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get uncertaintyPct => $composableBuilder(
    column: $table.uncertaintyPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get resultMpePct => $composableBuilder(
    column: $table.resultMpePct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get acceptanceMetricPct => $composableBuilder(
    column: $table.acceptanceMetricPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rejectionMetricPct => $composableBuilder(
    column: $table.rejectionMetricPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verdict => $composableBuilder(
    column: $table.verdict,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  $$FlowPointsTableFilterComposer get flowPointId {
    final $$FlowPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flowPointId,
      referencedTable: $db.flowPoints,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlowPointsTableFilterComposer(
            $db: $db,
            $table: $db.flowPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> testPointsRefs(
    Expression<bool> Function($$TestPointsTableFilterComposer f) f,
  ) {
    final $$TestPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.testPoints,
      getReferencedColumn: (t) => t.sampleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TestPointsTableFilterComposer(
            $db: $db,
            $table: $db.testPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> evidenceItemsRefs(
    Expression<bool> Function($$EvidenceItemsTableFilterComposer f) f,
  ) {
    final $$EvidenceItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.evidenceItems,
      getReferencedColumn: (t) => t.sampleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceItemsTableFilterComposer(
            $db: $db,
            $table: $db.evidenceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $SamplesTable> {
  $$SamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleNumber => $composableBuilder(
    column: $table.sampleNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get measurementMethod => $composableBuilder(
    column: $table.measurementMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get litersPerPulse => $composableBuilder(
    column: $table.litersPerPulse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get evidenceStepLiters => $composableBuilder(
    column: $table.evidenceStepLiters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get readingUncertaintyLiters => $composableBuilder(
    column: $table.readingUncertaintyLiters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flowPointCode => $composableBuilder(
    column: $table.flowPointCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get mpePct => $composableBuilder(
    column: $table.mpePct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lpsApprox => $composableBuilder(
    column: $table.lpsApprox,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get litersPerOdometerUnit => $composableBuilder(
    column: $table.litersPerOdometerUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get needleLitersPerRevolution => $composableBuilder(
    column: $table.needleLitersPerRevolution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAtMs => $composableBuilder(
    column: $table.endedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gpsLatitude => $composableBuilder(
    column: $table.gpsLatitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gpsLongitude => $composableBuilder(
    column: $table.gpsLongitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gpsAccuracyMeters => $composableBuilder(
    column: $table.gpsAccuracyMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gpsCapturedAtMs => $composableBuilder(
    column: $table.gpsCapturedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pulseCount => $composableBuilder(
    column: $table.pulseCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progressReferenceLiters => $composableBuilder(
    column: $table.progressReferenceLiters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get initialOdometerUnits => $composableBuilder(
    column: $table.initialOdometerUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get initialNeedleLiters => $composableBuilder(
    column: $table.initialNeedleLiters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get initialReadingSource => $composableBuilder(
    column: $table.initialReadingSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get finalOdometerUnits => $composableBuilder(
    column: $table.finalOdometerUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get finalNeedleLiters => $composableBuilder(
    column: $table.finalNeedleLiters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finalReadingSource => $composableBuilder(
    column: $table.finalReadingSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get referenceLiters => $composableBuilder(
    column: $table.referenceLiters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get indicatedLiters => $composableBuilder(
    column: $table.indicatedLiters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get errorPct => $composableBuilder(
    column: $table.errorPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get uncertaintyPct => $composableBuilder(
    column: $table.uncertaintyPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get resultMpePct => $composableBuilder(
    column: $table.resultMpePct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get acceptanceMetricPct => $composableBuilder(
    column: $table.acceptanceMetricPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rejectionMetricPct => $composableBuilder(
    column: $table.rejectionMetricPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verdict => $composableBuilder(
    column: $table.verdict,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  $$FlowPointsTableOrderingComposer get flowPointId {
    final $$FlowPointsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flowPointId,
      referencedTable: $db.flowPoints,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlowPointsTableOrderingComposer(
            $db: $db,
            $table: $db.flowPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SamplesTable> {
  $$SamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sampleNumber => $composableBuilder(
    column: $table.sampleNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get measurementMethod => $composableBuilder(
    column: $table.measurementMethod,
    builder: (column) => column,
  );

  GeneratedColumn<double> get litersPerPulse => $composableBuilder(
    column: $table.litersPerPulse,
    builder: (column) => column,
  );

  GeneratedColumn<double> get evidenceStepLiters => $composableBuilder(
    column: $table.evidenceStepLiters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get readingUncertaintyLiters => $composableBuilder(
    column: $table.readingUncertaintyLiters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get flowPointCode => $composableBuilder(
    column: $table.flowPointCode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get mpePct =>
      $composableBuilder(column: $table.mpePct, builder: (column) => column);

  GeneratedColumn<double> get lpsApprox =>
      $composableBuilder(column: $table.lpsApprox, builder: (column) => column);

  GeneratedColumn<double> get litersPerOdometerUnit => $composableBuilder(
    column: $table.litersPerOdometerUnit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get needleLitersPerRevolution => $composableBuilder(
    column: $table.needleLitersPerRevolution,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endedAtMs =>
      $composableBuilder(column: $table.endedAtMs, builder: (column) => column);

  GeneratedColumn<double> get gpsLatitude => $composableBuilder(
    column: $table.gpsLatitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get gpsLongitude => $composableBuilder(
    column: $table.gpsLongitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get gpsAccuracyMeters => $composableBuilder(
    column: $table.gpsAccuracyMeters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get gpsCapturedAtMs => $composableBuilder(
    column: $table.gpsCapturedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pulseCount => $composableBuilder(
    column: $table.pulseCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get progressReferenceLiters => $composableBuilder(
    column: $table.progressReferenceLiters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get initialOdometerUnits => $composableBuilder(
    column: $table.initialOdometerUnits,
    builder: (column) => column,
  );

  GeneratedColumn<double> get initialNeedleLiters => $composableBuilder(
    column: $table.initialNeedleLiters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get initialReadingSource => $composableBuilder(
    column: $table.initialReadingSource,
    builder: (column) => column,
  );

  GeneratedColumn<double> get finalOdometerUnits => $composableBuilder(
    column: $table.finalOdometerUnits,
    builder: (column) => column,
  );

  GeneratedColumn<double> get finalNeedleLiters => $composableBuilder(
    column: $table.finalNeedleLiters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get finalReadingSource => $composableBuilder(
    column: $table.finalReadingSource,
    builder: (column) => column,
  );

  GeneratedColumn<double> get referenceLiters => $composableBuilder(
    column: $table.referenceLiters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get indicatedLiters => $composableBuilder(
    column: $table.indicatedLiters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get errorPct =>
      $composableBuilder(column: $table.errorPct, builder: (column) => column);

  GeneratedColumn<double> get uncertaintyPct => $composableBuilder(
    column: $table.uncertaintyPct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get resultMpePct => $composableBuilder(
    column: $table.resultMpePct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get acceptanceMetricPct => $composableBuilder(
    column: $table.acceptanceMetricPct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rejectionMetricPct => $composableBuilder(
    column: $table.rejectionMetricPct,
    builder: (column) => column,
  );

  GeneratedColumn<String> get verdict =>
      $composableBuilder(column: $table.verdict, builder: (column) => column);

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  $$FlowPointsTableAnnotationComposer get flowPointId {
    final $$FlowPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.flowPointId,
      referencedTable: $db.flowPoints,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlowPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.flowPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> testPointsRefs<T extends Object>(
    Expression<T> Function($$TestPointsTableAnnotationComposer a) f,
  ) {
    final $$TestPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.testPoints,
      getReferencedColumn: (t) => t.sampleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TestPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.testPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> evidenceItemsRefs<T extends Object>(
    Expression<T> Function($$EvidenceItemsTableAnnotationComposer a) f,
  ) {
    final $$EvidenceItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.evidenceItems,
      getReferencedColumn: (t) => t.sampleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.evidenceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SamplesTable,
          SampleRow,
          $$SamplesTableFilterComposer,
          $$SamplesTableOrderingComposer,
          $$SamplesTableAnnotationComposer,
          $$SamplesTableCreateCompanionBuilder,
          $$SamplesTableUpdateCompanionBuilder,
          (SampleRow, $$SamplesTableReferences),
          SampleRow,
          PrefetchHooks Function({
            bool flowPointId,
            bool testPointsRefs,
            bool evidenceItemsRefs,
          })
        > {
  $$SamplesTableTableManager(_$AppDatabase db, $SamplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> flowPointId = const Value.absent(),
                Value<int> sampleNumber = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> measurementMethod = const Value.absent(),
                Value<double> litersPerPulse = const Value.absent(),
                Value<double> evidenceStepLiters = const Value.absent(),
                Value<double> readingUncertaintyLiters = const Value.absent(),
                Value<String> flowPointCode = const Value.absent(),
                Value<double> mpePct = const Value.absent(),
                Value<double?> lpsApprox = const Value.absent(),
                Value<double> litersPerOdometerUnit = const Value.absent(),
                Value<double> needleLitersPerRevolution = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int?> startedAtMs = const Value.absent(),
                Value<int?> endedAtMs = const Value.absent(),
                Value<double?> gpsLatitude = const Value.absent(),
                Value<double?> gpsLongitude = const Value.absent(),
                Value<double?> gpsAccuracyMeters = const Value.absent(),
                Value<int?> gpsCapturedAtMs = const Value.absent(),
                Value<int> pulseCount = const Value.absent(),
                Value<double?> progressReferenceLiters = const Value.absent(),
                Value<double?> initialOdometerUnits = const Value.absent(),
                Value<double?> initialNeedleLiters = const Value.absent(),
                Value<String?> initialReadingSource = const Value.absent(),
                Value<double?> finalOdometerUnits = const Value.absent(),
                Value<double?> finalNeedleLiters = const Value.absent(),
                Value<String?> finalReadingSource = const Value.absent(),
                Value<double?> referenceLiters = const Value.absent(),
                Value<double?> indicatedLiters = const Value.absent(),
                Value<double?> errorPct = const Value.absent(),
                Value<double?> uncertaintyPct = const Value.absent(),
                Value<double?> resultMpePct = const Value.absent(),
                Value<double?> acceptanceMetricPct = const Value.absent(),
                Value<double?> rejectionMetricPct = const Value.absent(),
                Value<String?> verdict = const Value.absent(),
                Value<String?> checksum = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SamplesCompanion(
                id: id,
                flowPointId: flowPointId,
                sampleNumber: sampleNumber,
                status: status,
                measurementMethod: measurementMethod,
                litersPerPulse: litersPerPulse,
                evidenceStepLiters: evidenceStepLiters,
                readingUncertaintyLiters: readingUncertaintyLiters,
                flowPointCode: flowPointCode,
                mpePct: mpePct,
                lpsApprox: lpsApprox,
                litersPerOdometerUnit: litersPerOdometerUnit,
                needleLitersPerRevolution: needleLitersPerRevolution,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                startedAtMs: startedAtMs,
                endedAtMs: endedAtMs,
                gpsLatitude: gpsLatitude,
                gpsLongitude: gpsLongitude,
                gpsAccuracyMeters: gpsAccuracyMeters,
                gpsCapturedAtMs: gpsCapturedAtMs,
                pulseCount: pulseCount,
                progressReferenceLiters: progressReferenceLiters,
                initialOdometerUnits: initialOdometerUnits,
                initialNeedleLiters: initialNeedleLiters,
                initialReadingSource: initialReadingSource,
                finalOdometerUnits: finalOdometerUnits,
                finalNeedleLiters: finalNeedleLiters,
                finalReadingSource: finalReadingSource,
                referenceLiters: referenceLiters,
                indicatedLiters: indicatedLiters,
                errorPct: errorPct,
                uncertaintyPct: uncertaintyPct,
                resultMpePct: resultMpePct,
                acceptanceMetricPct: acceptanceMetricPct,
                rejectionMetricPct: rejectionMetricPct,
                verdict: verdict,
                checksum: checksum,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String flowPointId,
                required int sampleNumber,
                required String status,
                required String measurementMethod,
                required double litersPerPulse,
                required double evidenceStepLiters,
                required double readingUncertaintyLiters,
                required String flowPointCode,
                required double mpePct,
                Value<double?> lpsApprox = const Value.absent(),
                required double litersPerOdometerUnit,
                required double needleLitersPerRevolution,
                required int createdAtMs,
                required int updatedAtMs,
                Value<int?> startedAtMs = const Value.absent(),
                Value<int?> endedAtMs = const Value.absent(),
                Value<double?> gpsLatitude = const Value.absent(),
                Value<double?> gpsLongitude = const Value.absent(),
                Value<double?> gpsAccuracyMeters = const Value.absent(),
                Value<int?> gpsCapturedAtMs = const Value.absent(),
                Value<int> pulseCount = const Value.absent(),
                Value<double?> progressReferenceLiters = const Value.absent(),
                Value<double?> initialOdometerUnits = const Value.absent(),
                Value<double?> initialNeedleLiters = const Value.absent(),
                Value<String?> initialReadingSource = const Value.absent(),
                Value<double?> finalOdometerUnits = const Value.absent(),
                Value<double?> finalNeedleLiters = const Value.absent(),
                Value<String?> finalReadingSource = const Value.absent(),
                Value<double?> referenceLiters = const Value.absent(),
                Value<double?> indicatedLiters = const Value.absent(),
                Value<double?> errorPct = const Value.absent(),
                Value<double?> uncertaintyPct = const Value.absent(),
                Value<double?> resultMpePct = const Value.absent(),
                Value<double?> acceptanceMetricPct = const Value.absent(),
                Value<double?> rejectionMetricPct = const Value.absent(),
                Value<String?> verdict = const Value.absent(),
                Value<String?> checksum = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SamplesCompanion.insert(
                id: id,
                flowPointId: flowPointId,
                sampleNumber: sampleNumber,
                status: status,
                measurementMethod: measurementMethod,
                litersPerPulse: litersPerPulse,
                evidenceStepLiters: evidenceStepLiters,
                readingUncertaintyLiters: readingUncertaintyLiters,
                flowPointCode: flowPointCode,
                mpePct: mpePct,
                lpsApprox: lpsApprox,
                litersPerOdometerUnit: litersPerOdometerUnit,
                needleLitersPerRevolution: needleLitersPerRevolution,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                startedAtMs: startedAtMs,
                endedAtMs: endedAtMs,
                gpsLatitude: gpsLatitude,
                gpsLongitude: gpsLongitude,
                gpsAccuracyMeters: gpsAccuracyMeters,
                gpsCapturedAtMs: gpsCapturedAtMs,
                pulseCount: pulseCount,
                progressReferenceLiters: progressReferenceLiters,
                initialOdometerUnits: initialOdometerUnits,
                initialNeedleLiters: initialNeedleLiters,
                initialReadingSource: initialReadingSource,
                finalOdometerUnits: finalOdometerUnits,
                finalNeedleLiters: finalNeedleLiters,
                finalReadingSource: finalReadingSource,
                referenceLiters: referenceLiters,
                indicatedLiters: indicatedLiters,
                errorPct: errorPct,
                uncertaintyPct: uncertaintyPct,
                resultMpePct: resultMpePct,
                acceptanceMetricPct: acceptanceMetricPct,
                rejectionMetricPct: rejectionMetricPct,
                verdict: verdict,
                checksum: checksum,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SamplesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                flowPointId = false,
                testPointsRefs = false,
                evidenceItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (testPointsRefs) db.testPoints,
                    if (evidenceItemsRefs) db.evidenceItems,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (flowPointId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.flowPointId,
                                    referencedTable: $$SamplesTableReferences
                                        ._flowPointIdTable(db),
                                    referencedColumn: $$SamplesTableReferences
                                        ._flowPointIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (testPointsRefs)
                        await $_getPrefetchedData<
                          SampleRow,
                          $SamplesTable,
                          PointRow
                        >(
                          currentTable: table,
                          referencedTable: $$SamplesTableReferences
                              ._testPointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SamplesTableReferences(
                                db,
                                table,
                                p0,
                              ).testPointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sampleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (evidenceItemsRefs)
                        await $_getPrefetchedData<
                          SampleRow,
                          $SamplesTable,
                          EvidenceRow
                        >(
                          currentTable: table,
                          referencedTable: $$SamplesTableReferences
                              ._evidenceItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SamplesTableReferences(
                                db,
                                table,
                                p0,
                              ).evidenceItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sampleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SamplesTable,
      SampleRow,
      $$SamplesTableFilterComposer,
      $$SamplesTableOrderingComposer,
      $$SamplesTableAnnotationComposer,
      $$SamplesTableCreateCompanionBuilder,
      $$SamplesTableUpdateCompanionBuilder,
      (SampleRow, $$SamplesTableReferences),
      SampleRow,
      PrefetchHooks Function({
        bool flowPointId,
        bool testPointsRefs,
        bool evidenceItemsRefs,
      })
    >;
typedef $$TestPointsTableCreateCompanionBuilder =
    TestPointsCompanion Function({
      required String id,
      required String sampleId,
      required String type,
      Value<int?> pulseCount,
      Value<double?> referenceLiters,
      Value<double?> readingLiters,
      Value<double?> indicatedLiters,
      Value<double?> diagnosticErrorPct,
      Value<double?> needleLiters,
      required int capturedAtMs,
      Value<int> rowid,
    });
typedef $$TestPointsTableUpdateCompanionBuilder =
    TestPointsCompanion Function({
      Value<String> id,
      Value<String> sampleId,
      Value<String> type,
      Value<int?> pulseCount,
      Value<double?> referenceLiters,
      Value<double?> readingLiters,
      Value<double?> indicatedLiters,
      Value<double?> diagnosticErrorPct,
      Value<double?> needleLiters,
      Value<int> capturedAtMs,
      Value<int> rowid,
    });

final class $$TestPointsTableReferences
    extends BaseReferences<_$AppDatabase, $TestPointsTable, PointRow> {
  $$TestPointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SamplesTable _sampleIdTable(_$AppDatabase db) =>
      db.samples.createAlias('test_points__sample_id__samples__id');

  $$SamplesTableProcessedTableManager get sampleId {
    final $_column = $_itemColumn<String>('sample_id')!;

    final manager = $$SamplesTableTableManager(
      $_db,
      $_db.samples,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sampleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EvidenceItemsTable, List<EvidenceRow>>
  _evidenceItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.evidenceItems,
    aliasName: 'test_points__id__evidence_items__point_id',
  );

  $$EvidenceItemsTableProcessedTableManager get evidenceItemsRefs {
    final manager = $$EvidenceItemsTableTableManager(
      $_db,
      $_db.evidenceItems,
    ).filter((f) => f.pointId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_evidenceItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TestPointsTableFilterComposer
    extends Composer<_$AppDatabase, $TestPointsTable> {
  $$TestPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pulseCount => $composableBuilder(
    column: $table.pulseCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get referenceLiters => $composableBuilder(
    column: $table.referenceLiters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get readingLiters => $composableBuilder(
    column: $table.readingLiters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get indicatedLiters => $composableBuilder(
    column: $table.indicatedLiters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get diagnosticErrorPct => $composableBuilder(
    column: $table.diagnosticErrorPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get needleLiters => $composableBuilder(
    column: $table.needleLiters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get capturedAtMs => $composableBuilder(
    column: $table.capturedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  $$SamplesTableFilterComposer get sampleId {
    final $$SamplesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sampleId,
      referencedTable: $db.samples,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SamplesTableFilterComposer(
            $db: $db,
            $table: $db.samples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> evidenceItemsRefs(
    Expression<bool> Function($$EvidenceItemsTableFilterComposer f) f,
  ) {
    final $$EvidenceItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.evidenceItems,
      getReferencedColumn: (t) => t.pointId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceItemsTableFilterComposer(
            $db: $db,
            $table: $db.evidenceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TestPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $TestPointsTable> {
  $$TestPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pulseCount => $composableBuilder(
    column: $table.pulseCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get referenceLiters => $composableBuilder(
    column: $table.referenceLiters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get readingLiters => $composableBuilder(
    column: $table.readingLiters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get indicatedLiters => $composableBuilder(
    column: $table.indicatedLiters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get diagnosticErrorPct => $composableBuilder(
    column: $table.diagnosticErrorPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get needleLiters => $composableBuilder(
    column: $table.needleLiters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capturedAtMs => $composableBuilder(
    column: $table.capturedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$SamplesTableOrderingComposer get sampleId {
    final $$SamplesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sampleId,
      referencedTable: $db.samples,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SamplesTableOrderingComposer(
            $db: $db,
            $table: $db.samples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TestPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TestPointsTable> {
  $$TestPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get pulseCount => $composableBuilder(
    column: $table.pulseCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get referenceLiters => $composableBuilder(
    column: $table.referenceLiters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get readingLiters => $composableBuilder(
    column: $table.readingLiters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get indicatedLiters => $composableBuilder(
    column: $table.indicatedLiters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get diagnosticErrorPct => $composableBuilder(
    column: $table.diagnosticErrorPct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get needleLiters => $composableBuilder(
    column: $table.needleLiters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get capturedAtMs => $composableBuilder(
    column: $table.capturedAtMs,
    builder: (column) => column,
  );

  $$SamplesTableAnnotationComposer get sampleId {
    final $$SamplesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sampleId,
      referencedTable: $db.samples,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SamplesTableAnnotationComposer(
            $db: $db,
            $table: $db.samples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> evidenceItemsRefs<T extends Object>(
    Expression<T> Function($$EvidenceItemsTableAnnotationComposer a) f,
  ) {
    final $$EvidenceItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.evidenceItems,
      getReferencedColumn: (t) => t.pointId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EvidenceItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.evidenceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TestPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TestPointsTable,
          PointRow,
          $$TestPointsTableFilterComposer,
          $$TestPointsTableOrderingComposer,
          $$TestPointsTableAnnotationComposer,
          $$TestPointsTableCreateCompanionBuilder,
          $$TestPointsTableUpdateCompanionBuilder,
          (PointRow, $$TestPointsTableReferences),
          PointRow,
          PrefetchHooks Function({bool sampleId, bool evidenceItemsRefs})
        > {
  $$TestPointsTableTableManager(_$AppDatabase db, $TestPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TestPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TestPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TestPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sampleId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int?> pulseCount = const Value.absent(),
                Value<double?> referenceLiters = const Value.absent(),
                Value<double?> readingLiters = const Value.absent(),
                Value<double?> indicatedLiters = const Value.absent(),
                Value<double?> diagnosticErrorPct = const Value.absent(),
                Value<double?> needleLiters = const Value.absent(),
                Value<int> capturedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TestPointsCompanion(
                id: id,
                sampleId: sampleId,
                type: type,
                pulseCount: pulseCount,
                referenceLiters: referenceLiters,
                readingLiters: readingLiters,
                indicatedLiters: indicatedLiters,
                diagnosticErrorPct: diagnosticErrorPct,
                needleLiters: needleLiters,
                capturedAtMs: capturedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sampleId,
                required String type,
                Value<int?> pulseCount = const Value.absent(),
                Value<double?> referenceLiters = const Value.absent(),
                Value<double?> readingLiters = const Value.absent(),
                Value<double?> indicatedLiters = const Value.absent(),
                Value<double?> diagnosticErrorPct = const Value.absent(),
                Value<double?> needleLiters = const Value.absent(),
                required int capturedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => TestPointsCompanion.insert(
                id: id,
                sampleId: sampleId,
                type: type,
                pulseCount: pulseCount,
                referenceLiters: referenceLiters,
                readingLiters: readingLiters,
                indicatedLiters: indicatedLiters,
                diagnosticErrorPct: diagnosticErrorPct,
                needleLiters: needleLiters,
                capturedAtMs: capturedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TestPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sampleId = false, evidenceItemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (evidenceItemsRefs) db.evidenceItems,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sampleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sampleId,
                                    referencedTable: $$TestPointsTableReferences
                                        ._sampleIdTable(db),
                                    referencedColumn:
                                        $$TestPointsTableReferences
                                            ._sampleIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (evidenceItemsRefs)
                        await $_getPrefetchedData<
                          PointRow,
                          $TestPointsTable,
                          EvidenceRow
                        >(
                          currentTable: table,
                          referencedTable: $$TestPointsTableReferences
                              ._evidenceItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TestPointsTableReferences(
                                db,
                                table,
                                p0,
                              ).evidenceItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.pointId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TestPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TestPointsTable,
      PointRow,
      $$TestPointsTableFilterComposer,
      $$TestPointsTableOrderingComposer,
      $$TestPointsTableAnnotationComposer,
      $$TestPointsTableCreateCompanionBuilder,
      $$TestPointsTableUpdateCompanionBuilder,
      (PointRow, $$TestPointsTableReferences),
      PointRow,
      PrefetchHooks Function({bool sampleId, bool evidenceItemsRefs})
    >;
typedef $$EvidenceItemsTableCreateCompanionBuilder =
    EvidenceItemsCompanion Function({
      required String id,
      required String sampleId,
      Value<String?> pointId,
      required String type,
      required bool required,
      Value<double?> volumeRefLiters,
      Value<int?> pulseCount,
      required int capturedAtMs,
      Value<String?> sha256,
      required String localPath,
      Value<String?> serverStorageKey,
      required String syncStatus,
      Value<int> rowid,
    });
typedef $$EvidenceItemsTableUpdateCompanionBuilder =
    EvidenceItemsCompanion Function({
      Value<String> id,
      Value<String> sampleId,
      Value<String?> pointId,
      Value<String> type,
      Value<bool> required,
      Value<double?> volumeRefLiters,
      Value<int?> pulseCount,
      Value<int> capturedAtMs,
      Value<String?> sha256,
      Value<String> localPath,
      Value<String?> serverStorageKey,
      Value<String> syncStatus,
      Value<int> rowid,
    });

final class $$EvidenceItemsTableReferences
    extends BaseReferences<_$AppDatabase, $EvidenceItemsTable, EvidenceRow> {
  $$EvidenceItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SamplesTable _sampleIdTable(_$AppDatabase db) =>
      db.samples.createAlias('evidence_items__sample_id__samples__id');

  $$SamplesTableProcessedTableManager get sampleId {
    final $_column = $_itemColumn<String>('sample_id')!;

    final manager = $$SamplesTableTableManager(
      $_db,
      $_db.samples,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sampleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TestPointsTable _pointIdTable(_$AppDatabase db) =>
      db.testPoints.createAlias('evidence_items__point_id__test_points__id');

  $$TestPointsTableProcessedTableManager? get pointId {
    final $_column = $_itemColumn<String>('point_id');
    if ($_column == null) return null;
    final manager = $$TestPointsTableTableManager(
      $_db,
      $_db.testPoints,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pointIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EvidenceItemsTableFilterComposer
    extends Composer<_$AppDatabase, $EvidenceItemsTable> {
  $$EvidenceItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get required => $composableBuilder(
    column: $table.required,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get volumeRefLiters => $composableBuilder(
    column: $table.volumeRefLiters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pulseCount => $composableBuilder(
    column: $table.pulseCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get capturedAtMs => $composableBuilder(
    column: $table.capturedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverStorageKey => $composableBuilder(
    column: $table.serverStorageKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  $$SamplesTableFilterComposer get sampleId {
    final $$SamplesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sampleId,
      referencedTable: $db.samples,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SamplesTableFilterComposer(
            $db: $db,
            $table: $db.samples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TestPointsTableFilterComposer get pointId {
    final $$TestPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pointId,
      referencedTable: $db.testPoints,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TestPointsTableFilterComposer(
            $db: $db,
            $table: $db.testPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvidenceItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $EvidenceItemsTable> {
  $$EvidenceItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get required => $composableBuilder(
    column: $table.required,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get volumeRefLiters => $composableBuilder(
    column: $table.volumeRefLiters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pulseCount => $composableBuilder(
    column: $table.pulseCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capturedAtMs => $composableBuilder(
    column: $table.capturedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverStorageKey => $composableBuilder(
    column: $table.serverStorageKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$SamplesTableOrderingComposer get sampleId {
    final $$SamplesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sampleId,
      referencedTable: $db.samples,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SamplesTableOrderingComposer(
            $db: $db,
            $table: $db.samples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TestPointsTableOrderingComposer get pointId {
    final $$TestPointsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pointId,
      referencedTable: $db.testPoints,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TestPointsTableOrderingComposer(
            $db: $db,
            $table: $db.testPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvidenceItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EvidenceItemsTable> {
  $$EvidenceItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get required =>
      $composableBuilder(column: $table.required, builder: (column) => column);

  GeneratedColumn<double> get volumeRefLiters => $composableBuilder(
    column: $table.volumeRefLiters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pulseCount => $composableBuilder(
    column: $table.pulseCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get capturedAtMs => $composableBuilder(
    column: $table.capturedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get serverStorageKey => $composableBuilder(
    column: $table.serverStorageKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  $$SamplesTableAnnotationComposer get sampleId {
    final $$SamplesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sampleId,
      referencedTable: $db.samples,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SamplesTableAnnotationComposer(
            $db: $db,
            $table: $db.samples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TestPointsTableAnnotationComposer get pointId {
    final $$TestPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pointId,
      referencedTable: $db.testPoints,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TestPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.testPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EvidenceItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EvidenceItemsTable,
          EvidenceRow,
          $$EvidenceItemsTableFilterComposer,
          $$EvidenceItemsTableOrderingComposer,
          $$EvidenceItemsTableAnnotationComposer,
          $$EvidenceItemsTableCreateCompanionBuilder,
          $$EvidenceItemsTableUpdateCompanionBuilder,
          (EvidenceRow, $$EvidenceItemsTableReferences),
          EvidenceRow,
          PrefetchHooks Function({bool sampleId, bool pointId})
        > {
  $$EvidenceItemsTableTableManager(_$AppDatabase db, $EvidenceItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EvidenceItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EvidenceItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EvidenceItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sampleId = const Value.absent(),
                Value<String?> pointId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<bool> required = const Value.absent(),
                Value<double?> volumeRefLiters = const Value.absent(),
                Value<int?> pulseCount = const Value.absent(),
                Value<int> capturedAtMs = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<String?> serverStorageKey = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EvidenceItemsCompanion(
                id: id,
                sampleId: sampleId,
                pointId: pointId,
                type: type,
                required: required,
                volumeRefLiters: volumeRefLiters,
                pulseCount: pulseCount,
                capturedAtMs: capturedAtMs,
                sha256: sha256,
                localPath: localPath,
                serverStorageKey: serverStorageKey,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sampleId,
                Value<String?> pointId = const Value.absent(),
                required String type,
                required bool required,
                Value<double?> volumeRefLiters = const Value.absent(),
                Value<int?> pulseCount = const Value.absent(),
                required int capturedAtMs,
                Value<String?> sha256 = const Value.absent(),
                required String localPath,
                Value<String?> serverStorageKey = const Value.absent(),
                required String syncStatus,
                Value<int> rowid = const Value.absent(),
              }) => EvidenceItemsCompanion.insert(
                id: id,
                sampleId: sampleId,
                pointId: pointId,
                type: type,
                required: required,
                volumeRefLiters: volumeRefLiters,
                pulseCount: pulseCount,
                capturedAtMs: capturedAtMs,
                sha256: sha256,
                localPath: localPath,
                serverStorageKey: serverStorageKey,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EvidenceItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sampleId = false, pointId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sampleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sampleId,
                                referencedTable: $$EvidenceItemsTableReferences
                                    ._sampleIdTable(db),
                                referencedColumn: $$EvidenceItemsTableReferences
                                    ._sampleIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (pointId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.pointId,
                                referencedTable: $$EvidenceItemsTableReferences
                                    ._pointIdTable(db),
                                referencedColumn: $$EvidenceItemsTableReferences
                                    ._pointIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EvidenceItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EvidenceItemsTable,
      EvidenceRow,
      $$EvidenceItemsTableFilterComposer,
      $$EvidenceItemsTableOrderingComposer,
      $$EvidenceItemsTableAnnotationComposer,
      $$EvidenceItemsTableCreateCompanionBuilder,
      $$EvidenceItemsTableUpdateCompanionBuilder,
      (EvidenceRow, $$EvidenceItemsTableReferences),
      EvidenceRow,
      PrefetchHooks Function({bool sampleId, bool pointId})
    >;
typedef $$SyncItemsTableCreateCompanionBuilder =
    SyncItemsCompanion Function({
      required String id,
      required String entityType,
      required String entityId,
      required String checksum,
      required String state,
      Value<int> attempts,
      Value<String?> lastError,
      required int createdAtMs,
      required int updatedAtMs,
      Value<int?> nextRetryAtMs,
      Value<int> rowid,
    });
typedef $$SyncItemsTableUpdateCompanionBuilder =
    SyncItemsCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> checksum,
      Value<String> state,
      Value<int> attempts,
      Value<String?> lastError,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int?> nextRetryAtMs,
      Value<int> rowid,
    });

class $$SyncItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncItemsTable> {
  $$SyncItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextRetryAtMs => $composableBuilder(
    column: $table.nextRetryAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncItemsTable> {
  $$SyncItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextRetryAtMs => $composableBuilder(
    column: $table.nextRetryAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncItemsTable> {
  $$SyncItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextRetryAtMs => $composableBuilder(
    column: $table.nextRetryAtMs,
    builder: (column) => column,
  );
}

class $$SyncItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncItemsTable,
          SyncItemRow,
          $$SyncItemsTableFilterComposer,
          $$SyncItemsTableOrderingComposer,
          $$SyncItemsTableAnnotationComposer,
          $$SyncItemsTableCreateCompanionBuilder,
          $$SyncItemsTableUpdateCompanionBuilder,
          (
            SyncItemRow,
            BaseReferences<_$AppDatabase, $SyncItemsTable, SyncItemRow>,
          ),
          SyncItemRow,
          PrefetchHooks Function()
        > {
  $$SyncItemsTableTableManager(_$AppDatabase db, $SyncItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> checksum = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int?> nextRetryAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncItemsCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                checksum: checksum,
                state: state,
                attempts: attempts,
                lastError: lastError,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                nextRetryAtMs: nextRetryAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String entityId,
                required String checksum,
                required String state,
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required int createdAtMs,
                required int updatedAtMs,
                Value<int?> nextRetryAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncItemsCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                checksum: checksum,
                state: state,
                attempts: attempts,
                lastError: lastError,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                nextRetryAtMs: nextRetryAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncItemsTable,
      SyncItemRow,
      $$SyncItemsTableFilterComposer,
      $$SyncItemsTableOrderingComposer,
      $$SyncItemsTableAnnotationComposer,
      $$SyncItemsTableCreateCompanionBuilder,
      $$SyncItemsTableUpdateCompanionBuilder,
      (
        SyncItemRow,
        BaseReferences<_$AppDatabase, $SyncItemsTable, SyncItemRow>,
      ),
      SyncItemRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$MetersTableTableManager get meters =>
      $$MetersTableTableManager(_db, _db.meters);
  $$VerificationCasesTableTableManager get verificationCases =>
      $$VerificationCasesTableTableManager(_db, _db.verificationCases);
  $$FlowPointsTableTableManager get flowPoints =>
      $$FlowPointsTableTableManager(_db, _db.flowPoints);
  $$SamplesTableTableManager get samples =>
      $$SamplesTableTableManager(_db, _db.samples);
  $$TestPointsTableTableManager get testPoints =>
      $$TestPointsTableTableManager(_db, _db.testPoints);
  $$EvidenceItemsTableTableManager get evidenceItems =>
      $$EvidenceItemsTableTableManager(_db, _db.evidenceItems);
  $$SyncItemsTableTableManager get syncItems =>
      $$SyncItemsTableTableManager(_db, _db.syncItems);
}
