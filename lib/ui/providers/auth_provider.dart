import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '/sync/sync_repository.dart';
import '/data/remote/pocketbase_repository.dart';
import '/core/identity/identity_manager.dart';
import '/sync/sync_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 1. Estendiamo Notifier<bool> invece di StateNotifier<bool>
class AuthNotifier extends Notifier<bool> {
  // 2. Il metodo build() sostituisce il costruttore ed esegue l'inizializzazione dello stato
  @override
  bool build() {
    final repo = GetIt.I<SyncRepository>();
    if (repo is PocketbaseRepository) {
      return repo.isLoggedIn;
    }
    return false;
  }

  Future<void> login(
    String email,
    String password, {
    String? recoveryKey,
  }) async {
    final repo = GetIt.I<SyncRepository>() as PocketbaseRepository;

    // Se l'utente ha inserito una chiave di ripristino, la salviamo prima di loggarci
    if (recoveryKey != null && recoveryKey.trim().isNotEmpty) {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'user_private_key', value: recoveryKey.trim());

      // Re-inizializziamo l'IdentityService con la nuova chiave privata appena caricata
      final identity = GetIt.I<IdentityService>();
      await identity.init();
    }

    // Effettuiamo il login su PocketBase
    await repo.login(email, password);

    // Se il login ha successo, avviamo subito un PULL completo dal server
    // per scaricare sul nuovo dispositivo tutti i gruppi e le spese storiche!
    final syncService = GetIt.I<SyncService>();
    await syncService.pullRemoteChanges();

    state = true; // Imposta lo stato a loggato
  }

  Future<void> register(String email, String password, String name) async {
    final repo = GetIt.I<SyncRepository>() as PocketbaseRepository;
    await repo.register(email, password, name);
    state = true;
  }

  void logout() {
    final repo = GetIt.I<SyncRepository>() as PocketbaseRepository;
    repo.logout();
    state = false;
  }
}

// 3. Esponiamo l'autenticazione usando NotifierProvider invece di StateNotifierProvider
final authProvider = NotifierProvider<AuthNotifier, bool>(() {
  return AuthNotifier();
});
