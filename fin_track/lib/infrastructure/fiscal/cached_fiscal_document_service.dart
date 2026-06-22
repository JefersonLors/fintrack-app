import 'package:drift/drift.dart';

import '../../domain/entities/fiscal_document_data.dart';
import '../../domain/entities/extracted_data.dart';
import '../../domain/infrastructure/i_fiscal_document_cache_service.dart';
import '../../domain/utils/cnpj_extractor.dart';
import '../database/app_database.dart';

class CachedFiscalDocumentService implements IFiscalDocumentCacheService {
  CachedFiscalDocumentService({required AppDatabase database})
    : _database = database;

  final AppDatabase _database;

  @override
  Future<FiscalDocumentData?> find({
    String? accessKey,
    String? urlQrCode,
  }) async {
    final key = _normalizeAccessKey(accessKey) ?? _accessKeyFromUrl(urlQrCode);
    final url = _normalizeUrl(urlQrCode);
    if (key == null && url == null) {
      return null;
    }

    final rows = await _database
        .customSelect(
          '''
      SELECT access_key, qr_code_url, issuer_cnpj, establishment,
             amount, issued_at
        FROM fiscal_document_cache
       WHERE (${key == null ? '0' : 'access_key = ?'})
          OR (${url == null ? '0' : 'qr_code_url = ?'})
       LIMIT 1
      ''',
          variables: [
            if (key != null) Variable<String>(key),
            if (url != null) Variable<String>(url),
          ],
          readsFrom: const {},
        )
        .get();
    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first.data;
    final issuedAtMs = row['issued_at'] as int?;
    return FiscalDocumentData(
      accessKey: row['access_key'] as String?,
      lookupUrl: row['qr_code_url'] as String?,
      issuerCnpj: row['issuer_cnpj'] as String?,
      establishment: row['establishment'] as String?,
      amount: (row['amount'] as num?)?.toDouble(),
      issuedAt: issuedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(issuedAtMs),
    );
  }

  @override
  Future<void> save(ExtractedData data) async {
    final key =
        _normalizeAccessKey(data.accessKey) ??
        _accessKeyFromUrl(data.urlQrCode);
    if (key == null) {
      return;
    }

    final cnpj =
        _normalizeCnpj(data.issuerCnpj) ??
        const CnpjExtractor()
            .extract(key, context: CnpjDocumentContext.fiscal)
            ?.cnpj;
    final issuedAtMs = data.transactionDate?.millisecondsSinceEpoch;
    final updatedAt = DateTime.now().millisecondsSinceEpoch;

    await _database.customStatement(
      '''
      INSERT INTO fiscal_document_cache (
        access_key, qr_code_url, issuer_cnpj, establishment,
        amount, issued_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(access_key) DO UPDATE SET
        qr_code_url = COALESCE(excluded.qr_code_url, fiscal_document_cache.qr_code_url),
        issuer_cnpj = COALESCE(excluded.issuer_cnpj, fiscal_document_cache.issuer_cnpj),
        establishment = COALESCE(excluded.establishment, fiscal_document_cache.establishment),
        amount = COALESCE(excluded.amount, fiscal_document_cache.amount),
        issued_at = COALESCE(excluded.issued_at, fiscal_document_cache.issued_at),
        updated_at = excluded.updated_at
      ''',
      [
        key,
        _normalizeUrl(data.urlQrCode),
        cnpj,
        _normalizeText(data.establishment),
        data.amount,
        issuedAtMs,
        updatedAt,
      ],
    );
  }

  String? _normalizeAccessKey(String? value) {
    final key = value?.replaceAll(RegExp(r'\D'), '');
    if (key == null || !RegExp(r'^\d{44}$').hasMatch(key)) {
      return null;
    }
    return key;
  }

  String? _accessKeyFromUrl(String? urlQrCode) {
    final url = _normalizeUrl(urlQrCode);
    if (url == null) {
      return null;
    }
    return const CnpjExtractor()
        .extract('', codes: [url], context: CnpjDocumentContext.fiscal)
        ?.accessKey;
  }

  String? _normalizeUrl(String? value) {
    final url = value?.trim();
    if (url == null || url.isEmpty) {
      return null;
    }
    return url;
  }

  String? _normalizeCnpj(String? value) {
    final cnpj = value?.replaceAll(RegExp(r'\D'), '');
    if (cnpj == null || !RegExp(r'^\d{14}$').hasMatch(cnpj)) {
      return null;
    }
    return cnpj;
  }

  String? _normalizeText(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}
