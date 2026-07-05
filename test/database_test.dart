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

    test(
      'Dovrebbe fare l\'upsert aggiornando i dati di un utente esistente (stesso id)',
      () async {
        await db.usersDao.upsertUser(
          UsersTableCompanion.insert(
            id: 'utente_1',
            name: 'Nome Vecchio',
            hlc: '000001:0000:utente_1',
          ),
        );

        await db.usersDao.upsertUser(
          UsersTableCompanion.insert(
            id: 'utente_1',
            name: 'Nome Nuovo',
            hlc: '000002:0000:utente_1',
          ),
        );

        final utenti = await db.select(db.usersTable).get();
        expect(utenti.length, equals(1)); // Nessun duplicato: stesso id
        expect(utenti.first.name, equals('Nome Nuovo'));
      },
    );

    test(
      'getMe dovrebbe "sanare" duplicati: tiene solo il primo utente con isMe=true',
      () async {
        // Scenario anomalo (es. bug di sync): due utenti marcati "Me"
        await db.usersDao.upsertUser(
          UsersTableCompanion.insert(
            id: 'utente_a',
            name: 'Io A',
            isMe: const Value(true),
            hlc: '000001:0000:a',
          ),
        );
        await db.usersDao.upsertUser(
          UsersTableCompanion.insert(
            id: 'utente_b',
            name: 'Io B',
            isMe: const Value(true),
            hlc: '000002:0000:b',
          ),
        );

        final me = await db.usersDao.getMe();
        expect(me, isNotNull);
        expect(me!.id, equals('utente_a')); // Il primo trovato resta "Me"

        // Il secondo deve essere stato "smarcato" come effetto collaterale
        final utenteB = await (db.select(
          db.usersTable,
        )..where((t) => t.id.equals('utente_b'))).getSingle();
        expect(utenteB.isMe, isFalse);
      },
    );
  });
  test('Dovrebbe creare e inserire un gruppo correttamente', () async {
    final nuovoGruppo = GroupsTableCompanion.insert(
      id: 'gruppo_japan_abc',
      name: 'Vacanza Giappone',
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
