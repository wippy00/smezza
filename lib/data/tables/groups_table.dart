import 'package:drift/drift.dart';

class GroupsTable extends Table {
  TextColumn get id => text()();   // UUID v4
  TextColumn get name => text()();
  TextColumn get currencyCode => text()();   // "EUR", "JPY", ecc.
  TextColumn get ownerId => text()();   // FK → users.id
  TextColumn get hlc => text()();
  TextColumn get signature => text().nullable()();
  
  // ---> AGGIUNGIAMO I PARTECIPANTI COME STRINGA SEPARATA DA VIRGOLE (YAGNI Approved!) <---
  TextColumn get memberIds => text().withDefault(const Constant(''))();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}