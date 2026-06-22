import '../../domain/entities/configuration.dart';
import '../../domain/entities/backup_record.dart';

class BackupAutomaticPolicy {
  const BackupAutomaticPolicy();

  bool canRun(Configuration configuration) {
    final password = configuration.backupPassword;
    return configuration.backupReminderEnabled &&
        configuration.linkedCloudAccount != null &&
        configuration.cloudTokenValid &&
        password != null &&
        password.isNotEmpty;
  }

  bool isDue(Configuration configuration, DateTime now) {
    final lastExport = configuration.lastSyncedExportAt;
    if (lastExport == null ||
        configuration.backupAvailability != BackupAvailability.active) {
      return true;
    }
    final interval = Configuration.backupReminderDuration(
      configuration.reminderIntervalDays,
    );
    return !lastExport.add(interval).isAfter(now);
  }
}
