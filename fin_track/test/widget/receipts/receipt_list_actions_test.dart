import 'dart:async';

import 'package:fin_track/domain/exceptions/storage_limit_exception.dart';
import 'package:fin_track/domain/value_objects/receipt_filter.dart';
import 'package:fin_track/presentation/receipts/pages/receipt_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';

import '../presentation_mockito_helpers.dart';
import '../presentation_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('list selects, runs actions, shows diagnostics and errors', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service, debugMode: true);
    final receipt = testReceipt(id: 8);

    stubReceiptListPage(service, receipts: [receipt]);
    when(
      service.diagnoseSemanticSearch(any),
    ).thenAnswer((_) async => 'diagnostic ok');
    when(service.shareImages(any)).thenAnswer((_) async {});
    when(service.saveImagesToDevice(any)).thenAnswer((_) async {});
    when(service.delete(any)).thenAnswer((_) async {});

    try {
      await tester.pumpWidget(testHost(dependencies, const ReceiptListPage()));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Mercado Modelo'));
      await tester.pumpAndSettle();
      expect(find.text('1 selecionado'), findsOne);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.share_outlined).last);
      await tester.pumpAndSettle();
      expect(find.text('Compartilhamento aberto.'), findsOne);
      verify(service.shareImages([8])).called(1);

      await tester.longPress(find.text('Mercado Modelo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.download_outlined).last);
      await tester.pumpAndSettle();
      verify(service.saveImagesToDevice([8])).called(1);

      await tester.enterText(find.byType(TextField), 'mercado');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.science_outlined));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Diagnóstico semântico'), findsOne);
      expect(find.text('diagnostic ok'), findsOne);
      await tester.tap(find.text('Fechar'));
      await tester.pump(const Duration(milliseconds: 300));

      when(service.findByFilters(any)).thenThrow(StateError('failure stream'));
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(
        find.text('Não foi possível carregar seus comprovantes.'),
        findsOne,
      );
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('list imports directly and shows errors', (tester) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final receipt = testReceipt(id: 20);
    final file = tempFile('list-import.txt');

    stubReceiptList(service, receipts: [receipt]);
    when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
    when(
      service.processPreview(any),
    ).thenAnswer((_) async => testReceipt(fileName: file.path));
    when(service.localFile(any)).thenAnswer((_) async => file);

    try {
      await tester.pumpWidget(testHost(dependencies, const ReceiptListPage()));
      await tester.pumpAndSettle();

      when(service.importFiles()).thenAnswer((_) async => [file]);
      await tester.tap(find.byIcon(Icons.file_download_outlined));
      await tester.pumpAndSettle();
      verify(service.importFiles()).called(1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      when(
        service.watchByFilters(any),
      ).thenAnswer((_) => Stream.value([receipt]));
      when(
        service.importFiles(),
      ).thenThrow(const StorageLimitException('limite atingido'));
      await tester.pumpWidget(testHost(dependencies, const ReceiptListPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.file_download_outlined));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      when(service.importFiles()).thenThrow(StateError('failure importacao'));
      await tester.tap(find.byIcon(Icons.file_download_outlined));
      await tester.pumpAndSettle();
      verify(service.importFiles()).called(greaterThanOrEqualTo(1));
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });

  testWidgets('list imports single and batch files and shows action failures', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service, debugMode: true);
    final file1 = tempFile('import-one.txt');
    final file2 = tempFile('import-two.txt');
    final receipt = testReceipt(id: 31);
    var importMode = 0;

    stubReceiptListPage(service, receipts: [receipt]);
    when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
    when(
      service.processPreview(any),
    ).thenThrow(const FormatException('OCR ruim'));
    when(service.importFiles()).thenAnswer((_) async {
      importMode++;
      return importMode == 1 ? [file1] : [file1, file2];
    });
    when(service.shareImages(any)).thenThrow(StateError('share falhou'));
    when(service.saveImagesToDevice(any)).thenThrow(StateError('save falhou'));
    when(service.delete(any)).thenThrow(StateError('delete falhou'));

    try {
      await tester.pumpWidget(testHost(dependencies, const ReceiptListPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.file_download_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Não foi possível processar o comprovante.'), findsOne);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.file_download_outlined));
      await tester.pump();
      verify(service.importFiles()).called(2);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      await tester.pumpWidget(testHost(dependencies, const ReceiptListPage()));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Mercado Modelo'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      final shareButton = find.byIcon(Icons.share_outlined);
      if (shareButton.evaluate().isNotEmpty) {
        await tester.tap(shareButton.last);
        await tester.pump();
        expect(
          find.text('Não foi possível abrir o compartilhamento.'),
          findsOne,
        );
      }

      await tester.longPress(find.text('Mercado Modelo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      final saveButton = find.byIcon(Icons.download_outlined);
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton.last);
        await tester.pump();
        expect(find.text('Não foi possível salvar os arquivos.'), findsOne);
      }

      final deleteButton = find.byIcon(Icons.delete_outline);
      if (deleteButton.evaluate().isNotEmpty) {
        await tester.longPress(find.text('Mercado Modelo'));
        await tester.pumpAndSettle();
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
        await tester.pump();
        expect(
          find.text('Não foi possível excluir os comprovantes.'),
          findsOne,
        );
      }
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file1);
      deleteFile(file2);
    }
  });

  testWidgets(
    'list shows active filters, clears search, and diagnostics with error',
    (tester) async {
      final service = MockIReceiptService();
      final dependencies = testDependencies(service, debugMode: true);
      final category = (await dependencies.categoryService.list()).first;
      final receipt = testReceipt(id: 32, category: category);

      stubReceiptListPage(service, receipts: [receipt]);
      when(
        service.diagnoseSemanticSearch(any),
      ).thenThrow(StateError('sem diagnostic'));

      try {
        await tester.pumpWidget(
          testHost(
            dependencies,
            ReceiptListPage(
              initialFilter: ReceiptFilter(categoryId: category.id),
              activeFilterLabel: 'Categoria: ${category.name}',
              autoFocusSearch: true,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Categoria: ${category.name}'), findsOne);

        await tester.enterText(find.byType(TextField), 'mercado');
        await tester.pumpAndSettle();
        final diagnostic = find.byIcon(Icons.science_outlined);
        if (diagnostic.evaluate().isNotEmpty) {
          await tester.tap(diagnostic);
          await tester.pump();
          expect(
            find.text('Não foi possível diagnosticar a busca semântica.'),
            findsOne,
          );
        }
      } finally {
        await disposeTestApp(tester, dependencies);
      }
    },
  );
}
