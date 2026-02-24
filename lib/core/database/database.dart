import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// Mixin per i campi necessari alla sincronizzazione P2P
mixin SyncableTable on Table {
  TextColumn get id => text()(); // UUID o Public Key
  TextColumn get hlc =>
      text()(); // Timestamp logico (es. 1738933500000:0001:nodeId)
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// 1. Users: id (public key), name, avatarPath, hlc, isMe
class Users extends Table with SyncableTable {
  TextColumn get name => text()();
  TextColumn get avatarPath => text().nullable()();
  BoolColumn get isMe => boolean().withDefault(const Constant(false))();
}

// 2. Groups: id (UUID), ownerId (public key), name, description, hlc, signature
class Groups extends Table with SyncableTable {
  TextColumn get ownerId => text().references(Users, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get createdAt => integer()();
  TextColumn get signature => text()();
}

// 3. GroupMembers: groupId, userId, role, authorizedBy, signature
class GroupMembers extends Table with SyncableTable {
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get role => text()(); // OWNER, ADMIN, MEMBER
  TextColumn get authorizedBy => text().references(Users, #id)();
  TextColumn get signature => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {groupId, userId}
  ];

}

// 4. Expenses: id, groupId, creatorId, description, amount, currencyCode, date, splitType, signature
class Expenses extends Table with SyncableTable {
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get creatorId => text().references(Users, #id)();
  TextColumn get description => text()();
  RealColumn get amount => real()();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  DateTimeColumn get date => dateTime()();
  TextColumn get splitType => text()(); // EQUAL, SHARES, etc.
  TextColumn get signature => text()();
  TextColumn get receiptPath => text().nullable()();
}

@DriftDatabase(tables: [Users, Groups, GroupMembers, Expenses])
class AppDatabase extends _$AppDatabase {
  // After generating code, this class needs to define a `schemaVersion` getter
  // and a constructor telling drift where the database should be stored.
  // These are described in the getting started guide: https://drift.simonbinder.eu/setup/
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(groups);
        await m.createTable(groupMembers);
        await m.createTable(expenses);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'my_database',
      native: const DriftNativeOptions(
        // By default, `driftDatabase` from `package:drift_flutter` stores the
        // database files in `getApplicationDocumentsDirectory()`.
        databaseDirectory: getApplicationSupportDirectory,
      ),
      // If you need web support, see https://drift.simonbinder.eu/platforms/web/
    );
  }
}


