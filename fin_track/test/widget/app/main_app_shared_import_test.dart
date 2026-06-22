import 'dart:async';
import 'dart:io';

import 'package:fin_track/application/receipts/batch/receipt_batch_import_service.dart';
import 'package:fin_track/domain/entities/configuration.dart';
import 'package:fin_track/domain/entities/receipt_batch_import.dart';
import 'package:fin_track/domain/exceptions/storage_limit_exception.dart';
import 'package:fin_track/domain/exceptions/operation_cancelled_exception.dart';
import 'package:fin_track/domain/repositories/i_receipt_batch_import_repository.dart';
import 'package:fin_track/main.dart';
import 'package:fin_track/presentation/widgets/storage_limit_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';

import '../main_app_test_helpers.dart';
import '../presentation_mockito_helpers.dart';
import '../presentation_mocks.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets(
    'imports initial shared file and removes temporary file on completion',
    (tester) async {
      final receiptService = MockIReceiptService();
      final dependencies = mainAppDependencies(receiptService: receiptService);
      final file = tempFile('initial_shared.txt');
      final platform = FakeFinTrackPlatformGateway(pendingFiles: [file.path]);
      when(
        receiptService.validateSpaceForNewReceipt(),
      ).thenAnswer((_) async {});
      when(
        receiptService.validateSpaceForNewReceipt(any),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        FinTrackApp(
          dependencies: dependencies,
          platformGateway: platform,
          sharedFilePageBuilder: singleSharedFilePage,
          waitBeforeSharedFileNavigation: noNavigationWait,
        ),
      );
      await pumpAppFrames(tester);

      expect(find.text('Arquivo compartilhado'), findsOneWidget);
      expect(find.text(file.path), findsOneWidget);
      verify(receiptService.validateSpaceForNewReceipt(any)).called(1);

      await tester.tap(find.text('Concluir importação'));
      await pumpAppFrames(tester);

      expect(file.existsSync(), isFalse);
      await disposeTestApp(tester, dependencies);
    },
  );

  testWidgets('ignores empty paths, duplicates, and missing files', (
    tester,
  ) async {
    final receiptService = MockIReceiptService();
    final dependencies = mainAppDependencies(receiptService: receiptService);
    final platform = FakeFinTrackPlatformGateway();
    when(receiptService.validateSpaceForNewReceipt()).thenAnswer((_) async {});
    when(
      receiptService.validateSpaceForNewReceipt(any),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      FinTrackApp(
        dependencies: dependencies,
        platformGateway: platform,
        sharedFilePageBuilder: singleSharedFilePage,
        waitBeforeSharedFileNavigation: noNavigationWait,
      ),
    );
    await pumpAppFrames(tester);

    await tester.runAsync(() async {
      unawaited(platform.listener?.call(['', '/file/missing.txt', '']));
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await pumpAppFrames(tester);

    expect(find.text('Arquivo compartilhado'), findsNothing);
    verifyNever(receiptService.validateSpaceForNewReceipt(any));

    await disposeTestApp(tester, dependencies);
  });

  testWidgets('storage limit cancels import and removes file', (tester) async {
    final receiptService = MockIReceiptService();
    final dependencies = mainAppDependencies(receiptService: receiptService);
    final file = tempFile('storage_limit.txt');
    final platform = FakeFinTrackPlatformGateway();
    when(
      receiptService.validateSpaceForNewReceipt(any),
    ).thenThrow(const StorageLimitException('limite atingido'));

    await tester.pumpWidget(
      FinTrackApp(
        dependencies: dependencies,
        platformGateway: platform,
        sharedFilePageBuilder: singleSharedFilePage,
        waitBeforeSharedFileNavigation: noNavigationWait,
      ),
    );
    await pumpAppFrames(tester);

    await tester.runAsync(() async {
      unawaited(platform.listener?.call([file.path]));
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await pumpAppFrames(tester);

    expect(find.text('Limite de armazenamento atingido.'), findsOneWidget);
    expect(find.text('Arquivo compartilhado'), findsNothing);
    expect(file.existsSync(), isFalse);

    hideStorageLimitSnackBarIfVisible();
    await pumpAppFrames(tester);
    await disposeTestApp(tester, dependencies);
  });

  testWidgets('discards shared file when authentication fails', (tester) async {
    final receiptService = MockIReceiptService();
    final localAuthService = MockILocalAuthenticationService();
    final file = tempFile('auth_failure.txt');
    final dependencies = mainAppDependencies(
      receiptService: receiptService,
      localAuthService: localAuthService,
      configuration: const Configuration(
        id: 1,
        onboardingCompleted: true,
        localAuthEnabled: true,
        authenticationType: AuthenticationType.pin,
      ),
    );
    final platform = FakeFinTrackPlatformGateway(pendingFiles: [file.path]);
    when(localAuthService.authenticatePin(any)).thenAnswer((_) async => false);

    await tester.pumpWidget(
      FinTrackApp(dependencies: dependencies, platformGateway: platform),
    );
    await pumpAppFrames(tester);

    expect(find.text('FinTrack bloqueado'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '9999');
    await tester.tap(find.widgetWithText(FilledButton, 'Desbloquear').last);
    await pumpAppFrames(tester);

    expect(file.existsSync(), isFalse);
    expect(find.text('Arquivo compartilhado'), findsNothing);
    verifyNever(receiptService.validateSpaceForNewReceipt(any));
    await disposeTestApp(tester, dependencies);
  });

  testWidgets('reschedules import when app is not ready yet', (tester) async {
    final receiptService = MockIReceiptService();
    final dependencies = mainAppDependencies(receiptService: receiptService);
    final file = tempFile('initial_retry.txt');
    final platform = FakeFinTrackPlatformGateway(pendingFiles: [file.path]);
    var resolverCalls = 0;

    await tester.pumpWidget(
      FinTrackApp(
        dependencies: dependencies,
        platformGateway: platform,
        sharedFilePageBuilder: singleSharedFilePage,
        waitBeforeSharedFileNavigation: noNavigationWait,
        navigatorResolver: (key) {
          resolverCalls++;
          return resolverCalls == 1 ? null : key.currentState;
        },
      ),
    );
    await pumpAppFrames(tester);
    await pumpAppFrames(tester);

    expect(find.text('Arquivo compartilhado'), findsOneWidget);
    expect(resolverCalls, greaterThan(1));

    await tester.tap(find.text('Concluir importação'));
    await pumpAppFrames(tester);
    expect(file.existsSync(), isFalse);
    await disposeTestApp(tester, dependencies);
  });

  testWidgets('reschedules import if navigator disappears before navigation', (
    tester,
  ) async {
    final receiptService = MockIReceiptService();
    final dependencies = mainAppDependencies(receiptService: receiptService);
    final file = tempFile('retry_navigation.txt');
    final platform = FakeFinTrackPlatformGateway(pendingFiles: [file.path]);
    var resolverCalls = 0;

    await tester.pumpWidget(
      FinTrackApp(
        dependencies: dependencies,
        platformGateway: platform,
        sharedFilePageBuilder: singleSharedFilePage,
        waitBeforeSharedFileNavigation: noNavigationWait,
        navigatorResolver: (key) {
          resolverCalls++;
          return resolverCalls == 2 ? null : key.currentState;
        },
      ),
    );
    await pumpAppFrames(tester);
    await pumpAppFrames(tester);

    expect(find.text('Arquivo compartilhado'), findsOneWidget);
    expect(resolverCalls, greaterThan(2));

    await tester.tap(find.text('Concluir importação'));
    await pumpAppFrames(tester);
    expect(file.existsSync(), isFalse);
    await disposeTestApp(tester, dependencies);
  });

  testWidgets('resumes pending batch import after app starts', (tester) async {
    final receiptService = MockIReceiptService();
    final batchService = _FakeReceiptBatchImportService(
      snapshot: _pendingBatchSnapshot(88),
    );
    final dependencies = mainAppDependencies(
      receiptService: receiptService,
      receiptBatchImportService: batchService,
    );

    await tester.pumpWidget(
      FinTrackApp(
        dependencies: dependencies,
        platformGateway: FakeFinTrackPlatformGateway(),
        waitBeforeSharedFileNavigation: noNavigationWait,
      ),
    );
    await pumpAppFrames(tester);

    expect(find.text('Processando lote'), findsOneWidget);
    expect(batchService.processedSessions, [88]);

    await disposeTestApp(tester, dependencies);
  });

  testWidgets('keeps app running when pending batch lookup fails', (
    tester,
  ) async {
    final receiptService = MockIReceiptService();
    final batchService = _FakeReceiptBatchImportService(
      snapshot: _pendingBatchSnapshot(89),
      failLatestLookup: true,
    );
    final dependencies = mainAppDependencies(
      receiptService: receiptService,
      receiptBatchImportService: batchService,
    );

    await tester.pumpWidget(
      FinTrackApp(
        dependencies: dependencies,
        platformGateway: FakeFinTrackPlatformGateway(),
        waitBeforeSharedFileNavigation: noNavigationWait,
      ),
    );
    await pumpAppFrames(tester);

    expect(find.text('Processando lote'), findsNothing);
    expect(find.byType(FinTrackApp), findsOneWidget);

    await disposeTestApp(tester, dependencies);
  });

  testWidgets('uses default builders for single shared file', (tester) async {
    final receiptService = MockIReceiptService();
    final dependencies = mainAppDependencies(receiptService: receiptService);
    final file = tempFile('default_builder_single.txt');
    final platform = FakeFinTrackPlatformGateway(pendingFiles: [file.path]);
    when(
      receiptService.processPreview(any),
    ).thenThrow(const OperationCancelledException());

    await tester.pumpWidget(
      FinTrackApp(dependencies: dependencies, platformGateway: platform),
    );
    await pumpShortAppFrames(tester);

    expect(find.text('Processando'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    await disposeTestApp(tester, dependencies);
    deleteFile(file);
  });

  testWidgets('uses default builders for shared batch', (tester) async {
    final receiptService = MockIReceiptService();
    final dependencies = mainAppDependencies(receiptService: receiptService);
    final firstItem = tempFile('default_batch_1.txt');
    final secondItem = tempFile('default_batch_2.txt');
    final platform = FakeFinTrackPlatformGateway();

    await tester.pumpWidget(
      FinTrackApp(
        dependencies: dependencies,
        platformGateway: platform,
        waitBeforeSharedFileNavigation: noNavigationWait,
      ),
    );
    await pumpAppFrames(tester);

    await tester.runAsync(() async {
      unawaited(platform.listener?.call([firstItem.path, secondItem.path]));
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await pumpShortAppFrames(tester);

    expect(find.text('Processando lote'), findsOneWidget);

    await disposeTestApp(tester, dependencies);
    deleteFile(firstItem);
    deleteFile(secondItem);
  });
}

ReceiptBatchImportSnapshot _pendingBatchSnapshot(int sessionId) {
  final now = DateTime(2026, 5, 22, 10);
  return ReceiptBatchImportSnapshot(
    session: ReceiptBatchImportSession(
      id: sessionId,
      createdAt: now,
      updatedAt: now,
      status: ReceiptBatchImportStatus.processing,
      stagingDirectory: Directory.systemTemp.path,
      totalItems: 1,
    ),
    items: [
      ReceiptBatchImportItem(
        id: 1,
        sessionId: sessionId,
        number: 1,
        originalPath: '/tmp/original.txt',
        stagedPath: '/tmp/staged.txt',
        status: ReceiptBatchImportItemStatus.processing,
        updatedAt: now,
      ),
    ],
  );
}

class _FakeReceiptBatchImportService extends ReceiptBatchImportService {
  _FakeReceiptBatchImportService({
    required ReceiptBatchImportSnapshot snapshot,
    this.failLatestLookup = false,
  }) : _snapshot = snapshot,
       super(
         repository: _UnusedReceiptBatchImportRepository(),
         receiptService: MockIReceiptService(),
       );

  final ReceiptBatchImportSnapshot _snapshot;
  final bool failLatestLookup;
  final processedSessions = <int>[];

  @override
  Future<ReceiptBatchImportSnapshot?> findLatestOpenSnapshot() async {
    if (failLatestLookup) {
      throw StateError('falha ao retomar lote');
    }
    return _snapshot;
  }

  @override
  Future<ReceiptBatchImportSnapshot?> findSnapshot(int sessionId) async {
    return _snapshot;
  }

  @override
  Stream<ReceiptBatchImportSnapshot?> watchSnapshot(int sessionId) {
    return Stream.value(_snapshot);
  }

  @override
  Future<void> pauseScheduledProcessing() async {}

  @override
  Future<void> processSession(int sessionId) async {
    processedSessions.add(sessionId);
  }
}

class _UnusedReceiptBatchImportRepository
    implements IReceiptBatchImportRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
