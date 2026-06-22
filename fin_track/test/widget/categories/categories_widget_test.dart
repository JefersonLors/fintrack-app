import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/presentation/categories/pages/categories_page.dart';
import 'package:fin_track/presentation/widgets/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widget_test_helpers.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('creates category through modal without dependent error', (
    tester,
  ) async {
    final dependencies = widgetDependencies();
    addTearDown(() async {
      await disposeWidgetDependencies(tester, dependencies);
    });

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: const MaterialApp(home: CategoriesPage()),
      ),
    );
    await pumpFrames(tester);

    await tester.tap(find.text('Nova'));
    await tester.pumpAndSettle();

    expect(find.text('Nova categoria'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome'),
      'Doações',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descrição'),
      'Serviços recorrentes',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      (await dependencies.categoryService.list()).any(
        (category) => category.name == 'Doações',
      ),
      isTrue,
    );

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets('informs when associated category cannot be deleted', (
    tester,
  ) async {
    final dependencies = widgetDependencies();
    addTearDown(() async {
      await disposeWidgetDependencies(tester, dependencies);
    });

    final category = (await dependencies.categoryService.list()).first;
    await saveTestReceipt(
      tester,
      dependencies,
      Receipt(
        id: 1,
        type: ReceiptType.invoice,
        expense: true,
        fileName: 'category_in_use.txt',
        fileType: 'text/plain',
        registeredAt: DateTime(2026, 4, 30),
        category: category,
      ),
    );

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: const MaterialApp(home: CategoriesPage()),
      ),
    );
    await pumpFrames(tester);

    await tester.tap(find.byTooltip('Excluir').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Categoria em uso'), findsOneWidget);
    expect(find.textContaining('está associada'), findsOneWidget);
    expect(find.text('Excluir categoria?'), findsNothing);

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets('informs when selection includes associated category', (
    tester,
  ) async {
    final dependencies = widgetDependencies();
    addTearDown(() async {
      await disposeWidgetDependencies(tester, dependencies);
    });

    final categories = await dependencies.categoryService.list();
    final assignedCategory = categories.first;
    final freeCategory = categories.firstWhere(
      (item) => item.id != assignedCategory.id,
    );
    await saveTestReceipt(
      tester,
      dependencies,
      Receipt(
        id: 1,
        type: ReceiptType.invoice,
        expense: true,
        fileName: 'category_selection_in_use.txt',
        fileType: 'text/plain',
        registeredAt: DateTime(2026, 4, 30),
        category: assignedCategory,
      ),
    );

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: const MaterialApp(home: CategoriesPage()),
      ),
    );
    await pumpFrames(tester);

    await tester.tap(find.byTooltip('Selecionar categorias'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(assignedCategory.name).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(freeCategory.name).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Excluir selecionadas'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Categorias em uso'), findsOneWidget);
    expect(find.textContaining('associada'), findsOneWidget);
    expect(find.textContaining(assignedCategory.name), findsWidgets);

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets('categories edits with validation and deletes free selection', (
    tester,
  ) async {
    final dependencies = widgetDependencies();
    addTearDown(() async {
      await disposeWidgetDependencies(tester, dependencies);
    });

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: const MaterialApp(home: CategoriesPage()),
      ),
    );
    await pumpFrames(tester);

    final categoriesBefore = await dependencies.categoryService.list();
    final firstCategory = categoriesBefore.first;

    await tester.tap(find.byTooltip('Renomear').first);
    await tester.pumpAndSettle();
    expect(find.text('Editar categoria'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome'), '');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um nome'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome'),
      'Category Revisada',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(
      (await dependencies.categoryService.list())
          .singleWhere((category) => category.id == firstCategory.id)
          .name,
      'Category Revisada',
    );

    await tester.tap(find.byTooltip('Selecionar categorias'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Excluir selecionadas'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(await dependencies.categoryService.list(), isEmpty);

    await disposeWidgetDependencies(tester, dependencies);
  });
}
