import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/expenses_table.dart';
import '../tables/splits_table.dart';

part 'expenses_dao.g.dart';

@DriftAccessor(tables: [ExpensesTable, SplitsTable])
class ExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$ExpensesDaoMixin {
  ExpensesDao(super.db);

  // Monitora le spese non cancellate di un gruppo in ordine decrescente di HLC (più recenti prima)
  Stream<List<ExpensesTableData>> watchByGroup(String groupId) {
    return (select(expensesTable)
          ..where((t) => t.groupId.equals(groupId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.hlc)]))
        .watch();
  }

  // Scrive una spesa e le sue quote in modo atomico (se uno fallisce, la transazione fallisce)
  Future<void> createExpenseWithSplits(
    ExpensesTableCompanion expense,
    List<SplitsTableCompanion> splits,
  ) async {
    await transaction(() async {
      await into(expensesTable).insertOnConflictUpdate(expense);
      for (final split in splits) {
        await into(splitsTable).insertOnConflictUpdate(split);
      }
    });
  }

  // Calcola il saldo netto di ogni utente in un gruppo (Credito - Debito)
  Future<Map<String, double>> getNetBalances(String groupId) async {
    final expenses =
        await (select(expensesTable)..where(
              (t) => t.groupId.equals(groupId) & t.isDeleted.equals(false),
            ))
            .get();

    final balances = <String, double>{};

    for (final expense in expenses) {
      // Chi ha pagato riceve un credito per l'intero importo
      balances[expense.payerId] =
          (balances[expense.payerId] ?? 0.0) + expense.amount;

      // Recuperiamo gli split associati a questa spesa
      final splits = await (select(
        splitsTable,
      )..where((t) => t.expenseId.equals(expense.id))).get();

      // Ogni partecipante viene addebitato della propria quota
      for (final split in splits) {
        balances[split.userId] =
            (balances[split.userId] ?? 0.0) - split.calculatedAmount;
      }
    }
    return balances;
  }

  Future<void> softDeleteExpense(String id, String newHlc) async {
    await (update(expensesTable)..where((t) => t.id.equals(id))).write(
      ExpensesTableCompanion(
        isDeleted: const Value(true),
        isSynced: const Value(false),
        hlc: Value(newHlc),
      ),
    );
  }
}
