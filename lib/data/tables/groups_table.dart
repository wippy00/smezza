import 'package:drift/drift.dart';

class GroupsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get currencyCode => text()();
  TextColumn get ownerId => text()();
  TextColumn get hlc => text()();
  TextColumn get signature => text().nullable()();
  TextColumn get memberIds => text().withDefault(const Constant(''))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  // --- AGGIUNTO: stesso discorso delle spese, così vedi anche se un gruppo non si è sincronizzato.
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}