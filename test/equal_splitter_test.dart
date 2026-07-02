import 'package:flutter_test/flutter_test.dart';
import 'package:smezza/domain/splitting/equal_splitter.dart';

void main() {
  group('EqualSplitter Tests', () {
    final splitter = EqualSplitter();
    final users = ['alice', 'bob', 'charlie'];

    test('Divisione perfetta (senza resto)', () {
      final result = splitter.calculate(totalAmount: 15.00, userIds: users);

      expect(result['alice'], equals(5.00));
      expect(result['bob'], equals(5.00));
      expect(result['charlie'], equals(5.00));

      // La somma totale deve essere esattamente 15.00
      final sum = result.values.reduce((a, b) => a + b);
      expect(sum, equals(15.00));
    });

    test('Divisione imperfetta (con resto di 1 centesimo)', () {
      // 10.00 / 3 = 3.3333...
      // Alice (primo elemento) dovrebbe prendersi il centesimo rimanente -> 3.34
      // Bob e Charlie -> 3.33
      final result = splitter.calculate(totalAmount: 10.00, userIds: users);

      expect(result['alice'], equals(3.34));
      expect(result['bob'], equals(3.33));
      expect(result['charlie'], equals(3.33));

      // La somma totale deve essere esattamente 10.00
      final sum = result.values.reduce((a, b) => a + b);
      expect(sum, equals(10.00));
    });

    test('Divisione imperfetta (con resto di 2 centesimi)', () {
      // 10.01 / 3 = 3.3366...
      // 10.01 € = 1001 centesimi.
      // Divisione intera: 1001 ~/ 3 = 333 centesimi (3.33€)
      // Resto: 1001 % 3 = 2 centesimi.
      // Alice (primo elemento) si prende l'intero resto -> 3.33 + 0.02 = 3.35€
      final result = splitter.calculate(totalAmount: 10.01, userIds: users);

      expect(result['alice'], equals(3.35));
      expect(result['bob'], equals(3.33));
      expect(result['charlie'], equals(3.33));

      final sum = result.values.reduce((a, b) => a + b);
      expect(sum, equals(10.01));
    });
  });
}
