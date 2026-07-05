import 'package:drift/drift.dart';

/// Copre sia rimborsi di una spesa specifica (expenseId valorizzato)
/// sia trasferimenti di denaro liberi tra due utenti (expenseId null).
class PaymentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get expenseId => text().nullable()();
  TextColumn get groupId => text()();
  TextColumn get fromUserId => text()();
  TextColumn get toUserId => text()();
  RealColumn get amount => real()();
  TextColumn get currencyCode => text()();
  TextColumn get note => text().nullable()();
  TextColumn get signature => text().nullable()();
  TextColumn get hlc => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}