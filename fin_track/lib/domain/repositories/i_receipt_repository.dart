import '../entities/receipt.dart';
import '../entities/embedding.dart';
import '../value_objects/receipt_filter.dart';
import '../value_objects/embedding_vector.dart';

abstract class IReceiptRepository {
  Future<Receipt> save(Receipt receipt);
  Future<void> update(Receipt receipt);
  Future<void> markCloudSynced(Iterable<int> ids);
  Future<void> markAllAsNotCloudSynced();
  Future<void> replaceAll(List<Receipt> receipts);
  Future<void> delete(int id);
  Future<Receipt> findById(int id);
  Future<List<Receipt>> findByFilters(ReceiptFilter filter);
  Future<List<Receipt>> findByTerms(String text);
  Future<List<Receipt>> findSimilar(EmbeddingVector vector, int limit);
  Future<List<Receipt>> findSimilarByFilters(
    EmbeddingVector vector,
    ReceiptFilter filter,
    int limit,
  );
  Future<void> saveEmbedding(Embedding embedding);
  Future<Embedding?> findEmbeddingByReceipt(int receiptId);
  Stream<List<Receipt>> watchByFilters(ReceiptFilter filter);
  Stream<List<Receipt>> watchAll();
}
