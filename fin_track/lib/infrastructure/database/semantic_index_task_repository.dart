import 'package:drift/drift.dart';

import '../../domain/entities/semantic_index_task.dart';
import '../../domain/repositories/i_semantic_index_task_repository.dart';
import 'app_database.dart';

class SemanticIndexTaskRepository implements ISemanticIndexTaskRepository {
  SemanticIndexTaskRepository(this._database);

  static const _maxAttempts = 3;

  final AppDatabase _database;

  @override
  Future<void> enqueueReceipt(int receiptId) {
    return enqueueReceipts([receiptId]);
  }

  @override
  Future<void> enqueueReceipts(Iterable<int> receiptIds) async {
    final ids = receiptIds.where((id) => id > 0).toSet();
    if (ids.isEmpty) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.transaction(() async {
      for (final id in ids) {
        await _database.customInsert(
          'INSERT INTO semantic_index_task '
          '(receipt_id, status, attempts, error_description, updated_at) '
          'VALUES (?, ?, 0, NULL, ?) '
          'ON CONFLICT(receipt_id) DO UPDATE SET '
          'status = excluded.status, '
          'attempts = 0, '
          'error_description = NULL, '
          'updated_at = excluded.updated_at '
          'WHERE semantic_index_task.status != ?',
          variables: [
            Variable<int>(id),
            Variable<String>(SemanticIndexTaskStatus.pending.persistedValue),
            Variable<int>(now),
            Variable<String>(SemanticIndexTaskStatus.processing.persistedValue),
          ],
        );
      }
    });
  }

  @override
  Future<SemanticIndexTask?> claimNextPending() async {
    final rows = await _database
        .customSelect(
          'SELECT * FROM semantic_index_task '
          'WHERE status = ? AND attempts < ? '
          'ORDER BY updated_at, receipt_id LIMIT 1',
          variables: [
            Variable<String>(SemanticIndexTaskStatus.pending.persistedValue),
            Variable<int>(_maxAttempts),
          ],
        )
        .get();
    if (rows.isEmpty) {
      return null;
    }
    final task = _taskFromRow(rows.single);
    final updated = await _database.customUpdate(
      'UPDATE semantic_index_task SET status = ?, attempts = attempts + 1, '
      'updated_at = ? WHERE receipt_id = ? AND status = ?',
      variables: [
        Variable<String>(SemanticIndexTaskStatus.processing.persistedValue),
        Variable<int>(DateTime.now().millisecondsSinceEpoch),
        Variable<int>(task.receiptId),
        Variable<String>(SemanticIndexTaskStatus.pending.persistedValue),
      ],
      updates: const <TableInfo<Table, Object?>>{},
    );
    if (updated != 1) {
      return claimNextPending();
    }
    return task;
  }

  @override
  Future<void> markCompleted(int receiptId) {
    return _database.customUpdate(
      'UPDATE semantic_index_task SET status = ?, error_description = NULL, '
      'updated_at = ? WHERE receipt_id = ?',
      variables: [
        Variable<String>(SemanticIndexTaskStatus.completed.persistedValue),
        Variable<int>(DateTime.now().millisecondsSinceEpoch),
        Variable<int>(receiptId),
      ],
      updates: const <TableInfo<Table, Object?>>{},
    );
  }

  @override
  Future<void> markFailed(int receiptId, Object error) async {
    final rows = await _database
        .customSelect(
          'SELECT attempts FROM semantic_index_task WHERE receipt_id = ?',
          variables: [Variable<int>(receiptId)],
        )
        .get();
    final attempts = rows.isEmpty
        ? _maxAttempts
        : rows.single.read<int>('attempts');
    final status = attempts >= _maxAttempts
        ? SemanticIndexTaskStatus.failed
        : SemanticIndexTaskStatus.pending;
    await _database.customUpdate(
      'UPDATE semantic_index_task SET status = ?, error_description = ?, '
      'updated_at = ? WHERE receipt_id = ?',
      variables: [
        Variable<String>(status.persistedValue),
        Variable<String>(semanticIndexTaskFailureMessage),
        Variable<int>(DateTime.now().millisecondsSinceEpoch),
        Variable<int>(receiptId),
      ],
      updates: const <TableInfo<Table, Object?>>{},
    );
  }

  @override
  Future<void> resetStaleProcessingTasks(Duration staleAfter) async {
    final now = DateTime.now();
    await _database.customUpdate(
      'UPDATE semantic_index_task SET status = ?, updated_at = ? '
      'WHERE status = ? AND updated_at < ?',
      variables: [
        Variable<String>(SemanticIndexTaskStatus.pending.persistedValue),
        Variable<int>(now.millisecondsSinceEpoch),
        Variable<String>(SemanticIndexTaskStatus.processing.persistedValue),
        Variable<int>(now.subtract(staleAfter).millisecondsSinceEpoch),
      ],
      updates: const <TableInfo<Table, Object?>>{},
    );
  }

  @override
  Future<bool> hasRunnableTasks() async {
    final rows = await _database
        .customSelect(
          'SELECT 1 FROM semantic_index_task '
          'WHERE status = ? AND attempts < ? LIMIT 1',
          variables: [
            Variable<String>(SemanticIndexTaskStatus.pending.persistedValue),
            Variable<int>(_maxAttempts),
          ],
        )
        .get();
    return rows.isNotEmpty;
  }

  SemanticIndexTask _taskFromRow(QueryRow row) {
    return SemanticIndexTask(
      receiptId: row.read<int>('receipt_id'),
      status: SemanticIndexTaskStatus.fromPersisted(row.read<String>('status')),
      attempts: row.read<int>('attempts'),
      errorDescription: row.readNullable<String>('error_description'),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('updated_at'),
      ),
    );
  }
}
