import 'package:drift/drift.dart';

class SplitsTable extends Table {
  TextColumn get id => text()();   // UUID v4
  TextColumn get expenseId => text()(); // FK → expenses.id
  TextColumn get userId => text()(); // FK → users.id (chi deve questa quota)
  RealColumn get calculatedAmount => real()(); // Quota finale (es. 15.00)
  RealColumn get rawValue => real().nullable()(); // Valore grezzo inserito dall'utente (opzionale)

  @override
  Set<Column> get primaryKey => {id};
}