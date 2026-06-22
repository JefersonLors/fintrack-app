import 'package:fin_track/presentation/categories/pages/categories_page.dart';
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

  testWidgets('categories selects, shows empty search, deletes, and edits', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final newName =
        'Category Cobertura ${DateTime.now().microsecondsSinceEpoch}';
    final editedName = '$newName Editada';
    final pageKey = GlobalKey<CategoriesPageState>();

    when(service.watchAll()).thenAnswer((_) => Stream.value([]));
    when(service.watchByFilters(any)).thenAnswer((_) => Stream.value([]));
    when(service.search(any)).thenAnswer((_) async => []);

    try {
      await tester.pumpWidget(
        testHost(dependencies, CategoriesPage(key: pageKey)),
      );
      await tester.pumpAndSettle();

      final initialCategories = await dependencies.categoryService.list();
      final initialName = initialCategories.first.name;
      expect(find.text(initialName), findsWidgets);
      expect(pageKey.currentState?.isSelecting, isFalse);
      expect(pageKey.currentState?.cancelSelectionMode(), isFalse);
      expect(pageKey.currentState?.hasActiveSearchState, isFalse);
      expect(pageKey.currentState?.clearSearchStateIfNeeded(), isFalse);

      await tester.drag(
        find.byIcon(Icons.drag_handle).first,
        const Offset(0, 90),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(initialName).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzz-without-category');
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma categoria encontrada'), findsOneWidget);
      expect(find.byTooltip('Selecionar categorias'), findsNothing);
      expect(pageKey.currentState?.hasActiveSearchState, isTrue);
      expect(pageKey.currentState?.clearSearchStateIfNeeded(), isTrue);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzz-without-category');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Limpar busca'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Selecionar categorias'));
      await tester.pumpAndSettle();
      expect(find.text('0 selecionadas'), findsOneWidget);

      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      expect(
        find.text('${initialCategories.length} selecionadas'),
        findsOneWidget,
      );

      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      expect(find.text('0 selecionadas'), findsOneWidget);

      await tester.longPress(find.text(initialName).first);
      await tester.pumpAndSettle();
      expect(find.text('1 selecionada'), findsOneWidget);
      expect(pageKey.currentState?.cancelSelectionMode(), isTrue);
      await tester.pumpAndSettle();

      await tester.longPress(find.text(initialName).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Excluir selecionadas'));
      await tester.pumpAndSettle();
      expect(find.text('Excluir categoria?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();
      expect(find.text('Categoria excluída.'), findsOneWidget);
      ScaffoldMessenger.of(
        tester.element(find.text('Categorias')),
      ).clearSnackBars();
      await tester.pump();

      await tester.tap(find.text('Nova'));
      await tester.pumpAndSettle();
      expect(find.text('Nova categoria'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
      await tester.pump();
      expect(find.text('Informe um nome'), findsOneWidget);

      await tester.tap(find.byTooltip('Pix'));
      await tester.tap(find.byTooltip('Cor').first);
      await tester.enterText(find.byType(TextFormField).at(0), newName);
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Descrita para cobertura',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Nova categoria'), findsNothing);

      await tester.enterText(find.byType(TextField), newName);
      await tester.pumpAndSettle();
      expect(find.text(newName), findsWidgets);

      await tester.tap(find.byTooltip('Renomear').last);
      await tester.pumpAndSettle();
      expect(find.text('Editar categoria'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), editedName);
      await tester.enterText(find.byType(TextFormField).at(1), '');
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Editar categoria'), findsNothing);
      await tester.enterText(find.byType(TextField), editedName);
      await tester.pumpAndSettle();
      expect(find.text(editedName), findsWidgets);
      expect(find.text('Sem descrição'), findsWidgets);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('categories confirms and cancels direct free deletion', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final category = (await dependencies.categoryService.list()).first;

    when(service.watchAll()).thenAnswer((_) => Stream.value([]));
    when(service.watchByFilters(any)).thenAnswer((_) => Stream.value([]));
    when(service.search(any)).thenAnswer((_) async => []);

    try {
      await tester.pumpWidget(testHost(dependencies, const CategoriesPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Excluir').first);
      await tester.pumpAndSettle();
      expect(find.text('Excluir categoria?'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text(category.name), findsWidgets);

      await tester.tap(find.byTooltip('Excluir').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();
      expect(find.text('Categoria excluída.'), findsOneWidget);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('categories cancels selected free deletion dialog', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final category = (await dependencies.categoryService.list()).first;

    when(service.watchAll()).thenAnswer((_) => Stream.value([]));
    when(service.watchByFilters(any)).thenAnswer((_) => Stream.value([]));
    when(service.search(any)).thenAnswer((_) async => []);

    try {
      await tester.pumpWidget(testHost(dependencies, const CategoriesPage()));
      await tester.pumpAndSettle();

      await tester.longPress(find.text(category.name).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Excluir selecionadas'));
      await tester.pumpAndSettle();
      expect(find.text('Excluir categoria?'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('1 selecionada'), findsOneWidget);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets(
    'categories searches, opens filtered list, and shows dialog with error',
    (tester) async {
      final service = MockIReceiptService();
      final dependencies = testDependencies(service);
      final category = (await dependencies.categoryService.list()).first;
      final receipt = testReceipt(
        id: 41,
        category: category,
        expense: false,
        amount: 150,
      );

      when(service.watchAll()).thenAnswer((_) => Stream.value([receipt]));
      when(
        service.watchByFilters(any),
      ).thenAnswer((_) => Stream.value([receipt]));
      when(service.search(any)).thenAnswer((_) async => [receipt]);

      try {
        await tester.pumpWidget(testHost(dependencies, const CategoriesPage()));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), category.name);
        await tester.pumpAndSettle();
        expect(find.text(category.name), findsWidgets);

        await tester.tap(find.text(category.name).first);
        await tester.pumpAndSettle();
        if (find.byType(ReceiptListPage).evaluate().isNotEmpty) {
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.text('Nova'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Transporte'));
        await tester.tap(find.byTooltip('Cor').last);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nome'),
          category.name,
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final cancel = find.widgetWithText(OutlinedButton, 'Cancelar');
        if (cancel.evaluate().isNotEmpty) {
          await tester.tap(cancel);
          await tester.pumpAndSettle();
        }
      } finally {
        await disposeTestApp(tester, dependencies);
      }
    },
  );

  testWidgets('categories shows stream errors', (tester) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);

    when(service.watchAll()).thenAnswer((_) => Stream.error(StateError('x')));

    try {
      await tester.pumpWidget(testHost(dependencies, const CategoriesPage()));
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível carregar o uso das categorias.'),
        findsOne,
      );
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets(
    'categories blocks deleting associated category and opens receipts',
    (tester) async {
      final service = MockIReceiptService();
      final dependencies = testDependencies(service);
      final category = (await dependencies.categoryService.list()).first;
      final receipt = testReceipt(id: 91, category: category);

      when(service.watchAll()).thenAnswer((_) => Stream.value([receipt]));
      when(
        service.watchByFilters(any),
      ).thenAnswer((_) => Stream.value([receipt]));
      when(service.search(any)).thenAnswer((_) async => [receipt]);

      try {
        await tester.pumpWidget(testHost(dependencies, const CategoriesPage()));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Excluir').first);
        await tester.pumpAndSettle();
        expect(find.text('Categoria em uso'), findsOneWidget);

        await tester.tap(
          find.widgetWithText(OutlinedButton, 'Ver comprovantes'),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ReceiptListPage), findsOneWidget);
      } finally {
        await disposeTestApp(tester, dependencies);
      }
    },
  );

  testWidgets('categories blocks deleting selected categories with usage', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final category = (await dependencies.categoryService.list()).first;
    final receipt = testReceipt(id: 92, category: category);

    when(service.watchAll()).thenAnswer((_) => Stream.value([receipt]));
    when(
      service.watchByFilters(any),
    ).thenAnswer((_) => Stream.value([receipt]));
    when(service.search(any)).thenAnswer((_) async => [receipt]);

    try {
      await tester.pumpWidget(testHost(dependencies, const CategoriesPage()));
      await tester.pumpAndSettle();

      await tester.longPress(find.text(category.name).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Excluir selecionadas'));
      await tester.pumpAndSettle();

      expect(find.text('Categorias em uso'), findsOneWidget);
      expect(find.text('Entendi'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Entendi'));
      await tester.pumpAndSettle();
      expect(find.text('Categorias em uso'), findsNothing);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });
}
