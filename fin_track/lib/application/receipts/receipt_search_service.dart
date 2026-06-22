import '../../domain/entities/receipt.dart';
import '../../domain/repositories/i_receipt_repository.dart';
import '../../domain/value_objects/receipt_filter.dart';

typedef ReceiptSemanticSearchCallback =
    Future<List<Receipt>> Function(String term);

class ReceiptSearchService {
  const ReceiptSearchService({
    required IReceiptRepository receipts,
    required ReceiptSemanticSearchCallback searchSemantically,
  }) : _receipts = receipts,
       _searchSemantically = searchSemantically;

  final IReceiptRepository _receipts;
  final ReceiptSemanticSearchCallback _searchSemantically;

  Future<List<Receipt>> search(String query) async {
    final term = query.trim();
    if (term.isEmpty) {
      return _receipts.findByFilters(const ReceiptFilter());
    }

    final textMatches = await _receipts.findByTerms(term);
    final semanticMatches = await _searchSemantically(term);
    final scored = <int, _SearchResult>{};

    for (var index = 0; index < semanticMatches.length; index++) {
      final receipt = semanticMatches[index];
      final score = 1 - (index / semanticMatches.length.clamp(1, 20));
      scored[receipt.id] = _SearchResult(receipt: receipt, score: score);
    }
    for (var index = 0; index < textMatches.length; index++) {
      final receipt = textMatches[index];
      final current = scored[receipt.id];
      final score = _textualScore(receipt, term) - (index * 0.01);
      scored[receipt.id] = _SearchResult(
        receipt: receipt,
        score: current == null ? score : score + current.score,
      );
    }

    final result = scored.values.toList()
      ..sort((a, b) {
        final relevance = b.score.compareTo(a.score);
        if (relevance != 0) {
          return relevance;
        }
        return _compareByExtractedDateDesc(a.receipt, b.receipt);
      });
    return result.map((item) => item.receipt).toList();
  }

  Future<List<Receipt>> findByFilters(ReceiptFilter filter) {
    return _receipts.findByFilters(filter);
  }

  Future<Receipt> findById(int id) => _receipts.findById(id);

  Stream<List<Receipt>> watchByFilters(ReceiptFilter filter) {
    return _receipts.watchByFilters(filter);
  }

  Stream<List<Receipt>> watchAll() => _receipts.watchAll();

  double _textualScore(Receipt receipt, String term) {
    final normalized = _normalize(term);
    final establishment = _normalize(
      receipt.extractedData?.establishment ?? '',
    );
    if (establishment == normalized) {
      return 2.4;
    }
    if (establishment.contains(normalized)) {
      return 2.1;
    }
    final category = receipt.category == null
        ? ''
        : [
            receipt.category!.name,
            receipt.category!.description ?? '',
          ].where((text) => text.trim().isNotEmpty).join(' ');
    final normalizedCategory = _normalize(category);
    if (normalizedCategory == normalized) {
      return 2.0;
    }
    if (normalizedCategory.contains(normalized)) {
      return 1.8;
    }
    if (_normalize(
      receipt.extractedData?.paymentMethod ?? '',
    ).contains(normalized)) {
      return 1.6;
    }
    if (_normalize(receipt.type.label).contains(normalized)) {
      return 1.5;
    }
    if (_normalize(
      receipt.expense ? 'despesa' : 'receita',
    ).contains(normalized)) {
      return 1.3;
    }
    final amount = receipt.extractedData?.amount;
    if (amount != null &&
        _normalize(amount.toStringAsFixed(2)).contains(normalized)) {
      return 1.2;
    }
    final data = receipt.extractedData?.transactionDate;
    if (data != null &&
        _normalize(data.toIso8601String()).contains(normalized)) {
      return 1.1;
    }
    if (_normalize(receipt.extractedContent).contains(normalized)) {
      return 0.35;
    }
    return 0;
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

  int _compareByExtractedDateDesc(Receipt a, Receipt b) {
    final dataA = a.extractedData?.transactionDate;
    final dataB = b.extractedData?.transactionDate;
    if (dataA == null && dataB == null) {
      return 0;
    }
    if (dataA == null) {
      return 1;
    }
    if (dataB == null) {
      return -1;
    }
    return dataB.compareTo(dataA);
  }
}

class _SearchResult {
  const _SearchResult({required this.receipt, required this.score});

  final Receipt receipt;
  final double score;
}
