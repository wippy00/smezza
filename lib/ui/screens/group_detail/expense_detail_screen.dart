import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../data/database.dart';
import '../../../core/identity/identity_manager.dart';
import '../../../core/hlc/hlc_manager.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final ExpensesTableData expense;
  final GroupsTableData group;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    required this.group,
  });

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Elimina Spesa'),
          content: Text(
            'Sei sicuro di voler eliminare "${expense.description}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final db = GetIt.I<AppDatabase>();
                final identity = GetIt.I<IdentityService>();
                final hlc = identity.nextHlc();

                await db.expensesDao.softDeleteExpense(
                  expense.id,
                  hlc.toString(),
                );
                if (context.mounted) {
                  Navigator.pop(context); // chiude il dialog
                  Navigator.pop(context); // chiude questa schermata
                }
              },
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final myId = GetIt.I<IdentityService>().uuid;
    final db = GetIt.I<AppDatabase>();
    final theme = Theme.of(context);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(
      Hlc.fromString(expense.hlc).timestampMs,
    );
    final bool isPayer = expense.payerId == myId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettagli Spesa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifica',
            onPressed: () {
              // La modifica di una spesa esistente non è ancora
              // implementata (AddExpenseScreen oggi crea solo nuove spese).
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Modifica spesa non ancora disponibile'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Elimina',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: FutureBuilder<List<SplitsTableData>>(
        future: (db.select(
          db.splitsTable,
        )..where((t) => t.expenseId.equals(expense.id))).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final splits = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${expense.amount.toStringAsFixed(2)} ${expense.currencyCode}',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              FutureBuilder<UsersTableData?>(
                future:
                    (db.select(db.usersTable)
                          ..where((t) => t.id.equals(expense.payerId)))
                        .getSingleOrNull(),
                builder: (context, snap) {
                  final name = snap.data?.name ?? expense.payerId;
                  final label = isPayer ? '$name (io)' : name;
                  return _InfoTile(
                    icon: Icons.person_outline,
                    label: 'Pagata da',
                    value: label,
                  );
                },
              ),
              if (expense.date != null)
                _InfoTile(
                  icon: Icons.event_outlined,
                  label: 'Data spesa',
                  value: _formatDate(expense.date!),
                ),
              _InfoTile(
                icon: Icons.history_outlined,
                label: 'Ultimo aggiornamento',
                value: _formatDate(updatedAt),
              ),
              const SizedBox(height: 4),
              Text(
                'Cronologia dettagliata delle modifiche non disponibile.',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Text(
                'Quote',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...splits.map((split) {
                final isMe = split.userId == myId;
                String subtitle;
                if (isPayer && !isMe) {
                  subtitle =
                      'Deve darti ${split.calculatedAmount.toStringAsFixed(2)} ${expense.currencyCode}';
                } else if (!isPayer && isMe) {
                  subtitle =
                      'Devi dare ${split.calculatedAmount.toStringAsFixed(2)} ${expense.currencyCode}';
                } else {
                  subtitle =
                      'Quota: ${split.calculatedAmount.toStringAsFixed(2)} ${expense.currencyCode}';
                }
                return FutureBuilder<UsersTableData?>(
                  future: (db.select(
                    db.usersTable,
                  )..where((t) => t.id.equals(split.userId))).getSingleOrNull(),
                  builder: (context, snap) {
                    final name = snap.data?.name ?? split.userId;
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(isMe ? '$name (io)' : name),
                      subtitle: Text(subtitle),
                    );
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      subtitle: Text(value),
    );
  }
}
