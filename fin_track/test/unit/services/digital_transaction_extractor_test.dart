import 'dart:io';

import 'package:fin_track/application/ocr/ocr_text_normalizer_service.dart';
import 'package:fin_track/application/ocr/digital_transaction_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const extractor = DigitalTransactionExtractor();
  final normalizer = OcrTextNormalizerService();

  test(
    'separates destination source and institution in Nubank receipt',
    () async {
      final text = await _fixture('nubank_payment_establishment.txt');

      final result = extractor.extract(normalizer.normalize(text));

      expect(result.destination?.name, 'DROGASIL 2631');
      expect(result.destination?.document, isNull);
      expect(result.destination?.institution, isNull);
      expect(result.destination?.cnpj, isNull);
      expect(result.source?.name, contains('Jeferson Leandro'));
      expect(result.source?.document, contains('163.225'));
      expect(result.source?.institution, 'Nubank / Nu Pagamentos S.A.');
      expect(result.source?.institutionDocument, '18236120000158');
      expect(result.amount, 16.36);
      expect(result.date, DateTime(2026, 5, 8, 19, 29));
      expect(result.paymentMethod, 'Credito');
    },
  );

  test('extracts recipient CNPJ without confusing institution', () {
    final result = extractor.extract(
      normalizer.normalize('''
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
'''),
    );

    expect(result.destination?.name, 'MERCADO CENTRAL LTDA');
    expect(result.destination?.document, '00.416.968/0001-01');
    expect(result.destination?.cnpj, '00416968000101');
    expect(result.destination?.institution, 'Banco Inter');
    expect(result.source?.name, 'CLIENTE TESTE');
    expect(result.source?.cnpj, '55986560000159');
    expect(result.source?.institution, 'Banco Exemplo');
    expect(result.amount, 32.90);
    expect(result.date, DateTime(2026, 2, 9));
    expect(result.paymentMethod, 'Pix');
  });

  test('does not use institution CNPJ as destination CNPJ', () {
    final result = extractor.extract(
      normalizer.normalize('''
Receipt de transferência
Valor
R\$ 77,40
Destino
Nome
MERCADO DA ESQUINA
Instituição
Banco Exemplo
CNPJ
12.345.678/0001-95
ISPB
12345678
Origem
Nome
CLIENTE TESTE
'''),
    );

    expect(result.destination?.name, 'MERCADO DA ESQUINA');
    expect(result.destination?.cnpj, isNull);
    expect(result.destination?.institution, 'Banco Exemplo');
    expect(result.destination?.institutionDocument, '12345678000195');
  });

  test('ignores bank data inside destination block', () {
    final result = extractor.extract(
      normalizer.normalize('''
Receipt TED
Valor
R\$ 150,00
Favorecido
MARIA SILVA
Agência 0001
Conta 12345-6
ISPB 00000000
Quem pagou
Nome
CLIENTE TESTE
'''),
    );

    expect(result.destination?.name, 'MARIA SILVA');
    expect(result.destination?.document, isNull);
    expect(result.destination?.cnpj, isNull);
  });

  test('extracts generic transfer by beneficiary', () async {
    final text = await _fixture('generic_bank_transfer.txt');

    final result = extractor.extract(normalizer.normalize(text));

    expect(result.destination?.name, contains('ANA PAULA'));
    expect(result.amount, 1250.30);
    expect(result.paymentMethod, 'TED');
  });

  test('extracts recipient with CNPJ in Inter receipt', () async {
    final text = await _fixture('inter_payment_recipient_cnpj.txt');

    final result = extractor.extract(normalizer.normalize(text));

    expect(result.destination?.name, 'BANCO INTER SA');
    expect(result.destination?.cnpj, '00416968000101');
    expect(result.destination?.institution, 'Banco Inter');
    expect(result.source?.name, contains('JEFERSON LEANDRO'));
    expect(result.source?.institution, 'Banco Inter');
    expect(result.amount, 102.10);
    expect(result.paymentMethod, isNotNull);
  });
}

Future<String> _fixture(String name) {
  return File('test/fixtures/ocr/$name').readAsString();
}
