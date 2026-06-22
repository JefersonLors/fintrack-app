import 'dart:async';

import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/value_objects/receipt_filter.dart';
import 'package:fin_track/presentation/receipts/widgets/receipt_list_result_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';

import '../presentation_mockito_helpers.dart';
import '../presentation_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('shows search failure and empty search results', (tester) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    var retries = 0;

    when(service.watchAll()).thenAnswer((_) => const Stream.empty());
    when(service.search(any)).thenThrow(StateError('search failed'));

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          ReceiptResults(
            filter: const ReceiptFilter(text: ' padaria '),
            customSort: false,
            deferReloads: false,
            onRetry: () => retries++,
            selecting: false,
            selectedCount: const <int>{},
            onToggleSelection: (_) {},
            onSelectVisible: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível executar a busca.'), findsOne);
      await tester.tap(find.text('Tentar novamente'));
      expect(retries, 1);

      when(service.search(any)).thenAnswer((_) async => const <Receipt>[]);
      await tester.pumpWidget(
        testHost(
          dependencies,
          ReceiptResults(
            filter: const ReceiptFilter(text: 'mercado'),
            customSort: false,
            deferReloads: false,
            onRetry: () => retries++,
            selecting: false,
            selectedCount: const <int>{},
            onToggleSelection: (_) {},
            onSelectVisible: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhum resultado encontrado'), findsOne);
      expect(
        find.text('Tente outros termos ou ajuste os filtros aplicados.'),
        findsOne,
      );
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('defers stream reloads until deferral is disabled', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final changes = StreamController<List<Receipt>>.broadcast();
    var calls = 0;

    when(service.watchAll()).thenAnswer((_) => changes.stream);
    when(service.findByFilters(any)).thenAnswer((_) async {
      calls += 1;
      return [testReceipt(id: calls, amount: calls.toDouble())];
    });

    Widget result({required bool deferReloads}) {
      return testHost(
        dependencies,
        ReceiptResults(
          filter: const ReceiptFilter(),
          customSort: false,
          deferReloads: deferReloads,
          onRetry: () {},
          selecting: false,
          selectedCount: const <int>{},
          onToggleSelection: (_) {},
          onSelectVisible: (_) {},
        ),
      );
    }

    try {
      await tester.pumpWidget(result(deferReloads: true));
      await tester.pumpAndSettle();
      expect(find.textContaining('R\$ 1,00'), findsOne);

      changes.add(const <Receipt>[]);
      await tester.pump();
      expect(calls, 1);

      await tester.pumpWidget(result(deferReloads: false));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.textContaining('R\$ 2,00'), findsOne);
    } finally {
      await changes.close();
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('shows load more progress, error and retry action', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final firstPage = List<Receipt>.generate(
      30,
      (index) => testReceipt(id: index + 1),
    );
    final secondPage = Completer<List<Receipt>>();
    var request = 0;

    when(service.watchAll()).thenAnswer((_) => const Stream.empty());
    when(service.findByFilters(any)).thenAnswer((_) {
      request += 1;
      if (request == 1) {
        return Future.value(firstPage);
      }
      if (request == 2) {
        return secondPage.future;
      }
      return Future.value([testReceipt(id: 31, amount: 31)]);
    });

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          ReceiptResults(
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
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOne);

      secondPage.completeError(StateError('page failed'));
      await tester.pumpAndSettle();
      expect(
        find.text('Não foi possível carregar mais comprovantes.'),
        findsOne,
      );

      final retryButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Tentar novamente'),
      );
      retryButton.onPressed?.call();
      await tester.pumpAndSettle();
      expect(find.textContaining('R\$ 31,00'), findsOne);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('selecting mode toggles receipts and all visible receipts', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final receipts = [testReceipt(id: 1), testReceipt(id: 2, amount: 99)];

    when(service.watchAll()).thenAnswer((_) => const Stream.empty());
    when(service.findByFilters(any)).thenAnswer((_) async => receipts);

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          Scaffold(body: _SelectableReceiptResultsHarness(receipts: receipts)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mercado Modelo').first);
      await tester.pumpAndSettle();
      expect(find.text('1 selecionado'), findsOne);

      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      expect(find.text('2 selecionados'), findsOne);
      expect(find.byIcon(Icons.check_box_outlined), findsOne);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('custom sorted search opens receipt details on tap', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final exportedFile = tempFile('detail-preview.txt');
    final lowValue = testReceipt(id: 1, amount: 1);
    final highValue = testReceipt(id: 2, amount: 99);

    when(service.watchAll()).thenAnswer((_) => const Stream.empty());
    when(service.search(any)).thenAnswer((_) async => [highValue, lowValue]);
    when(service.findById(any)).thenAnswer((invocation) async {
      final id = invocation.positionalArguments.first as int;
      return id == 1 ? lowValue : highValue;
    });
    when(service.exportFile(any)).thenAnswer((_) async => exportedFile);

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          ReceiptResults(
            filter: const ReceiptFilter(
              text: 'mercado',
              sortOrder: ReceiptSort.amount,
              sortDirection: SortDirection.ascending,
            ),
            customSort: true,
            deferReloads: false,
            onRetry: () {},
            selecting: false,
            selectedCount: const <int>{},
            onToggleSelection: (_) {},
            onSelectVisible: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('R\$ 1,00'), findsOne);

      await tester.tap(find.text('Mercado Modelo').first);
      await tester.pumpAndSettle();
      expect(find.text('Detalhes'), findsOne);
      verify(service.findById(any)).called(1);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(exportedFile);
    }
  });

  testWidgets('sort bar reports selected and unselected sort choices', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final changes = <ReceiptSort>[];

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          Scaffold(
            body: SortBar(
              sortOrder: ReceiptSort.amount,
              sortDirection: SortDirection.ascending,
              onChanged: changes.add,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Valor'));
      await tester.tap(find.text('Data'));
      await tester.pump();

      expect(changes, [ReceiptSort.amount, ReceiptSort.date]);
      expect(find.byIcon(Icons.arrow_upward), findsOne);
      expect(find.byIcon(Icons.calendar_month_outlined), findsOne);
      expect(find.byIcon(Icons.storefront_outlined), findsOne);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });
}

class _SelectableReceiptResultsHarness extends StatefulWidget {
  const _SelectableReceiptResultsHarness({required this.receipts});

  final List<Receipt> receipts;

  @override
  State<_SelectableReceiptResultsHarness> createState() =>
      _SelectableReceiptResultsHarnessState();
}

class _SelectableReceiptResultsHarnessState
    extends State<_SelectableReceiptResultsHarness> {
  final _selected = <int>{};

  @override
  Widget build(BuildContext context) {
    return ReceiptResults(
      filter: const ReceiptFilter(),
      customSort: false,
      deferReloads: false,
      onRetry: () {},
      selecting: true,
      selectedCount: _selected,
      onToggleSelection: (receipt) {
        setState(() {
          if (!_selected.add(receipt.id)) {
            _selected.remove(receipt.id);
          }
        });
      },
      onSelectVisible: (receipts) {
        setState(() {
          _selected
            ..clear()
            ..addAll(receipts.map((receipt) => receipt.id));
        });
      },
    );
  }
}
