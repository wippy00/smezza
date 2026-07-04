import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../../../data/database.dart';
import '../../../domain/debt/debt_simplifier.dart';

// 1. Provider per monitorare le spese del gruppo
final expensesProvider = StreamProvider.family<List<ExpensesTableData>, String>(
  (ref, groupId) {
    final db = GetIt.I<AppDatabase>();
    return db.expensesDao.watchByGroup(groupId);
  },
);

// 2. Provider magico che calcola e semplifica i debiti in tempo reale
final simplifiedDebtsByCurrencyProvider =
    FutureProvider.family<Map<String, List<Settlement>>, String>((
      ref,
      groupId,
    ) async {
      ref.watch(expensesProvider(groupId));
      final db = GetIt.I<AppDatabase>();
      final balances = await db.expensesDao.getNetBalancesByCurrency(groupId);
      return DebtSimplifier.simplifyByCurrency(balances);
    });

final simplifiedDebtsProvider =
    FutureProvider.family<Map<String, List<Settlement>>, String>((
      ref,
      groupId,
    ) async {
      ref.watch(expensesProvider(groupId));
      final db = GetIt.I<AppDatabase>();
      final balances = await db.expensesDao.getNetBalancesByCurrency(groupId);
      return DebtSimplifier.simplifyByCurrency(balances);
    });
