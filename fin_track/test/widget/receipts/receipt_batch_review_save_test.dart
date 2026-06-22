import 'dart:async';

import 'package:fin_track/domain/entities/category.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/entities/extracted_data.dart';
import 'package:fin_track/domain/exceptions/storage_limit_exception.dart';
import 'package:fin_track/infrastructure/diagnostics/fin_track_error_log.dart';
import 'package:fin_track/presentation/receipts/pages/receipt_batch_review_page.dart';
import 'package:fin_track/presentation/receipts/widgets/receipt_batch_item_form.dart';
import 'package:fin_track/presentation/widgets/storage_limit_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';

import '../presentation_mockito_helpers.dart';
import '../presentation_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(FinTrackErrorLog.clear);
  tearDown(FinTrackErrorLog.clear);

  testWidgets('review saves all while keeping item with error', (tester) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file1 = tempFile('review-save-error-1.txt');
    final file2 = tempFile('review-save-error-2.txt');
    const category = Category(id: 3, name: 'Casa');
    final item1 = testReadyBatch(
      file1,
      1,
      testReceipt(fileName: file1.path, category: category),
    );
    final item2 = testReadyBatch(
      file2,
      2,
      testReceipt(fileName: file2.path, category: category),
    );

    when(service.localFile(any)).thenAnswer((_) async => file1);
    when(service.saveConfirmed(any)).thenAnswer((invocation) async {
      final receipt = invocation.positionalArguments.first as Receipt;
      if (receipt.fileName == file2.path) {
        throw const StorageLimitException('failure item 2');
      }
      return receipt.copyWith(id: 700);
    });

    try {
      await tester.pumpWidget(
        testHost(dependencies, ReceiptBatchReviewPage(items: [item1, item2])),
      );
      await pumpIo(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar todos'));
      await tester.pumpAndSettle();
      expect(find.text('Limite de armazenamento atingido.'), findsOneWidget);
      hideStorageLimitSnackBarIfVisible();
      await tester.pump();
      verify(service.saveConfirmed(any)).called(2);
      expect(item2.status, ReceiptBatchItemStatus.error);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file1);
      deleteFile(file2);
    }
  });

  testWidgets(
    'review blocks navigation with global progress while saving all',
    (tester) async {
      final service = MockIReceiptService();
      final dependencies = testDependencies(service);
      final file1 = tempFile('review-save-all-progress-1.txt');
      final file2 = tempFile('review-save-all-progress-2.txt');
      const category = Category(id: 3, name: 'Casa');
      final firstSave = Completer<Receipt>();
      final secondSave = Completer<Receipt>();
      final item1 = testReadyBatch(
        file1,
        1,
        testReceipt(fileName: file1.path, category: category),
      );
      final item2 = testReadyBatch(
        file2,
        2,
        testReceipt(fileName: file2.path, category: category),
      );

      when(service.localFile(any)).thenAnswer((_) async => file1);
      when(service.saveConfirmed(any)).thenAnswer((invocation) {
        final receipt = invocation.positionalArguments.first as Receipt;
        if (receipt.fileName == file1.path) {
          return firstSave.future;
        }
        return secondSave.future;
      });

      try {
        await tester.pumpWidget(
          testHost(dependencies, ReceiptBatchReviewPage(items: [item1, item2])),
        );
        await pumpIo(tester);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Salvar todos'));
        await tester.pump();

        expect(find.text('Salvando comprovantes'), findsOneWidget);
        expect(
          find.text('Aguarde enquanto os comprovantes são salvos.'),
          findsOneWidget,
        );
        expect(find.text('0 de 2'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          tester
              .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.chevron_right),
              )
              .onPressed,
          isNull,
        );

        firstSave.complete(testReceipt(id: 701, fileName: file1.path));
        await tester.pump();
        expect(find.text('1 de 2'), findsOneWidget);

        secondSave.complete(testReceipt(id: 702, fileName: file2.path));
        await tester.pumpAndSettle();
        verify(service.saveConfirmed(any)).called(2);
      } finally {
        await disposeTestApp(tester, dependencies);
        deleteFile(file1);
        deleteFile(file2);
      }
    },
  );

  testWidgets(
    'batch review preserves date and type when navigating between items',
    (tester) async {
      final service = MockIReceiptService();
      final dependencies = testDependencies(service);
      final file1 = tempFile('review-preserve-fields-1.txt');
      final file2 = tempFile('review-preserve-fields-2.txt');
      final date1 = DateTime(2026, 4, 10);
      final date2 = DateTime(2026, 5, 11);
      const category = Category(id: 8, name: 'Transporte');
      final item1 = testReadyBatch(
        file1,
        1,
        testReceipt(
          fileName: file1.path,
          data: date1,
          category: category,
        ).copyWith(type: ReceiptType.invoice, expense: true),
      );
      final item2 = testReadyBatch(
        file2,
        2,
        testReceipt(
          fileName: file2.path,
          data: date2,
          category: category,
        ).copyWith(type: ReceiptType.pixReceipt, expense: false),
      );

      when(service.localFile(any)).thenAnswer((_) async => file1);
      when(service.saveConfirmed(any)).thenAnswer((invocation) async {
        final receipt = invocation.positionalArguments.first as Receipt;
        return receipt.copyWith(id: receipt.fileName == file1.path ? 701 : 702);
      });

      try {
        await tester.pumpWidget(
          testHost(dependencies, ReceiptBatchReviewPage(items: [item1, item2])),
        );
        await pumpIo(tester);
        await tester.pumpAndSettle();

        expect(find.byType(ReceiptBatchItemForm), findsOneWidget);
        await tester.tap(find.byTooltip('Próximo'));
        await tester.pumpAndSettle();
        expect(find.text('Revisar 2/2'), findsOne);
        expect(find.byType(ReceiptBatchItemForm), findsOneWidget);

        await tester.tap(find.byTooltip('Anterior'));
        await tester.pumpAndSettle();
        expect(find.text('Revisar 1/2'), findsOne);
        expect(find.byType(ReceiptBatchItemForm), findsOneWidget);
        await tester.tap(find.text('Salvar todos'));
        await tester.pumpAndSettle();

        final captured = verify(
          service.saveConfirmed(captureAny),
        ).captured.cast<Receipt>();
        expect(captured, hasLength(2));
        expect(captured[0].type, ReceiptType.invoice);
        expect(captured[0].expense, isTrue);
        expect(captured[0].extractedData?.transactionDate, date1);
        expect(captured[1].type, ReceiptType.pixReceipt);
        expect(captured[1].expense, isFalse);
        expect(captured[1].extractedData?.transactionDate, date2);
      } finally {
        await disposeTestApp(tester, dependencies);
        deleteFile(file1);
        deleteFile(file2);
      }
    },
  );

  testWidgets(
    'batch review keeps remaining item data after saving adjacent item',
    (tester) async {
      final service = MockIReceiptService();
      final dependencies = testDependencies(service);
      final file1 = tempFile('review-save-adjacent-1.txt');
      final file2 = tempFile('review-save-adjacent-2.txt');
      const category = Category(id: 8, name: 'Transporte');
      final date1 = DateTime(2026, 3, 9);
      final date2 = DateTime(2026, 6, 12);
      final item1 = testReadyBatch(
        file1,
        1,
        testReceipt(
          fileName: file1.path,
          category: category,
          amount: 11.25,
          data: date1,
        ).copyWith(
          type: ReceiptType.invoice,
          expense: true,
          extractedData: ExtractedData(
            id: 0,
            receiptId: 0,
            amount: 11.25,
            transactionDate: date1,
            establishment: 'Primeira Loja',
            paymentMethod: 'PIX',
          ),
        ),
      );
      final item2 = testReadyBatch(
        file2,
        2,
        testReceipt(
          fileName: file2.path,
          category: category,
          amount: 99.9,
          data: date2,
        ).copyWith(
          type: ReceiptType.pixReceipt,
          expense: false,
          extractedData: ExtractedData(
            id: 0,
            receiptId: 0,
            amount: 99.9,
            transactionDate: date2,
            establishment: 'Segunda Loja',
            paymentMethod: 'Cartão de crédito',
          ),
        ),
      );

      when(service.localFile(any)).thenAnswer((_) async => file1);
      when(service.saveConfirmed(any)).thenAnswer((invocation) async {
        final receipt = invocation.positionalArguments.first as Receipt;
        return receipt.copyWith(id: receipt.fileName == file1.path ? 801 : 802);
      });

      try {
        await tester.pumpWidget(
          testHost(dependencies, ReceiptBatchReviewPage(items: [item1, item2])),
        );
        await pumpIo(tester);
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Próximo'));
        await tester.pumpAndSettle();
        expect(find.text('Revisar 2/2'), findsOne);

        await tester.tap(find.text('Salvar item'));
        await tester.pumpAndSettle();
        expect(find.text('Revisar 1/1'), findsOne);

        await tester.tap(find.text('Salvar item'));
        await tester.pumpAndSettle();

        final captured = verify(
          service.saveConfirmed(captureAny),
        ).captured.cast<Receipt>();
        expect(captured, hasLength(2));

        expect(captured[0].fileName, file2.path);
        expect(captured[0].type, ReceiptType.pixReceipt);
        expect(captured[0].expense, isFalse);
        expect(captured[0].extractedData?.amount, 99.9);
        expect(captured[0].extractedData?.transactionDate, date2);
        expect(captured[0].extractedData?.establishment, 'Segunda Loja');
        expect(captured[0].extractedData?.paymentMethod, 'Cartão de crédito');

        expect(captured[1].fileName, file1.path);
        expect(captured[1].type, ReceiptType.invoice);
        expect(captured[1].expense, isTrue);
        expect(captured[1].extractedData?.amount, 11.25);
        expect(captured[1].extractedData?.transactionDate, date1);
        expect(captured[1].extractedData?.establishment, 'Primeira Loja');
        expect(captured[1].extractedData?.paymentMethod, 'PIX');
      } finally {
        await disposeTestApp(tester, dependencies);
        deleteFile(file1);
        deleteFile(file2);
      }
    },
  );

  testWidgets('batch review saves ready item using mocked service', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file = tempFile('review.txt');
    final category = const Category(id: 1, name: 'Alimentação');
    final item = ReceiptBatchItem(file: file, number: 1)
      ..status = ReceiptBatchItemStatus.ready
      ..receipt = testReceipt(fileName: file.path, category: category);

    when(service.localFile(any)).thenAnswer((_) async => file);
    when(service.saveConfirmed(any)).thenAnswer((invocation) async {
      final receipt = invocation.positionalArguments.first as Receipt;
      return receipt.copyWith(id: 99);
    });

    try {
      await tester.pumpWidget(
        testHost(dependencies, ReceiptBatchReviewPage(items: [item])),
      );
      await pumpIo(tester);
      await tester.pumpAndSettle();

      expect(find.text('Revisar 1/1'), findsOne);
      await tester.drag(find.byType(ListView), const Offset(0, -420));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(3));

      await tester.tap(find.text('Salvar item'));
      await tester.pumpAndSettle();

      verify(service.saveConfirmed(any)).called(1);
      expect(find.text('Revisar 1/1'), findsNothing);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });

  testWidgets('batch review notifies persisted batch when saving one item', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file = tempFile('review-save-one-persisted.txt');
    final savedItems = <ReceiptBatchItem>[];
    const category = Category(id: 3, name: 'Casa');
    final item = ReceiptBatchItem(file: file, number: 1, persistedItemId: 42)
      ..status = ReceiptBatchItemStatus.ready
      ..receipt = testReceipt(fileName: file.path, category: category);

    when(service.localFile(any)).thenAnswer((_) async => file);
    when(service.saveConfirmed(any)).thenAnswer((invocation) async {
      final receipt = invocation.positionalArguments.first as Receipt;
      return receipt.copyWith(id: 99);
    });

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          ReceiptBatchReviewPage(
            items: List<ReceiptBatchItem>.unmodifiable([item]),
            onItemSaved: (savedItem) async => savedItems.add(savedItem),
          ),
        ),
      );
      await pumpIo(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar item'));
      await tester.pumpAndSettle();

      verify(service.saveConfirmed(any)).called(1);
      expect(savedItems, [item]);
      expect(item.status, ReceiptBatchItemStatus.saved);
      expect(item.receipt?.id, 99);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });

  testWidgets('batch review edits fields before saving item', (tester) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file = tempFile('review-edit.png');
    final category = const Category(id: 7, name: 'Casa');
    final item = ReceiptBatchItem(file: file, number: 1)
      ..status = ReceiptBatchItemStatus.ready
      ..receipt = testReceipt(fileName: file.path, category: category).copyWith(
        fileType: 'image/png',
        extractedData: ExtractedData(
          id: 0,
          receiptId: 0,
          amount: 42.5,
          transactionDate: DateTime(2026, 5, 20),
          establishment: 'Mercado Modelo',
          paymentMethod: 'Pix',
          ocrConfidence: 0.2,
          valueConfidence: 0.2,
          dateConfidence: 0.2,
          establishmentConfidence: 0.2,
          paymentMethodConfidence: 0.2,
        ),
      );

    when(service.localFile(any)).thenAnswer((_) async => file);
    when(service.saveConfirmed(any)).thenAnswer((invocation) async {
      final receipt = invocation.positionalArguments.first as Receipt;
      return receipt.copyWith(id: 77);
    });

    try {
      await tester.pumpWidget(
        testHost(dependencies, ReceiptBatchReviewPage(items: [item])),
      );
      await pumpIo(tester);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -360));
      await tester.pumpAndSettle();
      final campos = find.byType(TextFormField);
      expect(campos, findsNWidgets(3));
      await tester.enterText(campos.at(0), 'Loja Editada');
      await tester.enterText(campos.at(1), '123,45');
      await tester.tap(find.text('Salvar item'));
      await tester.pumpAndSettle();

      final captured = verify(service.saveConfirmed(captureAny)).captured;
      final savedReceipt = captured.single as Receipt;
      expect(savedReceipt.expense, isTrue);
      expect(savedReceipt.extractedData?.amount, 123.45);
      expect(
        savedReceipt.extractedData?.transactionDate,
        DateTime(2026, 5, 20),
      );
      expect(savedReceipt.extractedData?.establishment, 'Loja Editada');
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });

  testWidgets('batch review changes date selectors and opens preview', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file = tempFile('review-selectors.png');
    final category = (await dependencies.categoryService.list()).first;
    final item = ReceiptBatchItem(file: file, number: 1)
      ..status = ReceiptBatchItemStatus.ready
      ..receipt = testReceipt(fileName: file.path, category: category).copyWith(
        fileType: 'image/png',
        extractedData: ExtractedData(
          id: 0,
          receiptId: 0,
          amount: 42.5,
          transactionDate: DateTime(2026, 5, 20),
          establishment: 'Mercado Modelo',
          paymentMethod: 'Pix',
          ocrConfidence: 0.9,
          valueConfidence: 0.9,
          dateConfidence: 0.9,
          establishmentConfidence: 0.9,
          paymentMethodConfidence: 0.9,
        ),
      );

    when(service.localFile(any)).thenAnswer((_) async => file);
    when(service.saveConfirmed(any)).thenAnswer((invocation) async {
      final receipt = invocation.positionalArguments.first as Receipt;
      return receipt.copyWith(id: 101);
    });

    try {
      await tester.pumpWidget(
        testHost(dependencies, ReceiptBatchReviewPage(items: [item])),
      );
      await pumpIo(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InteractiveViewer).first);
      await tester.pumpAndSettle();
      expect(find.text('Imagem do comprovante'), findsOne);
      tester.state<NavigatorState>(find.byType(Navigator).last).pop();
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -520));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Limpar data'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Data da transação'), findsOne);
      await tester.tap(find.byTooltip('Selecionar data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar item'));
      await tester.pumpAndSettle();
      final savedReceipt =
          verify(service.saveConfirmed(captureAny)).captured.single as Receipt;
      expect(savedReceipt.expense, isTrue);
      expect(savedReceipt.extractedData?.transactionDate, isNotNull);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });

  testWidgets('batch review shows error when saving item fails', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file = tempFile('review-save-error.txt');
    final item = testReadyBatch(file, 1, testReceipt(fileName: file.path));

    when(service.localFile(any)).thenAnswer((_) async => file);
    when(service.saveConfirmed(any)).thenThrow(StateError('save failure'));

    try {
      await tester.pumpWidget(
        testHost(dependencies, ReceiptBatchReviewPage(items: [item])),
      );
      await pumpIo(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar item'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Falha ao processar Item 1'), findsOne);
      expect(find.textContaining('save failure'), findsOne);
      expect(
        FinTrackErrorLog.recent().join('\n'),
        contains('Bad state: save failure'),
      );
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });
}
