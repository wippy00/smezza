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
      print("SyncService: Sincronizzazione completata!");
      return true;
    } catch (e) {
      print("SyncService: Errore imprevisto durante la sincronizzazione: $e");
      return false;
    }
  }

  /// 1. PUSH: invia le modifiche locali. Se un record fallisce, gli altri
  /// vengono comunque inviati; il record problematico resta "non sincronizzato"
  /// con un messaggio di errore leggibile, e verrà ritentato al prossimo giro.
  Future<void> pushLocalChanges() async {
    final unsyncedGroups = await (_db.select(
      _db.groupsTable,
    )..where((t) => t.isSynced.equals(false))).get();

    final unsyncedExpenses = await (_db.select(
      _db.expensesTable,
    )..where((t) => t.isSynced.equals(false))).get();

    // Prendiamo TUTTI gli split non sincronizzati (non solo quelli delle spese
    // non sincronizzate): così una modifica a uno split fatta DOPO che la
    // spesa era già stata sincronizzata viene comunque inviata.
    final unsyncedSplits = await (_db.select(
      _db.splitsTable,
    )..where((t) => t.isSynced.equals(false))).get();

    if (unsyncedGroups.isEmpty && unsyncedExpenses.isEmpty && unsyncedSplits.isEmpty) {
      print("SyncService [Push]: Nulla da sincronizzare.");
      return;
    }

    final packet = SyncPacket(
      senderUserId: sl<IdentityService>().uuid,
      sinceHlc: '',
      groups: unsyncedGroups.map((g) => g.toJson()).toList(),
      expenses: unsyncedExpenses.map((e) => e.toJson()).toList(),
      splits: unsyncedSplits.map((s) => s.toJson()).toList(),
    );

    final result = await _repo.push(packet);

    await _db.transaction(() async {
      for (final g in unsyncedGroups) {
        if (result.succeededGroupIds.contains(g.id)) {
          await (_db.update(_db.groupsTable)..where((t) => t.id.equals(g.id)))
              .write(const GroupsTableCompanion(
                isSynced: Value(true),
                syncError: Value(null),
              ));
        } else if (result.failedGroupErrors.containsKey(g.id)) {
          await (_db.update(_db.groupsTable)..where((t) => t.id.equals(g.id)))
              .write(GroupsTableCompanion(
                syncError: Value(result.failedGroupErrors[g.id]),
              ));
        }
      }

      for (final e in unsyncedExpenses) {
        if (result.succeededExpenseIds.contains(e.id)) {
          await (_db.update(_db.expensesTable)..where((t) => t.id.equals(e.id)))
              .write(const ExpensesTableCompanion(
                isSynced: Value(true),
                syncError: Value(null),
              ));
        } else if (result.failedExpenseErrors.containsKey(e.id)) {
          await (_db.update(_db.expensesTable)..where((t) => t.id.equals(e.id)))
              .write(ExpensesTableCompanion(
                syncError: Value(result.failedExpenseErrors[e.id]),
              ));
        }
      }

      for (final s in unsyncedSplits) {
        if (result.succeededSplitIds.contains(s.id)) {
          await (_db.update(_db.splitsTable)..where((t) => t.id.equals(s.id)))
              .write(const SplitsTableCompanion(isSynced: Value(true)));
        }
        // Per gli split non teniamo (per ora) un campo di errore dedicato:
        // se falliscono restano "non sincronizzati" e verranno ritentati.
      }
    });

    print(
      "SyncService [Push]: gruppi ${result.succeededGroupIds.length}/${unsyncedGroups.length}, "
      "spese ${result.succeededExpenseIds.length}/${unsyncedExpenses.length}, "
      "split ${result.succeededSplitIds.length}/${unsyncedSplits.length} sincronizzati.",
    );

    if (result.hasErrors) {
      print("SyncService [Push]: alcuni record hanno fallito, verranno ritentati al prossimo sync.");
    }
  }

  /// 2. PULL: scarica le modifiche remote. Gira SEMPRE, anche se il push
  /// sopra ha avuto errori parziali (non li propaga più come eccezione).
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

      await prefs.setString('last_sync_hlc', maxHlc);
      print(
        "SyncService [Pull]: Scaricati nuovi dati remoti. Nuovo HLC di sincronizzazione: $maxHlc",
      );
    } else {
      print("SyncService [Pull]: Nessun nuovo dato sul server.");
    }
  }
}