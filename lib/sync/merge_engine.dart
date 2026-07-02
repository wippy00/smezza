import 'package:drift/drift.dart';
import '../data/database.dart';
import '../core/hlc/hlc_manager.dart';
import 'sync_packet.dart';

class MergeEngine {
  final AppDatabase _db;

  MergeEngine(this._db);

  Future<void> applyPacket(SyncPacket packet) async {
    await _db.transaction(() async {
      for (final u in packet.users) {
        await _mergeUser(u);
      }
      for (final g in packet.groups) {
        await _mergeGroup(g);
      }
      for (final e in packet.expenses) {
        await _mergeExpense(e);
      }
      for (final s in packet.splits) {
        await _mergeSplit(s);
      }
    });
  }

  Future<void> _mergeUser(Map<String, dynamic> remote) async {
    final id = remote['id'] as String;
    final remoteHlc = Hlc.fromString(remote['hlc'] as String);

    final local = await (_db.select(
      _db.usersTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (local == null || remoteHlc > Hlc.fromString(local.hlc)) {
      // Usiamo UsersTableData.fromJson al posto del Companion!
      final record = UsersTableData.fromJson(remote);
      await _db.into(_db.usersTable).insertOnConflictUpdate(record);
    }
  }

  Future<void> _mergeGroup(Map<String, dynamic> remote) async {
    final id = remote['id'] as String;
    final remoteHlc = Hlc.fromString(remote['hlc'] as String);

    final local = await (_db.select(
      _db.groupsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (local == null || remoteHlc > Hlc.fromString(local.hlc)) {
      final record = GroupsTableData.fromJson(remote);
      await _db.into(_db.groupsTable).insertOnConflictUpdate(record);
    }
  }

  Future<void> _mergeExpense(Map<String, dynamic> remote) async {
    final id = remote['id'] as String;
    final remoteHlc = Hlc.fromString(remote['hlc'] as String);

    final local = await (_db.select(
      _db.expensesTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (local == null || remoteHlc > Hlc.fromString(local.hlc)) {
      final record = ExpensesTableData.fromJson(remote);
      await _db.into(_db.expensesTable).insertOnConflictUpdate(record);
    }
  }

  Future<void> _mergeSplit(Map<String, dynamic> remote) async {
    final id = remote['id'] as String;
    final local = await (_db.select(
      _db.splitsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (local == null) {
      final record = SplitsTableData.fromJson(remote);
      await _db.into(_db.splitsTable).insertOnConflictUpdate(record);
    }
  }
}
