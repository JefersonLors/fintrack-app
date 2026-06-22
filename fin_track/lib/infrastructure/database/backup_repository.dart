import 'package:drift/drift.dart';

import '../../domain/entities/backup_record.dart';
import '../../domain/entities/cloud_provider.dart';
import '../../domain/repositories/i_backup_repository.dart';
import 'app_database.dart';

class BackupRepository implements IBackupRepository {
  BackupRepository(this._database);

  final AppDatabase _database;

  @override
  Future<BackupRecord> save(BackupRecord record) async {
    final id = await _database
        .into(_database.backupRecords)
        .insert(
          BackupRecordsCompanion.insert(
            createdAt: record.createdAt,
            status: record.status.persistedValue,
            operation: Value(record.operation.persistedValue),
            totalReceipts: Value(record.totalReceipts),
            errorDescription: Value(record.errorDescription),
            cloudProvider: Value(record.cloudProvider?.persistedValue),
            linkedCloudAccount: Value(record.linkedCloudAccount),
            availability: Value(record.availability.persistedValue),
            configurationId: record.configurationId,
          ),
        );
    return (await _findById(id))!;
  }

  @override
  Future<BackupRecord> update(BackupRecord record) async {
    await (_database.update(
      _database.backupRecords,
    )..where((tbl) => tbl.id.equals(record.id))).write(
      BackupRecordsCompanion(
        createdAt: Value(record.createdAt),
        status: Value(record.status.persistedValue),
        operation: Value(record.operation.persistedValue),
        totalReceipts: Value(record.totalReceipts),
        errorDescription: Value(record.errorDescription),
        cloudProvider: Value(record.cloudProvider?.persistedValue),
        linkedCloudAccount: Value(record.linkedCloudAccount),
        availability: Value(record.availability.persistedValue),
        configurationId: Value(record.configurationId),
      ),
    );
    return (await _findById(record.id))!;
  }

  @override
  Future<List<BackupRecord>> list() async {
    final rows = await (_database.select(
      _database.backupRecords,
    )..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])).get();
    return rows.map(_mapRecord).toList();
  }

  @override
  Future<BackupRecord?> findLatest() async {
    final rows = await list();
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Stream<List<BackupRecord>> watchAll() {
    final query = _database.select(_database.backupRecords)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
    return query.watch().map((rows) => rows.map(_mapRecord).toList());
  }

  @override
  Future<void> clearHistory() async {
    await _database.delete(_database.backupRecords).go();
  }

  Future<BackupRecord?> _findById(int id) async {
    final row = await (_database.select(
      _database.backupRecords,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapRecord(row);
  }

  BackupRecord _mapRecord(BackupRecordRow row) {
    return BackupRecord(
      id: row.id,
      createdAt: row.createdAt,
      operation: _operation(row.operation),
      status: _status(row.status),
      totalReceipts: row.totalReceipts,
      errorDescription: row.errorDescription,
      cloudProvider: _cloudProvider(row.cloudProvider, row.linkedCloudAccount),
      linkedCloudAccount: row.linkedCloudAccount,
      availability: _availability(row.availability),
      configurationId: row.configurationId,
    );
  }

  BackupStatus _status(String value) {
    return BackupStatus.values.firstWhere(
      (status) => status.persistedValue == value,
      orElse: () => BackupStatus.failure,
    );
  }

  BackupOperation _operation(String value) {
    return BackupOperation.values.firstWhere(
      (operation) => operation.persistedValue == value,
      orElse: () => BackupOperation.export,
    );
  }

  CloudProvider? _cloudProvider(String? value, String? linkedAccount) {
    if (value == null && linkedAccount == null) {
      return null;
    }
    return CloudProvider.fromPersistedValue(value);
  }

  BackupAvailability _availability(String value) {
    return BackupAvailability.values.firstWhere(
      (state) => state.persistedValue == value,
      orElse: () => BackupAvailability.inactive,
    );
  }
}
