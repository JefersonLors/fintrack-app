import '../entities/semantic_index_task.dart';

const semanticIndexTaskFailureMessage =
    'Não foi possível atualizar a busca semântica.';

abstract class ISemanticIndexTaskRepository {
  Future<void> enqueueReceipt(int receiptId);
  Future<void> enqueueReceipts(Iterable<int> receiptIds);
  Future<SemanticIndexTask?> claimNextPending();
  Future<void> markCompleted(int receiptId);
  Future<void> markFailed(int receiptId, Object error);
  Future<void> resetStaleProcessingTasks(Duration staleAfter);
  Future<bool> hasRunnableTasks();
}

class InMemorySemanticIndexTaskRepository
    implements ISemanticIndexTaskRepository {
  InMemorySemanticIndexTaskRepository();

  final Map<int, SemanticIndexTask> _tasks = {};

  @override
  Future<void> enqueueReceipt(int receiptId) {
    return enqueueReceipts([receiptId]);
  }

  @override
  Future<void> enqueueReceipts(Iterable<int> receiptIds) async {
    final now = DateTime.now();
    for (final id in receiptIds.where((id) => id > 0).toSet()) {
      final current = _tasks[id];
      if (current?.status == SemanticIndexTaskStatus.processing) {
        continue;
      }
      _tasks[id] = SemanticIndexTask(
        receiptId: id,
        status: SemanticIndexTaskStatus.pending,
        attempts: 0,
        updatedAt: now,
      );
    }
  }

  @override
  Future<SemanticIndexTask?> claimNextPending() async {
    final pending =
        _tasks.values
            .where(
              (task) =>
                  task.status == SemanticIndexTaskStatus.pending &&
                  task.attempts < 3,
            )
            .toList()
          ..sort((a, b) {
            final byDate = a.updatedAt.compareTo(b.updatedAt);
            return byDate != 0 ? byDate : a.receiptId.compareTo(b.receiptId);
          });
    if (pending.isEmpty) {
      return null;
    }
    final task = pending.first;
    _tasks[task.receiptId] = SemanticIndexTask(
      receiptId: task.receiptId,
      status: SemanticIndexTaskStatus.processing,
      attempts: task.attempts + 1,
      updatedAt: DateTime.now(),
      errorDescription: task.errorDescription,
    );
    return task;
  }

  @override
  Future<void> markCompleted(int receiptId) async {
    _tasks[receiptId] = SemanticIndexTask(
      receiptId: receiptId,
      status: SemanticIndexTaskStatus.completed,
      attempts: _tasks[receiptId]?.attempts ?? 0,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> markFailed(int receiptId, Object error) async {
    final attempts = _tasks[receiptId]?.attempts ?? 3;
    _tasks[receiptId] = SemanticIndexTask(
      receiptId: receiptId,
      status: attempts >= 3
          ? SemanticIndexTaskStatus.failed
          : SemanticIndexTaskStatus.pending,
      attempts: attempts,
      updatedAt: DateTime.now(),
      errorDescription: semanticIndexTaskFailureMessage,
    );
  }

  @override
  Future<void> resetStaleProcessingTasks(Duration staleAfter) async {
    final staleBefore = DateTime.now().subtract(staleAfter);
    for (final entry in _tasks.entries.toList()) {
      final task = entry.value;
      if (task.status == SemanticIndexTaskStatus.processing &&
          task.updatedAt.isBefore(staleBefore)) {
        _tasks[entry.key] = SemanticIndexTask(
          receiptId: task.receiptId,
          status: SemanticIndexTaskStatus.pending,
          attempts: task.attempts,
          updatedAt: DateTime.now(),
          errorDescription: task.errorDescription,
        );
      }
    }
  }

  @override
  Future<bool> hasRunnableTasks() async {
    return _tasks.values.any(
      (task) =>
          task.status == SemanticIndexTaskStatus.pending && task.attempts < 3,
    );
  }
}
