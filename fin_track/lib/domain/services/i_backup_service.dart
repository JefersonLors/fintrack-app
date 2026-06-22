import '../entities/backup_record.dart';

abstract class IBackupService {
  Future<BackupRecord> exportBackup({required String password});
  Future<BackupRecord?> runAutomaticBackupIfNeeded({DateTime? now});
  Future<BackupRecord> restoreBackup({required String password});
  Future<List<BackupRecord>> listRecords();
  Stream<List<BackupRecord>> watchRecords();
  Future<void> clearHistory();
  Future<void> deleteBackup({required String password});
}
