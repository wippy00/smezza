import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:drift/drift.dart';
import 'package:smezza/ui/providers/backup_provider.dart';
import 'package:smezza/ui/screens/backup/backup_screen.dart';

import 'core/identity/identity_manager.dart';
import 'core/hlc/hlc_manager.dart';
import '/sync/merge_engine.dart';
import '/sync/sync_repository.dart';
import '/sync/sync_service.dart';
import 'data/database.dart';
import 'data/remote/pocketbase_repository.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/main_container_screen.dart';
import 'ui/screens/auth/auth_screen.dart';
import 'ui/providers/auth_provider.dart';

final sl = GetIt.instance;

Future<void> setupDependencies({AppDatabase? dbOverride}) async {
  // 1. Inizializza l'IdentityService
  final identityService = IdentityService();
  await identityService.init();
  sl.registerSingleton<IdentityService>(identityService);

  // 2. Registra il Database
  final db = dbOverride ?? AppDatabase();
  sl.registerSingleton<AppDatabase>(db);

  // 3. Registra il MergeEngine
  final mergeEngine = MergeEngine(db);
  sl.registerSingleton<MergeEngine>(mergeEngine);

  // 4. Inizializza e registra il PocketbaseRepository
  const String pocketbaseIp =
      'https://smezza.salamini.cloud'; // Modifica con l'IP del tuo server

  final pbRepo = PocketbaseRepository(
    pbUrl: pocketbaseIp,
    merge: mergeEngine,
    identity: identityService,
  );

  // ---> INIZIALIZZAZIONE ASINCRONA DEL PERSISTENT LOGIN <---
  await pbRepo.init();
  sl.registerSingleton<SyncRepository>(pbRepo);

  // 5. Registra il SyncService
  sl.registerSingleton<SyncService>(SyncService(db, sl<SyncRepository>()));

  // 6. Logica di Bootstrap locale dell'utente
  final usersDao = db.usersDao;
  final me = await usersDao.getMe();

  if (me == null) {
    final myUuid = identityService.uuid;
    final initialHlc = Hlc.now(myUuid);

    final meCompanion = UsersTableCompanion.insert(
      id: myUuid,
      name: 'Tu',
      isMe: const Value(true),
      hlc: initialHlc.toString(),
    );

    await usersDao.upsertUser(meCompanion);
    print("Bootstrap: Creato nuovo utente locale con ID: $myUuid");
  } else {
    print("Bootstrap: Utente esistente trovato con ID: ${me.id}");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();

  runApp(const ProviderScope(child: SmezzaApp()));
}

class SmezzaApp extends ConsumerWidget {
  const SmezzaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider);

    Widget home;
    if (!isLoggedIn) {
      home = const AuthScreen();
    } else {
      final needsBackup = ref.watch(needsBackupProvider);
      home = needsBackup.when(
        data: (needs) =>
            needs ? const BackupScreen() : const MainContainerScreen(),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) => const MainContainerScreen(),
      );
    }

    return MaterialApp(
      title: 'Smezza',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: home,
    );
  }
}
