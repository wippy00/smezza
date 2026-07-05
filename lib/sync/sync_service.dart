import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database.dart';
import '../../main.dart';
import '../core/identity/identity_manager.dart';
import 'sync_packet.dart';
import 'sync_repository.dart';

class SyncService {
  final AppDatabase _db;
  final SyncRepository _repo;

  SyncService(this._db, this._repo);

  Future<bool> sync() async {
    try {
      await pushLocalChanges();
      await pullRemoteChanges();
      return true;
    } catch (e) {
      print("SyncService: Errore imprevisto: $e");
      return false;
    }
  }

  Future<void> pushLocalChanges() async {
    final unsyncedGroups = await (_db.select(
      _db.groupsTable,
    )..where((t) => t.isSynced.equals(false))).get();
    final unsyncedExpenses = await (_db.select(
      _db.expensesTable,
    )..where((t) => t.isSynced.equals(false))).get();
    final unsyncedSplits = await (_db.select(
      _db.splitsTable,
    )..where((t) => t.isSynced.equals(false))).get();
    final unsyncedPayments = await (_db.select(
      _db.paymentsTable,
    )..where((t) => t.isSynced.equals(false))).get();

    if (unsyncedGroups.isEmpty &&
        unsyncedExpenses.isEmpty &&
        unsyncedSplits.isEmpty &&
        unsyncedPayments.isEmpty) {
      return;
    }

    final packet = SyncPacket(
      senderUserId: sl<IdentityService>().uuid,
      sinceHlc: '',
      groups: unsyncedGroups.map((g) => g.toJson()).toList(),
      expenses: unsyncedExpenses.map((e) => e.toJson()).toList(),
      splits: unsyncedSplits.map((s) => s.toJson()).toList(),
      payments: unsyncedPayments.map((p) => p.toJson()).toList(),
    );

    final result = await _repo.push(packet);

    await _db.transaction(() async {
      for (final g in unsyncedGroups) {
        if (result.succeededGroupIds.contains(g.id)) {
          await (_db.update(
            _db.groupsTable,
          )..where((t) => t.id.equals(g.id))).write(
            const GroupsTableCompanion(
              isSynced: Value(true),
              syncError: Value(null),
            ),
          );
        } else if (result.failedGroupErrors.containsKey(g.id)) {
          await (_db.update(
            _db.groupsTable,
          )..where((t) => t.id.equals(g.id))).write(
            GroupsTableCompanion(
              syncError: Value(result.failedGroupErrors[g.id]),
            ),
          );
        }
      }
      for (final e in unsyncedExpenses) {
        if (result.succeededExpenseIds.contains(e.id)) {
          await (_db.update(
            _db.expensesTable,
          )..where((t) => t.id.equals(e.id))).write(
            const ExpensesTableCompanion(
              isSynced: Value(true),
              syncError: Value(null),
            ),
          );
        } else if (result.failedExpenseErrors.containsKey(e.id)) {
          await (_db.update(
            _db.expensesTable,
          )..where((t) => t.id.equals(e.id))).write(
            ExpensesTableCompanion(
              syncError: Value(result.failedExpenseErrors[e.id]),
            ),
          );
        }
      }
      for (final s in unsyncedSplits) {
        if (result.succeededSplitIds.contains(s.id)) {
          await (_db.update(_db.splitsTable)..where((t) => t.id.equals(s.id)))
              .write(const SplitsTableCompanion(isSynced: Value(true)));
        }
      }
      for (final p in unsyncedPayments) {
        if (result.succeededPaymentIds.contains(p.id)) {
          await (_db.update(
            _db.paymentsTable,
          )..where((t) => t.id.equals(p.id))).write(
            const PaymentsTableCompanion(
              isSynced: Value(true),
              syncError: Value(null),
            ),
          );
        } else if (result.failedPaymentErrors.containsKey(p.id)) {
          await (_db.update(
            _db.paymentsTable,
          )..where((t) => t.id.equals(p.id))).write(
            PaymentsTableCompanion(
              syncError: Value(result.failedPaymentErrors[p.id]),
            ),
          );
        }
      }
    });
  }

  Future<void> pullRemoteChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final sinceHlc =
        prefs.getString('last_sync_hlc') ?? '000000000000000:0000:initial';

    final packet = await _repo.pull(sinceHlc: sinceHlc);

    if (packet != null && !packet.isEmpty) {
      String maxHlc = sinceHlc;
      for (final g in packet.groups) {
        final hlc = g['hlc'] as String;
        if (hlc.compareTo(maxHlc) > 0) maxHlc = hlc;
      }
      for (final e in packet.expenses) {
        final hlc = e['hlc'] as String;
        if (hlc.compareTo(maxHlc) > 0) maxHlc = hlc;
      }
      for (final p in packet.payments) {
        final hlc = p['hlc'] as String;
        if (hlc.compareTo(maxHlc) > 0) maxHlc = hlc;
      }
      await prefs.setString('last_sync_hlc', maxHlc);
    }
  }
}
