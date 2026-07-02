import 'package:flutter_test/flutter_test.dart';
import 'package:smezza/data/database.dart'; // Adatta al tuo progetto
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() async {
    await db.close();
  });

  group('UsersDao Tests', () {
    test('Dovrebbe fare l upsert e riconoscere "Me"', () async {
      // 1. Verifichiamo che inizialmente non ci sia nessun utente "Me"
      var me = await db.usersDao.getMe();
      expect(me, isNull);

      // 2. Creiamo l'utente locale ("Me")
      final meCompanion = UsersTableCompanion.insert(
        id: 'mia_chiave_pubblica_123',
        name: 'Tu',
        isMe: Value(true), // Usiamo Value(true) per sovrascrivere il default
        hlc: '000001738933500:0000:me',
      );

      await db.usersDao.upsertUser(meCompanion);

      // 3. Verifichiamo che getMe() ora trovi l'utente corretto
      me = await db.usersDao.getMe();
      expect(me, isNotNull);
      expect(me!.name, equals('Tu'));
      expect(me.isMe, isTrue);
    });
  });
  test('Dovrebbe creare e inserire un gruppo correttamente', () async {
    final nuovoGruppo = GroupsTableCompanion.insert(
      id: 'gruppo_japan_abc',
      name: 'Vacanza Giappone',
      currencyCode: 'EUR',
      ownerId: 'utente_alice_123',
      hlc: '000001738933500:0000:alice',
    );

    await db.into(db.groupsTable).insert(nuovoGruppo);

    final gruppi = await db.select(db.groupsTable).get();
    expect(gruppi.length, equals(1));
    expect(gruppi.first.name, equals('Vacanza Giappone'));
    expect(gruppi.first.isSynced, isFalse);
  });
}
