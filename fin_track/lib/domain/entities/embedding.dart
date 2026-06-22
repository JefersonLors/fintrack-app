import 'dart:typed_data';

class Embedding {
  const Embedding({
    required this.id,
    required this.receiptId,
    required this.vector,
    required this.model,
    required this.dimension,
    required this.generatedAt,
  });

  final int id;
  final int receiptId;
  final Uint8List vector;
  final String model;
  final int dimension;
  final DateTime generatedAt;

  Embedding copyWith({
    int? id,
    int? receiptId,
    Uint8List? vector,
    String? model,
    int? dimension,
    DateTime? generatedAt,
  }) {
    return Embedding(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      vector: vector ?? this.vector,
      model: model ?? this.model,
      dimension: dimension ?? this.dimension,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
