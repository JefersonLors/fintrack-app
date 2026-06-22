import 'package:fin_track/presentation/receipts/receipt_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';

import '../presentation_mockito_helpers.dart';
import '../presentation_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('detail shares, saves, and deletes with mocked service', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file = tempFile('detail.txt');
    final receipt = testReceipt(id: 21, fileName: file.path);

    when(service.findById(21)).thenAnswer((_) async => receipt);
    when(service.exportFile(21)).thenAnswer((_) async => file);
    when(service.shareImage(21)).thenAnswer((_) async {});
    when(service.saveImageToDevice(21)).thenAnswer((_) async {});
    when(service.delete(21)).thenAnswer((_) async {});

    try {
      await tester.pumpWidget(
        testHost(dependencies, const ReceiptDetailPage(receiptId: 21)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detalhes'), findsOne);
      expect(find.byIcon(Icons.more_vert), findsOne);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.share_outlined).last);
      await tester.pumpAndSettle();
      expect(find.text('Compartilhamento aberto.'), findsOne);
      verify(service.shareImage(21)).called(1);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.download_outlined).last);
      await tester.pumpAndSettle();
      verify(service.saveImageToDevice(21)).called(1);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline).last);
      await tester.pumpAndSettle();
      expect(find.text('Excluir comprovante?'), findsOne);

      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();
      verify(service.delete(21)).called(1);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });

  testWidgets('detail shows unavailable preview and load error', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file = tempFile('receipt.pdf');
    final receipt = testReceipt(
      id: 22,
      fileName: 'receipt.pdf',
    ).copyWith(fileType: 'application/pdf');

    when(service.findById(22)).thenAnswer((_) async => receipt);
    when(service.exportFile(22)).thenAnswer((_) async => file);

    try {
      await tester.pumpWidget(
        testHost(dependencies, const ReceiptDetailPage(receiptId: 22)),
      );
      await tester.pumpAndSettle();

      expect(find.text('receipt.pdf'), findsOne);
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOne);

      when(service.findById(23)).thenThrow(StateError('failure'));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(
        testHost(
          dependencies,
          const ReceiptDetailPage(
            key: ValueKey('detail-with-error'),
            receiptId: 23,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível abrir este comprovante.'), findsOne);
      expect(find.text('Tentar novamente'), findsOne);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });

  testWidgets('detail shows action errors and cancels deletion', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file = tempFile('detail-errors.png');
    final receipt = testReceipt(
      id: 23,
      fileName: file.path,
    ).copyWith(fileType: 'image/png');

    when(service.findById(23)).thenAnswer((_) async => receipt);
    when(service.exportFile(23)).thenAnswer((_) async => file);
    when(service.shareImage(23)).thenThrow(StateError('share'));
    when(service.saveImageToDevice(23)).thenThrow(StateError('save'));
    when(service.delete(23)).thenAnswer((_) async {});

    try {
      await tester.pumpWidget(
        testHost(dependencies, const ReceiptDetailPage(receiptId: 23)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.share_outlined).last);
      await tester.pumpAndSettle();
      expect(find.text('Não foi possível abrir o compartilhamento.'), findsOne);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.download_outlined).last);
      await tester.pumpAndSettle();
      verify(service.saveImageToDevice(23)).called(1);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline).last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
      await tester.pumpAndSettle();
      verifyNever(service.delete(23));
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });
}
