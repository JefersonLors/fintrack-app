import 'package:fin_track/domain/exceptions/storage_limit_exception.dart';
import 'package:fin_track/presentation/receipts/pages/receipt_batch_review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';

import '../presentation_mockito_helpers.dart';
import '../presentation_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('batch item starts pending and exposes sequential label', () {
    final file = tempFile('batch-item.txt');
    addTearDown(() => deleteFile(file));

    final item = ReceiptBatchItem(file: file, originalFile: file, number: 3);

    expect(item.label, 'Item 3');
    expect(item.file, file);
    expect(item.originalFile, file);
    expect(item.status, ReceiptBatchItemStatus.pending);
    expect(item.receipt, isNull);
    expect(item.error, isNull);
  });

  testWidgets('review shows loading when ready item still has no data', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file = tempFile('review-loading.txt');
    final item = ReceiptBatchItem(file: file, number: 1)
      ..status = ReceiptBatchItemStatus.ready;

    try {
      await tester.pumpWidget(
        testHost(dependencies, ReceiptBatchReviewPage(items: [item])),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Revisar 1/1'), findsOne);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Salvar item'), findsOneWidget);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });

  testWidgets('review shows limit error, cancels batch, and discards', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file = tempFile('review-limit.txt');
    final item = ReceiptBatchItem(file: file, number: 1)
      ..status = ReceiptBatchItemStatus.error
      ..error = StateError('initial error');

    when(
      service.validateSpaceForNewReceipt(any),
    ).thenThrow(const StorageLimitException('Limite de armazenamento'));
    when(service.discardPreview(any)).thenAnswer((_) async {});

    try {
      await tester.pumpWidget(
        testHost(dependencies, ReceiptBatchReviewPage(items: [item])),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Reprocessar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Limite de armazenamento'), findsWidgets);

      verify(service.validateSpaceForNewReceipt(file)).called(1);
      await tester.pump(const Duration(seconds: 3));
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });

  testWidgets('batch review reprocesses and removes item with error', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file = tempFile('review-error.txt');
    final item = ReceiptBatchItem(file: file, number: 1)
      ..status = ReceiptBatchItemStatus.error
      ..error = const FormatException('OCR ilegível');

    when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
    when(
      service.processPreview(any),
    ).thenAnswer((_) async => testReceipt(fileName: file.path));
    when(service.localFile(any)).thenAnswer((_) async => file);

    try {
      await tester.pumpWidget(
        testHost(dependencies, ReceiptBatchReviewPage(items: [item])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Falha ao processar Item 1'), findsOne);
      expect(find.text('OCR ilegível'), findsOne);

      await tester.tap(find.text('Reprocessar'));
      await tester.pumpAndSettle();

      expect(find.text('Falha ao processar Item 1'), findsNothing);
      verify(service.processPreview(file)).called(1);

      item.status = ReceiptBatchItemStatus.error;
      item.error = StateError('failure again');
      await tester.pumpWidget(
        testHost(dependencies, ReceiptBatchReviewPage(items: [item])),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir item'));
      await tester.pumpAndSettle();

      expect(find.text('Revisar 1/1'), findsNothing);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });
}
