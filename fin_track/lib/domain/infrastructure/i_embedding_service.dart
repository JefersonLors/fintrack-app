import '../value_objects/embedding_vector.dart';

abstract class IEmbeddingService {
  Future<EmbeddingVector> generate(String text);
}
