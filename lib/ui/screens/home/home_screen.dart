import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:smezza/ui/screens/group_detail/group_settings_screen.dart';
import 'package:uuid/uuid.dart';

import '../../providers/groups_provider.dart';
import '../../../data/database.dart';
import '../../../core/identity/identity_manager.dart';
import '../../providers/users_provider.dart';

import '/sync/sync_service.dart';
import 'package:smezza/sync/sync_trigger.dart';
import '../group_detail/group_detail_screen.dart';

import 'package:drift/drift.dart' show Value;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showAddGroupDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nuovo Gruppo'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nome Gruppo',
              border: OutlineInputBorder(),
            ),
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
                final hlc = identity.nextHlc();

                final payload =
                    '$gId|${nameController.text.trim()}|${identity.uuid}|${hlc.toString()}';
                final signature = await identity.sign(payload);

                await db.groupsDao.upsertGroup(
                  GroupsTableCompanion.insert(
                    id: gId,
                    name: nameController.text.trim(),
                    ownerId: identity.uuid,
                    memberIds: Value(identity.uuid),
                    hlc: hlc.toString(),
                    signature: Value(signature),
                  ),
                );

                triggerSync();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Crea'),
            ),
          ],
        );
      },
    );
  }

  void _showGroupContextMenu(
    BuildContext context,
    GroupsTableData group, {
    Offset? position,
  }) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final tapPos = position ?? overlay.size.center(Offset.zero);
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        tapPos.dx,
        tapPos.dy,
        overlay.size.width - tapPos.dx,
        overlay.size.height - tapPos.dy,
      ),
      items: const [
        PopupMenuItem(value: 'settings', child: Text('Impostazioni')),
      ],
    ).then((value) {
      if (!context.mounted || value == null) return;
      if (value == 'settings') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupSettingsScreen(group: group)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  final success = await syncService.sync();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Sincronizzazione completata!'
                              : 'Errore di sincronizzazione! Controlla la connessione o le collezioni.',
                        ),
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
        body: RefreshIndicator(
          onRefresh: () => GetIt.I<SyncService>().sync(),
          child: groupsAsync.when(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupDetailScreen(group: group),
                        ),
                      ),
                      onLongPress: () => _showGroupContextMenu(context, group),
                      onSecondaryTapDown: (details) => _showGroupContextMenu(
                        context,
                        group,
                        position: details.globalPosition,
                      ),
                      child: ListTile(
                        trailing: !group.isSynced
                            ? Tooltip(
                                message:
                                    group.syncError ??
                                    'In attesa di sincronizzazione',
                                child: Icon(
                                  group.syncError != null
                                      ? Icons.error_outline
                                      : Icons.cloud_upload_outlined,
                                  color: group.syncError != null
                                      ? Colors.orange
                                      : Colors.grey,
                                  size: 20,
                                ),
                              )
                            : null,
                        leading: const CircleAvatar(
                          child: Icon(Icons.group_outlined),
                        ),
                        title: Text(
                          group.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => _showAddGroupDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ================= SCHERMATA AMICI =================
class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  void _showAddFriendDialog(BuildContext context) {
    final nameController = TextEditingController();
    final keyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Aggiungi Amico'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome Amico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'Chiave Pubblica (ID)',
                  helperText:
                      'Chiedi all\'amico di copiarti il suo ID dal tab Account o scansiona il suo QR',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
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
                final name = nameController.text.trim();
                final key = keyController.text.trim();

                if (name.isEmpty || key.isEmpty || key.length < 30) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Inserisci dati validi! La chiave deve essere quella pubblica.',
                      ),
                    ),
                  );
                  return;
                }

                final db = GetIt.I<AppDatabase>();
                final identity = GetIt.I<IdentityService>();
                final hlc = identity.nextHlc();

                await db.usersDao.upsertUser(
                  UsersTableCompanion.insert(
                    id: key,
                    name: name,
                    hlc: hlc.toString(),
                  ),
                );

                triggerSync();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Aggiungi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final myId = GetIt.I<IdentityService>().uuid;

    return Scaffold(
      appBar: AppBar(title: const Text('I tuoi Amici')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Errore: $err')),
        data: (users) {
          final friends = users.where((u) => u.id != myId).toList();

          if (friends.isEmpty) {
            return const Center(
              child: Text(
                'Nessun amico aggiunto. Aggiungine uno col tasto +!',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(
                    friend.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'ID: ${friend.id.substring(0, 10)}...',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFriendDialog(context),
        child: const Icon(Icons.person_add_alt_1_outlined),
      ),
    );
  }
}
