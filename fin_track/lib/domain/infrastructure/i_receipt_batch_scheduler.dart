abstract class IReceiptBatchScheduler {
  Future<bool> schedulePendingBatchImports();
  Future<bool> cancelPendingBatchImports();
}

class NoopReceiptBatchScheduler implements IReceiptBatchScheduler {
  const NoopReceiptBatchScheduler();

  @override
  Future<bool> schedulePendingBatchImports() async => true;

  @override
  Future<bool> cancelPendingBatchImports() async => true;
}
