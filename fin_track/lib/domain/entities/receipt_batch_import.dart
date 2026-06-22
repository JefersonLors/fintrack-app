import 'dart:io';

import '../../application/receipts/batch/receipt_batch_codec.dart';
import 'receipt.dart';

enum ReceiptBatchImportStatus {
  pending('PENDENTE'),
  processing('PROCESSANDO'),
  review('REVISAO'),
  completed('CONCLUIDO'),
  canceled('CANCELADO');

  const ReceiptBatchImportStatus(this.persistedValue);

  final String persistedValue;

  static ReceiptBatchImportStatus fromPersisted(String value) {
    return ReceiptBatchImportStatus.values.firstWhere(
      (status) => status.persistedValue == value,
      orElse: () => ReceiptBatchImportStatus.pending,
    );
  }
}

enum ReceiptBatchImportItemStatus {
  pending('PENDENTE'),
  processing('PROCESSANDO'),
  ready('PRONTO'),
  error('FALHA'),
  saved('SALVO');

  const ReceiptBatchImportItemStatus(this.persistedValue);

  final String persistedValue;

  static ReceiptBatchImportItemStatus fromPersisted(String value) {
    return ReceiptBatchImportItemStatus.values.firstWhere(
      (status) => status.persistedValue == value,
      orElse: () => ReceiptBatchImportItemStatus.pending,
    );
  }
}

class ReceiptBatchImportSession {
  const ReceiptBatchImportSession({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.stagingDirectory,
    required this.totalItems,
  });

  final int id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ReceiptBatchImportStatus status;
  final String stagingDirectory;
  final int totalItems;
}

class ReceiptBatchImportItem {
  const ReceiptBatchImportItem({
    required this.id,
    required this.sessionId,
    required this.number,
    required this.originalPath,
    required this.stagedPath,
    required this.status,
    this.errorDescription,
    this.receiptJson,
    required this.updatedAt,
  });

  final int id;
  final int sessionId;
  final int number;
  final String originalPath;
  final String stagedPath;
  final ReceiptBatchImportItemStatus status;
  final String? errorDescription;
  final String? receiptJson;
  final DateTime updatedAt;

  File get file => File(stagedPath);

  Receipt? get receipt => receiptBatchReceiptFromJsonString(receiptJson);
}

class ReceiptBatchImportSnapshot {
  const ReceiptBatchImportSnapshot({
    required this.session,
    required this.items,
  });

  final ReceiptBatchImportSession session;
  final List<ReceiptBatchImportItem> items;

  bool get isProcessComplete {
    return items.every(
      (item) =>
          item.status == ReceiptBatchImportItemStatus.ready ||
          item.status == ReceiptBatchImportItemStatus.error ||
          item.status == ReceiptBatchImportItemStatus.saved,
    );
  }
}
