import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/users_table.dart';

// Come per il database, il generatore creerà un file .g.dart associato
part 'users_dao.g.dart';

@DriftAccessor(tables: [UsersTable])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  // Recupera l'utente "Me" (il proprietario del dispositivo)
  Future<UsersTableData?> getMe() async {
    final all = await (select(
      usersTable,
    )..where((t) => t.isMe.equals(true))).get();
    if (all.isEmpty) return null;
    if (all.length > 1) {
      for (final u in all.skip(1)) {
        await (update(usersTable)..where((t) => t.id.equals(u.id))).write(
          const UsersTableCompanion(isMe: Value(false)),
        );
      }
    }
    return all.first;
  }

  // Inserisce o aggiorna un utente (Upsert)
  Future<void> upsertUser(UsersTableCompanion entry) {
    return into(usersTable).insertOnConflictUpdate(entry);
  }
}
