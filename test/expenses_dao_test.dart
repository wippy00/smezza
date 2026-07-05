import 'package:flutter_test/flutter_test.dart';
import 'package:smezza/data/database.dart';
// import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() async {
    await db.close();
  });

  group('ExpensesDao Tests', () {
    test(
      'Dovrebbe registrare una spesa con splits e calcolare i saldi netti',
      () async {
        const gId = 'gruppo_cena';
        const uAlice = 'alice_pubkey';
        const uBob = 'bob_pubkey';
        const uCharlie = 'charlie_pubkey';

        // 1. Inseriamo la spesa: Alice paga 15€ per tutti in parti uguali (5€ a testa)
        final spesa = ExpensesTableCompanion.insert(
          id: 'spesa_cena_1',
          groupId: gId,
          payerId: uAlice,
          description: 'Cena',
          amount: 15.00,
          currencyCode: 'EUR',
          splitType: 'EQUAL',
          hlc: '000001738933500:0000:alice',
        );

        final splits = [
          SplitsTableCompanion.insert(
            id: 's1',
            expenseId: 'spesa_cena_1',
            userId: uAlice,
            calculatedAmount: 5.00,
          ),
          SplitsTableCompanion.insert(
            id: 's2',
            expenseId: 'spesa_cena_1',
            userId: uBob,
            calculatedAmount: 5.00,
          ),
          SplitsTableCompanion.insert(
            id: 's3',
            expenseId: 'spesa_cena_1',
            userId: uCharlie,
            calculatedAmount: 5.00,
          ),
        ];

        await db.expensesDao.createExpenseWithSplits(spesa, splits);

        // 2. Calcoliamo i saldi netti del gruppo (raggruppati per valuta)
        // NB: il metodo si chiama "getNetBalancesByCurrency" (non più
        // "getNetBalances", che non esiste più nel DAO: il vecchio test
        // non compilava più dopo il refactor multi-valuta).
        final balancesByCurrency = await db.expensesDao
            .getNetBalancesByCurrency(gId);
        final netBalances = balancesByCurrency['EUR']!;

        // Alice ha pagato 15€ e consumato 5€ -> Credito netto di +10€
        expect(netBalances[uAlice], equals(10.00));
        // Bob ha pagato 0€ e consumato 5€ -> Debito netto di -5€
        expect(netBalances[uBob], equals(-5.00));
        // Charlie ha pagato 0€ e consumato 5€ -> Debito netto di -5€
        expect(netBalances[uCharlie], equals(-5.00));
      },
    );

    test('Dovrebbe separare i saldi netti per valuta diversa', () async {
      const gId = 'gruppo_multi_valuta';
      const uAlice = 'alice_pubkey';
      const uBob = 'bob_pubkey';

      // Spesa in EUR: Alice paga 10€, divisi in due
      await db.expensesDao.createExpenseWithSplits(
        ExpensesTableCompanion.insert(
          id: 'spesa_eur',
          groupId: gId,
          payerId: uAlice,
          description: 'Pranzo',
          amount: 10.00,
          currencyCode: 'EUR',
          splitType: 'EQUAL',
          hlc: '000001738933500:0000:alice',
        ),
        [
          SplitsTableCompanion.insert(
            id: 'seur1',
            expenseId: 'spesa_eur',
            userId: uAlice,
            calculatedAmount: 5.00,
          ),
          SplitsTableCompanion.insert(
            id: 'seur2',
            expenseId: 'spesa_eur',
            userId: uBob,
            calculatedAmount: 5.00,
          ),
        ],
      );

      // Spesa in USD: Bob paga 20$, divisi in due
      await db.expensesDao.createExpenseWithSplits(
        ExpensesTableCompanion.insert(
          id: 'spesa_usd',
          groupId: gId,
          payerId: uBob,
          description: 'Souvenir',
          amount: 20.00,
          currencyCode: 'USD',
          splitType: 'EQUAL',
          hlc: '000001738933501:0000:bob',
        ),
        [
          SplitsTableCompanion.insert(
            id: 'susd1',
            expenseId: 'spesa_usd',
            userId: uAlice,
            calculatedAmount: 10.00,
          ),
          SplitsTableCompanion.insert(
            id: 'susd2',
            expenseId: 'spesa_usd',
            userId: uBob,
            calculatedAmount: 10.00,
          ),
        ],
      );

      final balances = await db.expensesDao.getNetBalancesByCurrency(gId);

      expect(balances.keys, containsAll(['EUR', 'USD']));
      expect(balances['EUR']![uAlice], equals(5.00));
      expect(balances['EUR']![uBob], equals(-5.00));
      expect(balances['USD']![uBob], equals(10.00));
      expect(balances['USD']![uAlice], equals(-10.00));
    });

    test(
      'Dovrebbe calcolare i debiti diretti persona->persona (pairwise, senza netting globale)',
      () async {
        const gId = 'gruppo_pairwise';
        const uAlice = 'alice_pubkey';
        const uBob = 'bob_pubkey';
        const uCharlie = 'charlie_pubkey';

        // Alice paga 30€ per tutti e tre (10€ a testa)
        await db.expensesDao.createExpenseWithSplits(
          ExpensesTableCompanion.insert(
            id: 'spesa_1',
            groupId: gId,
            payerId: uAlice,
            description: 'Cena',
            amount: 30.00,
            currencyCode: 'EUR',
            splitType: 'EQUAL',
            hlc: '000001738933500:0000:alice',
          ),
          [
            SplitsTableCompanion.insert(
              id: 'p1',
              expenseId: 'spesa_1',
              userId: uAlice,
              calculatedAmount: 10.00,
            ),
            SplitsTableCompanion.insert(
              id: 'p2',
              expenseId: 'spesa_1',
              userId: uBob,
              calculatedAmount: 10.00,
            ),
            SplitsTableCompanion.insert(
              id: 'p3',
              expenseId: 'spesa_1',
              userId: uCharlie,
              calculatedAmount: 10.00,
            ),
          ],
        );

        // Bob paga 20€ per sé e Alice (10€ a testa)
        await db.expensesDao.createExpenseWithSplits(
          ExpensesTableCompanion.insert(
            id: 'spesa_2',
            groupId: gId,
            payerId: uBob,
            description: 'Taxi',
            amount: 20.00,
            currencyCode: 'EUR',
            splitType: 'EQUAL',
            hlc: '000001738933501:0000:bob',
          ),
          [
            SplitsTableCompanion.insert(
              id: 'p4',
              expenseId: 'spesa_2',
              userId: uAlice,
              calculatedAmount: 10.00,
            ),
            SplitsTableCompanion.insert(
              id: 'p5',
              expenseId: 'spesa_2',
              userId: uBob,
              calculatedAmount: 10.00,
            ),
          ],
        );

        final debts = await db.expensesDao.getPairwiseDebtsByCurrency(gId);
        final eurDebts = debts['EUR']!;

        // Charlie deve 10€ ad Alice (nessun'altra spesa li coinvolge insieme)
        expect(eurDebts[uCharlie]?[uAlice], equals(10.00));

        // Tra Alice e Bob: Alice deve 10€ a Bob (spesa_2), Bob deve 10€ ad
        // Alice (spesa_1) -> si nettano a vicenda -> nessun debito residuo
        expect(eurDebts[uAlice]?[uBob], isNull);
        expect(eurDebts[uBob]?[uAlice], isNull);
      },
    );

    test(
      'Dovrebbe rimuovere le vecchie quote non più presenti dopo un update',
      () async {
        const gId = 'gruppo_update';
        const uAlice = 'alice_pubkey';
        const uBob = 'bob_pubkey';
        const uCharlie = 'charlie_pubkey';

        final spesa = ExpensesTableCompanion.insert(
          id: 'spesa_upd',
          groupId: gId,
          payerId: uAlice,
          description: 'Spesa iniziale',
          amount: 20.00,
          currencyCode: 'EUR',
          splitType: 'EQUAL',
          hlc: '000001738933500:0000:alice',
        );

        await db.expensesDao.createExpenseWithSplits(spesa, [
          SplitsTableCompanion.insert(
            id: 'up1',
            expenseId: 'spesa_upd',
            userId: uAlice,
            calculatedAmount: 10.00,
          ),
          SplitsTableCompanion.insert(
            id: 'up2',
            expenseId: 'spesa_upd',
            userId: uBob,
            calculatedAmount: 10.00,
          ),
        ]);

        // Aggiorniamo la spesa: ora la dividiamo tra Alice e Charlie invece
        // che tra Alice e Bob. La quota "up2" (Bob) deve sparire.
        await db.expensesDao.updateExpenseWithSplits(
          ExpensesTableCompanion.insert(
            id: 'spesa_upd',
            groupId: gId,
            payerId: uAlice,
            description: 'Spesa modificata',
            amount: 20.00,
            currencyCode: 'EUR',
            splitType: 'EQUAL',
            hlc: '000001738933502:0000:alice',
          ),
          [
            SplitsTableCompanion.insert(
              id: 'up1',
              expenseId: 'spesa_upd',
              userId: uAlice,
              calculatedAmount: 10.00,
            ),
            SplitsTableCompanion.insert(
              id: 'up3',
              expenseId: 'spesa_upd',
              userId: uCharlie,
              calculatedAmount: 10.00,
            ),
          ],
        );

        final balances = await db.expensesDao.getNetBalancesByCurrency(gId);
        final eur = balances['EUR']!;

        expect(eur[uBob], isNull); // Bob non ha più alcuna quota
        expect(eur[uCharlie], equals(-10.00));
        expect(eur[uAlice], equals(10.00));
      },
    );

    test(
      'softDeleteExpense dovrebbe escludere la spesa da watchByGroup',
      () async {
        const gId = 'gruppo_delete';

        await db.expensesDao.createExpenseWithSplits(
          ExpensesTableCompanion.insert(
            id: 'spesa_del',
            groupId: gId,
            payerId: 'alice',
            description: 'Da cancellare',
            amount: 10.00,
            currencyCode: 'EUR',
            splitType: 'EQUAL',
            hlc: '000001738933500:0000:alice',
          ),
          [],
        );

        var attive = await db.expensesDao.watchByGroup(gId).first;
        expect(attive.length, equals(1));

        await db.expensesDao.softDeleteExpense(
          'spesa_del',
          '000001738933999:0000:alice',
        );

        attive = await db.expensesDao.watchByGroup(gId).first;
        expect(attive, isEmpty);
      },
    );
  });
}
