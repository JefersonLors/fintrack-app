part of 'receipt_service_test.dart';

void registerReceiptExtractionBasicsTests() {
  test('DataExtractorService extracts Brazilian monetary amount', () {
    final extractor = DataExtractorService();

    expect(extractor.extractAmount('Valor R\$ 84,90'), 84.90);
  });

  test('DataExtractorService extracts dd/MM/yyyy date', () {
    final extractor = DataExtractorService();

    expect(extractor.extractDate('Data 28/04/2026'), DateTime(2026, 4, 28));
    expect(
      extractor.extractDate('Emissão 8/5/26 19:48'),
      DateTime(2026, 5, 8, 19, 48),
    );
    expect(extractor.extractDate('Data 31/02/2026'), isNull);
  });

  test('DataExtractorService classifies unknown type and payment', () {
    final extractor = DataExtractorService();

    expect(
      extractor.inferType('Arquivo sem marcadores fiscais'),
      ReceiptType.other,
    );
    expect(
      extractor.extractPaymentMethod('Sem forma de pagamento legível'),
      isNull,
    );
    expect(
      ReceiptPaymentMethod.normalize('Cartao de credito'),
      ReceiptPaymentMethod.creditCard,
    );
  });

  test(
    'DataExtractorService recognizes alternate amount date and method formats',
    () {
      final extractor = DataExtractorService();

      expect(extractor.extract('Valor total R\$ 12,30', 0.8).amount, 12.30);
      expect(extractor.extractAmount('R\$ 7,00 taxa R\$ 50,00'), 50);
      expect(extractor.extractAmount('Itens 1.234,56 e 10,00'), 1234.56);
      expect(extractor.extractAmount('sem valores'), isNull);
      expect(
        extractor.extractDate('Emitido em 2026-05-23'),
        DateTime(2026, 5, 23),
      );
      expect(
        extractor.extractDate('Salvador, 3 de março de 2026'),
        DateTime(2026, 3, 3),
      );
      expect(
        extractor.extractDate('Pagamento 23-05-2026'),
        DateTime(2026, 5, 23),
      );
      expect(extractor.extractDate('sem data'), isNull);
      expect(
        extractor.extractEstablishment('BANCO\nMercado Azul\nTOTAL'),
        'BANCO',
      );
      expect(
        extractor.extractPaymentMethod('transferencia pix enviada'),
        'PIX',
      );
      expect(
        extractor.extractPaymentMethod('cartao credito aprovado'),
        'Cartão de crédito',
      );
      expect(
        extractor.extractPaymentMethod('cartao debito aprovado'),
        'Cartão de débito',
      );
      expect(extractor.extractPaymentMethod('pagamento em cash'), 'Dinheiro');
      expect(extractor.extractPaymentMethod('boleto bancario'), 'Boleto');
    },
  );
}
