abstract class ISemanticIndexScheduler {
  Future<bool> schedulePendingSemanticIndex();
  Future<bool> cancelPendingSemanticIndex();
}

class NoopSemanticIndexScheduler implements ISemanticIndexScheduler {
  const NoopSemanticIndexScheduler();

  @override
  Future<bool> schedulePendingSemanticIndex() async => true;

  @override
  Future<bool> cancelPendingSemanticIndex() async => true;
}
