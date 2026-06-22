import 'backup_record.dart';
import 'cloud_provider.dart';

enum AuthenticationType {
  pin('PIN', 'PIN'),
  biometric('BIOMETRIA', 'Biometria');

  const AuthenticationType(this.persistedValue, this.label);

  final String persistedValue;
  final String label;
}

enum VisualThemeMode {
  dark('ESCURO'),
  light('CLARO');

  const VisualThemeMode(this.persistedValue);

  final String persistedValue;
}

class Configuration {
  static const defaultAutoLockIntervalMinutes = 5;
  static const autoLockIntervalMinuteOptions = <int>[0, 1, 5, 30];
  static const testReminderIntervalMinutes = 1;
  static const defaultBackupReminderIntervalDays = 7;
  static const backupReminderIntervalDayOptions = <int>[0, 1, 3, 7, 15, 30];

  static int validAutoLockIntervalMinutes(int minutes) {
    if (autoLockIntervalMinuteOptions.contains(minutes)) {
      return minutes;
    }
    return defaultAutoLockIntervalMinutes;
  }

  static String autoLockIntervalLabel(int minutes) {
    return switch (minutes) {
      0 => 'Imediatamente',
      1 => '1 minuto',
      _ => '$minutes minutos',
    };
  }

  static int validBackupReminderIntervalDays(int days) {
    if (backupReminderIntervalDayOptions.contains(days)) {
      return days;
    }
    return defaultBackupReminderIntervalDays;
  }

  static String backupReminderIntervalLabel(int days) {
    return switch (days) {
      0 => 'A cada 1 minuto',
      1 => 'A cada 1 dia',
      _ => 'A cada $days dias',
    };
  }

  static Duration backupReminderDuration(int days) {
    final valid = validBackupReminderIntervalDays(days);
    if (valid == 0) {
      return const Duration(minutes: testReminderIntervalMinutes);
    }
    return Duration(days: valid);
  }

  const Configuration({
    required this.id,
    this.localAuthEnabled = false,
    this.authenticationType,
    this.autoLockIntervalMinutes = defaultAutoLockIntervalMinutes,
    CloudProvider? cloudProvider,
    this.linkedCloudAccount,
    bool? cloudTokenValid,
    this.cloudLinkedAt,
    this.backupReminderEnabled = false,
    this.reminderIntervalDays = defaultBackupReminderIntervalDays,
    this.storageLimitMB = 500,
    this.backupPassword,
    this.onboardingCompleted = false,
    this.lastSyncedExportAt,
    this.backupAvailability = BackupAvailability.inactive,
    this.visualThemeMode = VisualThemeMode.dark,
  }) : cloudProvider =
           cloudProvider ??
           (linkedCloudAccount != null ? CloudProvider.googleDrive : null),
       cloudTokenValid = cloudTokenValid ?? false;

  final int id;
  final bool localAuthEnabled;
  final AuthenticationType? authenticationType;
  final int autoLockIntervalMinutes;
  final CloudProvider? cloudProvider;
  final String? linkedCloudAccount;
  final bool cloudTokenValid;
  final DateTime? cloudLinkedAt;
  final bool backupReminderEnabled;
  final int reminderIntervalDays;
  final int storageLimitMB;
  final String? backupPassword;
  final bool onboardingCompleted;
  final DateTime? lastSyncedExportAt;
  final BackupAvailability backupAvailability;
  final VisualThemeMode visualThemeMode;

  bool get hasBackupPassword => backupPassword?.isNotEmpty == true;

  Configuration copyWith({
    int? id,
    bool? localAuthEnabled,
    AuthenticationType? authenticationType,
    int? autoLockIntervalMinutes,
    CloudProvider? cloudProvider,
    String? linkedCloudAccount,
    bool? cloudTokenValid,
    DateTime? cloudLinkedAt,
    bool? backupReminderEnabled,
    int? reminderIntervalDays,
    int? storageLimitMB,
    String? backupPassword,
    bool? onboardingCompleted,
    DateTime? lastSyncedExportAt,
    BackupAvailability? backupAvailability,
    VisualThemeMode? visualThemeMode,
    bool clearCloudAccount = false,
    bool clearAuthenticationType = false,
    bool clearBackupPassword = false,
    bool clearLastSyncedExportAt = false,
  }) {
    return Configuration(
      id: id ?? this.id,
      localAuthEnabled: localAuthEnabled ?? this.localAuthEnabled,
      authenticationType: clearAuthenticationType
          ? null
          : authenticationType ?? this.authenticationType,
      autoLockIntervalMinutes:
          autoLockIntervalMinutes ?? this.autoLockIntervalMinutes,
      cloudProvider: clearCloudAccount
          ? null
          : cloudProvider ?? this.cloudProvider,
      linkedCloudAccount: clearCloudAccount
          ? null
          : linkedCloudAccount ?? this.linkedCloudAccount,
      cloudTokenValid: clearCloudAccount
          ? false
          : cloudTokenValid ?? this.cloudTokenValid,
      cloudLinkedAt: clearCloudAccount
          ? null
          : cloudLinkedAt ?? this.cloudLinkedAt,
      backupReminderEnabled:
          backupReminderEnabled ?? this.backupReminderEnabled,
      reminderIntervalDays: reminderIntervalDays ?? this.reminderIntervalDays,
      storageLimitMB: storageLimitMB ?? this.storageLimitMB,
      backupPassword: clearBackupPassword
          ? null
          : backupPassword ?? this.backupPassword,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      lastSyncedExportAt: clearLastSyncedExportAt
          ? null
          : lastSyncedExportAt ?? this.lastSyncedExportAt,
      backupAvailability: backupAvailability ?? this.backupAvailability,
      visualThemeMode: visualThemeMode ?? this.visualThemeMode,
    );
  }
}
