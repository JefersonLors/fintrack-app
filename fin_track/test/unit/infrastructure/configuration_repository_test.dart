import 'package:fin_track/domain/entities/configuration.dart';
import 'package:fin_track/domain/entities/backup_record.dart';
import 'package:fin_track/domain/entities/cloud_provider.dart';
import 'package:fin_track/infrastructure/database/app_database.dart';
import 'package:fin_track/infrastructure/database/configuration_repository.dart';
import 'package:fin_track/infrastructure/security/memory_secure_secrets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.memory();
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'configuration creates defaultConfiguration saves fields and emits observation',
    () async {
      final secrets = MemorySecureSecrets();
      final repository = ConfigurationRepository(database, secrets: secrets);

      final firstConfiguration = await repository.watch().first;
      expect(firstConfiguration.id, 1);
      expect(firstConfiguration.authenticationType, isNull);

      await repository.save(
        firstConfiguration.copyWith(
          localAuthEnabled: true,
          authenticationType: AuthenticationType.pin,
          autoLockIntervalMinutes: 999,
          cloudProvider: CloudProvider.googleDrive,
          linkedCloudAccount: 'account@fintrack.test',
          cloudTokenValid: true,
          cloudLinkedAt: DateTime(2026, 5, 23),
          backupReminderEnabled: true,
          reminderIntervalDays: 999,
          storageLimitMB: 1024,
          backupPassword: 'segredo',
          onboardingCompleted: true,
          lastSyncedExportAt: DateTime(2026, 5, 24),
          backupAvailability: BackupAvailability.active,
          visualThemeMode: VisualThemeMode.light,
        ),
      );

      final saved = await repository.load();
      expect(saved.localAuthEnabled, isTrue);
      expect(saved.authenticationType, AuthenticationType.pin);
      expect(saved.autoLockIntervalMinutes, 5);
      expect(saved.reminderIntervalDays, 7);
      expect(saved.backupPassword, 'segredo');
      expect(saved.backupAvailability, BackupAvailability.active);
      expect(saved.visualThemeMode, VisualThemeMode.light);
      expect(saved.cloudProvider, CloudProvider.googleDrive);
      expect(saved.linkedCloudAccount, 'account@fintrack.test');
      expect(saved.cloudTokenValid, isTrue);
    },
  );

  test(
    'configuration recreates defaultConfiguration and applies persisted fallbacks',
    () async {
      final repository = ConfigurationRepository(database);

      await database.customStatement('DELETE FROM configuration WHERE id = 1');
      final defaultConfiguration = await repository.load();

      expect(defaultConfiguration.id, 1);
      expect(
        defaultConfiguration.backupAvailability,
        BackupAvailability.inactive,
      );
      expect(defaultConfiguration.visualThemeMode, VisualThemeMode.dark);

      await database.customStatement(
        "UPDATE configuration SET backup_availability = 'DESCONHECIDO', "
        "visual_theme_mode = 'NEON', authentication_type = 'IRIS' WHERE id = 1",
      );
      final withInvalidValues = await repository.load();

      expect(withInvalidValues.backupAvailability, BackupAvailability.inactive);
      expect(withInvalidValues.visualThemeMode, VisualThemeMode.dark);
      expect(withInvalidValues.authenticationType, isNull);
    },
  );
}
