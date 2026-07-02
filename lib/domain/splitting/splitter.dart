import 'equal_splitter.dart';

/// Interfaccia comune per tutti i tipi di divisione delle spese.
abstract class Splitter {
  /// Calcola le quote per ciascun utente.
  /// INVARIANTE: La somma dei valori restituiti nella mappa deve essere
  /// esattamente uguale a [totalAmount] (gestendo i centesimi di resto).
  Map<String, double> calculate({
    required double totalAmount,
    required List<String> userIds,
    Map<String, double>? rawValues,
  });
}

/// Factory: restituisce lo Splitter corretto dato il tipo come stringa.
Splitter splitterFor(String splitType) => switch (splitType) {
  'EQUAL' => EqualSplitter(),
  // Aggiungeremo gli altri tipi (EXACT, PERCENT, SHARES) nei prossimi passi
  _ => throw ArgumentError('SplitType sconosciuto: $splitType'),
};
