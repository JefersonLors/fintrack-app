import 'package:fin_track/domain/entities/fiscal_document_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hasUsefulData identifica campos fiscais relevantes', () {
    expect(const FiscalDocumentData().hasUsefulData, isFalse);
    expect(
      const FiscalDocumentData(
        lookupUrl: 'https://consulta.test',
      ).hasUsefulData,
      isFalse,
    );
    expect(
      const FiscalDocumentData(documentState: 'BA').hasUsefulData,
      isFalse,
    );

    expect(const FiscalDocumentData(amount: 10).hasUsefulData, isTrue);
    expect(
      FiscalDocumentData(issuedAt: DateTime(2026, 5, 24)).hasUsefulData,
      isTrue,
    );
    expect(
      const FiscalDocumentData(establishment: 'Mercado').hasUsefulData,
      isTrue,
    );
    expect(
      const FiscalDocumentData(issuerCnpj: '11222333000181').hasUsefulData,
      isTrue,
    );
    expect(const FiscalDocumentData(accessKey: '123').hasUsefulData, isTrue);
    expect(const FiscalDocumentData(documentNumber: '9').hasUsefulData, isTrue);
    expect(const FiscalDocumentData(documentSeries: '1').hasUsefulData, isTrue);
    expect(const FiscalDocumentData(items: ['item']).hasUsefulData, isTrue);
  });

  test('preserves fiscal lookup data', () {
    final data = DateTime(2026, 5, 24, 12);
    final extractedData = FiscalDocumentData(
      amount: 99.9,
      issuedAt: data,
      establishment: 'Loja',
      issuerCnpj: '11222333000181',
      accessKey: 'chave',
      lookupUrl: 'https://consulta.test',
      documentNumber: '42',
      documentSeries: '3',
      documentState: 'BA',
      items: const ['Cafe'],
    );

    expect(extractedData.amount, 99.9);
    expect(extractedData.issuedAt, data);
    expect(extractedData.establishment, 'Loja');
    expect(extractedData.lookupUrl, 'https://consulta.test');
    expect(extractedData.documentState, 'BA');
    expect(extractedData.items, ['Cafe']);
  });
}
