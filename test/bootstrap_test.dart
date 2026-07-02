import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smezza/main.dart';
import 'package:smezza/core/identity/identity_manager.dart';
import 'package:smezza/data/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await GetIt.instance.reset();
  });

  group('Bootstrap Tests', () {
    test(
      'Dovrebbe inizializzare le dipendenze e creare l utente locale al primo avvio',
      () async {
        final testDb = AppDatabase.inMemory();

        // Chiamiamo la funzione definita in main.dart
        await setupDependencies(dbOverride: testDb);

        expect(GetIt.instance.isRegistered<IdentityService>(), isTrue);
        expect(GetIt.instance.isRegistered<AppDatabase>(), isTrue);

        final identity = GetIt.instance<IdentityService>();
        final db = GetIt.instance<AppDatabase>();

        final me = await db.usersDao.getMe();
        expect(me, isNotNull);
        expect(me!.id, equals(identity.uuid));
        expect(me.name, equals('Tu'));
        expect(me.isMe, isTrue);

        await testDb.close();
      },
    );
  });
}
