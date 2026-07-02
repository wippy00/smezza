import 'splitter.dart';

/// Divide il totale in parti uguali.
/// Per evitare problemi di arrotondamento floating point, lavoriamo in centesimi.
/// Il resto dei centesimi viene assegnato al primo utente della lista.
class EqualSplitter implements Splitter {
  @override
  Map<String, double> calculate({
    required double totalAmount,
    required List<String> userIds,
    Map<String, double>?
    rawValues, // Non usato per la divisione in parti uguali
  }) {
    assert(userIds.isNotEmpty, 'La lista degli utenti non può essere vuota');

    final n = userIds.length;

    // 1. Convertiamo in centesimi interi (es. 10.00€ -> 1000 centesimi)
    // per evitare le imprecisioni dei numeri decimali (floating point)
    final totalCents = (totalAmount * 100).round();

    // 2. Divisione intera (~/ in Dart equivale a // in Python)
    final baseCents = totalCents ~/ n;

    // 3. Calcolo del resto dei centesimi (% in Dart è identico a Python)
    final remainder = totalCents % n;

    // 4. Creazione della mappa dei risultati
    return {
      for (var i = 0; i < n; i++)
        // Il primo utente (i == 0) si fa carico del resto dei centesimi
        userIds[i]: (baseCents + (i == 0 ? remainder : 0)) / 100.0,
    };
  }
}
