part of 'receipt_repository.dart';

extension ReceiptRepositoryHelpers on ReceiptRepository {
  Stream<void> _watchChanges() {
    late StreamController<void> controller;
    final subscriptions = <StreamSubscription<List<dynamic>>>[];

    Future<void> emit() async {
      if (!controller.isClosed) {
        controller.add(null);
      }
    }

    controller = StreamController<void>(
      onListen: () {
        for (final stream in <Stream<List<dynamic>>>[
          _database.select(_database.receipts).watch(),
          _database.select(_database.extractedDataTable).watch(),
          _database.select(_database.embeddings).watch(),
          _database.select(_database.categories).watch(),
        ]) {
          subscriptions.add(stream.listen((_) => emit()));
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  Future<ReceiptRow?> _findReceiptRow(int id) {
    return (_database.select(
      _database.receipts,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  ReceiptsCompanion _receiptCompanion(
    Receipt receipt, {
    bool update = false,
    int? categoryId,
  }) {
    return ReceiptsCompanion(
      id: update ? Value(receipt.id) : const Value.absent(),
      type: Value(receipt.type.persistedValue),
      expense: Value(receipt.expense),
      fileName: Value(receipt.fileName),
      fileType: Value(receipt.fileType),
      fileHash: Value(receipt.fileHash),
      fileSize: Value(receipt.fileSize),
      extractedContent: Value(receipt.extractedContent),
      categoryId: Value(categoryId),
      cloudSynced: Value(receipt.cloudSynced),
      registeredAt: Value(receipt.registeredAt),
    );
  }

  Future<void> _clearSearchIndexes() async {
    await _database.customStatement('DELETE FROM receipt_fts');
    await _embeddingPersistence.clearSearchVectors();
  }

  Future<void> _removeFromSearchIndexes(int receiptId) async {
    await _database.customStatement('DELETE FROM receipt_fts WHERE rowid = ?', [
      receiptId,
    ]);
    await _embeddingPersistence.removeSearchVector(receiptId);
  }

  Future<void> _indexSearch(Receipt receipt) async {
    await _database.customStatement('DELETE FROM receipt_fts WHERE rowid = ?', [
      receipt.id,
    ]);

    final structured = _structuredTextForFts(receipt);
    final ocr = receipt.extractedContent.trim();
    final text = [
      structured,
      ocr,
    ].where((part) => part.trim().isNotEmpty).join('\n');

    await _database.customStatement(
      'INSERT INTO receipt_fts(rowid, text, structured, ocr) '
      'VALUES (?, ?, ?, ?)',
      [receipt.id, text, structured, ocr],
    );
  }

  List<Receipt> _applyLimitOffset(
    List<Receipt> receipts,
    ReceiptFilter filter,
  ) {
    if (filter.limit == null) {
      return receipts;
    }
    return receipts.skip(filter.offset ?? 0).take(filter.limit!).toList();
  }

  List<Receipt> _sortReceipts(List<Receipt> receipts, ReceiptFilter filter) {
    final result = [...receipts];
    switch (filter.sortOrder) {
      case ReceiptSort.date:
        result.sort((a, b) {
          final dateA = a.extractedData?.transactionDate;
          final dateB = b.extractedData?.transactionDate;
          if (dateA == null && dateB == null) {
            return 0;
          }
          if (dateA == null) {
            return 1;
          }
          if (dateB == null) {
            return -1;
          }
          final comparison = dateA.compareTo(dateB);
          return _applyDirection(comparison, filter.sortDirection);
        });
      case ReceiptSort.amount:
        result.sort((a, b) {
          final amountA = _signedAmount(a);
          final amountB = _signedAmount(b);
          if (amountA == null && amountB == null) {
            return 0;
          }
          if (amountA == null) {
            return 1;
          }
          if (amountB == null) {
            return -1;
          }
          final comparison = amountA.compareTo(amountB);
          return _applyDirection(comparison, filter.sortDirection);
        });
      case ReceiptSort.establishment:
        result.sort((a, b) {
          final nameA = a.extractedData?.establishment ?? '';
          final nameB = b.extractedData?.establishment ?? '';
          final comparison = nameA.compareTo(nameB);
          return _applyDirection(comparison, filter.sortDirection);
        });
    }
    return result;
  }

  int _applyDirection(int comparison, SortDirection direction) {
    return switch (direction) {
      SortDirection.ascending => comparison,
      SortDirection.descending => -comparison,
    };
  }

  double? _signedAmount(Receipt receipt) {
    final amount = receipt.extractedData?.amount;
    if (amount == null) {
      return null;
    }
    return receipt.expense ? -amount : amount;
  }

  String _indexedStructuredText(Receipt receipt) {
    return _normalize(_structuredTextForFts(receipt));
  }

  String _structuredTextForFts(Receipt receipt) {
    final extractedData = receipt.extractedData;
    final amount = extractedData?.amount;
    final transactionDate = extractedData?.transactionDate;
    final dataIso = transactionDate?.toIso8601String() ?? '';
    final dataBr = transactionDate == null
        ? ''
        : '${transactionDate.day.toString().padLeft(2, '0')}/'
              '${transactionDate.month.toString().padLeft(2, '0')}/'
              '${transactionDate.year}';

    return [
      receipt.fileName,
      receipt.type.label,
      receipt.type.persistedValue,
      receipt.expense ? 'despesa gasto saida debito' : 'receita entrada',
      extractedData?.establishment ?? '',
      extractedData?.issuerLegalName ?? '',
      extractedData?.issuerTradeName ?? '',
      amount == null ? '' : amount.toStringAsFixed(2),
      amount == null ? '' : amount.toStringAsFixed(2).replaceAll('.', ','),
      dataIso,
      dataBr,
      extractedData?.paymentMethod ?? '',
      extractedData?.issuerCnpj ?? '',
      extractedData?.accessKey ?? '',
      extractedData?.documentNumber ?? '',
      extractedData?.documentSeries ?? '',
      extractedData?.documentState ?? '',
      extractedData?.fiscalCnaeDescription ?? '',
      extractedData?.issuerCity ?? '',
      extractedData?.issuerState ?? '',
      extractedData?.extractionParser ?? '',
      ...?extractedData?.items,
      if (receipt.category != null) ...[
        receipt.category!.name,
        receipt.category!.description ?? '',
      ],
    ].where((part) => part.trim().isNotEmpty).join(' ');
  }

  String _indexedOcrText(Receipt receipt) {
    return _normalize(receipt.extractedContent);
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }

  bool _matchesTerms(String indexedText, String normalizedTerm) {
    final terms = normalizedTerm
        .split(RegExp(r'\s+'))
        .map((term) => term.trim())
        .where((term) => term.isNotEmpty);
    return terms.every(indexedText.contains);
  }

  int _compareByExtractedDateDesc(Receipt a, Receipt b) {
    final dateA = a.extractedData?.transactionDate;
    final dateB = b.extractedData?.transactionDate;
    if (dateA == null && dateB == null) {
      return 0;
    }
    if (dateA == null) {
      return 1;
    }
    if (dateB == null) {
      return -1;
    }
    return dateB.compareTo(dateA);
  }
}
