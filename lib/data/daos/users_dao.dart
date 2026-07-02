import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/users_table.dart';

// Come per il database, il generatore creerà un file .g.dart associato
part 'users_dao.g.dart';

@DriftAccessor(tables: [UsersTable])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  // Recupera l'utente "Me" (il proprietario del dispositivo)
  Future<UsersTableData?> getMe() {
    return (select(
      usersTable,
    )..where((t) => t.isMe.equals(true))).getSingleOrNull();
  }

  // Inserisce o aggiorna un utente (Upsert)
  Future<void> upsertUser(UsersTableCompanion entry) {
    return into(usersTable).insertOnConflictUpdate(entry);
  }
}
