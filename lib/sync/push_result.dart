/// Risultato di un push: cosa è andato a buon fine e cosa no, record per record.
/// Serve a non far fallire l'intero sync per un solo elemento problematico.
class PushResult {
  final Set<String> succeededGroupIds;
  final Set<String> succeededExpenseIds;
  final Set<String> succeededSplitIds;
  final Set<String> succeededPaymentIds; // NUOVO

  final Map<String, String> failedGroupErrors;
  final Map<String, String> failedExpenseErrors;
  final Map<String, String> failedSplitErrors;
  final Map<String, String> failedPaymentErrors; // NUOVO

  const PushResult({
    this.succeededGroupIds = const {},
    this.succeededExpenseIds = const {},
    this.succeededSplitIds = const {},
    this.succeededPaymentIds = const {},
    this.failedGroupErrors = const {},
    this.failedExpenseErrors = const {},
    this.failedSplitErrors = const {},
    this.failedPaymentErrors = const {},
  });

  bool get hasErrors =>
      failedGroupErrors.isNotEmpty ||
      failedExpenseErrors.isNotEmpty ||
      failedSplitErrors.isNotEmpty ||
      failedPaymentErrors.isNotEmpty;
}
