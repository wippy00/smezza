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

  Future<void> softDeleteGroup(String id, String newHlc) async {
    await (update(groupsTable)..where((t) => t.id.equals(id))).write(
      GroupsTableCompanion(
        isDeleted: const Value(true),
        isSynced: const Value(false),
        hlc: Value(newHlc),
      ),
    );
  }

  Future<void> renameGroup(String id, String newName, String newHlc) async {
    await (update(groupsTable)..where((t) => t.id.equals(id))).write(
      GroupsTableCompanion(
        name: Value(newName),
        isSynced: const Value(false),
        hlc: Value(newHlc),
      ),
    );
  }

  Future<void> removeMemberFromGroup(
    String groupId,
    String userId,
    String newHlc,
  ) async {
    final group = await (select(
      groupsTable,
    )..where((t) => t.id.equals(groupId))).getSingle();

    // Owner non si rimuove mai
    if (userId == group.ownerId) return;

    final currentMembers = group.memberIds.isEmpty
        ? <String>[]
        : group.memberIds.split(',');
    currentMembers.remove(userId);

    await (update(groupsTable)..where((t) => t.id.equals(groupId))).write(
      GroupsTableCompanion(
        memberIds: Value(currentMembers.join(',')),
        isSynced: const Value(false),
        hlc: Value(newHlc),
      ),
    );
  }

  Future<void> addMemberToGroup(
    String groupId,
    String userId,
    String newHlc,
  ) async {
    final group = await (select(
      groupsTable,
    )..where((t) => t.id.equals(groupId))).getSingle();

    // Creiamo la lista attuale dei membri
    final currentMembers = group.memberIds.isEmpty
        ? <String>[]
        : group.memberIds.split(',').toList();

    if (!currentMembers.contains(userId)) {
      currentMembers.add(userId);

      // Aggiorniamo il gruppo locale e lo marchiamo come da sincronizzare
      await (update(groupsTable)..where((t) => t.id.equals(groupId))).write(
        GroupsTableCompanion(
          memberIds: Value(currentMembers.join(',')),
          isSynced: const Value(false),
          hlc: Value(newHlc),
        ),
      );
    }
  }
}
