import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';

import '../../application/receipts/batch/receipt_batch_codec.dart';
import '../../application/receipts/batch/receipt_batch_state.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/entities/receipt_batch_import.dart';
import '../../domain/repositories/i_receipt_batch_import_repository.dart';
import '../diagnostics/error_handling.dart';
import 'app_database.dart';

class ReceiptBatchImportRepository implements IReceiptBatchImportRepository {
  ReceiptBatchImportRepository(this._database);

  static const _databaseBusyRetryDelays = <Duration>[
    Duration(milliseconds: 80),
    Duration(milliseconds: 160),
    Duration(milliseconds: 320),
    Duration(milliseconds: 640),
    Duration(milliseconds: 1000),
  ];

  final AppDatabase _database;

  @override
  Future<int> createSession({
    required Directory stagingDirectory,
    required List<File> originalFiles,
    required List<File> stagedFiles,
  }) async {
    final now = DateTime.now();
    return _database.transaction(() async {
      final sessionId = await _database
          .customInsert(
            'INSERT INTO receipt_batch_import_session '
            '(created_at, updated_at, status, staging_directory, total_items) '
            'VALUES (?, ?, ?, ?, ?)',
            variables: [
              Variable<int>(now.millisecondsSinceEpoch),
              Variable<int>(now.millisecondsSinceEpoch),
              Variable<String>(ReceiptBatchImportStatus.pending.persistedValue),
              Variable<String>(stagingDirectory.path),
              Variable<int>(stagedFiles.length),
            ],
          )
          .then((_) => _lastInsertRowId());

      for (var index = 0; index < stagedFiles.length; index++) {
        await _database.customInsert(
          'INSERT INTO receipt_batch_import_item '
          '(session_id, item_number, original_path, staged_path, status, updated_at) '
          'VALUES (?, ?, ?, ?, ?, ?)',
          variables: [
            Variable<int>(sessionId),
            Variable<int>(index + 1),
            Variable<String>(originalFiles[index].path),
            Variable<String>(stagedFiles[index].path),
            Variable<String>(
              ReceiptBatchImportItemStatus.pending.persistedValue,
            ),
            Variable<int>(now.millisecondsSinceEpoch),
          ],
        );
      }
      return sessionId;
    });
  }

  @override
  Future<ReceiptBatchImportSnapshot?> findSnapshot(int sessionId) async {
    final sessionRows = await _database
        .customSelect(
          'SELECT * FROM receipt_batch_import_session WHERE id = ?',
          variables: [Variable<int>(sessionId)],
          readsFrom: const <ResultSetImplementation>{},
        )
        .get();
    if (sessionRows.isEmpty) {
      return null;
    }
    return ReceiptBatchImportSnapshot(
      session: _sessionFromRow(sessionRows.single),
      items: await _findItems(sessionId),
    );
  }

  @override
  Future<ReceiptBatchImportSnapshot?> findLatestOpenSnapshot() async {
    final rows = await _database
        .customSelect(
          'SELECT * FROM receipt_batch_import_session '
          "WHERE status IN ('PENDENTE','PROCESSANDO','REVISAO') "
          'ORDER BY updated_at DESC LIMIT 1',
        )
        .get();
    if (rows.isEmpty) {
      return null;
    }
    final session = _sessionFromRow(rows.single);
    return ReceiptBatchImportSnapshot(
      session: session,
      items: await _findItems(session.id),
    );
  }

  @override
  Stream<ReceiptBatchImportSnapshot?> watchSnapshot(int sessionId) {
    return (() async* {
      yield await findSnapshot(sessionId);
      yield* Stream<void>.periodic(
        const Duration(milliseconds: 100),
      ).asyncMap((_) => findSnapshot(sessionId));
    })();
  }

  @override
  Future<List<ReceiptBatchImportSession>> findRunnableSessions() async {
    final rows = await _database
        .customSelect(
          'SELECT * FROM receipt_batch_import_session '
          "WHERE status IN ('PENDENTE','PROCESSANDO') "
          'ORDER BY created_at',
        )
        .get();
    return rows.map(_sessionFromRow).toList();
  }

