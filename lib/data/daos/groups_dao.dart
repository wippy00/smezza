import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/groups_table.dart';

part 'groups_dao.g.dart';

@DriftAccessor(tables: [GroupsTable])
class GroupsDao extends DatabaseAccessor<AppDatabase> with _$GroupsDaoMixin {
  GroupsDao(super.db);

  // Restituisce uno Stream reattivo: ogni volta che i gruppi cambiano sul DB,
  // chi ascolta riceve automaticamente la lista aggiornata.
  Stream<List<GroupsTableData>> watchAllGroups() {
    return (select(
      groupsTable,
    )..where((t) => t.isDeleted.equals(false))).watch();
  }

  Future<void> upsertGroup(GroupsTableCompanion entry) {
    return into(groupsTable).insertOnConflictUpdate(entry);
  }
}
