import 'dart:async';
import 'dart:io';

import 'package:fin_track/application/policies/backup_automatic_policy.dart';
import 'package:fin_track/application/policies/backup_configuration_policy.dart';
import 'package:fin_track/application/policies/category_deletion_policy.dart';
import 'package:fin_track/application/policies/storage_limit_policy.dart';
import 'package:fin_track/domain/entities/cloud_provider.dart';
import 'package:fin_track/domain/entities/configuration.dart';
import 'package:fin_track/domain/entities/backup_record.dart';
import 'package:fin_track/domain/exceptions/storage_limit_exception.dart';
import 'package:fin_track/domain/services/i_configuration_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BackupAutomaticPolicy validates prerequisites and schedule', () {
    const policy = BackupAutomaticPolicy();
    final now = DateTime(2026, 5, 25, 12);
    final ready = Configuration(
      id: 1,
      backupReminderEnabled: true,
      linkedCloudAccount: 'user@example.com',
      cloudTokenValid: true,
      backupPassword: 'password',
      backupAvailability: BackupAvailability.active,
      lastSyncedExportAt: now.subtract(const Duration(days: 8)),
    );

    expect(policy.canRun(ready), isTrue);
    expect(policy.isDue(ready, now), isTrue);
    expect(policy.canRun(ready.copyWith(clearBackupPassword: true)), isFalse);
    expect(policy.isDue(ready.copyWith(lastSyncedExportAt: now), now), isFalse);
  });

  test(
    'BackupConfigurationPolicy blocks automatic backup without requirements',
    () {
      const policy = BackupConfigurationPolicy();
      const disabled = Configuration(id: 1, backupReminderEnabled: true);
      const enabled = Configuration(
        id: 1,
        backupReminderEnabled: true,
        linkedCloudAccount: 'user@example.com',
        cloudTokenValid: true,
        backupPassword: 'password',
      );

      expect(policy.canEnableAutomaticBackup(disabled), isFalse);
      expect(policy.shouldDisableAutomaticBackup(disabled), isTrue);
      expect(policy.canEnableAutomaticBackup(enabled), isTrue);
      expect(policy.validReminderInterval(999), 7);
    },
  );

  test(
    'CategoryDeletionPolicy keeps deletion blocked when category is in use',
    () {
      const policy = CategoryDeletionPolicy();

      expect(
        () => policy.validateDeletion(hasAssociatedReceipts: true),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => policy.validateDeletion(hasAssociatedReceipts: false),
        returnsNormally,
      );
    },
  );

  test(
    'StorageLimitPolicy checks single and accumulated receipt sizes',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'fintrack_policy_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/receipt.txt')
        ..writeAsStringSync('12345');
      final service = _ConfigurationServiceFake(
        const Configuration(id: 1, storageLimitMB: 1),
        occupiedBytes: 1024 * 1024 - 3,
      );
      final policy = StorageLimitPolicy(configuration: service);

      expect(await policy.fileSize(file), 5);
      await expectLater(
        policy.validateSpaceForNewReceipt(file),
        throwsA(isA<StorageLimitException>()),
      );
    },
  );
}

class _ConfigurationServiceFake implements IConfigurationService {
  _ConfigurationServiceFake(this.configuration, {this.occupiedBytes = 0});

  final Configuration configuration;
  final int occupiedBytes;

  @override
  Future<Configuration> load() async => configuration;

  @override
  Future<int> calculateUsedSpaceBytes() async => occupiedBytes;

  @override
  Future<void> update(Configuration configuration) async {}

  @override
  Future<void> configureAutomaticBackup({
    required bool active,
    required int intervalDays,
  }) async {}

  @override
  Future<void> completeOnboarding() async {}

  @override
  Future<void> unlinkGoogle() async {}

  @override
  Future<void> unlinkCloud() async {}

  @override
  Future<void> normalizeAutomaticBackupIfNeeded() async {}

  @override
  Stream<Configuration> watch() => const Stream.empty();

  @override
  Future<void> resetOnboarding() async {}

  @override
  Future<bool> verifyGoogleToken() async => false;

  @override
  Future<bool> verifyCloudToken() async => false;

  @override
  Future<void> linkGoogle() async {}

  @override
  Future<void> linkCloud(CloudProvider provider) async {}
}
