import 'dart:async';

import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/entities/extracted_data.dart';
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

  testWidgets('list uses mock to load, search, and import empty file', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service, debugMode: true);
    final receipt = testReceipt(id: 7);

    stubReceiptListPage(service, receipts: [receipt]);
    when(service.importFiles()).thenAnswer((_) async => []);

    try {
      await tester.pumpWidget(testHost(dependencies, const ReceiptListPage()));
      await tester.pumpAndSettle();

      expect(find.text('Mercado Modelo'), findsOne);
      expect(find.text('1 comprovante cadastrado'), findsOne);
      expect(find.byTooltip('Selecionar comprovantes'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'mercado');
      await tester.pumpAndSettle();

      expect(find.text('1 comprovante encontrado'), findsOne);
      verify(service.search('mercado')).called(greaterThanOrEqualTo(1));

      await tester.tap(find.byIcon(Icons.file_download_outlined));
      await tester.pump();

      expect(
        find.text('Nenhum arquivo foi recebido para importação.'),
        findsOne,
      );
      verify(service.importFiles()).called(1);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('list hides multi-selection action without visible receipts', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);

    stubReceiptListPage(service, receipts: const <Receipt>[]);

    try {
      await tester.pumpWidget(testHost(dependencies, const ReceiptListPage()));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum comprovante registrado'), findsOneWidget);
      expect(find.byTooltip('Selecionar comprovantes'), findsNothing);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('empty list keeps empty state while sort reloads', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final requests = <Completer<List<Receipt>>>[];

    when(service.watchAll()).thenAnswer((_) => const Stream.empty());
    when(service.findByFilters(any)).thenAnswer((_) {
      final completer = Completer<List<Receipt>>();
      requests.add(completer);
      return completer.future;
    });

    try {
      await tester.pumpWidget(testHost(dependencies, const ReceiptListPage()));
      await tester.pump();
      expect(find.text('Carregando comprovantes'), findsOneWidget);

      requests.single.complete(const <Receipt>[]);
      await tester.pumpAndSettle();

      expect(find.text('Nenhum comprovante registrado'), findsOneWidget);
      expect(find.text('Carregando comprovantes'), findsNothing);

      await tester.tap(find.text('Valor'));
      await tester.pump();

      expect(requests, hasLength(2));
      expect(find.text('Nenhum comprovante registrado'), findsOneWidget);
      expect(find.text('Carregando comprovantes'), findsNothing);

      requests.last.complete(const <Receipt>[]);
      await tester.pumpAndSettle();

      expect(find.text('Nenhum comprovante registrado'), findsOneWidget);
      expect(find.text('Carregando comprovantes'), findsNothing);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('list loads next receipt page near the end', (tester) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final receipts = List<Receipt>.generate(
      35,
      (index) => testReceipt(id: index + 1),
    );

    when(service.watchAll()).thenAnswer((_) => const Stream.empty());
    when(service.findByFilters(any)).thenAnswer((invocation) async {
      final filter = invocation.positionalArguments.first as ReceiptFilter;
      return receipts
          .skip(filter.offset ?? 0)
          .take(filter.limit ?? receipts.length)
          .toList();
    });

    try {
      await tester.pumpWidget(testHost(dependencies, const ReceiptListPage()));
      await tester.pumpAndSettle();

      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -1000));
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.pumpAndSettle();

      final filters = verify(
        service.findByFilters(captureAny),
      ).captured.cast<ReceiptFilter>().toList();
      expect(filters.any((filter) => filter.limit == 30), isTrue);
      expect(filters.any((filter) => filter.offset == 30), isTrue);

      await tester.tap(find.text('Valor'));
      await tester.pumpAndSettle();

      final filtersAfterSort = verify(
        service.findByFilters(captureAny),
      ).captured.cast<ReceiptFilter>().toList();
      expect(filtersAfterSort.last.offset ?? 0, 0);
      expect(filtersAfterSort.last.sortOrder, ReceiptSort.amount);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('text search paginates after applying ranked results', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final receipts = List<Receipt>.generate(
      35,
      (index) => _receiptWithEstablishment(
        id: index + 1,
        establishment: 'Mercado ${index + 1}',
      ),
    );

    when(service.watchAll()).thenAnswer((_) => const Stream.empty());
    when(service.findByFilters(any)).thenAnswer((_) async => const <Receipt>[]);
    when(service.search(any)).thenAnswer((_) async => receipts);

    try {
      await tester.pumpWidget(testHost(dependencies, const ReceiptListPage()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'mercado');
      await tester.pumpAndSettle();
      expect(find.text('Mercado 1'), findsOne);
      expect(find.text('Mercado 35'), findsNothing);

      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      verify(service.search('mercado')).called(greaterThanOrEqualTo(2));
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('stale first page response does not replace current results', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final firstRequest = Completer<List<Receipt>>();
    final secondRequest = Completer<List<Receipt>>();
    var calls = 0;

    when(service.watchAll()).thenAnswer((_) => const Stream.empty());
    when(service.findByFilters(any)).thenAnswer((_) {
      calls += 1;
      return calls == 1 ? firstRequest.future : secondRequest.future;
    });

    try {
      await tester.pumpWidget(testHost(dependencies, const ReceiptListPage()));
      await tester.pump();
      await tester.tap(find.text('Valor'));
      await tester.pump();

      firstRequest.complete([
        _receiptWithEstablishment(id: 1, establishment: 'Resultado antigo'),
      ]);
      await tester.pump();
      expect(find.text('Resultado antigo'), findsNothing);

      secondRequest.complete([
        _receiptWithEstablishment(id: 2, establishment: 'Resultado atual'),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Resultado atual'), findsOne);
      expect(find.text('Resultado antigo'), findsNothing);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });
}

Receipt _receiptWithEstablishment({
  required int id,
  required String establishment,
}) {
  return testReceipt(id: id).copyWith(
    extractedData: ExtractedData(
      id: id,
      receiptId: id,
      amount: 10,
      transactionDate: DateTime(2026, 5, id.clamp(1, 28)),
      establishment: establishment,
      paymentMethod: 'Pix',
      ocrConfidence: 0.95,
    ),
  );
}
