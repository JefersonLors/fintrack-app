import '../../domain/entities/category.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/entities/extracted_data.dart';
import '../../domain/infrastructure/i_embedding_service.dart';
import '../../domain/infrastructure/i_category_preference_service.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../../domain/utils/cnpj_extractor.dart';
import '../../domain/value_objects/embedding_vector.dart';
import '../ocr/ocr_processing_result.dart';

class ReceiptCategoryService {
  ReceiptCategoryService({
    required ICategoryRepository categories,
    required IEmbeddingService embeddings,
    ICategoryPreferenceService? categoryPreference,
  }) : _categories = categories,
       _embeddings = embeddings,
       _categoryPreference = categoryPreference;

  final ICategoryRepository _categories;
  final IEmbeddingService _embeddings;
  final ICategoryPreferenceService? _categoryPreference;
  final Map<String, Future<EmbeddingVector>> _categoryEmbeddingCache = {};

  Future<Category?> suggest(String text, ExtractedData data) async {
    final registeredCategories = await _categories.list();
    if (registeredCategories.isEmpty) {
      return null;
    }

    final byCnpj = await _categoryByCnpj(data, registeredCategories);
    if (byCnpj != null) {
      return byCnpj;
    }

    if (_normalizeCnpj(data.issuerCnpj) == null) {
      final byEstablishment = await _categoryByEstablishment(
        data,
        registeredCategories,
      );
      if (byEstablishment != null) {
        return byEstablishment;
      }
    }

    final byCnae = await _categoryByReliableText(
      data.fiscalCnaeDescription,
      registeredCategories,
      minimumScore: 0.12,
      minimumDifference: 0.02,
    );
    if (byCnae != null) {
      return byCnae;
    }

    final byItems = await _categoryByLearnedItems(
      data.items,
      registeredCategories,
    );
    if (byItems != null) {
      return byItems;
    }

    final sources = await _categorySources(text, data);
    var best = registeredCategories.first;
    var bestScore = -1.0;
    var secondScore = -1.0;

    _removeObsoleteCategoryEmbeddings(registeredCategories);
    for (final category in registeredCategories) {
      final categoryEmbedding = await _categoryEmbedding(category);
      final score = _categoryScore(sources, categoryEmbedding, category);
      if (score > bestScore) {
        secondScore = bestScore;
        best = category;
        bestScore = score;
      } else if (score > secondScore) {
        secondScore = score;
      }
    }

    if (!_isCategoryScoreReliable(bestScore, secondScore)) {
      return null;
    }
    return best;
  }

  Future<void> registerPreference(Receipt receipt) async {
    final preference = _categoryPreference;
    final data = receipt.extractedData;
    final category = receipt.category;
    if (preference == null || data == null || category == null) {
      return;
    }
    if (category.id <= 0) {
      return;
    }
    final cnpj = _normalizeCnpj(data.issuerCnpj);
    final establishment = data.establishment?.trim();
    if (cnpj != null && establishment != null && establishment.isNotEmpty) {
      await preference.registerCnpjConfirmation(
        cnpj: cnpj,
        establishment: establishment,
        categoryId: category.id,
      );
    }
    await preference.registerPreferredCategory(
      cnpj: cnpj,
      establishment: data.establishment,
      categoryId: category.id,
    );
    await preference.registerCategoryItems(
      items: data.items,
      categoryId: category.id,
    );
  }

  String categoryText(
    String normalizedText,
    OcrProcessingResult processing,
    ExtractedData data,
  ) {
    final itemsText = data.items.join(' ');
    return [
      itemsText,
      itemsText,
      itemsText,
      _textWithoutFiscalIdentifiers(normalizedText),
      processing.type.label,
      data.establishment ?? '',
      data.fiscalCnaeDescription ?? '',
    ].join(' ');
  }

  bool _isCategoryScoreReliable(
    double bestScore,
    double secondScore, {
    double itemBoost = 0,
  }) {
    if (itemBoost >= 0.05 && bestScore > 0) {
      return true;
    }
    if (bestScore <= 0) {
      return false;
    }
    final difference = secondScore >= 0 ? bestScore - secondScore : 1.0;
    if (bestScore >= 0.18 && difference >= 0.02) {
      return true;
    }
    if (bestScore >= 0.08 && difference >= 0.05) {
      return true;
    }
    if (bestScore < 0.08) {
      return false;
    }
    return secondScore < 0;
  }

