import 'dart:typed_data';

import 'package:fin_track/domain/entities/embedding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copyWith preserves values and replaces provided fields', () {
    final originalVector = Uint8List.fromList([1, 2, 3]);
    final originalDate = DateTime(2026, 5, 24);
    final embedding = Embedding(
      id: 1,
      receiptId: 2,
      vector: originalVector,
      model: 'model-a',
      dimension: 3,
      generatedAt: originalDate,
    );

    final preserved = embedding.copyWith();
    expect(preserved.id, 1);
    expect(preserved.receiptId, 2);
    expect(preserved.vector, same(originalVector));
    expect(preserved.model, 'model-a');
    expect(preserved.dimension, 3);
    expect(preserved.generatedAt, originalDate);

    final newVector = Uint8List.fromList([4, 5]);
    final newDate = DateTime(2026, 5, 25);
    final updated = embedding.copyWith(
      id: 10,
      receiptId: 20,
      vector: newVector,
      model: 'model-b',
      dimension: 2,
      generatedAt: newDate,
    );

    expect(updated.id, 10);
    expect(updated.receiptId, 20);
    expect(updated.vector, same(newVector));
    expect(updated.model, 'model-b');
    expect(updated.dimension, 2);
    expect(updated.generatedAt, newDate);
  });
}
