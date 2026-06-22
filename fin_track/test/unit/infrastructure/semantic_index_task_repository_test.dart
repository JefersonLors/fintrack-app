import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/infrastructure/database/app_database.dart';
import 'package:fin_track/infrastructure/database/repositories/receipt_repository.dart';
import 'package:fin_track/infrastructure/database/semantic_index_task_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'semantic index task repository claims retries and recovers stale work',
    () async {
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final repository = SemanticIndexTaskRepository(database);
      final receipt = await ReceiptRepository(database).save(
        Receipt(
          id: 0,
          type: ReceiptType.receipt,
          expense: true,
          fileName: 'semantic-task-10.txt',
          fileType: 'text/plain',
          registeredAt: DateTime(2026, 5, 28),
        ),
      );

      await repository.enqueueReceipt(receipt.id);

      final first = await repository.claimNextPending();
      expect(first?.receiptId, receipt.id);
      expect(await repository.claimNextPending(), isNull);

      await repository.resetStaleProcessingTasks(Duration.zero);
      final recovered = await repository.claimNextPending();
      expect(recovered?.receiptId, receipt.id);

      await repository.markFailed(
        receipt.id,
        StateError('SqliteException package:drift/native.dart'),
      );
      expect(await repository.hasRunnableTasks(), isTrue);
      final retry = await repository.claimNextPending();
      expect(retry?.receiptId, receipt.id);
      expect(
        retry?.errorDescription,
        'Não foi possível atualizar a busca semântica.',
      );

      await repository.markFailed(receipt.id, StateError('falha 2'));
      expect(await repository.hasRunnableTasks(), isFalse);
      expect(await repository.claimNextPending(), isNull);
    },
  );

  test(
    'semantic index task repository requeues completed receipt when needed again',
    () async {
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final repository = SemanticIndexTaskRepository(database);
      final receipt = await ReceiptRepository(database).save(
        Receipt(
          id: 0,
          type: ReceiptType.receipt,
          expense: true,
          fileName: 'semantic-task-20.txt',
          fileType: 'text/plain',
          registeredAt: DateTime(2026, 5, 28),
        ),
      );

      await repository.enqueueReceipt(receipt.id);
      expect((await repository.claimNextPending())?.receiptId, receipt.id);
      await repository.markCompleted(receipt.id);
      expect(await repository.hasRunnableTasks(), isFalse);

      await repository.enqueueReceipt(receipt.id);
      expect(await repository.hasRunnableTasks(), isTrue);
      expect((await repository.claimNextPending())?.receiptId, receipt.id);
    },
  );
}
