import 'dart:math' as math;

import 'embedding_vector.dart';

class CompositeEmbeddingScore {
  const CompositeEmbeddingScore({
    required this.finalScore,
    required this.establishment,
    required this.categories,
    required this.context,
    required this.payment,
    required this.fullCosineScore,
    required this.usedFieldScore,
  });

  final double finalScore;
  final double establishment;
  final double categories;
  final double context;
  final double payment;
  final double fullCosineScore;
  final bool usedFieldScore;

  static CompositeEmbeddingScore calculate({
    required EmbeddingVector query,
    required EmbeddingVector persisted,
  }) {
    final fullCosineScore = query.cosineSimilarity(persisted);
    if (!_hasCompatibleFields(query, persisted)) {
      return CompositeEmbeddingScore(
        finalScore: fullCosineScore,
        establishment: 0,
        categories: 0,
        context: 0,
        payment: 0,
        fullCosineScore: fullCosineScore,
        usedFieldScore: false,
      );
    }

    final fieldCount = _fieldCount(query, persisted);
    final fieldSize = query.vector.length ~/ fieldCount;
    final establishment = _fieldSimilarity(
      query,
      persisted,
      start: 0,
      length: fieldSize,
    );
    final categories = _fieldSimilarity(
      query,
      persisted,
      start: fieldSize,
      length: fieldSize,
    );
    if (fieldCount == 2) {
      final primary = math.max(establishment, categories);
      final secondary = math.min(establishment, categories);
      final finalScore = primary * 0.90 + secondary * 0.10;
      return CompositeEmbeddingScore(
        finalScore: finalScore.clamp(-1, 1).toDouble(),
        establishment: establishment,
        categories: categories,
        context: 0,
        payment: 0,
        fullCosineScore: fullCosineScore,
        usedFieldScore: true,
      );
    }

    final context = _fieldSimilarity(
      query,
      persisted,
      start: fieldSize * 2,
      length: fieldSize,
    );
    final payment = _fieldSimilarity(
      query,
      persisted,
      start: fieldSize * 3,
      length: fieldSize,
    );

    final primary = math.max(establishment, categories);
    final support =
        (math.max(context, payment) * 0.20) +
        (math.min(context, payment) * 0.05);
    final fieldSpecificFallback = math.max(context, payment) * 0.55;
    final finalScore = math.max(
      primary * 0.85 + support,
      fieldSpecificFallback,
    );

    return CompositeEmbeddingScore(
      finalScore: finalScore.clamp(-1, 1).toDouble(),
      establishment: establishment,
      categories: categories,
      context: context,
      payment: payment,
      fullCosineScore: fullCosineScore,
      usedFieldScore: true,
    );
  }

  static bool _hasCompatibleFields(
    EmbeddingVector query,
    EmbeddingVector persisted,
  ) {
    return query.vector.length == persisted.vector.length &&
        query.dimension == persisted.dimension &&
        query.vector.length >= 4 &&
        query.vector.length % _fieldCount(query, persisted) == 0 &&
        query.model.contains('field-composite') &&
        persisted.model.contains('field-composite');
  }

  static int _fieldCount(EmbeddingVector query, EmbeddingVector persisted) {
    if (query.model.contains('field-composite-hybrid') &&
        persisted.model.contains('field-composite-hybrid')) {
      return 2;
    }
    return 4;
  }

  static double _fieldSimilarity(
    EmbeddingVector query,
    EmbeddingVector persisted, {
    required int start,
    required int length,
  }) {
    var product = 0.0;
    var queryNorm = 0.0;
    var persistedNorm = 0.0;
    for (var i = start; i < start + length; i++) {
      final a = query.vector[i];
      final b = persisted.vector[i];
      product += a * b;
      queryNorm += a * a;
      persistedNorm += b * b;
    }

    if (queryNorm == 0 || persistedNorm == 0) {
      return 0;
    }
    return product / (math.sqrt(queryNorm) * math.sqrt(persistedNorm));
  }
}
