import 'dart:io';

import '../entities/receipt_batch_import.dart';
import '../entities/receipt.dart';

abstract class IReceiptBatchImportRepository {
  Future<int> createSession({
    required Directory stagingDirectory,
    required List<File> originalFiles,
    required List<File> stagedFiles,
  });

  Future<ReceiptBatchImportSnapshot?> findSnapshot(int sessionId);
  Future<ReceiptBatchImportSnapshot?> findLatestOpenSnapshot();
  Stream<ReceiptBatchImportSnapshot?> watchSnapshot(int sessionId);
  Future<List<ReceiptBatchImportSession>> findRunnableSessions();
  Future<void> resetStaleProcessingItems(int sessionId, Duration staleAfter);
  Future<ReceiptBatchImportItem?> claimNextPendingItem(int sessionId);
  Future<void> markItemReady(int itemId, Receipt receipt);
  Future<void> markItemError(int itemId, Object error);
  Future<void> markItemSaved(int itemId, Receipt receipt);
  Future<void> markSessionStatus(
    int sessionId,
    ReceiptBatchImportStatus status,
  );
  Future<void> refreshSessionStatus(int sessionId);
  Future<void> deleteSession(int sessionId);
}