  Future<Map<int, double>> _categoryBoostsByItems(List<String> items) async {
    if (items.isEmpty) {
      return const <int, double>{};
    }
    final preference = _categoryPreference;
    if (preference == null) {
      return const <int, double>{};
    }
    return preference.itemBoosts(items);
  }

  Future<List<_CategorySource>> _categorySources(
    String text,
    ExtractedData data,
  ) async {
    var sources = <({String text, double weight})>[
      (text: data.items.join(' ').trim(), weight: 0.40),
      (text: data.fiscalCnaeDescription?.trim() ?? '', weight: 0.25),
      (text: data.establishment?.trim() ?? '', weight: 0.20),
      (text: text.trim(), weight: 0.15),
    ].where((source) => source.text.isNotEmpty).toList();

    if (sources.isEmpty) {
      sources = [(text: text, weight: 1)];
    }

    final totalWeight = sources.fold<double>(
      0,
      (total, source) => total + source.weight,
    );
    final normalizer = totalWeight <= 0 ? 1.0 : totalWeight;
    final result = <_CategorySource>[];
    for (final source in sources) {
      result.add(
        _CategorySource(
          embedding: await _embeddings.generate(source.text),
          text: source.text,
          weight: source.weight / normalizer,
        ),
      );
    }
    return result;
  }

  double _categoryScore(
    List<_CategorySource> sources,
    EmbeddingVector categoryEmbedding,
    Category category,
  ) {
    var score = 0.0;
    final categoryTextValue = [
      _categoryEmbeddingText(category),
      _categorySynonyms(category),
    ].where((text) => text.isNotEmpty).join(' ');
    for (final source in sources) {
      final semantic = source.embedding.cosineSimilarity(categoryEmbedding);
      final lexical = _termOverlap(source.text, categoryTextValue);
      score += ((semantic * 0.65) + (lexical * 0.35)) * source.weight;
    }
    return score;
  }

  double _termOverlap(String origin, String category) {
    final originTerms = _categoryTerms(origin);
    if (originTerms.isEmpty) {
      return 0;
    }
    final categoryTerms = _categoryTerms(category);
    if (categoryTerms.isEmpty) {
      return 0;
    }
    final intersection = originTerms.intersection(categoryTerms).length;
    return intersection / originTerms.length;
  }

  Set<String> _categoryTerms(String text) {
    return _normalize(text)
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((term) => term.length >= 3)
        .toSet();
  }

  Future<Category?> _categoryByCnpj(
    ExtractedData data,
    List<Category> registeredCategories,
  ) async {
    final preference = _categoryPreference;
    if (preference == null || _normalizeCnpj(data.issuerCnpj) == null) {
      return null;
    }
    final categoryId = await preference.findPreferredCategory(
      cnpj: data.issuerCnpj,
    );
    return _categoryById(categoryId, registeredCategories);
  }

  Future<Category?> _categoryByEstablishment(
    ExtractedData data,
    List<Category> registeredCategories,
  ) async {
    final preference = _categoryPreference;
    if (preference == null) {
      return null;
    }
    final categoryId = await preference.findPreferredCategory(
      establishment: data.establishment,
    );
    return _categoryById(categoryId, registeredCategories);
  }

  Category? _categoryById(
    int? categoryId,
    List<Category> registeredCategories,
  ) {
    if (categoryId == null) {
      return null;
    }
    for (final category in registeredCategories) {
      if (category.id == categoryId) {
        return category;
      }
    }
    return null;
  }

