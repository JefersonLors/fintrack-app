import 'package:fin_track/application/ocr/financial_nature_classifier_service.dart';
import 'package:fin_track/application/ocr/financial_nature_result.dart';
import 'package:fin_track/domain/entities/category.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/entities/extracted_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifies purchase documents as expense', () {
    expect(
      _inferir(
        type: ReceiptType.invoice,
        text: 'NFC-e cupom fiscal total pago R\$ 80,00',
      ).expense,
      isTrue,
    );
    expect(
      _inferir(
        type: ReceiptType.receipt,
        text: 'Via cliente debito cartao amount pago R\$ 70,00',
      ).expense,
      isTrue,
    );
  });

  test('classifies sent and received Pix', () {
    expect(
      _inferir(
        type: ReceiptType.pixReceipt,
        text: 'Pix enviado pagamento realizado destino Maria',
      ).expense,
      isTrue,
    );
    expect(
      _inferir(
        type: ReceiptType.pixReceipt,
        text: 'Pix recebido amount recebido remetente Maria',
      ).expense,
      isFalse,
    );
  });

  test('classifies paid Pix as expense even with identified recipient', () {
    expect(
      _inferir(
        type: ReceiptType.pixReceipt,
        text: '''
Receipt Pix
Pagamento efetuado
Quem recebeu
Nome
MERCADO CENTRAL LTDA
CPF/CNPJ
00.416.968/0001-01
''',
      ).expense,
      isTrue,
    );
    expect(
      _inferir(
        type: ReceiptType.pixReceipt,
        text: 'Receipt Pix recebedor MERCADO CENTRAL amount R\$ 32,90',
      ).expense,
      isTrue,
    );
  });

  test('classifies received Pix as income by input context', () {
    expect(
      _inferir(
        type: ReceiptType.pixReceipt,
        text: '''
Pix recebido
Valor recebido
Quem pagou
Nome
CLIENTE TESTE
''',
      ).expense,
      isFalse,
    );
  });

  test('classifies refund and auxiliary categories', () {
    expect(
      _inferir(
        text: 'Reembolso recebido amount recebido',
        categories: const [Category(id: 10, name: 'Reembolso')],
      ).expense,
      isFalse,
    );
    expect(
      _inferir(
        text: 'Compra no mercado',
        categories: const [Category(id: 1, name: 'Alimentação')],
      ).expense,
      isTrue,
    );
  });

  test('ambiguous text assumes expense with low confidence', () {
    final result = _inferir(text: 'Receipt sem details claros');

    expect(result.expense, isTrue);
    expect(result.confidence, lessThan(0.6));
  });
}

FinancialNatureResult _inferir({
  String text = '',
  ReceiptType type = ReceiptType.other,
  List<Category> categories = const [],
}) {
  const classificador = FinancialNatureClassifierService();
  return classificador.infer(
    originalText: text,
    normalizedText: text,
    type: type,
    data: const ExtractedData(id: 0, receiptId: 0),
    categories: categories,
  );
}
