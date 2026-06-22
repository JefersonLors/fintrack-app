import '../../domain/infrastructure/i_semantic_index_scheduler.dart';
import '../image/fin_track_platform.dart';

class AndroidSemanticIndexScheduler implements ISemanticIndexScheduler {
  const AndroidSemanticIndexScheduler();

  @override
  Future<bool> schedulePendingSemanticIndex() {
    return FinTrackPlatform.schedulePendingSemanticIndex();
  }

  @override
  Future<bool> cancelPendingSemanticIndex() {
    return FinTrackPlatform.cancelPendingSemanticIndex();
  }
}
