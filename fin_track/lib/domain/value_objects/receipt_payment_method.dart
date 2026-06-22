class ReceiptPaymentMethod {
  const ReceiptPaymentMethod._();

  static const unidentified = 'Não identificado';
  static const pix = 'PIX';
  static const creditCard = 'Cartão de crédito';
  static const debitCard = 'Cartão de débito';
  static const cash = 'Dinheiro';
  static const boleto = 'Boleto';
  static const ted = 'TED';
  static const doc = 'DOC';
  static const bankTransfer = 'Transferência bancária';
  static const other = 'Outros';

  static const options = <String>[
    pix,
    creditCard,
    debitCard,
    cash,
    boleto,
    ted,
    doc,
    bankTransfer,
    other,
  ];

  static String? normalize(String? amount) {
    final raw = amount?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final normalized = _normalize(raw);
    if (normalized == _normalize(unidentified)) {
      return null;
    }
    if (normalized.contains('pix')) {
      return pix;
    }
    if (_hasAny(normalized, [
      'cartao de credito',
      'credito',
      'cred',
      'visa',
      'mastercard',
      'elo',
      'amex',
      'american express',
      'hipercard',
    ])) {
      return creditCard;
    }
    if (_hasAny(normalized, ['cartao de debito', 'debito', 'deb'])) {
      return debitCard;
    }
    if (_hasAny(normalized, ['dinheiro', 'especie', 'em especie'])) {
      return cash;
    }
    if (_hasAny(normalized, [
      'boleto',
      'codigo de barras',
      'linha digitavel',
    ])) {
      return boleto;
    }
    if (normalized == 'ted' || normalized.contains(' ted')) {
      return ted;
    }
    if (normalized == 'doc' || normalized.contains(' doc')) {
      return doc;
    }
    if (normalized.contains('transferencia')) {
      return bankTransfer;
    }
    if (normalized.contains('outro')) {
      return other;
    }

    for (final option in options) {
      if (_normalize(option) == normalized) {
        return option;
      }
    }
    return other;
  }

  static bool _hasAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }
}
