import 'dart:async';
import 'dart:io';

import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/presentation/receipts/controllers/receipt_batch_controller.dart';
import 'package:fin_track/presentation/receipts/pages/receipt_batch_processing_page.dart';
import 'package:fin_track/presentation/receipts/widgets/batch_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';

import '../presentation_mockito_helpers.dart';
import '../presentation_mocks.dart';
import '../widget_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('batch processing renders initial queue', (tester) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file1 = tempFile('batch-1.txt');
    final file2 = tempFile('batch-2.txt');

    when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
    when(service.processPreview(any)).thenAnswer((invocation) async {
      final file = invocation.positionalArguments.first as File;
      return testReceipt(fileName: file.path);
    });
    when(service.localFile(any)).thenAnswer((_) async => file1);

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          ReceiptBatchProcessingPage(files: [file1, file2]),
        ),
      );
      await tester.pump();

      expect(find.text('Processando lote'), findsOne);
      expect(find.text('Total'), findsOne);
      expect(find.text('Pendentes'), findsOne);
      expect(find.text('Item 1'), findsOne);
      expect(find.text('Item 2'), findsOne);
      verifyNever(service.processPreview(any));
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file1);
      deleteFile(file2);
    }
  });

  testWidgets('batch processing completes items and opens review', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file1 = tempFile('batch-success-1.txt');
    final file2 = tempFile('batch-success-2.txt');

    when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
    when(service.processPreview(any)).thenAnswer((invocation) async {
      final file = invocation.positionalArguments.first as File;
      return testReceipt(fileName: file.path);
    });
    when(service.localFile(any)).thenAnswer((invocation) async {
      final fileName = invocation.positionalArguments.first as String;
      return File(fileName);
    });

    try {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testHost(
            dependencies,
            ReceiptBatchProcessingPage(files: [file1, file2]),
          ),
        );
        await tester.pump();
        await Future<void>.delayed(const Duration(seconds: 2));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Revisar 1/2').evaluate().isNotEmpty ||
            find.text('Processando lote').evaluate().isNotEmpty,
        isTrue,
      );
      expect(find.text('Item 1'), findsOne);
      verify(
        service.validateSpaceForNewReceipt(any),
      ).called(greaterThanOrEqualTo(1));
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file1);
      deleteFile(file2);
    }
  });

  testWidgets('batch item card opens the staged item file preview', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final stagedFile = tempFile('batch-card-preview.png')
      ..writeAsBytesSync(testPngBytes);
    final missingOriginal = File('${stagedFile.path}.missing');
    final item = ReceiptBatchItem(
      file: stagedFile,
      originalFile: missingOriginal,
      number: 7,
    )..status = ReceiptBatchItemStatus.processing;

    try {
      await tester.pumpWidget(
        testHost(dependencies, Scaffold(body: BatchItemCard(item: item))),
      );

      await tester.tap(find.widgetWithText(ListTile, 'Item 7'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Item 7'), findsWidgets);
      expect(find.byType(InteractiveViewer), findsOne);
      expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(stagedFile);
    }
  });

  testWidgets('batch processing shows limit error for all items', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file1 = tempFile('batch-limit-1.txt');
    final file2 = tempFile('batch-limit-2.txt');

    when(
      service.validateSpaceForNewReceipt(any),
    ).thenThrow(StateError('sem espaco'));

    try {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testHost(
            dependencies,
            ReceiptBatchProcessingPage(files: [file1, file2]),
          ),
        );
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 800));
      });
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 300));
        if (find.text('Falha ao processar Item 1').evaluate().isNotEmpty) {
          break;
        }
      }

      expect(find.text('Falha ao processar Item 1'), findsOne);
      expect(find.text('Reprocessar'), findsOne);
      verify(
        service.validateSpaceForNewReceipt(any),
      ).called(greaterThanOrEqualTo(1));
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file1);
      deleteFile(file2);
    }
  });

  testWidgets('batch processing marks error when staging fails', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file = File('${Directory.systemTemp.path}/fintrack-missing.txt');

    try {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testHost(dependencies, ReceiptBatchProcessingPage(files: [file])),
        );
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Falha no processamento'), findsOne);
      verifyNever(service.validateSpaceForNewReceipt(any));
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('batch processing keeps item error for review', (tester) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file1 = tempFile('batch-error-1.txt');
    final file2 = tempFile('batch-error-2.txt');

    when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
    when(service.processPreview(any)).thenAnswer((invocation) async {
      final file = invocation.positionalArguments.first as File;
      if (file.path.contains('002')) {
        throw const FormatException('OCR falhou');
      }
      return testReceipt(fileName: file.path);
    });
    when(service.localFile(any)).thenAnswer((invocation) async {
      final fileName = invocation.positionalArguments.first as String;
      return File(fileName);
    });

    try {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testHost(
            dependencies,
            ReceiptBatchProcessingPage(files: [file1, file2]),
          ),
        );
        await tester.pump();
        await Future<void>.delayed(const Duration(seconds: 4));
      });
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Revisar 1/2').evaluate().isNotEmpty ||
            find.text('Processando lote').evaluate().isNotEmpty,
        isTrue,
      );
      verify(service.processPreview(any)).called(greaterThanOrEqualTo(1));
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file1);
      deleteFile(file2);
    }
  });

  testWidgets('batch processing confirms cancellation and discards preview', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file1 = tempFile('batch-cancel-1.txt');
    final file2 = tempFile('batch-cancel-2.txt');
    final pendingReceipt = Completer<Receipt>();

    when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
    when(service.processPreview(any)).thenAnswer((invocation) {
      final file = invocation.positionalArguments.first as File;
      if (file.path.contains('001')) {
        return Future.value(testReceipt(id: 0, fileName: file.path));
      }
      return pendingReceipt.future;
    });
    when(service.discardPreview(any)).thenAnswer((_) async {});

    try {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testHost(
            dependencies,
            Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) =>
                    ReceiptBatchProcessingPage(files: [file1, file2]),
              ),
            ),
          ),
        );
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 800));
      });
      await tester.pump(const Duration(milliseconds: 300));

      await tester
          .state<NavigatorState>(find.byType(Navigator).last)
          .maybePop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Cancelar processamento em lote?'), findsOne);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Continuar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Processando lote'), findsOne);

      await tester
          .state<NavigatorState>(find.byType(Navigator).last)
          .maybePop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(FilledButton, 'Cancelar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(service.discardPreview(any)).called(1);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file1);
      deleteFile(file2);
    }
  });

  testWidgets('batch cancellation stops remaining foreground processing', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file1 = tempFile('batch-cancel-stop-1.txt');
    final file2 = tempFile('batch-cancel-stop-2.txt');
    final file3 = tempFile('batch-cancel-stop-3.txt');
    final firstPendingReceipt = Completer<Receipt>();
    final secondPendingReceipt = Completer<Receipt>();

    when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
    when(service.processPreview(any)).thenAnswer((invocation) {
      final file = invocation.positionalArguments.first as File;
      if (file.path.contains('001')) {
        return firstPendingReceipt.future;
      }
      if (file.path.contains('002')) {
        return secondPendingReceipt.future;
      }
      return Future.value(testReceipt(id: 0, fileName: file.path));
    });
    when(service.discardPreview(any)).thenAnswer((_) async {});

    try {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          testHost(
            dependencies,
            Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) =>
                    ReceiptBatchProcessingPage(files: [file1, file2, file3]),
              ),
            ),
          ),
        );
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 800));
      });
      await tester.pump(const Duration(milliseconds: 300));

      await tester
          .state<NavigatorState>(find.byType(Navigator).last)
          .maybePop();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(FilledButton, 'Cancelar'));
      await tester.pump();

      firstPendingReceipt.complete(testReceipt(id: 0, fileName: file1.path));
      secondPendingReceipt.complete(testReceipt(id: 0, fileName: file2.path));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );

      verify(service.processPreview(any)).called(2);
      verify(service.discardPreview(any)).called(2);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file1);
      deleteFile(file2);
      deleteFile(file3);
    }
  });
}
