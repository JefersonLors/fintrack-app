import '../../domain/entities/category.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/entities/extracted_data.dart';
import '../../domain/utils/ocr_parser_utils.dart';
import 'financial_nature_result.dart';

class FinancialNatureClassifierService {
  const FinancialNatureClassifierService();

  FinancialNatureResult infer({
    required String originalText,
    required String normalizedText,
    required ReceiptType type,
    required ExtractedData data,
    required List<Category> categories,
  }) {
    final text = normalizeSearch('$originalText\n$normalizedText');
    final categoryNames = categories
        .map(
          (category) =>
              normalizeSearch('${category.name} ${category.description ?? ''}'),
        )
        .join(' ');
    var expenseScore = 0.0;
    var incomeScore = 0.0;
    final reasons = <String>[];

    void scoreExpense(double points, String reason) {
      expenseScore += points;
      reasons.add(reason);
    }

    void scoreIncome(double points, String reason) {
      incomeScore += points;
      reasons.add(reason);
    }

    if (_looksLikeOutgoingTransfer(text)) {
      scoreExpense(0.48, 'transferência de saída');
    }
    if (_looksLikeIncomingTransfer(text)) {
      scoreIncome(0.52, 'transferência de input');
    }

    final expenseSignals = countOccurrences(text, _expenseSignals);
    final incomeSignals = countOccurrences(text, _incomeSignals);
    if (expenseSignals > 0) {
      scoreExpense((expenseSignals * 0.22).clamp(0, 0.66), 'sinais de saída');
    }
    if (incomeSignals > 0) {
      scoreIncome((incomeSignals * 0.25).clamp(0, 0.75), 'sinais de receita');
    }

    switch (type) {
      case ReceiptType.invoice:
        scoreExpense(0.35, 'nota fiscal');
      case ReceiptType.receipt:
        scoreExpense(0.12, 'recibo');
      case ReceiptType.pixReceipt:
      case ReceiptType.other:
        break;
    }

    if (containsAny(categoryNames, _expenseCategories)) {
      scoreExpense(0.18, 'categoria de despesa');
    }
    if (containsAny(categoryNames, _incomeCategories)) {
      scoreIncome(0.22, 'categoria de receita');
    }

    final expense = incomeScore > expenseScore ? false : true;
    final difference = (expenseScore - incomeScore).abs();
    final highestScore = expense ? expenseScore : incomeScore;
    final confidence = (0.35 + highestScore + difference * 0.35).clamp(
      0.35,
      1.0,
    );

    return FinancialNatureResult(
      expense: expense,
      confidence: confidence.toDouble(),
      reasons: reasons.isEmpty ? const ['classificação padrão'] : reasons,
    );
  }

  static const _expenseSignals = [
    'pagamento realizado',
    'pagamento efetuado',
    'pagamento enviado',
    'transferencia enviada',
    'pix enviado',
    'pix realizado',
    'compra',
    'debito',
    'credito',
    'cartao',
    'valor pago',
    'total pago',
    'pago a',
    'quem recebeu',
    'destino',
    'favorecido',
    'beneficiario',
    'via cliente',
    'nota fiscal',
    'cupom fiscal',
    'nfc-e',
    'nf-e',
  ];

  static const _incomeSignals = [
    'pix recebido',
    'transferencia recebida',
    'recebido de',
    'valor recebido',
    'deposito recebido',
    'credito recebido',
    'reembolso',
    'estorno',
    'devolucao',
    'remetente',
    'quem pagou',
  ];

  static const _expenseCategories = [
    'alimentacao',
    'mercado',
    'combustivel',
    'saude',
    'transporte',
    'moradia',
    'educacao',
    'lazer',
  ];

  static const _incomeCategories = [
    'salario',
    'reembolso',
    'recebimentos',
    'recebimento',
    'venda',
    'rendimento',
    'rendimentos',
  ];

  bool _looksLikeOutgoingTransfer(String text) {
    if (!containsAny(text, const [
      'pix',
      'transferencia',
      'ted',
      'doc',
      'comprovante de pagamento',
    ])) {
      return false;
    }
    return containsAny(text, const [
      'pagamento realizado',
      'pagamento efetuado',
      'pagamento enviado',
      'pix enviado',
      'transferencia enviada',
      'quem recebeu',
      'destino',
      'favorecido',
      'beneficiario',
      'pago a',
    ]);
  }

  bool _looksLikeIncomingTransfer(String text) {
    if (!containsAny(text, const [
      'pix',
      'transferencia',
      'ted',
      'doc',
      'deposito',
    ])) {
      return false;
    }
    if (containsAny(text, const [
      'pagamento realizado',
      'pagamento efetuado',
      'pix enviado',
      'transferencia enviada',
      'quem recebeu',
      'destino',
      'favorecido',
    ])) {
      return false;
    }
    return containsAny(text, const [
      'pix recebido',
      'transferencia recebida',
      'recebido de',
      'valor recebido',
      'deposito recebido',
      'credito recebido',
      'quem pagou',
      'remetente',
      'pagador',
    ]);
  }
}
