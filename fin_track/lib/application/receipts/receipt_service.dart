import 'dart:io';

import '../../domain/entities/receipt.dart';
import '../../domain/entities/extracted_data.dart';
import '../../domain/infrastructure/i_document_scanner_service.dart';
import '../../domain/infrastructure/i_fiscal_document_cache_service.dart';
import '../../domain/infrastructure/i_embedding_diagnostics.dart';
import '../../domain/infrastructure/i_embedding_service.dart';
import '../../domain/infrastructure/i_error_reporter.dart';
import '../../domain/infrastructure/i_image_preprocessor_service.dart';
import '../../domain/infrastructure/i_image_service.dart';
import '../../domain/infrastructure/i_semantic_index_scheduler.dart';
import '../../domain/infrastructure/i_visual_code_service.dart';
import '../../domain/infrastructure/i_cnpj_lookup_service.dart';
import '../../domain/infrastructure/i_fiscal_document_lookup_service.dart';
import '../../domain/infrastructure/i_ocr_service.dart';
import '../../domain/infrastructure/i_category_preference_service.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../../domain/repositories/i_receipt_repository.dart';
import '../../domain/repositories/i_semantic_index_task_repository.dart';
import '../../domain/services/i_receipt_service.dart';
import '../../domain/services/i_configuration_service.dart';
import '../../domain/value_objects/receipt_filter.dart';
import '../../domain/value_objects/ocr_result.dart';
import '../../infrastructure/diagnostics/error_handling.dart';
import 'receipt_enrichment_service.dart';
import 'receipt_file_service.dart';
import 'receipt_search_service.dart';
import 'receipt_category_service.dart';
import 'receipt_import_service.dart';
import 'receipt_processing_service.dart';
import 'receipt_semantic_service.dart';
import '../policies/storage_limit_policy.dart';
import '../ocr/data_extractor_service.dart';
import '../ocr/financial_nature_classifier_service.dart';
import 'semantic/receipt_semantic_indexer.dart';

class ReceiptService implements IReceiptService {
  ReceiptService({
    required IReceiptRepository receipts,
    ISemanticIndexTaskRepository? semanticTasks,
    required ICategoryRepository categories,
    required IImageService images,
    IDocumentScannerService? scanner,
    IImagePreprocessorService? imagePreprocessor,
    IVisualCodeService? visualCode,
    ICnpjLookupService? cnpjLookup,
    IFiscalDocumentLookupService? fiscalDocumentLookup,
    IFiscalDocumentCacheService? fiscalDocumentCache,
    ICategoryPreferenceService? categoryPreference,
    required IOCRService ocr,
    required IEmbeddingService embeddings,
    required IConfigurationService configuration,
    required DataExtractorService dataExtractor,
    FinancialNatureClassifierService? natureClassifier,
    ReceiptSemanticIndexer? semanticIndexer,
    ISemanticIndexScheduler semanticIndexScheduler =
        const NoopSemanticIndexScheduler(),
    IEmbeddingDiagnostics? embeddingDiagnostics,
    IErrorReporter? errorReporter,
  }) : _receipts = receipts,
       _images = images,
       _dataExtractor = dataExtractor,
       _embeddingDiagnostics =
           embeddingDiagnostics ??
           (embeddings is IEmbeddingDiagnostics
               ? embeddings as IEmbeddingDiagnostics
               : null),
       _errorReporter = errorReporter,
       _natureClassifier =
           natureClassifier ?? const FinancialNatureClassifierService(),
       _semanticIndexer =
           semanticIndexer ?? ReceiptSemanticIndexer(embeddings: embeddings) {
    _enrichmentService = ReceiptEnrichmentService(
      cnpjLookup: cnpjLookup,
      fiscalDocumentLookup: fiscalDocumentLookup,
      fiscalDocumentCache: fiscalDocumentCache,
      errorReporter: errorReporter,
    );
    _storagePolicy = StorageLimitPolicy(configuration: configuration);
    _fileService = ReceiptFileService(receipts: receipts, images: images);
    _searchService = ReceiptSearchService(
      receipts: receipts,
      searchSemantically: _searchSemantically,
    );
    _categoryService = ReceiptCategoryService(
      categories: categories,
      embeddings: embeddings,
      categoryPreference: categoryPreference,
    );
    _semanticService = ReceiptSemanticService(
      receipts: receipts,
      semanticTasks: semanticTasks ?? InMemorySemanticIndexTaskRepository(),
      embeddings: embeddings,
      semanticIndexer: _semanticIndexer,
      scheduler: semanticIndexScheduler,
      embeddingDiagnostics: _embeddingDiagnostics,
      errorReporter: errorReporter,
    );
    _importService = ReceiptImportService(
      fileService: _fileService,
      scanner: scanner,
    );
    _processingService = ReceiptProcessingService(
      imagePreprocessor: imagePreprocessor,
      visualCode: visualCode,
      ocr: ocr,
    );
  }

