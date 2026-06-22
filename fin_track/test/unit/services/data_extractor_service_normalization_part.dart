part of 'data_extractor_service_test.dart';

void registerExtractorNormalizationTests() {
  test('normalizer cleans common OCR noise', () {
    final normalized = OcrTextNormalizerService().normalize('''
Instituiçáo
Instituiçăo
LỤCIA
sa\u0303o joao
Instituição
RS 400,00
Me ajuda →
Ouvidoria: 0800
''');

    expect(normalized.normalized, contains('Instituição'));
    expect(normalized.normalized, contains('LUCIA'));
    expect(normalized.normalized, contains('sao joao'));
    expect(normalized.normalized, contains('R\$ 400,00'));
    expect(normalized.normalized, isNot(contains('Me ajuda')));
    expect(normalized.normalized, isNot(contains('Ouvidoria')));
  });

  test('extractor recognizes written-out and abbreviated dates', () {
    final service = DataExtractorService();

    expect(service.extractDate('12 de maio de 2026'), DateTime(2026, 5, 12));
    expect(
      service.extractDate('Realizado em 12 de maio de 2026 às 10:35'),
      DateTime(2026, 5, 12, 10, 35),
    );
    expect(service.extractDate('12 MAI. 2026'), DateTime(2026, 5, 12));
    expect(service.extractDate('12/mai/2026'), DateTime(2026, 5, 12));
    expect(
      service.extractDate('12-mar-26 08h15'),
      DateTime(2026, 3, 12, 8, 15),
    );
  });
}
