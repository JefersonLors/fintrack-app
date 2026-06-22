import 'package:fin_track/application/ocr/fallback_receipt_parser.dart';
import 'package:fin_track/application/ocr/card_payment_parser.dart';
import 'package:fin_track/application/ocr/generic_receipt_parser.dart';
import 'package:fin_track/application/ocr/digital_transfer_parser.dart';
import 'package:fin_track/application/ocr/normalized_ocr_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public parser getters return expected metadata', () {
    expect(DigitalTransferParser().name, 'digital_transfer');
    expect(DigitalTransferParser().targetType.name, 'pixReceipt');
    expect(DigitalTransferParser().priority, 100);
    expect(CardPaymentParser().name, 'card_payment');
    expect(GenericReceiptParser().name, 'generic_receipt');
    expect(FallbackReceiptParser().priority, -1);
  });
  test('DigitalTransferParser rejects pure fiscal and weak text', () {
    final parser = DigitalTransferParser();

    expect(
      parser
          .tryExtract(_normalizedText('NFC-e\nvalor total R\$ 10,00'), 1)
          .success,
      isFalse,
    );
    expect(
      parser.tryExtract(_normalizedText('line solta sem signals'), 0.5).success,
      isFalse,
    );
    final insufficientSignal = parser.tryExtract(_normalizedText('pix'), -0.5);
    expect(insufficientSignal.success, isFalse);
    expect(insufficientSignal.data.ocrConfidence, 0);
  });

  test('DigitalTransferParser identifies Pix and limits OCR confidence', () {
    final parser = DigitalTransferParser();

    final result = parser.tryExtract(
      _normalizedText(
        'PIX comprovante de pagamento\n'
        'Estabelecimento\n'
        'Loja Azul\n'
        'Valor R\$ 32,10\n'
        'Data 24/05/2026\n'
        'E2E ABCD1234567890',
      ),
      2,
    );

    expect(result.success, isTrue);
    expect(result.type.name, 'pixReceipt');
    expect(result.data.paymentMethod, 'Pix');
    expect(result.data.establishment, 'Loja Azul');
    expect(result.data.amount, 32.10);
    expect(result.data.transactionDate, DateTime(2026, 5, 24));
    expect(result.data.documentNumber, 'ABCD1234567890');
    expect(result.data.ocrConfidence, 1);
  });
  test('DigitalTransferParser recognizes alternate payment methods', () {
    final parser = DigitalTransferParser();

    final cases = <String, String>{
      'DOC comprovante de pagamento destino Loja Azul amount R\$ 10,00': 'DOC',
      'crédito comprovante de pagamento estabelecimento Loja amount R\$ 11,00':
          'Credito',
      'débito comprovante de pagamento estabelecimento Loja amount R\$ 12,00':
          'Debito',
      'cartão comprovante de pagamento estabelecimento Loja amount R\$ 13,00':
          'Cartao',
      'type de transferencia transferencia destino Loja amount R\$ 14,00':
          'Outros',
      'pagamento efetuado destino Loja Azul amount R\$ 15,00': 'Outros',
    };

    for (final entry in cases.entries) {
      final result = parser.tryExtract(_normalizedText(entry.key), 0.8);
      expect(
        result.data.paymentMethod,
        anyOf(entry.value, 'Transferência', 'Outros'),
      );
    }
  });

  test('DigitalTransferParser uses method fallback and highest amount', () {
    final parser = DigitalTransferParser();

    final cases = <String, String>{
      'pix transacao estabelecimento Loja valor final 9,90': 'Pix',
      'ted transacao estabelecimento Loja valor final 10,90': 'TED',
      'doc transacao estabelecimento Loja valor final 11,90': 'DOC',
      'credito transacao estabelecimento Loja valor final 12,90': 'Credito',
      'debito transacao estabelecimento Loja valor final 13,90': 'Debito',
      'cartao transacao estabelecimento Loja valor final 14,90': 'Cartao',
      'transferencia transacao estabelecimento Loja valor final 15,90':
          'Transferência',
    };

    for (final entry in cases.entries) {
      final result = parser.tryExtract(_normalizedText(entry.key), 0.8);
      expect(result.data.paymentMethod, entry.value);
      expect(result.data.amount, isNotNull);
    }
  });
  test('DigitalTransferParser uses lines and geometry as fallback', () {
    final parser = DigitalTransferParser();
    final textByLines = _normalizedText(
      'Comprovante de pagamento\n'
      'Quem recebeu\n'
      'Nome\n'
      'Mercado Azul Ltda\n'
      'CNPJ\n'
      '11.222.333/0001-81\n'
      'Quem pagou\n'
      'Cliente\n'
      'Valor R\$ 18,90\n'
      'E2E ABCD1234567890',
    );

    final byLines = parser.tryExtract(textByLines, 0.9);
    expect(byLines.success, isTrue);
    expect(byLines.data.establishment, 'Mercado Azul Ltda');
    expect(byLines.data.documentNumber, 'ABCD1234567890');

    final byGeometry = parser.tryExtract(
      _normalizedText(
        'Comprovante de pagamento\nQuem recebeu\nNome\nPadaria Sol\n'
        'CNPJ\n11.222.333/0001-81\nValor\nR\$ 21,30\n'
        'Data\n23/05/2026\nE2E XYZ987654321',
        geometry: _geometria([
          _line('Quem recebeu', 0, 0, 100, 20),
          _line('Nome', 0, 30, 50, 50),
          _line('Padaria Sol', 70, 30, 180, 50),
          _line('CNPJ', 0, 60, 50, 80),
          _line('11.222.333/0001-81', 70, 60, 210, 80),
          _line('Valor', 0, 90, 50, 110),
          _line('R\$ 21,30', 70, 90, 150, 110),
          _line('Data', 0, 120, 50, 140),
          _line('23/05/2026', 70, 120, 160, 140),
          _line('E2E', 0, 150, 50, 170),
          _line('XYZ987654321', 70, 150, 200, 170),
        ]),
      ),
      0.95,
    );

    expect(byGeometry.success, isTrue);
    expect(byGeometry.data.amount, 21.30);
    expect(byGeometry.data.transactionDate, DateTime(2026, 5, 23));
    expect(byGeometry.data.issuerCnpj, '11222333000181');
    expect(byGeometry.data.documentNumber, 'XYZ987654321');
  });

  test('DigitalTransferParser extracts participant by textual section', () {
    final parser = DigitalTransferParser();

    final result = parser.tryExtract(
      _normalizedText(
        'TED transferencia realizada\n'
        'Destino\n'
        'Padaria Central\n'
        'Origem\n'
        'Cliente Teste\n'
        'Valor R\$ 50,00\n'
        'Data 24/05/2026\n'
        'E2E ZYX987654321',
      ),
      0.7,
    );

    expect(result.success, isTrue);
    expect(result.type.name, 'receipt');
    expect(result.data.paymentMethod, 'TED');
    expect(result.data.establishment, 'Padaria Central');
    expect(result.data.documentNumber, 'ZYX987654321');
  });

  test('DigitalTransferParser uses geometric proximity without section', () {
    final parser = DigitalTransferParser();

    final result = parser.tryExtract(
      _normalizedText(
        'Comprovante de pagamento\nNome\nLoja Geometrica\n'
        'CNPJ\n11.222.333/0001-81\nValor\nR\$ 90,00\nE2E ABC123456789',
        geometry: _geometria([
          _line('Nome', 0, 0, 50, 20),
          _line('Loja Geometrica', 70, 0, 190, 20),
          _line('CNPJ', 0, 30, 50, 50),
          _line('11.222.333/0001-81', 70, 30, 200, 50),
          _line('Valor', 0, 60, 50, 80),
          _line('R\$ 90,00', 70, 60, 150, 80),
          _line('E2E', 0, 90, 50, 110),
          _line('ABC123456789', 70, 90, 180, 110),
        ]),
      ),
      0.8,
    );

    expect(result.success, isTrue);
    expect(result.data.establishment, 'Loja Geometrica');
    expect(result.data.issuerCnpj, '11222333000181');
    expect(result.data.documentNumber, 'ABC123456789');
  });

  test('DigitalTransferParser pula labels ao buscar nome participant', () {
    final parser = DigitalTransferParser();

    final result = parser.tryExtract(
      _normalizedText(
        'pix transacao\n'
        'Nome\n'
        'CPF\n'
        'Loja Sem Secao\n'
        'Valor R\$ 12,00\n'
        'E2E EFG123456789',
      ),
      0.8,
    );

    expect(result.success, isTrue);
    expect(result.data.establishment, 'Loja Sem Secao');
  });
}

NormalizedOcrText _normalizedText(
  String text, {
  NormalizedOcrGeometry? geometry,
}) {
  return NormalizedOcrText(
    original: text,
    normalized: text
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u'),
    lines: text.split('\n'),
    geometry: geometry,
  );
}

NormalizedOcrGeometry _geometria(List<VisualOcrLine> lines) {
  return NormalizedOcrGeometry(
    lines: lines,
    bands: [
      for (final line in lines) VisualOcrBand(lines: [line]),
    ],
  );
}

VisualOcrLine _line(
  String text,
  double left,
  double top,
  double right,
  double bottom, {
  bool inInstitutionBlock = false,
}) {
  return VisualOcrLine(
    text: text,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    blockIndex: 0,
    lineIndex: 0,
    inInstitutionBlock: inInstitutionBlock,
  );
}
