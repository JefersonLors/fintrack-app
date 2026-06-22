part of 'backup_service_test.dart';

void registerBackupCryptoConfigTests() {
  test('AES256Service uses v2 authenticated envelope with password', () async {
    final service = AES256Service(iterations: 1000);
    final payload = Uint8List.fromList(utf8.encode('Mercado Central R\$ 128'));

    final encrypted = await service.encrypt(payload, 'password-segura-123');
    final encryptedText = utf8.decode(encrypted);
    final opened = await service.decrypt(encrypted, 'password-segura-123');

    expect(encryptedText, contains('"magic":"FTBACKUP"'));
    expect(encryptedText, contains('"version":2'));
    expect(encryptedText, contains('aes-gcm-256'));
    expect(encryptedText, isNot(contains('Mercado Central')));
    expect(utf8.decode(opened), 'Mercado Central R\$ 128');
  });

  test('AES256Service fails with wrong password or changed content', () async {
    final service = AES256Service(iterations: 1000);
    final encrypted = await service.encrypt(
      Uint8List.fromList(utf8.encode('payload protegido')),
      'password-segura-123',
    );
    final changed = Uint8List.fromList(encrypted);
    changed[changed.length - 8] ^= 0x01;

    await expectLater(
      service.decrypt(encrypted, 'password-errada-456'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Senha incorreta ou backup corrompido.',
        ),
      ),
    );
    await expectLater(
      service.decrypt(changed, 'password-segura-123'),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'AES256Service generates different files for the same payload',
    () async {
      final service = AES256Service(iterations: 1000);
      final payload = Uint8List.fromList(utf8.encode('mesmo backup'));

      final first = await service.encrypt(payload, 'password-segura-123');
      final second = await service.encrypt(payload, 'password-segura-123');

      expect(first, isNot(equals(second)));
    },
  );

  test('successful link persists Google account', () async {
    final environment = await _createEnvironment();

    await environment.configurationService.linkGoogle();
    final configuration = await environment.configurations.load();

    expect(configuration.linkedCloudAccount, 'usuario@fintrack.test');
    expect(configuration.cloudTokenValid, isTrue);
    expect(configuration.cloudLinkedAt, isNotNull);

    await environment.dispose();
  });

  test('link cancellation does not persist invalid state', () async {
    final environment = await _createEnvironment();
    environment.cloud.cancelLink = true;

    await expectLater(
      environment.configurationService.linkGoogle(),
      throwsStateError,
    );
    final configuration = await environment.configurations.load();

    expect(configuration.linkedCloudAccount, isNull);
    expect(configuration.cloudTokenValid, isFalse);

    await environment.dispose();
  });

  test('database failure reverts restored files', () async {
    final source = await _createEnvironment();
    await _saveReceipt(
      source.receipts,
      source.images,
      fileText: 'file vindo do backup',
      extractedContent: 'New backup',
    );
    await source.configurationService.linkGoogle();
    await source.backupService.exportBackup(password: 'password-segura-123');

    final database = AppDatabase.memory();
    final images = ImageService(
      baseDirectory: Directory(
        '${Directory.systemTemp.path}/fin_track_backup_rollback_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    final receipts = ReceiptRepository(database);
    await _saveReceipt(
      receipts,
      images,
      fileText: 'file antigo',
      extractedContent: 'Banco antigo',
    );
    final configurations = ConfigurationRepository(database);
    final backups = BackupRepository(database);
    final configurationService = ConfigurationService(
      configurations: configurations,
      cloud: source.cloud,
      images: images,
    );
    await configurationService.linkGoogle();
    final backupService = BackupService(
      receipts: _FailingReplaceReceiptRepository(receipts),
      backups: backups,
      configurations: configurations,
      cryptography: AES256Service(iterations: 1000),
      cloud: source.cloud,
      images: images,
    );

    final record = await backupService.restoreBackup(
      password: 'password-segura-123',
    );
    final preservedReceipts = await receipts.findByFilters(
      const ReceiptFilter(),
    );
    final preservedFile = File(
      images.rebuildPath(preservedReceipts.single.fileName),
    );

    expect(record.status, BackupStatus.failure);
    expect(record.operation, BackupOperation.restore);
    expect(preservedReceipts.single.extractedContent, 'Banco antigo');
    expect(await preservedFile.readAsString(), 'file antigo');

    await source.dispose();
    await database.close();
  });

  test(
    'clearing history does not remove automatic backup technical state',
    () async {
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
        intervalDays: 1,
      );

      final record = await environment.backupService.exportBackup(
        password: 'password-segura-123',
      );
      await environment.backupService.clearHistory();

      final configuration = await environment.configurations.load();
      expect(await environment.backups.list(), isEmpty);
      expect(configuration.lastSyncedExportAt, record.createdAt);
      expect(configuration.backupAvailability, BackupAvailability.active);
      expect(
        await environment.backupService.runAutomaticBackupIfNeeded(
          now: record.createdAt.add(const Duration(hours: 12)),
        ),
        isNull,
      );

      await environment.dispose();
    },
  );

  testWidgets('backup and restore buttons stay blocked without link', (
    tester,
  ) async {
    final dependencies = FinTrackDependencies.local();

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: const MaterialApp(home: BackupPage()),
      ),
    );
    await tester.pumpAndSettle();

    final backup = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Backup'),
    );
    final restoreButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Restaurar'),
    );
    expect(find.text('Não vinculado'), findsOneWidget);
    expect(
      find.text('Toque para vincular uma conta de armazenamento em nuvem.'),
      findsOneWidget,
    );
    expect(backup.onPressed, isNull);
    expect(restoreButton.onPressed, isNull);

    await tester.tap(find.text('Não vinculado'));
    await tester.pumpAndSettle();
    expect(find.text('Escolha o serviço de nuvem'), findsOneWidget);

    dependencies.dispose();
  });

  testWidgets('clear cloud data button removes linked backup', (tester) async {
    final cloud = _FakeCloudStorage()
      ..files.add(
        await _encryptedBackup(
          password: 'password-segura-123',
          payload: <String, Object?>{'backup': 'valido'},
        ),
      );
    final dependencies = FinTrackDependencies.local(cloud: cloud);

    await dependencies.configurationService.linkGoogle();
    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: const MaterialApp(home: BackupPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpar nuvem'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Limpar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).last,
      'password-segura-123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Limpar'));
    await tester.pumpAndSettle();

    expect(cloud.files, isEmpty);
    expect(find.text('Dados da nuvem removidos.'), findsOneWidget);

    dependencies.dispose();
  });
}
