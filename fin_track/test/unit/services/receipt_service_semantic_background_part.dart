part of 'receipt_service_test.dart';

void registerReceiptSemanticBackgroundTests() {
  test('semantic indexing uses persisted queue and scheduler', () async {
    final scheduler = _RecordingSemanticIndexScheduler();
    final dependencies = FinTrackDependencies.local(
      embeddings: _TestEmbeddingService(),
      cnpjLookup: const _NoopCnpjLookupService(),
      semanticIndexScheduler: scheduler,
    );
    addTearDown(dependencies.dispose);

    final saved = await dependencies.receiptService.register(
      await _receiptFixture('semantic_background.txt', '''
Mercado Central
Nota fiscal eletronica
Data 28/04/2026
Pagamento cartao de credito
Total R\$ 128,45
'''),
    );

    final indexed = await _fetchAfterBackgroundEmbeddings(
      dependencies,
      saved.id,
    );

    expect(indexed.embedding, isNotNull);
    expect(scheduler.scheduled, greaterThan(0));
    expect(scheduler.canceled, greaterThan(0));
  });

  test('failed semantic indexing is retried and then isolated', () async {
    final scheduler = _RecordingSemanticIndexScheduler();
    final dependencies = FinTrackDependencies.local(
      embeddings: _FailingEmbeddingService(),
      cnpjLookup: const _NoopCnpjLookupService(),
      semanticIndexScheduler: scheduler,
    );
    addTearDown(dependencies.dispose);

    final receipt = await dependencies.receiptService.saveConfirmed(
      Receipt(
        id: 0,
        type: ReceiptType.receipt,
        expense: true,
        fileName: (await _receiptFixture(
          'semantic_failure.txt',
          'Total 10',
        )).path,
        fileType: 'text/plain',
        extractedContent: 'Total 10',
        registeredAt: DateTime(2026, 5, 28),
      ),
    );

    final processed = await dependencies.receiptService
        .reindexPendingSemanticEmbeddings();
    final persisted = await dependencies.receiptService.findById(receipt.id);

    expect(processed, 0);
    expect(persisted.embedding, isNull);
    expect(scheduler.scheduled, greaterThan(0));
    expect(scheduler.canceled, greaterThan(0));
  });
}

class _RecordingSemanticIndexScheduler implements ISemanticIndexScheduler {
  int scheduled = 0;
  int canceled = 0;

  @override
  Future<bool> schedulePendingSemanticIndex() async {
    scheduled++;
    return true;
  }

  @override
  Future<bool> cancelPendingSemanticIndex() async {
    canceled++;
    return true;
  }
}
