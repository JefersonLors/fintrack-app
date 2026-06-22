part of 'receipt_service_test.dart';

void registerReceiptCategorySuggestionTests() {
  test('uses local item memory as weak boost after repetition', () async {
    final dependencies = _dependencies();
    final health = (await dependencies.categoryService.list()).firstWhere(
      (category) => category.name == 'Saúde',
    );

    for (final establishment in ['Loja Um', 'Loja Dois']) {
      await dependencies.receiptService.saveConfirmed(
        Receipt(
          id: 0,
          type: ReceiptType.invoice,
          expense: true,
          fileName: (await _receiptFixture(
            'item_memory_$establishment.txt',
            establishment,
          )).path,
          fileType: 'text/plain',
          extractedContent: establishment,
          registeredAt: DateTime(2026, 5, 10),
          extractedData: ExtractedData(
            id: 0,
            receiptId: 0,
            establishment: establishment,
            items: const ['Curativo Premium'],
          ),
          category: health,
        ),
      );
    }

    final newReceipt = await dependencies.receiptService.register(
      await _receiptFixture('new_item_memory.txt', '''
Loja Tres
Nota fiscal
Itens: Curativo Premium
Valor total R\$ 19,90
Emissao: 10/05/2026 12:30:00
'''),
    );

    expect(newReceipt.category?.name, 'Saúde');

    dependencies.dispose();
  });

  test(
    'without-category filter returns only receipts without category',
    () async {
      final dependencies = _dependencies();
      final category = await dependencies.categoryService.create('Mercado');

      await dependencies.receiptService.saveConfirmed(
        Receipt(
          id: 0,
          type: ReceiptType.invoice,
          expense: true,
          fileName: (await _receiptFixture(
            'with_category.txt',
            'Compra categorizada',
          )).path,
          fileType: 'text/plain',
          extractedContent: 'Compra categorizada',
          registeredAt: DateTime(2026, 5, 7),
          extractedData: ExtractedData(
            id: 0,
            receiptId: 0,
            amount: 40,
            transactionDate: DateTime(2026, 5, 7),
            establishment: 'Mercado com categoria',
          ),
          category: category,
        ),
      );
      await dependencies.receiptService.saveConfirmed(
        Receipt(
          id: 0,
          type: ReceiptType.receipt,
          expense: true,
          fileName: (await _receiptFixture(
            'without_category.txt',
            'Compra sem categoria',
          )).path,
          fileType: 'text/plain',
          extractedContent: 'Compra sem categoria',
          registeredAt: DateTime(2026, 5, 8),
          extractedData: ExtractedData(
            id: 0,
            receiptId: 0,
            amount: 15,
            transactionDate: DateTime(2026, 5, 8),
            establishment: 'Compra avulsa',
          ),
        ),
      );

      final withoutCategory = await dependencies.receiptService.findByFilters(
        const ReceiptFilter(withoutCategory: true),
      );
      final categorized = await dependencies.receiptService.findByFilters(
        ReceiptFilter(categoryId: category.id),
      );

      expect(withoutCategory, hasLength(1));
      expect(withoutCategory.single.category, isNull);
      expect(categorized, hasLength(1));
      expect(categorized.single.category?.id, category.id);

      dependencies.dispose();
    },
  );

  test('processPreview does not use file name as establishment', () async {
    final dir = await Directory.systemTemp.createTemp('fin_track_preview_');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });
    final file = File('${dir.path}/76236319817490_289731728.jpg')
      ..writeAsBytesSync(<int>[1, 2, 3, 4]);
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final service = ReceiptService(
      receipts: ReceiptRepository(database),
      categories: CategoryRepository(database),
      images: ImageService(baseDirectory: Directory('${dir.path}/imgs')),
      ocr: const _StaticOcrService(
        text: '76236319817490_289731728.jpg',
        confidence: 0.30,
      ),
      embeddings: _TestEmbeddingService(),
      configuration: _FakeConfigurationService(),
      dataExtractor: DataExtractorService(),
    );

    final preview = await service.processPreview(file);

    expect(preview.extractedData?.establishment, isEmpty);
    expect(preview.extractedData?.establishmentConfidence, isNull);
  });

  test(
    'processPreview does not create category when none are registered',
    () async {
      final dir = await Directory.systemTemp.createTemp('fin_track_preview_');
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });
      final file = File('${dir.path}/without_category.jpg')
        ..writeAsBytesSync(<int>[1, 2, 3, 4]);
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final categories = CategoryRepository(database);
      for (final category in await categories.list()) {
        await categories.delete(category.id);
      }
      final service = ReceiptService(
        receipts: ReceiptRepository(database),
        categories: categories,
        images: ImageService(baseDirectory: Directory('${dir.path}/imgs')),
        ocr: const _StaticOcrService(
          text: '''
Mercado Central
Total R\$ 30,00
Data 12/05/2026
''',
          confidence: 0.85,
        ),
        embeddings: _TestEmbeddingService(),
        configuration: _FakeConfigurationService(),
        dataExtractor: DataExtractorService(),
      );

      final preview = await service.processPreview(file);

      expect(preview.category, isNull);
      expect(await categories.list(), isEmpty);
    },
  );

  test('caches category embeddings and refreshes on category update', () async {
    final embeddings = _CountingEmbeddingService();
    final dependencies = FinTrackDependencies.local(embeddings: embeddings);

    await dependencies.receiptService.register(
      await _receiptFixture('category_cache_1.txt', '''
Mercado Central
Nota fiscal
Total R\$ 10,00
'''),
    );
    await dependencies.receiptService.register(
      await _receiptFixture('category_cache_2.txt', '''
Farmacia Popular
Nota fiscal
Total R\$ 20,00
'''),
    );

    expect(embeddings.calls['Saúde Medicamentos e consultas'], 1);

    final health = (await dependencies.categoryService.list()).firstWhere(
      (category) => category.name == 'Saúde',
    );
    await dependencies.categoryService.update(
      health.copyWith(description: 'Farmácias, medicamentos e consultas'),
    );
    await dependencies.receiptService.register(
      await _receiptFixture('category_cache_3.txt', '''
Farmacia Nova
Cupom fiscal
Total R\$ 30,00
'''),
    );

    expect(embeddings.calls['Saúde Medicamentos e consultas'], 1);
    expect(embeddings.calls['Saúde Farmácias, medicamentos e consultas'], 1);

    dependencies.dispose();
  });
}
