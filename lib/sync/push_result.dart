/// Risultato di un push: cosa è andato a buon fine e cosa no, record per record.
/// Serve a non far fallire l'intero sync per un solo elemento problematico.
class PushResult {
  final Set<String> succeededGroupIds;
  final Set<String> succeededExpenseIds;
  final Set<String> succeededSplitIds;

  final Map<String, String> failedGroupErrors; // id -> messaggio errore
  final Map<String, String> failedExpenseErrors;
  final Map<String, String> failedSplitErrors;

  const PushResult({
    this.succeededGroupIds = const {},
    this.succeededExpenseIds = const {},
    this.succeededSplitIds = const {},
    this.failedGroupErrors = const {},
    this.failedExpenseErrors = const {},
    this.failedSplitErrors = const {},
  });

  bool get hasErrors =>
      failedGroupErrors.isNotEmpty ||
      failedExpenseErrors.isNotEmpty ||
      failedSplitErrors.isNotEmpty;
}
