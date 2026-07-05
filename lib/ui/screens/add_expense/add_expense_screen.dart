import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:smezza/sync/sync_trigger.dart';
import 'package:uuid/uuid.dart';
import '../../providers/users_provider.dart';
import '../../../data/database.dart';
import '../../../domain/splitting/equal_splitter.dart';
import '../../../core/identity/identity_manager.dart';
import 'package:drift/drift.dart' show Value;

class AddExpenseScreen extends ConsumerStatefulWidget {
  final GroupsTableData group;
  final ExpensesTableData? existingExpense; // NUOVO: se valorizzato = modifica
  final List<SplitsTableData>? existingSplits; // NUOVO

  const AddExpenseScreen({
    super.key,
    required this.group,
    this.existingExpense,
    this.existingSplits,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedPayerId;
  final Set<String> _selectedParticipants = {};
  late String _selectedCurrency = 'EUR';
  bool _initializedFromExisting = false;

  // NUOVO: modalità "Prestito/Rimborso" invece di spesa condivisa.
  bool _isLoan = false;
  String? _loanRecipientId;

  bool get _isEditing => widget.existingExpense != null;

  static const _commonCurrencies = ['EUR', 'USD', 'GBP', 'CHF'];
  static const _currencySymbols = {
    'EUR': '€',
    'USD': '\$',
    'GBP': '£',
    'CHF': 'CHF',
  };

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.existingExpense!;
      _descController.text = e.description;
      _amountController.text = e.amount.toString();
      _selectedPayerId = e.payerId;
      _selectedCurrency = 'EUR';
      _selectedParticipants.addAll(
        (widget.existingSplits ?? []).map((s) => s.userId),
      );
      _initializedFromExisting = true;

      if (e.splitType == 'LOAN' && _selectedParticipants.isNotEmpty) {
        _isLoan = true;
        _loanRecipientId = _selectedParticipants.first;
      }
    } else {
      _selectedPayerId = GetIt.I<IdentityService>().uuid;
    }
  }

