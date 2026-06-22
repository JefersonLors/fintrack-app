import 'dart:async';

import 'package:fin_track/domain/entities/category.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/value_objects/receipt_filter.dart';
import 'package:fin_track/presentation/receipts/pages/receipt_list_page.dart';
import 'package:fin_track/presentation/receipts/widgets/receipt_list_result_widgets.dart';
import 'package:fin_track/presentation/receipts/widgets/receipt_tile_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';

import '../presentation_mockito_helpers.dart';
import '../presentation_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('list exposes public search state and initial filter', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final key = GlobalKey<ReceiptListPageState>();

    stubReceiptListPage(
      service,
      receipts: [testReceipt(id: 107)],
      searchResults: const <Receipt>[],
    );

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          ReceiptListPage(
            key: key,
            autoFocusSearch: true,
            activeFilterLabel: 'Receitas',
            initialFilter: ReceiptFilter(
              text: 'mercado',
              type: ReceiptType.receipt,
              expense: false,
              startDate: DateTime(2026, 5, 1),
              endDate: DateTime(2026, 5, 31),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(key.currentState?.hasActiveSearchState, isTrue);
      expect(key.currentState?.isSelecting, isFalse);
      expect(key.currentState?.cancelSelectionMode(), isFalse);
      expect(key.currentState?.clearSearchStateIfNeeded(), isTrue);
      await tester.pumpAndSettle();
      expect(key.currentState?.hasActiveSearchState, isFalse);

      await tester.pumpWidget(
        testHost(
          dependencies,
          ReceiptListPage(
            key: key,
            activeFilterLabel: 'Sem categoria',
            initialFilter: const ReceiptFilter(withoutCategory: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sem categoria'), findsWidgets);
      expect(key.currentState?.hasActiveSearchState, isTrue);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('list filters, sorts, and shows empty search state', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);

    stubReceiptListPage(
      service,
      receipts: [testReceipt(id: 9)],
      searchResults: const <Receipt>[],
    );
    when(service.watchAll()).thenAnswer((_) => Stream.value([]));

    try {
      await tester.pumpWidget(testHost(dependencies, const ReceiptListPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Valor'));
      await tester.pumpAndSettle();
      expect(find.text('1 comprovante cadastrado'), findsOne);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      expect(find.text('Filtros'), findsOne);
      await tester.ensureVisible(find.text('Aplicar'));
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'inexistente');
      await tester.pumpAndSettle();
      expect(find.text('Nenhum resultado encontrado'), findsOne);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('list applies advanced filters with category and period', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final category = await dependencies.categoryService.create('Casa');
    final receipt = testReceipt(id: 19, category: category);

    stubReceiptListPage(service, receipts: [receipt]);

    try {
      await tester.pumpWidget(testHost(dependencies, const ReceiptListPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      expect(find.text('Filtros'), findsOne);
      expect(find.text('Casa'), findsWidgets);

      await tester.ensureVisible(find.byTooltip('Escolher período'));
      await tester.tap(find.byTooltip('Escolher período'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('23').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aplicar').last);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Limpar período'), findsOne);
      await tester.tap(find.byTooltip('Limpar período'));
      await tester.pumpAndSettle();
      expect(find.text('Selecionar intervalo'), findsOne);

      await tester.tap(find.text('Aplicar').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('20/05/2026'), findsWidgets);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('list selects all and deletes selected receipts', (tester) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final receipts = [
      testReceipt(id: 41),
      testReceipt(id: 42, category: const Category(id: 9, name: 'Casa')),
    ];

    stubReceiptList(service, receipts: receipts);
    when(service.delete(any)).thenAnswer((_) async {});

    try {
      await tester.pumpWidget(testHost(dependencies, const ReceiptListPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Selecionar comprovantes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      expect(find.text('2 selecionados'), findsOne);

      await tester.tap(find.byTooltip('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline).last);
      await tester.pumpAndSettle();
      expect(find.text('Excluir 2 comprovantes?'), findsOne);
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();

      verify(service.delete(41)).called(1);
      verify(service.delete(42)).called(1);
      expect(find.text('2 comprovantes excluídos.'), findsOne);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('list blocks navigation while deleting selected receipts', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final receipts = [testReceipt(id: 61), testReceipt(id: 62)];
    final firstDelete = Completer<void>();
    final secondDelete = Completer<void>();

    stubReceiptList(service, receipts: receipts);
    when(service.delete(61)).thenAnswer((_) => firstDelete.future);
    when(service.delete(62)).thenAnswer((_) => secondDelete.future);

    try {
      await tester.pumpWidget(testHost(dependencies, const ReceiptListPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Selecionar comprovantes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline).last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pump();

      expect(find.text('Excluindo comprovantes'), findsOneWidget);
      expect(find.text('0 de 2'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      firstDelete.complete();
      await tester.pump();
      expect(find.text('1 de 2'), findsOneWidget);

      secondDelete.complete();
      await tester.pumpAndSettle();
      expect(find.text('Excluindo comprovantes'), findsNothing);
      expect(find.text('2 comprovantes excluídos.'), findsOneWidget);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets(
    'list defers background reloads while deleting selected receipts',
    (tester) async {
      final service = MockIReceiptService();
      final dependencies = testDependencies(service);
      final changes = StreamController<List<Receipt>>();
      final firstDelete = Completer<void>();
      final secondDelete = Completer<void>();
      var receipts = [testReceipt(id: 71), testReceipt(id: 72)];

      when(service.watchAll()).thenAnswer((_) => changes.stream);
      when(service.findByFilters(any)).thenAnswer((invocation) async {
        final filter = invocation.positionalArguments.first as ReceiptFilter;
        return receipts
            .skip(filter.offset ?? 0)
            .take(filter.limit ?? receipts.length)
            .toList();
      });
      when(service.search(any)).thenAnswer((_) async => receipts);
      when(service.delete(71)).thenAnswer((_) {
        receipts = [testReceipt(id: 72)];
        changes.add(receipts);
        return firstDelete.future;
      });
      when(service.delete(72)).thenAnswer((_) {
        receipts = const <Receipt>[];
        changes.add(receipts);
        return secondDelete.future;
      });

      try {
        await tester.pumpWidget(
          testHost(dependencies, const ReceiptListPage()),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Selecionar comprovantes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Todos'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Mais opções'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.delete_outline).last);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
        await tester.pump();

        expect(find.text('Excluindo comprovantes'), findsOneWidget);
        expect(find.text('Carregando comprovantes'), findsNothing);

        firstDelete.complete();
        await tester.pump();
        expect(find.text('Excluindo comprovantes'), findsOneWidget);
        expect(find.text('Carregando comprovantes'), findsNothing);

        secondDelete.complete();
        await tester.pumpAndSettle();
        expect(find.text('Excluindo comprovantes'), findsNothing);
        expect(find.text('Carregando comprovantes'), findsNothing);
      } finally {
        await changes.close();
        await disposeTestApp(tester, dependencies);
      }
    },
  );

  testWidgets('list shows selection action errors and clears filter', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service, debugMode: true);
    final receipt = testReceipt(id: 51);

    stubReceiptListPage(service, receipts: [receipt]);
    when(service.shareImages(any)).thenThrow(StateError('share'));
    when(service.saveImagesToDevice(any)).thenThrow(StateError('save'));
    when(service.delete(any)).thenThrow(StateError('delete'));

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          const ReceiptListPage(activeFilterLabel: 'Casa'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Mercado Modelo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.share_outlined).last);
      await tester.pumpAndSettle();
      expect(find.text('Não foi possível abrir o compartilhamento.'), findsOne);

      await tester.tap(find.byTooltip('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.download_outlined).last);
      await tester.pumpAndSettle();
      verify(service.saveImagesToDevice([51])).called(1);

      await tester.tap(find.byTooltip('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline).last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();
      verify(service.delete(51)).called(1);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('results show search and pagination errors', (tester) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final receipts = [for (var i = 1; i <= 30; i++) testReceipt(id: i)];
    var retriedLoadMore = false;

    when(service.watchAll()).thenAnswer((_) => const Stream.empty());
    when(service.search(any)).thenThrow(StateError('busca'));
    when(service.findByFilters(any)).thenAnswer((invocation) async {
      final filter = invocation.positionalArguments.first as ReceiptFilter;
      if ((filter.offset ?? 0) > 0) {
        retriedLoadMore = true;
        throw StateError('mais');
      }
      return receipts;
    });

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          Scaffold(
            body: ReceiptResults(
              filter: const ReceiptFilter(text: 'mercado'),
              customSort: false,
              deferReloads: false,
              onRetry: () {},
              selecting: false,
              selectedCount: const <int>{},
              onToggleSelection: (_) {},
              onSelectVisible: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Não foi possível executar a busca.'), findsOneWidget);

      await tester.pumpWidget(
        testHost(
          dependencies,
          Scaffold(
            body: ReceiptResults(
              filter: const ReceiptFilter(),
              customSort: false,
              deferReloads: false,
              onRetry: () {},
              selecting: false,
              selectedCount: const <int>{},
              onToggleSelection: (_) {},
              onSelectVisible: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.fling(find.byType(ListView), const Offset(0, -10000), 10000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.text('Não foi possível carregar mais comprovantes.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, 'Tentar novamente'), findsOne);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Tentar novamente'));
      await tester.pumpAndSettle();
      expect(retriedLoadMore, isTrue);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('results selection, navigation and sort callbacks work', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final receipt = testReceipt(id: 501);
    final toggled = <int>[];
    final selectedVisible = <List<Receipt>>[];
    final sortChanges = <ReceiptSort>[];

    when(service.watchAll()).thenAnswer((_) => const Stream.empty());
    when(service.findByFilters(any)).thenAnswer((_) async => [receipt]);
    when(service.findById(501)).thenAnswer((_) async => receipt);

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          Scaffold(
            body: ReceiptResults(
              filter: const ReceiptFilter(),
              customSort: false,
              deferReloads: false,
              onRetry: () {},
              selecting: true,
              selectedCount: const <int>{501},
              onToggleSelection: (receipt) => toggled.add(receipt.id),
              onSelectVisible: selectedVisible.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 selecionado'), findsOneWidget);
      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      expect(selectedVisible.single.map((receipt) => receipt.id), [501]);

      await tester.tap(find.text('Mercado Modelo').first);
      await tester.pumpAndSettle();
      expect(toggled, [501]);

      await tester.pumpWidget(
        testHost(
          dependencies,
          Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: ReceiptResults(
                    filter: const ReceiptFilter(),
                    customSort: false,
                    deferReloads: false,
                    onRetry: () {},
                    selecting: false,
                    selectedCount: const <int>{},
                    onToggleSelection: (receipt) => toggled.add(receipt.id),
                    onSelectVisible: selectedVisible.add,
                  ),
                ),
                SortBar(
                  sortOrder: ReceiptSort.amount,
                  sortDirection: SortDirection.ascending,
                  onChanged: sortChanges.add,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Valor'));
      await tester.pumpAndSettle();
      expect(sortChanges, [ReceiptSort.amount]);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('results tap opens receipt detail', (tester) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final receipt = testReceipt(id: 777);
    final exported = tempFile('detail.txt');
    addTearDown(() => deleteFile(exported));

    when(service.watchAll()).thenAnswer((_) => const Stream.empty());
    when(service.findByFilters(any)).thenAnswer((_) async => [receipt]);
    when(service.findById(777)).thenAnswer((_) async => receipt);
    when(service.exportFile(777)).thenAnswer((_) async => exported);

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          Scaffold(
            body: ReceiptResults(
              filter: const ReceiptFilter(),
              customSort: false,
              deferReloads: false,
              onRetry: () {},
              selecting: false,
              selectedCount: const <int>{},
              onToggleSelection: (_) {},
              onSelectVisible: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ReceiptTile).first);
      await tester.pumpAndSettle();

      verify(service.findById(777)).called(1);
      expect(find.text('Detalhes'), findsOneWidget);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });
}
