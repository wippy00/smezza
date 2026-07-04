import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '/data/database.dart';

// Provider originale: tutta la rubrica locale
final allUsersProvider = StreamProvider<List<UsersTableData>>((ref) {
  final db = GetIt.I<AppDatabase>();
  return (db.select(
    db.usersTable,
  )..where((t) => t.isDeleted.equals(false))).watch();
});

// NUOVO PROVIDER: Restituisce SOLO gli utenti che appartengono a un determinato gruppo
final groupMembersProvider =
    StreamProvider.family<List<UsersTableData>, String>((ref, groupId) {
      final db = GetIt.I<AppDatabase>();

      return (db.select(
        db.groupsTable,
      )..where((t) => t.id.equals(groupId))).watch().asyncMap((groups) async {
        if (groups.isEmpty) return [];

        final group = groups.first;
        final memberIds = group.memberIds.isEmpty
            ? <String>[]
            : group.memberIds.split(',');

        // Assicuriamoci che il proprietario sia sempre incluso
        if (!memberIds.contains(group.ownerId)) memberIds.add(group.ownerId);

        // Recuperiamo i dati completi degli utenti (Nomi) dal DB locale
        return await (db.select(
          db.usersTable,
        )..where((t) => t.id.isIn(memberIds))).get();
      });
    });
