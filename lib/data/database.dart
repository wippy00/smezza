import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/users_table.dart';
import 'tables/groups_table.dart';
import 'tables/expenses_table.dart';
import 'tables/splits_table.dart';

import 'daos/users_dao.dart';
import 'daos/groups_dao.dart';
import 'daos/expenses_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [UsersTable, GroupsTable, ExpensesTable, SplitsTable],
  daos: [UsersDao, GroupsDao, ExpensesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.inMemory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 3; // era 2

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(splitsTable, splitsTable.hlc);
        await m.addColumn(splitsTable, splitsTable.isSynced);
        await m.addColumn(splitsTable, splitsTable.isDeleted);
        await m.addColumn(expensesTable, expensesTable.categoryId);
        await m.addColumn(expensesTable, expensesTable.date);
      }
      if (from < 3) {
        await m.addColumn(expensesTable, expensesTable.syncError);
        await m.addColumn(groupsTable, groupsTable.syncError);
      }
    },
  );
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'smezza.db'));
    return NativeDatabase.createInBackground(file);
  });
}