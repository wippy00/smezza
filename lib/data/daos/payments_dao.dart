import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/payments_table.dart';

part 'payments_dao.g.dart';

@DriftAccessor(tables: [PaymentsTable])
class PaymentsDao extends DatabaseAccessor<AppDatabase>
    with _$PaymentsDaoMixin {
  PaymentsDao(super.db);

  Stream<List<PaymentsTableData>> watchByGroup(String groupId) {
    return (select(paymentsTable)
          ..where((t) => t.groupId.equals(groupId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.hlc)]))
        .watch();
  }

  Future<void> insertPayment(PaymentsTableCompanion entry) =>
      into(paymentsTable).insertOnConflictUpdate(entry);

  Future<void> softDelete(String id, String newHlc) =>
      (update(paymentsTable)..where((t) => t.id.equals(id))).write(
        PaymentsTableCompanion(
          isDeleted: const Value(true),
          isSynced: const Value(false),
          hlc: Value(newHlc),
        ),
      );
}
