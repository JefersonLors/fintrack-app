part of 'receipt_service_test.dart';

void registerReceiptPipelineProcessingTests() {
  test(
    'registers receipt with extracted data and schedules embedding',
    () async {
      final dependencies = _dependencies();

      final receipt = await dependencies.receiptService.register(
        await _receiptFixture('central_market.txt', '''
Mercado Central
Nota fiscal eletronica
CNPJ 55.986.560/0001-59
Data 28/04/2026
Pagamento cartao de credito
Total R\$ 128,45
Itens: arroz, cafe, frutas
'''),
      );

      expect(receipt.id, greaterThan(0));
      expect(receipt.expense, isTrue);
      expect(receipt.extractedData?.amount, 128.45);
      expect(receipt.extractedData?.establishment, 'Mercado Central');
      expect(receipt.extractedData?.items, containsAll(['arroz', 'cafe']));
      expect(receipt.extractedData?.issuerCnpj, '55986560000159');
      expect(receipt.embedding, isNull);
      final withEmbedding = await _fetchAfterBackgroundEmbeddings(
        dependencies,
        receipt.id,
      );
      expect(
        withEmbedding.embedding?.dimension,
        _TestEmbeddingService.dimension * 4,
      );
      expect(receipt.category?.name, 'Alimentação');

      dependencies.dispose();
    },
  );

  test('updates structured data and replaces semantic embedding', () async {
    final dependencies = _dependencies();

    final receipt = await dependencies.receiptService.register(
      await _receiptFixture('ocr_editavel.txt', '''
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

    await dependencies.receiptService.update(
      receiptWithEmbedding.copyWith(
        extractedData: receiptWithEmbedding.extractedData?.copyWith(
          establishment: 'Farmacia Nova',
          amount: 36.90,
          paymentMethod: 'PIX',
        ),
      ),
    );
    final updated = await dependencies.receiptService.findById(receipt.id);

    expect(updated.extractedContent, contains('Mercado Central'));
    expect(updated.extractedData?.establishment, 'Farmacia Nova');
    expect(updated.embedding, isNotNull);
    expect(List<int>.from(updated.embedding!.vector), isNot(previousEmbedding));

    final search = await dependencies.receiptService.search('farmacia');
    expect(search.first.id, receipt.id);

    dependencies.dispose();
  });

  test('scanDocument delegates to injected scanner', () async {
    final file = await _receiptFixture('scanner_fake.txt', 'OCR fake');
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final service = ReceiptService(
      receipts: ReceiptRepository(database),
      categories: CategoryRepository(database),
      images: _FakeImageService(),
      scanner: _FakeScannerService(file),
      ocr: _FakeOcrService(),
      embeddings: _TestEmbeddingService(),
      configuration: _FakeConfigurationService(),
      dataExtractor: DataExtractorService(),
    );

    expect(await service.scanDocument(), file);
  });

  test(
    'processPreview uses preprocessed image in OCR and preserves original file',
    () async {
      final dir = await Directory.systemTemp.createTemp('fin_track_preview_');
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });
      final original = File('${dir.path}/original.jpg')
        ..writeAsBytesSync(<int>[10, 20, 30, 40]);
      final preprocessed = File('${dir.path}/preprocessado.jpg')
        ..writeAsBytesSync(<int>[50, 60, 70, 80]);
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final ocr = _RecordingOcrService();
      final preprocessor = _RecordingImagePreprocessor(preprocessed);
      final service = ReceiptService(
        receipts: ReceiptRepository(database),
        categories: CategoryRepository(database),
        images: ImageService(baseDirectory: Directory('${dir.path}/imgs')),
        imagePreprocessor: preprocessor,
        ocr: ocr,
        embeddings: _TestEmbeddingService(),
        configuration: _FakeConfigurationService(),
        dataExtractor: DataExtractorService(),
      );

      final preview = await service.processPreview(original);

      expect(preprocessor.received?.path, original.path);
      expect(ocr.received?.path, preprocessed.path);
      expect(preview.fileName, original.path);
      expect(preview.fileSize, original.lengthSync());
      expect(
        preview.extractedData?.qualityMetadata?['varianteEscolhida'],
        'original',
      );
      expect(
        preview.extractedData?.qualityMetadata?['variantesTestadas'],
        contains('preprocessada'),
      );
      expect(preview.extractedData?.qualityMetadata?['sharpness'], 0.7);
      expect(
        preview.extractedData?.qualityMetadata?['ocrEstruturadoLinhas'],
        contains(contains('Mercado Central')),
      );
      expect(
        preview.extractedData?.qualityMetadata?['ocrEstruturadoResumo'],
        containsPair('linhas', 3),
      );
      expect(
        preview.fileHash,
        sha256.convert(original.readAsBytesSync()).toString(),
      );
      expect(await preprocessed.exists(), isFalse);
    },
  );

  test(
    'processPreview skips OCR variants when original OCR is already strong',
    () async {
      final dir = await Directory.systemTemp.createTemp('fin_track_preview_');
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });
      final original = File('${dir.path}/original.jpg')
        ..writeAsBytesSync(<int>[10, 20, 30, 40]);
      final preprocessed = File('${dir.path}/preprocessado.jpg')
        ..writeAsBytesSync(<int>[50, 60, 70, 80]);
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final ocr = _StrongRecordingOcrService();
      final preprocessor = _RecordingImagePreprocessor(preprocessed);
      final service = ReceiptService(
        receipts: ReceiptRepository(database),
        categories: CategoryRepository(database),
        images: ImageService(baseDirectory: Directory('${dir.path}/imgs')),
        imagePreprocessor: preprocessor,
        ocr: ocr,
        embeddings: _TestEmbeddingService(),
        configuration: _FakeConfigurationService(),
        dataExtractor: DataExtractorService(),
      );

      final preview = await service.processPreview(original);

      expect(preprocessor.received, isNull);
      expect(ocr.receivedPaths, [original.path]);
      expect(await preprocessed.exists(), isTrue);
      expect(preview.fileName, original.path);
      expect(
        preview.extractedData?.qualityMetadata?['varianteEscolhida'],
        'original',
      );
      expect(preview.extractedData?.qualityMetadata?['variantesTestadas'], [
        'original',
      ]);
    },
  );

  test(
    'processPreview uses original when preprocessor generates no variants',
    () async {
      final dir = await Directory.systemTemp.createTemp('fin_track_preview_');
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });
      final original = File('${dir.path}/original.txt')
        ..writeAsStringSync('Mercado\nR\$ 10,00');
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final ocr = _RecordingOcrService();
      final service = ReceiptService(
        receipts: ReceiptRepository(database),
        categories: CategoryRepository(database),
        images: ImageService(baseDirectory: Directory('${dir.path}/imgs')),
        imagePreprocessor: _EmptyVariantsPreprocessor(),
        ocr: ocr,
        embeddings: _TestEmbeddingService(),
        configuration: _FakeConfigurationService(),
        dataExtractor: DataExtractorService(),
      );

      final preview = await service.processPreview(original);

      expect(ocr.received?.path, original.path);
      expect(
        preview.extractedData?.qualityMetadata?['varianteEscolhida'],
        'original',
      );
    },
  );

  test(
    'processPreview uses preprocess fallback when variant generation fails',
    () async {
      final dir = await Directory.systemTemp.createTemp('fin_track_preview_');
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });
      final original = File('${dir.path}/original.txt')
        ..writeAsStringSync('Mercado\nR\$ 10,00');
      final preprocessed = File('${dir.path}/fallback.txt')
        ..writeAsStringSync('Mercado melhorado\nR\$ 10,00');
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final ocr = _RecordingOcrService();
      final service = ReceiptService(
        receipts: ReceiptRepository(database),
        categories: CategoryRepository(database),
        images: ImageService(baseDirectory: Directory('${dir.path}/imgs')),
        imagePreprocessor: _ThrowingVariantsPreprocessor(preprocessed),
        ocr: ocr,
        embeddings: _TestEmbeddingService(),
        configuration: _FakeConfigurationService(),
        dataExtractor: DataExtractorService(),
      );

      final preview = await service.processPreview(original);

      expect(
        preview.extractedData?.qualityMetadata?['variantesTestadas'],
        contains('preprocessada'),
      );
    },
  );

  test(
    'processPreview ignores preprocessor when fallback also fails',
    () async {
      final dir = await Directory.systemTemp.createTemp('fin_track_preview_');
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });
      final original = File('${dir.path}/original.txt')
        ..writeAsStringSync('Mercado\nR\$ 10,00');
      final database = AppDatabase.memory();
      addTearDown(database.close);
      final ocr = _RecordingOcrService();
      final service = ReceiptService(
        receipts: ReceiptRepository(database),
        categories: CategoryRepository(database),
        images: ImageService(baseDirectory: Directory('${dir.path}/imgs')),
        imagePreprocessor: _FailingPreprocessor(),
        ocr: ocr,
        embeddings: _TestEmbeddingService(),
        configuration: _FakeConfigurationService(),
        dataExtractor: DataExtractorService(),
      );

      final preview = await service.processPreview(original);

      expect(ocr.received?.path, original.path);
      expect(
        preview.extractedData?.qualityMetadata?['varianteEscolhida'],
        'original',
      );
    },
  );

  test(
    'visual code reader limits concurrent work and keeps unique codes',
    () async {
      final dir = await Directory.systemTemp.createTemp('fin_track_codes_');
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });
      final files = [
        File('${dir.path}/a.txt')..writeAsStringSync('a'),
        File('${dir.path}/b.txt')..writeAsStringSync('b'),
        File('${dir.path}/c.txt')..writeAsStringSync('c'),
      ];
      final visualCode = _SlowVisualCodeService();
      final processing = ReceiptProcessingService(
        visualCode: visualCode,
        ocr: _FakeOcrService(),
      );

      final codes = await processing.readVisualCodes(files);

      expect(codes.toSet(), {
        'shared',
        'code-a.txt',
        'code-b.txt',
        'code-c.txt',
      });
      expect(visualCode.maxConcurrent, 2);
    },
  );

  test(
    'OCR variant processing limits concurrent work and selects best score',
    () async {
      final dir = await Directory.systemTemp.createTemp('fin_track_ocr_');
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });
      final files = [
        File('${dir.path}/low.txt')..writeAsStringSync('low'),
        File('${dir.path}/best.txt')..writeAsStringSync('best'),
        File('${dir.path}/medium.txt')..writeAsStringSync('medium'),
      ];
      final ocr = _SlowVariantOcrService();
      final processing = ReceiptProcessingService(ocr: ocr);

      final result = await processing.processBestOcrVariant(
        files
            .map(
              (file) =>
                  OcrImageVariant(name: file.uri.pathSegments.last, file: file),
            )
            .toList(),
      );

      expect(result.variant.name, 'best.txt');
      expect(result.result.text, contains('Total R\$ 999,99'));
      expect(ocr.maxConcurrent, 2);
    },
  );
}
