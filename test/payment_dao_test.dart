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

  PaymentsTableCompanion buildPayment({
    required String id,
    required String groupId,
    required String hlc,
    String from = 'alice',
    String to = 'bob',
    double amount = 10.0,
  }) {
    return PaymentsTableCompanion.insert(
      id: id,
      groupId: groupId,
      fromUserId: from,
      toUserId: to,
      amount: amount,
      currencyCode: 'EUR',
      hlc: hlc,
    );
  }

  group('PaymentsDao Tests', () {
    test(
      'insertPayment dovrebbe salvare un pagamento non sincronizzato',
      () async {
        await db.paymentsDao.insertPayment(
          buildPayment(id: 'p1', groupId: 'g1', hlc: '000001:0000:alice'),
        );

        final pagamenti = await db.paymentsDao.watchByGroup('g1').first;
        expect(pagamenti.length, equals(1));
        expect(pagamenti.first.isSynced, isFalse);
        expect(pagamenti.first.amount, equals(10.0));
      },
    );

    test(
      'watchByGroup dovrebbe filtrare per gruppo e ordinare per hlc decrescente',
      () async {
        await db.paymentsDao.insertPayment(
          buildPayment(id: 'vecchio', groupId: 'g1', hlc: '000001:0000:alice'),
        );
        await db.paymentsDao.insertPayment(
          buildPayment(id: 'recente', groupId: 'g1', hlc: '000002:0000:alice'),
        );
        await db.paymentsDao.insertPayment(
          buildPayment(
            id: 'altro_gruppo',
            groupId: 'g2',
            hlc: '000003:0000:alice',
          ),
        );

        final pagamenti = await db.paymentsDao.watchByGroup('g1').first;

        expect(pagamenti.length, equals(2));
        // Il più recente (hlc più alto) deve arrivare per primo
        expect(pagamenti.first.id, equals('recente'));
        expect(pagamenti.last.id, equals('vecchio'));
      },
    );

    test('watchByGroup dovrebbe escludere i pagamenti cancellati', () async {
      await db.paymentsDao.insertPayment(
        buildPayment(id: 'p1', groupId: 'g1', hlc: '000001:0000:alice'),
      );
      await db.paymentsDao.insertPayment(
        buildPayment(id: 'p2', groupId: 'g1', hlc: '000002:0000:alice'),
      );

      await db.paymentsDao.softDelete('p2', '000003:0000:alice');

      final pagamenti = await db.paymentsDao.watchByGroup('g1').first;
      expect(pagamenti.length, equals(1));
      expect(pagamenti.first.id, equals('p1'));
    });

    test(
      'softDelete dovrebbe marcare isDeleted e isSynced=false con nuovo hlc',
      () async {
        await db.paymentsDao.insertPayment(
          buildPayment(id: 'p1', groupId: 'g1', hlc: '000001:0000:alice'),
        );

        await db.paymentsDao.softDelete('p1', '000009:0000:alice');

        final pagamento = await (db.select(
          db.paymentsTable,
        )..where((t) => t.id.equals('p1'))).getSingle();

        expect(pagamento.isDeleted, isTrue);
        expect(pagamento.isSynced, isFalse);
        expect(pagamento.hlc, equals('000009:0000:alice'));
      },
    );
  });
}
