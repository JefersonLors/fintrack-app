import 'dart:io';
import 'dart:typed_data';

import '../../domain/entities/configuration.dart';
import '../../domain/entities/backup_record.dart';
import '../../domain/entities/cloud_provider.dart';
import '../../domain/infrastructure/i_cloud_storage.dart';
import '../../domain/infrastructure/i_cryptography_service.dart';
import '../../domain/infrastructure/i_error_reporter.dart';
import '../../domain/infrastructure/i_image_service.dart';
import '../../domain/repositories/i_backup_repository.dart';
import '../../domain/repositories/i_receipt_repository.dart';
import '../../domain/repositories/i_configuration_repository.dart';
import '../../domain/services/i_backup_service.dart';
import '../../domain/value_objects/receipt_filter.dart';
import '../policies/backup_automatic_policy.dart';
import 'backup_payload_service.dart';
import 'backup_restore_service.dart';

class BackupService implements IBackupService {
  BackupService({
    required IReceiptRepository receipts,
    required IBackupRepository backups,
    required IConfigurationRepository configurations,
    required ICryptographyService cryptography,
    ICloudStorage? cloud,
    ICloudStorageRegistry? cloudRegistry,
    required IImageService images,
    IErrorReporter? errorReporter,
  }) : _receipts = receipts,
       _backups = backups,
       _configurations = configurations,
       _cryptography = cryptography,
       _cloudRegistry = cloudRegistry ?? SingleCloudStorageRegistry(cloud!),
       _errorReporter = errorReporter,
       _payload = BackupPayloadService(
         images: images,
         cryptography: cryptography,
       ),
       _restore = BackupRestoreService(
         payload: BackupPayloadService(
           images: images,
           cryptography: cryptography,
         ),
         images: images,
         receipts: receipts,
         configurations: configurations,
         errorReporter: errorReporter,
       );

  static const _backupAutomaticPolicy = BackupAutomaticPolicy();

  final IReceiptRepository _receipts;
  final IBackupRepository _backups;
  final IConfigurationRepository _configurations;
  final ICryptographyService _cryptography;
  final ICloudStorageRegistry _cloudRegistry;
  final IErrorReporter? _errorReporter;
  final BackupPayloadService _payload;
  final BackupRestoreService _restore;
  Future<BackupRecord?>? _automaticBackupInProgress;
  static const _pendingExportLockTimeout = Duration(hours: 2);

  @override
  Future<BackupRecord> exportBackup({required String password}) async {
    await _ensureNoRecentPendingExport();
    final configuration = await _ensureCloudAccountLinked();
    final cloud = _storageFor(configuration);
    final items = await _receipts.findByFilters(const ReceiptFilter());
    final pending = await _registerPending(
      configuration,
      items.length,
      BackupOperation.export,
    );

    try {
      final payload = await _payload.serializeBackup(items, configuration);
      final encrypted = await _cryptography.encrypt(payload, password);
      await cloud.upload(<Uint8List>[encrypted]);
      await _receipts.markCloudSynced(items.map((receipt) => receipt.id));
      await _markAllBackupsInactive();
      final synced = await _backups.update(
        pending.copyWith(
          status: BackupStatus.synced,
          totalReceipts: items.length,
          availability: BackupAvailability.active,
        ),
      );
      await _configurations.save(
        configuration.copyWith(
          lastSyncedExportAt: synced.createdAt,
          backupAvailability: BackupAvailability.active,
        ),
      );
      return synced;
    } catch (error, stackTrace) {
      return _registerFailure(
        pending,
        _backupFailureMessage(error),
        error,
        stackTrace,
      );
    }
  }

  @override
  Future<BackupRecord?> runAutomaticBackupIfNeeded({DateTime? now}) {
    final inProgress = _automaticBackupInProgress;
    if (inProgress != null) {
      return inProgress;
    }

    final future = _runAutomaticBackupIfNeeded(now ?? DateTime.now());
    _automaticBackupInProgress = future;
    return future.whenComplete(() => _automaticBackupInProgress = null);
  }

  Future<BackupRecord?> _runAutomaticBackupIfNeeded(DateTime now) async {
    final configuration = await _configurations.load();
    final password = configuration.backupPassword;

    if (!configuration.backupReminderEnabled) {
      return null;
    }
    if (!_backupAutomaticPolicy.isDue(configuration, now)) {
      return null;
    }
    if (configuration.linkedCloudAccount == null) {
      return _registerAutomaticFailure(
        configuration,
        'Conta de nuvem não vinculada para o backup automático.',
      );
    }
    if (password == null || password.isEmpty) {
      return _registerAutomaticFailure(
        configuration,
        'Senha de backup ausente. Defina uma senha para retomar o backup automático.',
      );
    }
    if (!configuration.cloudTokenValid) {
      return _registerAutomaticFailure(
        configuration,
        'A sessão da conta de nuvem expirou. Vincule a conta novamente para retomar o backup automático.',
      );
    }

    final validToken = await _storageFor(configuration).verifyToken();
    if (!validToken) {
      await _configurations.save(
        configuration.copyWith(
          cloudTokenValid: false,
          backupReminderEnabled: false,
        ),
      );
      return _registerAutomaticFailure(
        configuration,
        'A sessão da conta de nuvem expirou. Vincule a conta novamente para retomar o backup automático.',
      );
    }

    return exportBackup(password: password);
  }

  Future<void> _ensureNoRecentPendingExport() async {
    final latest = await _backups.findLatest();
    if (latest == null ||
        latest.operation != BackupOperation.export ||
        latest.status != BackupStatus.pending) {
      return;
    }
    final staleBefore = DateTime.now().subtract(_pendingExportLockTimeout);
    if (latest.createdAt.isAfter(staleBefore)) {
      throw StateError('Já existe um backup em andamento.');
    }
  }