  Future<Category?> _categoryByReliableText(
    String? text,
    List<Category> registeredCategories, {
    required double minimumScore,
    required double minimumDifference,
  }) async {
    final source = text?.trim();
    if (source == null || source.isEmpty) {
      return null;
    }
    _removeObsoleteCategoryEmbeddings(registeredCategories);
    final embeddingFonte = await _embeddings.generate(source);
    var best = registeredCategories.first;
    var bestScore = -1.0;
    var secondScore = -1.0;
    for (final category in registeredCategories) {
      final categoryEmbedding = await _categoryEmbedding(category);
      final categoryTextValue = [
        _categoryEmbeddingText(category),
        _categorySynonyms(category),
      ].where((text) => text.isNotEmpty).join(' ');
      final semantic = embeddingFonte.cosineSimilarity(categoryEmbedding);
      final lexical = _termOverlap(source, categoryTextValue);
      final score = (semantic * 0.55) + (lexical * 0.45);
      if (score > bestScore) {
        secondScore = bestScore;
        best = category;
        bestScore = score;
      } else if (score > secondScore) {
        secondScore = score;
      }
    }
    final difference = secondScore >= 0 ? bestScore - secondScore : 1.0;
    if (bestScore >= minimumScore && difference >= minimumDifference) {
      return best;
    }
    return null;
  }

  Future<Category?> _categoryByLearnedItems(
    List<String> items,
    List<Category> registeredCategories,
  ) async {
    final boosts = await _categoryBoostsByItems(items);
    if (boosts.isEmpty) {
      return null;
    }
    final sorted = boosts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final best = sorted.first;
    final secondScore = sorted.length > 1 ? sorted[1].value : -1.0;
    if (!_isCategoryScoreReliable(
      best.value,
      secondScore,
      itemBoost: best.value,
    )) {
      return null;
    }
    return _categoryById(best.key, registeredCategories);
  }

  Future<EmbeddingVector> _categoryEmbedding(Category category) {
    final key = _categoryEmbeddingKey(category);
    return _categoryEmbeddingCache.putIfAbsent(
      key,
      () => _embeddings.generate(_categoryEmbeddingText(category)),
    );
  }

  void _removeObsoleteCategoryEmbeddings(List<Category> categories) {
    final currentKeys = categories.map(_categoryEmbeddingKey).toSet();
    _categoryEmbeddingCache.removeWhere((key, _) => !currentKeys.contains(key));
  }

  String _categoryEmbeddingKey(Category category) {
    return [
      category.id,
      category.name.trim(),
      category.description?.trim() ?? '',
    ].join('|');
  }

  String _categoryEmbeddingText(Category category) {
    return [
      category.name.trim(),
      category.description?.trim() ?? '',
    ].where((text) => text.isNotEmpty).join(' ');
  }

  String _categorySynonyms(Category category) {
    return switch (_normalize(category.name)) {
      'alimentacao' =>
        'supermercado mercado padaria restaurante refeicao alimentos bebidas arroz cafe fruta frutas',
      'transporte' =>
        'posto combustivel gasolina alcool diesel estacionamento mobilidade',
      'saude' =>
        'farmacia farmaceutico medicamento remedio clinica consulta hospital',
      'moradia' => 'aluguel condominio energia agua internet casa residencia',
      'educacao' => 'curso escola faculdade livro material didatico',
      'lazer' => 'evento entretenimento cinema viagem passeio',
      'pix' => 'transferencia pagamento pix',
      _ => '',
    };
  }

  String _textWithoutFiscalIdentifiers(String text) {
    return text
        .replaceAll(RegExp(r'https?://\S+', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'(?<!\d)(?:\d[ .-]?){44}(?!\d)'), ' ')
        .replaceAll(
          RegExp(
            r'(?:cnpj|cnp3)?\s*:?\s*\d{2}\D?\d{3}\D?\d{3}\D?\d{4}\D?\d{2}',
            caseSensitive: false,
          ),
          ' ',
        );
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

  String? _normalizeCnpj(String? cnpj) {
    final normalized = cnpj?.replaceAll(RegExp(r'\D'), '');
    if (normalized == null ||
        !RegExp(r'^\d{14}$').hasMatch(normalized) ||
        !hasValidCnpjDigits(normalized)) {
      return null;
    }
    return normalized;
  }
}

class _CategorySource {
  const _CategorySource({
    required this.embedding,
    required this.text,
    required this.weight,
  });

  final EmbeddingVector embedding;
  final String text;
  final double weight;
}
