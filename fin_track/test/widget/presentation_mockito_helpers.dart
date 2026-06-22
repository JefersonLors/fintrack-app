import 'dart:io';

import 'package:fin_track/application/config/app_config.dart';
import 'package:fin_track/application/receipts/batch/receipt_batch_import_service.dart';
import 'package:fin_track/bootstrap/fin_track_dependencies.dart';
import 'package:fin_track/domain/entities/category.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/entities/configuration.dart';
import 'package:fin_track/domain/entities/company_data.dart';
import 'package:fin_track/domain/entities/extracted_data.dart';
import 'package:fin_track/domain/entities/backup_record.dart';
import 'package:fin_track/domain/infrastructure/i_local_authentication_service.dart';
import 'package:fin_track/domain/infrastructure/i_cnpj_lookup_service.dart';
import 'package:fin_track/domain/infrastructure/i_embedding_service.dart';
import 'package:fin_track/domain/services/i_backup_service.dart';
import 'package:fin_track/domain/services/i_receipt_service.dart';
import 'package:fin_track/domain/services/i_configuration_service.dart';
import 'package:fin_track/domain/value_objects/embedding_vector.dart';
import 'package:fin_track/domain/value_objects/receipt_filter.dart';
import 'package:fin_track/presentation/receipts/pages/receipt_batch_review_page.dart';
import 'package:fin_track/presentation/theme/fin_track_theme.dart';
import 'package:fin_track/presentation/widgets/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'presentation_mocks.dart';

Widget testHost(FinTrackDependencies dependencies, Widget child) {
  return AppScope(
    dependencies: dependencies,
    child: MaterialApp(theme: FinTrackTheme.light(), home: child),
  );
}

FinTrackDependencies testDependencies(
  IReceiptService service, {
  IBackupService? backupService,
  IConfigurationService? configurationService,
  ILocalAuthenticationService? localAuthService,
  ReceiptBatchImportService? receiptBatchImportService,
  bool debugMode = false,
}) {
  return FinTrackDependencies.local(
    embeddings: const TestEmbeddingService(),
    cnpjLookup: const TestCnpjLookupService(),
    receiptServiceOverride: service,
    backupServiceOverride: backupService,
    configurationServiceOverride: configurationService,
    receiptBatchImportServiceOverride: receiptBatchImportService,
    localAuthentication: localAuthService,
    appConfig: debugMode
        ? AppConfig.fromJson({'version': 1, 'debugMode': true})
        : AppConfig.defaults,
  );
}

Receipt testReceipt({
  int id = 0,
  String fileName = 'receipt.txt',
  Category? category,
  bool expense = true,
  double amount = 42.5,
  DateTime? data,
}) {
  return Receipt(
    id: id,
    type: ReceiptType.receipt,
    expense: expense,
    fileName: fileName,
    fileType: 'text/plain',
    extractedContent: 'Compra no Mercado Modelo',
    registeredAt: DateTime(2026, 5, 22, 10),
    extractedData: ExtractedData(
      id: id,
      receiptId: id,
      amount: amount,
      transactionDate: data ?? DateTime(2026, 5, 20),
      establishment: 'Mercado Modelo',
      paymentMethod: 'Pix',
      ocrConfidence: 0.95,
      valueConfidence: 0.95,
      dateConfidence: 0.95,
      establishmentConfidence: 0.95,
      paymentMethodConfidence: 0.95,
    ),
    category: category,
  );
}

ReceiptBatchItem testReadyBatch(File file, int number, Receipt receipt) {
  return ReceiptBatchItem(file: file, number: number)
    ..status = ReceiptBatchItemStatus.ready
    ..receipt = receipt;
}

Configuration testConfigBackup() {
  return Configuration(
    id: 1,
    linkedCloudAccount: 'account@fintrack.test',
    cloudTokenValid: true,
    backupPassword: 'password-segura',
  );
}

BackupRecord testBackupRecord() {
  return BackupRecord(
    id: 1,
    createdAt: DateTime(2026, 5, 22, 10),
    status: BackupStatus.synced,
    totalReceipts: 3,
    configurationId: 1,
    linkedCloudAccount: 'account@fintrack.test',
    availability: BackupAvailability.active,
  );
}

Configuration testShellConfig() {
  return const Configuration(id: 1, onboardingCompleted: true);
}

void stubReceiptList(
  MockIReceiptService service, {
  List<Receipt> receipts = const <Receipt>[],
}) {
  when(service.watchByFilters(any)).thenAnswer((_) => Stream.value(receipts));
  when(service.findByFilters(any)).thenAnswer((invocation) async {
    final filter = invocation.positionalArguments.first as ReceiptFilter;
    if (filter.limit == null) {
      return receipts;
    }
    return receipts.skip(filter.offset ?? 0).take(filter.limit!).toList();
  });
  when(service.watchAll()).thenAnswer((_) => Stream.value(receipts));
}

void stubReceiptSearch(
  MockIReceiptService service, {
  List<Receipt> searchResults = const <Receipt>[],
}) {
  when(service.search(any)).thenAnswer((_) async => searchResults);
}

void stubReceiptListPage(
  MockIReceiptService service, {
  List<Receipt> receipts = const <Receipt>[],
  List<Receipt>? searchResults,
}) {
  stubReceiptList(service, receipts: receipts);
  stubReceiptSearch(service, searchResults: searchResults ?? receipts);
}

void stubReceiptStorage(
  MockIReceiptService service, {
  int orphanFilesRemoved = 0,
}) {
  when(service.deleteOrphanFiles()).thenAnswer((_) async => orphanFilesRemoved);
}

void stubShellList(MockIReceiptService service) {
  stubReceiptList(service);
}

File tempFile(String name) {
  final file = File(
    '${Directory.systemTemp.path}/fintrack_mockito_${DateTime.now().microsecondsSinceEpoch}_$name',
  );
  file.writeAsStringSync('test receipt');
  return file;
}

void deleteFile(File file) {
  if (file.existsSync()) {
    file.deleteSync();
  }
}

Future<void> disposeTestApp(
  WidgetTester tester,
  FinTrackDependencies dependencies,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
  await dependencies.database.close();
  await tester.pump(const Duration(milliseconds: 1));
}

Future<void> pumpIo(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  });
  await tester.pump();
}

class TestEmbeddingService implements IEmbeddingService {
  const TestEmbeddingService();

  @override
  Future<EmbeddingVector> generate(String text) async {
    return EmbeddingVector(
      vector: List<double>.filled(8, 0),
      model: 'widget-mockito-test',
      dimension: 8,
    );
  }
}

class TestCnpjLookupService implements ICnpjLookupService {
  const TestCnpjLookupService();

  @override
  Future<CompanyData?> lookup(String cnpj) async => null;
}
