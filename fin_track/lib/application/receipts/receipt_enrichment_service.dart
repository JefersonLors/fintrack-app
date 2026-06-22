import 'dart:async';

import '../../domain/entities/company_data.dart';
import '../../domain/entities/extracted_data.dart';
import '../../domain/infrastructure/i_cnpj_lookup_service.dart';
import '../../domain/infrastructure/i_error_reporter.dart';
import '../../domain/infrastructure/i_fiscal_document_cache_service.dart';
import '../../domain/infrastructure/i_fiscal_document_lookup_service.dart';
import '../../domain/utils/cnpj_extractor.dart';

class ReceiptEnrichmentService {
  ReceiptEnrichmentService({
    ICnpjLookupService? cnpjLookup,
    IFiscalDocumentLookupService? fiscalDocumentLookup,
    IFiscalDocumentCacheService? fiscalDocumentCache,
    IErrorReporter? errorReporter,
  }) : _cnpjLookup = cnpjLookup,
       _fiscalDocumentLookup = fiscalDocumentLookup,
       _fiscalDocumentCache = fiscalDocumentCache,
       _errorReporter = errorReporter;

  static const _backgroundCnpjLookupTimeout = Duration(seconds: 3);
  static const _backgroundFiscalLookupTimeout = Duration(seconds: 5);

  final ICnpjLookupService? _cnpjLookup;
  final IFiscalDocumentLookupService? _fiscalDocumentLookup;
  final IFiscalDocumentCacheService? _fiscalDocumentCache;
  final IErrorReporter? _errorReporter;
  final Map<String, Future<CompanyData?>> _cnpjLookupCache = {};
  final Map<String, Future<ExtractedData>> _fiscalLookupCache = {};

  Future<ExtractedData> enrichByFiscalLookup(ExtractedData data) async {
    final query = _fiscalDocumentLookup;
    final url = data.urlQrCode?.trim();
    final key = data.accessKey?.replaceAll(RegExp(r'\D'), '');
    if (query == null ||
        ((url == null || url.isEmpty) &&
            (key == null || !RegExp(r'^\d{44}$').hasMatch(key)))) {
      return data;
    }

    final cacheKey = [
      if (url != null && url.isNotEmpty) url,
      if (key != null && key.isNotEmpty) key,
    ].join('|');
    final enrichmentFuture = _fiscalLookupCache.putIfAbsent(cacheKey, () async {
      final fiscal = await query.lookup(urlQrCode: url, accessKey: key);
      if (fiscal == null || !fiscal.hasUsefulData) {
        return data;
      }
      return data.copyWith(
        amount: fiscal.amount ?? data.amount,
        transactionDate: fiscal.issuedAt ?? data.transactionDate,
        establishment: fiscal.establishment ?? data.establishment,
        items: fiscal.items.isNotEmpty ? fiscal.items : data.items,
        issuerCnpj: fiscal.issuerCnpj ?? data.issuerCnpj,
        accessKey: fiscal.accessKey ?? data.accessKey,
        urlQrCode: fiscal.lookupUrl ?? data.urlQrCode,
        documentNumber: fiscal.documentNumber ?? data.documentNumber,
        documentSeries: fiscal.documentSeries ?? data.documentSeries,
        documentState: fiscal.documentState ?? data.documentState,
        valueConfidence: fiscal.amount == null ? data.valueConfidence : 0.98,
        dateConfidence: fiscal.issuedAt == null ? data.dateConfidence : 0.98,
        establishmentConfidence: fiscal.establishment == null
            ? data.establishmentConfidence
            : 0.98,
      );
    });
    try {
      return await enrichmentFuture.timeout(
        _backgroundFiscalLookupTimeout,
        onTimeout: () => data,
      );
    } catch (error, stackTrace) {
      _fiscalLookupCache.remove(cacheKey);
      _recordError(
        StateError('Falha ao consultar documento fiscal remoto. $error'),
        stackTrace,
      );
      return data;
    }
  }

