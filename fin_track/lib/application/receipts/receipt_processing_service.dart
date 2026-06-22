import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/entities/extracted_data.dart';
import '../../domain/infrastructure/i_visual_code_service.dart';
import '../../domain/infrastructure/i_image_preprocessor_service.dart';
import '../../domain/infrastructure/i_image_service.dart';
import '../../domain/infrastructure/i_ocr_service.dart';
import '../../domain/value_objects/ocr_result.dart';
import '../../infrastructure/diagnostics/error_handling.dart';
import '../ocr/data_extractor_service.dart';
import '../ocr/financial_nature_classifier_service.dart';
import '../ocr/ocr_processing_result.dart';

part 'receipt_processing_diagnostics.dart';
part 'receipt_processing_models.dart';

typedef ValidateFileSpaceCallback = Future<void> Function(File file);
typedef EnrichDataCallback = Future<ExtractedData> Function(ExtractedData data);
typedef NormalizeDataCallback = ExtractedData Function(ExtractedData data);
typedef SuggestCategoryCallback =
    Future<Category?> Function(String text, ExtractedData data);
typedef CategoryTextBuilder =
    String Function(
      String normalizedText,
      OcrProcessingResult processing,
      ExtractedData data,
    );
typedef ScheduleEnrichmentCallback = void Function(ExtractedData data);
typedef RegisterDiagnosticCallback = void Function(String message);
typedef RegisterErrorCallback =
    void Function(Object error, StackTrace stackTrace);

class ReceiptProcessingService {
  ReceiptProcessingService({
    IImagePreprocessorService? imagePreprocessor,
    IVisualCodeService? visualCode,
    required IOCRService ocr,
  }) : _imagePreprocessor = imagePreprocessor,
       _visualCode = visualCode,
       _ocr = ocr;

  static final _ocrLimiter = _AsyncSemaphore(2);
  static final _visualCodeLimiter = _AsyncSemaphore(2);
  static const _originalOcrFastPathScore = 90.0;

  final IImagePreprocessorService? _imagePreprocessor;
  final IVisualCodeService? _visualCode;
  final IOCRService _ocr;

  Future<File> preparePreviewFile(
    File image, {
    required IImageService images,
    required ValidateFileSpaceCallback validateSpace,
  }) async {
    validateFile(image);
    await validateSpace(image);
    return image;
  }

