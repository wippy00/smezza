import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'home/home_screen.dart';
import 'account/account_screen.dart';
import '../providers/users_provider.dart';
import '/data/database.dart';
import '/core/hlc/hlc_manager.dart';
import '/core/identity/identity_manager.dart';

class MainContainerScreen extends StatefulWidget {
  const MainContainerScreen({super.key});

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const HomeScreen(), // Tab 0: Gruppi
    const FriendsScreen(), // Tab 1: Amici (Reale!)
    const _PlaceholderScreen(
      title: 'Attività',
      icon: Icons.history,
    ), // Tab 2: Placeholder
    const AccountScreen(), // Tab 3: Account
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Gruppi',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Amici',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history_toggle_off),
            label: 'Attività',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

// ================= SCHERMATA AMICI REALE =================
class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  // Mostra il dialog M3 per inserire l'amico tramite chiave pubblica (ID)
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
                final hlc = Hlc.now(identity.uuid);

                // Salviamo l'amico nel nostro database SQLite locale
                await db.usersDao.upsertUser(
                  UsersTableCompanion.insert(
                    id: key, // La chiave pubblica dell'amico È il suo ID unico globale
                    name: name,
                    hlc: hlc.toString(),
                  ),
                );

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
          // Filtriamo via "Me" dalla lista amici per mostrare solo le altre persone
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

// Placeholder
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
