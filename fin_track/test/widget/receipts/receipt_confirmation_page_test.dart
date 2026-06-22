import 'package:fin_track/domain/entities/category.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/entities/extracted_data.dart';
import 'package:fin_track/domain/exceptions/storage_limit_exception.dart';
import 'package:fin_track/presentation/receipts/pages/receipt_confirmation_page.dart';
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

  testWidgets('confirmation shows structured OCR, fallback, and save error', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service, debugMode: true);
    final file = tempFile('confirmation.pdf');
    final category = (await dependencies.categoryService.list()).first;
    final receipt =
        testReceipt(
          id: 31,
          fileName: 'confirmation.pdf',
          category: category,
        ).copyWith(
          fileType: 'application/pdf',
          extractedContent: 'text bruto do OCR',
          extractedData: ExtractedData(
            id: 31,
            receiptId: 31,
            amount: 18.9,
            transactionDate: DateTime(2026, 5, 20),
            establishment: 'Mercado Modelo',
            items: const ['Banana', 'Café'],
            paymentMethod: 'Pix',
            issuerCnpj: '12345678000199',
            accessKey: '123',
            urlQrCode: 'https://nfe.test/qr',
            documentNumber: '99',
            documentSeries: '1',
            documentState: 'BA',
            issuerLegalName: 'Mercado Modelo LTDA',
            issuerTradeName: 'Mercado Modelo',
            fiscalCnaeDescription: 'Comércio varejista',
            issuerCity: 'Salvador',
            issuerState: 'BA',
            ocrConfidence: 0.4,
            extractionParser: 'fiscal_document',
            extractionConfidence: 0.5,
            valueConfidence: 0.4,
            dateConfidence: 0.4,
            establishmentConfidence: 0.4,
            paymentMethodConfidence: 0.4,
            qualityMetadata: const {
              'ocrEstruturadoResumo': {'blocos': 1, 'lines': 2, 'elementos': 3},
              'ocrEstruturadoLinhas': ['line fiscal', '', 'total 18,90'],
            },
          ),
        );

    when(service.findById(31)).thenAnswer((_) async => receipt);
    when(service.localFile(any)).thenAnswer((_) async => file);
    when(service.update(any)).thenThrow(const FormatException('Valor ruim'));

    try {
      await tester.pumpWidget(
        testHost(dependencies, const ReceiptConfirmationPage(receiptId: 31)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirmar dados'), findsOne);
      expect(find.text('Pré-visualização indisponível'), findsOne);

      await tester.scrollUntilVisible(
        find.textContaining('Confiança OCR'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Confiança OCR'));
      await tester.pumpAndSettle();
      expect(find.text('Resultado do OCR'), findsOne);
      expect(find.textContaining('blocos=1'), findsOne);
      await tester.tap(find.text('Texto'));
      await tester.pump();
      expect(find.text('text bruto do OCR'), findsOne);
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar').last);
      await tester.pumpAndSettle();

      expect(find.text('Valor ruim'), findsOne);
      verify(service.update(any)).called(1);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });

  testWidgets('confirmation shows pendingFields, saves preview, and discards', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file = tempFile('confirmation-preview.txt');
    final previewReceipt = testReceipt(id: 0, fileName: file.path).copyWith(
      extractedData: const ExtractedData(
        id: 0,
        receiptId: 0,
        amount: null,
        transactionDate: null,
        establishment: '',
        ocrConfidence: 0.9,
        extractionParser: 'fallback',
        extractionConfidence: 0.8,
      ),
      clearCategory: true,
    );

    when(service.localFile(any)).thenAnswer((_) async => file);
    when(service.discardPreview(any)).thenAnswer((_) async {});
    when(service.saveConfirmed(any)).thenAnswer((invocation) async {
      final receipt = invocation.positionalArguments.first as Receipt;
      return receipt.copyWith(id: 101);
    });

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          ReceiptConfirmationPage(receipt: previewReceipt),
        ),
      );
      await pumpIo(tester);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar').last);
      await tester.pumpAndSettle();
      expect(find.text('Salvar com campos incompletos?'), findsOne);
      expect(
        find.textContaining('valor, data, estabelecimento e categoria'),
        findsOne,
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Revisar'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmar dados'), findsOne);

      await tester.scrollUntilVisible(
        find.text('Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar').last);
      await tester.pumpAndSettle();
      verify(service.saveConfirmed(any)).called(1);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }

    final discardService = MockIReceiptService();
    final discardDeps = testDependencies(discardService);
    final discardFile = tempFile('confirmation-discard.txt');
    when(discardService.localFile(any)).thenAnswer((_) async => discardFile);
    when(discardService.discardPreview(any)).thenAnswer((_) async {});
    try {
      await tester.pumpWidget(
        testHost(
          discardDeps,
          ReceiptConfirmationPage(
            receipt: previewReceipt.copyWith(fileName: discardFile.path),
          ),
        ),
      );
      await pumpIo(tester);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Cancelar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar').last);
      await tester.pumpAndSettle();
      expect(find.text('Descartar dados extraídos?'), findsOne);
      await tester.tap(find.widgetWithText(FilledButton, 'Descartar'));
      await tester.pumpAndSettle();
      verify(
        discardService.discardPreview(any),
      ).called(greaterThanOrEqualTo(1));
    } finally {
      await disposeTestApp(tester, discardDeps);
      deleteFile(discardFile);
    }
  });

  testWidgets('confirmation saves existing receipt and edits selectors', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    var finished = false;
    final file = tempFile('confirmation-edit.png');
    final receipt = testReceipt(
      id: 61,
      fileName: file.path,
      category: const Category(id: 1, name: 'Alimentação'),
    ).copyWith(fileType: 'image/png');

    when(service.findById(61)).thenAnswer((_) async => receipt);
    when(service.localFile(any)).thenAnswer((_) async => file);
    when(service.update(any)).thenAnswer((_) async {});

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          ReceiptConfirmationPage(
            receiptId: 61,
            onFinished: () async => finished = true,
          ),
        ),
      );
      await pumpIo(tester);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Receita'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Receita'));
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .ancestor(
              of: find.text('Forma de pagamento'),
              matching: find.byType(InkWell),
            )
            .last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dinheiro').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Limpar data'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Selecionar data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar').last);
      await tester.pumpAndSettle();

      final savedReceipt =
          verify(service.update(captureAny)).captured.single as Receipt;
      expect(savedReceipt.expense, isFalse);
      expect(savedReceipt.extractedData?.paymentMethod, 'Dinheiro');
    } finally {
      await disposeTestApp(tester, dependencies);
      expect(finished, isTrue);
      deleteFile(file);
    }
  });

  testWidgets('confirmation shows storage and generic save failures', (
    tester,
  ) async {
    final storageService = MockIReceiptService();
    final storageDeps = testDependencies(storageService);
    final storageFile = tempFile('confirmation-storage.txt');
    final category = (await storageDeps.categoryService.list()).first;
    final receipt = testReceipt(
      id: 71,
      fileName: storageFile.path,
      category: category,
    );

    when(storageService.findById(71)).thenAnswer((_) async => receipt);
    when(storageService.localFile(any)).thenAnswer((_) async => storageFile);
    when(
      storageService.update(any),
    ).thenThrow(const StorageLimitException('Sem espaço.'));

    try {
      await tester.pumpWidget(
        testHost(storageDeps, const ReceiptConfirmationPage(receiptId: 71)),
      );
      await pumpIo(tester);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar').last);
      await tester.pumpAndSettle();
      expect(find.text('Limite de armazenamento atingido.'), findsOneWidget);
      hideStorageLimitSnackBarIfVisible();
      await tester.pump();
    } finally {
      await disposeTestApp(tester, storageDeps);
      deleteFile(storageFile);
    }

    final genericService = MockIReceiptService();
    final genericDeps = testDependencies(genericService);
    final genericFile = tempFile('confirmation-generic.txt');
    when(genericService.findById(72)).thenAnswer(
      (_) async =>
          testReceipt(id: 72, fileName: genericFile.path, category: category),
    );
    when(genericService.localFile(any)).thenAnswer((_) async => genericFile);
    when(genericService.update(any)).thenThrow(StateError('boom'));

    try {
      await tester.pumpWidget(
        testHost(genericDeps, const ReceiptConfirmationPage(receiptId: 72)),
      );
      await pumpIo(tester);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar').last);
      await tester.pumpAndSettle();
      expect(find.text('Não foi possível salvar o comprovante.'), findsOne);
    } finally {
      await disposeTestApp(tester, genericDeps);
      deleteFile(genericFile);
    }
  });
}