  @override
  Future<BackupRecord> restoreBackup({required String password}) async {
    final configuration = await _ensureCloudAccountLinked();
    final pending = await _registerPending(
      configuration,
      0,
      BackupOperation.restore,
    );

    try {
      final files = await _storageFor(configuration).download();
      if (files.isEmpty) {
        throw const FormatException(
          'Nenhum backup disponível para restauração.',
        );
      }
      final totalReceipts = await _restore.restore(
        files: files,
        password: password,
        configuration: configuration,
      );
      return _backups.update(
        pending.copyWith(
          status: BackupStatus.synced,
          totalReceipts: totalReceipts,
        ),
      );
    } catch (error, stackTrace) {
      return _registerFailure(
        pending,
        _restoreFailureMessage(error),
        error,
        stackTrace,
      );
    }
  }

  @override
  Future<List<BackupRecord>> listRecords() => _backups.list();

  @override
  Stream<List<BackupRecord>> watchRecords() {
    return _backups.watchAll();
  }

  @override
  Future<void> clearHistory() {
    return _backups.clearHistory();
  }

  @override
  Future<void> deleteBackup({required String password}) async {
    final configuration = await _ensureCloudAccountLinked();
    final cloud = _storageFor(configuration);
    final files = await cloud.download();
    if (files.isEmpty) {
      throw const FormatException(
        'Nenhum backup disponível para remover da nuvem.',
      );
    }
    await _payload.firstValidBackup(files, password);
    await cloud.deleteBackup();
    await _receipts.markAllAsNotCloudSynced();
    await _markBackupsDeleted();
    await _configurations.save(
      configuration.copyWith(backupAvailability: BackupAvailability.deleted),
    );
  }

  Future<void> _markAllBackupsInactive() async {
    final records = await _backups.list();
    for (final record in records) {
      if (record.operation == BackupOperation.export &&
          record.availability == BackupAvailability.active) {
        await _backups.update(
          record.copyWith(availability: BackupAvailability.inactive),
        );
      }
    }
  }

  Future<void> _markBackupsDeleted() async {
    final records = await _backups.list();
    for (final record in records) {
      if (record.operation == BackupOperation.export &&
          record.availability == BackupAvailability.active) {
        await _backups.update(
          record.copyWith(availability: BackupAvailability.deleted),
        );
      }
    }
  }

  ICloudStorage _storageFor(Configuration configuration) {
    return _cloudRegistry.storageFor(
      configuration.cloudProvider ?? CloudProvider.googleDrive,
    );
  }

  Future<Configuration> _ensureCloudAccountLinked() async {
    var configuration = await _configurations.load();
    if (configuration.linkedCloudAccount == null) {
      throw StateError('Vincule uma conta de nuvem antes de continuar.');
    }

    final validToken =
        configuration.cloudTokenValid &&
        await _storageFor(configuration).verifyToken();
    if (validToken) {
      return configuration;
    }

    await _configurations.save(configuration.copyWith(cloudTokenValid: false));
    CloudAccount account;
    try {
      account = await _storageFor(configuration).linkAccount();
    } catch (error, stackTrace) {
      await _configurations.save(
        configuration.copyWith(
          cloudTokenValid: false,
          backupReminderEnabled: false,
        ),
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
    configuration = (await _configurations.load()).copyWith(
      cloudProvider: configuration.cloudProvider ?? CloudProvider.googleDrive,
      linkedCloudAccount: account.email,
      cloudTokenValid: true,
      cloudLinkedAt: account.linkedAt,
    );
    await _configurations.save(configuration);
    return configuration;
  }

  Future<BackupRecord> _registerPending(
    Configuration configuration,
    int total,
    BackupOperation operation,
  ) {
    return _backups.save(
      BackupRecord(
        id: 0,
        createdAt: DateTime.now(),
        operation: operation,
        status: BackupStatus.pending,
        totalReceipts: total,
        configurationId: configuration.id,
        cloudProvider: configuration.cloudProvider,
        linkedCloudAccount: configuration.linkedCloudAccount,
        availability: BackupAvailability.inactive,
      ),
    );
  }

  Future<BackupRecord> _registerFailure(
    BackupRecord record,
    String message,
    Object error,
    StackTrace stackTrace,
  ) {
    _errorReporter?.record(error, stackTrace);
    return _backups.update(
      record.copyWith(
        status: BackupStatus.failure,
        totalReceipts: record.totalReceipts,
        errorDescription: message,
      ),
    );
  }

  Future<BackupRecord> _registerAutomaticFailure(
    Configuration configuration,
    String message,
  ) async {
    final pending = await _registerPending(
      configuration,
      0,
      BackupOperation.export,
    );
    return _backups.update(
      pending.copyWith(status: BackupStatus.failure, errorDescription: message),
    );
  }

  String _backupFailureMessage(Object error) {
    if (error is CloudStorageFailure) {
      return error.userMessage;
    }
    if (error is FileSystemException || error is FormatException) {
      return 'Não foi possível preparar os comprovantes para backup.';
    }
    return 'Não foi possível concluir o backup. Tente novamente.';
  }

  String _restoreFailureMessage(Object error) {
    if (error is CloudStorageFailure) {
      return error.userMessage;
    }
    if (error is FormatException) {
      return switch (error.message) {
        'Senha incorreta ou backup corrompido.' => error.message,
        'Nenhum backup disponível para restauração.' => error.message,
        _ => 'O arquivo de backup encontrado não pôde ser lido.',
      };
    }
    if (error is FileSystemException) {
      return 'Não foi possível restaurar os arquivos dos comprovantes.';
    }
    return 'Não foi possível restaurar o backup. Tente novamente.';
  }
}
