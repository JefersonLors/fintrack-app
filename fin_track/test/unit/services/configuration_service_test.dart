import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fin_track/application/configuration/configuration_service.dart';
import 'package:fin_track/bootstrap/fin_track_dependencies.dart';
import 'package:fin_track/domain/entities/cloud_provider.dart';
import 'package:fin_track/domain/entities/configuration.dart';
import 'package:fin_track/domain/infrastructure/i_backup_scheduler.dart';
import 'package:fin_track/domain/infrastructure/i_cloud_storage.dart';
import 'package:fin_track/domain/infrastructure/i_image_service.dart';
import 'package:fin_track/domain/repositories/i_configuration_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onboarding is reset', () async {
    final dependencies = FinTrackDependencies.local();
    final service = dependencies.configurationService;

    expect((await service.load()).onboardingCompleted, isFalse);

    await service.completeOnboarding();
    expect((await service.load()).onboardingCompleted, isTrue);

    await service.resetOnboarding();
    final configuration = await service.load();
    expect(configuration.onboardingCompleted, isFalse);

    dependencies.dispose();
  });

  test('automatic lock interval is persisted in configurations', () async {
    final dependencies = FinTrackDependencies.local();
    final service = dependencies.configurationService;

    final current = await service.load();
    expect(current.autoLockIntervalMinutes, 5);
    expect(Configuration.autoLockIntervalMinuteOptions, [0, 1, 5, 30]);
    expect(Configuration.autoLockIntervalLabel(0), 'Imediatamente');
    expect(Configuration.autoLockIntervalLabel(1), '1 minuto');
    expect(Configuration.autoLockIntervalLabel(30), '30 minutos');
    expect(Configuration.validAutoLockIntervalMinutes(20), 5);

    await service.update(current.copyWith(autoLockIntervalMinutes: 30));

    expect((await service.load()).autoLockIntervalMinutes, 30);

    dependencies.dispose();
  });

  test('automatic backup requires linked account and password', () async {
    final dependencies = FinTrackDependencies.local();
    final service = dependencies.configurationService;

    await service.configureAutomaticBackup(active: true, intervalDays: 0);
    var configuration = await service.load();
    expect(configuration.backupReminderEnabled, isFalse);

    await service.linkGoogle();
    configuration = await service.load();
    await service.update(
      configuration.copyWith(backupPassword: 'password-segura-123'),
    );
    await service.configureAutomaticBackup(active: true, intervalDays: 0);
    configuration = await service.load();
    expect(configuration.backupReminderEnabled, isTrue);
    expect(configuration.reminderIntervalDays, 0);

    await service.configureAutomaticBackup(active: true, intervalDays: 15);
    configuration = await service.load();
    expect(configuration.reminderIntervalDays, 15);

    await service.unlinkGoogle();
    configuration = await service.load();
    expect(configuration.backupReminderEnabled, isFalse);
    expect(configuration.linkedCloudAccount, isNull);

    dependencies.dispose();
  });

  test('linkCloud persists selected provider and account metadata', () async {
    final repo = _FakeConfigurationRepository(const Configuration(id: 1));
    final service = ConfigurationService(
      configurations: repo,
      cloud: _FakeCloud(),
      images: _FakeImageService(),
    );

    await service.linkCloud(CloudProvider.googleDrive);

    final configuration = await service.load();
    expect(configuration.cloudProvider, CloudProvider.googleDrive);
    expect(configuration.linkedCloudAccount, 'user@example.com');
    expect(configuration.cloudTokenValid, isTrue);
    expect(configuration.cloudLinkedAt, DateTime(2026, 5, 23));
  });

  test('automatic backup schedules and cancels background work', () async {
    final repo = _FakeConfigurationRepository(
      const Configuration(
        id: 1,
        linkedCloudAccount: 'user@example.com',
        cloudTokenValid: true,
        backupPassword: 'password',
      ),
    );
    final scheduler = _FakeBackupScheduler();
    final service = ConfigurationService(
      configurations: repo,
      cloud: _FakeCloud(),
      images: _FakeImageService(),
      scheduler: scheduler,
    );

    await service.configureAutomaticBackup(active: true, intervalDays: 7);
    expect(scheduler.scheduledIntervals, [7]);
    expect((await service.load()).backupReminderEnabled, isTrue);

    await service.configureAutomaticBackup(active: false, intervalDays: 7);
    expect(scheduler.cancelCount, 1);
    expect((await service.load()).backupReminderEnabled, isFalse);
  });

  test('automatic backup is not enabled when scheduling fails', () async {
    final repo = _FakeConfigurationRepository(
      const Configuration(
        id: 1,
        linkedCloudAccount: 'user@example.com',
        cloudTokenValid: true,
        backupPassword: 'password',
      ),
    );
    final scheduler = _FakeBackupScheduler(scheduleResult: false);
    final service = ConfigurationService(
      configurations: repo,
      cloud: _FakeCloud(),
      images: _FakeImageService(),
      scheduler: scheduler,
    );

    await expectLater(
      service.configureAutomaticBackup(active: true, intervalDays: 7),
      throwsStateError,
    );
    expect((await service.load()).backupReminderEnabled, isFalse);
  });

  test('disabling Google token cancels scheduled automatic backup', () async {
    final repo = _FakeConfigurationRepository(
      const Configuration(
        id: 1,
        linkedCloudAccount: 'user@example.com',
        cloudTokenValid: true,
        backupReminderEnabled: true,
        backupPassword: 'password',
      ),
    );
    final scheduler = _FakeBackupScheduler();
    final service = ConfigurationService(
      configurations: repo,
      cloud: _FakeCloud(validToken: false),
      images: _FakeImageService(),
      scheduler: scheduler,
    );

    expect(await service.verifyGoogleToken(), isFalse);
    expect(scheduler.cancelCount, 1);
    expect(repo.savedItems.single.backupReminderEnabled, isFalse);
  });

  test('backup password is not kept in SQLite schema', () async {
    final dependencies = FinTrackDependencies.local();
    final service = dependencies.configurationService;

    final current = await service.load();
    await service.update(
      current.copyWith(backupPassword: 'password-segura-123'),
    );

    final configuration = await service.load();
    expect(configuration.backupPassword, 'password-segura-123');

    final columns = await dependencies.database
        .customSelect('PRAGMA table_info(configuration)')
        .get();
    final names = columns.map((row) => row.read<String>('name')).toSet();
    expect(names, isNot(contains('backup_password')));

    dependencies.dispose();
  });

  test('visual theme mode is dark by default and persists change', () async {
    final dependencies = FinTrackDependencies.local();
    final service = dependencies.configurationService;

    final current = await service.load();
    expect(current.visualThemeMode, VisualThemeMode.dark);

    await service.update(
      current.copyWith(visualThemeMode: VisualThemeMode.light),
    );
    expect((await service.load()).visualThemeMode, VisualThemeMode.light);

    final columns = await dependencies.database
        .customSelect('PRAGMA table_info(configuration)')
        .get();
    final names = columns.map((row) => row.read<String>('name')).toSet();
    expect(names, contains('visual_theme_mode'));

    dependencies.dispose();
  });

  group('ConfigurationService comportamentos adicionais', () {
    test('verifyGoogleToken disables reminder when token expires', () async {
      final repo = _FakeConfigurationRepository(
        const Configuration(
          id: 1,
          linkedCloudAccount: 'user@example.com',
          cloudTokenValid: true,
          backupReminderEnabled: true,
          backupPassword: 'password',
        ),
      );
      final service = ConfigurationService(
        configurations: repo,
        cloud: _FakeCloud(validToken: false),
        images: _FakeImageService(),
      );

      expect(await service.verifyGoogleToken(), isFalse);

      expect(repo.savedItems.single.cloudTokenValid, isFalse);
      expect(repo.savedItems.single.backupReminderEnabled, isFalse);
    });

    test('normalizes automatic backup only when necessary', () async {
      final repo = _FakeConfigurationRepository(
        const Configuration(
          id: 1,
          linkedCloudAccount: 'user@example.com',
          cloudTokenValid: false,
          backupReminderEnabled: true,
          backupPassword: 'password',
        ),
      );
      final service = ConfigurationService(
        configurations: repo,
        cloud: _FakeCloud(),
        images: _FakeImageService(usedSpace: 42),
      );

      await service.normalizeAutomaticBackupIfNeeded();
      expect(repo.savedItems.single.backupReminderEnabled, isFalse);
      expect(await service.calculateUsedSpaceBytes(), 42);

      repo
        ..savedItems.clear()
        ..current = const Configuration(
          id: 2,
          linkedCloudAccount: 'user@example.com',
          cloudTokenValid: true,
          backupReminderEnabled: false,
          backupPassword: 'password',
        );
      await service.normalizeAutomaticBackupIfNeeded();
      expect(repo.savedItems, isEmpty);
    });

    test('normalization reschedules valid automatic backup', () async {
      final repo = _FakeConfigurationRepository(
        const Configuration(
          id: 1,
          linkedCloudAccount: 'user@example.com',
          cloudTokenValid: true,
          backupReminderEnabled: true,
          reminderIntervalDays: 3,
          backupPassword: 'password',
        ),
      );
      final scheduler = _FakeBackupScheduler();
      final service = ConfigurationService(
        configurations: repo,
        cloud: _FakeCloud(),
        images: _FakeImageService(),
        scheduler: scheduler,
      );

      await service.normalizeAutomaticBackupIfNeeded();

      expect(scheduler.scheduledIntervals, [3]);
      expect(repo.savedItems, isEmpty);
    });
  });
}

