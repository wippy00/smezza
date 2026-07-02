import 'package:flutter_test/flutter_test.dart';
import 'package:smezza/sync/merge_engine.dart';
import 'package:smezza/sync/sync_packet.dart';
import 'package:smezza/data/database.dart';
// import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  late AppDatabase db;
  late MergeEngine mergeEngine;

  setUp(() {
    db = AppDatabase.inMemory();
    mergeEngine = MergeEngine(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Sync & MergeEngine Tests', () {
    test(
      'Dovrebbe applicare un pacchetto dati e gestire i conflitti HLC',
      () async {
        // 1. Scriviamo un record locale "vecchio" (HLC: 1000)
        await db
            .into(db.groupsTable)
            .insert(
              GroupsTableCompanion.insert(
                id: 'vacanza_roma',
                name: 'Roma Locale',
                currencyCode: 'EUR',
                ownerId: 'alice_123',
                hlc: '000000000001000:0000:alice',
              ),
            );

        // 2. Creiamo un pacchetto remoto in cui lo stesso gruppo è più recente (HLC: 2000)
        // e c'è anche un gruppo completamente nuovo
        final packet = SyncPacket(
          senderUserId: 'bob_456',
          sinceHlc: '000000000000000:0000:bob',
          groups: [
            // Conflitto: stesso ID, ma HLC 2000 > 1000 locale. Deve essere aggiornato!
            {
              'id': 'vacanza_roma',
              'name': 'Roma Remota (Aggiornata)',
              'currencyCode': 'EUR',
              'ownerId': 'alice_123',
              'hlc': '000000000002000:0000:server',
              'isDeleted': false,
              'isSynced': true,
            },
            // Record Nuovo: deve essere inserito
            {
              'id': 'vacanza_milano',
              'name': 'Treno Pe Roma Remota',
              'currencyCode': 'EUR',
              'ownerId': 'bob_456',
              'hlc': '000000000001500:0000:server',
              'isDeleted': false,
              'isSynced': true,
            },
          ],
        );

        // Applichiamo il pacchetto
        await mergeEngine.applyPacket(packet);

        // 3. Verifiche
        final roma = await (db.select(
          db.groupsTable,
        )..where((t) => t.id.equals('vacanza_roma'))).getSingle();
        expect(
          roma.name,
          equals('Roma Remota (Aggiornata)'),
        ); // Ha vinto l'HLC remoto!
        expect(roma.hlc, equals('000000000002000:0000:server'));

        final milano = await (db.select(
          db.groupsTable,
        )..where((t) => t.id.equals('vacanza_milano'))).getSingle();
        expect(milano.name, equals('Treno Pe Roma Remota'));
      },
    );
  });
}
