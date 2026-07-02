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
final simplifiedDebtsProvider = FutureProvider.family<List<Settlement>, String>((
  ref,
  groupId,
) async {
  // Trucco reattivo: "ascoltiamo" le spese. Ogni volta che una spesa viene aggiunta,
  // modificata o eliminata, questo provider si ricalcola da solo in background!
  ref.watch(expensesProvider(groupId));

  final db = GetIt.I<AppDatabase>();

  // Calcoliamo i saldi netti dal DB
  final balances = await db.expensesDao.getNetBalances(groupId);

  // Semplifichiamo i debiti con l'algoritmo del Modulo B
  return DebtSimplifier.simplify(balances);
});