class _FakeConfigurationRepository implements IConfigurationRepository {
  _FakeConfigurationRepository(this.current);

  Configuration current;
  final savedItems = <Configuration>[];
  final controller = StreamController<Configuration>.broadcast();

  @override
  Future<Configuration> load() async => current;

  @override
  Stream<Configuration> watch() => controller.stream;

  @override
  Future<void> save(Configuration configuration) async {
    current = configuration;
    savedItems.add(configuration);
    controller.add(configuration);
  }
}

class _FakeCloud implements ICloudStorage {
  const _FakeCloud({this.validToken = true});

  final bool validToken;

  @override
  Future<void> upload(List<Uint8List> files) async {}

  @override
  Future<void> deleteBackup() async {}

  @override
  Future<List<Uint8List>> download() async => const <Uint8List>[];

  @override
  Future<void> unlinkAccount() async {}

  @override
  Future<bool> verifyToken() async => validToken;

  @override
  Future<CloudAccount> linkAccount() async {
    return CloudAccount(
      email: 'user@example.com',
      linkedAt: DateTime(2026, 5, 23),
    );
  }
}

class _FakeBackupScheduler implements IBackupScheduler {
  _FakeBackupScheduler({this.scheduleResult = true});

  final bool scheduleResult;
  final scheduledIntervals = <int>[];
  var cancelCount = 0;

