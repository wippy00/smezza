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
  Future<Map<String, Map<String, double>>> getNetBalancesByCurrency(
    String groupId,
  ) async {
    final expenses =
        await (select(expensesTable)..where(
              (t) => t.groupId.equals(groupId) & t.isDeleted.equals(false),
            ))
            .get();

    final balances = <String, Map<String, double>>{};

    for (final expense in expenses) {
      final cur = expense.currencyCode;
      balances.putIfAbsent(cur, () => {});
      balances[cur]![expense.payerId] =
          (balances[cur]![expense.payerId] ?? 0.0) + expense.amount;

      final splits = await (select(
        splitsTable,
      )..where((t) => t.expenseId.equals(expense.id))).get();
      for (final split in splits) {
        balances[cur]![split.userId] =
            (balances[cur]![split.userId] ?? 0.0) - split.calculatedAmount;
      }
    }
    return balances;
  }

  // Calcola i debiti diretti persona->persona (senza ottimizzazione/netting
  // globale): per ogni spesa, ogni partecipante non pagante deve la propria
  // quota al pagatore. Nettato solo all'interno della stessa coppia debitore/
  // creditore, non sull'intero gruppo. Usato quando la semplificazione è
  // disattivata, così si sa sempre "chi deve dare a chi".
  Future<Map<String, Map<String, Map<String, double>>>>
  getPairwiseDebtsByCurrency(String groupId) async {
    final expenses =
        await (select(expensesTable)..where(
              (t) => t.groupId.equals(groupId) & t.isDeleted.equals(false),
            ))
            .get();

    final debts = <String, Map<String, Map<String, double>>>{};

    void addDebt(
      String currency,
      String debtor,
      String creditor,
      double amount,
    ) {
      if (debtor == creditor || amount == 0) return;
      final byCurrency = debts.putIfAbsent(currency, () => {});
      final byDebtor = byCurrency.putIfAbsent(debtor, () => {});
      byDebtor[creditor] = (byDebtor[creditor] ?? 0) + amount;
    }

    for (final expense in expenses) {
      final cur = expense.currencyCode;
      final splits = await (select(
        splitsTable,
      )..where((t) => t.expenseId.equals(expense.id))).get();

      for (final split in splits) {
        if (split.userId == expense.payerId) continue;
        addDebt(cur, split.userId, expense.payerId, split.calculatedAmount);
      }
    }

    final result = <String, Map<String, Map<String, double>>>{};
    for (final entry in debts.entries) {
      final currency = entry.key;
      final byDebtor = entry.value;
      final seen = <String>{};
      final resultByDebtor = <String, Map<String, double>>{};

      for (final a in byDebtor.keys) {
        for (final b in byDebtor[a]!.keys) {
          final pairKey = ([a, b]..sort()).join('|');
          if (seen.contains(pairKey)) continue;
          seen.add(pairKey);

          final aOwesB = byDebtor[a]?[b] ?? 0;
          final bOwesA = byDebtor[b]?[a] ?? 0;
          final net = aOwesB - bOwesA;

          if (net > 0.005) {
            resultByDebtor.putIfAbsent(a, () => {})[b] = net;
          } else if (net < -0.005) {
            resultByDebtor.putIfAbsent(b, () => {})[a] = -net;
          }
        }
      }
      if (resultByDebtor.isNotEmpty) result[currency] = resultByDebtor;
    }

    return result;
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