  static const double ocrConfidenceThreshold =
      OcrResult.acceptableConfidenceThreshold;

  final IReceiptRepository _receipts;
  final IImageService _images;
  final DataExtractorService _dataExtractor;
  final IEmbeddingDiagnostics? _embeddingDiagnostics;
  final IErrorReporter? _errorReporter;
  final FinancialNatureClassifierService _natureClassifier;
  final ReceiptSemanticIndexer _semanticIndexer;
  late final ReceiptEnrichmentService _enrichmentService;
  late final StorageLimitPolicy _storagePolicy;
  late final ReceiptFileService _fileService;
  late final ReceiptSearchService _searchService;
  late final ReceiptCategoryService _categoryService;
  late final ReceiptImportService _importService;
  late final ReceiptProcessingService _processingService;
  late final ReceiptSemanticService _semanticService;

  @override
  Future<File> scanDocument() => _importService.scanDocument();

  @override
  Future<File> captureImage() => _importService.captureImage();

  @override
  Future<List<File>> importFiles() => _importService.importFiles();

  @override
  Future<void> validateSpaceForNewReceipt([File? file]) async {
    await _storagePolicy.validateSpaceForNewReceipt(file);
  }

  @override
  Future<void> validateSpaceForNewReceipts(List<File> files) async {
    await _storagePolicy.validateSpaceForNewReceipts(files);
  }

  @override
  Future<Receipt> register(File image) async {
    return _importService.register(
      image,
      processPreview: processPreview,
      saveConfirmed: saveConfirmed,
    );
  }

  @override
  Future<Receipt> processPreview(File image) async {
    return _processingService.processPreview(
      image,
      images: _images,
      validateSpace: validateSpaceForNewReceipt,
      dataExtractor: _dataExtractor,
      natureClassifier: _natureClassifier,
      enrichByLocalFiscalCache: _enrichmentService.enrichByLocalFiscalCache,
      enrichByLocalCnpj: _enrichmentService.enrichByLocalCnpj,
      normalizeEstablishment: _withEmptyEstablishmentIfMissing,
      suggestCategory: _categoryService.suggest,
      categoryText: _categoryService.categoryText,
      scheduleRemoteEnrichment:
          _enrichmentService.scheduleRemoteBackgroundEnrichment,
      recordDiagnostic: _recordDiagnostic,
      registerError: _registerError,
    );
  }

