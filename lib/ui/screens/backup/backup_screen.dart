// lib/ui/screens/backup/backup_screen.dart — NUOVO FILE

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '/core/identity/identity_manager.dart';
import '../../providers/backup_provider.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});
  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _confirmed = false;
  String? _key;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  void _loadKey() async {
    final identity = GetIt.I<IdentityService>();
    final k = await identity.exportKeyAsync();
    setState(() => _key = k);
  }

  @override
  Widget build(BuildContext context) {
    if (_key == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final key = _key!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup obbligatorio'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Salva questa chiave PRIMA di continuare. Se la perdi, perdi TUTTI i tuoi dati per sempre.',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Center(
                child: QrImageView(
                  data: key,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(color: Colors.black),
                  dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                key,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Clipboard.setData(ClipboardData(text: key)),
              icon: const Icon(Icons.copy),
              label: const Text('Copia'),
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v ?? false),
              title: const Text('Ho salvato la chiave in un posto sicuro'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _confirmed
                  ? () async {
                      await GetIt.I<IdentityService>().confirmBackup();
                      ref.invalidate(needsBackupProvider);
                    }
                  : null,
              child: const Text('Continua'),
            ),
          ],
        ),
      ),
    );
  }
}
