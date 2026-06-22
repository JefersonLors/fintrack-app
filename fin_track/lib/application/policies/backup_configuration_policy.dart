import '../../domain/entities/configuration.dart';

class BackupConfigurationPolicy {
  const BackupConfigurationPolicy();

  int validReminderInterval(int days) {
    return Configuration.validBackupReminderIntervalDays(days);
  }

  bool canEnableAutomaticBackup(Configuration configuration) {
    return configuration.linkedCloudAccount != null &&
        configuration.cloudTokenValid &&
        configuration.hasBackupPassword;
  }

  bool shouldDisableAutomaticBackup(Configuration configuration) {
    return configuration.backupReminderEnabled &&
        !canEnableAutomaticBackup(configuration);
  }
}
