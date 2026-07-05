// Rimborso spesa (expenseId valorizzato) o trasferimento libero (expenseId null)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:smezza/sync/sync_trigger.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import '../../providers/users_provider.dart';
import '../../../data/database.dart';
import '../../../core/identity/identity_manager.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  final GroupsTableData group;
  final ExpensesTableData linkedExpense; // ora required, non nullable
  final String? initialFromUserId;
  final double? initialAmount;

  const AddPaymentScreen({
    super.key,
    required this.group,
    required this.linkedExpense,
    this.initialFromUserId,
    this.initialAmount,
  });

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  final _amountController = TextEditingController();
  String? _fromUserId;

  @override
  void initState() {
    super.initState();
    _fromUserId = widget.initialFromUserId;
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(2);
    }
  }

  void _save() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0 || _fromUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi correttamente!')),
      );
      return;
    }

    final db = GetIt.I<AppDatabase>();
    final identity = GetIt.I<IdentityService>();
    final id = const Uuid().v4();
    final hlc = identity.nextHlc();

    await db.paymentsDao.insertPayment(
      PaymentsTableCompanion.insert(
        id: id,
        groupId: widget.group.id,
        fromUserId: _fromUserId!,
        toUserId: widget.linkedExpense.payerId,
        amount: amount,
        currencyCode: widget.linkedExpense.currencyCode,
        expenseId: Value(widget.linkedExpense.id),
        hlc: hlc.toString(),
      ),
    );
    triggerSync();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(groupMembersProvider(widget.group.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Registra Rimborso')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (users) {
          final payables = users
              .where((u) => u.id != widget.linkedExpense.payerId)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Rimborso per: ${widget.linkedExpense.description}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: _fromUserId,
                decoration: const InputDecoration(
                  labelText: 'Chi paga',
                  border: OutlineInputBorder(),
                ),
                items: payables
                    .map(
                      (u) => DropdownMenuItem(
                        value: u.id,
                        child: Text(u.isMe ? '${u.name} (io)' : u.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _fromUserId = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Importo (${widget.linkedExpense.currencyCode})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Conferma'),
              ),
            ],
          );
        },
      ),
    );
  }
}
