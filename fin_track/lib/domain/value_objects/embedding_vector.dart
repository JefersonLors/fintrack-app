import 'dart:math' as math;

class EmbeddingVector {
  const EmbeddingVector({
    required this.vector,
    required this.model,
    required this.dimension,
  });

  final List<double> vector;
  final String model;
  final int dimension;

  double cosineSimilarity(EmbeddingVector other) {
    final limit = math.min(vector.length, other.vector.length);
    if (limit == 0) {
      return 0;
    }

    var product = 0.0;
    var normA = 0.0;
    var normB = 0.0;
    for (var i = 0; i < limit; i++) {
      product += vector[i] * other.vector[i];
      normA += vector[i] * vector[i];
      normB += other.vector[i] * other.vector[i];
    }

    if (normA == 0 || normB == 0) {
      return 0;
    }

    return product / (math.sqrt(normA) * math.sqrt(normB));
  }
}