  @override
  Future<Receipt> saveConfirmed(Receipt receipt) async {
    final normalizedReceipt = _withNormalizedEstablishment(receipt);
    if (receipt.id != 0) {
      final backupPending = normalizedReceipt.copyWith(cloudSynced: false);
      try {
        final updated = await _semanticService.withUpdatedEmbedding(
          backupPending,
        );
        await _receipts.update(updated);
      } catch (error, stackTrace) {
        _registerError(
          StateError(
            'Falha ao atualizar embedding; comprovante será salvo sem embedding atualizado. $error',
          ),
          stackTrace,
        );
        await _receipts.update(
          _semanticService.withoutEmbedding(backupPending),
        );
      }
      final saved = await _receipts.findById(receipt.id);
      if (_semanticIndexer.needsReindex(saved)) {
        _semanticService.scheduleBackgroundSemanticEmbedding(saved);
      }
      await _categoryService.registerPreference(saved);
      await _enrichmentService.registerFiscalCache(saved.extractedData);
      return saved;
    }

    await _validateStorageLimitBytes(
      normalizedReceipt.fileSize ?? 0,
      plural: false,
    );
    final sourceFile = await _previewFile(normalizedReceipt);
    final finalName = await _images.saveToFileSystem(sourceFile);
    try {
      final saved = await _receipts.save(
        Receipt(
          id: 0,
          type: normalizedReceipt.type,
          expense: normalizedReceipt.expense,
          fileName: finalName,
          fileType: _fileType(finalName),
          fileHash: normalizedReceipt.fileHash,
          fileSize: normalizedReceipt.fileSize,
          extractedContent: normalizedReceipt.extractedContent,
          cloudSynced: false,
          registeredAt: normalizedReceipt.registeredAt,
          extractedData: normalizedReceipt.extractedData,
          category: normalizedReceipt.category,
        ),
      );

      final persisted = await _receipts.findById(saved.id);
      await _categoryService.registerPreference(persisted);
      await _enrichmentService.registerFiscalCache(persisted.extractedData);
      _semanticService.scheduleBackgroundSemanticEmbedding(persisted);
      return persisted;
    } catch (error, stackTrace) {
      await ignoreCleanupFailure(
        () => _images.delete(finalName),
        diagnosticContext:
            'Falha ao remover arquivo salvo após erro ao persistir comprovante',
        report: true,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<void> discardPreview(Receipt receipt) async {
    await _fileService.discardPreview(receipt);
  }

  @override
  Future<File> localFile(Receipt receipt) async {
    return _fileService.localFile(receipt);
  }

  Future<File> _previewFile(Receipt receipt) async {
    return _fileService.previewFile(receipt);
  }

  @override
  Future<List<Receipt>> search(String query) async {
    return _searchService.search(query);
  }

  Future<List<Receipt>> _searchSemantically(String term) async {
    return _semanticService.searchSemantically(term);
  }

  Future<void> waitForBackgroundEmbeddings() async {
    await _semanticService.waitForBackgroundEmbeddings();
  }

  String _fileType(String fileName) {
    return _processingService.fileType(fileName);
  }

  ExtractedData _withEmptyEstablishmentIfMissing(ExtractedData data) {
    final establishment = data.establishment?.trim();
    if (establishment != null && establishment.isNotEmpty) {
      return data;
    }
    return data.copyWith(establishment: '');
  }

  @override
  Future<List<Receipt>> findByFilters(ReceiptFilter filter) {
    return _searchService.findByFilters(filter);
  }

  @override
  Future<Receipt> findById(int id) => _searchService.findById(id);

  Future<void> _validateStorageLimitBytes(
    int fileSize, {
    required bool plural,
  }) async {
    await _storagePolicy.validateStorageLimitBytes(fileSize, plural: plural);
  }

  @override
  Future<void> update(Receipt receipt) async {
    final backupPending = _withNormalizedEstablishment(
      receipt,
    ).copyWith(cloudSynced: false);
    try {
      await _receipts.update(
        await _semanticService.withUpdatedEmbeddingIfNeeded(backupPending),
      );
    } catch (error, stackTrace) {
      _registerError(
        StateError(
          'Falha ao atualizar embedding; comprovante será salvo e reindexado depois. $error',
        ),
        stackTrace,
      );
      await _receipts.update(_semanticService.withoutEmbedding(backupPending));
      _semanticService.scheduleBackgroundSemanticEmbedding(
        await _receipts.findById(receipt.id),
      );
    }
    await _categoryService.registerPreference(
      await _receipts.findById(receipt.id),
    );
  }

  Receipt _withNormalizedEstablishment(Receipt receipt) {
    final data = receipt.extractedData;
    if (data == null) {
      return receipt;
    }
    final normalized = data.withNormalizedEstablishment();
    if (identical(normalized, data)) {
      return receipt;
    }
    return receipt.copyWith(extractedData: normalized);
  }

  @override
  Future<void> delete(int id) async {
    await _fileService.delete(id);
  }

  @override
  Future<int> deleteOrphanFiles() async {
    return _fileService.deleteOrphanFiles();
  }

  @override
  Future<File> exportFile(int id) async {
    return _fileService.exportFile(id);
  }

  @override
  Future<void> shareImage(int id) async {
    await _fileService.shareImage(id);
  }

  @override
  Future<void> shareImages(List<int> ids) async {
    await _fileService.shareImages(ids);
  }

  @override
  Future<void> saveImageToDevice(int id) async {
    await _fileService.saveImageToDevice(id);
  }

  @override
  Future<void> saveImagesToDevice(List<int> ids) async {
    await _fileService.saveImagesToDevice(ids);
  }

  @override
  Stream<List<Receipt>> watchByFilters(ReceiptFilter filter) {
    return _searchService.watchByFilters(filter);
  }

  @override
  Stream<List<Receipt>> watchAll() => _searchService.watchAll();

  @override
  Future<int> reindexPendingSemanticEmbeddings() {
    return _semanticService.reindexPendingSemanticEmbeddings();
  }

  @override
  Future<String> diagnoseSemanticSearch(String query, {int limit = 10}) {
    return _semanticService.diagnoseSemanticSearch(query, limit: limit);
  }

  void _registerError(Object error, StackTrace? stackTrace) {
    _errorReporter?.record(error, stackTrace);
  }

  void _recordDiagnostic(String message) {
    _errorReporter?.recordDiagnostic(message);
  }
}