  @override
  Future<void> resetStaleProcessingItems(
    int sessionId,
    Duration staleAfter,
  ) async {
    final now = DateTime.now();
    final staleBefore = now.subtract(staleAfter).millisecondsSinceEpoch;
    await _writeWithDatabaseBusyRetry(
      () => _database.customUpdate(
        'UPDATE receipt_batch_import_item SET status = ?, updated_at = ? '
        'WHERE session_id = ? AND status = ? AND updated_at < ?',
        variables: [
          Variable<String>(ReceiptBatchImportItemStatus.pending.persistedValue),
          Variable<int>(now.millisecondsSinceEpoch),
          Variable<int>(sessionId),
          Variable<String>(
            ReceiptBatchImportItemStatus.processing.persistedValue,
          ),
          Variable<int>(staleBefore),
        ],
        updates: const <TableInfo<Table, Object?>>{},
      ),
    );
  }

  @override
  Future<ReceiptBatchImportItem?> claimNextPendingItem(int sessionId) async {
    final rows = await _database
        .customSelect(
          'SELECT * FROM receipt_batch_import_item '
          'WHERE session_id = ? AND status = ? '
          'ORDER BY item_number LIMIT 1',
          variables: [
            Variable<int>(sessionId),
            Variable<String>(
              ReceiptBatchImportItemStatus.pending.persistedValue,
            ),
          ],
        )
        .get();
    if (rows.isEmpty) {
      return null;
    }
    final item = _itemFromRow(rows.single);
    final updated = await _writeWithDatabaseBusyRetry(
      () => _database.customUpdate(
        'UPDATE receipt_batch_import_item SET status = ?, updated_at = ? '
        'WHERE id = ? AND status = ?',
        variables: [
          Variable<String>(
            ReceiptBatchImportItemStatus.processing.persistedValue,
          ),
          Variable<int>(DateTime.now().millisecondsSinceEpoch),
          Variable<int>(item.id),
          Variable<String>(ReceiptBatchImportItemStatus.pending.persistedValue),
        ],
        updates: const <TableInfo<Table, Object?>>{},
      ),
    );
    if (updated != 1) {
      return claimNextPendingItem(sessionId);
    }
    await markSessionStatus(sessionId, ReceiptBatchImportStatus.processing);
    return item;
  }

  @override
  Future<void> markItemReady(int itemId, Receipt receipt) async {
    await _updateItem(
      itemId,
      ReceiptBatchImportItemStatus.ready,
      receiptJson: receiptBatchReceiptToJsonString(receipt),
    );
    await _refreshSessionForItem(itemId);
  }

  @override
  Future<void> markItemError(int itemId, Object error) async {
    await _updateItem(
      itemId,
      ReceiptBatchImportItemStatus.error,
      errorDescription: receiptBatchUserErrorMessage(error),
    );
    await _refreshSessionForItem(itemId);
  }

  @override
  Future<void> markItemSaved(int itemId, Receipt receipt) async {
    await _updateItem(
      itemId,
      ReceiptBatchImportItemStatus.saved,
      receiptJson: receiptBatchReceiptToJsonString(receipt),
    );
    await _refreshSessionForItem(itemId);
  }

  @override
  Future<void> markSessionStatus(
    int sessionId,
    ReceiptBatchImportStatus status,
  ) {
    return _writeWithDatabaseBusyRetry(
      () => _database.customUpdate(
        'UPDATE receipt_batch_import_session SET status = ?, updated_at = ? '
        'WHERE id = ?',
        variables: [
          Variable<String>(status.persistedValue),
          Variable<int>(DateTime.now().millisecondsSinceEpoch),
          Variable<int>(sessionId),
        ],
        updates: const <TableInfo<Table, Object?>>{},
      ),
    );
  }

  @override
  Future<void> refreshSessionStatus(int sessionId) async {
    final items = await _findItems(sessionId);
    if (items.isEmpty) {
      return;
    }
    final complete = items.every(
      (item) =>
          item.status == ReceiptBatchImportItemStatus.ready ||
          item.status == ReceiptBatchImportItemStatus.error ||
          item.status == ReceiptBatchImportItemStatus.saved,
    );
    if (complete) {
      await markSessionStatus(sessionId, ReceiptBatchImportStatus.review);
    }
  }

