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
      for (final p in packet.payments) {
        await _mergePayment(p);
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
      await _db
          .into(_db.usersTable)
          .insertOnConflictUpdate(UsersTableData.fromJson(remote));
    }
  }

  Future<void> _mergeGroup(Map<String, dynamic> remote) async {
    final id = remote['id'] as String;
    final remoteHlc = Hlc.fromString(remote['hlc'] as String);
    final local = await (_db.select(
      _db.groupsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (local == null || remoteHlc > Hlc.fromString(local.hlc)) {
      await _db
          .into(_db.groupsTable)
          .insertOnConflictUpdate(GroupsTableData.fromJson(remote));
    }
  }

  Future<void> _mergeExpense(Map<String, dynamic> remote) async {
    final id = remote['id'] as String;
    final remoteHlc = Hlc.fromString(remote['hlc'] as String);
    final local = await (_db.select(
      _db.expensesTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (local == null || remoteHlc > Hlc.fromString(local.hlc)) {
      await _db
          .into(_db.expensesTable)
          .insertOnConflictUpdate(ExpensesTableData.fromJson(remote));
    }
  }

  Future<void> _mergeSplit(Map<String, dynamic> remote) async {
    final id = remote['id'] as String;
    final remoteHlcStr = remote['hlc'] as String?;
    final remoteHlc = remoteHlcStr != null
        ? Hlc.fromString(remoteHlcStr)
        : null;
    final local = await (_db.select(
      _db.splitsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    final localHlcStr = local?.hlc;
    final localHlc = localHlcStr != null ? Hlc.fromString(localHlcStr) : null;
    final shouldWrite =
        local == null ||
        localHlc == null ||
        (remoteHlc != null && remoteHlc > localHlc);
    if (shouldWrite) {
      await _db
          .into(_db.splitsTable)
          .insertOnConflictUpdate(SplitsTableData.fromJson(remote));
    }
  }

  // NUOVO: stesso pattern LWW su HLC usato per expenses/groups.
  Future<void> _mergePayment(Map<String, dynamic> remote) async {
    final id = remote['id'] as String;
    final remoteHlc = Hlc.fromString(remote['hlc'] as String);
    final local = await (_db.select(
      _db.paymentsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (local == null || remoteHlc > Hlc.fromString(local.hlc)) {
      await _db
          .into(_db.paymentsTable)
          .insertOnConflictUpdate(PaymentsTableData.fromJson(remote));
    }
  }
}
