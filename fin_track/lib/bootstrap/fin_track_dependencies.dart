import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../application/backup/backup_service.dart';
import '../application/categories/category_service.dart';
import '../application/config/app_config.dart';
import '../application/configuration/configuration_service.dart';
import '../application/ocr/data_extractor_service.dart';
import '../application/ocr/financial_nature_classifier_service.dart';
import '../application/receipts/batch/receipt_batch_import_service.dart';
import '../application/receipts/receipt_service.dart';
import '../application/receipts/semantic/receipt_semantic_indexer.dart';
import '../infrastructure/category/cached_category_preference_service.dart';
import '../domain/infrastructure/i_category_preference_service.dart';
import '../domain/infrastructure/i_backup_scheduler.dart';
import '../domain/infrastructure/i_receipt_batch_scheduler.dart';
import '../domain/infrastructure/i_semantic_index_scheduler.dart';
import '../domain/infrastructure/i_cloud_storage.dart';
import '../domain/infrastructure/i_cnpj_lookup_service.dart';
import '../domain/infrastructure/i_document_scanner_service.dart';
import '../domain/infrastructure/i_embedding_service.dart';
import '../domain/infrastructure/i_fiscal_document_lookup_service.dart';
import '../domain/infrastructure/i_image_preprocessor_service.dart';
import '../domain/infrastructure/i_local_authentication_service.dart';
import '../domain/infrastructure/i_problem_report_service.dart';
import '../domain/infrastructure/i_secure_secrets.dart';
import '../domain/infrastructure/i_visual_code_service.dart';
import '../domain/services/i_backup_service.dart';
import '../domain/services/i_category_service.dart';
import '../domain/services/i_configuration_service.dart';
import '../domain/services/i_receipt_service.dart';
import '../infrastructure/cryptography/aes256_service.dart';
import '../infrastructure/backup/android_backup_scheduler.dart';
import '../infrastructure/database/app_database.dart';
import '../infrastructure/database/backup_repository.dart';
import '../infrastructure/database/category_repository.dart';
import '../infrastructure/database/configuration_repository.dart';
import '../infrastructure/database/receipt_batch_import_repository.dart';
import '../infrastructure/database/repositories/receipt_repository.dart';
import '../infrastructure/database/semantic_index_task_repository.dart';
import '../infrastructure/diagnostics/fin_track_error_log.dart';
import '../infrastructure/diagnostics/fin_track_problem_report_service.dart';
import '../infrastructure/embedding/distiluse_multilingual_service.dart';
import '../infrastructure/company/brasil_api_cnpj_service.dart';
import '../infrastructure/company/cached_cnpj_lookup_service.dart';
import '../infrastructure/fiscal/cached_fiscal_document_service.dart';
import '../infrastructure/fiscal/fiscal_document_lookup_service.dart';
import '../infrastructure/image/image_service.dart';
import '../infrastructure/image/image_preprocessor_service.dart';
import '../infrastructure/receipts/android_receipt_batch_scheduler.dart';
import '../infrastructure/semantic/android_semantic_index_scheduler.dart';
import '../infrastructure/cloud/google_drive_service.dart';
import '../infrastructure/ocr/google_mlkit_visual_code_service.dart';
import '../infrastructure/ocr/google_mlkit_service.dart';
import '../infrastructure/scanner/mlkit_document_scanner_service.dart';
import '../infrastructure/security/flutter_secure_secrets.dart';
import '../infrastructure/security/fin_track_local_authentication_service.dart';
import '../infrastructure/security/memory_secure_secrets.dart';

class FinTrackDependencies {
  FinTrackDependencies._({
    required this.database,
    required this.receiptService,
    required this.categoryService,
    required this.backupService,
    required this.receiptBatchImportService,
    required this.configurationService,
    required this.localAuthenticationService,
    required this.problemReportService,
    required this.cloudStorageRegistry,
    required this.appConfig,
  });

