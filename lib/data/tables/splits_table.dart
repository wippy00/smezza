import 'package:drift/drift.dart';

class SplitsTable extends Table {
  TextColumn get id => text()();   // UUID v4
  TextColumn get expenseId => text()(); // FK → expenses.id
  TextColumn get userId => text()(); // FK → users.id (chi deve questa quota)
  RealColumn get calculatedAmount => real()(); // Quota finale (es. 15.00)
  RealColumn get rawValue => real().nullable()(); // Valore grezzo inserito dall'utente (opzionale)

  // --- AGGIUNTO: necessari per la risoluzione dei conflitti (LWW) e per il push incrementale ---
  TextColumn get hlc => text().nullable()(); // nullable per compatibilità con le righe già esistenti
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}