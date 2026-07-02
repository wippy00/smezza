import 'package:drift/drift.dart';

class UsersTable extends Table {
  // getter in Dart (equivalente di @property in Python)
  TextColumn get id => text()(); // Chiave pubblica Ed25519 (Base64URL)
  TextColumn get name => text()();
  BoolColumn get isMe => boolean().withDefault(const Constant(false))();
  TextColumn get hlc => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  // Definiamo la chiave primaria
  @override
  Set<Column> get primaryKey => {id};
}
