import 'package:flutter_test/flutter_test.dart';
import 'package:smezza/domain/debt/debt_simplifier.dart';

void main() {
  group('DebtSimplifier Tests', () {
    test('Debito circolare perfetto dovrebbe azzerarsi', () {
      // Alice deve 10 a Bob (+10 Bob, -10 Alice)
      // Bob deve 10 a Charlie (+10 Charlie, -10 Bob)
      // Charlie deve 10 ad Alice (+10 Alice, -10 Charlie)
      // Tutti i saldi netti sono 0.0!
      final netBalances = {'alice': 0.0, 'bob': 0.0, 'charlie': 0.0};

      final results = DebtSimplifier.simplify(netBalances);

      // Nessuna transazione necessaria!
      expect(results, isEmpty);
    });

    test('Semplificazione debito a 3 vie', () {
      // Alice ha pagato 15€ per tutti (Alice ha un credito netto di +10€)
      // Bob e Charlie non hanno pagato nulla (hanno un debito netto di -5€ ciascuno)
      final netBalances = {'alice': 10.00, 'bob': -5.00, 'charlie': -5.00};

      final results = DebtSimplifier.simplify(netBalances);

      expect(results.length, equals(2));

      // Bob deve pagare 5€ ad Alice
      final bobSettle = results.firstWhere((s) => s.from == 'bob');
      expect(bobSettle.to, equals('alice'));
      expect(bobSettle.amount, equals(5.00));

      // Charlie deve pagare 5€ ad Alice
      final charlieSettle = results.firstWhere((s) => s.from == 'charlie');
      expect(charlieSettle.to, equals('alice'));
      expect(charlieSettle.amount, equals(5.00));
    });

    test('Semplificazione di catene di debito complesse', () {
      // Scenario:
      // Alice deve ricevere 10€ (+10.00)
      // Bob deve ricevere 5€ (+5.00)
      // Charlie deve dare 15€ (-15.00)
      final netBalances = {'alice': 10.00, 'bob': 5.00, 'charlie': -15.00};

      final results = DebtSimplifier.simplify(netBalances);

      // Invece di fare transazioni multiple, Charlie paga direttamente entrambi!
      expect(results.length, equals(2));

      final toAlice = results.firstWhere(
        (s) => s.from == 'charlie' && s.to == 'alice',
      );
      expect(toAlice.amount, equals(10.00));

      final toBob = results.firstWhere(
        (s) => s.from == 'charlie' && s.to == 'bob',
      );
      expect(toBob.amount, equals(5.00));
    });
  });
}
