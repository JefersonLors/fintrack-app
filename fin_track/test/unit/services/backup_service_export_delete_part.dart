part of 'backup_service_test.dart';

void registerBackupExportDeleteTests() {
  test('encrypted backup records synced status', () async {
    final environment = await _createEnvironment();
    final receipt = await _saveReceipt(
      environment.receipts,
      environment.images,
    );
    await environment.configurationService.linkGoogle();

    expect(
      (await environment.receipts.findById(receipt.id)).cloudSynced,
      isFalse,
    );

    final record = await environment.backupService.exportBackup(
      password: 'password-segura-123',
    );
    final sent = environment.cloud.files.single;
    final synced = await environment.receipts.findById(receipt.id);
    final encryptedText = latin1.decode(sent, allowInvalid: true);

    expect(record.operation, BackupOperation.export);
    expect(record.status, BackupStatus.synced);
    expect(record.totalReceipts, 1);
    expect(synced.cloudSynced, isTrue);
    expect(encryptedText.contains('Mercado Central'), isFalse);
    expect(encryptedText.contains('comprovante em texto claro'), isFalse);

    await environment.dispose();
  });

  test('backup failure updates BackupRecord with failure status', () async {
    final environment = await _createEnvironment();
    final receipt = await _saveReceipt(
      environment.receipts,
      environment.images,
    );
    await environment.configurationService.linkGoogle();
    environment.cloud.failUpload = true;

    final record = await environment.backupService.exportBackup(
      password: 'password-segura-123',
    );
    final history = await environment.backups.list();

    expect(record.status, BackupStatus.failure);
    expect(record.operation, BackupOperation.export);
    expect(
      record.errorDescription,
      'Não foi possível concluir o backup. Tente novamente.',
    );
    expect(history, hasLength(1));
    expect(history.single.status, BackupStatus.failure);
    expect(
      (await environment.receipts.findById(receipt.id)).cloudSynced,
      isFalse,
    );

    await environment.dispose();
  });

  test('automatic backup records failure when password is missing', () async {
    final environment = await _createEnvironment();
    await environment.configurationService.linkGoogle();
    final current = await environment.configurations.load();
    await environment.configurations.save(
      current.copyWith(backupReminderEnabled: true, backupPassword: ''),
    );

    final record = await environment.backupService.runAutomaticBackupIfNeeded(
      now: DateTime(2026, 5, 28, 10),
    );
    final history = await environment.backups.list();

    expect(record, isNotNull);
    expect(record!.status, BackupStatus.failure);
    expect(
      record.errorDescription,
      'Senha de backup ausente. Defina uma senha para retomar o backup automático.',
    );
    expect(history.single.status, BackupStatus.failure);

    await environment.dispose();
  });

  test(
    'automatic backup records failure and disables config when token expires',
    () async {
      final environment = await _createEnvironment();
      await environment.configurationService.linkGoogle();
      environment.cloud.linked = false;
      final current = await environment.configurations.load();
      await environment.configurations.save(
        current.copyWith(
          backupReminderEnabled: true,
          backupPassword: 'password-segura-123',
        ),
      );

      final record = await environment.backupService.runAutomaticBackupIfNeeded(
        now: DateTime(2026, 5, 28, 10),
      );
      final configuration = await environment.configurations.load();

      expect(record, isNotNull);
      expect(record!.status, BackupStatus.failure);
      expect(
        record.errorDescription,
        'A sessão da conta de nuvem expirou. Vincule a conta novamente para retomar o backup automático.',
      );
      expect(configuration.cloudTokenValid, isFalse);
      expect(configuration.backupReminderEnabled, isFalse);

      await environment.dispose();
    },
  );

  test(
    'new backup inactivates previous backups and keeps only the latest active',
    () async {
      final environment = await _createEnvironment();
      await _saveReceipt(environment.receipts, environment.images);
      await environment.configurationService.linkGoogle();

      final first = await environment.backupService.exportBackup(
        password: 'password-segura-123',
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final second = await environment.backupService.exportBackup(
        password: 'password-segura-123',
      );
      final records = await environment.backups.list();
      final firstPersisted = records.singleWhere(
        (record) => record.id == first.id,
      );
      final secondPersisted = records.singleWhere(
        (record) => record.id == second.id,
      );
      final activeExports = records.where(
        (record) =>
            record.operation == BackupOperation.export &&
            record.availability == BackupAvailability.active,
      );

      expect(records, hasLength(2));
      expect(first.availability, BackupAvailability.active);
      expect(second.availability, BackupAvailability.active);
      expect(firstPersisted.availability, BackupAvailability.inactive);
      expect(secondPersisted.availability, BackupAvailability.active);
      expect(activeExports, hasLength(1));
      expect(activeExports.single.id, second.id);
      expect(first.id, isNot(equals(second.id)));

      await environment.dispose();
    },
  );

  test(
    'delete backup removes from cloud and marks records as deleted',
    () async {
      final environment = await _createEnvironment();
      final receipt = await _saveReceipt(
        environment.receipts,
        environment.images,
      );
      await environment.configurationService.linkGoogle();

      await environment.backupService.exportBackup(
        password: 'password-segura-123',
      );
      expect(environment.cloud.files, isNotEmpty);

      await environment.backupService.deleteBackup(
        password: 'password-segura-123',
      );
      final records = await environment.backups.list();
      final receiptLocal = await environment.receipts.findById(receipt.id);

      expect(environment.cloud.files, isEmpty);
      expect(records, hasLength(1));
      expect(records.single.availability, BackupAvailability.deleted);
      expect(receiptLocal.cloudSynced, isFalse);

      await environment.dispose();
    },
  );

  test(
    'delete backup requires correct password before clearing cloud',
    () async {
      final environment = await _createEnvironment();
      final receipt = await _saveReceipt(
        environment.receipts,
        environment.images,
      );
      await environment.configurationService.linkGoogle();
      await environment.backupService.exportBackup(
        password: 'password-segura-123',
      );

      await expectLater(
        environment.backupService.deleteBackup(
          password: 'password-incorreta-456',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Senha incorreta ou backup corrompido.',
          ),
        ),
      );
      final records = await environment.backups.list();
      final receiptLocal = await environment.receipts.findById(receipt.id);

      expect(environment.cloud.files, isNotEmpty);
      expect(records.single.availability, BackupAvailability.active);
      expect(receiptLocal.cloudSynced, isTrue);

      await environment.dispose();
    },
  );

  test('delete backup does not mark restores as deleted', () async {
    final source = await _createEnvironment();
    await _saveReceipt(source.receipts, source.images);
    await source.configurationService.linkGoogle();
    await source.backupService.exportBackup(password: 'password-segura-123');

    final target = await _createEnvironment(cloud: source.cloud);
    await target.configurationService.linkGoogle();
    await target.backupService.restoreBackup(password: 'password-segura-123');

    await target.backupService.deleteBackup(password: 'password-segura-123');
    final records = await target.backups.list();

    expect(target.cloud.files, isEmpty);
    expect(records, hasLength(1));
    expect(records.single.operation, BackupOperation.restore);
    expect(records.single.status, BackupStatus.synced);
    expect(records.single.availability, BackupAvailability.inactive);

    await source.dispose();
    await target.dispose();
  });

  test('backup requests reauthentication when token expires', () async {
    final environment = await _createEnvironment();
    await _saveReceipt(environment.receipts, environment.images);
    await environment.configurationService.linkGoogle();
    final current = await environment.configurations.load();
    await environment.configurations.save(
      current.copyWith(cloudTokenValid: false),
    );

    final record = await environment.backupService.exportBackup(
      password: 'password-segura-123',
    );
    final configuration = await environment.configurations.load();

    expect(record.status, BackupStatus.synced);
    expect(environment.cloud.linkCount, 2);
    expect(configuration.cloudTokenValid, isTrue);

    await environment.dispose();
  });

  test('successful manual backup preserves active automatic backup', () async {
    final environment = await _createEnvironment();
    await _saveReceipt(environment.receipts, environment.images);
    await environment.configurationService.linkGoogle();
    await environment.configurations.save(
      (await environment.configurations.load()).copyWith(
        backupPassword: 'password-segura-123',
      ),
    );
    await environment.configurationService.configureAutomaticBackup(
      active: true,
      intervalDays: 0,
    );

    final record = await environment.backupService.exportBackup(
      password: 'password-segura-123',
    );

    expect(record.status, BackupStatus.synced);
    final configuration = await environment.configurations.load();
    expect(configuration.backupReminderEnabled, isTrue);
    expect(configuration.reminderIntervalDays, 0);
    expect(configuration.lastSyncedExportAt, record.createdAt);
    expect(configuration.backupAvailability, BackupAvailability.active);

    await environment.dispose();
  });

  test('automatic backup runs when due and password is set', () async {
    final environment = await _createEnvironment();
    await _saveReceipt(environment.receipts, environment.images);
    await environment.configurationService.linkGoogle();
    await environment.configurations.save(
      (await environment.configurations.load()).copyWith(
        backupPassword: 'password-segura-123',
      ),
    );
    await environment.configurationService.configureAutomaticBackup(
      active: true,
      intervalDays: 0,
    );

    final record = await environment.backupService.runAutomaticBackupIfNeeded(
      now: DateTime(2026, 5, 10, 12),
    );

    expect(record, isNotNull);
    expect(record!.status, BackupStatus.synced);
    expect(environment.cloud.files, hasLength(1));

    await environment.dispose();
  });

  test(
    'automatic backup does not run without password or before interval',
    () async {
      final environment = await _createEnvironment();
      await _saveReceipt(environment.receipts, environment.images);
      await environment.configurationService.linkGoogle();

      await environment.configurationService.configureAutomaticBackup(
        active: true,
        intervalDays: 0,
      );
      expect(
        await environment.backupService.runAutomaticBackupIfNeeded(),
        isNull,
      );
      expect(environment.cloud.files, isEmpty);

      await environment.configurations.save(
        (await environment.configurations.load()).copyWith(
          backupPassword: 'password-segura-123',
          backupReminderEnabled: true,
          reminderIntervalDays: 1,
          lastSyncedExportAt: DateTime(2026, 5, 10, 12),
          backupAvailability: BackupAvailability.active,
        ),
      );

      expect(
        await environment.backupService.runAutomaticBackupIfNeeded(
          now: DateTime(2026, 5, 10, 18),
        ),
        isNull,
      );
      expect(environment.cloud.files, isEmpty);

      await environment.dispose();
    },
  );
}