  void _saveExpense() async {
    final desc = _descController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (_isLoan && _loanRecipientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona a chi stai prestando i soldi!'),
        ),
      );
      return;
    }

    final participants = _isLoan
        ? <String>{_loanRecipientId!}
        : _selectedParticipants;

    if (desc.isEmpty ||
        amount <= 0.0 ||
        _selectedPayerId == null ||
        participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Compila tutti i campi e seleziona almeno un partecipante!',
          ),
        ),
      );
      return;
    }

    final db = GetIt.I<AppDatabase>();
    final identity = GetIt.I<IdentityService>();

    final splitter = EqualSplitter();
    final participantsList = participants.toList();
    final splitResults = splitter.calculate(
      totalAmount: amount,
      userIds: participantsList,
    );

    final expenseId = _isEditing
        ? widget.existingExpense!.id
        : const Uuid().v4();
    final hlc = identity.nextHlc();

    final payload =
        '$expenseId|${widget.group.id}|$_selectedPayerId|$amount|$_selectedCurrency|${hlc.toString()}';
    final signature = await identity.sign(payload);

    final expenseCompanion = ExpensesTableCompanion.insert(
      id: expenseId,
      groupId: widget.group.id,
      payerId: _selectedPayerId!,
      description: desc,
      amount: amount,
      currencyCode: _selectedCurrency,
      date: Value(_isEditing ? widget.existingExpense!.date : DateTime.now()),
      splitType: _isLoan ? 'LOAN' : 'EQUAL',
      hlc: hlc.toString(),
      signature: Value(signature),
      isSynced: const Value(false),
    );

    final splitsCompanions = splitResults.entries.map((entry) {
      return SplitsTableCompanion.insert(
        id: const Uuid().v4(),
        expenseId: expenseId,
        userId: entry.key,
        calculatedAmount: entry.value,
        hlc: Value(hlc.toString()),
      );
    }).toList();

    if (_isEditing) {
      await db.expensesDao.updateExpenseWithSplits(
        expenseCompanion,
        splitsCompanions,
      );
    } else {
      await db.expensesDao.createExpenseWithSplits(
        expenseCompanion,
        splitsCompanions,
      );
    }
    triggerSync();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(groupMembersProvider(widget.group.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? (_isLoan ? 'Modifica Prestito' : 'Modifica Spesa')
              : (_isLoan ? 'Nuovo Prestito' : 'Nuova Spesa'),
        ),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Errore: $err')),
        data: (users) {
          final uniqueUsers = <dynamic>[];
          final ids = <String>{};
          for (final u in users) {
            if (ids.add(u.id)) uniqueUsers.add(u);
          }

          if (!_initializedFromExisting &&
              _selectedParticipants.isEmpty &&
              uniqueUsers.isNotEmpty) {
            _selectedParticipants.addAll(
              uniqueUsers.map((u) => u.id as String),
            );
          }

          final hasSelectedPayer = uniqueUsers.any(
            (u) => u.id == _selectedPayerId,
          );
          final activePayerId = hasSelectedPayer
              ? _selectedPayerId
              : (uniqueUsers.isNotEmpty ? uniqueUsers.first.id : null);
          if (activePayerId != _selectedPayerId)
            _selectedPayerId = activePayerId;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Spesa'),
                    icon: Icon(Icons.receipt_long_outlined),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Prestito/Rimborso'),
                    icon: Icon(Icons.volunteer_activism_outlined),
                  ),
                ],
                selected: {_isLoan},
                onSelectionChanged: (selection) {
                  setState(() {
                    _isLoan = selection.first;
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: Colors.teal.withValues(alpha: 0.15),
                  selectedForegroundColor: Colors.teal[800],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: _isLoan
                      ? 'Descrizione (es. Prestito per taxi)'
                      : 'Descrizione (es. Spesa, Birre)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Importo',
                        border: const OutlineInputBorder(),
                        prefixText:
                            '${_currencySymbols[_selectedCurrency] ?? _selectedCurrency} ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<String>(
                      initialValue:
                          _commonCurrencies.contains(_selectedCurrency)
                          ? _selectedCurrency
                          : _commonCurrencies.first,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      items: _commonCurrencies
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setState(() => _selectedCurrency = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: activePayerId,
                decoration: const InputDecoration(
                  labelText: 'Chi ha pagato?',
                  border: OutlineInputBorder(),
                ),
                items: uniqueUsers
                    .map(
                      (u) => DropdownMenuItem<String>(
                        value: u.id,
                        child: Text(u.isMe ? '${u.name} (io)' : u.name),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedPayerId = val),
              ),
              const SizedBox(height: 24),
              if (_isLoan) ...[
                Text(
                  'A chi presti/rimborsi i soldi?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: uniqueUsers.any((u) => u.id == _loanRecipientId)
                      ? _loanRecipientId
                      : null,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.volunteer_activism_outlined),
                  ),
                  hint: const Text('Seleziona un amico'),
                  items: uniqueUsers
                      .where((u) => u.id != activePayerId)
                      .map(
                        (u) => DropdownMenuItem<String>(
                          value: u.id,
                          child: Text(u.name),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _loanRecipientId = val),
                ),
                const SizedBox(height: 8),
                Text(
                  'L\'intero importo sarà registrato come debito di questa persona verso di te, senza dividerlo tra altri partecipanti.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ] else ...[
                Text(
                  'Divisa tra:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: uniqueUsers.map((u) {
                      final isSelected = _selectedParticipants.contains(u.id);
                      return CheckboxListTile(
                        title: Text(u.isMe ? '${u.name} (io)' : u.name),
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedParticipants.add(u.id);
                            } else if (_selectedParticipants.length > 1) {
                              _selectedParticipants.remove(u.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _saveExpense,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _isLoan ? Colors.teal[700] : null,
                ),
                icon: Icon(
                  _isLoan
                      ? Icons.volunteer_activism_outlined
                      : Icons.save_outlined,
                ),
                label: Text(
                  _isEditing ? 'Salva Modifiche' : 'Salva',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
