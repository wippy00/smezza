import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';
import '../../providers/users_provider.dart';
import '../../../data/database.dart';
import '../../../domain/splitting/equal_splitter.dart';
import '../../../core/identity/identity_manager.dart';
import 'package:drift/drift.dart' show Value;

class AddExpenseScreen extends ConsumerStatefulWidget {
  final GroupsTableData group;

  const AddExpenseScreen({super.key, required this.group});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedPayerId;
  final Set<String> _selectedParticipants = {};
  late String _selectedCurrency;

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
    _selectedPayerId = GetIt.I<IdentityService>().uuid;
    _selectedCurrency = widget.group.currencyCode;
  }

  void _saveExpense() async {
    final desc = _descController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (desc.isEmpty ||
        amount <= 0.0 ||
        _selectedPayerId == null ||
        _selectedParticipants.isEmpty) {
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
    final participantsList = _selectedParticipants.toList();

    final splitResults = splitter.calculate(
      totalAmount: amount,
      userIds: participantsList,
    );

    final expenseId = const Uuid().v4();
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
      date: Value(DateTime.now()),
      splitType: 'EQUAL',
      hlc: hlc.toString(),
      signature: Value(signature),
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

    await db.expensesDao.createExpenseWithSplits(
      expenseCompanion,
      splitsCompanions,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(groupMembersProvider(widget.group.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Nuova Spesa')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Errore: $err')),
        data: (users) {
          final uniqueUsers = <dynamic>[];
          final ids = <String>{};
          for (final u in users) {
            if (ids.add(u.id)) {
              uniqueUsers.add(u);
            }
          }

          if (_selectedParticipants.isEmpty && uniqueUsers.isNotEmpty) {
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

          if (activePayerId != _selectedPayerId) {
            _selectedPayerId = activePayerId;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Descrizione (es. Spesa, Birre)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Importo + Valuta sulla stessa riga: il simbolo della valuta
              // basta da solo a dare senso al campo, niente prefixIcon extra.
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
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCurrency = val);
                        }
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
                items: uniqueUsers.map((u) {
                  return DropdownMenuItem<String>(
                    value: u.id,
                    child: Text(u.isMe ? '${u.name} (io)' : u.name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedPayerId = val;
                  });
                },
              ),
              const SizedBox(height: 24),

              Text(
                'Divisa tra:',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                          } else {
                            if (_selectedParticipants.length > 1) {
                              _selectedParticipants.remove(u.id);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: _saveExpense,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.save_outlined),
                label: const Text(
                  'Salva Spesa',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}