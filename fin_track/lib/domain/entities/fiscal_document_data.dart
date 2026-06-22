class FiscalDocumentData {
  const FiscalDocumentData({
    this.amount,
    this.issuedAt,
    this.establishment,
    this.issuerCnpj,
    this.accessKey,
    this.lookupUrl,
    this.documentNumber,
    this.documentSeries,
    this.documentState,
    this.items = const <String>[],
  });

  final double? amount;
  final DateTime? issuedAt;
  final String? establishment;
  final String? issuerCnpj;
  final String? accessKey;
  final String? lookupUrl;
  final String? documentNumber;
  final String? documentSeries;
  final String? documentState;
  final List<String> items;

  bool get hasUsefulData {
    return amount != null ||
        issuedAt != null ||
        establishment != null ||
        issuerCnpj != null ||
        accessKey != null ||
        documentNumber != null ||
        documentSeries != null ||
        items.isNotEmpty;
  }
}
