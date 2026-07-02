import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:drift/drift.dart';

import 'core/identity/identity_manager.dart';
import 'core/hlc/hlc_manager.dart';
import 'data/database.dart';

import 'sync/merge_engine.dart';
import 'sync/sync_repository.dart';
import 'data/remote/pocketbase_repository.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/home/home_screen.dart';

import 'sync/sync_service.dart';

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
  sl.registerSingleton<MergeEngine>(mergeEngine); // Utile anche separatamente

  // 4. Registra il PocketbaseRepository come nostra sorgente di sync
  // ---> INSERISCI QUI IL LINK AL TUO SERVER POCKETBASE <---
  const String pocketbaseIp =
      'http://192.168.1.5:8090'; // Sostituisci con l'IP della tua istanza PocketBase

  sl.registerSingleton<SyncRepository>(
    PocketbaseRepository(
      pbUrl: pocketbaseIp,
      merge: mergeEngine,
      identity: identityService,
    ),
  );

  // 2. Registra poi il SyncService (il pilota, che recupera la macchina tramite sl<SyncRepository>())
  sl.registerSingleton<SyncService>(
    SyncService(
      db,
      sl<SyncRepository>(), // Recupera la macchina registrata sopra
    ),
  );

  // 5. Logica di Bootstrap locale dell'utente
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

    // ---> AGGIUNGI QUESTO BLOCCO PER CREARE ALICE E BOB DI TEST <---
    await usersDao.upsertUser(
      UsersTableCompanion.insert(
        id: 'alice_dummy_key',
        name: 'Alice',
        hlc: Hlc.now('alice_dummy_key', lastKnown: initialHlc).toString(),
      ),
    );
    await usersDao.upsertUser(
      UsersTableCompanion.insert(
        id: 'bob_dummy_key',
        name: 'Bob',
        hlc: Hlc.now('bob_dummy_key', lastKnown: initialHlc).toString(),
      ),
    );
    print("Bootstrap: Creati amici di test: Alice e Bob");
  } else {
    print("Bootstrap: Utente esistente trovato con ID: ${me.id}");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const ProviderScope(child: SmezzaApp()));
}

class SmezzaApp extends StatelessWidget {
  const SmezzaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smezza',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Segue automaticamente il tema del telefono
      home: const HomeScreen(),
    );
  }
}
