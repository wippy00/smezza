class Settlement {
  final String from; // Chi deve pagare (debitore)
  final String to; // Chi deve ricevere (creditore)
  final int amountCents; // Importo in centesimi per evitare errori sui decimali

  double get amount => amountCents / 100.0;

  const Settlement({
    required this.from,
    required this.to,
    required this.amountCents,
  });
}

class DebtSimplifier {
  /// [netBalances]: mappa userId → saldo netto.
  ///   Positivo = creditore (deve ricevere soldi).
  ///   Negativo = debitore (deve dare soldi).
  static List<Settlement> simplify(Map<String, double> netBalances) {
    // 1. Convertiamo tutti i saldi in centesimi interi (evita problemi di float)
    final balancesCents = netBalances.map(
      (k, v) => MapEntry(k, (v * 100).round()),
    );

    // 2. Separiamo i creditori dai debitori
    // Usiamo il Cascade Operator (..) per ordinare la lista subito dopo averla creata
    final creditors = balancesCents.entries.where((e) => e.value > 0).toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      ); // Dal creditore più grande al più piccolo

    final debtors = balancesCents.entries.where((e) => e.value < 0).toList()
      ..sort(
        (a, b) => a.value.compareTo(b.value),
      ); // Dal debitore più negativo al meno negativo

    // Strutture mutabili temporanee per l'algoritmo greedy
    // Ogni elemento è una lista di due elementi: [userId, saldoCents]
    final mCred = creditors.map((e) => <Object>[e.key, e.value]).toList();
    final mDebt = debtors.map((e) => <Object>[e.key, e.value]).toList();

    final settlements = <Settlement>[];

    int ci = 0; // Indice del creditore corrente
    int di = 0; // Indice del debitore corrente

    while (ci < mCred.length && di < mDebt.length) {
      final credAmt = mCred[ci][1] as int;
      final debtAmt =
          -(mDebt[di][1] as int); // Rendiamo l'importo positivo per il calcolo

      // Calcoliamo l'importo minimo che si può scambiare in questa transazione
      final settleAmt = credAmt < debtAmt ? credAmt : debtAmt;

      settlements.add(
        Settlement(
          from: mDebt[di][0] as String,
          to: mCred[ci][0] as String,
          amountCents: settleAmt,
        ),
      );

      // Aggiorniamo i saldi residui
      mCred[ci][1] = credAmt - settleAmt;
      mDebt[di][1] = (mDebt[di][1] as int) + settleAmt;

      // Se il creditore o il debitore hanno saldato il loro conto, passiamo al successivo
      if ((mCred[ci][1] as int) == 0) ci++;
      if ((mDebt[di][1] as int) == 0) di++;
    }

    return settlements;
  }

  static Map<String, List<Settlement>> simplifyByCurrency(
    Map<String, Map<String, double>> balancesByCurrency,
  ) {
    return balancesByCurrency.map((k, v) => MapEntry(k, simplify(v)));
  }
}
