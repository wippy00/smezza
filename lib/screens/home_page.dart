import 'package:flutter/material.dart';
import 'package:smezza/core/database/database.dart';
import 'package:smezza/core/database/database_service.dart';
import 'package:smezza/core/security/identity_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseService _databaseService = DatabaseService();
  List<Group> _groups = [];
  bool _isGroupsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _databaseService.close();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isGroupsLoading = true;
    });

    try {
      final groups = await _databaseService.fetchGroups();
      setState(() {
        _groups = groups;
        _isGroupsLoading = false;
      });
    } catch (e) {
      setState(() {
        _isGroupsLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore caricamento gruppi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteGroup(String id) async {
    try {
      await _databaseService.deleteGroup(id);
      await _loadGroups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gruppo eliminato'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore eliminando il gruppo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddGroupDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Crea gruppo'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome del gruppo'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci un nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Descrizione (opzionale)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Crea'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await IdentityManager.init();
      final ownerId = IdentityManager.uuid;
      final desc = descriptionController.text.trim();
      await _databaseService.createGroup(
        ownerId,
        nameController.text.trim(),
        description: desc.isNotEmpty ? desc : null,
      );
      await _loadGroups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gruppo creato con successo'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  void _showDeleteGroupDialog(Group group) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Elimina gruppo'),
          content: Text('Rimuovere "${group.name}" dal database?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteGroup(group.id);
              },
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );
  }

  double get _totalAmount {
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smezza'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadGroups),
        ],
      ),
      body: Column(
        children: [
          // Card gruppi
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'I tuoi gruppi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddGroupDialog,
                        icon: const Icon(Icons.group_add),
                        label: const Text('Nuovo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isGroupsLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_groups.isEmpty)
                    const Text(
                      'Nessun gruppo creato',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _groups.length,
                      itemBuilder: (context, index) {
                        final group = _groups[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.group),
                          ),
                          title: Text(group.name),
                          subtitle: Text(group.description ?? 'Nessuna descrizione'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                            onPressed: () => _showDeleteGroupDialog(group),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
