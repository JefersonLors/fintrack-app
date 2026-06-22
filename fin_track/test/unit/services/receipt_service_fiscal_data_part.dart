part of 'receipt_service_test.dart';

void registerReceiptFiscalDataTests() {
  test('saves and retrieves structured fiscal data', () async {
    final dependencies = _dependencies();

    final saved = await dependencies.receiptService.saveConfirmed(
      Receipt(
        id: 0,
        type: ReceiptType.invoice,
        expense: true,
        fileName: (await _receiptFixture(
          'fiscal_data.txt',
          'Nota fiscal com data fiscais persistidos',
        )).path,
        fileType: 'text/plain',
        extractedContent: 'Nota fiscal com data fiscais persistidos',
        registeredAt: DateTime(2026, 5, 9),
        extractedData: const ExtractedData(
          id: 0,
          receiptId: 0,
          establishment: 'Mercado Central',
          issuerCnpj: '12345678000190',
          accessKey: '29260412345678000190650010000012341000056789',
          urlQrCode: 'https://nfce.sefaz.ba.gov.br/qrcode?p=abc',
          documentNumber: '1234',
          documentSeries: '1',
          documentState: 'BA',
        ),
      ),
    );

    expect(saved.extractedData?.issuerCnpj, '12345678000190');
    expect(
      saved.extractedData?.accessKey,
      '29260412345678000190650010000012341000056789',
    );
    expect(saved.extractedData?.urlQrCode, contains('sefaz.ba.gov.br'));
    expect(saved.extractedData?.documentNumber, '1234');
    expect(saved.extractedData?.documentSeries, '1');
    expect(saved.extractedData?.documentState, 'BA');

    dependencies.dispose();
  });

  test('enriches fiscal establishment through local CNPJ cache', () async {
    final dependencies = FinTrackDependencies.local(
      embeddings: _TestEmbeddingService(),
      cnpjLookup: const _FakeLocalCnpjLookupService(),
    );

    final receipt = await dependencies.receiptService.register(
      await _receiptFixture('cnpj_enriquecido.txt', '''
Nome borrado do OCR
Nota fiscal eletronica
CNPJ 55.986.560/0001-59
Data 28/04/2026
Valor total R\$ 128,45
'''),
    );

    expect(receipt.extractedData?.establishment, 'Mercado Fonte API');
    expect(receipt.extractedData?.issuerCnpj, '55986560000159');
    expect(receipt.extractedData?.issuerLegalName, 'MERCADO CENTRAL LTDA');
    expect(receipt.extractedData?.issuerTradeName, 'Mercado Fonte API');
    expect(
      receipt.extractedData?.fiscalCnaeDescription,
      'Comercio varejista de mercadorias em geral',
    );
    expect(receipt.extractedData?.issuerCity, 'SALVADOR');
    expect(receipt.extractedData?.issuerState, 'BA');
    expect(receipt.extractedData?.establishmentConfidence, 0.95);

    dependencies.dispose();
  });

  test('cnpj_cache applies company data immediately in preview', () async {
    final database = AppDatabase.memory();
    final dependencies = FinTrackDependencies.local(
      database: database,
      embeddings: _TestEmbeddingService(),
      cnpjLookup: CachedCnpjLookupService(
        database: database,
        remote: const _NeverCnpjLookupService(),
      ),
    );
    await database
        .into(database.cnpjCache)
        .insertOnConflictUpdate(
          CnpjCacheCompanion.insert(
            cnpj: '55986560000159',
            legalName: const Value('MERCADO CENTRAL LTDA'),
            tradeName: const Value('Mercado Cache Local'),
            confirmedName: const Value('Mercado Confirmado Local'),
            fiscalCnaeDescription: const Value(
              'Comercio varejista de mercadorias em geral',
            ),
            city: const Value('SALVADOR'),
            state: const Value('BA'),
            updatedAt: DateTime(2026, 5, 10),
          ),
        );

    final preview = await dependencies.receiptService.processPreview(
      await _receiptFixture('cnpj_cache_preview.txt', '''
Nome borrado do OCR
Nota fiscal eletronica
CNPJ 55.986.560/0001-59
Data 28/04/2026
Valor total R\$ 128,45
'''),
    );

    expect(preview.extractedData?.establishment, 'Mercado Confirmado Local');
    expect(preview.extractedData?.issuerLegalName, 'MERCADO CENTRAL LTDA');
    expect(preview.extractedData?.issuerTradeName, 'Mercado Cache Local');
    expect(
      preview.extractedData?.fiscalCnaeDescription,
      'Comercio varejista de mercadorias em geral',
    );
    expect(preview.extractedData?.issuerCity, 'SALVADOR');
    expect(preview.extractedData?.issuerState, 'BA');

    dependencies.dispose();
  });

  test('cnpj_cache suggests preferred category immediately', () async {
    final database = AppDatabase.memory();
    final dependencies = FinTrackDependencies.local(
      database: database,
      embeddings: _TestEmbeddingService(),
      cnpjLookup: CachedCnpjLookupService(
        database: database,
        remote: const _NeverCnpjLookupService(),
      ),
    );
    final transport = (await dependencies.categoryService.list()).firstWhere(
      (category) => category.name == 'Transporte',
    );
    await database
        .into(database.cnpjCache)
        .insertOnConflictUpdate(
          CnpjCacheCompanion.insert(
            cnpj: '55986560000159',
            preferredCategoryId: Value(transport.id),
            updatedAt: DateTime(2026, 5, 10),
          ),
        );

    final preview = await dependencies.receiptService.processPreview(
      await _receiptFixture('cnpj_cache_category.txt', '''
Documento Auxiliar da Nota Fiscal de Consumidor Eletronica
Nome ruidoso
CNPJ 55.986.560/0001-59
Produto diverso
Valor total R\$ 34,90
Emissao: 10/05/2026 12:30:00
'''),
    );

    expect(preview.category?.name, 'Transporte');

    dependencies.dispose();
  });

  test(
    'confirmed save learns confirmed name and category by existing CNPJ',
    () async {
      final database = AppDatabase.memory();
      final dependencies = FinTrackDependencies.local(
        database: database,
        embeddings: _TestEmbeddingService(),
        cnpjLookup: CachedCnpjLookupService(
          database: database,
          remote: const _NeverCnpjLookupService(),
        ),
      );
      final category = (await dependencies.categoryService.list()).firstWhere(
        (category) => category.name == 'Alimentação',
      );
      await database
          .into(database.cnpjCache)
          .insertOnConflictUpdate(
            CnpjCacheCompanion.insert(
              cnpj: '55986560000159',
              legalName: const Value('MERCADO CENTRAL LTDA'),
              tradeName: const Value('Mercado Oficial'),
              updatedAt: DateTime(2026, 5, 10),
            ),
          );

      await dependencies.receiptService.saveConfirmed(
        Receipt(
          id: 0,
          type: ReceiptType.invoice,
          expense: true,
          fileName: (await _receiptFixture(
            'cnpj_existing_confirmed_name.txt',
            'name confirmado existing',
          )).path,
          fileType: 'text/plain',
          extractedContent: 'name confirmado existing',
          registeredAt: DateTime(2026, 5, 10),
          extractedData: ExtractedData(
            id: 0,
            receiptId: 0,
            issuerCnpj: '55.986.560/0001-59',
            establishment: 'Mercado Corrigido Pelo Usuario',
          ),
          category: category,
        ),
      );

      final row = await (database.select(
        database.cnpjCache,
      )..where((tbl) => tbl.cnpj.equals('55986560000159'))).getSingle();

      expect(row.legalName, 'MERCADO CENTRAL LTDA');
      expect(row.tradeName, 'Mercado Oficial');
      expect(row.confirmedName, 'Mercado Corrigido Pelo Usuario');
      expect(row.preferredCategoryId, category.id);

      dependencies.dispose();
    },
  );

  test('confirmed save creates CNPJ cache with confirmed name', () async {
    final database = AppDatabase.memory();
    final dependencies = FinTrackDependencies.local(
      database: database,
      embeddings: _TestEmbeddingService(),
      cnpjLookup: CachedCnpjLookupService(
        database: database,
        remote: const _NeverCnpjLookupService(),
      ),
    );
    final category = (await dependencies.categoryService.list()).firstWhere(
      (category) => category.name == 'Transporte',
    );

    await dependencies.receiptService.saveConfirmed(
      Receipt(
        id: 0,
        type: ReceiptType.receipt,
        expense: true,
        fileName: (await _receiptFixture(
          'cnpj_new_confirmed_name.txt',
          'name confirmado novo',
        )).path,
        fileType: 'text/plain',
        extractedContent: 'name confirmado novo',
        registeredAt: DateTime(2026, 5, 10),
        extractedData: ExtractedData(
          id: 0,
          receiptId: 0,
          issuerCnpj: '55.986.560/0001-59',
          establishment: 'Transporte Confirmado Usuario',
        ),
        category: category,
      ),
    );

    final row = await (database.select(
      database.cnpjCache,
    )..where((tbl) => tbl.cnpj.equals('55986560000159'))).getSingle();

    expect(row.confirmedName, 'Transporte Confirmado Usuario');
    expect(row.preferredCategoryId, category.id);
    expect(row.legalName, isNull);
    expect(row.tradeName, isNull);

    dependencies.dispose();
  });

  test('update learns confirmed name by CNPJ in saved receipt', () async {
    final database = AppDatabase.memory();
    final dependencies = FinTrackDependencies.local(
      database: database,
      embeddings: _TestEmbeddingService(),
      cnpjLookup: CachedCnpjLookupService(
        database: database,
        remote: const _NeverCnpjLookupService(),
      ),
    );
    final category = (await dependencies.categoryService.list()).firstWhere(
      (category) => category.name == 'Alimentação',
    );
    final saved = await dependencies.receiptService.saveConfirmed(
      Receipt(
        id: 0,
        type: ReceiptType.invoice,
        expense: true,
        fileName: (await _receiptFixture(
          'cnpj_edit_confirmed_name.txt',
          'name confirmado edicao',
        )).path,
        fileType: 'text/plain',
        extractedContent: 'name confirmado edicao',
        registeredAt: DateTime(2026, 5, 10),
        extractedData: const ExtractedData(
          id: 0,
          receiptId: 0,
          issuerCnpj: '55.986.560/0001-59',
          establishment: 'Nome Antes Da Edicao',
        ),
        category: category,
      ),
    );

    await dependencies.receiptService.update(
      saved.copyWith(
        extractedData: saved.extractedData?.copyWith(
          establishment: 'Nome Corrigido Na Edicao',
        ),
      ),
    );

    final row = await (database.select(
      database.cnpjCache,
    )..where((tbl) => tbl.cnpj.equals('55986560000159'))).getSingle();

    expect(row.confirmedName, 'Nome Corrigido Na Edicao');
    expect(row.preferredCategoryId, category.id);

    dependencies.dispose();
  });

  test('remote fiscal lookup does not block preview by QR code URL', () async {
    final dependencies = FinTrackDependencies.local(
      embeddings: _TestEmbeddingService(),
      visualCode: const _FakeVisualCodeService([
        'https://nfce.sefaz.ba.gov.br/consulta?p=29260556062868000170650000001859490166640140',
      ]),
      cnpjLookup: const _NoopCnpjLookupService(),
      fiscalDocumentLookup: const _FakeFiscalDocumentLookupService(),
    );

    final receipt = await dependencies.receiptService.register(
      await _receiptFixture('fiscal_qr_lookup.txt', '''
Documento Auxiliar da Nota Fiscal de Consumidor Eletronica
Sacola Dom João VI Ltda
CNPJ 56.062.868/0001-70
VALOR TOTAL R\$ 9,86
08/05/2026 19:48
'''),
    );

    final extractedData = receipt.extractedData;
    expect(extractedData?.amount, 9.86);
    expect(extractedData?.transactionDate, DateTime(2026, 5, 8, 19, 48));
    expect(extractedData?.establishment, contains('Sacola Dom'));
    expect(extractedData?.issuerCnpj, '56062868000170');
    expect(
      extractedData?.accessKey,
      '29260556062868000170650000001859490166640140',
    );
    expect(extractedData?.documentNumber, '185949');
    expect(extractedData?.documentSeries, '0');
    expect(extractedData?.documentState, 'BA');
    expect(extractedData?.items, isEmpty);

    dependencies.dispose();
  });
}