  @override
  Future<void> deleteSession(int sessionId) async {
    final snapshot = await findSnapshot(sessionId);
    await _writeWithDatabaseBusyRetry(
      () => _database.customUpdate(
        'DELETE FROM receipt_batch_import_session WHERE id = ?',
        variables: [Variable<int>(sessionId)],
        updates: const <TableInfo<Table, Object?>>{},
      ),
    );
    final staging = snapshot?.session.stagingDirectory;
    if (staging != null && staging.isNotEmpty) {
      await ignoreCleanupFailure(() async {
        final directory = Directory(staging);
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
    }
  }

  Future<void> _updateItem(
    int itemId,
    ReceiptBatchImportItemStatus status, {
    String? receiptJson,
    String? errorDescription,
  }) {
    return _writeWithDatabaseBusyRetry(
      () => _database.customUpdate(
        'UPDATE receipt_batch_import_item SET '
        'status = ?, receipt_json = ?, error_description = ?, updated_at = ? '
        'WHERE id = ?',
        variables: [
          Variable<String>(status.persistedValue),
          Variable<String>(receiptJson),
          Variable<String>(errorDescription),
          Variable<int>(DateTime.now().millisecondsSinceEpoch),
          Variable<int>(itemId),
        ],
        updates: const <TableInfo<Table, Object?>>{},
      ),
    );
  }

  Future<T> _writeWithDatabaseBusyRetry<T>(Future<T> Function() write) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await write();
      } catch (error) {
        if (!_isDatabaseBusy(error) ||
            attempt >= _databaseBusyRetryDelays.length) {
          rethrow;
        }
        await Future<void>.delayed(_databaseBusyRetryDelays[attempt]);
      }
    }
  }

  bool _isDatabaseBusy(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('database is locked') ||
        message.contains('database_busy') ||
        message.contains('sqlite_busy') ||
        message.contains('code 5');
  }

  Future<void> _refreshSessionForItem(int itemId) async {
    final rows = await _database
        .customSelect(
          'SELECT session_id FROM receipt_batch_import_item WHERE id = ?',
          variables: [Variable<int>(itemId)],
        )
        .get();
    if (rows.isEmpty) {
      return;
    }
    await refreshSessionStatus(rows.single.read<int>('session_id'));
  }

  Future<List<ReceiptBatchImportItem>> _findItems(int sessionId) async {
    final rows = await _database
        .customSelect(
          'SELECT * FROM receipt_batch_import_item '
          'WHERE session_id = ? ORDER BY item_number',
          variables: [Variable<int>(sessionId)],
        )
        .get();
    return rows.map(_itemFromRow).toList();
  }

  Future<int> _lastInsertRowId() async {
    final row = await _database
        .customSelect('SELECT last_insert_rowid() AS id')
        .getSingle();
    return row.read<int>('id');
  }

  ReceiptBatchImportSession _sessionFromRow(QueryRow row) {
    return ReceiptBatchImportSession(
      id: row.read<int>('id'),
      createdAt: _date(row.read<int>('created_at')),
      updatedAt: _date(row.read<int>('updated_at')),
      status: ReceiptBatchImportStatus.fromPersisted(
        row.read<String>('status'),
      ),
      stagingDirectory: row.read<String>('staging_directory'),
      totalItems: row.read<int>('total_items'),
    );
  }

  ReceiptBatchImportItem _itemFromRow(QueryRow row) {
    return ReceiptBatchImportItem(
      id: row.read<int>('id'),
      sessionId: row.read<int>('session_id'),
      number: row.read<int>('item_number'),
      originalPath: row.read<String>('original_path'),
      stagedPath: row.read<String>('staged_path'),
      status: ReceiptBatchImportItemStatus.fromPersisted(
        row.read<String>('status'),
      ),
      errorDescription: row.readNullable<String>('error_description'),
      receiptJson: row.readNullable<String>('receipt_json'),
      updatedAt: _date(row.read<int>('updated_at')),
    );
  }

  DateTime _date(int millis) => DateTime.fromMillisecondsSinceEpoch(millis);
}
