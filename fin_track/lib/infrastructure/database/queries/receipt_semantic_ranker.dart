import 'dart:typed_data';

import '../../../domain/value_objects/composite_embedding_score.dart';
import '../../../domain/value_objects/embedding_vector.dart';
import '../app_database.dart';
import 'receipt_semantic_query.dart';

class ReceiptSemanticRanker {
  const ReceiptSemanticRanker({
    this.minimumSimilarity = 0.30,
    this.strongSimilarity = 0.45,
    this.similarityWindow = 0.08,
    this.minimumGap = 0.08,
  });

  final double minimumSimilarity;
  final double strongSimilarity;
  final double similarityWindow;
  final double minimumGap;

  List<ReceiptRow> rank(
    List<ReceiptSemanticCandidate> candidates,
    EmbeddingVector query,
    int limit,
  ) {
    final scored = <_ScoredReceipt>[];

    for (final candidate in candidates) {
      final persisted = EmbeddingVector(
        vector: _deserializeVector(candidate.embedding.vector),
        model: candidate.embedding.model,
        dimension: candidate.embedding.dimension,
      );
      if (!_isCompatible(query, persisted)) {
        continue;
      }
      final score = CompositeEmbeddingScore.calculate(
        query: query,
        persisted: persisted,
      ).finalScore;
      scored.add(_ScoredReceipt(candidate.row, score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return _filter(scored).take(limit).map((item) => item.row).toList();
  }

  List<double> _deserializeVector(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final values = <double>[];
    for (var i = 0; i + 8 <= bytes.length; i += 8) {
      values.add(data.getFloat64(i, Endian.little));
    }
    return values;
  }

  bool _isCompatible(EmbeddingVector query, EmbeddingVector persisted) {
    return query.dimension == persisted.dimension &&
        query.vector.length == persisted.vector.length;
  }

  List<_ScoredReceipt> _filter(List<_ScoredReceipt> scored) {
    if (scored.isEmpty) {
      return const <_ScoredReceipt>[];
    }

    final bestScore = scored.first.score;
    if (bestScore < minimumSimilarity) {
      return const <_ScoredReceipt>[];
    }

    final secondScore = scored.length > 1 ? scored[1].score : 0.0;
    final gap = bestScore - secondScore;
    if (bestScore < strongSimilarity) {
      return gap >= minimumGap ? <_ScoredReceipt>[scored.first] : const [];
    }

    final cutoff = (bestScore - similarityWindow) > minimumSimilarity
        ? bestScore - similarityWindow
        : minimumSimilarity;
    return scored.where((item) => item.score >= cutoff).toList();
  }
}

class _ScoredReceipt {
  const _ScoredReceipt(this.row, this.score);

  final ReceiptRow row;
  final double score;
}
