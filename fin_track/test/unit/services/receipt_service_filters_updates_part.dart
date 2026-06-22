part of 'receipt_service_test.dart';

void registerReceiptFiltersUpdatesTests() {
  test('update receipt marks backup as pending', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final receipts = ReceiptRepository(database);
    final embeddings = _TestEmbeddingService();
    final service = ReceiptService(
      receipts: receipts,
      categories: CategoryRepository(database),
      images: _FakeImageService(),
      ocr: _FakeOcrService(),
      embeddings: embeddings,
      configuration: _FakeConfigurationService(),
      dataExtractor: DataExtractorService(),
    );
    final saved = await receipts.save(
      Receipt(
        id: 0,
        type: ReceiptType.invoice,
        expense: true,
        fileName: 'market_backup.txt',
        fileType: 'text/plain',
        extractedContent: 'Mercado Central',
        cloudSynced: true,
        registeredAt: DateTime(2026, 5, 13),
        extractedData: const ExtractedData(
          id: 0,
          receiptId: 0,
          establishment: 'Mercado Central',
          amount: 25,
        ),
      ),
    );

    await service.update(saved.copyWith(extractedContent: 'Mercado editado'));
    final updated = await receipts.findById(saved.id);

    expect(updated.cloudSynced, isFalse);
  });

  test(
    'keeps saved structured data and removes old embedding if regeneration fails',
    () async {
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final receipts = ReceiptRepository(database);
      final service = ReceiptService(
        receipts: receipts,
        categories: CategoryRepository(database),
        images: _FakeImageService(),
        ocr: _FakeOcrService(),
        embeddings: _FailingEmbeddingService(),
        configuration: _FakeConfigurationService(),
        dataExtractor: DataExtractorService(),
      );

      final saved = await receipts.save(
        Receipt(
          id: 0,
          type: ReceiptType.receipt,
          expense: true,
          fileName: 'embedding_failure.txt',
          fileType: 'text/plain',
          extractedContent: 'Texto antigo',
          registeredAt: DateTime(2026, 4, 30),
        ),
      );
      await receipts.saveEmbedding(
        Embedding(
          id: 0,
          receiptId: saved.id,
          vector: Uint8List(16),
          model: 'test',
          dimension: 2,
          generatedAt: DateTime(2026, 4, 30),
        ),
      );

      await service.update(
        saved.copyWith(
          extractedData: const ExtractedData(
            id: 0,
            receiptId: 0,
            establishment: 'Texto estruturado corrigido',
          ),
        ),
      );
      final updated = await receipts.findById(saved.id);

      expect(updated.extractedContent, 'Texto antigo');
      expect(
        updated.extractedData?.establishment,
        'Texto estruturado corrigido',
      );
      expect(updated.embedding, isNull);
    },
  );

  test('saveConfirmed updates existing receipt', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final receipts = ReceiptRepository(database);
    final service = ReceiptService(
      receipts: receipts,
      categories: CategoryRepository(database),
      images: _FakeImageService(),
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
        fileName: 'existing.txt',
        fileType: 'text/plain',
        extractedContent: 'Antigo',
        cloudSynced: true,
        registeredAt: DateTime(2026, 5, 20),
      ),
    );

    final updated = await service.saveConfirmed(
      saved.copyWith(
        extractedContent: 'Novo',
        extractedData: const ExtractedData(
          id: 0,
          receiptId: 0,
          establishment: '  Mercado Atualizado  ',
        ),
      ),
    );

    expect(updated.id, saved.id);
    expect(updated.extractedContent, 'Novo');
    expect(updated.cloudSynced, isFalse);
    expect(updated.extractedData?.establishment, 'Mercado Atualizado');
    expect(updated.embedding, isNotNull);
  });

  test(
    'search prioritizes extracted data and uses raw OCR as secondary',
    () async {
      final dependencies = _dependencies();

      await dependencies.receiptService.saveConfirmed(
        Receipt(
          id: 0,
          type: ReceiptType.invoice,
          expense: true,
          fileName: (await _receiptFixture(
            'ignored_raw_ocr.txt',
            'Fantasma OCR bruto que nao deve entrar na search',
          )).path,
          fileType: 'text/plain',
          extractedContent: 'Fantasma OCR bruto que nao deve entrar na search',
          registeredAt: DateTime(2026, 5, 6),
          extractedData: ExtractedData(
            id: 0,
            receiptId: 0,
            amount: 25,
            transactionDate: DateTime(2026, 5, 6),
            establishment: 'Mercado Estruturado',
            paymentMethod: 'Pix',
          ),
        ),
      );
      await dependencies.receiptService.saveConfirmed(
        Receipt(
          id: 0,
          type: ReceiptType.receipt,
          expense: true,
          fileName: (await _receiptFixture(
            'priority_structured_data.txt',
            'Receipt sem o termo fantasma no OCR',
          )).path,
          fileType: 'text/plain',
          extractedContent: 'Receipt sem o termo pesquisado no OCR',
          registeredAt: DateTime(2026, 5, 7),
          extractedData: ExtractedData(
            id: 0,
            receiptId: 0,
            amount: 30,
            transactionDate: DateTime(2026, 5, 7),
            establishment: 'Fantasma Estruturado',
            paymentMethod: 'Pix',
          ),
        ),
      );

      final results = await dependencies.receiptService.search('Fantasma');

      expect(results, hasLength(2));
      expect(
        results.first.extractedData?.establishment,
        'Fantasma Estruturado',
      );
      final marketResults = await dependencies.receiptService.search(
        'Mercado Estruturado',
      );
      expect(
        marketResults.first.extractedData?.establishment,
        'Mercado Estruturado',
      );

      dependencies.dispose();
    },
  );

  test(
    'period filter uses extracted date instead of registration date',
    () async {
      final dependencies = _dependencies();

      await dependencies.receiptService.saveConfirmed(
        Receipt(
          id: 0,
          type: ReceiptType.receipt,
          expense: true,
          fileName: (await _receiptFixture(
            'extracted_data_period.txt',
            'Compra registrada em maio com transacao de abril',
          )).path,
          fileType: 'text/plain',
          extractedContent: 'Compra registrada em maio com transacao de abril',
          registeredAt: DateTime(2026, 5, 6),
          extractedData: ExtractedData(
            id: 0,
            receiptId: 0,
            amount: 80,
            transactionDate: DateTime(2026, 4),
            establishment: 'Loja Abril',
          ),
        ),
      );

      final maio = await dependencies.receiptService.findByFilters(
        ReceiptFilter(
          startDate: DateTime(2026, 5),
          endDate: DateTime(2026, 5, 31, 23, 59, 59),
        ),
      );
      final abril = await dependencies.receiptService.findByFilters(
        ReceiptFilter(
          startDate: DateTime(2026, 4),
          endDate: DateTime(2026, 4, 30, 23, 59, 59),
        ),
      );

      expect(maio, isEmpty);
      expect(abril, hasLength(1));

      dependencies.dispose();
    },
  );

  test(
    'amount sortOrder treats income as positive and expenses as negative',
    () async {
      final dependencies = _dependencies();

      final income = await dependencies.receiptService.saveConfirmed(
        Receipt(
          id: 0,
          type: ReceiptType.receipt,
          expense: false,
          fileName: (await _receiptFixture(
            'income_amount.txt',
            'Recebimento R\$ 50,00',
          )).path,
          fileType: 'text/plain',
          extractedContent: 'Recebimento R\$ 50,00',
          registeredAt: DateTime(2026, 5, 6),
          extractedData: ExtractedData(
            id: 0,
            receiptId: 0,
            amount: 50,
            transactionDate: DateTime(2026, 5, 6),
            establishment: 'Cliente A',
          ),
        ),
      );
      final lowerExpense = await dependencies.receiptService.saveConfirmed(
        Receipt(
          id: 0,
          type: ReceiptType.invoice,
          expense: true,
          fileName: (await _receiptFixture(
            'lower_expense_amount.txt',
            'Compra R\$ 20,00',
          )).path,
          fileType: 'text/plain',
          extractedContent: 'Compra R\$ 20,00',
          registeredAt: DateTime(2026, 5, 6),
          extractedData: ExtractedData(
            id: 0,
            receiptId: 0,
            amount: 20,
            transactionDate: DateTime(2026, 5, 6),
            establishment: 'Mercado B',
          ),
        ),
      );
      final higherExpense = await dependencies.receiptService.saveConfirmed(
        Receipt(
          id: 0,
          type: ReceiptType.invoice,
          expense: true,
          fileName: (await _receiptFixture(
            'higher_expense_amount.txt',
            'Compra R\$ 100,00',
          )).path,
          fileType: 'text/plain',
          extractedContent: 'Compra R\$ 100,00',
          registeredAt: DateTime(2026, 5, 6),
          extractedData: ExtractedData(
            id: 0,
            receiptId: 0,
            amount: 100,
            transactionDate: DateTime(2026, 5, 6),
            establishment: 'Fornecedor C',
          ),
        ),
      );

      final results = await dependencies.receiptService.findByFilters(
        const ReceiptFilter(sortOrder: ReceiptSort.amount),
      );
      final ascendingResults = await dependencies.receiptService.findByFilters(
        const ReceiptFilter(
          sortOrder: ReceiptSort.amount,
          sortDirection: SortDirection.ascending,
        ),
      );

      expect(results.map((receipt) => receipt.id), [
        income.id,
        lowerExpense.id,
        higherExpense.id,
      ]);
      expect(ascendingResults.map((receipt) => receipt.id), [
        higherExpense.id,
        lowerExpense.id,
        income.id,
      ]);

      dependencies.dispose();
    },
  );

  test(
    'date filled after OCR without date persists and enters report filter',
    () async {
      final dependencies = _dependencies();

      final saved = await dependencies.receiptService.saveConfirmed(
        Receipt(
          id: 0,
          type: ReceiptType.receipt,
          expense: true,
          fileName: (await _receiptFixture(
            'ocr_without_date_fixed.txt',
            'Recibo sem data no OCR',
          )).path,
          fileType: 'text/plain',
          extractedContent: 'Recibo sem data no OCR',
          registeredAt: DateTime(2026, 4, 20),
          extractedData: const ExtractedData(
            id: 0,
            receiptId: 0,
            amount: 75,
            establishment: 'Prestador sem data',
          ),
        ),
      );

      await dependencies.receiptService.update(
        saved.copyWith(
          extractedData: ExtractedData(
            id: saved.extractedData?.id ?? 0,
            receiptId: saved.id,
            amount: 75,
            transactionDate: DateTime(2026, 5, 6),
            establishment: 'Prestador sem data',
          ),
        ),
      );

      final updated = await dependencies.receiptService.findById(saved.id);
      final filtrados = await dependencies.receiptService.findByFilters(
        ReceiptFilter(
          startDate: DateTime(2026, 5),
          endDate: DateTime(2026, 5, 31, 23, 59, 59),
        ),
      );

      expect(updated.extractedData?.transactionDate, DateTime(2026, 5, 6));
      expect(filtrados.map((receipt) => receipt.id), contains(saved.id));

      dependencies.dispose();
    },
  );

  test('update amount reindexes semantic embedding', () async {
    final embeddings = _CountingEmbeddingService();
    final dependencies = FinTrackDependencies.local(embeddings: embeddings);

    final receipt = await dependencies.receiptService.register(
      await _receiptFixture('amount_without_reindex.txt', '''
Mercado Central
Nota fiscal eletronica
Total R\$ 128,45
Itens: arroz e cafe
'''),
    );
    final receiptWithEmbedding = await _fetchAfterBackgroundEmbeddings(
      dependencies,
      receipt.id,
    );
    final previousEmbedding = List<int>.from(
      receiptWithEmbedding.embedding!.vector,
    );
    final callsBefore = embeddings.totalCalls;

    await dependencies.receiptService.update(
      receiptWithEmbedding.copyWith(
        extractedData: receiptWithEmbedding.extractedData?.copyWith(
          amount: 98.76,
        ),
      ),
    );
    final updated = await dependencies.receiptService.findById(receipt.id);

    expect(updated.extractedData?.amount, 98.76);
    expect(List<int>.from(updated.embedding!.vector), isNot(previousEmbedding));
    expect(embeddings.totalCalls, greaterThan(callsBefore));

    dependencies.dispose();
  });

  test('preview processing respects local storage limit', () async {
    final dependencies = _dependencies();
    final configuration = await dependencies.configurationService.load();
    await dependencies.configurationService.update(
      configuration.copyWith(storageLimitMB: 1),
    );

    final file = await _receiptFixture(
      'storage_limit.txt',
      List.filled(1 * 1024 * 1024 + 1, 'a').join(),
    );
    await expectLater(
      dependencies.receiptService.processPreview(file),
      throwsA(isA<FormatException>()),
    );
    expect(
      await dependencies.receiptService.findByFilters(const ReceiptFilter()),
      isEmpty,
    );

    dependencies.dispose();
  });
}
