import 'category.dart';
import 'extracted_data.dart';
import 'embedding.dart';

enum ReceiptType {
  invoice('NOTA_FISCAL', 'Nota fiscal'),
  receipt('RECIBO', 'Recibo'),
  pixReceipt('COMPROVANTE_PIX', 'Comprovante Pix'),
  other('OUTROS', 'Outros');

  const ReceiptType(this.persistedValue, this.label);

  final String persistedValue;
  final String label;

  static ReceiptType fromPersisted(String value) {
    return ReceiptType.values.firstWhere(
      (type) => type.persistedValue == value,
      orElse: () => ReceiptType.other,
    );
  }
}

enum ReceiptSort {
  date('Data'),
  amount('Valor'),
  establishment('Estabelecimento');

  const ReceiptSort(this.label);

  final String label;
}

class Receipt {
  const Receipt({
    required this.id,
    required this.type,
    required this.expense,
    required this.fileName,
    required this.fileType,
    this.fileHash,
    this.fileSize,
    this.extractedContent = '',
    this.cloudSynced = false,
    required this.registeredAt,
    this.extractedData,
    this.embedding,
    this.category,
  });

  final int id;
  final ReceiptType type;
  final bool expense;
  final String fileName;
  final String fileType;
  final String? fileHash;
  final int? fileSize;
  final String extractedContent;
  final bool cloudSynced;
  final DateTime registeredAt;
  final ExtractedData? extractedData;
  final Embedding? embedding;
  final Category? category;

  Receipt copyWith({
    int? id,
    ReceiptType? type,
    bool? expense,
    String? fileName,
    String? fileType,
    String? fileHash,
    int? fileSize,
    String? extractedContent,
    bool? cloudSynced,
    DateTime? registeredAt,
    ExtractedData? extractedData,
    Embedding? embedding,
    Category? category,
    bool clearCategory = false,
  }) {
    return Receipt(
      id: id ?? this.id,
      type: type ?? this.type,
      expense: expense ?? this.expense,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileHash: fileHash ?? this.fileHash,
      fileSize: fileSize ?? this.fileSize,
      extractedContent: extractedContent ?? this.extractedContent,
      cloudSynced: cloudSynced ?? this.cloudSynced,
      registeredAt: registeredAt ?? this.registeredAt,
      extractedData: extractedData ?? this.extractedData,
      embedding: embedding ?? this.embedding,
      category: clearCategory ? null : category ?? this.category,
    );
  }
}
