import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:smezza/domain/debt/debt_simplifier.dart';
import 'package:smezza/ui/screens/group_detail/group_settings_screen.dart';
import '../../providers/expenses_provider.dart';
import '/data/database.dart';
import '/core/identity/identity_manager.dart';
import '../add_expense/add_expense_screen.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final GroupsTableData group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  bool _simplifyDebts = true;

  @override
  Widget build(BuildContext context) {
    final myId = GetIt.I<IdentityService>().uuid;
    final db = GetIt.I<AppDatabase>();

    final expensesAsync = ref.watch(expensesProvider(widget.group.id));
    final debtsAsync = ref.watch(simplifiedDebtsProvider(widget.group.id));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.group.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      GroupSettingsScreen(group: widget.group),
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Spese'),
              Tab(
                icon: Icon(Icons.account_balance_wallet_outlined),
                text: 'Saldi',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
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

                    return FutureBuilder<List<SplitsTableData>>(
                      future: (db.select(
                        db.splitsTable,
                      )..where((t) => t.expenseId.equals(expense.id))).get(),
                      builder: (context, snapshot) {
                        final splits = snapshot.data ?? [];

                        final bool isPayer = expense.payerId == myId;
                        final bool isParticipant = splits.any(
                          (s) => s.userId == myId,
                        );

                        Color itemColor;
                        IconData itemIcon;
                        String roleText;

                        if (isPayer) {
                          itemColor = Colors.green.shade700;
                          itemIcon = Icons.arrow_upward_rounded;
                          roleText = 'Hai pagato tu';
                        } else if (isParticipant) {
                          itemColor = Colors.red.shade700;
                          itemIcon = Icons.arrow_downward_rounded;
                          roleText = 'Devi pagare';
                        } else {
                          itemColor = Colors.grey.shade600;
                          itemIcon = Icons.remove_circle_outline_rounded;
                          roleText = 'Non ti riguarda';
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: itemColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: itemColor.withOpacity(0.1),
                              child: Icon(itemIcon, color: itemColor),
                            ),
                            title: Text(
                              expense.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '$roleText • Da ${expense.payerId.substring(0, 6)}...',
                              style: TextStyle(color: itemColor, fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${expense.amount.toStringAsFixed(2)} ${expense.currencyCode}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: itemColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _SyncStatusIcon(
                                  isSynced: expense.isSynced,
                                  syncError: expense.syncError,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    final identity = GetIt.I<IdentityService>();
                                    final hlc = identity.nextHlc();
                                    await db.expensesDao.softDeleteExpense(
                                      expense.id,
                                      hlc.toString(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),

            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: SwitchListTile(
                      title: const Text('Semplifica risarcimenti'),
                      subtitle: const Text(
                        'Riduce al minimo il numero di transazioni tra membri',
                      ),
                      value: _simplifyDebts,
                      onChanged: (val) {
                        setState(() {
                          _simplifyDebts = val;
                        });
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: _simplifyDebts
                      ? _buildSimplifiedDebts(debtsAsync)
                      : _buildRawBalances(db, widget.group.id, myId),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddExpenseScreen(group: widget.group),
              ),
            );
          },
          child: const Icon(Icons.add_card),
        ),
      ),
    );
  }

  Widget _buildSimplifiedDebts(
    AsyncValue<Map<String, List<Settlement>>> debtsAsync,
  ) {
    return debtsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Errore: $err')),
      data: (byCurrency) {
        final entries = byCurrency.entries
            .where((e) => e.value.isNotEmpty)
            .toList();
        if (entries.isEmpty) {
          return const Center(
            child: Text(
              'Tutti i conti sono in pari! 🎉',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ...entry.value.map(
                  (settlement) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
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
                                        '${settlement.amount.toStringAsFixed(2)} ${entry.key} ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                  const TextSpan(text: 'a '),
                                  TextSpan(
                                    text: '${settlement.to.substring(0, 6)}...',
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
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRawBalances(AppDatabase db, String groupId, String myId) {
    return FutureBuilder<Map<String, Map<String, double>>>(
      future: db.expensesDao.getNetBalancesByCurrency(groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Errore: ${snapshot.error}'));
        }

        final byCurrency = snapshot.data ?? {};
        final entries = byCurrency.entries
            .where((e) => e.value.isNotEmpty)
            .toList();
        if (entries.isEmpty) {
          return const Center(
            child: Text(
              'Ancora nessun saldo da calcolare.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: entries.map((curEntry) {
            final currency = curEntry.key;
            final list = curEntry.value.entries.toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    currency,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ...list.map((entry) {
                  final userId = entry.key;
                  final amount = entry.value;

                  final bool isMe = userId == myId;
                  final String name = isMe
                      ? 'Tu'
                      : '${userId.substring(0, 8)}...';

                  Color balanceColor;
                  String textType;
                  IconData balanceIcon;

                  if (amount > 0) {
                    balanceColor = Colors.green.shade700;
                    textType = 'spetta ricevere';
                    balanceIcon = Icons.add_circle_outline_rounded;
                  } else if (amount < 0) {
                    balanceColor = Colors.red.shade700;
                    textType = 'deve dare';
                    balanceIcon = Icons.remove_circle_outline_rounded;
                  } else {
                    balanceColor = Colors.grey.shade600;
                    textType = 'è in pari';
                    balanceIcon = Icons.check_circle_outline_rounded;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Icon(balanceIcon, color: balanceColor),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '$textType nel gruppo',
                        style: TextStyle(color: balanceColor),
                      ),
                      trailing: Text(
                        '${amount.abs().toStringAsFixed(2)} $currency',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: balanceColor,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

class _SyncStatusIcon extends StatelessWidget {
  final bool isSynced;
  final String? syncError;

  const _SyncStatusIcon({required this.isSynced, required this.syncError});

  @override
  Widget build(BuildContext context) {
    if (syncError != null) {
      return IconButton(
        icon: const Icon(Icons.error_outline, color: Colors.orange, size: 20),
        tooltip: 'Errore di sincronizzazione (tocca per i dettagli)',
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Sincronizzazione fallita'),
              content: Text(syncError!),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ok'),
                ),
              ],
            ),
          );
        },
      );
    }

    if (!isSynced) {
      return const Tooltip(
        message: 'In attesa di sincronizzazione',
        child: Padding(
          padding: EdgeInsets.only(right: 4),
          child: Icon(
            Icons.cloud_upload_outlined,
            color: Colors.grey,
            size: 18,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
