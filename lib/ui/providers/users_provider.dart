import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../../../data/database.dart';

// Semplice StreamProvider che legge tutti gli utenti salvati nel DB locale
final allUsersProvider = StreamProvider<List<UsersTableData>>((ref) {
  final db = GetIt.I<AppDatabase>();
  return (db.select(
    db.usersTable,
  )..where((t) => t.isDeleted.equals(false))).watch();
});
