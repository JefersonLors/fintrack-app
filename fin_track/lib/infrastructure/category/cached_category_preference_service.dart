import 'package:drift/drift.dart';

import '../../domain/infrastructure/i_category_preference_service.dart';
import '../database/app_database.dart';

class CachedCategoryPreferenceService implements ICategoryPreferenceService {
  CachedCategoryPreferenceService({required AppDatabase database})
    : _database = database;

  final AppDatabase _database;

  @override
  Future<int?> findPreferredCategory({
    String? cnpj,
    String? establishment,
  }) async {
    final normalizedCnpj = _normalizeCnpj(cnpj);
    if (normalizedCnpj != null) {
      final row = await (_database.select(
        _database.cnpjCache,
      )..where((tbl) => tbl.cnpj.equals(normalizedCnpj))).getSingleOrNull();
      final categoryId = row?.preferredCategoryId;
      if (categoryId != null && await _categoryExists(categoryId)) {
        return categoryId;
      }
      return null;
    }

    final establishmentKey = _normalizeEstablishment(establishment);
    if (establishmentKey == null) {
      return null;
    }
    final row =
        await (_database.select(_database.establishmentCategoryCache)
              ..where((tbl) => tbl.establishmentKey.equals(establishmentKey)))
            .getSingleOrNull();
    final categoryId = row?.categoryId;
    if (categoryId != null && await _categoryExists(categoryId)) {
      return categoryId;
    }
    return null;
  }

  @override
  Future<void> registerPreferredCategory({
    String? cnpj,
    String? establishment,
    required int categoryId,
  }) async {
    if (categoryId <= 0 || !await _categoryExists(categoryId)) {
      return;
    }

    final updatedAt = DateTime.now();
    final normalizedCnpj = _normalizeCnpj(cnpj);
    if (normalizedCnpj != null) {
      final existing = await (_database.select(
        _database.cnpjCache,
      )..where((tbl) => tbl.cnpj.equals(normalizedCnpj))).getSingleOrNull();
      await _database
          .into(_database.cnpjCache)
          .insertOnConflictUpdate(
            CnpjCacheCompanion.insert(
              cnpj: normalizedCnpj,
              legalName: Value(existing?.legalName),
              tradeName: Value(existing?.tradeName),
              confirmedName: Value(existing?.confirmedName),
              fiscalCnaeDescription: Value(existing?.fiscalCnaeDescription),
              city: Value(existing?.city),
              state: Value(existing?.state),
              preferredCategoryId: Value(categoryId),
              updatedAt: updatedAt,
            ),
          );
      return;
    }

    final establishmentKey = _normalizeEstablishment(establishment);
    if (establishmentKey == null) {
      return;
    }
    await _database
        .into(_database.establishmentCategoryCache)
        .insertOnConflictUpdate(
          EstablishmentCategoryCacheCompanion.insert(
            establishmentKey: establishmentKey,
            establishment: establishment!.trim(),
            categoryId: categoryId,
            updatedAt: updatedAt,
          ),
        );
  }

