part of 'data_extractor_service_test.dart';

void registerFiscalReceiptExtractorTests() {
  test('fiscal document parser extracts total date and issuer', () async {
    final service = DataExtractorService();
    final text = await _fixture('fiscal_document.txt');

    final result = service.process(text, 0.91);
    final extractedData = result.extractedData;

    expect(result.parser, 'fiscal_document');
    expect(result.type, ReceiptType.invoice);
    expect(extractedData.amount, 128.45);
    expect(extractedData.transactionDate, DateTime(2026, 4, 28));
    expect(extractedData.establishment, contains('MERCADO CENTRAL'));
  });

  test(
    'fiscal document parser recognizes generic NFC-e without valid CNPJ',
    () async {
      final service = DataExtractorService();
      final text = await _fixture('generic_fiscal_document.txt');

      final result = service.process(text, 0.84);
      final extractedData = result.extractedData;

      expect(result.parser, 'fiscal_document');
      expect(result.type, ReceiptType.invoice);
      expect(extractedData.amount, 128.45);
      expect(extractedData.transactionDate, DateTime(2026, 4, 28));
      expect(extractedData.establishment, contains('MERCADO CENTRAL'));
      expect(extractedData.issuerCnpj, isNull);
      expect(extractedData.paymentMethod, 'Cartão de crédito');
    },
  );

  test('fiscal parser uses geometry for total issuer and items', () {
    final service = DataExtractorService();

    final result = service.processResult(
      OcrResult(
        text: '''
NFC-e
Documento Auxiliar da Nota Fiscal de Consumidor Eletronica
Emitente
CNPJ
Descricao
Valor Total
Emissao
''',
        confidence: 0.90,
        provider: 'fake',
        lines: const [
          OcrLine(
            text: 'NFC-e',
            left: 10,
            top: 0,
            right: 60,
            bottom: 18,
            blockIndex: 0,
            lineIndex: 0,
          ),
          OcrLine(
            text: 'Emitente',
            left: 10,
            top: 30,
            right: 90,
            bottom: 48,
            blockIndex: 0,
            lineIndex: 1,
          ),
          OcrLine(
            text: 'MERCADO CENTRAL LTDA',
            left: 200,
            top: 30,
            right: 420,
            bottom: 48,
            blockIndex: 0,
            lineIndex: 2,
          ),
          OcrLine(
            text: 'CNPJ',
            left: 10,
            top: 60,
            right: 60,
            bottom: 78,
            blockIndex: 0,
            lineIndex: 3,
          ),
          OcrLine(
            text: '00.416.968/0001-01',
            left: 200,
            top: 60,
            right: 380,
            bottom: 78,
            blockIndex: 0,
            lineIndex: 4,
          ),
          OcrLine(
            text: 'Descricao',
            left: 10,
            top: 90,
            right: 100,
            bottom: 108,
            blockIndex: 0,
            lineIndex: 5,
          ),
          OcrLine(
            text: 'ARROZ INTEGRAL 1KG',
            left: 10,
            top: 120,
            right: 210,
            bottom: 138,
            blockIndex: 0,
            lineIndex: 6,
          ),
          OcrLine(
            text: 'Valor Total',
            left: 10,
            top: 150,
            right: 120,
            bottom: 168,
            blockIndex: 0,
            lineIndex: 7,
          ),
          OcrLine(
            text: 'R\$ 128,45',
            left: 200,
            top: 150,
            right: 300,
            bottom: 168,
            blockIndex: 0,
            lineIndex: 8,
          ),
          OcrLine(
            text: 'Emissao',
            left: 10,
            top: 180,
            right: 90,
            bottom: 198,
            blockIndex: 0,
            lineIndex: 9,
          ),
          OcrLine(
            text: '28/04/2026',
            left: 200,
            top: 180,
            right: 310,
            bottom: 198,
            blockIndex: 0,
            lineIndex: 10,
          ),
        ],
      ),
    );
    final extractedData = result.extractedData;

    expect(result.parser, 'fiscal_document');
    expect(extractedData.amount, 128.45);
    expect(extractedData.transactionDate, DateTime(2026, 4, 28));
    expect(extractedData.establishment, 'MERCADO CENTRAL LTDA');
    expect(extractedData.issuerCnpj, '00416968000101');
    expect(extractedData.items, contains('ARROZ INTEGRAL'));
  });

  test('fiscal parser uses issuer and degraded NFC-e signals', () async {
    final service = DataExtractorService();
    final text = await _fixture('degraded_nfce.txt');

    final result = service.process(text, 0.62);
    final extractedData = result.extractedData;

    expect(result.parser, 'fiscal_document');
    expect(result.type, ReceiptType.invoice);
    expect(extractedData.amount, 32.40);
    expect(extractedData.establishment, contains('PADARIA'));
  });

  test('fiscal parser prioritizes paid total and issuer before CNPJ', () async {
    final service = DataExtractorService();
    final text = await _fixture('gas_station_nfce_multi_product.txt');

    final result = service.process(text, 0.70);
    final extractedData = result.extractedData;

    expect(result.parser, 'fiscal_document');
    expect(result.type, ReceiptType.invoice);
    expect(extractedData.amount, 150.00);
    expect(extractedData.transactionDate, DateTime(2026, 4, 2, 17, 32, 32));
    expect(extractedData.establishment, contains('POSTO MATARIPE BONOCO'));
    expect(extractedData.items, contains('GASOLINA COMUM'));
    expect(extractedData.issuerCnpj, '55986560000159');
    expect(
      extractedData.accessKey,
      '29260455986560000159650210000156761007188082',
    );
    expect(extractedData.documentNumber, '15676');
    expect(extractedData.documentSeries, '21');
    expect(extractedData.documentState, 'BA');
  });

  test(
    'fiscal parser does not use item amount when there are multiple products',
    () async {
      final service = DataExtractorService();
      final text = await _fixture('bakery_nfce_total_items.txt');

      final result = service.process(text, 0.70);
      final extractedData = result.extractedData;

      expect(result.parser, 'fiscal_document');
      expect(result.type, ReceiptType.invoice);
      expect(extractedData.amount, 29.40);
      expect(extractedData.transactionDate, DateTime(2026, 5, 8, 19, 43, 21));
      expect(extractedData.establishment, contains('DOCE PAO'));
      expect(extractedData.items, contains('MINI BRIGADEIRAO'));
      expect(extractedData.items, contains('TORTLETA BRIGADEIRO'));
      expect(extractedData.items, contains('PAO KG'));
    },
  );

  test('fiscal parser uses QR Code to classify NFC-e', () async {
    final service = DataExtractorService();
    final text = await _fixture('nfce_qr_without_fiscal_text.txt');

    final result = service.process(
      text,
      0.65,
      codes: const [
        'https://nfce.sefaz.ba.gov.br/servicos/nfce/qrcode.aspx?p=29260556062868000170650000001859490166640140|2|1|1',
      ],
    );
    final extractedData = result.extractedData;

    expect(result.parser, 'fiscal_document');
    expect(result.type, ReceiptType.invoice);
    expect(extractedData.amount, 9.86);
    expect(extractedData.transactionDate, DateTime(2026, 5, 8, 19, 48));
    expect(extractedData.establishment, contains('SACOLAO DOM JOAO'));
    expect(extractedData.issuerCnpj, '56062868000170');
    expect(
      extractedData.accessKey,
      '29260556062868000170650000001859490166640140',
    );
    expect(extractedData.urlQrCode, startsWith('https://nfce.sefaz.ba.gov.br'));
    expect(extractedData.documentNumber, '185949');
    expect(extractedData.documentSeries, '0');
    expect(extractedData.documentState, 'BA');
  });

  test('fiscal parser extracts item table and fiscal URL from OCR', () async {
    final service = DataExtractorService();
    final text = await _fixture('self_service_nfce_table.txt');

    final result = service.process(text, 0.70);
    final extractedData = result.extractedData;

    expect(result.parser, 'fiscal_document');
    expect(extractedData.amount, 51.15);
    expect(extractedData.transactionDate, DateTime(2026, 5, 12, 20, 39, 1));
    expect(extractedData.establishment, contains('QUATRO ACAI SECOND'));
    expect(extractedData.items, contains('SELF SERVICE'));
    expect(extractedData.issuerCnpj, '59788795000197');
    expect(
      extractedData.accessKey,
      '29260559788795000197651010000018721010118725',
    );
    expect(extractedData.urlQrCode, startsWith('https://www.sefaz.ba.gov.br'));
  });

  test('fiscal parser recognizes fiscal URL embedded in QR Code', () async {
    final service = DataExtractorService();
    final text = await _fixture('nfce_qr_without_fiscal_text.txt');

    final result = service.process(
      text,
      0.65,
      codes: const [
        'QRCode: www.nfce.sefaz.ba.gov.br/servicos/nfce/qrcode.aspx?p=29260556062868000170650000001859490166640140|2|1|1',
      ],
    );

    expect(result.parser, 'fiscal_document');
    expect(
      result.extractedData.urlQrCode,
      startsWith('https://www.nfce.sefaz.ba.gov.br'),
    );
  });

  test('generic receipt parser extracts amount and date', () async {
    final service = DataExtractorService();
    final text = await _fixture('generic_receipt.txt');

    final result = service.process(text, 0.58);
    final extractedData = result.extractedData;

    expect(result.parser, 'generic_receipt');
    expect(result.type, ReceiptType.receipt);
    expect(extractedData.amount, 250.00);
    expect(extractedData.transactionDate, DateTime(2026, 4, 30));
  });

  test('fallback keeps working on unknown text', () {
    final service = DataExtractorService();

    final result = service.process('Arquivo sem estrutura conhecida', 0.2);

    expect(result.parser, 'fallback');
    expect(result.type, ReceiptType.other);
  });
}
