import 'package:fin_track/domain/utils/cnpj_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const extractor = CnpjExtractor();

  test('detects formatted and unmasked CNPJ', () {
    final formatted = extractor.extract('CNPJ 55.986.560/0001-59');
    final unmasked = extractor.extract('CNPJ 55986560000159');

    expect(formatted?.cnpj, '55986560000159');
    expect(unmasked?.cnpj, '55986560000159');
  });

  test('detects CNPJ broken by spaces punctuation and line breaks', () {
    final result = extractor.extract('''
CPF/CNPJ
00 . 416 .
968 / 0001 - 01
''');

    expect(result?.cnpj, '00416968000101');
  });

  test('detects CNPJ with mixed separators read by OCR', () {
    final withCommas = extractor.extract('CNPJ 55,986 560/0001 59');
    final withMixedSeparators = extractor.extract('''
CPF/CNPJ
00.416,968 / 0001;01
''');

    expect(withCommas?.cnpj, '55986560000159');
    expect(withMixedSeparators?.cnpj, '00416968000101');
  });

  test('derives CNPJ from access key with high priority', () {
    final result = extractor.extract(
      'Chave de acesso 29260455986560000159650210000156761007188082',
      context: CnpjDocumentContext.fiscal,
    );

    expect(result?.cnpj, '55986560000159');
    expect(result?.accessKey, '29260455986560000159650210000156761007188082');
    expect(result?.best.source, CnpjSource.accessKey);
    expect(result?.best.score, greaterThan(100));
  });

  test('extracts key and CNPJ from fiscal QR code URL', () {
    final result = extractor.extract(
      '',
      codes: const [
        'https://nfce.sefaz.ba.gov.br/servicos/nfce/qrcode.aspx?p=29260556062868000170650000001859490166640140|2|1|1',
      ],
      context: CnpjDocumentContext.fiscal,
    );

    expect(result?.cnpj, '56062868000170');
    expect(result?.accessKey, '29260556062868000170650000001859490166640140');
    expect(result?.urlQrCode, startsWith('https://nfce.sefaz.ba.gov.br'));
    expect(result?.best.source, CnpjSource.qrCode);
  });

  test('prioritizes recipient in Pix receipt with payer CNPJ', () {
    final result = extractor.extract('''
Quem recebeu
Nome
MERCADO CENTRAL LTDA
CPF/CNPJ
00.416.968/0001-01

Quem pagou
Nome
CLIENTE TESTE
CPF/CNPJ
55.986.560/0001-59
''', context: CnpjDocumentContext.transfer);

    expect(result?.cnpj, '00416968000101');
  });

  test('avoids intermediary bank CNPJ when establishment CNPJ exists', () {
    final result = extractor.extract('''
Instituição
Banco Exemplo S.A.
CNPJ
55.986.560/0001-59

Favorecido
PADARIA DO BAIRRO LTDA
CNPJ
59.788.795/0001-97
''', context: CnpjDocumentContext.transfer);

    expect(result?.cnpj, '59788795000197');
  });

  test('descarta cnpj matematicamente invalido', () {
    final result = extractor.extract('CNPJ 11.111.111/1111-11');

    expect(result, isNull);
  });
}
