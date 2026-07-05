import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:smezza/core/hlc/hlc_manager.dart';
import 'package:smezza/domain/debt/debt_simplifier.dart';
import 'package:smezza/ui/screens/group_detail/group_settings_screen.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/users_provider.dart';
import '/data/database.dart';
import '/core/identity/identity_manager.dart';
import '../add_expense/add_expense_screen.dart';
import 'expense_detail_screen.dart';
import '../../providers/payments_provider.dart';
import '../add_expense/add_payment_screen.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final GroupsTableData group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  bool _simplifyDebts = true;

  Future<ExpensesTableData?> _findExpenseForSettlement(
    AppDatabase db,
    String groupId,
    String debtorId,
    String creditorId,
  ) async {
    final expenses =
        await (db.select(db.expensesTable)
              ..where(
                (t) =>
                    t.groupId.equals(groupId) &
                    t.payerId.equals(creditorId) &
                    t.isDeleted.equals(false),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.hlc)]))
            .get();
    for (final e in expenses) {
      final hasSplit =
          await (db.select(db.splitsTable)..where(
                (t) => t.expenseId.equals(e.id) & t.userId.equals(debtorId),
              ))
              .getSingleOrNull();
      if (hasSplit != null) return e;
    }
    return null;
  }

  Future<void> _openPaymentFor(
    AppDatabase db,
    String from,
    String to,
    double amount,
  ) async {
    final expense = await _findExpenseForSettlement(
      db,
      widget.group.id,
      from,
      to,
    );
    if (expense == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nessuna spesa collegata trovata')),
        );
      }
      return;
    }
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddPaymentScreen(
            group: widget.group,
            linkedExpense: expense,
            initialFromUserId: from,
            initialAmount: amount,
          ),
        ),
      );
    }
  }

  Widget _buildHistoryTab(WidgetRef ref, String Function(String id) nameFor) {
    final expensesAsync = ref.watch(expensesProvider(widget.group.id));
    final paymentsAsync = ref.watch(paymentsProvider(widget.group.id));

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore: $e')),
      data: (expenses) {
        return paymentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Errore: $e')),
          data: (payments) {
            final items = <_HistoryItem>[
              ...expenses.map((e) => _HistoryItem.expense(e)),
              ...payments.map((p) => _HistoryItem.payment(p)),
            ]..sort((a, b) => b.hlc.compareTo(a.hlc));

            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'Nessuna attività ancora.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final when = DateTime.fromMillisecondsSinceEpoch(
                  Hlc.fromString(item.hlc).timestampMs,
                );
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      item.isPayment
                          ? Icons.swap_horiz
                          : Icons.receipt_long_outlined,
                      color: item.isDeleted ? Colors.grey : null,
                    ),
                    title: Text(
                      item.isPayment
                          ? '${nameFor(item.fromUserId!)} → ${nameFor(item.toUserId!)}'
                          : item.description!,
                      style: TextStyle(
                        decoration: item.isDeleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      '${item.amount.toStringAsFixed(2)} ${item.currencyCode} · '
                      '${when.day.toString().padLeft(2, '0')}/${when.month.toString().padLeft(2, '0')} '
                      '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}'
                      '${item.isDeleted ? ' · Eliminata' : ''}',
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSimplifiedDebts(
    AppDatabase db,
    AsyncValue<Map<String, List<Settlement>>> debtsAsync,
    String Function(String id) nameFor,
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
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openPaymentFor(
                        db,
                        settlement.from,
                        settlement.to,
                        settlement.amount,
                      ),
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
                                      text: '${nameFor(settlement.from)} ',
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
                                      text: nameFor(settlement.to),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
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

  Widget _buildRawBalances(
    AppDatabase db,
    String groupId,
    String Function(String id) nameFor,
  ) {
    return FutureBuilder<Map<String, Map<String, Map<String, double>>>>(
      future: db.expensesDao.getPairwiseDebtsByCurrency(groupId),
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
              'Tutti i conti sono in pari! 🎉',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: entries.map((curEntry) {
            final currency = curEntry.key;
            final debtorEntries = curEntry.value.entries.toList();
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
                for (final debtorEntry in debtorEntries)
                  for (final creditorEntry in debtorEntry.value.entries)
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openPaymentFor(
                          db,
                          debtorEntry.key,
                          creditorEntry.key,
                          creditorEntry.value,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.swap_horiz,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                    children: [
                                      TextSpan(
                                        text: '${nameFor(debtorEntry.key)} ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const TextSpan(text: 'deve dare '),
                                      TextSpan(
                                        text:
                                            '${creditorEntry.value.toStringAsFixed(2)} $currency ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                        ),
                                      ),
                                      const TextSpan(text: 'a '),
                                      TextSpan(
                                        text: nameFor(creditorEntry.key),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right),
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

  @override
  Widget build(BuildContext context) {
    final myId = GetIt.I<IdentityService>().uuid;
    final db = GetIt.I<AppDatabase>();

    final expensesAsync = ref.watch(expensesProvider(widget.group.id));
    final debtsAsync = ref.watch(simplifiedDebtsProvider(widget.group.id));
    final membersAsync = ref.watch(groupMembersProvider(widget.group.id));

    final namesById = <String, String>{};
    membersAsync.whenData((members) {
      for (final m in members) {
        namesById[m.id] = m.isMe ? 'Tu' : m.name;
      }
    });
    String nameFor(String id) => namesById[id] ?? 'Utente sconosciuto';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.group.name),
          actions: [
            _SyncStatusIcon(
              isSynced: widget.group.isSynced,
              syncError: widget.group.syncError,
            ),
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
              Tab(icon: Icon(Icons.history_outlined), text: 'Cronologia'),
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
                        final bool isInvolved = isPayer || isParticipant;

                        Color itemColor;
                        IconData itemIcon;

                        if (isPayer) {
                          itemColor = Colors.green.shade700;
                          itemIcon = Icons.arrow_upward_rounded;
                        } else if (isParticipant) {
                          itemColor = Colors.red.shade700;
                          itemIcon = Icons.arrow_downward_rounded;
                        } else {
                          itemColor = Colors.grey.shade600;
                          itemIcon = Icons.remove_circle_outline_rounded;
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
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExpenseDetailScreen(
                                  expense: expense,
                                  group: widget.group,
                                ),
                              ),
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
                              subtitle: isInvolved
                                  ? Text(
                                      '${nameFor(expense.payerId)} ha pagato ${expense.amount.toStringAsFixed(2)} ${expense.currencyCode}',
                                      style: TextStyle(
                                        color: itemColor,
                                        fontSize: 12,
                                      ),
                                    )
                                  : const Text(
                                      'Non ti riguarda',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isInvolved)
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
                                ],
                              ),
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
                      ? _buildSimplifiedDebts(db, debtsAsync, nameFor)
                      : _buildRawBalances(db, widget.group.id, nameFor),
                ),
              ],
            ),

            _buildHistoryTab(ref, nameFor),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'add_expense',
          tooltip: 'Aggiungi spesa',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddExpenseScreen(group: widget.group),
              ),
            );
          },
          child: const Icon(Icons.add_card),
        ),
      ),
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

class _HistoryItem {
  final bool isPayment;
  final String hlc;
  final double amount;
  final String currencyCode;
  final bool isDeleted;
  final String? description;
  final String? fromUserId;
  final String? toUserId;

  _HistoryItem._({
    required this.isPayment,
    required this.hlc,
    required this.amount,
    required this.currencyCode,
    required this.isDeleted,
    this.description,
    this.fromUserId,
    this.toUserId,
  });

  factory _HistoryItem.expense(ExpensesTableData e) => _HistoryItem._(
    isPayment: false,
    hlc: e.hlc,
    amount: e.amount,
    currencyCode: e.currencyCode,
    isDeleted: e.isDeleted,
    description: e.description,
  );

  factory _HistoryItem.payment(PaymentsTableData p) => _HistoryItem._(
    isPayment: true,
    hlc: p.hlc,
    amount: p.amount,
    currencyCode: p.currencyCode,
    isDeleted: p.isDeleted,
    fromUserId: p.fromUserId,
    toUserId: p.toUserId,
  );
}
