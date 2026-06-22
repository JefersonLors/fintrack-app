import '../../domain/entities/configuration.dart';
import '../../domain/entities/cloud_provider.dart';
import '../../domain/infrastructure/i_backup_scheduler.dart';
import '../../domain/infrastructure/i_cloud_storage.dart';
import '../../domain/infrastructure/i_image_service.dart';
import '../../domain/repositories/i_configuration_repository.dart';
import '../../domain/services/i_configuration_service.dart';
import '../policies/backup_configuration_policy.dart';

class ConfigurationService implements IConfigurationService {
  ConfigurationService({
    required IConfigurationRepository configurations,
    ICloudStorage? cloud,
    ICloudStorageRegistry? cloudRegistry,
    required IImageService images,
    IBackupScheduler scheduler = const NoopBackupScheduler(),
  }) : _configurations = configurations,
       _cloudRegistry = cloudRegistry ?? SingleCloudStorageRegistry(cloud!),
       _images = images,
       _scheduler = scheduler;

  static const _backupPolicy = BackupConfigurationPolicy();

  final IConfigurationRepository _configurations;
  final ICloudStorageRegistry _cloudRegistry;
  final IImageService _images;
  final IBackupScheduler _scheduler;

  @override
  Future<Configuration> load() => _configurations.load();

  @override
  Future<void> update(Configuration configuration) {
    return _configurations.save(configuration);
  }

  @override
  Future<void> linkCloud(CloudProvider provider) async {
    final cloud = _cloudRegistry.storageFor(provider);
    final account = await cloud.linkAccount();
    final current = await load();
    await update(
      current.copyWith(
        cloudProvider: provider,
        linkedCloudAccount: account.email,
        cloudTokenValid: true,
        cloudLinkedAt: account.linkedAt,
      ),
    );
  }

  @override
  Future<void> unlinkCloud() async {
    final current = await load();
    final provider = current.cloudProvider ?? CloudProvider.googleDrive;
    await _cloudRegistry.storageFor(provider).unlinkAccount();
    await _scheduler.cancelAutomaticBackup();
    await update(
      current.copyWith(
        cloudTokenValid: false,
        backupReminderEnabled: false,
        clearCloudAccount: true,
      ),
    );
  }

  @override
  Future<bool> verifyCloudToken() async {
    final current = await load();
    if (current.linkedCloudAccount == null) {
      return false;
    }
    final provider = current.cloudProvider ?? CloudProvider.googleDrive;
    final valid = await _cloudRegistry.storageFor(provider).verifyToken();
    if (current.cloudTokenValid != valid ||
        (!valid && current.backupReminderEnabled)) {
      if (!valid && current.backupReminderEnabled) {
        await _scheduler.cancelAutomaticBackup();
      }
      await update(
        current.copyWith(
          cloudTokenValid: valid,
          backupReminderEnabled: valid ? current.backupReminderEnabled : false,
        ),
      );
    }
    return valid;
  }

  @override
  Future<void> linkGoogle() => linkCloud(CloudProvider.googleDrive);

  @override
  Future<void> unlinkGoogle() => unlinkCloud();

  @override
  Future<bool> verifyGoogleToken() => verifyCloudToken();

  @override
  Future<void> configureAutomaticBackup({
    required bool active,
    required int intervalDays,
  }) async {
    final current = await load();
    final validInterval = _backupPolicy.validReminderInterval(intervalDays);

    if (!active || !_backupPolicy.canEnableAutomaticBackup(current)) {
      await _scheduler.cancelAutomaticBackup();
      await update(
        current.copyWith(
          backupReminderEnabled: false,
          reminderIntervalDays: validInterval,
        ),
      );
      return;
    }

    final scheduled = await _scheduler.scheduleAutomaticBackup(
      intervalDays: validInterval,
    );
    if (!scheduled) {
      throw StateError('Não foi possível agendar o backup automático.');
    }

    await update(
      current.copyWith(
        backupReminderEnabled: true,
        reminderIntervalDays: validInterval,
      ),
    );
  }

  @override
  Future<void> normalizeAutomaticBackupIfNeeded() async {
    final current = await load();
    if (!current.backupReminderEnabled ||
        _backupPolicy.shouldDisableAutomaticBackup(current)) {
      if (current.backupReminderEnabled) {
        await _scheduler.cancelAutomaticBackup();
        await update(current.copyWith(backupReminderEnabled: false));
      }
      return;
    }
    await _scheduler.scheduleAutomaticBackup(
      intervalDays: _backupPolicy.validReminderInterval(
        current.reminderIntervalDays,
      ),
    );
  }

  @override
  Future<int> calculateUsedSpaceBytes() {
    return _images.calculateUsedSpaceBytes();
  }

  @override
  Future<void> completeOnboarding() async {
    final current = await load();
    await update(current.copyWith(onboardingCompleted: true));
  }

  @override
  Future<void> resetOnboarding() async {
    final current = await load();
    await update(current.copyWith(onboardingCompleted: false));
  }

  @override
  Stream<Configuration> watch() => _configurations.watch();
}
