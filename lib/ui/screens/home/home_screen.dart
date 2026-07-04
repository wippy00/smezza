import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import '../../providers/groups_provider.dart';
import '../../../data/database.dart';
import '../../../core/hlc/hlc_manager.dart';
import '../../../core/identity/identity_manager.dart';
import '../group_detail/group_detail_screen.dart';

import '/sync/sync_service.dart';

import 'package:drift/drift.dart' show Value;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Funzione per mostrare il Dialog M3 di creazione gruppo
  void _showAddGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedCurrency = 'EUR';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nuovo Gruppo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome Gruppo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Valuta',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'EUR', child: Text('Euro (€)')),
                  DropdownMenuItem(value: 'USD', child: Text('Dollaro (\$)')),
                  DropdownMenuItem(value: 'GBP', child: Text('Sterlina (£)')),
                ],
                onChanged: (val) {
                  if (val != null) selectedCurrency = val;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                final db = GetIt.I<AppDatabase>();
                final identity = GetIt.I<IdentityService>();

                final gId = const Uuid().v4();
                final hlc = Hlc.now(identity.uuid);

                // --- CALCOLO DELLA FIRMA DEL GRUPPO ---
                // Payload canonico: "id|nome|valuta|proprietario|hlc"
                final payload =
                    '$gId|${nameController.text.trim()}|$selectedCurrency|${identity.uuid}|${hlc.toString()}';

                final signature = await identity.sign(payload);
                // --------------------------------------

                await db.groupsDao.upsertGroup(
                  GroupsTableCompanion.insert(
                    id: gId,
                    name: nameController.text.trim(),
                    currencyCode: selectedCurrency,
                    ownerId: identity.uuid,
                    memberIds: Value(identity.uuid),
                    hlc: hlc.toString(),
                    signature: Value(
                      signature,
                    ), // Salviamo la firma crittografica!
                  ),
                );

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Crea'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteGroup(BuildContext context, GroupsTableData group) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Elimina Gruppo'),
          content: Text(
            'Sei sicuro di voler eliminare il gruppo "${group.name}"? Tutti i dati verranno rimossi.',
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
                final hlc = Hlc.now(identity.uuid);

                // Eseguiamo il soft-delete locale
                await db.groupsDao.softDeleteGroup(group.id, hlc.toString());
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch si mette in ascolto del provider.
    // Se i dati sul DB cambiano, l'intero metodo build viene ricalcolato.
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar.large(
            title: const Text('I tuoi Gruppi'),
            actions: [
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'Sincronizza ora',
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sincronizzazione in corso...'),
                      duration: Duration(seconds: 1),
                    ),
                  );

                  final syncService = GetIt.I<SyncService>();

                  // Recuperiamo l'esito della sincronizzazione (true/false)
                  final success = await syncService.sync();

                  if (context.mounted) {
                    // Rimuove la notifica precedente "Sincronizzazione in corso"
                    ScaffoldMessenger.of(context).clearSnackBars();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Sincronizzazione completata!'
                              : 'Errore di sincronizzazione! Controlla la connessione o le collezioni.',
                        ),
                        // In caso di errore coloriamo la notifica di rosso (Material 3 Error Color)
                        backgroundColor: success
                            ? null
                            : Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
        body: groupsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Errore: $err')),
          data: (groups) {
            if (groups.isEmpty) {
              return const Center(
                child: Text(
                  'Nessun gruppo. Creane uno col tasto in basso!',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.group_outlined),
                    ),
                    title: Text(
                      group.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Valuta: ${group.currencyCode}'),
                    // Aggiungiamo il tasto cestino
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDeleteGroup(context, group),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupDetailScreen(group: group),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      // Pulsante di azione fluttuante M3 (un quadrato molto arrotondato)
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => _showAddGroupDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