  Future<Receipt> processPreview(
    File image, {
    required IImageService images,
    required ValidateFileSpaceCallback validateSpace,
    required DataExtractorService dataExtractor,
    required FinancialNatureClassifierService natureClassifier,
    required EnrichDataCallback enrichByLocalFiscalCache,
    required EnrichDataCallback enrichByLocalCnpj,
    required NormalizeDataCallback normalizeEstablishment,
    required SuggestCategoryCallback suggestCategory,
    required CategoryTextBuilder categoryText,
    required ScheduleEnrichmentCallback scheduleRemoteEnrichment,
    required RegisterDiagnosticCallback recordDiagnostic,
    required RegisterErrorCallback registerError,
  }) async {
    final file = await preparePreviewFile(
      image,
      images: images,
      validateSpace: validateSpace,
    );

    try {
      final totalWatch = Stopwatch()..start();
      final preprocessingWatch = Stopwatch();
      final originalVariant = OcrImageVariant(name: 'original', file: file);
      final codesWatch = Stopwatch();
      final ocrWatch = Stopwatch()..start();
      final originalOcr = await processOcrVariant(originalVariant);
      ocrWatch.stop();
      var ocrVariants = <OcrImageVariant>[originalVariant];
      var bestOcr = originalOcr;
      var visualCodes = const <String>[];

      if (!shouldKeepOriginalOcr(originalOcr)) {
        preprocessingWatch.start();
        ocrVariants = await generateVariantsForOcr(file);
        preprocessingWatch.stop();

        codesWatch.start();
        visualCodes = await readVisualCodes(
          ocrVariants.map((variant) => variant.file).toList(),
        );
        codesWatch.stop();

        ocrWatch.start();
        bestOcr = await processBestOcrVariant(
          ocrVariants,
          knownResults: [originalOcr],
        );
        ocrWatch.stop();
      } else {
        codesWatch.start();
        visualCodes = await readVisualCodes([file]);
        codesWatch.stop();
      }

      final ocrResult = bestOcr.result;
      final qualityWatch = Stopwatch()..start();
      final imageQuality = qualityWithCodes(
        await analyzeImageQuality(file, visualCodes),
        visualCodes,
      );
      qualityWatch.stop();
      final extractionWatch = Stopwatch()..start();
      final processing = dataExtractor.processResult(
        ocrResult,
        codes: visualCodes,
      );
      extractionWatch.stop();
      final inferredEstablishment =
          processing.extractedData.establishment ??
          dataExtractor.extractEstablishment(ocrResult.text);
      final processedData = processing.extractedData.establishment == null
          ? processing.extractedData.copyWith(
              establishment: inferredEstablishment,
              establishmentConfidence: inferredEstablishment == null
                  ? null
                  : processing.extractionConfidence * 0.8,
            )
          : processing.extractedData;
      final fiscalCacheWatch = Stopwatch()..start();
      final fiscalCacheData = await enrichByLocalFiscalCache(processedData);
      fiscalCacheWatch.stop();
      final cnpjWatch = Stopwatch()..start();
      final cnpjData = await enrichByLocalCnpj(fiscalCacheData);
      cnpjWatch.stop();
      final enrichedData = normalizeEstablishment(
        cnpjData
            .copyWith(
              qualityMetadata: ocrQualityMetadata(
                imageQuality,
                bestOcr,
                ocrVariants,
              ),
            )
            .withNormalizedEstablishment(),
      );
      final categoryWatch = Stopwatch()..start();
      final suggestedCategory = await suggestCategory(
        categoryText(processing.normalizedText, processing, enrichedData),
        enrichedData,
      );
      categoryWatch.stop();
      final nature = natureClassifier.infer(
        originalText: processing.originalText,
        normalizedText: processing.normalizedText,
        type: processing.type,
        data: enrichedData,
        categories: suggestedCategory == null
            ? const <Category>[]
            : <Category>[suggestedCategory],
      );
      final now = DateTime.now();
      scheduleRemoteEnrichment(enrichedData);

      final base = Receipt(
        id: 0,
        type: processing.type,
        expense: nature.expense,
        fileName: file.path,
        fileType: fileType(file.path),
        fileHash: await hashSha256(file),
        fileSize: file.lengthSync(),
        extractedContent: processing.originalText,
        registeredAt: now,
        extractedData: enrichedData,
        category: suggestedCategory,
      );
      totalWatch.stop();
      recordDiagnostic(
        [
          'pipeline=ocr',
          'ocrProvider=${ocrResult.provider}',
          'visualCodes=${visualCodes.length}',
          'fiscalLookup=background',
          'cnpjLookup=${enrichedData.issuerLegalName == null ? 'local_miss' : 'local_hit'}',
          'ocrConfidence=${ocrResult.confidence.toStringAsFixed(2)}',
          'ocrVariant=${bestOcr.variant.name}',
          'ocrVariantScore=${bestOcr.score.toStringAsFixed(2)}',
          'parser=${processing.parser}',
          'extractionConfidence=${processing.extractionConfidence.toStringAsFixed(2)}',
          'embedding=deferred',
          'preprocessing=${bestOcr.variant.file.path == file.path ? 'skipped' : 'applied'}',
          'ocrVariants=${ocrVariants.length}',
          'originalOcrScore=${originalOcr.score.toStringAsFixed(2)}',
          'sharpness=${imageQuality.sharpness.toStringAsFixed(2)}',
          'contrast=${imageQuality.contrast.toStringAsFixed(2)}',
          'originalFileKept=yes',
          'preprocessingTimeMs=${preprocessingWatch.elapsedMilliseconds}',
          'codesTimeMs=${codesWatch.elapsedMilliseconds}',
          'qualityTimeMs=${qualityWatch.elapsedMilliseconds}',
          'fiscalLookupTimeMs=${fiscalCacheWatch.elapsedMilliseconds}',
          'cnpjLookupTimeMs=${cnpjWatch.elapsedMilliseconds}',
          'ocrTimeMs=${ocrWatch.elapsedMilliseconds}',
          'extractionTimeMs=${extractionWatch.elapsedMilliseconds}',
          'categoryTimeMs=${categoryWatch.elapsedMilliseconds}',
          'embeddingTimeMs=0',
          'totalTimeMs=${totalWatch.elapsedMilliseconds}',
        ].join(' '),
      );
      await discardTemporaryVariants(ocrVariants);
      return base;
    } catch (error, stackTrace) {
      registerError(error, stackTrace);
      rethrow;
    }
  }

