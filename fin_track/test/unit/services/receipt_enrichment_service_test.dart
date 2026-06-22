import 'package:fin_track/application/receipts/receipt_enrichment_service.dart';
import 'package:fin_track/domain/entities/company_data.dart';
import 'package:fin_track/domain/entities/extracted_data.dart';
import 'package:fin_track/domain/entities/fiscal_document_data.dart';
import 'package:fin_track/domain/infrastructure/i_cnpj_lookup_service.dart';
import 'package:fin_track/domain/infrastructure/i_error_reporter.dart';
import 'package:fin_track/domain/infrastructure/i_fiscal_document_cache_service.dart';
import 'package:fin_track/domain/infrastructure/i_fiscal_document_lookup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'remote fiscal lookup ignores invalid queries and empty documents',
    () async {
      final lookup = _FiscalLookupFake();
      final service = ReceiptEnrichmentService(fiscalDocumentLookup: lookup);
      const data = ExtractedData(id: 0, receiptId: 0, amount: 12);

      expect(await service.enrichByFiscalLookup(data), data);
      expect(lookup.calls, 0);

      final emptyResult = await service.enrichByFiscalLookup(
        data.copyWith(accessKey: '1' * 44),
      );

      expect(emptyResult.amount, 12);
      expect(lookup.calls, 1);
    },
  );

  test('remote fiscal lookup applies complete document fields', () async {
    final issuedAt = DateTime(2026, 5, 20, 14, 30);
    final service = ReceiptEnrichmentService(
      fiscalDocumentLookup: _FiscalLookupFake(
        result: FiscalDocumentData(
          amount: 99.9,
          issuedAt: issuedAt,
          establishment: 'Mercado Fiscal',
          issuerCnpj: '12345678000195',
          accessKey: '9' * 44,
          lookupUrl: 'https://sefaz.test/nfce',
          documentNumber: '123',
          documentSeries: '2',
          documentState: 'BA',
          items: const ['arroz', 'cafe'],
        ),
      ),
    );

    final enriched = await service.enrichByFiscalLookup(
      ExtractedData(
        id: 0,
        receiptId: 0,
        amount: 10,
        items: ['antigo'],
        accessKey: '1' * 44,
      ),
    );

    expect(enriched.amount, 99.9);
    expect(enriched.transactionDate, issuedAt);
    expect(enriched.establishment, 'Mercado Fiscal');
    expect(enriched.items, ['arroz', 'cafe']);
    expect(enriched.documentNumber, '123');
    expect(enriched.documentSeries, '2');
    expect(enriched.documentState, 'BA');
    expect(enriched.valueConfidence, 0.98);
    expect(enriched.dateConfidence, 0.98);
    expect(enriched.establishmentConfidence, 0.98);
  });

  test('local fiscal cache handles missing cache and cache failures', () async {
    const data = ExtractedData(id: 0, receiptId: 0, amount: 44);
    expect(
      await ReceiptEnrichmentService().enrichByLocalFiscalCache(data),
      data,
    );

    final reporter = _RecordingErrorReporter();
    final failed = await ReceiptEnrichmentService(
      fiscalDocumentCache: _FiscalCacheFake(throwOnFind: true),
      errorReporter: reporter,
    ).enrichByLocalFiscalCache(data);

    expect(failed, data);
    expect(reporter.errors.single.toString(), contains('cache fiscal local'));
  });

  test(
    'local cnpj lookup covers invalid nonlocal and missing company cases',
    () async {
      const invalid = ExtractedData(id: 0, receiptId: 0, issuerCnpj: '123');
      expect(
        await ReceiptEnrichmentService().enrichByLocalCnpj(invalid),
        invalid,
      );

      const valid = ExtractedData(
        id: 0,
        receiptId: 0,
        issuerCnpj: '12345678000195',
      );
      final remoteOnly = ReceiptEnrichmentService(
        cnpjLookup: _RemoteCnpjFake(),
      );
      expect(await remoteOnly.enrichByLocalCnpj(valid), valid);

      final localMiss = ReceiptEnrichmentService(
        cnpjLookup: _LocalCnpjFake(company: null),
      );
      expect(await localMiss.enrichByLocalCnpj(valid), valid);
    },
  );

  test('local cnpj applies company data without preferred name', () async {
    final service = ReceiptEnrichmentService(
      cnpjLookup: _LocalCnpjFake(
        company: const CompanyData(
          cnpj: '12.345.678/0001-95',
          fiscalCnaeDescription: 'Comercio varejista',
          city: 'Salvador',
          state: 'BA',
        ),
      ),
    );

    final enriched = await service.enrichByLocalCnpj(
      const ExtractedData(
        id: 0,
        receiptId: 0,
        establishment: 'Nome OCR',
        issuerCnpj: '12345678000195',
        establishmentConfidence: 0.4,
      ),
    );

    expect(enriched.establishment, 'Nome OCR');
    expect(enriched.issuerLegalName, isNull);
    expect(enriched.fiscalCnaeDescription, 'Comercio varejista');
    expect(enriched.issuerCity, 'Salvador');
    expect(enriched.issuerState, 'BA');
    expect(enriched.establishmentConfidence, 0.4);
  });

  test(
    'remote fiscal lookup records failures and returns original data',
    () async {
      final reporter = _RecordingErrorReporter();
      final service = ReceiptEnrichmentService(
        fiscalDocumentLookup: _FiscalLookupFake(throwOnLookup: true),
        errorReporter: reporter,
      );

      final data = ExtractedData(id: 0, receiptId: 0, accessKey: '1' * 44);
      final result = await service.enrichByFiscalLookup(data);

      expect(result, data);
      expect(
        reporter.errors.any(
          (e) => e.toString().contains('documento fiscal remoto'),
        ),
        isTrue,
      );
    },
  );
}

class _FiscalLookupFake implements IFiscalDocumentLookupService {
  _FiscalLookupFake({this.result, this.throwOnLookup = false});

  final FiscalDocumentData? result;
  final bool throwOnLookup;
  var calls = 0;

  @override
  Future<FiscalDocumentData?> lookup({
    String? urlQrCode,
    String? accessKey,
  }) async {
    calls++;
    if (throwOnLookup) {
      throw StateError('sefaz indisponivel');
    }
    return result ?? const FiscalDocumentData();
  }
}

class _FiscalCacheFake implements IFiscalDocumentCacheService {
  _FiscalCacheFake({this.throwOnFind = false});

  final bool throwOnFind;

  @override
  Future<FiscalDocumentData?> find({String? accessKey, String? urlQrCode}) {
    if (throwOnFind) {
      throw StateError('cache indisponivel');
    }
    return Future.value(null);
  }

  @override
  Future<void> save(ExtractedData data) async {}
}

class _RemoteCnpjFake implements ICnpjLookupService {
  @override
  Future<CompanyData?> lookup(String cnpj) {
    return Future.value(null);
  }
}

class _LocalCnpjFake implements ICnpjLookupService, ILocalCnpjLookupService {
  _LocalCnpjFake({required this.company});

  final CompanyData? company;

  @override
  Future<CompanyData?> lookup(String cnpj) async => company;

  @override
  Future<CompanyData?> lookupLocal(String cnpj) async => company;
}

class _RecordingErrorReporter implements IErrorReporter {
  final errors = <Object>[];

  @override
  void record(Object error, StackTrace? stackTrace) {
    errors.add(error);
  }

  @override
  void recordDiagnostic(String message) {}
}
