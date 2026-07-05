import 'package:drift/drift.dart';

class ExpensesTable extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get payerId => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get description => text()();
  RealColumn get amount => real()();
  TextColumn get currencyCode => text()();
  DateTimeColumn get date => dateTime().nullable()();
  TextColumn get splitType => text()();
  TextColumn get signature => text().nullable()();
  TextColumn get hlc => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}