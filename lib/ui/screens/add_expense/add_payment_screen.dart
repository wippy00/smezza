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
  final ExpensesTableData? linkedExpense;

  const AddPaymentScreen({super.key, required this.group, this.linkedExpense});

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _fromUserId;
  String? _toUserId;

  @override
  void initState() {
    super.initState();
    _fromUserId = GetIt.I<IdentityService>().uuid;
  }

  void _save() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0 ||
        _fromUserId == null ||
        _toUserId == null ||
        _fromUserId == _toUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi correttamente!')),
      );
      return;
    }

    final db = GetIt.I<AppDatabase>();
    final identity = GetIt.I<IdentityService>();
    final id = const Uuid().v4();
    final hlc = identity.nextHlc();

    final payload =
        '$id|${widget.group.id}|$_fromUserId|$_toUserId|$amount|${hlc.toString()}';
    final signature = await identity.sign(payload);

    await db.paymentsDao.insertPayment(
      PaymentsTableCompanion.insert(
        id: id,
        groupId: widget.group.id,
        fromUserId: _fromUserId!,
        toUserId: _toUserId!,
        amount: amount,
        currencyCode: 'EUR',

        expenseId: Value(widget.linkedExpense?.id),
        note: Value(
          _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
        signature: Value(signature),
        hlc: hlc.toString(),
      ),
    );
    triggerSync();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(groupMembersProvider(widget.group.id));
    final isReimbursement = widget.linkedExpense != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isReimbursement ? 'Registra Rimborso' : 'Trasferisci Denaro',
        ),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (users) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isReimbursement)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Rimborso per: ${widget.linkedExpense!.description}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              DropdownButtonFormField<String>(
                initialValue: _fromUserId,
                decoration: const InputDecoration(
                  labelText: 'Chi paga',
                  border: OutlineInputBorder(),
                ),
                items: users
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
              DropdownButtonFormField<String>(
                initialValue: _toUserId,
                decoration: const InputDecoration(
                  labelText: 'Chi riceve',
                  border: OutlineInputBorder(),
                ),
                items: users
                    .map(
                      (u) => DropdownMenuItem(
                        value: u.id,
                        child: Text(u.isMe ? '${u.name} (io)' : u.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _toUserId = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Importo (EUR)',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Nota (opzionale)',
                  border: OutlineInputBorder(),
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