  Future<ExtractedData> enrichByLocalFiscalCache(ExtractedData data) async {
    final cache = _fiscalDocumentCache;
    if (cache == null) {
      return data;
    }
    try {
      final fiscal = await cache.find(
        accessKey: data.accessKey,
        urlQrCode: data.urlQrCode,
      );
      if (fiscal == null || !fiscal.hasUsefulData) {
        return data;
      }
      return data.copyWith(
        amount: fiscal.amount ?? data.amount,
        transactionDate: fiscal.issuedAt ?? data.transactionDate,
        establishment: fiscal.establishment ?? data.establishment,
        issuerCnpj: fiscal.issuerCnpj ?? data.issuerCnpj,
        accessKey: fiscal.accessKey ?? data.accessKey,
        urlQrCode: fiscal.lookupUrl ?? data.urlQrCode,
        valueConfidence: fiscal.amount == null ? data.valueConfidence : 0.95,
        dateConfidence: fiscal.issuedAt == null ? data.dateConfidence : 0.95,
        establishmentConfidence: fiscal.establishment == null
            ? data.establishmentConfidence
            : 0.95,
      );
    } catch (error, stackTrace) {
      _recordError(
        StateError('Falha ao consultar cache fiscal local. $error'),
        stackTrace,
      );
      return data;
    }
  }

  Future<void> registerFiscalCache(ExtractedData? data) async {
    final cache = _fiscalDocumentCache;
    if (cache == null || data == null) {
      return;
    }
    try {
      await cache.save(data);
    } catch (error, stackTrace) {
      _recordError(
        StateError('Falha ao salvar dados no cache fiscal local. $error'),
        stackTrace,
      );
    }
  }

  Future<ExtractedData> enrichByLocalCnpj(ExtractedData data) async {
    final cnpj = _normalizeCnpj(data.issuerCnpj);
    final query = _cnpjLookup;
    if (cnpj == null) {
      return data;
    }
    final ILocalCnpjLookupService? localLookup =
        query is ILocalCnpjLookupService
        ? query as ILocalCnpjLookupService
        : null;
    if (localLookup == null) {
      return data;
    }

    try {
      final company = await localLookup.lookupLocal(cnpj);
      if (company == null) {
        return data;
      }
      return _applyCompanyData(data, company);
    } catch (error, stackTrace) {
      _recordError(
        StateError('Falha ao consultar CNPJ em cache local. $error'),
        stackTrace,
      );
      return data;
    }
  }

  void scheduleRemoteBackgroundEnrichment(ExtractedData data) {
    unawaited(
      _warmRemoteCaches(data).catchError((Object error, StackTrace stackTrace) {
        _errorReporter?.record(
          StateError('Falha no enriquecimento remoto em segundo plano. $error'),
          stackTrace,
        );
        return null;
      }),
    );
  }

  Future<void> _warmRemoteCaches(ExtractedData data) async {
    await Future.wait([
      enrichByFiscalLookup(data)
          .timeout(_backgroundFiscalLookupTimeout, onTimeout: () => data)
          .then(registerFiscalCache),
      if (_normalizeCnpj(data.issuerCnpj) case final cnpj?)
        _lookupCompanyByCnpj(
          cnpj,
        ).timeout(_backgroundCnpjLookupTimeout, onTimeout: () => null),
    ]);
  }

  Future<CompanyData?> _lookupCompanyByCnpj(String cnpj) async {
    final query = _cnpjLookup;
    if (query == null) {
      return null;
    }
    final companyFuture = _cnpjLookupCache.putIfAbsent(
      cnpj,
      () => query.lookup(cnpj),
    );
    try {
      return await companyFuture.timeout(
        _backgroundCnpjLookupTimeout,
        onTimeout: () => null,
      );
    } catch (error, stackTrace) {
      _cnpjLookupCache.remove(cnpj);
      _recordError(
        StateError('Falha ao consultar CNPJ remoto. $error'),
        stackTrace,
      );
      return null;
    }
  }

  void _recordError(Object error, StackTrace stackTrace) {
    _errorReporter?.record(error, stackTrace);
  }

  ExtractedData _applyCompanyData(ExtractedData data, CompanyData company) {
    final preferredName = company.preferredName;
    return data.copyWith(
      establishment: preferredName ?? data.establishment,
      issuerCnpj: company.cnpj.replaceAll(RegExp(r'\D'), ''),
      issuerLegalName: company.legalName,
      issuerTradeName: company.tradeName,
      fiscalCnaeDescription: company.fiscalCnaeDescription,
      issuerCity: company.city,
      issuerState: company.state,
      establishmentConfidence: preferredName == null
          ? data.establishmentConfidence
          : 0.95,
    );
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
