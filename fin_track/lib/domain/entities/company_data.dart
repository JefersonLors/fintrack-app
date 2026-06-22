class CompanyData {
  const CompanyData({
    required this.cnpj,
    this.legalName,
    this.tradeName,
    this.confirmedName,
    this.fiscalCnaeDescription,
    this.city,
    this.state,
  });

  final String cnpj;
  final String? legalName;
  final String? tradeName;
  final String? confirmedName;
  final String? fiscalCnaeDescription;
  final String? city;
  final String? state;

  String? get preferredName {
    final confirmed = confirmedName?.trim();
    if (confirmed != null && confirmed.isNotEmpty) {
      return confirmed;
    }
    final trade = tradeName?.trim();
    if (trade != null && trade.isNotEmpty) {
      return trade;
    }
    final legal = legalName?.trim();
    if (legal != null && legal.isNotEmpty) {
      return legal;
    }
    return null;
  }
}