  String fileType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return 'application/pdf';
    }
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return 'image/heic';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return 'text/plain';
  }

  Future<String> hashSha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<List<String>> readVisualCodes(List<File> files) async {
    final reader = _visualCode;
    if (reader == null) {
      return const [];
    }
    final results = await Future.wait(
      files.map((file) async {
        return fallbackOnFailure(
          () => _visualCodeLimiter.run(() => reader.readCodes(file)),
          fallback: const <String>[],
          diagnosticContext: 'Falha ao ler códigos visuais do comprovante',
        );
      }),
    );
    final codes = results.expand((codes) => codes).toSet();
    return codes.toList();
  }

  bool shouldKeepOriginalOcr(OcrVariantResult result) {
    return result.result.confidence >=
            OcrResult.acceptableConfidenceThreshold &&
        result.score >= _originalOcrFastPathScore;
  }

  Future<List<OcrImageVariant>> generateVariantsForOcr(File file) async {
    final preprocessor = _imagePreprocessor;
    if (preprocessor == null) {
      return <OcrImageVariant>[OcrImageVariant(name: 'original', file: file)];
    }
    final variants = await fallbackOnFailure<List<OcrImageVariant>?>(
      () async {
        await preprocessor.cleanOldTemporaryFiles();
        final variants = await preprocessor.generateVariants(file);
        if (variants.isEmpty) {
          return <OcrImageVariant>[
            OcrImageVariant(name: 'original', file: file),
          ];
        }
        return variants;
      },
      fallback: null,
      diagnosticContext: 'Falha ao preparar variantes para OCR',
    );
    if (variants != null) {
      return variants;
    }

    final preprocessed = await fallbackOnFailure<OcrImageVariant?>(
      () async {
        final preprocessed = await preprocessor.preprocess(file);
        if (preprocessed.path == file.path) {
          return null;
        }
        return OcrImageVariant(
          name: 'preprocessada',
          file: preprocessed,
          temporary: true,
        );
      },
      fallback: null,
      diagnosticContext: 'Falha ao preparar imagem preprocessada para OCR',
    );
    return <OcrImageVariant>[
      OcrImageVariant(name: 'original', file: file),
      ?preprocessed,
    ];
  }

  Future<OcrImageQuality> analyzeImageQuality(
    File file,
    List<String> visualCodes,
  ) async {
    final preprocessor = _imagePreprocessor;
    if (preprocessor == null) {
      return fallbackQuality(file, visualCodes);
    }
    return fallbackOnFailure(
      () => preprocessor.analyzeQuality(
        file,
        hasQrCode: visualCodes.any((codigo) => codigo.startsWith('http')),
        hasBarcode: visualCodes.isNotEmpty,
      ),
      fallback: await fallbackQuality(file, visualCodes),
      diagnosticContext: 'Falha ao analisar qualidade da imagem do comprovante',
    );
  }

  Future<OcrVariantResult> processBestOcrVariant(
    List<OcrImageVariant> variants, {
    List<OcrVariantResult> knownResults = const <OcrVariantResult>[],
  }) async {
    final knownByPath = <String, OcrVariantResult>{
      for (final result in knownResults) result.variant.file.path: result,
    };
    final results = await Future.wait(
      variants.map((variant) async {
        final known = knownByPath[variant.file.path];
        if (known != null) {
          return known;
        }
        return processOcrVariant(variant);
      }),
    );
    return results.reduce(
      (best, candidato) => candidato.score > best.score ? candidato : best,
    );
  }

  Future<OcrVariantResult> processOcrVariant(OcrImageVariant variant) async {
    final result = await _ocrLimiter.run(() => _ocr.process(variant.file));
    final score = scoreOcrResult(result.text, result.confidence);
    return OcrVariantResult(variant: variant, result: result, score: score);
  }

  Future<OcrImageQuality> fallbackQuality(
    File file,
    List<String> visualCodes,
  ) async {
    return OcrImageQuality(
      width: 0,
      height: 0,
      sizeBytes: await file.exists() ? await file.length() : 0,
      sharpness: 0,
      contrast: 0,
      brightness: 0,
      orientationDegrees: 0,
      hasQrCode: visualCodes.any((codigo) => codigo.startsWith('http')),
      hasBarcode: visualCodes.isNotEmpty,
    );
  }

  OcrImageQuality qualityWithCodes(
    OcrImageQuality quality,
    List<String> visualCodes,
  ) {
    return OcrImageQuality(
      width: quality.width,
      height: quality.height,
      sizeBytes: quality.sizeBytes,
      sharpness: quality.sharpness,
      contrast: quality.contrast,
      brightness: quality.brightness,
      orientationDegrees: quality.orientationDegrees,
      hasQrCode: visualCodes.any((codigo) => codigo.startsWith('http')),
      hasBarcode: visualCodes.isNotEmpty,
    );
  }
}
