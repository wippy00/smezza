import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _recoveryKeyCtrl = TextEditingController();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _showRecoveryField = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _recoveryKeyCtrl.dispose();
    super.dispose();
  }

  // --- PARSER ECCELLENTE DEI MESSAGGI DI ERRORE DI POCKETBASE ---
  String _getFriendlyErrorMessage(dynamic e) {
    if (e is ClientException) {
      final statusCode = e.statusCode;

      if (statusCode == 0) {
        return 'Impossibile connettersi al server. Controlla la tua connessione internet.';
      }

      if (statusCode == 400) {
        final message = e.response['message']?.toString() ?? '';
        if (message.contains('authenticate') || message.contains('identify')) {
          return 'Email o password errati. Riprova.';
        }

        // Estraiamo errori di validazione specifici (es. formato email errato)
        final data = e.response['data'];
        if (data is Map && data.isNotEmpty) {
          final errorsList = [];
          data.forEach((key, value) {
            if (value is Map && value['message'] != null) {
              errorsList.add('${key.toUpperCase()}: ${value['message']}');
            }
          });
          if (errorsList.isNotEmpty) {
            return 'Errore nei dati:\n${errorsList.join('\n')}';
          }
        }
        return 'Richiesta non valida. Controlla i dati inseriti.';
      }

      if (statusCode == 404) {
        return 'Servizio non trovato sul server (Errore 404).';
      }

      if (statusCode == 403) {
        return 'Non hai i permessi per accedere a questa risorsa.';
      }
    }

    // Fallback pulito se non è una ClientException conosciuta
    return e.toString().replaceAll('Exception:', '').split(':').last.trim();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isRegisterMode) {
        await ref
            .read(authProvider.notifier)
            .register(
              _emailCtrl.text.trim(),
              _passwordCtrl.text.trim(),
              _nameCtrl.text.trim(),
            );
      } else {
        final keyToSend = _showRecoveryField
            ? _recoveryKeyCtrl.text.trim()
            : null;

        await ref
            .read(authProvider.notifier)
            .login(
              _emailCtrl.text.trim(),
              _passwordCtrl.text.trim(),
              recoveryKey: keyToSend,
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getFriendlyErrorMessage(e),
            ), // Usa il parser eccellente
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.wallet_outlined,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Smezza',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  _isRegisterMode
                      ? 'Crea un account per sincronizzare'
                      : 'Accedi per iniziare a smezzare',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),

                if (_isRegisterMode) ...[
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Inserisci il tuo nome'
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Inserisci un indirizzo email valido'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                  validator: (v) => v == null || v.length < 6
                      ? 'La password deve avere almeno 6 caratteri'
                      : null,
                ),
                const SizedBox(height: 8),

                if (!_isRegisterMode) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showRecoveryField = !_showRecoveryField;
                        });
                      },
                      icon: Icon(
                        _showRecoveryField
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                      ),
                      label: const Text(
                        'Ripristina identità esistente (Chiave Privata)',
                      ),
                    ),
                  ),
                  if (_showRecoveryField) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _recoveryKeyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Chiave Privata di Ripristino',
                        helperText:
                            'Incolla la tua chiave privata per recuperare i gruppi storici',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ] else ...[
                  const SizedBox(height: 24),
                ],

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _isRegisterMode ? 'Registrati' : 'Accedi',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRegisterMode = !_isRegisterMode;
                      _showRecoveryField = false;
                      _recoveryKeyCtrl.clear();
                    });
                  },
                  child: Text(
                    _isRegisterMode
                        ? 'Hai già un account? Accedi'
                        : 'Non hai un account? Registrati',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
