import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '/sync/sync_repository.dart';
import '/data/remote/pocketbase_repository.dart';
import '/core/identity/identity_manager.dart';
import '/sync/sync_service.dart';

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
    final identity = GetIt.I<IdentityService>();

    if (recoveryKey != null && recoveryKey.trim().isNotEmpty) {
      await identity.importKey(recoveryKey.trim());
    }

    // Verifica ANCHE se non c'è recovery: la chiave locale deve combaciare col server
    final match = await repo.verifyIdentityMatchesServer(email, password);
    if (!match) {
      throw Exception(
        'La chiave locale non corrisponde a questo account. Login bloccato.',
      );
    }

    await repo.login(email, password);

    final syncService = GetIt.I<SyncService>();
    await syncService.pullRemoteChanges();

    state = true;
  }

  Future<void> register(String email, String password, String name) async {
    final repo = GetIt.I<SyncRepository>() as PocketbaseRepository;
    final identity = GetIt.I<IdentityService>();

    await identity
        .forceNewIdentity(); // device condiviso: mai ereditare chiave vecchia

    await repo.register(email, password, name);
    await identity.resetBackupFlag();

    state = true;
  }

  Future<void> logout() async {
    final repo = GetIt.I<SyncRepository>() as PocketbaseRepository;
    await repo.logout();
    await GetIt.I<IdentityService>().wipeIdentity();
    state = false;
  }
}

// 3. Esponiamo l'autenticazione usando NotifierProvider invece di StateNotifierProvider
final authProvider = NotifierProvider<AuthNotifier, bool>(() {
  return AuthNotifier();
});
