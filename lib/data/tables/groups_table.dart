import 'package:drift/drift.dart';

class GroupsTable extends Table {
  TextColumn get id => text()(); // UUID v4 generato sul dispositivo
  TextColumn get name => text()();
  TextColumn get currencyCode => text()(); // "EUR", "USD", ecc.
  TextColumn get ownerId => text()(); // ID dell'utente proprietario (FK → users.id)
  TextColumn get hlc => text()();
  TextColumn get signature => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
