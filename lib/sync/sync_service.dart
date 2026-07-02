import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database.dart';
import '../../main.dart'; // per accedere al service locator sl
import '../core/identity/identity_manager.dart';
import 'sync_packet.dart';
import 'sync_repository.dart';

class SyncService {
  final AppDatabase _db;
  final SyncRepository _repo;

  SyncService(this._db, this._repo);

  /// Esegue un ciclo completo di sincronizzazione: Push + Pull
  Future<bool> sync() async {
    try {
      await pushLocalChanges();
      await pullRemoteChanges();
      print("SyncService: Sincronizzazione completata con successo!");
      return true; // <--- Ritorna true se tutto è andato a buon fine
    } catch (e) {
      print("SyncService: Errore durante la sincronizzazione: $e");
      return false; // <--- Ritorna false se si è verificato un errore
    }
  }

  /// 1. PUSH: Invia le modifiche locali al server
  Future<void> pushLocalChanges() async {
    // Recupera i gruppi locali non ancora sincronizzati
    final unsyncedGroups = await (_db.select(
      _db.groupsTable,
    )..where((t) => t.isSynced.equals(false))).get();

    // Recupera le spese locali non ancora sincronizzati
    final unsyncedExpenses = await (_db.select(
      _db.expensesTable,
    )..where((t) => t.isSynced.equals(false))).get();

    // Recupera gli split associati alle spese non sincronizzate
    final List<SplitsTableData> splits = [];
    for (final exp in unsyncedExpenses) {
      final expSplits = await (_db.select(
        _db.splitsTable,
      )..where((t) => t.expenseId.equals(exp.id))).get();
      splits.addAll(expSplits);
    }

    if (unsyncedGroups.isEmpty && unsyncedExpenses.isEmpty) {
      print("SyncService [Push]: Nulla da sincronizzare.");
      return;
    }

    // Costruiamo il pacchetto di sincronizzazione convertendo i record di Drift in JSON
    final packet = SyncPacket(
      senderUserId: sl<IdentityService>().uuid,
      sinceHlc: '',
      groups: unsyncedGroups.map((g) => g.toJson()).toList(),
      expenses: unsyncedExpenses.map((e) => e.toJson()).toList(),
      splits: splits.map((s) => s.toJson()).toList(),
    );

    // Inviamo il pacchetto a PocketBase
    await _repo.push(packet);

    // Se l'invio è andato a buon fine, marchiamo i record locali come sincronizzati (isSynced = true)
    await _db.transaction(() async {
      for (final g in unsyncedGroups) {
        await (_db.update(_db.groupsTable)..where((t) => t.id.equals(g.id)))
            .write(const GroupsTableCompanion(isSynced: Value(true)));
      }
      for (final e in unsyncedExpenses) {
        await (_db.update(_db.expensesTable)..where((t) => t.id.equals(e.id)))
            .write(const ExpensesTableCompanion(isSynced: Value(true)));
      }
    });

    print(
      "SyncService [Push]: Spediti con successo ${unsyncedGroups.length} gruppi e ${unsyncedExpenses.length} spese.",
    );
  }

  /// 2. PULL: Scarica le modifiche remote dal server
  Future<void> pullRemoteChanges() async {
    final prefs = await SharedPreferences.getInstance();

    // Recuperiamo l'ultimo HLC fino a cui ci eravamo sincronizzati (se vuoto, partiamo dall'inizio)
    final sinceHlc =
        prefs.getString('last_sync_hlc') ?? '000000000000000:0000:initial';

    // Scarichiamo i dati remoti modificati dopo sinceHlc
    final packet = await _repo.pull(sinceHlc: sinceHlc);

    if (packet != null && !packet.isEmpty) {
      // Troviamo l'HLC più alto nel pacchetto ricevuto per aggiornare il nostro progresso
      String maxHlc = sinceHlc;

      for (final g in packet.groups) {
        final hlc = g['hlc'] as String;
        if (hlc.compareTo(maxHlc) > 0) maxHlc = hlc;
      }
      for (final e in packet.expenses) {
        final hlc = e['hlc'] as String;
        if (hlc.compareTo(maxHlc) > 0) maxHlc = hlc;
      }

      // Salviamo l'HLC aggiornato nelle SharedPreferences
      await prefs.setString('last_sync_hlc', maxHlc);
      print(
        "SyncService [Pull]: Scaricati nuovi dati remoti. Nuovo HLC di sincronizzazione: $maxHlc",
      );
    } else {
      print("SyncService [Pull]: Nessun nuovo dato sul server.");
    }
  }
}
