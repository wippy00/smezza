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

        // 2. Calcoliamo i saldi netti del gruppo
        final netBalances = await db.expensesDao.getNetBalances(gId);

        // Alice ha pagato 15€ e consumato 5€ -> Credito netto di +10€
        expect(netBalances[uAlice], equals(10.00));
        // Bob ha pagato 0€ e consumato 5€ -> Debito netto di -5€
        expect(netBalances[uBob], equals(-5.00));
        // Charlie ha pagato 0€ e consumato 5€ -> Debito netto di -5€
        expect(netBalances[uCharlie], equals(-5.00));
      },
    );
  });
}