  @override
  Future<bool> scheduleAutomaticBackup({required int intervalDays}) async {
    scheduledIntervals.add(intervalDays);
    return scheduleResult;
  }

  @override
  Future<bool> cancelAutomaticBackup() async {
    cancelCount++;
    return true;
  }

  @override
  Future<bool> runNowForTesting() async {
    return true;
  }
}

class _FakeImageService implements IImageService {
  const _FakeImageService({this.usedSpace = 0});

  final int usedSpace;

  @override
  Future<int> calculateUsedSpaceBytes() async => usedSpace;

  @override
  Future<File> capture() => throw UnimplementedError();

  @override
  Future<void> share(String fileName, String fileType) async {}

  @override
  Future<void> shareMany(List<String> fileNames) async {}

  @override
  Future<TemporaryRestoreDirectory> createTemporaryRestore() async {
    return const TemporaryRestoreDirectory(path: '', rollbackPath: '');
  }

  @override
  Future<void> discardTemporaryRestore(
    TemporaryRestoreDirectory session,
  ) async {}

  @override
  Future<void> delete(String fileName) async {}

  @override
  Future<int> deleteUnreferencedFiles(Set<String> fileNames) async {
    return 0;
  }

  @override
  Future<void> deleteIfManaged(String fileName) async {}

  @override
  Future<void> deleteAll() async {}

  @override
  bool managedByApp(String fileName) => false;

  @override
  Future<List<File>> importMany() => throw UnimplementedError();

  @override
  Future<void> promoteTemporaryRestore(
    TemporaryRestoreDirectory session,
  ) async {}

  @override
  String rebuildPath(String fileName) => fileName;

  @override
  Future<String> restoreToTemporaryDirectory(
    TemporaryRestoreDirectory session,
    String fileName,
    Uint8List bytes,
  ) async {
    return fileName;
  }

  @override
  Future<String> restoreToFileSystem(String fileName, Uint8List bytes) async {
    return fileName;
  }

  @override
  Future<void> revertTemporaryRestore(
    TemporaryRestoreDirectory session,
  ) async {}

  @override
  Future<void> saveToDevice(String fileName, String fileType) async {}

  @override
  Future<void> saveManyToDevice(List<String> fileNames) async {}

  @override
  Future<String> saveToFileSystem(File file) async => file.path;
}
