import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../../providers/auth_provider.dart';
import '/core/identity/identity_manager.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

// class _AuthScreenState {} // Ignora, serve solo a Riverpod internamente

class _AccountScreenState extends ConsumerState<AccountScreen> {
  String _privateKeyB64 = '';
  final _restoreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrivateKey();
  }

  // Leggiamo la chiave privata in modo sicuro per mostrarla a schermo (Backup)
  void _loadPrivateKey() async {
    const storage = FlutterSecureStorage();
    // Recuperiamo il valore memorizzato nel portachiavi sicuro del telefono
    final key = await storage.read(key: 'user_private_key');
    setState(() {
      _privateKeyB64 = key ?? '';
    });
  }

  // Sovrascrive la chiave privata esistente per ripristinare l'identità
  void _restoreIdentity() async {
    final pastedKey = _restoreController.text.trim();
    if (pastedKey.isEmpty || pastedKey.length < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chiave di ripristino non valida!')),
      );
      return;
    }

    const storage = FlutterSecureStorage();
    // Salviamo la nuova chiave privata nel portachiavi sicuro
    await storage.write(key: 'user_private_key', value: pastedKey);

    // Re-inizializziamo l'IdentityService per caricare la nuova identità
    final identity = GetIt.I<IdentityService>();
    await identity.init();

    if (mounted) {
      _restoreController.clear();
      _loadPrivateKey(); // Ricarica la chiave visualizzata
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identità ripristinata con successo! Riavvia l\'app.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final identity = GetIt.I<IdentityService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Il tuo Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Scollegati',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sezione Profilo
          // Sezione Profilo con QR Code
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    child: Icon(Icons.person, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'La tua chiave pubblica (ID)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    identity.uuid,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ---> QUESTO È IL NUOVO WIDGET DEL QR CODE <---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors
                          .white, // Sfondo bianco fisso per garantire la massima scansionabilità anche nel tema scuro!
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: identity
                          .uuid, // Il testo da codificare nel QR (la chiave pubblica)
                      version: QrVersions.auto,
                      size: 180.0,
                      gapless: false,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sezione Backup della Chiave Privata
          Text(
            'Backup dell\'Identità',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'ATTENZIONE: Questa chiave ti permette di recuperare tutti i tuoi dati. Non condividerla con nessuno e salvala in un posto sicuro offline.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    _privateKeyB64,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _privateKeyB64));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chiave copiata negli appunti!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copia Chiave Privata'),
                  ),
                  const SizedBox(height: 8), // Spazio
                  // ---> PULSANTE ESPORTA IN FILE <---
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        // Ottiene la cartella Documenti del telefono
                        final directory =
                            await getApplicationDocumentsDirectory();
                        final file = File(
                          '${directory.path}/smezza_backup_key.txt',
                        );

                        // Scrive la chiave nel file
                        await file.writeAsString(_privateKeyB64);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Salvata in: ${file.path}'),
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Errore nel salvataggio: $e'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Esporta come File (.txt)'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sezione Ripristino dell'Identità
          Text(
            'Ripristina Identità',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _restoreController,
                    decoration: const InputDecoration(
                      labelText: 'Incolla qui la chiave privata',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _restoreIdentity,
                    icon: const Icon(Icons.restore),
                    label: const Text('Ripristina Identità'),
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
