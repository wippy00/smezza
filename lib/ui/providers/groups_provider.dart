import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../../data/database.dart';

// Un StreamProvider è perfetto perché watchAllGroups() restituisce uno Stream.
// Riverpod gestirà automaticamente gli stati di Loading, Error e Data per noi.
final groupsProvider = StreamProvider<List<GroupsTableData>>((ref) {
  final db = GetIt.I<AppDatabase>();
  return db.groupsDao.watchAllGroups();
});
