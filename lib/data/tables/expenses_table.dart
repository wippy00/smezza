import 'package:drift/drift.dart';

class ExpensesTable extends Table {
  TextColumn get id => text()();   // UUID v4
  TextColumn get groupId => text()(); // FK → groups.id
  TextColumn get payerId => text()(); // FK → users.id (chi ha effettivamente sborsato i soldi)
  TextColumn get description => text()();
  RealColumn get amount => real()();
  TextColumn get currencyCode => text()();
  TextColumn get splitType => text()(); // EQUAL, EXACT, PERCENT, SHARES
  TextColumn get signature => text().nullable()(); // Firma crittografica (opzionale per ora)
  TextColumn get hlc => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}