part of 'receipt_service_test.dart';

void registerReceiptSemanticSearchTests() {
  test('ReceiptSemanticIndexer builds natural text for embedding', () {
    final indexer = ReceiptSemanticIndexer(
      embeddings: _RecordingEmbeddingService(),
    );
    final text = indexer.semanticText(
      Receipt(
        id: 1,
        type: ReceiptType.receipt,
        expense: true,
        fileName: 'receipt.txt',
        fileType: 'text/plain',
        extractedContent: 'OCR bruto do receipt',
        registeredAt: DateTime(2026, 4, 30),
        extractedData: ExtractedData(
          id: 1,
          receiptId: 1,
          amount: 70,
          transactionDate: DateTime(2026, 4, 12, 12, 16),
          establishment: 'POSTO MATARIPE',
          paymentMethod: 'Débito',
        ),
        category: const Category(
          id: 1,
          name: 'Combustível',
          description: 'Abastecimento e postos',
        ),
      ),
    );

    expect(text, contains('POSTO MATARIPE'));
    expect(text, contains('Combustível - Abastecimento e postos'));
    expect(text, contains('type Recibo'));
    expect(text, contains('despesa'));
    expect(text, contains('Débito'));
    expect(text, contains('amount 70,00'));
    expect(text, contains('data 12/04/2026'));
    expect(text, contains('OCR bruto do receipt'));
  });

  test(
    'ReceiptSemanticIndexer generates composite with context and payment',
    () async {
      final indexer = ReceiptSemanticIndexer(
        embeddings: _RecordingEmbeddingService(),
      );
      final embedding = await indexer.generateEmbedding(
        Receipt(
          id: 1,
          type: ReceiptType.pixReceipt,
          expense: false,
          fileName: 'pix.txt',
          fileType: 'text/plain',
          extractedContent: 'Transferência Pix recebida',
          registeredAt: DateTime(2026, 5, 1),
          extractedData: ExtractedData(
            id: 1,
            receiptId: 1,
            amount: 250,
            transactionDate: DateTime(2026, 5, 1),
            establishment: 'CLIENTE EXEMPLO',
            paymentMethod: 'Pix',
          ),
        ),
      );

      expect(embedding.model, contains('field-composite-v3'));
      expect(embedding.dimension, 16);

      final query = await indexer.generateQueryEmbedding('recebimento pix');
      expect(query.model, contains('field-composite-v3'));
      expect(query.dimension, 16);
    },
  );

  test('CompositeEmbeddingScore prioritizes relevant semantic field', () {
    const query = EmbeddingVector(
      vector: [1, 0, 1, 0, 1, 0, 1, 0],
      model: 'fake:field-composite',
      dimension: 8,
    );
    const persisted = EmbeddingVector(
      vector: [0, 1, 1, 0, 0, 1, 0, 1],
      model: 'fake:field-composite',
      dimension: 8,
    );

    final score = CompositeEmbeddingScore.calculate(
      query: query,
      persisted: persisted,
    );

    expect(score.usedFieldScore, isTrue);
    expect(score.fullCosineScore, closeTo(0.25, 0.0001));
    expect(score.categories, closeTo(1, 0.0001));
    expect(score.finalScore, greaterThan(0.80));
  });

  test('CompositeEmbeddingScore supports hybrid composite of two fields', () {
    const query = EmbeddingVector(
      vector: [1, 0, 1, 0],
      model: 'fake:field-composite-hybrid',
      dimension: 4,
    );
    const persisted = EmbeddingVector(
      vector: [0, 1, 1, 0],
      model: 'fake:field-composite-hybrid',
      dimension: 4,
    );

    final score = CompositeEmbeddingScore.calculate(
      query: query,
      persisted: persisted,
    );

    expect(score.usedFieldScore, isTrue);
    expect(score.establishment, closeTo(0, 0.0001));
    expect(score.categories, closeTo(1, 0.0001));
    expect(score.context, 0);
    expect(score.payment, 0);
    expect(score.finalScore, closeTo(0.90, 0.0001));
  });

  test('semantic search discards low and tangled results', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final repository = ReceiptRepository(database);

    await _saveWithControlledEmbedding(
      repository,
      fileId: 'baixo_1',
      embedding: _embeddingWithSemanticScore(0.34),
    );
    await _saveWithControlledEmbedding(
      repository,
      fileId: 'baixo_2',
      embedding: _embeddingWithSemanticScore(0.33),
    );
    await _saveWithControlledEmbedding(
      repository,
      fileId: 'baixo_3',
      embedding: _embeddingWithSemanticScore(0.32),
    );

    final results = await repository.findSimilar(
      _controlledSemanticQuery(),
      10,
    );

    expect(results, isEmpty);
  });

  test(
    'semantic search accepts low top score when separation is clear',
    () async {
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final repository = ReceiptRepository(database);

      await _saveWithControlledEmbedding(
        repository,
        fileId: 'highlighted',
        embedding: _embeddingWithSemanticScore(0.35),
      );
      await _saveWithControlledEmbedding(
        repository,
        fileId: 'distante',
        embedding: _embeddingWithSemanticScore(0.18),
      );

      final results = await repository.findSimilar(
        _controlledSemanticQuery(),
        10,
      );

      expect(results, hasLength(1));
      expect(results.single.fileName, 'highlighted.txt');
    },
  );

  test('semantic search does not depend on fixed canonical synonym', () async {
    final dependencies = _dependencies();

    await dependencies.receiptService.register(
      await _receiptFixture('avenue_gas_station.txt', '''
Receipt Pix
Posto Avenida Combustivel
Data 28/04/2026
Valor R\$ 84,90
Pagamento PIX
'''),
    );
    final results = await dependencies.receiptService.search('combustivel');

    expect(results, isNotEmpty);
    expect(results.first.extractedData?.establishment, contains('Posto'));

    dependencies.dispose();
  });

  test('semantic search beats weak literal only in raw OCR', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final receipts = ReceiptRepository(database);
    final embeddings = _TestEmbeddingService();
    final indexer = ReceiptSemanticIndexer(embeddings: embeddings);
    final service = ReceiptService(
      receipts: receipts,
      categories: CategoryRepository(database),
      images: _FakeImageService(),
      ocr: _FakeOcrService(),
      embeddings: embeddings,
      configuration: _FakeConfigurationService(),
      dataExtractor: DataExtractorService(),
      semanticIndexer: indexer,
    );
    final semanticamenteRelevante = Receipt(
      id: 0,
      type: ReceiptType.invoice,
      expense: true,
      fileName: 'health.txt',
      fileType: 'text/plain',
      extractedContent: 'Documento sem termo literal',
      registeredAt: DateTime(2026, 5, 8),
      extractedData: const ExtractedData(
        id: 0,
        receiptId: 0,
        establishment: 'Clinica Popular',
      ),
      category: const Category(
        id: 3,
        name: 'Saúde',
        description: 'Medicamentos e consultas',
      ),
    );
    await receipts.save(
      semanticamenteRelevante.copyWith(
        embedding: await indexer.generateEmbedding(semanticamenteRelevante),
      ),
    );
    await receipts.save(
      Receipt(
        id: 0,
        type: ReceiptType.receipt,
        expense: true,
        fileName: 'ocr_only.txt',
        fileType: 'text/plain',
        extractedContent: 'OCR bruto menciona Medicamentos sem context',
        registeredAt: DateTime(2026, 5, 9),
        extractedData: const ExtractedData(
          id: 0,
          receiptId: 0,
          establishment: 'Padaria Central',
        ),
      ),
    );

    final results = await service.search('Medicamentos');

    expect(results, hasLength(2));
    expect(results.first.category?.name, 'Saúde');
  });

  test('semantic search considers income context and payment', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final receipts = ReceiptRepository(database);
    final embeddings = _TestEmbeddingService();
    final indexer = ReceiptSemanticIndexer(embeddings: embeddings);
    final service = ReceiptService(
      receipts: receipts,
      categories: CategoryRepository(database),
      images: _FakeImageService(),
      ocr: _FakeOcrService(),
      embeddings: embeddings,
      configuration: _FakeConfigurationService(),
      dataExtractor: DataExtractorService(),
      semanticIndexer: indexer,
    );

    final pixIncome = Receipt(
      id: 0,
      type: ReceiptType.pixReceipt,
      expense: false,
      fileName: 'pix_income.txt',
      fileType: 'text/plain',
      extractedContent: 'Transferencia recebida de cliente',
      registeredAt: DateTime(2026, 5, 10),
      extractedData: const ExtractedData(
        id: 0,
        receiptId: 0,
        establishment: 'CLIENTE EXEMPLO',
        amount: 250,
        paymentMethod: 'Pix',
      ),
    );
    final cardExpense = Receipt(
      id: 0,
      type: ReceiptType.receipt,
      expense: true,
      fileName: 'card_expense.txt',
      fileType: 'text/plain',
      extractedContent: 'Compra comum',
      registeredAt: DateTime(2026, 5, 10),
      extractedData: const ExtractedData(
        id: 0,
        receiptId: 0,
        establishment: 'LOJA EXEMPLO',
        amount: 250,
        paymentMethod: 'Cartao de credito',
      ),
    );
    await receipts.save(
      pixIncome.copyWith(embedding: await indexer.generateEmbedding(pixIncome)),
    );
    await receipts.save(
      cardExpense.copyWith(
        embedding: await indexer.generateEmbedding(cardExpense),
      ),
    );

    final results = await service.search('recebimento pix');

    expect(results, isNotEmpty);
    expect(results.first.expense, isFalse);
    expect(results.first.extractedData?.paymentMethod, 'Pix');
  });

  test(
    'semantic search diagnostic reports comparisons and discarded receipts',
    () async {
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final receipts = ReceiptRepository(database);
      final reporter = _RecordingErrorReporter();
      final service = ReceiptService(
        receipts: receipts,
        categories: CategoryRepository(database),
        images: _FakeImageService(),
        ocr: _FakeOcrService(),
        embeddings: _DiagnosticEmbeddingService(),
        configuration: _FakeConfigurationService(),
        dataExtractor: DataExtractorService(),
        semanticIndexer: _DiagnosticSemanticIndexer(),
        embeddingDiagnostics: const _StaticEmbeddingDiagnostics(
          'model=diagnostico',
        ),
        errorReporter: reporter,
      );

      await receipts.save(
        Receipt(
          id: 0,
          type: ReceiptType.invoice,
          expense: true,
          fileName: 'without_embedding.txt',
          fileType: 'text/plain',
          extractedContent: 'Sem embedding',
          registeredAt: DateTime(2026, 5, 20),
        ),
      );
      await _saveWithControlledEmbedding(
        receipts,
        fileId: 'incompativel',
        embedding: Embedding(
          id: 0,
          receiptId: 0,
          vector: _serializeVector([1, 0]),
          model: 'fake:field-composite',
          dimension: 2,
          generatedAt: DateTime(2026, 5, 20),
        ),
      );
      await _saveWithControlledEmbedding(
        receipts,
        fileId: 'comparavel',
        embedding: Embedding(
          id: 0,
          receiptId: 0,
          vector: _serializeVector([1, 0, 1, 0]),
          model: 'fake:field-composite',
          dimension: 4,
          generatedAt: DateTime(2026, 5, 20),
        ),
      );

      final diagnostic = await service.diagnoseSemanticSearch(
        'saude',
        limit: 80,
      );

      expect(diagnostic, contains('Semantic search diagnostic'));
      expect(diagnostic, contains('query="saude"'));
      expect(diagnostic, contains('totalReceipts=3'));
      expect(diagnostic, contains('compared=1'));
      expect(diagnostic, contains('skippedWithoutEmbedding=1'));
      expect(diagnostic, contains('skippedIncompatible=1'));
      expect(
        diagnostic,
        contains('queryEmbeddingDiagnostic=model=diagnostico'),
      );
      expect(diagnostic, contains('currentTextScore='));
      expect(diagnostic, contains('fields='));
      expect(diagnostic, contains('probes:'));
      expect(reporter.diagnostics, contains(diagnostic));
    },
  );

  test('semantic search diagnostic requires filled query', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final service = ReceiptService(
      receipts: ReceiptRepository(database),
      categories: CategoryRepository(database),
      images: _FakeImageService(),
      ocr: _FakeOcrService(),
      embeddings: _TestEmbeddingService(),
      configuration: _FakeConfigurationService(),
      dataExtractor: DataExtractorService(),
    );

    await expectLater(
      service.diagnoseSemanticSearch('   '),
      throwsA(isA<FormatException>()),
    );
  });

  test('search does not wait for pending semantic reindex', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final receipts = ReceiptRepository(database);
    final indexer = _PendingReindexSemanticIndexer();
    final service = ReceiptService(
      receipts: receipts,
      categories: CategoryRepository(database),
      images: _FakeImageService(),
      ocr: _FakeOcrService(),
      embeddings: _TestEmbeddingService(),
      configuration: _FakeConfigurationService(),
      dataExtractor: DataExtractorService(),
      semanticIndexer: indexer,
    );
    await receipts.save(
      Receipt(
        id: 0,
        type: ReceiptType.receipt,
        expense: true,
        fileName: 'pending.txt',
        fileType: 'text/plain',
        extractedContent: 'Sem embedding ainda',
        registeredAt: DateTime(2026, 5, 9),
      ),
    );

    final results = await service
        .search('qualquer')
        .timeout(const Duration(milliseconds: 200));

    expect(results, isEmpty);
    expect(indexer.reindexacaoIniciada.isCompleted, isTrue);
  });
}
