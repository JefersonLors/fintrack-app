import 'dart:async';
import 'dart:io';

import 'package:fin_track/application/receipts/batch/batch_staging_service.dart';
import 'package:fin_track/application/backup/background_backup_entrypoint.dart';
import 'package:fin_track/application/receipts/batch/background_receipt_batch_entrypoint.dart';
import 'package:fin_track/application/receipts/batch/receipt_batch_codec.dart';
import 'package:fin_track/application/receipts/batch/receipt_batch_import_service.dart';
import 'package:fin_track/application/receipts/batch/receipt_batch_state.dart';
import 'package:fin_track/application/receipts/semantic/background_semantic_index_entrypoint.dart';
import 'package:fin_track/application/receipts/semantic/receipt_semantic_indexer.dart';
import 'package:fin_track/application/use_cases/process_receipt_batch_use_case.dart';
import 'package:fin_track/bootstrap/fin_track_dependencies.dart';
import 'package:fin_track/domain/entities/category.dart';
import 'package:fin_track/domain/entities/cloud_provider.dart';
import 'package:fin_track/domain/entities/extracted_data.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/entities/receipt_batch_import.dart';
import 'package:fin_track/domain/entities/semantic_index_task.dart';
import 'package:fin_track/domain/infrastructure/i_backup_scheduler.dart';
import 'package:fin_track/domain/infrastructure/i_embedding_service.dart';
import 'package:fin_track/domain/infrastructure/i_receipt_batch_scheduler.dart';
import 'package:fin_track/domain/repositories/i_receipt_batch_import_repository.dart';
import 'package:fin_track/domain/repositories/i_semantic_index_task_repository.dart';
import 'package:fin_track/domain/services/i_receipt_service.dart';
import 'package:fin_track/domain/value_objects/embedding_vector.dart';
import 'package:fin_track/infrastructure/backup/android_backup_scheduler.dart';
import 'package:fin_track/infrastructure/database/receipt_batch_import_repository.dart';
import 'package:fin_track/infrastructure/receipts/android_receipt_batch_scheduler.dart';
import 'package:fin_track/infrastructure/semantic/android_semantic_index_scheduler.dart';
import 'package:fin_track/main.dart' as app;
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Android schedulers', () {
    const channel = MethodChannel('fin_track/native');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
    });

    test(
      'delegate backup, receipt batch and semantic scheduling to platform',
      () async {
        final calls = <MethodCall>[];
        messenger.setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });

        const backup = AndroidBackupScheduler();
        const batch = AndroidReceiptBatchScheduler();
        const semantic = AndroidSemanticIndexScheduler();

        expect(await backup.scheduleAutomaticBackup(intervalDays: 3), isTrue);
        expect(await backup.cancelAutomaticBackup(), isTrue);
        expect(await backup.runNowForTesting(), isTrue);
        expect(await batch.schedulePendingBatchImports(), isTrue);
        expect(await batch.cancelPendingBatchImports(), isTrue);
        expect(await semantic.schedulePendingSemanticIndex(), isTrue);
        expect(await semantic.cancelPendingSemanticIndex(), isTrue);

        expect(calls.map((call) => call.method), [
          'scheduleAutomaticBackup',
          'cancelAutomaticBackup',
          'runAutomaticBackupNowForTesting',
          'schedulePendingBatchImports',
          'cancelPendingBatchImports',
          'schedulePendingSemanticIndex',
          'cancelPendingSemanticIndex',
        ]);
        expect(calls.first.arguments, {'intervalDays': 3});
      },
    );

    test('noop schedulers keep safe defaults', () async {
      const backup = NoopBackupScheduler();
      const batch = NoopReceiptBatchScheduler();

      expect(await backup.scheduleAutomaticBackup(intervalDays: 1), isTrue);
      expect(await backup.cancelAutomaticBackup(), isTrue);
      expect(await backup.runNowForTesting(), isFalse);
      expect(await batch.schedulePendingBatchImports(), isTrue);
      expect(await batch.cancelPendingBatchImports(), isTrue);
    });
  });

  group('Background backup entrypoint', () {
    test('reports skipped success when automatic backup is not due', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final temp = await Directory.systemTemp.createTemp(
        'fintrack_background_backup_',
      );
      addTearDown(() => _deleteDirectoryIfExists(temp));

      const backupChannel = MethodChannel('fin_track/background_backup');
      const pathProviderChannel = MethodChannel(
        'plugins.flutter.io/path_provider',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <MethodCall>[];

      messenger.setMockMethodCallHandler(backupChannel, (call) async {
        calls.add(call);
        return null;
      });
      messenger.setMockMethodCallHandler(pathProviderChannel, (call) async {
        return temp.path;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(backupChannel, null);
        messenger.setMockMethodCallHandler(pathProviderChannel, null);
      });

      await app.finTrackBackgroundBackupDispatcher();

      expect(calls.map((call) => call.method), ['backgroundBackupFinished']);
      expect(calls.single.arguments, {
        'success': true,
        'skipped': true,
        'retryable': false,
        'message': null,
      });
    });

    test('reports non retryable automatic backup failure', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final temp = await Directory.systemTemp.createTemp(
        'fintrack_background_backup_failure_',
      );
      addTearDown(() => _deleteDirectoryIfExists(temp));

      const backupChannel = MethodChannel('fin_track/background_backup');
      const pathProviderChannel = MethodChannel(
        'plugins.flutter.io/path_provider',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <MethodCall>[];

      messenger.setMockMethodCallHandler(pathProviderChannel, (call) async {
        return temp.path;
      });

      final dependencies = await FinTrackDependencies.persistent();
      final configuration = await dependencies.configurationService.load();
      await dependencies.configurationService.update(
        configuration.copyWith(
          backupReminderEnabled: true,
          backupPassword: 'segredo123',
          clearCloudAccount: true,
        ),
      );
      dependencies.dispose();

      messenger.setMockMethodCallHandler(backupChannel, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(backupChannel, null);
        messenger.setMockMethodCallHandler(pathProviderChannel, null);
      });

      await runFinTrackBackgroundBackup();

      expect(calls.map((call) => call.method), ['backgroundBackupFinished']);
      expect(calls.single.arguments, {
        'success': false,
        'skipped': false,
        'retryable': false,
        'message': contains('Conta de nuvem não vinculada'),
      });
    });

    test('reports startup failure as retryable', () async {
      const backupChannel = MethodChannel('fin_track/background_backup');
      const pathProviderChannel = MethodChannel(
        'plugins.flutter.io/path_provider',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <MethodCall>[];

      messenger.setMockMethodCallHandler(backupChannel, (call) async {
        calls.add(call);
        return null;
      });
      messenger.setMockMethodCallHandler(pathProviderChannel, (call) async {
        throw StateError('sem diretorio');
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(backupChannel, null);
        messenger.setMockMethodCallHandler(pathProviderChannel, null);
      });

      await runFinTrackBackgroundBackup();

      expect(calls.map((call) => call.method), ['backgroundBackupFinished']);
      expect(calls.single.arguments, {
        'success': false,
        'skipped': false,
        'retryable': true,
        'message': 'Não foi possível executar o backup automático.',
      });
    });
  });

  group('Background receipt batch entrypoint', () {
    test('reports success when pending sessions are processed', () async {
      final temp = await Directory.systemTemp.createTemp(
        'fintrack_background_batch_',
      );
      addTearDown(() => _deleteDirectoryIfExists(temp));

      const batchChannel = MethodChannel('fin_track/background_receipt_batch');
      const pathProviderChannel = MethodChannel(
        'plugins.flutter.io/path_provider',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <MethodCall>[];

      messenger.setMockMethodCallHandler(batchChannel, (call) async {
        calls.add(call);
        return null;
      });
      messenger.setMockMethodCallHandler(pathProviderChannel, (call) async {
        return temp.path;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(batchChannel, null);
        messenger.setMockMethodCallHandler(pathProviderChannel, null);
      });

      final files = await _files(['batch_original.txt', 'batch_staged.txt']);
      final stagingDirectory = Directory('${temp.path}/staging')
        ..createSync(recursive: true);
      final seedDependencies = await FinTrackDependencies.persistent();
      final seedRepository = ReceiptBatchImportRepository(
        seedDependencies.database,
      );
      final sessionId = await seedRepository.createSession(
        stagingDirectory: stagingDirectory,
        originalFiles: [files.first],
        stagedFiles: [files.last],
      );
      final seededSnapshot = await seedRepository.findSnapshot(sessionId);
      await seedRepository.markItemReady(
        seededSnapshot!.items.single.id,
        _receipt(fileName: files.last.path),
      );
      await seedDependencies.database.close();

      await app.finTrackBackgroundReceiptBatchDispatcher();

      expect(calls.map((call) => call.method), [
        'backgroundReceiptBatchFinished',
      ]);
      expect(calls.single.arguments, {'success': true, 'message': null});

      final verifyDependencies = await FinTrackDependencies.persistent();
      addTearDown(() async => verifyDependencies.database.close());
      final processedSnapshot = await ReceiptBatchImportRepository(
        verifyDependencies.database,
      ).findSnapshot(sessionId);
      expect(
        processedSnapshot?.session.status,
        ReceiptBatchImportStatus.review,
      );
    });

    test('reports startup failure to platform', () async {
      const batchChannel = MethodChannel('fin_track/background_receipt_batch');
      const pathProviderChannel = MethodChannel(
        'plugins.flutter.io/path_provider',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <MethodCall>[];

      messenger.setMockMethodCallHandler(batchChannel, (call) async {
        calls.add(call);
        return null;
      });
      messenger.setMockMethodCallHandler(pathProviderChannel, (call) async {
        throw StateError('sem diretorio');
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(batchChannel, null);
        messenger.setMockMethodCallHandler(pathProviderChannel, null);
      });

      await runFinTrackBackgroundReceiptBatchImport();

      expect(calls.map((call) => call.method), [
        'backgroundReceiptBatchFinished',
      ]);
      expect(calls.single.arguments, {
        'success': false,
        'message': 'Não foi possível processar a importação em lote.',
      });
    });
  });

  group('Batch staging and codec', () {
    test(
      'stages files with safe names and removes temporary originals',
      () async {
        final temp = await Directory.systemTemp.createTemp(
          'fintrack_stage_test_',
        );
        addTearDown(() => _deleteDirectoryIfExists(temp));
        final sharedDir = Directory('${temp.path}/shared_imports')
          ..createSync();
        final source = File('${sharedDir.path}/cupom fiscal @ mercado.txt')
          ..writeAsStringSync('conteudo');

        final result = await const BatchStagingService().stage([source]);
        addTearDown(() => _deleteDirectoryIfExists(result.directory));

        expect(result.directory.existsSync(), isTrue);
        expect(source.existsSync(), isFalse);
        expect(result.files.single.existsSync(), isTrue);
        expect(result.files.single.readAsStringSync(), 'conteudo');
        expect(
          result.files.single.path,
          contains('item_001_cupom_fiscal_mercado.txt'),
        );
      },
    );

    test('codec round trips receipt and handles empty or invalid payloads', () {
      final receipt = _receipt().copyWith(
        cloudSynced: true,
        fileHash: 'hash',
        fileSize: 42,
        extractedData: ExtractedData(
          id: 7,
          receiptId: 9,
          amount: 19.9,
          transactionDate: DateTime(2026, 5, 20),
          establishment: 'Mercado Modelo',
          items: const ['Arroz'],
          paymentMethod: 'Pix',
          issuerCnpj: '123',
          accessKey: 'chave',
          urlQrCode: 'https://qr.test',
          documentNumber: '55',
          documentSeries: '1',
          documentState: 'BA',
          issuerLegalName: 'Mercado Modelo LTDA',
          issuerTradeName: 'Mercado Modelo',
          fiscalCnaeDescription: 'Mercado',
          issuerCity: 'Salvador',
          issuerState: 'BA',
          ocrConfidence: 0.9,
          extractionParser: 'parser',
          extractionConfidence: 0.8,
          valueConfidence: 0.7,
          dateConfidence: 0.6,
          establishmentConfidence: 0.5,
          paymentMethodConfidence: 0.4,
          qualityMetadata: const {'sharpness': 1.0},
        ),
        category: const Category(
          id: 2,
          name: 'Alimentacao',
          description: 'Compras de mercado',
          inferredAutomatically: true,
          icon: 'shopping_cart',
          colorArgb: 0xFF00AA00,
        ),
      );

      final decoded = receiptBatchReceiptFromJsonString(
        receiptBatchReceiptToJsonString(receipt),
      );

      expect(decoded, isNotNull);
      expect(decoded!.id, receipt.id);
      expect(decoded.type, ReceiptType.receipt);
      expect(decoded.fileHash, 'hash');
      expect(decoded.fileSize, 42);
      expect(decoded.extractedData?.amount, 19.9);
      expect(decoded.extractedData?.items, ['Arroz']);
      expect(decoded.extractedData?.qualityMetadata, {'sharpness': 1.0});
      expect(decoded.category?.name, 'Alimentacao');
      expect(receiptBatchReceiptFromJsonString(null), isNull);
      expect(receiptBatchReceiptFromJsonString(''), isNull);
      expect(receiptBatchReceiptFromJsonString('[]'), isNull);
    });

    test('batch progress and import persisted values expose defaults', () {
      const empty = ReceiptBatchProgress(
        total: 0,
        processed: 0,
        pending: 0,
        errors: 0,
      );
      const partial = ReceiptBatchProgress(
        total: 4,
        processed: 1,
        pending: 2,
        errors: 1,
      );
      final item = ReceiptBatchItem(file: File('a.txt'), number: 3);

      expect(empty.progress, 0);
      expect(empty.isComplete, isTrue);
      expect(partial.progress, 0.25);
      expect(partial.isComplete, isFalse);
      expect(item.label, 'Item 3');
      expect(
        ReceiptBatchImportStatus.fromPersisted('REVISAO'),
        ReceiptBatchImportStatus.review,
      );
      expect(
        ReceiptBatchImportStatus.fromPersisted('x'),
        ReceiptBatchImportStatus.pending,
      );
      expect(
        ReceiptBatchImportItemStatus.fromPersisted('SALVO'),
        ReceiptBatchImportItemStatus.saved,
      );
      expect(
        ReceiptBatchImportItemStatus.fromPersisted('x'),
        ReceiptBatchImportItemStatus.pending,
      );
    });
  });

  group('ProcessReceiptBatchUseCase', () {
    test('stages files and processes previews until ready', () async {
      final files = await _files(['a', 'b']);
      final staged = await _files(['staged-a', 'staged-b']);
      final items = [
        ReceiptBatchItem(file: files[0], number: 1),
        ReceiptBatchItem(file: files[1], number: 2),
      ];
      final service = _FakeReceiptService();
      var changes = 0;

      final result =
          await ProcessReceiptBatchUseCase(
            concurrency: 1,
            stagingService: _FakeStagingService(stagedFiles: staged),
          ).call(
            items: items,
            service: service,
            onChanged: () => changes++,
            isCanceled: () => false,
          );

      expect(result.stagingDirectory, isNotNull);
      expect(
        items.map((item) => item.file.path),
        staged.map((file) => file.path),
      );
      expect(
        items.map((item) => item.status),
        everyElement(ReceiptBatchItemStatus.ready),
      );
      expect(items.map((item) => item.receipt?.fileName), [
        'staged-a',
        'staged-b',
      ]);
      expect(service.validated.length, 4);
      expect(changes, greaterThanOrEqualTo(4));
    });

    test(
      'marks all items as error when staging or storage validation fails',
      () async {
        final files = await _files(['a']);
        final items = [ReceiptBatchItem(file: files.single, number: 1)];

        await ProcessReceiptBatchUseCase(
          stagingService: _FakeStagingService(stageError: StateError('stage')),
        ).call(
          items: items,
          service: _FakeReceiptService(),
          onChanged: () {},
          isCanceled: () => false,
        );

        expect(items.single.status, ReceiptBatchItemStatus.error);
        expect(items.single.error, isA<StateError>());

        final staged = await _files(['staged-a']);
        final storageItems = [ReceiptBatchItem(file: files.single, number: 1)];
        Object? storageError;
        await ProcessReceiptBatchUseCase(
          stagingService: _FakeStagingService(stagedFiles: staged),
        ).call(
          items: storageItems,
          service: _FakeReceiptService(validateError: StateError('space')),
          onChanged: () {},
          isCanceled: () => false,
          onStorageLimit: (error) => storageError = error,
        );

        expect(storageItems.single.status, ReceiptBatchItemStatus.error);
        expect(storageError, isA<StateError>());
      },
    );

    test('stops on cancellation and discards unsaved preview', () async {
      final files = await _files(['a']);
      final staged = await _files(['staged-a']);
      final items = [ReceiptBatchItem(file: files.single, number: 1)];
      final service = _FakeReceiptService();
      var checks = 0;

      await ProcessReceiptBatchUseCase(
        concurrency: 1,
        stagingService: _FakeStagingService(stagedFiles: staged),
      ).call(
        items: items,
        service: service,
        onChanged: () {},
        isCanceled: () => ++checks >= 5,
      );

      expect(items.single.status, ReceiptBatchItemStatus.processing);
      expect(items.single.receipt, isNull);
      expect(service.discarded.map((receipt) => receipt.fileName), [
        'staged-a',
      ]);
    });

    test('returns early when canceled after staging', () async {
      final files = await _files(['a']);
      final staged = await _files(['staged-a']);
      final items = [ReceiptBatchItem(file: files.single, number: 1)];
      final service = _FakeReceiptService();

      final result =
          await ProcessReceiptBatchUseCase(
            stagingService: _FakeStagingService(stagedFiles: staged),
          ).call(
            items: items,
            service: service,
            onChanged: () {},
            isCanceled: () => true,
          );

      expect(result.stagingDirectory, isNotNull);
      expect(items.single.status, ReceiptBatchItemStatus.pending);
      expect(service.validated, isEmpty);
    });

    test('marks item error when preview processing fails', () async {
      final files = await _files(['a']);
      final staged = await _files(['staged-a']);
      final items = [ReceiptBatchItem(file: files.single, number: 1)];
      Object? capturedError;

      await ProcessReceiptBatchUseCase(
        concurrency: 1,
        stagingService: _FakeStagingService(stagedFiles: staged),
      ).call(
        items: items,
        service: _FakeReceiptService(
          processErrors: {staged.single.path: StateError('ocr')},
        ),
        onChanged: () {},
        isCanceled: () => false,
        onStorageLimit: (error) => capturedError = error,
      );

      expect(items.single.status, ReceiptBatchItemStatus.error);
      expect(items.single.error, isA<StateError>());
      expect(capturedError, isA<StateError>());
    });
  });

  group('Semantic helpers', () {
    test('domain persisted fallbacks use safe defaults', () {
      expect(
        CloudProvider.fromPersistedValue('DESCONHECIDO'),
        CloudProvider.googleDrive,
      );
      expect(
        SemanticIndexTaskStatus.fromPersisted('DESCONHECIDO'),
        SemanticIndexTaskStatus.pending,
      );
      final task = SemanticIndexTask(
        receiptId: 1,
        status: SemanticIndexTaskStatus.failed,
        attempts: 3,
        updatedAt: DateTime(2026, 5, 20),
        errorDescription: 'falha',
      );

      expect(task.receiptId, 1);
      expect(task.errorDescription, 'falha');
    });

    test(
      'background semantic entrypoint reports success to platform',
      () async {
        final temp = await Directory.systemTemp.createTemp(
          'fintrack_background_semantic_',
        );
        addTearDown(() => _deleteDirectoryIfExists(temp));

        const backgroundChannel = MethodChannel(
          'fin_track/background_semantic_index',
        );
        const pathProviderChannel = MethodChannel(
          'plugins.flutter.io/path_provider',
        );
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        final calls = <MethodCall>[];

        messenger.setMockMethodCallHandler(backgroundChannel, (call) async {
          calls.add(call);
          return null;
        });
        messenger.setMockMethodCallHandler(pathProviderChannel, (call) async {
          return temp.path;
        });
        addTearDown(() {
          messenger.setMockMethodCallHandler(backgroundChannel, null);
          messenger.setMockMethodCallHandler(pathProviderChannel, null);
        });

        await app.finTrackBackgroundSemanticIndexDispatcher();

        expect(calls.map((call) => call.method), [
          'backgroundSemanticIndexFinished',
        ]);
        expect(calls.single.arguments, {'success': true});
      },
    );

    test('background semantic entrypoint reports startup failure', () async {
      const backgroundChannel = MethodChannel(
        'fin_track/background_semantic_index',
      );
      const pathProviderChannel = MethodChannel(
        'plugins.flutter.io/path_provider',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <MethodCall>[];

      messenger.setMockMethodCallHandler(backgroundChannel, (call) async {
        calls.add(call);
        return null;
      });
      messenger.setMockMethodCallHandler(pathProviderChannel, (call) async {
        throw StateError('sem diretorio');
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(backgroundChannel, null);
        messenger.setMockMethodCallHandler(pathProviderChannel, null);
      });

      await runFinTrackBackgroundSemanticIndex();

      expect(calls.map((call) => call.method), [
        'backgroundSemanticIndexFinished',
      ]);
      expect(calls.single.arguments, {
        'success': false,
        'message': 'Não foi possível atualizar a busca semântica.',
      });
    });

    test(
      'in-memory semantic queue sorts, retries and resets stale work',
      () async {
        final repository = InMemorySemanticIndexTaskRepository();

        await repository.enqueueReceipts([2, 1, 0, -1, 2]);
        final first = await repository.claimNextPending();
        expect(first?.receiptId, 1);
        await repository.markFailed(first!.receiptId, StateError('retry'));
        expect(await repository.hasRunnableTasks(), isTrue);

        final retry = await repository.claimNextPending();
        expect(retry?.receiptId, 2);
        await repository.markFailed(retry!.receiptId, StateError('retry'));
        await repository.markFailed(retry.receiptId, StateError('retry'));
        await repository.markFailed(retry.receiptId, StateError('failed'));
        expect(await repository.hasRunnableTasks(), isTrue);

        final processing = await repository.claimNextPending();
        expect(processing?.receiptId, 1);
        await Future<void>.delayed(const Duration(milliseconds: 2));
        await repository.resetStaleProcessingTasks(Duration.zero);
        final reset = await repository.claimNextPending();
        expect(reset?.receiptId, 2);
        await repository.markCompleted(reset!.receiptId);
        expect((await repository.claimNextPending())?.receiptId, 1);
      },
    );

    test(
      'semantic indexer includes rare fiscal fields and truncates long OCR',
      () {
        final indexer = ReceiptSemanticIndexer(
          embeddings: _LowCoverageEmbeddingService(),
        );
        final receipt = _receipt().copyWith(
          extractedContent: List.filled(80, 'texto longo').join(' '),
          extractedData: ExtractedData(
            id: 1,
            receiptId: 1,
            amount: 750,
            transactionDate: DateTime(2026, 12, 31),
            establishment: 'Posto Central',
            documentNumber: '12345',
            documentSeries: '9',
            documentState: 'BA',
            fiscalCnaeDescription: 'Comercio varejista',
            issuerCity: 'Salvador',
            issuerState: 'BA',
            paymentMethod: 'Credito',
          ),
        );

        final text = indexer.semanticText(receipt);

        expect(text, contains('documento fiscal numero 12345'));
        expect(text, contains('amount muito alto acima de 500'));
        expect(text, contains('periodo 2026-12'));
        expect(text, contains('Comercio varejista'));
        expect(text.length, lessThan(900));
      },
    );

    test('semantic indexer fills missing field vectors with zeros', () async {
      final indexer = ReceiptSemanticIndexer(
        embeddings: _LowCoverageEmbeddingService(dropPaymentVector: true),
      );

      final embedding = await indexer.generateEmbedding(_receipt());

      expect(embedding.dimension, 4);
      expect(
        embedding.model,
        contains(ReceiptSemanticIndexer.semanticEmbeddingVersion),
      );
    });
  });

  group('ReceiptBatchImportService', () {
    test(
      'creates sessions, processes ready and failed items, then completes',
      () async {
        final source = (await _files(['source'])).single;
        final staged = (await _files(['staged'])).single;
        final repository = _FakeBatchImportRepository(
          pendingItems: [
            _importItem(1, staged.path),
            _importItem(2, staged.path),
          ],
        );
        final receiptService = _FakeReceiptService(
          processErrors: {staged.path: StateError('ocr')},
        );
        final scheduler = _FakeBatchScheduler();
        final service = ReceiptBatchImportService(
          repository: repository,
          receiptService: receiptService,
          scheduler: scheduler,
          stagingService: _FakeStagingService(stagedFiles: [staged]),
        );

        expect(await service.createSession([source]), 10);
        expect(scheduler.scheduled, 1);
        expect((await service.findSnapshot(10))?.session.id, 10);
        expect((await service.findLatestOpenSnapshot())?.session.id, 10);
        expect((await service.watchSnapshot(10).first)?.session.id, 10);

        await service.processSession(10);
        expect(repository.resetSessions, [10]);
        expect(
          repository.sessionStatuses.first,
          ReceiptBatchImportStatus.processing,
        );
        expect(repository.readyItems, isEmpty);
        expect(repository.errorItems, [1, 2]);

        await service.markSaved(2, _receipt(fileName: 'saved'));
        await service.completeSession(10);
        expect(repository.savedItems, [2]);
        expect(repository.deletedSessions, [10]);
      },
    );

    test(
      'processes pending sessions and cancels with preview cleanup',
      () async {
        final staged = (await _files(['staged'])).single;
        final preview = _receipt(id: 0, fileName: staged.path);
        final repository = _FakeBatchImportRepository(
          pendingItems: [_importItem(1, staged.path)],
        )..snapshotItems = [_importItem(1, staged.path, receipt: preview)];
        final receiptService = _FakeReceiptService(previewReceipt: preview);
        final scheduler = _FakeBatchScheduler();
        final service = ReceiptBatchImportService(
          repository: repository,
          receiptService: receiptService,
          scheduler: scheduler,
        );

        await service.processPendingSessions();
        expect(repository.readyItems, [1]);
        expect(repository.refreshedSessions, [10]);

        await service.cancelSession(10);
        expect(scheduler.canceled, 1);
        expect(receiptService.discarded.map((receipt) => receipt.fileName), [
          preview.fileName,
        ]);
        expect(
          repository.sessionStatuses.last,
          ReceiptBatchImportStatus.canceled,
        );
        expect(repository.deletedSessions, [10]);
      },
    );

    test('marks item as error when preview processing times out', () async {
      final staged = (await _files(['staged'])).single;
      final repository = _FakeBatchImportRepository(
        pendingItems: [_importItem(1, staged.path)],
      );
      final receiptService = _FakeReceiptService(processNeverCompletes: true);
      final service = ReceiptBatchImportService(
        repository: repository,
        receiptService: receiptService,
        itemProcessingTimeout: const Duration(milliseconds: 10),
      );

      await service.processSession(10);

      expect(repository.readyItems, isEmpty);
      expect(repository.errorItems, [1]);
      expect(repository.errorDescriptions.single, contains('Tempo limite'));
      expect(repository.refreshedSessions, [10]);
    });

    test('processes claimed items with controlled concurrency', () async {
      final files = await _files(['staged-1', 'staged-2']);
      final repository = _FakeBatchImportRepository(
        pendingItems: [
          _importItem(1, files[0].path),
          _importItem(2, files[1].path),
        ],
      );
      final receiptService = _BlockingReceiptService();
      final service = ReceiptBatchImportService(
        repository: repository,
        receiptService: receiptService,
      );

      final processing = service.processSession(10);
      await Future<void>.delayed(Duration.zero);

      expect(
        receiptService.processingPaths,
        unorderedEquals([files[0].path, files[1].path]),
      );

      receiptService.completeAll();
      await processing;

      expect(repository.readyItems, unorderedEquals([1, 2]));
      expect(repository.refreshedSessions, [10]);
    });
  });
}

Future<List<File>> _files(List<String> names) async {
  final directory = await Directory.systemTemp.createTemp(
    'fintrack_batch_test_',
  );
  addTearDown(() => _deleteDirectoryIfExists(directory));
  return [
    for (final name in names)
      File('${directory.path}/$name')..writeAsStringSync(name),
  ];
}

Receipt _receipt({int id = 1, String fileName = 'receipt.txt'}) {
  return Receipt(
    id: id,
    type: ReceiptType.receipt,
    expense: true,
    fileName: fileName,
    fileType: 'text/plain',
    extractedContent: 'Mercado',
    registeredAt: DateTime(2026, 5, 20),
  );
}

ReceiptBatchImportItem _importItem(int id, String path, {Receipt? receipt}) {
  return ReceiptBatchImportItem(
    id: id,
    sessionId: 10,
    number: id,
    originalPath: path,
    stagedPath: path,
    status: ReceiptBatchImportItemStatus.pending,
    receiptJson: receipt == null
        ? null
        : receiptBatchReceiptToJsonString(receipt),
    updatedAt: DateTime(2026, 5, 20),
  );
}

class _FakeStagingService extends BatchStagingService {
  _FakeStagingService({this.stagedFiles = const [], this.stageError});

  final List<File> stagedFiles;
  final Object? stageError;

  @override
  Future<BatchStagingResult> stage(List<File> files) async {
    final error = stageError;
    if (error != null) {
      throw error;
    }
    final directory = await Directory.systemTemp.createTemp('fintrack_staged_');
    addTearDown(() => _deleteDirectoryIfExists(directory));
    return BatchStagingResult(directory: directory, files: stagedFiles);
  }
}

Future<void> _deleteDirectoryIfExists(Directory directory) async {
  if (await directory.exists()) {
    await directory.delete(recursive: true);
  }
}

class _FakeReceiptService implements IReceiptService {
  _FakeReceiptService({
    this.validateError,
    this.previewReceipt,
    this.processErrors = const {},
    this.processNeverCompletes = false,
  });

  final Object? validateError;
  final Receipt? previewReceipt;
  final Map<String, Object> processErrors;
  final bool processNeverCompletes;
  final validated = <File>[];
  final discarded = <Receipt>[];

  @override
  Future<void> validateSpaceForNewReceipt([File? file]) async {
    if (file != null) {
      validated.add(file);
    }
    final error = validateError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<Receipt> processPreview(File image) async {
    if (processNeverCompletes) {
      return Completer<Receipt>().future;
    }
    final error = processErrors[image.path];
    if (error != null) {
      throw error;
    }
    return previewReceipt ??
        _receipt(id: 0, fileName: image.path.split('/').last);
  }

  @override
  Future<void> discardPreview(Receipt receipt) async {
    discarded.add(receipt);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BlockingReceiptService extends _FakeReceiptService {
  final processingPaths = <String>[];
  final _pending = <Completer<Receipt>>[];

  @override
  Future<Receipt> processPreview(File image) {
    processingPaths.add(image.path);
    final completer = Completer<Receipt>();
    _pending.add(completer);
    return completer.future;
  }

  void completeAll() {
    for (final completer in _pending) {
      if (!completer.isCompleted) {
        completer.complete(_receipt());
      }
    }
  }
}

class _LowCoverageEmbeddingService implements IEmbeddingService {
  const _LowCoverageEmbeddingService({this.dropPaymentVector = false});

  final bool dropPaymentVector;

  @override
  Future<EmbeddingVector> generate(String text) async {
    if (dropPaymentVector && text.contains('pagamento')) {
      return const EmbeddingVector(
        vector: [1],
        model: 'low-coverage-model',
        dimension: 1,
      );
    }
    return EmbeddingVector(
      vector: [text.length.isEven ? 1 : 0, text.contains('Receita') ? 1 : 0],
      model: 'low-coverage-model',
      dimension: 2,
    );
  }
}

class _FakeBatchScheduler implements IReceiptBatchScheduler {
  int scheduled = 0;
  int canceled = 0;

  @override
  Future<bool> schedulePendingBatchImports() async {
    scheduled++;
    return true;
  }

  @override
  Future<bool> cancelPendingBatchImports() async {
    canceled++;
    return true;
  }
}

class _FakeBatchImportRepository implements IReceiptBatchImportRepository {
  _FakeBatchImportRepository({
    List<ReceiptBatchImportItem> pendingItems = const [],
  }) : _pendingItems = List.of(pendingItems);

  final List<ReceiptBatchImportItem> _pendingItems;
  var snapshotItems = <ReceiptBatchImportItem>[];
  final resetSessions = <int>[];
  final readyItems = <int>[];
  final errorItems = <int>[];
  final errorDescriptions = <String>[];
  final savedItems = <int>[];
  final refreshedSessions = <int>[];
  final deletedSessions = <int>[];
  final sessionStatuses = <ReceiptBatchImportStatus>[];

  ReceiptBatchImportSnapshot get snapshot {
    return ReceiptBatchImportSnapshot(
      session: ReceiptBatchImportSession(
        id: 10,
        createdAt: nullDate,
        updatedAt: nullDate,
        status: ReceiptBatchImportStatus.pending,
        stagingDirectory: '/tmp/staging',
        totalItems: 1,
      ),
      items: snapshotItems,
    );
  }

  @override
  Future<int> createSession({
    required Directory stagingDirectory,
    required List<File> originalFiles,
    required List<File> stagedFiles,
  }) async {
    return 10;
  }

  @override
  Future<ReceiptBatchImportSnapshot?> findSnapshot(int sessionId) async =>
      snapshot;

  @override
  Future<ReceiptBatchImportSnapshot?> findLatestOpenSnapshot() async =>
      snapshot;

  @override
  Stream<ReceiptBatchImportSnapshot?> watchSnapshot(int sessionId) =>
      Stream.value(snapshot);

  @override
  Future<List<ReceiptBatchImportSession>> findRunnableSessions() async => [
    snapshot.session,
  ];

  @override
  Future<void> resetStaleProcessingItems(
    int sessionId,
    Duration staleAfter,
  ) async {
    resetSessions.add(sessionId);
  }

  @override
  Future<ReceiptBatchImportItem?> claimNextPendingItem(int sessionId) async {
    if (_pendingItems.isEmpty) {
      return null;
    }
    return _pendingItems.removeAt(0);
  }

  @override
  Future<void> markItemReady(int itemId, Receipt receipt) async {
    readyItems.add(itemId);
  }

  @override
  Future<void> markItemError(int itemId, Object error) async {
    errorItems.add(itemId);
    errorDescriptions.add(error.toString());
  }

  @override
  Future<void> markItemSaved(int itemId, Receipt receipt) async {
    savedItems.add(itemId);
  }

  @override
  Future<void> markSessionStatus(
    int sessionId,
    ReceiptBatchImportStatus status,
  ) async {
    sessionStatuses.add(status);
  }

  @override
  Future<void> refreshSessionStatus(int sessionId) async {
    refreshedSessions.add(sessionId);
  }

  @override
  Future<void> deleteSession(int sessionId) async {
    deletedSessions.add(sessionId);
  }
}

final nullDate = DateTime(2026, 5, 20);
