import '../../domain/utils/ocr_parser_utils.dart';

class NfceFiscalStrategy {
  const NfceFiscalStrategy();

  int scoreSignals(String text) {
    return countOccurrences(text, const [
      'nf-e',
      'nfe',
      'nfc-e',
      'nota fiscal',
      'cupom fiscal',
      'danfe',
      'documento auxiliar',
      'consumidor eletronica',
      'chave de acesso',
      'emitente',
      'tributos',
      'valor total',
      'total pago',
      'qtd total de itens',
      'itens',
    ]);
  }

  bool recognizes({
    required String text,
    required bool hasFiscalQr,
    required String? accessKey,
  }) {
    if (hasFiscalQr || accessKey != null) {
      return true;
    }
    return scoreSignals(text) >= 1;
  }
}

class FiscalAmount {
  const FiscalAmount(this.amount, this.score);

  final double amount;
  final double score;
}

class AccessKeyData {
  const AccessKeyData({
    required this.state,
    required this.cnpj,
    required this.series,
    required this.number,
  });

  factory AccessKeyData.fromKey(String key) {
    return AccessKeyData(
      state: stateByCode(key.substring(0, 2)),
      cnpj: key.substring(6, 20),
      series: int.parse(key.substring(22, 25)).toString(),
      number: int.parse(key.substring(25, 34)).toString(),
    );
  }

  final String? state;
  final String cnpj;
  final String series;
  final String number;

  static String? stateByCode(String code) {
    const states = {
      '11': 'RO',
      '12': 'AC',
      '13': 'AM',
      '14': 'RR',
      '15': 'PA',
      '16': 'AP',
      '17': 'TO',
      '21': 'MA',
      '22': 'PI',
      '23': 'CE',
      '24': 'RN',
      '25': 'PB',
      '26': 'PE',
      '27': 'AL',
      '28': 'SE',
      '29': 'BA',
      '31': 'MG',
      '32': 'ES',
      '33': 'RJ',
      '35': 'SP',
      '41': 'PR',
      '42': 'SC',
      '43': 'RS',
      '50': 'MS',
      '51': 'MT',
      '52': 'GO',
      '53': 'DF',
    };
    return states[code];
  }
}
