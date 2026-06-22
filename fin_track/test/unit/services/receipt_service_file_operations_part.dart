part of 'receipt_service_test.dart';

void registerReceiptFileOperationsTests() {
  test('capture and batch import delegations use image service', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final captured = await _receiptFixture('direct_capture.txt', 'A');
    final multiple = [
      await _receiptFixture('direct_batch_1.txt', 'C'),
      await _receiptFixture('direct_batch_2.txt', 'D'),
    ];
    final images = _RecordingImageService(
      captured: captured,
      multiple: multiple,
    );
    final service = ReceiptService(
      receipts: ReceiptRepository(database),
      categories: CategoryRepository(database),
      images: images,
      ocr: _FakeOcrService(),
      embeddings: _TestEmbeddingService(),
      configuration: _FakeConfigurationService(),
      dataExtractor: DataExtractorService(),
    );

    expect(await service.captureImage(), captured);
    expect(await service.importFiles(), multiple);
  });

  test('batch space validation rejects individual and total limits', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final images = _RecordingImageService(usedSpaceBytes: 0);
    final service = ReceiptService(
      receipts: ReceiptRepository(database),
      categories: CategoryRepository(database),
      images: images,
      ocr: _FakeOcrService(),
      embeddings: _TestEmbeddingService(),
      configuration: _StorageLimitConfigurationService(limitMb: 1),
      dataExtractor: DataExtractorService(),
    );
    final largeFile = await _receiptFixture(
      'large_file.txt',
      'x' * (1024 * 1024 + 1),
    );

    await expectLater(
      service.validateSpaceForNewReceipts([largeFile]),
      throwsA(isA<StorageLimitException>()),
    );

    final fullStorageService = ReceiptService(
      receipts: ReceiptRepository(database),
      categories: CategoryRepository(database),
      images: _RecordingImageService(),
      ocr: _FakeOcrService(),
      embeddings: _TestEmbeddingService(),
      configuration: _StorageLimitConfigurationService(
        limitMb: 1,
        usedSpaceBytes: 1024 * 1024 - 10,
      ),
      dataExtractor: DataExtractorService(),
    );
    final smallFile = await _receiptFixture('small_file.txt', '123456');

    await expectLater(
      fullStorageService.validateSpaceForNewReceipts([smallFile, smallFile]),
      throwsA(isA<StorageLimitException>()),
    );
  });

  test('processPreview accepts files directly', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final imported = await _receiptFixture(
      'import_preview.txt',
      'Mercado Azul\nValor R\$ 12,00',
    );
    final images = _RecordingImageService();
    final service = ReceiptService(
      receipts: ReceiptRepository(database),
      categories: CategoryRepository(database),
      images: images,
      ocr: const _StaticOcrService(
        text: 'Mercado Azul\nValor R\$ 12,00\nData 23/05/2026',
        confidence: 0.9,
      ),
      embeddings: _TestEmbeddingService(),
      configuration: _FakeConfigurationService(),
      dataExtractor: DataExtractorService(),
    );

    final importedPreview = await service.processPreview(imported);

    expect(importedPreview.id, 0);
  });

  test('utility operations delegate to repository and image service', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final receipts = ReceiptRepository(database);
    final images = _RecordingImageService();
    final service = ReceiptService(
      receipts: receipts,
      categories: CategoryRepository(database),
      images: images,
      ocr: _FakeOcrService(),
      embeddings: _TestEmbeddingService(),
      configuration: _FakeConfigurationService(),
      dataExtractor: DataExtractorService(),
    );
    final saved = await receipts.save(
      Receipt(
        id: 0,
        type: ReceiptType.receipt,
        expense: true,
        fileName: 'utility.txt',
        fileType: 'text/plain',
        extractedContent: 'Utilitario',
        registeredAt: DateTime(2026, 5, 20),
      ),
    );

    expect(service.watchAll(), isA<Stream<List<Receipt>>>());
    expect(
      service.watchByFilters(const ReceiptFilter()),
      isA<Stream<List<Receipt>>>(),
    );
    expect(await service.search('   '), hasLength(1));
    expect((await service.exportFile(saved.id)).path, 'utility.txt');

    await service.shareImage(saved.id);
    await service.shareImages(const []);
    await service.saveImageToDevice(saved.id);
    await service.saveImagesToDevice(const []);
    final removed = await service.deleteOrphanFiles();

    expect(images.sharedFiles, ['utility.txt:text/plain']);
    expect(images.savedToDevice, ['utility.txt:text/plain']);
    expect(images.receivedReferences, {'utility.txt'});
    expect(removed, 123);
  });

  test('preview and local file handle temporary and managed files', () async {
    final dir = await Directory.systemTemp.createTemp('fin_track_local_');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });
    final file = File('${dir.path}/preview.txt')..writeAsStringSync('abc');
    final rebuilt = File('${dir.path}/rebuilt.txt')..writeAsStringSync('def');
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final images = _RecordingImageService(rebuiltPath: rebuilt.path);
    final service = ReceiptService(
      receipts: ReceiptRepository(database),
      categories: CategoryRepository(database),
      images: images,
      ocr: _FakeOcrService(),
      embeddings: _TestEmbeddingService(),
      configuration: _FakeConfigurationService(),
      dataExtractor: DataExtractorService(),
    );

    expect(
      (await service.localFile(
        Receipt(
          id: 0,
          type: ReceiptType.receipt,
          expense: true,
          fileName: file.path,
          fileType: 'text/plain',
          registeredAt: DateTime(2026, 5, 20),
        ),
      )).path,
      file.path,
    );
    expect(
      (await service.localFile(
        Receipt(
          id: 5,
          type: ReceiptType.receipt,
          expense: true,
          fileName: 'managed.txt',
          fileType: 'text/plain',
          registeredAt: DateTime(2026, 5, 20),
        ),
      )).path,
      rebuilt.path,
    );

    await service.discardPreview(
      Receipt(
        id: 0,
        type: ReceiptType.receipt,
        expense: true,
        fileName: 'preview.txt',
        fileType: 'text/plain',
        registeredAt: DateTime(2026, 5, 20),
      ),
    );
    await service.discardPreview(
      Receipt(
        id: 9,
        type: ReceiptType.receipt,
        expense: true,
        fileName: 'persisted.txt',
        fileType: 'text/plain',
        registeredAt: DateTime(2026, 5, 20),
      ),
    );

    expect(images.deletedIfManaged, ['preview.txt']);
  });
}
