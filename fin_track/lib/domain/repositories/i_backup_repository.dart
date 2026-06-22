import '../entities/backup_record.dart';

abstract class IBackupRepository {
  Future<BackupRecord> save(BackupRecord record);
  Future<BackupRecord> update(BackupRecord record);
  Future<List<BackupRecord>> list();
  Future<BackupRecord?> findLatest();
  Stream<List<BackupRecord>> watchAll();
  Future<void> clearHistory();
}
