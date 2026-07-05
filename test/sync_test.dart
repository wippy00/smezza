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
                ownerId: 'alice_123',
                hlc: '000000000001000:0000:alice',
              ),
            );

        // 2. Creiamo un pacchetto remoto in cui lo stesso gruppo è più recente (HLC: 2000)
        // e c'è anche un gruppo completamente nuovo
        // NB: GroupsTableData.fromJson richiede TUTTI i campi non nullable
        // della tabella (memberIds, isSynced, syncError inclusi), altrimenti
        // il merge esplode a runtime con un errore di cast su null.
        final packet = SyncPacket(
          senderUserId: 'bob_456',
          sinceHlc: '000000000000000:0000:bob',
          groups: [
            // Conflitto: stesso ID, ma HLC 2000 > 1000 locale. Deve essere aggiornato!
            {
              'id': 'vacanza_roma',
              'name': 'Roma Remota (Aggiornata)',
              'ownerId': 'alice_123',
              'hlc': '000000000002000:0000:server',
              'signature': null,
              'memberIds': '',
              'isDeleted': false,
              'isSynced': true,
              'syncError': null,
            },
            // Record Nuovo: deve essere inserito
            {
              'id': 'vacanza_milano',
              'name': 'Treno Pe Roma Remota',
              'ownerId': 'bob_456',
              'hlc': '000000000001500:0000:server',
              'signature': null,
              'memberIds': '',
              'isDeleted': false,
              'isSynced': true,
              'syncError': null,
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

    test(
      'Non dovrebbe sovrascrivere un record locale più recente del pacchetto remoto (LWW)',
      () async {
        // Il locale ha HLC 5000, più recente di quello che arriva dal server (2000)
        await db
            .into(db.groupsTable)
            .insert(
              GroupsTableCompanion.insert(
                id: 'vacanza_roma',
                name: 'Roma Locale (più recente)',
                ownerId: 'alice_123',
                hlc: '000000000005000:0000:alice',
              ),
            );

        final packet = SyncPacket(
          senderUserId: 'bob_456',
          sinceHlc: '000000000000000:0000:bob',
          groups: [
            {
              'id': 'vacanza_roma',
              'name': 'Roma Remota (vecchia)',
              'ownerId': 'alice_123',
              'hlc': '000000000002000:0000:server',
              'signature': null,
              'memberIds': '',
              'isDeleted': false,
              'isSynced': true,
              'syncError': null,
            },
          ],
        );

        await mergeEngine.applyPacket(packet);

        final roma = await (db.select(
          db.groupsTable,
        )..where((t) => t.id.equals('vacanza_roma'))).getSingle();

        // Il dato locale, più recente, deve vincere e restare invariato
        expect(roma.name, equals('Roma Locale (più recente)'));
        expect(roma.hlc, equals('000000000005000:0000:alice'));
      },
    );

    test(
      'Dovrebbe fare il merge di utenti, spese, quote e pagamenti nuovi',
      () async {
        final packet = SyncPacket(
          senderUserId: 'bob_456',
          sinceHlc: '000000000000000:0000:bob',
          users: [
            {
              'id': 'bob_456',
              'name': 'Bob',
              'isMe': false,
              'hlc': '000000000001000:0000:bob',
              'isDeleted': false,
            },
          ],
          expenses: [
            {
              'id': 'spesa_remota_1',
              'groupId': 'gruppo_x',
              'payerId': 'bob_456',
              'categoryId': null,
              'description': 'Pizza',
              'amount': 20.0,
              'currencyCode': 'EUR',
              'date': null,
              'splitType': 'EQUAL',
              'signature': null,
              'hlc': '000000000001000:0000:bob',
              'isDeleted': false,
              'isSynced': true,
              'syncError': null,
            },
          ],
          splits: [
            {
              'id': 'split_remoto_1',
              'expenseId': 'spesa_remota_1',
              'userId': 'bob_456',
              'calculatedAmount': 10.0,
              'rawValue': null,
              'hlc': '000000000001000:0000:bob',
              'isSynced': true,
              'isDeleted': false,
            },
          ],
          payments: [
            {
              'id': 'pagamento_remoto_1',
              'expenseId': null,
              'groupId': 'gruppo_x',
              'fromUserId': 'bob_456',
              'toUserId': 'alice_123',
              'amount': 5.0,
              'currencyCode': 'EUR',
              'note': null,
              'signature': null,
              'hlc': '000000000001000:0000:bob',
              'isSynced': true,
              'isDeleted': false,
              'syncError': null,
            },
          ],
        );

        await mergeEngine.applyPacket(packet);

        final bob = await (db.select(
          db.usersTable,
        )..where((t) => t.id.equals('bob_456'))).getSingle();
        expect(bob.name, equals('Bob'));

        final spesa = await (db.select(
          db.expensesTable,
        )..where((t) => t.id.equals('spesa_remota_1'))).getSingle();
        expect(spesa.description, equals('Pizza'));
        expect(spesa.amount, equals(20.0));

        final split = await (db.select(
          db.splitsTable,
        )..where((t) => t.id.equals('split_remoto_1'))).getSingle();
        expect(split.calculatedAmount, equals(10.0));

        final pagamento = await (db.select(
          db.paymentsTable,
        )..where((t) => t.id.equals('pagamento_remoto_1'))).getSingle();
        expect(pagamento.amount, equals(5.0));
        expect(pagamento.fromUserId, equals('bob_456'));
      },
    );
  });
}
