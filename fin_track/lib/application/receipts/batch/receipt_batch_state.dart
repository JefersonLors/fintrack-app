import 'dart:io';

import '../../../domain/entities/receipt.dart';
import '../../../infrastructure/diagnostics/user_error_message.dart';

enum ReceiptBatchItemStatus { pending, processing, ready, error, saved }

const receiptBatchProcessingErrorMessage =
    'Não foi possível processar este comprovante. '
    'Tente reprocessar o item ou importe outra imagem.';

String receiptBatchUserErrorMessage(Object? error) {
  return userFriendlyErrorMessage(
    error,
    fallback: receiptBatchProcessingErrorMessage,
  );
}

class ReceiptBatchItem {
  ReceiptBatchItem({
    required this.file,
    required this.number,
    this.originalFile,
    this.persistedItemId,
  }) : status = ReceiptBatchItemStatus.pending;

  File file;
  final File? originalFile;
  final int? persistedItemId;
  final int number;
  ReceiptBatchItemStatus status;
  Receipt? receipt;
  Object? error;

  String get label => 'Item $number';
}

class ReceiptBatchProgress {
  const ReceiptBatchProgress({
    required this.total,
    required this.processed,
    required this.pending,
    required this.errors,
  });

  final int total;
  final int processed;
  final int pending;
  final int errors;

  double get progress => total == 0 ? 0 : processed / total;
  bool get isComplete => processed == total;
}
