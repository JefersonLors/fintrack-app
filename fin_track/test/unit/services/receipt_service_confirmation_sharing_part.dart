part of 'receipt_service_test.dart';

void registerReceiptConfirmationSharingTests() {
  test(
    'localFile uses reconstructed path for preview without direct file',
    () async {
      final dir = await Directory.systemTemp.createTemp('fin_track_local_');
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });
      final rebuilt = File('${dir.path}/rebuilt.txt')..writeAsStringSync('def');
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final service = ReceiptService(
        receipts: ReceiptRepository(database),
        categories: CategoryRepository(database),
        images: _RecordingImageService(rebuiltPath: rebuilt.path),
        ocr: _FakeOcrService(),
        embeddings: _TestEmbeddingService(),
        configuration: _FakeConfigurationService(),
        dataExtractor: DataExtractorService(),
      );

      final file = await service.localFile(
        Receipt(
          id: 0,
          type: ReceiptType.receipt,
          expense: true,
          fileName: 'missing_preview.txt',
          fileType: 'text/plain',
          registeredAt: DateTime(2026, 5, 20),
        ),
      );

      expect(file.path, rebuilt.path);
    },
  );

  test(
    'processes preview without creating record before confirmation',
    () async {
      final dependencies = _dependencies();

      final preview = await dependencies.receiptService.processPreview(
        await _receiptFixture('preview_market.txt', '''
Mercado Central
Nota fiscal eletronica
Data 28/04/2026
Pagamento cartao de credito
Total R\$ 128,45
'''),
      );

      expect(preview.id, 0);
      expect(preview.expense, isTrue);
      expect(preview.embedding, isNull);
      expect(
        await dependencies.receiptService.findByFilters(const ReceiptFilter()),
        isEmpty,
      );

      final saved = await dependencies.receiptService.saveConfirmed(preview);

      expect(saved.id, greaterThan(0));
      expect(
        await dependencies.receiptService.findByFilters(const ReceiptFilter()),
        hasLength(1),
      );

      dependencies.dispose();
    },
  );

  test('delete removes record and local file', () async {
    final dependencies = _dependencies();

    final receipt = await dependencies.receiptService.register(
      await _receiptFixture('delete_market.txt', '''
Mercado Central
Nota fiscal eletronica
Data 28/04/2026
Pagamento cartao de credito
Total R\$ 128,45
'''),
    );
    final file = await dependencies.receiptService.exportFile(receipt.id);

    expect(await file.exists(), isTrue);

    await dependencies.receiptService.delete(receipt.id);

    expect(await file.exists(), isFalse);
    await expectLater(
      dependencies.receiptService.findById(receipt.id),
      throwsStateError,
    );

    dependencies.dispose();
  });

  test('shareImages sends multiple files to platform', () async {
    const channel = MethodChannel('fin_track/native');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'shareFiles';
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final dependencies = _dependencies();
    final first = await dependencies.receiptService.register(
      await _receiptFixture('share_market.txt', 'Mercado\nTotal 10,00'),
    );
    final second = await dependencies.receiptService.register(
      await _receiptFixture('share_pharmacy.txt', 'Farmacia\nTotal 20,00'),
    );

    await dependencies.receiptService.shareImages([first.id, second.id]);

    final call = calls.singleWhere((call) => call.method == 'shareFiles');
    final arguments = Map<Object?, Object?>.from(
      call.arguments as Map<Object?, Object?>,
    );
    final paths = List<Object?>.from(arguments['paths']! as List<Object?>);
    expect(paths, hasLength(2));
    expect(paths.first.toString(), contains('share_market.txt'));
    expect(paths.last.toString(), contains('share_pharmacy.txt'));

    dependencies.dispose();
  });

  test('saveImagesToDevice sends multiple files to platform', () async {
    const channel = MethodChannel('fin_track/native');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'saveFilesToDevice';
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final dependencies = _dependencies();
    final first = await dependencies.receiptService.register(
      await _receiptFixture('save_market.txt', 'Mercado\nTotal 10,00'),
    );
    final second = await dependencies.receiptService.register(
      await _receiptFixture('save_pharmacy.txt', 'Farmacia\nTotal 20,00'),
    );

    await dependencies.receiptService.saveImagesToDevice([first.id, second.id]);

    final call = calls.singleWhere(
      (call) => call.method == 'saveFilesToDevice',
    );
    final arguments = Map<Object?, Object?>.from(
      call.arguments as Map<Object?, Object?>,
    );
    final paths = List<Object?>.from(arguments['paths']! as List<Object?>);
    expect(paths, hasLength(2));
    expect(paths.first.toString(), contains('save_market.txt'));
    expect(paths.last.toString(), contains('save_pharmacy.txt'));

    dependencies.dispose();
  });
}
