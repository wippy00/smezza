import 'package:flutter_test/flutter_test.dart';
import 'package:smezza/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() async {
    await db.close();
  });

  GroupsTableCompanion buildGroup({
    required String id,
    String name = 'Gruppo Test',
    String ownerId = 'owner_1',
    String hlc = '000001738933500:0000:owner',
  }) {
    return GroupsTableCompanion.insert(
      id: id,
      name: name,
      ownerId: ownerId,
      hlc: hlc,
    );
  }

  group('GroupsDao Tests', () {
    test(
      'upsertGroup dovrebbe inserire un nuovo gruppo non sincronizzato',
      () async {
        await db.groupsDao.upsertGroup(buildGroup(id: 'g1'));

        final gruppi = await db.groupsDao.watchAllGroups().first;
        expect(gruppi.length, equals(1));
        expect(gruppi.first.isSynced, isFalse);
        expect(gruppi.first.memberIds, equals(''));
      },
    );

    test(
      'watchAllGroups dovrebbe escludere i gruppi cancellati (soft delete)',
      () async {
        await db.groupsDao.upsertGroup(buildGroup(id: 'g1', name: 'Attivo'));
        await db.groupsDao.upsertGroup(
          buildGroup(id: 'g2', name: 'Da cancellare'),
        );

        await db.groupsDao.softDeleteGroup('g2', '000001738933999:0000:owner');

        final gruppi = await db.groupsDao.watchAllGroups().first;
        expect(gruppi.length, equals(1));
        expect(gruppi.first.id, equals('g1'));
      },
    );

    test(
      'softDeleteGroup dovrebbe marcare isDeleted e isSynced=false',
      () async {
        await db.groupsDao.upsertGroup(buildGroup(id: 'g1'));
        await db.groupsDao.softDeleteGroup('g1', '000001738933999:0000:owner');

        final gruppo = await (db.select(
          db.groupsTable,
        )..where((t) => t.id.equals('g1'))).getSingle();

        expect(gruppo.isDeleted, isTrue);
        expect(gruppo.isSynced, isFalse);
        expect(gruppo.hlc, equals('000001738933999:0000:owner'));
      },
    );

    test(
      'renameGroup dovrebbe aggiornare nome, hlc e marcare da sincronizzare',
      () async {
        await db.groupsDao.upsertGroup(
          buildGroup(id: 'g1', name: 'Vecchio nome'),
        );

        await db.groupsDao.renameGroup(
          'g1',
          'Nuovo nome',
          '000001738933999:0000:owner',
        );

        final gruppo = await (db.select(
          db.groupsTable,
        )..where((t) => t.id.equals('g1'))).getSingle();

        expect(gruppo.name, equals('Nuovo nome'));
        expect(gruppo.isSynced, isFalse);
        expect(gruppo.hlc, equals('000001738933999:0000:owner'));
      },
    );

    test('addMemberToGroup dovrebbe aggiungere un membro alla lista', () async {
      await db.groupsDao.upsertGroup(buildGroup(id: 'g1'));

      await db.groupsDao.addMemberToGroup(
        'g1',
        'bob',
        '000001738933999:0000:owner',
      );

      final gruppo = await (db.select(
        db.groupsTable,
      )..where((t) => t.id.equals('g1'))).getSingle();

      expect(gruppo.memberIds, equals('bob'));
    });

    test(
      'addMemberToGroup non dovrebbe duplicare un membro già presente',
      () async {
        await db.groupsDao.upsertGroup(buildGroup(id: 'g1'));

        await db.groupsDao.addMemberToGroup('g1', 'bob', '000001:0000:owner');
        await db.groupsDao.addMemberToGroup('g1', 'bob', '000002:0000:owner');

        final gruppo = await (db.select(
          db.groupsTable,
        )..where((t) => t.id.equals('g1'))).getSingle();

        expect(gruppo.memberIds, equals('bob'));
        expect(gruppo.memberIds.split(',').length, equals(1));
      },
    );

    test(
      'addMemberToGroup dovrebbe accodare membri multipli separati da virgola',
      () async {
        await db.groupsDao.upsertGroup(buildGroup(id: 'g1'));

        await db.groupsDao.addMemberToGroup('g1', 'bob', '000001:0000:owner');
        await db.groupsDao.addMemberToGroup(
          'g1',
          'charlie',
          '000002:0000:owner',
        );

        final gruppo = await (db.select(
          db.groupsTable,
        )..where((t) => t.id.equals('g1'))).getSingle();

        expect(gruppo.memberIds, equals('bob,charlie'));
      },
    );

    test(
      'removeMemberFromGroup dovrebbe rimuovere un membro esistente',
      () async {
        await db.groupsDao.upsertGroup(buildGroup(id: 'g1'));
        await db.groupsDao.addMemberToGroup('g1', 'bob', '000001:0000:owner');
        await db.groupsDao.addMemberToGroup(
          'g1',
          'charlie',
          '000002:0000:owner',
        );

        await db.groupsDao.removeMemberFromGroup(
          'g1',
          'bob',
          '000003:0000:owner',
        );

        final gruppo = await (db.select(
          db.groupsTable,
        )..where((t) => t.id.equals('g1'))).getSingle();

        expect(gruppo.memberIds, equals('charlie'));
      },
    );

    test(
      'removeMemberFromGroup non dovrebbe mai rimuovere il proprietario',
      () async {
        await db.groupsDao.upsertGroup(
          buildGroup(id: 'g1', ownerId: 'owner_1'),
        );
        await db.groupsDao.addMemberToGroup(
          'g1',
          'owner_1',
          '000001:0000:owner',
        );

        // Tentiamo di rimuovere il proprietario: non deve succedere nulla
        await db.groupsDao.removeMemberFromGroup(
          'g1',
          'owner_1',
          '000002:0000:owner',
        );

        final gruppo = await (db.select(
          db.groupsTable,
        )..where((t) => t.id.equals('g1'))).getSingle();

        // memberIds non viene toccato: il metodo esce subito (early return)
        expect(gruppo.memberIds, equals('owner_1'));
      },
    );
  });
}
