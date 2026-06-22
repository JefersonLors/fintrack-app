import 'package:fin_track/domain/entities/category.dart';
import 'package:fin_track/domain/entities/receipt.dart';
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

  testWidgets('review discards pending preview when exit is confirmed', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file = tempFile('review-discard-exit.txt');
    final item = testReadyBatch(
      file,
      1,
      testReceipt(id: 0, fileName: file.path),
    );

    when(service.localFile(any)).thenAnswer((_) async => file);
    when(service.discardPreview(any)).thenAnswer((_) async {});

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => ReceiptBatchReviewPage(items: [item]),
            ),
          ),
        ),
      );
      await pumpIo(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester
          .state<NavigatorState>(find.byType(Navigator).last)
          .maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Descartar lote?'), findsOne);
      await tester.tap(find.widgetWithText(FilledButton, 'Descartar'));
      await tester.pumpAndSettle();

      verify(service.discardPreview(any)).called(1);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });

  testWidgets(
    'batch review shows empty state, navigation, pendingFields, and save error',
    (tester) async {
      final service = MockIReceiptService();
      final dependencies = testDependencies(service);
      final file1 = tempFile('review-extra-1.txt');
      final file2 = tempFile('review-extra-2.txt');
      final category = const Category(id: 1, name: 'Alimentação');
      final pronto = testReadyBatch(
        file1,
        1,
        testReceipt(fileName: file1.path, category: category),
      );
      final pendingReceipt = testReadyBatch(
        file2,
        2,
        testReceipt(
          id: 0,
          fileName: file2.path,
        ).copyWith(clearCategory: true, extractedData: null),
      );

      when(service.localFile(any)).thenAnswer((_) async => file1);
      when(service.saveConfirmed(any)).thenAnswer((invocation) async {
        final receipt = invocation.positionalArguments.first as Receipt;
        if (receipt.fileName == file2.path) {
          throw StateError('save failure');
        }
        return receipt.copyWith(id: 88);
      });

      try {
        await tester.pumpWidget(
          testHost(
            dependencies,
            const ReceiptBatchReviewPage(items: <ReceiptBatchItem>[]),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Nenhum comprovante para revisar.'), findsOne);

        await tester.pumpWidget(
          testHost(
            dependencies,
            ReceiptBatchReviewPage(items: [pronto, pendingReceipt]),
          ),
        );
        await pumpIo(tester);
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Próximo'));
        await tester.pumpAndSettle();
        expect(find.text('Revisar 2/2'), findsOne);

        await tester.tap(find.text('Salvar todos'));
        await tester.pumpAndSettle();
        expect(find.text('Salvar com campos incompletos?'), findsOne);
        await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
        await tester.pumpAndSettle();
        verify(service.saveConfirmed(any)).called(greaterThanOrEqualTo(1));
      } finally {
        await disposeTestApp(tester, dependencies);
        deleteFile(file1);
        deleteFile(file2);
      }
    },
  );

  testWidgets('batch review confirms pendingFields and saves all', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file1 = tempFile('review-pending-1.txt');
    final file2 = tempFile('review-pending-2.txt');
    final item1 = testReadyBatch(file1, 1, testReceipt(fileName: file1.path));
    final item2 = testReadyBatch(
      file2,
      2,
      testReceipt(fileName: file2.path, id: 2),
    );

    when(service.localFile(any)).thenAnswer((_) async => file1);
    when(service.saveConfirmed(any)).thenAnswer((invocation) async {
      final receipt = invocation.positionalArguments.first as Receipt;
      return receipt.copyWith(id: receipt.id == 0 ? 10 : receipt.id);
    });

    try {
      await tester.pumpWidget(
        testHost(dependencies, ReceiptBatchReviewPage(items: [item1, item2])),
      );
      await pumpIo(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar todos'));
      await tester.pumpAndSettle();

      expect(find.text('Salvar com campos incompletos?'), findsOne);
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
      await tester.pumpAndSettle();

      verify(service.saveConfirmed(any)).called(2);
      expect(find.text('Revisar 1/2'), findsNothing);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file1);
      deleteFile(file2);
    }
  });
}
