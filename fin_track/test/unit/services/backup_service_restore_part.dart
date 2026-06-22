part of 'backup_service_test.dart';

void registerBackupRestoreTests() {
  test(
    'restores valid backup by repopulating database and private file',
    () async {
      final source = await _createEnvironment();
      await _saveReceipt(source.receipts, source.images);
      await source.configurationService.linkGoogle();
      await source.backupService.exportBackup(password: 'password-segura-123');

      final target = await _createEnvironment(cloud: source.cloud);
      await target.configurationService.linkGoogle();
      final record = await target.backupService.restoreBackup(
        password: 'password-segura-123',
      );
      final restoredReceipts = await target.receipts.findByFilters(
        const ReceiptFilter(),
      );
      final restoredFile = File(
        target.images.rebuildPath(restoredReceipts.single.fileName),
      );

      expect(record.status, BackupStatus.synced);
      expect(record.operation, BackupOperation.restore);
      expect(restoredReceipts, hasLength(1));
      expect(
        restoredReceipts.single.extractedContent,
        contains('Mercado Central'),
      );
      expect(restoredReceipts.single.expense, isTrue);
      expect(restoredReceipts.single.embedding, isNotNull);
      expect(await restoredFile.readAsString(), 'comprovante em texto claro');

      await source.dispose();
      await target.dispose();
    },
  );

  test('restore with wrong password records friendly failure', () async {
    final source = await _createEnvironment();
    await _saveReceipt(source.receipts, source.images);
    await source.configurationService.linkGoogle();
    await source.backupService.exportBackup(password: 'password-segura-123');

    final target = await _createEnvironment(cloud: source.cloud);
    await target.configurationService.linkGoogle();
    final record = await target.backupService.restoreBackup(
      password: 'password-incorreta-456',
    );

    expect(record.status, BackupStatus.failure);
    expect(record.operation, BackupOperation.restore);
    expect(record.errorDescription, 'Senha incorreta ou backup corrompido.');

    await source.dispose();
    await target.dispose();
  });

  test('restore without available backup records friendly failure', () async {
    final environment = await _createEnvironment();
    await environment.configurationService.linkGoogle();

    final record = await environment.backupService.restoreBackup(
      password: 'password-segura-123',
    );
    final history = await environment.backups.list();

    expect(record.status, BackupStatus.failure);
    expect(record.operation, BackupOperation.restore);
    expect(
      record.errorDescription,
      'Nenhum backup disponível para restauração.',
    );
    expect(history.single.id, record.id);

    await environment.dispose();
  });

  test(
    'backup with receipt missing corresponding file does not change local state',
    () async {
      final target = await _createEnvironment();
      await _saveReceipt(
        target.receipts,
        target.images,
        fileText: 'estado antigo intacto',
        extractedContent: 'Estado antigo',
      );
      await target.configurationService.linkGoogle();
      target.cloud.files.add(
        await _encryptedBackup(
          password: 'password-segura-123',
          payload: {
            'version': 2,
            'configuration': <String, Object?>{},
            'files': const <Object?>[],
            'receipts': [
              {
                'type': ReceiptType.invoice.persistedValue,
                'expense': true,
                'fileName': 'missing.txt',
                'fileType': 'text/plain',
                'extractedContent': 'Novo backup',
                'registeredAt': DateTime(2026, 5, 1).toIso8601String(),
                'category': null,
              },
            ],
          },
        ),
      );

      final record = await target.backupService.restoreBackup(
        password: 'password-segura-123',
      );
      final preservedReceipts = await target.receipts.findByFilters(
        const ReceiptFilter(),
      );
      final preservedFile = File(
        target.images.rebuildPath(preservedReceipts.single.fileName),
      );

      expect(record.status, BackupStatus.failure);
      expect(record.operation, BackupOperation.restore);
      expect(preservedReceipts.single.extractedContent, 'Estado antigo');
      expect(await preservedFile.readAsString(), 'estado antigo intacto');

      await target.dispose();
    },
  );

  test(
    'restore discards temporary files and records rollback failures',
    () async {
      final database = AppDatabase.memory();
      final images = _FailingTemporaryRestoreImageService();
      final receipts = ReceiptRepository(database);
      final configurations = ConfigurationRepository(database);
      final reporter = _RecordingErrorReporter();
      final restore = BackupRestoreService(
        payload: BackupPayloadService(
          images: images,
          cryptography: AES256Service(iterations: 1000),
        ),
        images: images,
        receipts: receipts,
        configurations: configurations,
        errorReporter: reporter,
      );
      final backup = await _encryptedBackup(
        password: 'password-segura-123',
        payload: {
          'version': 2,
          'configuration': <String, Object?>{},
          'files': [
            {
              'fileName': 'receipt.txt',
              'fileType': 'text/plain',
              'bytesBase64': base64Encode(utf8.encode('arquivo')),
            },
          ],
          'receipts': [
            {
              'type': ReceiptType.receipt.persistedValue,
              'expense': true,
              'fileName': 'receipt.txt',
              'fileType': 'text/plain',
              'registeredAt': DateTime(2026, 5, 1).toIso8601String(),
              'category': null,
            },
          ],
        },
      );

      await expectLater(
        restore.restore(
          files: [backup],
          password: 'password-segura-123',
          configuration: const Configuration(id: 1),
        ),
        throwsA(isA<StateError>()),
      );

      expect(images.createdTemporaryRestore, isTrue);
      expect(images.discardAttempts, 1);
      expect(reporter.errors.single, isA<StateError>());

      await database.close();
    },
  );
}