  @override
  Future<void> registerCnpjConfirmation({
    required String cnpj,
    required String establishment,
    required int categoryId,
  }) async {
    if (categoryId <= 0 || !await _categoryExists(categoryId)) {
      return;
    }
    final normalizedCnpj = _normalizeCnpj(cnpj);
    final confirmedName = establishment.trim();
    if (normalizedCnpj == null || confirmedName.isEmpty) {
      return;
    }

    final existing = await (_database.select(
      _database.cnpjCache,
    )..where((tbl) => tbl.cnpj.equals(normalizedCnpj))).getSingleOrNull();
    await _database
        .into(_database.cnpjCache)
        .insertOnConflictUpdate(
          CnpjCacheCompanion.insert(
            cnpj: normalizedCnpj,
            legalName: Value(existing?.legalName),
            tradeName: Value(existing?.tradeName),
            confirmedName: Value(confirmedName),
            fiscalCnaeDescription: Value(existing?.fiscalCnaeDescription),
            city: Value(existing?.city),
            state: Value(existing?.state),
            preferredCategoryId: Value(categoryId),
            updatedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<Map<int, double>> itemBoosts(List<String> items) async {
    final keys = items
        .map(_normalizeItem)
        .whereType<String>()
        .toSet()
        .take(12)
        .toList();
    if (keys.isEmpty) {
      return const <int, double>{};
    }

    final rows = await (_database.select(
      _database.itemCategoryCache,
    )..where((tbl) => tbl.itemKey.isIn(keys))).get();

    final boosts = <int, double>{};
    for (final row in rows) {
      if (row.occurrences < 2) {
        continue;
      }
      final increment = (0.10 * (row.occurrences - 1)).clamp(0.0, 0.12);
      boosts[row.categoryId] = ((boosts[row.categoryId] ?? 0) + increment)
          .clamp(0.0, 0.15);
    }
    return boosts;
  }

  @override
  Future<void> registerCategoryItems({
    required List<String> items,
    required int categoryId,
  }) async {
    if (categoryId <= 0 || !await _categoryExists(categoryId)) {
      return;
    }

    final now = DateTime.now();
    final entries = <String, String>{};
    for (final item in items) {
      final key = _normalizeItem(item);
      if (key != null) {
        entries.putIfAbsent(key, () => item.trim());
      }
      if (entries.length >= 12) {
        break;
      }
    }

    for (final entry in entries.entries) {
      final existing =
          await (_database.select(_database.itemCategoryCache)..where(
                (tbl) =>
                    tbl.itemKey.equals(entry.key) &
                    tbl.categoryId.equals(categoryId),
              ))
              .getSingleOrNull();
      await _database
          .into(_database.itemCategoryCache)
          .insertOnConflictUpdate(
            ItemCategoryCacheCompanion.insert(
              itemKey: entry.key,
              item: entry.value,
              categoryId: categoryId,
              occurrences: Value((existing?.occurrences ?? 0) + 1),
              updatedAt: now,
            ),
          );
    }
  }

  Future<bool> _categoryExists(int categoryId) async {
    final row = await (_database.select(
      _database.categories,
    )..where((tbl) => tbl.id.equals(categoryId))).getSingleOrNull();
    return row != null;
  }

  String? _normalizeCnpj(String? cnpj) {
    final normalized = cnpj?.replaceAll(RegExp(r'\D'), '');
    if (normalized == null || !RegExp(r'^\d{14}$').hasMatch(normalized)) {
      return null;
    }
    return normalized;
  }

  String? _normalizeEstablishment(String? establishment) {
    final original = establishment?.trim();
    if (!_cacheableEstablishment(original)) {
      return null;
    }
    final text = original!
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.length < 3) {
      return null;
    }
    return text;
  }

  bool _cacheableEstablishment(String? establishment) {
    final text = establishment?.trim();
    if (text == null || text.length < 3) {
      return false;
    }
    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.length < 3) {
      return false;
    }
    if (RegExp(r'^[\d\s.,:/\-]+$').hasMatch(text)) {
      return false;
    }
    if (RegExp(
      r'\.(jpg|jpeg|png|pdf|webp|heic)$',
      caseSensitive: false,
    ).hasMatch(text)) {
      return false;
    }
    const badValues = {
      'nao identificado',
      'receipt',
      'nota fiscal',
      'documento auxiliar',
      'consumidor eletronica',
      'cupom fiscal',
      'amount',
      'amount total',
      'total',
      'data',
      'hora',
      'pagamento',
      'pix',
      'transferencia',
      'credito',
      'debito',
      'cartao',
      'cnpj',
      'cpf',
      'cpf cnpj',
      'key de acesso',
      'codigo de autorizacao',
      'nsu',
      'origem',
      'destino',
      'quem recebeu',
      'quem pagou',
      'name',
      'instituicao',
      'sem category',
    };
    if (badValues.contains(normalized)) {
      return false;
    }
    final terms = normalized
        .split(' ')
        .where((term) => term.length >= 3)
        .toList();
    if (terms.isEmpty) {
      return false;
    }
    return RegExp(r'[a-zA-ZÀ-ÿ]').hasMatch(text);
  }

  String? _normalizeItem(String? item) {
    final text = item
        ?.trim()
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\b\d+[,.]\d+\b'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text == null || text.length < 4) {
      return null;
    }
    final terms = text.split(' ').where((term) => term.length >= 3).toList();
    if (terms.isEmpty || terms.every(_genericTerm)) {
      return null;
    }
    return terms.take(5).join(' ');
  }

  bool _genericTerm(String term) {
    const genericTerms = {
      'produto',
      'produtos',
      'item',
      'items',
      'servico',
      'servicos',
      'taxa',
      'kit',
      'unidade',
      'unid',
      'diverso',
      'diversos',
      'other',
      'mercadoria',
      'mercadorias',
      'recarga',
      'amount',
      'total',
    };
    return genericTerms.contains(term);
  }
}
