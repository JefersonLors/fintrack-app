import 'package:fin_track/application/receipts/receipt_semantic_service.dart';
import 'package:fin_track/application/receipts/semantic/receipt_semantic_indexer.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/infrastructure/i_embedding_service.dart';
import 'package:fin_track/domain/repositories/i_receipt_repository.dart';
import 'package:fin_track/domain/repositories/i_semantic_index_task_repository.dart';
import 'package:fin_track/domain/value_objects/embedding_vector.dart';
import 'package:fin_track/domain/value_objects/receipt_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'semantic search returns empty list when query embedding fails',
    () async {
      final embeddings = _ThrowingEmbeddingService();
      final service = ReceiptSemanticService(
        receipts: _EmptyReceiptRepository(),
        semanticTasks: InMemorySemanticIndexTaskRepository(),
        embeddings: embeddings,
        semanticIndexer: ReceiptSemanticIndexer(embeddings: embeddings),
      );

      final results = await service.searchSemantically('mercado');

      expect(results, isEmpty);
    },
  );
}

class _ThrowingEmbeddingService implements IEmbeddingService {
  @override
  Future<EmbeddingVector> generate(String text) {
    throw StateError('embedding indisponivel');
  }
}

class _EmptyReceiptRepository implements IReceiptRepository {
  @override
  Future<List<Receipt>> findByFilters(ReceiptFilter filter) async {
    return const <Receipt>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