  factory FinTrackDependencies.local({
    AppDatabase? database,
    Directory? imagesDirectory,
    ICloudStorage? cloud,
    IDocumentScannerService? scanner,
    IEmbeddingService? embeddings,
    IImagePreprocessorService? imagePreprocessor,
    IVisualCodeService? visualCode,
    ICnpjLookupService? cnpjLookup,
    IFiscalDocumentLookupService? fiscalDocumentLookup,
    ICategoryPreferenceService? categoryPreference,
    IBackupScheduler? backupScheduler,
    IReceiptBatchScheduler? receiptBatchScheduler,
    ISemanticIndexScheduler? semanticIndexScheduler,
    ISecureSecrets? secrets,
    ILocalAuthenticationService? localAuthentication,
    IProblemReportService? problemReport,
    IReceiptService? receiptServiceOverride,
    IBackupService? backupServiceOverride,
    IConfigurationService? configurationServiceOverride,
    ReceiptBatchImportService? receiptBatchImportServiceOverride,
    AppConfig? appConfig,
  }) {
    final resolvedDatabase = database ?? AppDatabase.memory();
    final resolvedSecrets = secrets ?? MemorySecureSecrets();
    final images = ImageService(baseDirectory: imagesDirectory);
    final resolvedCloud = cloud ?? GoogleDriveService.simulated();
    final cloudRegistry = SingleCloudStorageRegistry(resolvedCloud);
    const errorReporter = FinTrackErrorReporter();
    const defaultPlatformServices = FinTrackLocalAuthenticationService();
    const defaultProblemReport = FinTrackProblemReportService();
    final resolvedEmbeddings =
        embeddings ??
        DistilUseMultilingualService(errorReporter: errorReporter);
    final resolvedAppConfig = appConfig ?? AppConfig.defaults;
    final resolvedScanner = scanner ?? MLKitDocumentScannerService();
    final preprocessingDirectory = imagesDirectory == null
        ? Directory(p.join(Directory.systemTemp.path, 'fintrack', 'tmp_ocr'))
        : Directory(p.join(imagesDirectory.parent.path, 'tmp_ocr'));
    final resolvedImagePreprocessor =
        imagePreprocessor ??
        ImagePreprocessorService(temporaryDirectory: preprocessingDirectory);
    final receipts = ReceiptRepository(resolvedDatabase);
    final categories = CategoryRepository(resolvedDatabase);
    final configurations = ConfigurationRepository(
      resolvedDatabase,
      secrets: resolvedSecrets,
    );
    final backups = BackupRepository(resolvedDatabase);
    final batchImports = ReceiptBatchImportRepository(resolvedDatabase);
    final semanticTasks = SemanticIndexTaskRepository(resolvedDatabase);
    const natureClassifier = FinancialNatureClassifierService();
    final configurationService =
        configurationServiceOverride ??
        ConfigurationService(
          configurations: configurations,
          cloudRegistry: cloudRegistry,
          images: images,
          scheduler: backupScheduler ?? const NoopBackupScheduler(),
        );
    final receiptService =
        receiptServiceOverride ??
        ReceiptService(
          receipts: receipts,
          semanticTasks: semanticTasks,
          categories: categories,
          images: images,
          scanner: resolvedScanner,
          imagePreprocessor: resolvedImagePreprocessor,
          visualCode: visualCode ?? GoogleMLKitVisualCodeService(),
          cnpjLookup:
              cnpjLookup ??
              CachedCnpjLookupService(
                database: resolvedDatabase,
                remote: BrasilApiCnpjService(),
              ),
          fiscalDocumentLookup:
              fiscalDocumentLookup ?? FiscalDocumentLookupService(),
          fiscalDocumentCache: CachedFiscalDocumentService(
            database: resolvedDatabase,
          ),
          categoryPreference:
              categoryPreference ??
              CachedCategoryPreferenceService(database: resolvedDatabase),
          ocr: GoogleMLKitService(),
          embeddings: resolvedEmbeddings,
          configuration: configurationService,
          dataExtractor: DataExtractorService(),
          natureClassifier: natureClassifier,
          semanticIndexer: ReceiptSemanticIndexer(
            embeddings: resolvedEmbeddings,
          ),
          semanticIndexScheduler:
              semanticIndexScheduler ?? const NoopSemanticIndexScheduler(),
          errorReporter: errorReporter,
        );
    final categoryService = CategoryService(categories);
    final receiptBatchImportService =
        receiptBatchImportServiceOverride ??
        ReceiptBatchImportService(
          repository: batchImports,
          receiptService: receiptService,
          scheduler: receiptBatchScheduler ?? const NoopReceiptBatchScheduler(),
        );

    final dependencies = FinTrackDependencies._(
      database: resolvedDatabase,
      receiptService: receiptService,
      categoryService: categoryService,
      backupService:
          backupServiceOverride ??
          BackupService(
            receipts: receipts,
            backups: backups,
            configurations: configurations,
            cryptography: AES256Service(),
            cloudRegistry: cloudRegistry,
            images: images,
            errorReporter: errorReporter,
          ),
      receiptBatchImportService: receiptBatchImportService,
      configurationService: configurationService,
      localAuthenticationService:
          localAuthentication ?? defaultPlatformServices,
      problemReportService: problemReport ?? defaultProblemReport,
      cloudStorageRegistry: cloudRegistry,
      appConfig: resolvedAppConfig,
    );

    return dependencies;
  }

  static Future<FinTrackDependencies> persistent() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(
      p.join(documentsDir.path, 'fintrack', 'receipts'),
    );
    final secrets = FlutterSecureSecrets();
    return FinTrackDependencies.local(
      database: AppDatabase(),
      imagesDirectory: imageDir,
      secrets: secrets,
      cloud: GoogleDriveService(),
      backupScheduler: const AndroidBackupScheduler(),
      receiptBatchScheduler: const AndroidReceiptBatchScheduler(),
      semanticIndexScheduler: const AndroidSemanticIndexScheduler(),
      appConfig: await AppConfig.loadFromAsset(),
    );
  }

  final AppDatabase database;
  final IReceiptService receiptService;
  final ICategoryService categoryService;
  final IBackupService backupService;
  final ReceiptBatchImportService receiptBatchImportService;
  final IConfigurationService configurationService;
  final ILocalAuthenticationService localAuthenticationService;
  final IProblemReportService problemReportService;
  final ICloudStorageRegistry cloudStorageRegistry;
  final AppConfig appConfig;

  void dispose() {
    database.close();
  }
}
