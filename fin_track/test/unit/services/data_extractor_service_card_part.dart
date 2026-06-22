part of 'data_extractor_service_test.dart';

void registerCardExtractorTests() {
  test(
    'card payment parser extracts amount date method and establishment',
    () async {
      final service = DataExtractorService();
      final text = await _fixture('card_payment.txt');

      final result = service.process(text, 0.74);
      final extractedData = result.extractedData;

      expect(result.parser, 'card_payment');
      expect(result.type, ReceiptType.receipt);
      expect(extractedData.amount, 70.00);
      expect(extractedData.transactionDate, DateTime(2026, 4, 12, 12, 16));
      expect(extractedData.paymentMethod, contains('Debito'));
      expect(extractedData.establishment, contains('POSTO MATARIPE'));
      expect(extractedData.paymentMethodConfidence, greaterThan(0.7));
    },
  );

  test('card parser extracts merchant CNPJ when available', () {
    final service = DataExtractorService();

    final result = service.process('''
LOJISTA
MERCADO CENTRAL LTDA
CNPJ
00.416.968/0001-01
VIA CLIENTE
CREDITO A VISTA
VALOR
R\$ 89,90
DATA 09/02/2026 12:40
NSU 123456
AUT: 987654
''', 0.86);
    final extractedData = result.extractedData;

    expect(result.parser, 'card_payment');
    expect(extractedData.establishment, contains('MERCADO CENTRAL'));
    expect(extractedData.issuerCnpj, '00416968000101');
    expect(extractedData.amount, 89.90);
  });

  test(
    'card parser uses geometry for merchant amount date and authorization',
    () {
      final service = DataExtractorService();

      final result = service.processResult(
        OcrResult(
          text: '''
VIA CLIENTE
CREDITO A VISTA
Valor
Data
Lojista
CNPJ
Autorizacao
''',
          confidence: 0.88,
          provider: 'fake',
          lines: const [
            OcrLine(
              text: 'VIA CLIENTE',
              left: 10,
              top: 0,
              right: 120,
              bottom: 18,
              blockIndex: 0,
              lineIndex: 0,
            ),
            OcrLine(
              text: 'CREDITO A VISTA',
              left: 10,
              top: 24,
              right: 170,
              bottom: 42,
              blockIndex: 0,
              lineIndex: 1,
            ),
            OcrLine(
              text: 'Valor',
              left: 10,
              top: 54,
              right: 60,
              bottom: 72,
              blockIndex: 0,
              lineIndex: 2,
            ),
            OcrLine(
              text: 'R\$ 89,90',
              left: 210,
              top: 54,
              right: 300,
              bottom: 72,
              blockIndex: 0,
              lineIndex: 3,
            ),
            OcrLine(
              text: 'Data',
              left: 10,
              top: 84,
              right: 60,
              bottom: 102,
              blockIndex: 0,
              lineIndex: 4,
            ),
            OcrLine(
              text: '09/02/2026 12:40',
              left: 210,
              top: 84,
              right: 380,
              bottom: 102,
              blockIndex: 0,
              lineIndex: 5,
            ),
            OcrLine(
              text: 'Lojista',
              left: 10,
              top: 114,
              right: 80,
              bottom: 132,
              blockIndex: 0,
              lineIndex: 6,
            ),
            OcrLine(
              text: 'MERCADO CENTRAL LTDA',
              left: 210,
              top: 114,
              right: 430,
              bottom: 132,
              blockIndex: 0,
              lineIndex: 7,
            ),
            OcrLine(
              text: 'CNPJ',
              left: 10,
              top: 144,
              right: 60,
              bottom: 162,
              blockIndex: 0,
              lineIndex: 8,
            ),
            OcrLine(
              text: '00.416.968/0001-01',
              left: 210,
              top: 144,
              right: 390,
              bottom: 162,
              blockIndex: 0,
              lineIndex: 9,
            ),
            OcrLine(
              text: 'Autorizacao',
              left: 10,
              top: 174,
              right: 120,
              bottom: 192,
              blockIndex: 0,
              lineIndex: 10,
            ),
            OcrLine(
              text: '987654',
              left: 210,
              top: 174,
              right: 280,
              bottom: 192,
              blockIndex: 0,
              lineIndex: 11,
            ),
          ],
        ),
      );
      final extractedData = result.extractedData;

      expect(result.parser, 'card_payment');
      expect(extractedData.amount, 89.90);
      expect(extractedData.transactionDate, DateTime(2026, 2, 9, 12, 40));
      expect(extractedData.establishment, 'MERCADO CENTRAL LTDA');
      expect(extractedData.issuerCnpj, '00416968000101');
      expect(extractedData.documentNumber, '987654');
    },
  );

  test('card parser works without known acquirer', () async {
    final service = DataExtractorService();
    final text = await _fixture('generic_card_payment.txt');

    final result = service.process(text, 0.80);
    final extractedData = result.extractedData;

    expect(result.parser, 'card_payment');
    expect(extractedData.amount, 89.90);
    expect(extractedData.paymentMethod, contains('Credito'));
    expect(extractedData.establishment, contains('LOJA CENTRAL'));
  });

  test('card parser recognizes Cielo receipt with spaced CNPJ', () async {
    final service = DataExtractorService();
    final text = await _fixture('cielo_card_payment.txt');

    final result = service.process(text, 0.82);
    final extractedData = result.extractedData;

    expect(result.parser, 'card_payment');
    expect(extractedData.amount, 70.00);
    expect(extractedData.transactionDate, DateTime(2026, 4, 12, 12, 16));
    expect(extractedData.paymentMethod, contains('Debito'));
    expect(extractedData.establishment, contains('POSTO MATARIPE'));
    expect(extractedData.issuerCnpj, '55986560000159');
  });
}
