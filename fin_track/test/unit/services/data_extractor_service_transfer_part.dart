part of 'data_extractor_service_test.dart';

void registerTransferExtractorTests() {
  test(
    'digital transfer parser extracts amount date method and recipient',
    () async {
      final service = DataExtractorService();
      final text = await _fixture('pix_digital_transfer.txt');

      final result = service.process(text, 0.68);
      final extractedData = result.extractedData;

      expect(result.parser, 'digital_transfer');
      expect(result.type, ReceiptType.pixReceipt);
      expect(extractedData.amount, 400.00);
      expect(extractedData.transactionDate, DateTime(2026, 4, 25, 10, 46, 32));
      expect(extractedData.paymentMethod, 'Pix');
      expect(extractedData.establishment, contains('MIRIAN'));
      expect(extractedData.valueConfidence, greaterThan(0.8));
      expect(extractedData.dateConfidence, greaterThan(0.8));
      expect(extractedData.establishmentConfidence, greaterThan(0.7));
    },
  );

  test('transfer parser does not depend on a specific bank', () async {
    final service = DataExtractorService();
    final text = await _fixture('generic_bank_transfer.txt');

    final result = service.process(text, 0.72);
    final extractedData = result.extractedData;

    expect(result.parser, 'digital_transfer');
    expect(result.type, ReceiptType.receipt);
    expect(extractedData.amount, 1250.30);
    expect(extractedData.paymentMethod, 'TED');
    expect(extractedData.establishment, contains('ANA PAULA'));
  });

  test(
    'digital payment parser uses establishment and accessible CNPJ',
    () async {
      final service = DataExtractorService();
      final text = await _fixture('nubank_payment_establishment.txt');

      final result = service.process(text, 0.88);
      final extractedData = result.extractedData;

      expect(result.parser, 'digital_transfer');
      expect(extractedData.amount, 16.36);
      expect(extractedData.transactionDate, DateTime(2026, 5, 8, 19, 29));
      expect(extractedData.establishment, contains('DROGASIL 2631'));
      expect(extractedData.issuerCnpj, isNull);
      expect(extractedData.paymentMethod, 'Credito');
    },
  );

  test('digital payment parser uses CNPJ from recipient section', () async {
    final service = DataExtractorService();
    final text = await _fixture('inter_payment_recipient_cnpj.txt');

    final result = service.process(text, 0.90);
    final extractedData = result.extractedData;

    expect(result.parser, 'digital_transfer');
    expect(extractedData.amount, 102.10);
    expect(extractedData.transactionDate, DateTime(2026, 2, 9));
    expect(extractedData.establishment, contains('BANCO INTER SA'));
    expect(extractedData.issuerCnpj, '00416968000101');
  });

  test(
    'parser pagamento digital tolera zero lido como letra no cnpj',
    () async {
      final service = DataExtractorService();
      final text = (await _fixture(
        'inter_payment_recipient_cnpj.txt',
      )).replaceAll('00.416.968/0001-01', 'OO.416.968/OOO1-O1');

      final result = service.process(text, 0.86);
      final extractedData = result.extractedData;

      expect(result.parser, 'digital_transfer');
      expect(extractedData.establishment, contains('BANCO INTER SA'));
      expect(extractedData.issuerCnpj, '00416968000101');
    },
  );

  test('pipeline prioritizes recipient CNPJ in Pix receipt', () {
    final service = DataExtractorService();

    final result = service.process('''
Receipt Pix
Valor
R\$ 32,90
Data da transação
09/02/2026
Quem recebeu
Nome
MERCADO CENTRAL LTDA
CPF/CNPJ
00.416.968/0001-01
Instituição
Banco Inter
Quem pagou
Nome
CLIENTE TESTE
CPF/CNPJ
55.986.560/0001-59
Instituição
Banco Exemplo
''', 0.88);

    expect(result.parser, 'digital_transfer');
    expect(result.extractedData.establishment, contains('MERCADO'));
    expect(result.extractedData.establishment, isNot(contains('Banco')));
    expect(result.extractedData.issuerCnpj, '00416968000101');
  });

  test('transfer parser uses geometry for label and amount pairs', () {
    final service = DataExtractorService();

    final result = service.processResult(
      OcrResult(
        text: '''
Receipt Pix
Valor
Quem recebeu
Nome
CPF/CNPJ
Instituição
Banco Inter
R\$ 400,00
MERCADO CENTRAL LTDA
00.416.968/0001-01
''',
        confidence: 0.91,
        provider: 'fake',
        lines: const [
          OcrLine(
            text: 'Receipt Pix',
            left: 10,
            top: 0,
            right: 180,
            bottom: 18,
            blockIndex: 0,
            lineIndex: 0,
          ),
          OcrLine(
            text: 'Valor',
            left: 10,
            top: 30,
            right: 60,
            bottom: 48,
            blockIndex: 0,
            lineIndex: 1,
          ),
          OcrLine(
            text: 'R\$ 400,00',
            left: 220,
            top: 30,
            right: 320,
            bottom: 48,
            blockIndex: 0,
            lineIndex: 2,
          ),
          OcrLine(
            text: 'Quem recebeu',
            left: 10,
            top: 70,
            right: 150,
            bottom: 88,
            blockIndex: 0,
            lineIndex: 3,
          ),
          OcrLine(
            text: 'Nome',
            left: 10,
            top: 100,
            right: 60,
            bottom: 118,
            blockIndex: 0,
            lineIndex: 4,
          ),
          OcrLine(
            text: 'MERCADO CENTRAL LTDA',
            left: 220,
            top: 100,
            right: 430,
            bottom: 118,
            blockIndex: 0,
            lineIndex: 5,
          ),
          OcrLine(
            text: 'CPF/CNPJ',
            left: 10,
            top: 130,
            right: 90,
            bottom: 148,
            blockIndex: 0,
            lineIndex: 6,
          ),
          OcrLine(
            text: '00.416.968/0001-01',
            left: 220,
            top: 130,
            right: 390,
            bottom: 148,
            blockIndex: 0,
            lineIndex: 7,
          ),
          OcrLine(
            text: 'Instituição',
            left: 10,
            top: 160,
            right: 110,
            bottom: 178,
            blockIndex: 0,
            lineIndex: 8,
          ),
          OcrLine(
            text: 'Banco Inter',
            left: 220,
            top: 160,
            right: 330,
            bottom: 178,
            blockIndex: 0,
            lineIndex: 9,
          ),
        ],
      ),
    );

    expect(result.parser, 'digital_transfer');
    expect(result.extractedData.amount, 400);
    expect(result.extractedData.establishment, 'MERCADO CENTRAL LTDA');
    expect(result.extractedData.issuerCnpj, '00416968000101');
  });

  test('transfer parser uses amount below label by geometry', () {
    final service = DataExtractorService();

    final result = service.processResult(
      _positionedOcrResult([
        _line('Receipt Pix', 10, 0),
        _line('Valor', 10, 30),
        _line('R\$ 72,35', 10, 60),
        _line('Quem recebeu', 10, 100),
        _line('Nome', 10, 130),
        _line('PADARIA CENTRAL LTDA', 10, 160),
        _line('CPF/CNPJ', 10, 190),
        _line('00.416.968/0001-01', 10, 220),
      ]),
    );

    expect(result.parser, 'digital_transfer');
    expect(result.extractedData.amount, 72.35);
    expect(result.extractedData.establishment, 'PADARIA CENTRAL LTDA');
    expect(result.extractedData.issuerCnpj, '00416968000101');
  });

  test(
    'transfer parser ignores bank visual block separated from destination',
    () {
      final service = DataExtractorService();

      final result = service.processResult(
        _positionedOcrResult([
          _line('Receipt Pix', 10, 0),
          _line('Valor', 10, 30),
          _line('R\$ 18,90', 220, 30),
          _line('Quem recebeu', 10, 70),
          _line('Nome', 10, 100),
          _line('DROGARIA BOA SAUDE LTDA', 220, 100),
          _line('CPF/CNPJ', 10, 130),
          _line('00.416.968/0001-01', 220, 130),
          _line('Instituição', 10, 170),
          _line('Banco Inter', 220, 170),
          _line('CNPJ', 10, 200),
          _line('90.400.888/0001-42', 220, 200),
        ]),
      );

      expect(result.parser, 'digital_transfer');
      expect(result.extractedData.establishment, contains('DROGARIA'));
      expect(result.extractedData.establishment, isNot(contains('Banco')));
      expect(result.extractedData.issuerCnpj, '00416968000101');
    },
  );

  test(
    'transfer parser recognizes Nubank Pix without using origin CNPJ',
    () async {
      final service = DataExtractorService();
      final text = await _fixture('nubank_pix_transfer.txt');

      final result = service.process(text, 0.76);
      final extractedData = result.extractedData;

      expect(result.parser, 'digital_transfer');
      expect(result.type, ReceiptType.pixReceipt);
      expect(extractedData.amount, 400.00);
      expect(extractedData.transactionDate, DateTime(2026, 4, 25, 10, 46, 32));
      expect(extractedData.paymentMethod, 'Pix');
      expect(extractedData.establishment, contains('MIRIAN'));
      expect(extractedData.issuerCnpj, isNull);
    },
  );
}
