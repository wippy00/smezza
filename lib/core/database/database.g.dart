// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

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
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarPathMeta = const VerificationMeta(
    'avatarPath',
  );
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
    'avatar_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isMeMeta = const VerificationMeta('isMe');
  @override
  late final GeneratedColumn<bool> isMe = GeneratedColumn<bool>(
    'is_me',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_me" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    isDeleted,
    name,
    avatarPath,
    isMe,
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
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('avatar_path')) {
      context.handle(
        _avatarPathMeta,
        avatarPath.isAcceptableOrUnknown(data['avatar_path']!, _avatarPathMeta),
      );
    }
    if (data.containsKey('is_me')) {
      context.handle(
        _isMeMeta,
        isMe.isAcceptableOrUnknown(data['is_me']!, _isMeMeta),
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
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      avatarPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_path'],
      ),
      isMe: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_me'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String hlc;
  final bool isDeleted;
  final String name;
  final String? avatarPath;
  final bool isMe;
  const User({
    required this.id,
    required this.hlc,
    required this.isDeleted,
    required this.name,
    this.avatarPath,
    required this.isMe,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    map['is_me'] = Variable<bool>(isMe);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
      name: Value(name),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      isMe: Value(isMe),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      name: serializer.fromJson<String>(json['name']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      isMe: serializer.fromJson<bool>(json['isMe']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'name': serializer.toJson<String>(name),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'isMe': serializer.toJson<bool>(isMe),
    };
  }

  User copyWith({
    String? id,
    String? hlc,
    bool? isDeleted,
    String? name,
    Value<String?> avatarPath = const Value.absent(),
    bool? isMe,
  }) => User(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
    name: name ?? this.name,
    avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
    isMe: isMe ?? this.isMe,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      name: data.name.present ? data.name.value : this.name,
      avatarPath: data.avatarPath.present
          ? data.avatarPath.value
          : this.avatarPath,
      isMe: data.isMe.present ? data.isMe.value : this.isMe,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('name: $name, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('isMe: $isMe')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, hlc, isDeleted, name, avatarPath, isMe);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted &&
          other.name == this.name &&
          other.avatarPath == this.avatarPath &&
          other.isMe == this.isMe);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<String> name;
  final Value<String?> avatarPath;
  final Value<bool> isMe;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.isMe = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String hlc,
    this.isDeleted = const Value.absent(),
    required String name,
    this.avatarPath = const Value.absent(),
    this.isMe = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hlc = Value(hlc),
       name = Value(name);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<String>? name,
    Expression<String>? avatarPath,
    Expression<bool>? isMe,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (name != null) 'name': name,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (isMe != null) 'is_me': isMe,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<String>? name,
    Value<String?>? avatarPath,
    Value<bool>? isMe,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      isMe: isMe ?? this.isMe,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (isMe.present) {
      map['is_me'] = Variable<bool>(isMe.value);
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
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('name: $name, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('isMe: $isMe, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupsTable extends Groups with TableInfo<$GroupsTable, Group> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signatureMeta = const VerificationMeta(
    'signature',
  );
  @override
  late final GeneratedColumn<String> signature = GeneratedColumn<String>(
    'signature',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    isDeleted,
    ownerId,
    name,
    description,
    createdAt,
    signature,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<Group> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('signature')) {
      context.handle(
        _signatureMeta,
        signature.isAcceptableOrUnknown(data['signature']!, _signatureMeta),
      );
    } else if (isInserting) {
      context.missing(_signatureMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Group map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Group(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      signature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature'],
      )!,
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }
}

class Group extends DataClass implements Insertable<Group> {
  final String id;
  final String hlc;
  final bool isDeleted;
  final String ownerId;
  final String name;
  final String? description;
  final int createdAt;
  final String signature;
  const Group({
    required this.id,
    required this.hlc,
    required this.isDeleted,
    required this.ownerId,
    required this.name,
    this.description,
    required this.createdAt,
    required this.signature,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['owner_id'] = Variable<String>(ownerId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['signature'] = Variable<String>(signature);
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
      ownerId: Value(ownerId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      signature: Value(signature),
    );
  }

  factory Group.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Group(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      signature: serializer.fromJson<String>(json['signature']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'ownerId': serializer.toJson<String>(ownerId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<int>(createdAt),
      'signature': serializer.toJson<String>(signature),
    };
  }

  Group copyWith({
    String? id,
    String? hlc,
    bool? isDeleted,
    String? ownerId,
    String? name,
    Value<String?> description = const Value.absent(),
    int? createdAt,
    String? signature,
  }) => Group(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
    ownerId: ownerId ?? this.ownerId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    signature: signature ?? this.signature,
  );
  Group copyWithCompanion(GroupsCompanion data) {
    return Group(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      signature: data.signature.present ? data.signature.value : this.signature,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Group(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('signature: $signature')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    isDeleted,
    ownerId,
    name,
    description,
    createdAt,
    signature,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Group &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted &&
          other.ownerId == this.ownerId &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.signature == this.signature);
}

class GroupsCompanion extends UpdateCompanion<Group> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<String> ownerId;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> createdAt;
  final Value<String> signature;
  final Value<int> rowid;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.signature = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupsCompanion.insert({
    required String id,
    required String hlc,
    this.isDeleted = const Value.absent(),
    required String ownerId,
    required String name,
    this.description = const Value.absent(),
    required int createdAt,
    required String signature,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hlc = Value(hlc),
       ownerId = Value(ownerId),
       name = Value(name),
       createdAt = Value(createdAt),
       signature = Value(signature);
  static Insertable<Group> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<String>? ownerId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? createdAt,
    Expression<String>? signature,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (ownerId != null) 'owner_id': ownerId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (signature != null) 'signature': signature,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<String>? ownerId,
    Value<String>? name,
    Value<String?>? description,
    Value<int>? createdAt,
    Value<String>? signature,
    Value<int>? rowid,
  }) {
    return GroupsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      signature: signature ?? this.signature,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (signature.present) {
      map['signature'] = Variable<String>(signature.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('ownerId: $ownerId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('signature: $signature, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupMembersTable extends GroupMembers
    with TableInfo<$GroupMembersTable, GroupMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
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
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorizedByMeta = const VerificationMeta(
    'authorizedBy',
  );
  @override
  late final GeneratedColumn<String> authorizedBy = GeneratedColumn<String>(
    'authorized_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _signatureMeta = const VerificationMeta(
    'signature',
  );
  @override
  late final GeneratedColumn<String> signature = GeneratedColumn<String>(
    'signature',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    isDeleted,
    groupId,
    userId,
    role,
    authorizedBy,
    signature,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('authorized_by')) {
      context.handle(
        _authorizedByMeta,
        authorizedBy.isAcceptableOrUnknown(
          data['authorized_by']!,
          _authorizedByMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authorizedByMeta);
    }
    if (data.containsKey('signature')) {
      context.handle(
        _signatureMeta,
        signature.isAcceptableOrUnknown(data['signature']!, _signatureMeta),
      );
    } else if (isInserting) {
      context.missing(_signatureMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {groupId, userId},
  ];
  @override
  GroupMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupMember(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      authorizedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}authorized_by'],
      )!,
      signature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature'],
      )!,
    );
  }

  @override
  $GroupMembersTable createAlias(String alias) {
    return $GroupMembersTable(attachedDatabase, alias);
  }
}

class GroupMember extends DataClass implements Insertable<GroupMember> {
  final String id;
  final String hlc;
  final bool isDeleted;
  final String groupId;
  final String userId;
  final String role;
  final String authorizedBy;
  final String signature;
  const GroupMember({
    required this.id,
    required this.hlc,
    required this.isDeleted,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.authorizedBy,
    required this.signature,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['group_id'] = Variable<String>(groupId);
    map['user_id'] = Variable<String>(userId);
    map['role'] = Variable<String>(role);
    map['authorized_by'] = Variable<String>(authorizedBy);
    map['signature'] = Variable<String>(signature);
    return map;
  }

  GroupMembersCompanion toCompanion(bool nullToAbsent) {
    return GroupMembersCompanion(
      id: Value(id),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
      groupId: Value(groupId),
      userId: Value(userId),
      role: Value(role),
      authorizedBy: Value(authorizedBy),
      signature: Value(signature),
    );
  }

  factory GroupMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupMember(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      groupId: serializer.fromJson<String>(json['groupId']),
      userId: serializer.fromJson<String>(json['userId']),
      role: serializer.fromJson<String>(json['role']),
      authorizedBy: serializer.fromJson<String>(json['authorizedBy']),
      signature: serializer.fromJson<String>(json['signature']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'groupId': serializer.toJson<String>(groupId),
      'userId': serializer.toJson<String>(userId),
      'role': serializer.toJson<String>(role),
      'authorizedBy': serializer.toJson<String>(authorizedBy),
      'signature': serializer.toJson<String>(signature),
    };
  }

  GroupMember copyWith({
    String? id,
    String? hlc,
    bool? isDeleted,
    String? groupId,
    String? userId,
    String? role,
    String? authorizedBy,
    String? signature,
  }) => GroupMember(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
    groupId: groupId ?? this.groupId,
    userId: userId ?? this.userId,
    role: role ?? this.role,
    authorizedBy: authorizedBy ?? this.authorizedBy,
    signature: signature ?? this.signature,
  );
  GroupMember copyWithCompanion(GroupMembersCompanion data) {
    return GroupMember(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      userId: data.userId.present ? data.userId.value : this.userId,
      role: data.role.present ? data.role.value : this.role,
      authorizedBy: data.authorizedBy.present
          ? data.authorizedBy.value
          : this.authorizedBy,
      signature: data.signature.present ? data.signature.value : this.signature,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupMember(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('authorizedBy: $authorizedBy, ')
          ..write('signature: $signature')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    isDeleted,
    groupId,
    userId,
    role,
    authorizedBy,
    signature,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupMember &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted &&
          other.groupId == this.groupId &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.authorizedBy == this.authorizedBy &&
          other.signature == this.signature);
}

class GroupMembersCompanion extends UpdateCompanion<GroupMember> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<String> groupId;
  final Value<String> userId;
  final Value<String> role;
  final Value<String> authorizedBy;
  final Value<String> signature;
  final Value<int> rowid;
  const GroupMembersCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.groupId = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.authorizedBy = const Value.absent(),
    this.signature = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupMembersCompanion.insert({
    required String id,
    required String hlc,
    this.isDeleted = const Value.absent(),
    required String groupId,
    required String userId,
    required String role,
    required String authorizedBy,
    required String signature,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hlc = Value(hlc),
       groupId = Value(groupId),
       userId = Value(userId),
       role = Value(role),
       authorizedBy = Value(authorizedBy),
       signature = Value(signature);
  static Insertable<GroupMember> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<String>? groupId,
    Expression<String>? userId,
    Expression<String>? role,
    Expression<String>? authorizedBy,
    Expression<String>? signature,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (groupId != null) 'group_id': groupId,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (authorizedBy != null) 'authorized_by': authorizedBy,
      if (signature != null) 'signature': signature,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupMembersCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<String>? groupId,
    Value<String>? userId,
    Value<String>? role,
    Value<String>? authorizedBy,
    Value<String>? signature,
    Value<int>? rowid,
  }) {
    return GroupMembersCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      authorizedBy: authorizedBy ?? this.authorizedBy,
      signature: signature ?? this.signature,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (authorizedBy.present) {
      map['authorized_by'] = Variable<String>(authorizedBy.value);
    }
    if (signature.present) {
      map['signature'] = Variable<String>(signature.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupMembersCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('authorizedBy: $authorizedBy, ')
          ..write('signature: $signature, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _creatorIdMeta = const VerificationMeta(
    'creatorId',
  );
  @override
  late final GeneratedColumn<String> creatorId = GeneratedColumn<String>(
    'creator_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _splitTypeMeta = const VerificationMeta(
    'splitType',
  );
  @override
  late final GeneratedColumn<String> splitType = GeneratedColumn<String>(
    'split_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signatureMeta = const VerificationMeta(
    'signature',
  );
  @override
  late final GeneratedColumn<String> signature = GeneratedColumn<String>(
    'signature',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptPathMeta = const VerificationMeta(
    'receiptPath',
  );
  @override
  late final GeneratedColumn<String> receiptPath = GeneratedColumn<String>(
    'receipt_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    isDeleted,
    groupId,
    creatorId,
    description,
    amount,
    currencyCode,
    date,
    splitType,
    signature,
    receiptPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Expense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('creator_id')) {
      context.handle(
        _creatorIdMeta,
        creatorId.isAcceptableOrUnknown(data['creator_id']!, _creatorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_creatorIdMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('split_type')) {
      context.handle(
        _splitTypeMeta,
        splitType.isAcceptableOrUnknown(data['split_type']!, _splitTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_splitTypeMeta);
    }
    if (data.containsKey('signature')) {
      context.handle(
        _signatureMeta,
        signature.isAcceptableOrUnknown(data['signature']!, _signatureMeta),
      );
    } else if (isInserting) {
      context.missing(_signatureMeta);
    }
    if (data.containsKey('receipt_path')) {
      context.handle(
        _receiptPathMeta,
        receiptPath.isAcceptableOrUnknown(
          data['receipt_path']!,
          _receiptPathMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      creatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_id'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      splitType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}split_type'],
      )!,
      signature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature'],
      )!,
      receiptPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_path'],
      ),
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final String id;
  final String hlc;
  final bool isDeleted;
  final String groupId;
  final String creatorId;
  final String description;
  final double amount;
  final String currencyCode;
  final DateTime date;
  final String splitType;
  final String signature;
  final String? receiptPath;
  const Expense({
    required this.id,
    required this.hlc,
    required this.isDeleted,
    required this.groupId,
    required this.creatorId,
    required this.description,
    required this.amount,
    required this.currencyCode,
    required this.date,
    required this.splitType,
    required this.signature,
    this.receiptPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['group_id'] = Variable<String>(groupId);
    map['creator_id'] = Variable<String>(creatorId);
    map['description'] = Variable<String>(description);
    map['amount'] = Variable<double>(amount);
    map['currency_code'] = Variable<String>(currencyCode);
    map['date'] = Variable<DateTime>(date);
    map['split_type'] = Variable<String>(splitType);
    map['signature'] = Variable<String>(signature);
    if (!nullToAbsent || receiptPath != null) {
      map['receipt_path'] = Variable<String>(receiptPath);
    }
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
      groupId: Value(groupId),
      creatorId: Value(creatorId),
      description: Value(description),
      amount: Value(amount),
      currencyCode: Value(currencyCode),
      date: Value(date),
      splitType: Value(splitType),
      signature: Value(signature),
      receiptPath: receiptPath == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptPath),
    );
  }

  factory Expense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      groupId: serializer.fromJson<String>(json['groupId']),
      creatorId: serializer.fromJson<String>(json['creatorId']),
      description: serializer.fromJson<String>(json['description']),
      amount: serializer.fromJson<double>(json['amount']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      date: serializer.fromJson<DateTime>(json['date']),
      splitType: serializer.fromJson<String>(json['splitType']),
      signature: serializer.fromJson<String>(json['signature']),
      receiptPath: serializer.fromJson<String?>(json['receiptPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'groupId': serializer.toJson<String>(groupId),
      'creatorId': serializer.toJson<String>(creatorId),
      'description': serializer.toJson<String>(description),
      'amount': serializer.toJson<double>(amount),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'date': serializer.toJson<DateTime>(date),
      'splitType': serializer.toJson<String>(splitType),
      'signature': serializer.toJson<String>(signature),
      'receiptPath': serializer.toJson<String?>(receiptPath),
    };
  }

  Expense copyWith({
    String? id,
    String? hlc,
    bool? isDeleted,
    String? groupId,
    String? creatorId,
    String? description,
    double? amount,
    String? currencyCode,
    DateTime? date,
    String? splitType,
    String? signature,
    Value<String?> receiptPath = const Value.absent(),
  }) => Expense(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
    groupId: groupId ?? this.groupId,
    creatorId: creatorId ?? this.creatorId,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    currencyCode: currencyCode ?? this.currencyCode,
    date: date ?? this.date,
    splitType: splitType ?? this.splitType,
    signature: signature ?? this.signature,
    receiptPath: receiptPath.present ? receiptPath.value : this.receiptPath,
  );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      creatorId: data.creatorId.present ? data.creatorId.value : this.creatorId,
      description: data.description.present
          ? data.description.value
          : this.description,
      amount: data.amount.present ? data.amount.value : this.amount,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      date: data.date.present ? data.date.value : this.date,
      splitType: data.splitType.present ? data.splitType.value : this.splitType,
      signature: data.signature.present ? data.signature.value : this.signature,
      receiptPath: data.receiptPath.present
          ? data.receiptPath.value
          : this.receiptPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('groupId: $groupId, ')
          ..write('creatorId: $creatorId, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('date: $date, ')
          ..write('splitType: $splitType, ')
          ..write('signature: $signature, ')
          ..write('receiptPath: $receiptPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    isDeleted,
    groupId,
    creatorId,
    description,
    amount,
    currencyCode,
    date,
    splitType,
    signature,
    receiptPath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted &&
          other.groupId == this.groupId &&
          other.creatorId == this.creatorId &&
          other.description == this.description &&
          other.amount == this.amount &&
          other.currencyCode == this.currencyCode &&
          other.date == this.date &&
          other.splitType == this.splitType &&
          other.signature == this.signature &&
          other.receiptPath == this.receiptPath);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<String> groupId;
  final Value<String> creatorId;
  final Value<String> description;
  final Value<double> amount;
  final Value<String> currencyCode;
  final Value<DateTime> date;
  final Value<String> splitType;
  final Value<String> signature;
  final Value<String?> receiptPath;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.groupId = const Value.absent(),
    this.creatorId = const Value.absent(),
    this.description = const Value.absent(),
    this.amount = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.date = const Value.absent(),
    this.splitType = const Value.absent(),
    this.signature = const Value.absent(),
    this.receiptPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    required String hlc,
    this.isDeleted = const Value.absent(),
    required String groupId,
    required String creatorId,
    required String description,
    required double amount,
    required String currencyCode,
    required DateTime date,
    required String splitType,
    required String signature,
    this.receiptPath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hlc = Value(hlc),
       groupId = Value(groupId),
       creatorId = Value(creatorId),
       description = Value(description),
       amount = Value(amount),
       currencyCode = Value(currencyCode),
       date = Value(date),
       splitType = Value(splitType),
       signature = Value(signature);
  static Insertable<Expense> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<String>? groupId,
    Expression<String>? creatorId,
    Expression<String>? description,
    Expression<double>? amount,
    Expression<String>? currencyCode,
    Expression<DateTime>? date,
    Expression<String>? splitType,
    Expression<String>? signature,
    Expression<String>? receiptPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (groupId != null) 'group_id': groupId,
      if (creatorId != null) 'creator_id': creatorId,
      if (description != null) 'description': description,
      if (amount != null) 'amount': amount,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (date != null) 'date': date,
      if (splitType != null) 'split_type': splitType,
      if (signature != null) 'signature': signature,
      if (receiptPath != null) 'receipt_path': receiptPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<String>? groupId,
    Value<String>? creatorId,
    Value<String>? description,
    Value<double>? amount,
    Value<String>? currencyCode,
    Value<DateTime>? date,
    Value<String>? splitType,
    Value<String>? signature,
    Value<String?>? receiptPath,
    Value<int>? rowid,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      groupId: groupId ?? this.groupId,
      creatorId: creatorId ?? this.creatorId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      date: date ?? this.date,
      splitType: splitType ?? this.splitType,
      signature: signature ?? this.signature,
      receiptPath: receiptPath ?? this.receiptPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (creatorId.present) {
      map['creator_id'] = Variable<String>(creatorId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (splitType.present) {
      map['split_type'] = Variable<String>(splitType.value);
    }
    if (signature.present) {
      map['signature'] = Variable<String>(signature.value);
    }
    if (receiptPath.present) {
      map['receipt_path'] = Variable<String>(receiptPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('groupId: $groupId, ')
          ..write('creatorId: $creatorId, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('date: $date, ')
          ..write('splitType: $splitType, ')
          ..write('signature: $signature, ')
          ..write('receiptPath: $receiptPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $GroupsTable groups = $GroupsTable(this);
  late final $GroupMembersTable groupMembers = $GroupMembersTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    groups,
    groupMembers,
    expenses,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required String id,
      required String hlc,
      Value<bool> isDeleted,
      required String name,
      Value<String?> avatarPath,
      Value<bool> isMe,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<String> name,
      Value<String?> avatarPath,
      Value<bool> isMe,
      Value<int> rowid,
    });

final class $$UsersTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTable, User> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GroupsTable, List<Group>> _groupsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.groups,
    aliasName: $_aliasNameGenerator(db.users.id, db.groups.ownerId),
  );

  $$GroupsTableProcessedTableManager get groupsRefs {
    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.ownerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_groupsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: $_aliasNameGenerator(db.users.id, db.expenses.creatorId),
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.creatorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMe => $composableBuilder(
    column: $table.isMe,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> groupsRefs(
    Expression<bool> Function($$GroupsTableFilterComposer f) f,
  ) {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.ownerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.creatorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMe => $composableBuilder(
    column: $table.isMe,
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

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isMe =>
      $composableBuilder(column: $table.isMe, builder: (column) => column);

  Expression<T> groupsRefs<T extends Object>(
    Expression<T> Function($$GroupsTableAnnotationComposer a) f,
  ) {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.ownerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.creatorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
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
          PrefetchHooks Function({bool groupsRefs, bool expensesRefs})
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
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> avatarPath = const Value.absent(),
                Value<bool> isMe = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                hlc: hlc,
                isDeleted: isDeleted,
                name: name,
                avatarPath: avatarPath,
                isMe: isMe,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String hlc,
                Value<bool> isDeleted = const Value.absent(),
                required String name,
                Value<String?> avatarPath = const Value.absent(),
                Value<bool> isMe = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                hlc: hlc,
                isDeleted: isDeleted,
                name: name,
                avatarPath: avatarPath,
                isMe: isMe,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$UsersTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({groupsRefs = false, expensesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (groupsRefs) db.groups,
                if (expensesRefs) db.expenses,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (groupsRefs)
                    await $_getPrefetchedData<User, $UsersTable, Group>(
                      currentTable: table,
                      referencedTable: $$UsersTableReferences._groupsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$UsersTableReferences(db, table, p0).groupsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.ownerId == item.id),
                      typedResults: items,
                    ),
                  if (expensesRefs)
                    await $_getPrefetchedData<User, $UsersTable, Expense>(
                      currentTable: table,
                      referencedTable: $$UsersTableReferences
                          ._expensesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$UsersTableReferences(db, table, p0).expensesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.creatorId == item.id),
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
      PrefetchHooks Function({bool groupsRefs, bool expensesRefs})
    >;
typedef $$GroupsTableCreateCompanionBuilder =
    GroupsCompanion Function({
      required String id,
      required String hlc,
      Value<bool> isDeleted,
      required String ownerId,
      required String name,
      Value<String?> description,
      required int createdAt,
      required String signature,
      Value<int> rowid,
    });
typedef $$GroupsTableUpdateCompanionBuilder =
    GroupsCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<String> ownerId,
      Value<String> name,
      Value<String?> description,
      Value<int> createdAt,
      Value<String> signature,
      Value<int> rowid,
    });

final class $$GroupsTableReferences
    extends BaseReferences<_$AppDatabase, $GroupsTable, Group> {
  $$GroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _ownerIdTable(_$AppDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.groups.ownerId, db.users.id),
  );

  $$UsersTableProcessedTableManager get ownerId {
    final $_column = $_itemColumn<String>('owner_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ownerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$GroupMembersTable, List<GroupMember>>
  _groupMembersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.groupMembers,
    aliasName: $_aliasNameGenerator(db.groups.id, db.groupMembers.groupId),
  );

  $$GroupMembersTableProcessedTableManager get groupMembersRefs {
    final manager = $$GroupMembersTableTableManager(
      $_db,
      $_db.groupMembers,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_groupMembersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: $_aliasNameGenerator(db.groups.id, db.expenses.groupId),
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GroupsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get ownerId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
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

  Expression<bool> groupMembersRefs(
    Expression<bool> Function($$GroupMembersTableFilterComposer f) f,
  ) {
    final $$GroupMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groupMembers,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupMembersTableFilterComposer(
            $db: $db,
            $table: $db.groupMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get ownerId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
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

class $$GroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get signature =>
      $composableBuilder(column: $table.signature, builder: (column) => column);

  $$UsersTableAnnotationComposer get ownerId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerId,
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

  Expression<T> groupMembersRefs<T extends Object>(
    Expression<T> Function($$GroupMembersTableAnnotationComposer a) f,
  ) {
    final $$GroupMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groupMembers,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.groupMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupsTable,
          Group,
          $$GroupsTableFilterComposer,
          $$GroupsTableOrderingComposer,
          $$GroupsTableAnnotationComposer,
          $$GroupsTableCreateCompanionBuilder,
          $$GroupsTableUpdateCompanionBuilder,
          (Group, $$GroupsTableReferences),
          Group,
          PrefetchHooks Function({
            bool ownerId,
            bool groupMembersRefs,
            bool expensesRefs,
          })
        > {
  $$GroupsTableTableManager(_$AppDatabase db, $GroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> signature = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupsCompanion(
                id: id,
                hlc: hlc,
                isDeleted: isDeleted,
                ownerId: ownerId,
                name: name,
                description: description,
                createdAt: createdAt,
                signature: signature,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String hlc,
                Value<bool> isDeleted = const Value.absent(),
                required String ownerId,
                required String name,
                Value<String?> description = const Value.absent(),
                required int createdAt,
                required String signature,
                Value<int> rowid = const Value.absent(),
              }) => GroupsCompanion.insert(
                id: id,
                hlc: hlc,
                isDeleted: isDeleted,
                ownerId: ownerId,
                name: name,
                description: description,
                createdAt: createdAt,
                signature: signature,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$GroupsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                ownerId = false,
                groupMembersRefs = false,
                expensesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (groupMembersRefs) db.groupMembers,
                    if (expensesRefs) db.expenses,
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
                        if (ownerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ownerId,
                                    referencedTable: $$GroupsTableReferences
                                        ._ownerIdTable(db),
                                    referencedColumn: $$GroupsTableReferences
                                        ._ownerIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (groupMembersRefs)
                        await $_getPrefetchedData<
                          Group,
                          $GroupsTable,
                          GroupMember
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._groupMembersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).groupMembersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (expensesRefs)
                        await $_getPrefetchedData<Group, $GroupsTable, Expense>(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._expensesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).expensesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
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

typedef $$GroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupsTable,
      Group,
      $$GroupsTableFilterComposer,
      $$GroupsTableOrderingComposer,
      $$GroupsTableAnnotationComposer,
      $$GroupsTableCreateCompanionBuilder,
      $$GroupsTableUpdateCompanionBuilder,
      (Group, $$GroupsTableReferences),
      Group,
      PrefetchHooks Function({
        bool ownerId,
        bool groupMembersRefs,
        bool expensesRefs,
      })
    >;
typedef $$GroupMembersTableCreateCompanionBuilder =
    GroupMembersCompanion Function({
      required String id,
      required String hlc,
      Value<bool> isDeleted,
      required String groupId,
      required String userId,
      required String role,
      required String authorizedBy,
      required String signature,
      Value<int> rowid,
    });
typedef $$GroupMembersTableUpdateCompanionBuilder =
    GroupMembersCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<String> groupId,
      Value<String> userId,
      Value<String> role,
      Value<String> authorizedBy,
      Value<String> signature,
      Value<int> rowid,
    });

final class $$GroupMembersTableReferences
    extends BaseReferences<_$AppDatabase, $GroupMembersTable, GroupMember> {
  $$GroupMembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupIdTable(_$AppDatabase db) => db.groups.createAlias(
    $_aliasNameGenerator(db.groupMembers.groupId, db.groups.id),
  );

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.groupMembers.userId, db.users.id),
  );

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

  static $UsersTable _authorizedByTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(db.groupMembers.authorizedBy, db.users.id),
      );

  $$UsersTableProcessedTableManager get authorizedBy {
    final $_column = $_itemColumn<String>('authorized_by')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_authorizedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GroupMembersTableFilterComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
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

  $$UsersTableFilterComposer get authorizedBy {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorizedBy,
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
}

class $$GroupMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
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

  $$UsersTableOrderingComposer get authorizedBy {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorizedBy,
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

class $$GroupMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get signature =>
      $composableBuilder(column: $table.signature, builder: (column) => column);

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
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

  $$UsersTableAnnotationComposer get authorizedBy {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorizedBy,
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
}

class $$GroupMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupMembersTable,
          GroupMember,
          $$GroupMembersTableFilterComposer,
          $$GroupMembersTableOrderingComposer,
          $$GroupMembersTableAnnotationComposer,
          $$GroupMembersTableCreateCompanionBuilder,
          $$GroupMembersTableUpdateCompanionBuilder,
          (GroupMember, $$GroupMembersTableReferences),
          GroupMember,
          PrefetchHooks Function({bool groupId, bool userId, bool authorizedBy})
        > {
  $$GroupMembersTableTableManager(_$AppDatabase db, $GroupMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> authorizedBy = const Value.absent(),
                Value<String> signature = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupMembersCompanion(
                id: id,
                hlc: hlc,
                isDeleted: isDeleted,
                groupId: groupId,
                userId: userId,
                role: role,
                authorizedBy: authorizedBy,
                signature: signature,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String hlc,
                Value<bool> isDeleted = const Value.absent(),
                required String groupId,
                required String userId,
                required String role,
                required String authorizedBy,
                required String signature,
                Value<int> rowid = const Value.absent(),
              }) => GroupMembersCompanion.insert(
                id: id,
                hlc: hlc,
                isDeleted: isDeleted,
                groupId: groupId,
                userId: userId,
                role: role,
                authorizedBy: authorizedBy,
                signature: signature,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GroupMembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({groupId = false, userId = false, authorizedBy = false}) {
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
                        if (groupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.groupId,
                                    referencedTable:
                                        $$GroupMembersTableReferences
                                            ._groupIdTable(db),
                                    referencedColumn:
                                        $$GroupMembersTableReferences
                                            ._groupIdTable(db)
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
                                        $$GroupMembersTableReferences
                                            ._userIdTable(db),
                                    referencedColumn:
                                        $$GroupMembersTableReferences
                                            ._userIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (authorizedBy) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.authorizedBy,
                                    referencedTable:
                                        $$GroupMembersTableReferences
                                            ._authorizedByTable(db),
                                    referencedColumn:
                                        $$GroupMembersTableReferences
                                            ._authorizedByTable(db)
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

typedef $$GroupMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupMembersTable,
      GroupMember,
      $$GroupMembersTableFilterComposer,
      $$GroupMembersTableOrderingComposer,
      $$GroupMembersTableAnnotationComposer,
      $$GroupMembersTableCreateCompanionBuilder,
      $$GroupMembersTableUpdateCompanionBuilder,
      (GroupMember, $$GroupMembersTableReferences),
      GroupMember,
      PrefetchHooks Function({bool groupId, bool userId, bool authorizedBy})
    >;
typedef $$ExpensesTableCreateCompanionBuilder =
    ExpensesCompanion Function({
      required String id,
      required String hlc,
      Value<bool> isDeleted,
      required String groupId,
      required String creatorId,
      required String description,
      required double amount,
      required String currencyCode,
      required DateTime date,
      required String splitType,
      required String signature,
      Value<String?> receiptPath,
      Value<int> rowid,
    });
typedef $$ExpensesTableUpdateCompanionBuilder =
    ExpensesCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<String> groupId,
      Value<String> creatorId,
      Value<String> description,
      Value<double> amount,
      Value<String> currencyCode,
      Value<DateTime> date,
      Value<String> splitType,
      Value<String> signature,
      Value<String?> receiptPath,
      Value<int> rowid,
    });

final class $$ExpensesTableReferences
    extends BaseReferences<_$AppDatabase, $ExpensesTable, Expense> {
  $$ExpensesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupIdTable(_$AppDatabase db) => db.groups.createAlias(
    $_aliasNameGenerator(db.expenses.groupId, db.groups.id),
  );

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UsersTable _creatorIdTable(_$AppDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.expenses.creatorId, db.users.id),
  );

  $$UsersTableProcessedTableManager get creatorId {
    final $_column = $_itemColumn<String>('creator_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_creatorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get splitType => $composableBuilder(
    column: $table.splitType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptPath => $composableBuilder(
    column: $table.receiptPath,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableFilterComposer get creatorId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creatorId,
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
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get splitType => $composableBuilder(
    column: $table.splitType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptPath => $composableBuilder(
    column: $table.receiptPath,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableOrderingComposer get creatorId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creatorId,
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

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get splitType =>
      $composableBuilder(column: $table.splitType, builder: (column) => column);

  GeneratedColumn<String> get signature =>
      $composableBuilder(column: $table.signature, builder: (column) => column);

  GeneratedColumn<String> get receiptPath => $composableBuilder(
    column: $table.receiptPath,
    builder: (column) => column,
  );

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableAnnotationComposer get creatorId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creatorId,
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
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          Expense,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (Expense, $$ExpensesTableReferences),
          Expense,
          PrefetchHooks Function({bool groupId, bool creatorId})
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> creatorId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> splitType = const Value.absent(),
                Value<String> signature = const Value.absent(),
                Value<String?> receiptPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                hlc: hlc,
                isDeleted: isDeleted,
                groupId: groupId,
                creatorId: creatorId,
                description: description,
                amount: amount,
                currencyCode: currencyCode,
                date: date,
                splitType: splitType,
                signature: signature,
                receiptPath: receiptPath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String hlc,
                Value<bool> isDeleted = const Value.absent(),
                required String groupId,
                required String creatorId,
                required String description,
                required double amount,
                required String currencyCode,
                required DateTime date,
                required String splitType,
                required String signature,
                Value<String?> receiptPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                hlc: hlc,
                isDeleted: isDeleted,
                groupId: groupId,
                creatorId: creatorId,
                description: description,
                amount: amount,
                currencyCode: currencyCode,
                date: date,
                splitType: splitType,
                signature: signature,
                receiptPath: receiptPath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExpensesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false, creatorId = false}) {
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
                    if (groupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.groupId,
                                referencedTable: $$ExpensesTableReferences
                                    ._groupIdTable(db),
                                referencedColumn: $$ExpensesTableReferences
                                    ._groupIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (creatorId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.creatorId,
                                referencedTable: $$ExpensesTableReferences
                                    ._creatorIdTable(db),
                                referencedColumn: $$ExpensesTableReferences
                                    ._creatorIdTable(db)
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

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      Expense,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (Expense, $$ExpensesTableReferences),
      Expense,
      PrefetchHooks Function({bool groupId, bool creatorId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
  $$GroupMembersTableTableManager get groupMembers =>
      $$GroupMembersTableTableManager(_db, _db.groupMembers);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
}
