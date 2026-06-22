import '../../domain/infrastructure/i_receipt_batch_scheduler.dart';
import '../image/fin_track_platform.dart';

class AndroidReceiptBatchScheduler implements IReceiptBatchScheduler {
  const AndroidReceiptBatchScheduler();

  @override
  Future<bool> schedulePendingBatchImports() {
    return FinTrackPlatform.schedulePendingBatchImports();
  }

  @override
  Future<bool> cancelPendingBatchImports() {
    return FinTrackPlatform.cancelPendingBatchImports();
  }
}
