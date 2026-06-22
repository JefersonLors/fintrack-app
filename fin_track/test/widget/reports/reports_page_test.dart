import 'package:fin_track/bootstrap/fin_track_dependencies.dart';
import 'package:fin_track/domain/entities/category.dart';
import 'package:fin_track/domain/entities/extracted_data.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/presentation/reports/reports_page.dart';
import 'package:fin_track/presentation/theme/fin_track_theme.dart';
import 'package:fin_track/presentation/widgets/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';

import '../presentation_mockito_helpers.dart';
import '../presentation_mocks.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('reports renders empty state with local dependencies', (
    tester,
  ) async {
    final dependencies = FinTrackDependencies.local();

    try {
      await tester.pumpWidget(
        AppScope(dependencies: dependencies, child: _host(const ReportsPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Relatórios'), findsOneWidget);
      expect(find.text('Sem dados no período'), findsOneWidget);
      expect(find.textContaining('R\$'), findsWidgets);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      dependencies.dispose();
    }
  });

  testWidgets('reports shows error state and retries stream build', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);

    when(
      service.watchAll(),
    ).thenAnswer((_) => Stream<List<Receipt>>.error(StateError('falha')));

    try {
      await tester.pumpWidget(testHost(dependencies, const ReportsPage()));
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível gerar os relatórios.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      verify(service.watchAll()).called(greaterThanOrEqualTo(2));
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('reports shows date, period, and drilldown', (tester) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final foodCategory = const Category(id: 1, name: 'Alimentação');
    final salaryCategory = const Category(id: 2, name: 'Salário');
    final today = DateTime.now();
    final data = [
      testReceipt(id: 1, category: foodCategory, amount: 120, data: today),
      testReceipt(
        id: 2,
        category: salaryCategory,
        amount: 3000,
        expense: false,
        data: today,
      ),
      testReceipt(id: 3, amount: 40, data: DateTime(2020, 1, 1)),
      testReceipt(id: 4).copyWith(
        extractedData: const ExtractedData(
          id: 4,
          receiptId: 4,
          amount: 15,
          establishment: 'Sem data',
        ),
      ),
    ];

    when(service.watchAll()).thenAnswer((_) => Stream.value(data));
    stubReceiptListPage(service, receipts: [data.first]);
    stubReceiptStorage(service);

    try {
      await tester.pumpWidget(testHost(dependencies, const ReportsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Receitas'), findsWidgets);
      expect(find.text('Despesas'), findsWidgets);
      expect(find.textContaining('comprovante'), findsWidgets);

      await tester.tap(find.text('Receitas').first);
      await tester.pumpAndSettle();
      verify(service.findByFilters(any)).called(greaterThanOrEqualTo(1));
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Despesas').first);
      await tester.pumpAndSettle();
      verify(service.findByFilters(any)).called(greaterThanOrEqualTo(1));
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hoje'));
      await tester.pumpAndSettle();
      expect(find.textContaining('comprovante'), findsWidgets);

      await tester.scrollUntilVisible(
        find.text('Alimentação'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Alimentação'), findsOne);

      await tester.tap(find.text('Alimentação'));
      await tester.pumpAndSettle();
      verify(service.findByFilters(any)).called(greaterThanOrEqualTo(1));
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Recibo').first,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Recibo').first);
      await tester.pumpAndSettle();
      verify(service.findByFilters(any)).called(greaterThanOrEqualTo(1));
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });
}

Widget _host(Widget child) {
  return MaterialApp(theme: FinTrackTheme.light(), home: child);
}
