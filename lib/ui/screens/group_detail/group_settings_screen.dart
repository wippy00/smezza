import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:smezza/ui/providers/users_provider.dart';
import '../../../data/database.dart';
import '../../../core/hlc/hlc_manager.dart';
import '../../../core/identity/identity_manager.dart';

class GroupSettingsScreen extends ConsumerStatefulWidget {
  final GroupsTableData group;
  const GroupSettingsScreen({super.key, required this.group});

  @override
  ConsumerState<GroupSettingsScreen> createState() =>
      _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.group.name);
  }

  void _saveName() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty || newName == widget.group.name) return;

    final db = GetIt.I<AppDatabase>();
    final identity = GetIt.I<IdentityService>();
    final hlc = Hlc.now(identity.uuid);

    await db.groupsDao.renameGroup(widget.group.id, newName, hlc.toString());
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nome aggiornato!')));
    }
  }

  void _removeMember(String userId) async {
    final db = GetIt.I<AppDatabase>();
    final identity = GetIt.I<IdentityService>();
    final hlc = Hlc.now(identity.uuid);

    await db.groupsDao.removeMemberFromGroup(
      widget.group.id,
      userId,
      hlc.toString(),
    );
  }

  void _addMember(String userId) async {
    final db = GetIt.I<AppDatabase>();
    final identity = GetIt.I<IdentityService>();
    final hlc = Hlc.now(identity.uuid);

    await db.groupsDao.addMemberToGroup(
      widget.group.id,
      userId,
      hlc.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = GetIt.I<IdentityService>().uuid;
    final allUsersAsync = ref.watch(allUsersProvider);
    final db = GetIt.I<AppDatabase>();

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni Gruppo')),
      body: StreamBuilder<GroupsTableData>(
        stream: (db.select(
          db.groupsTable,
        )..where((t) => t.id.equals(widget.group.id))).watchSingle(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final group = snapshot.data!;
          final memberIds = group.memberIds.isEmpty
              ? <String>[]
              : group.memberIds.split(',');
          if (!memberIds.contains(group.ownerId)) memberIds.add(group.ownerId);

          final bool isOwner = group.ownerId == myId;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _nameCtrl,
                enabled: isOwner,
                decoration: const InputDecoration(
                  labelText: 'Nome Gruppo',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _saveName(),
              ),
              const SizedBox(height: 8),
              if (isOwner)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _saveName,
                    child: const Text('Salva nome'),
                  ),
                ),
              const SizedBox(height: 24),
              Text('Membri', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              allUsersAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Errore: $e'),
                data: (allUsers) {
                  final currentMembers = allUsers
                      .where((u) => memberIds.contains(u.id))
                      .toList();
                  final addable = allUsers
                      .where((u) => !memberIds.contains(u.id) && !u.isMe)
                      .toList();

                  return Column(
                    children: [
                      ...currentMembers.map((u) {
                        final isThisOwner = u.id == group.ownerId;
                        return ListTile(
                          leading: Icon(
                            isThisOwner ? Icons.shield : Icons.person_outline,
                          ),
                          title: Text(u.isMe ? 'Tu' : u.name),
                          subtitle: Text(isThisOwner ? 'Owner' : 'Membro'),
                          trailing: (isOwner && !isThisOwner)
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removeMember(u.id),
                                )
                              : null,
                        );
                      }),
                      if (isOwner && addable.isNotEmpty) ...[
                        const Divider(),
                        Text(
                          'Aggiungi',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        ...addable.map(
                          (u) => ListTile(
                            leading: const Icon(
                              Icons.person_add_alt_1_outlined,
                            ),
                            title: Text(u.name),
                            onTap: () => _addMember(u.id),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
