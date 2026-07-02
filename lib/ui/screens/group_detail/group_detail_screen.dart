import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/expenses_provider.dart';
import '../../../data/database.dart';
import '../add_expense/add_expense_screen.dart';

class GroupDetailScreen extends ConsumerWidget {
  final GroupsTableData group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider(group.id));
    final debtsAsync = ref.watch(simplifiedDebtsProvider(group.id));

    return DefaultTabController(
      length: 2, // 2 Tab: Spese e Debiti
      child: Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Spese'),
              Tab(
                icon: Icon(Icons.account_balance_wallet_outlined),
                text: 'Debiti Semplificati',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- TAB 1: LISTA SPESE ---
            expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Errore: $err')),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return const Center(
                    child: Text(
                      'Ancora nessuna spesa in questo gruppo.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.shopping_bag_outlined),
                        ),
                        title: Text(
                          expense.description,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Pagato da: ${expense.payerId.substring(0, 8)}...',
                        ), // Mostra l'inizio della chiave pubblica
                        trailing: Text(
                          '${expense.amount.toStringAsFixed(2)} ${expense.currencyCode}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // --- TAB 2: BILANCI E DEBITI SEMPLIFICATI ---
            debtsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Errore: $err')),
              data: (settlements) {
                if (settlements.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tutti i conti sono in pari! 🎉',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: settlements.length,
                  itemBuilder: (context, index) {
                    final settlement = settlements[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest, // Colore di sfondo moderno M3
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.swap_horiz, color: Colors.indigo),
                            const SizedBox(width: 16),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  children: [
                                    TextSpan(
                                      text:
                                          '${settlement.from.substring(0, 6)}... ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(text: 'deve dare '),
                                    TextSpan(
                                      text:
                                          '${settlement.amount.toStringAsFixed(2)} ${group.currencyCode} ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                    const TextSpan(text: 'a '),
                                    TextSpan(
                                      text:
                                          '${settlement.to.substring(0, 6)}...',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        // Bottone per aggiungere spese (lo collegheremo presto!)
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddExpenseScreen(group: group),
              ),
            );
          },
          child: const Icon(Icons.add_card),
        ),
      ),
    );
  }
}
