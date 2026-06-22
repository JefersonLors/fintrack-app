import 'package:drift/drift.dart';

import '../../domain/entities/configuration.dart';
import '../../domain/entities/backup_record.dart';
import '../../domain/entities/cloud_provider.dart';
import '../../domain/infrastructure/i_secure_secrets.dart';
import '../../domain/repositories/i_configuration_repository.dart';
import '../security/memory_secure_secrets.dart';
import 'app_database.dart';

class ConfigurationRepository implements IConfigurationRepository {
  ConfigurationRepository(this._database, {ISecureSecrets? secrets})
    : _secrets = secrets ?? MemorySecureSecrets();

  final AppDatabase _database;
  final ISecureSecrets _secrets;

  @override
  Future<Configuration> load() async {
    final row = await (_database.select(
      _database.configurations,
    )..where((tbl) => tbl.id.equals(1))).getSingleOrNull();
    if (row != null) {
      return _mapConfiguration(row);
    }

    await _database
        .into(_database.configurations)
        .insert(
          const ConfigurationsCompanion(id: Value(1)),
          mode: InsertMode.insertOrIgnore,
        );
    return _mapConfiguration(
      const ConfigurationRow(
        id: 1,
        localAuthEnabled: false,
        authenticationType: null,
        autoLockIntervalMinutes: Configuration.defaultAutoLockIntervalMinutes,
        cloudProvider: null,
        linkedCloudAccount: null,
        cloudTokenValid: false,
        cloudLinkedAt: null,
        backupReminderEnabled: false,
        reminderIntervalDays: Configuration.defaultBackupReminderIntervalDays,
        storageLimitMb: 500,
        onboardingCompleted: false,
        lastSyncedExportAt: null,
        backupAvailability: 'INATIVO',
        visualThemeMode: 'ESCURO',
      ),
    );
  }

  @override
  Future<void> save(Configuration configuration) async {
    await _secrets.saveBackupPassword(configuration.backupPassword);
    await _database
        .into(_database.configurations)
        .insertOnConflictUpdate(
          ConfigurationsCompanion(
            id: const Value(1),
            localAuthEnabled: Value(configuration.localAuthEnabled),
            authenticationType: Value(
              configuration.authenticationType?.persistedValue,
            ),
            autoLockIntervalMinutes: Value(
              Configuration.validAutoLockIntervalMinutes(
                configuration.autoLockIntervalMinutes,
              ),
            ),
            cloudProvider: Value(configuration.cloudProvider?.persistedValue),
            linkedCloudAccount: Value(configuration.linkedCloudAccount),
            cloudTokenValid: Value(configuration.cloudTokenValid),
            cloudLinkedAt: Value(configuration.cloudLinkedAt),
            backupReminderEnabled: Value(configuration.backupReminderEnabled),
            reminderIntervalDays: Value(
              Configuration.validBackupReminderIntervalDays(
                configuration.reminderIntervalDays,
              ),
            ),
            storageLimitMb: Value(configuration.storageLimitMB),
            onboardingCompleted: Value(configuration.onboardingCompleted),
            lastSyncedExportAt: Value(configuration.lastSyncedExportAt),
            backupAvailability: Value(
              configuration.backupAvailability.persistedValue,
            ),
            visualThemeMode: Value(
              configuration.visualThemeMode.persistedValue,
            ),
          ),
        );
  }

  @override
  Stream<Configuration> watch() {
    return (_database.select(_database.configurations)
          ..where((tbl) => tbl.id.equals(1)))
        .watchSingle()
        .asyncMap(_mapConfiguration);
  }

  Future<Configuration> _mapConfiguration(ConfigurationRow row) async {
    return Configuration(
      id: row.id,
      localAuthEnabled: row.localAuthEnabled,
      authenticationType: _authenticationType(row.authenticationType),
      autoLockIntervalMinutes: Configuration.validAutoLockIntervalMinutes(
        row.autoLockIntervalMinutes,
      ),
      cloudProvider: _cloudProvider(row.cloudProvider, row.linkedCloudAccount),
      linkedCloudAccount: row.linkedCloudAccount,
      cloudTokenValid: row.cloudTokenValid,
      cloudLinkedAt: row.cloudLinkedAt,
      backupReminderEnabled: row.backupReminderEnabled,
      reminderIntervalDays: Configuration.validBackupReminderIntervalDays(
        row.reminderIntervalDays,
      ),
      storageLimitMB: row.storageLimitMb,
      backupPassword: await _secrets.readBackupPassword(),
      onboardingCompleted: row.onboardingCompleted,
      lastSyncedExportAt: row.lastSyncedExportAt,
      backupAvailability: _availabilityBackup(row.backupAvailability),
      visualThemeMode: _visualThemeMode(row.visualThemeMode),
    );
  }

  BackupAvailability _availabilityBackup(String value) {
    return BackupAvailability.values.firstWhere(
      (state) => state.persistedValue == value,
      orElse: () => BackupAvailability.inactive,
    );
  }

  CloudProvider? _cloudProvider(String? value, String? linkedAccount) {
    if (value == null && linkedAccount == null) {
      return null;
    }
    return CloudProvider.fromPersistedValue(value);
  }

  AuthenticationType? _authenticationType(String? value) {
    if (value == null) {
      return null;
    }
    for (final type in AuthenticationType.values) {
      if (type.persistedValue == value) {
        return type;
      }
    }
    return null;
  }

  VisualThemeMode _visualThemeMode(String value) {
    return VisualThemeMode.values.firstWhere(
      (modo) => modo.persistedValue == value,
      orElse: () => VisualThemeMode.dark,
    );
  }
}
