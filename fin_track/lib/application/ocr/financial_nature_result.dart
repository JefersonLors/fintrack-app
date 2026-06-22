class FinancialNatureResult {
  const FinancialNatureResult({
    required this.expense,
    required this.confidence,
    required this.reasons,
  });

  final bool expense;
  final double confidence;
  final List<String> reasons;
}
