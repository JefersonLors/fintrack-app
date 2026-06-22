part of 'receipt_service_test.dart';

void registerReceiptCnpjCategoryLearningTests() {
  test(
    'local fiscal cache enriches preview by QR key without remote lookup',
    () async {
      final database = AppDatabase.memory();
      final fiscalCache = CachedFiscalDocumentService(database: database);
      final dependencies = FinTrackDependencies.local(
        database: database,
        embeddings: _TestEmbeddingService(),
        visualCode: const _FakeVisualCodeService([
          'https://nfce.sefaz.ba.gov.br/servicos/nfce/qrcode.aspx?p=29260556062868000170650000001859490166640140|2|1|1',
        ]),
        cnpjLookup: const _NoopCnpjLookupService(),
        fiscalDocumentLookup: const _NeverFiscalDocumentLookupService(),
      );
      await fiscalCache.save(
        ExtractedData(
          id: 0,
          receiptId: 0,
          accessKey: '29260556062868000170650000001859490166640140',
          urlQrCode:
              'https://nfce.sefaz.ba.gov.br/servicos/nfce/qrcode.aspx?p=29260556062868000170650000001859490166640140|2|1|1',
          issuerCnpj: '56062868000170',
          establishment: 'Sacolao Cache Fiscal',
          amount: 9.86,
          transactionDate: DateTime(2026, 5, 8, 19, 48),
        ),
      );

      final preview = await dependencies.receiptService.processPreview(
        await _receiptFixture('local_fiscal_cache_lookup.txt', '''
Documento Auxiliar da Nota Fiscal de Consumidor Eletronica
Texto incompleto do OCR
'''),
      );
      final extractedData = preview.extractedData;

      expect(
        extractedData?.accessKey,
        '29260556062868000170650000001859490166640140',
      );
      expect(extractedData?.issuerCnpj, '56062868000170');
      expect(extractedData?.establishment, 'Sacolao Cache Fiscal');
      expect(extractedData?.amount, 9.86);
      expect(extractedData?.transactionDate, DateTime(2026, 5, 8, 19, 48));

      dependencies.dispose();
    },
  );

  test('confirmed save persists compact QR data in fiscal cache', () async {
    final database = AppDatabase.memory();
    final fiscalCache = CachedFiscalDocumentService(database: database);
    final dependencies = FinTrackDependencies.local(
      database: database,
      embeddings: _TestEmbeddingService(),
      cnpjLookup: const _NoopCnpjLookupService(),
    );

    await dependencies.receiptService.saveConfirmed(
      Receipt(
        id: 0,
        type: ReceiptType.invoice,
        expense: true,
        fileName: (await _receiptFixture(
          'persisted_fiscal_cache.txt',
          'Cache fiscal persisted',
        )).path,
        fileType: 'text/plain',
        extractedContent: 'Cache fiscal persisted',
        registeredAt: DateTime(2026, 5, 9),
        extractedData: ExtractedData(
          id: 0,
          receiptId: 0,
          accessKey: '29260556062868000170650000001859490166640140',
          urlQrCode:
              'https://nfce.sefaz.ba.gov.br/servicos/nfce/qrcode.aspx?p=29260556062868000170650000001859490166640140|2|1|1',
          issuerCnpj: '56062868000170',
          establishment: 'Sacolao Dom Joao',
          amount: 9.86,
          transactionDate: DateTime(2026, 5, 8, 19, 48),
        ),
      ),
    );

    final fiscal = await fiscalCache.find(
      accessKey: '29260556062868000170650000001859490166640140',
    );

    expect(fiscal?.lookupUrl, contains('qrcode.aspx'));
    expect(fiscal?.issuerCnpj, '56062868000170');
    expect(fiscal?.establishment, 'Sacolao Dom Joao');
    expect(fiscal?.amount, 9.86);
    expect(fiscal?.issuedAt, DateTime(2026, 5, 8, 19, 48));

    dependencies.dispose();
  });

  test('learns category confirmed by CNPJ', () async {
    final dependencies = _dependencies();
    final transport = (await dependencies.categoryService.list()).firstWhere(
      (category) => category.name == 'Transporte',
    );

    await dependencies.receiptService.saveConfirmed(
      Receipt(
        id: 0,
        type: ReceiptType.invoice,
        expense: true,
        fileName: (await _receiptFixture(
          'base_cnpj_preference.txt',
          'Preferencia por CNPJ',
        )).path,
        fileType: 'text/plain',
        extractedContent: 'Preferencia por CNPJ',
        registeredAt: DateTime(2026, 5, 10),
        extractedData: const ExtractedData(
          id: 0,
          receiptId: 0,
          establishment: 'Posto de Teste',
          issuerCnpj: '55986560000159',
        ),
        category: transport,
      ),
    );

    final newReceipt = await dependencies.receiptService.register(
      await _receiptFixture('new_cnpj_preference.txt', '''
Documento Auxiliar da Nota Fiscal de Consumidor Eletronica
Nome ruidoso
CNPJ 55.986.560/0001-59
Produto diverso
Valor total R\$ 34,90
Emissao: 10/05/2026 12:30:00
'''),
    );

    expect(newReceipt.category?.name, 'Transporte');

    dependencies.dispose();
  });

  test('does not write establishment cache when CNPJ exists', () async {
    final database = AppDatabase.memory();
    final dependencies = FinTrackDependencies.local(
      database: database,
      embeddings: _TestEmbeddingService(),
      cnpjLookup: const _NoopCnpjLookupService(),
    );
    final transport = (await dependencies.categoryService.list()).firstWhere(
      (category) => category.name == 'Transporte',
    );

    await dependencies.receiptService.saveConfirmed(
      Receipt(
        id: 0,
        type: ReceiptType.invoice,
        expense: true,
        fileName: (await _receiptFixture(
          'cnpj_preference_without_establishment.txt',
          'Preferencia por CNPJ sem fallback establishment',
        )).path,
        fileType: 'text/plain',
        extractedContent: 'Preferencia por CNPJ sem fallback establishment',
        registeredAt: DateTime(2026, 5, 10),
        extractedData: const ExtractedData(
          id: 0,
          receiptId: 0,
          establishment: 'Loja Com Cnpj',
          issuerCnpj: '55986560000159',
        ),
        category: transport,
      ),
    );

    final rows = await database
        .select(database.establishmentCategoryCache)
        .get();
    expect(rows, isEmpty);

    dependencies.dispose();
  });

  test('does not write establishment cache with bad name', () async {
    final database = AppDatabase.memory();
    final dependencies = FinTrackDependencies.local(
      database: database,
      embeddings: _TestEmbeddingService(),
      cnpjLookup: const _NoopCnpjLookupService(),
    );
    final health = (await dependencies.categoryService.list()).firstWhere(
      (category) => category.name == 'Saúde',
    );

    await dependencies.receiptService.saveConfirmed(
      Receipt(
        id: 0,
        type: ReceiptType.receipt,
        expense: true,
        fileName: (await _receiptFixture(
          'bad_establishment_preference.txt',
          'Preferencia por establishment ruim',
        )).path,
        fileType: 'text/plain',
        extractedContent: 'Preferencia por establishment ruim',
        registeredAt: DateTime(2026, 5, 10),
        extractedData: const ExtractedData(
          id: 0,
          receiptId: 0,
          establishment: 'Receipt',
        ),
        category: health,
      ),
    );

    final rows = await database
        .select(database.establishmentCategoryCache)
        .get();
    expect(rows, isEmpty);

    dependencies.dispose();
  });

  test('learns category confirmed by establishment without CNPJ', () async {
    final dependencies = _dependencies();
    final health = (await dependencies.categoryService.list()).firstWhere(
      (category) => category.name == 'Saúde',
    );

    await dependencies.receiptService.saveConfirmed(
      Receipt(
        id: 0,
        type: ReceiptType.receipt,
        expense: true,
        fileName: (await _receiptFixture(
          'base_establishment_preference.txt',
          'Preferencia por establishment',
        )).path,
        fileType: 'text/plain',
        extractedContent: 'Preferencia por establishment',
        registeredAt: DateTime(2026, 5, 10),
        extractedData: const ExtractedData(
          id: 0,
          receiptId: 0,
          establishment: 'Clinica Sao Bento',
        ),
        category: health,
      ),
    );

    final newReceipt = await dependencies.receiptService.register(
      await _receiptFixture('new_establishment_preference.txt', '''
Receipt
CLINICA SÃO BENTO
Produto diverso
Valor R\$ 88,00
Data 10/05/2026
'''),
    );

    expect(newReceipt.category?.name, 'Saúde');

    dependencies.dispose();
  });

  test('uses CNAE as strong signal to suggest category', () async {
    final dependencies = FinTrackDependencies.local(
      embeddings: _TestEmbeddingService(),
      cnpjLookup: const _FakeHealthCnaeLookupService(),
    );

    final receipt = await dependencies.receiptService.register(
      await _receiptFixture('category_by_cnae.txt', '''
Mercado Popular
Documento Auxiliar da Nota Fiscal de Consumidor Eletronica
CNPJ 55.986.560/0001-59
Produto diverso
Valor total R\$ 42,00
Emissao: 10/05/2026 12:30:00
'''),
    );

    expect(receipt.extractedData?.fiscalCnaeDescription, contains('Saúde'));
    expect(receipt.category?.name, 'Saúde');

    dependencies.dispose();
  });

  test('processPreview does not wait for remote lookups', () async {
    final dependencies = FinTrackDependencies.local(
      embeddings: _TestEmbeddingService(),
      cnpjLookup: const _NeverCnpjLookupService(),
      fiscalDocumentLookup: const _NeverFiscalDocumentLookupService(),
      visualCode: const _FakeVisualCodeService([
        'https://nfce.sefaz.ba.gov.br/consulta?p=29260556062868000170650000001859490166640140',
      ]),
    );
    final file = await _receiptFixture('offline_first.txt', '''
Documento Auxiliar da Nota Fiscal de Consumidor Eletronica
Sacola Dom João VI Ltda
CNPJ 56.062.868/0001-70
VALOR TOTAL R\$ 9,86
08/05/2026 19:48
''');

    final preview = await dependencies.receiptService
        .processPreview(file)
        .timeout(const Duration(seconds: 5));

    expect(preview.extractedData?.amount, 9.86);
    expect(preview.extractedData?.issuerCnpj, '56062868000170');

    dependencies.dispose();
  });
}
