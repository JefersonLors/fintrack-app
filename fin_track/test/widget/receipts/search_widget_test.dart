import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/entities/extracted_data.dart';
import 'package:fin_track/main.dart';
import 'package:fin_track/presentation/receipts/receipt_detail_page.dart';
import 'package:fin_track/presentation/receipts/pages/receipt_confirmation_page.dart';
import 'package:fin_track/presentation/shell/fin_track_shell.dart';
import 'package:fin_track/presentation/widgets/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widget_test_helpers.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('back button in search unfocuses and then clears query', (
    tester,
  ) async {
    final dependencies = widgetDependencies();
    addTearDown(() async {
      await disposeWidgetDependencies(tester, dependencies);
    });
    await dependencies.configurationService.update(
      (await dependencies.configurationService.load()).copyWith(
        onboardingCompleted: true,
      ),
    );

    await tester.pumpWidget(FinTrackApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'mercado');
    await tester.pumpAndSettle();

    expect(find.text('mercado'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    var searchField = tester.widget<TextField>(find.byType(TextField).first);
    expect(searchField.controller?.text, 'mercado');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    searchField = tester.widget<TextField>(find.byType(TextField).first);
    expect(searchField.controller?.text, isEmpty);
    expect(find.text('Nenhum comprovante registrado'), findsOneWidget);

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets('search inspection appears only in debug mode', (tester) async {
    final dependencies = widgetDependencies();
    addTearDown(() async {
      await disposeWidgetDependencies(tester, dependencies);
    });
    await dependencies.configurationService.update(
      (await dependencies.configurationService.load()).copyWith(
        onboardingCompleted: true,
      ),
    );

    await tester.pumpWidget(FinTrackApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'mercado');
    await tester.pumpAndSettle();

    expect(find.byTooltip('Diagnosticar busca semântica'), findsNothing);

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets('search inspection opens diagnostics in debug mode', (
    tester,
  ) async {
    final dependencies = widgetDependencies(debugMode: true);
    addTearDown(() async {
      await disposeWidgetDependencies(tester, dependencies);
    });
    await dependencies.configurationService.update(
      (await dependencies.configurationService.load()).copyWith(
        onboardingCompleted: true,
      ),
    );

    await tester.pumpWidget(FinTrackApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'mercado');
    await tester.pumpAndSettle();

    expect(find.byTooltip('Diagnosticar busca semântica'), findsOneWidget);

    await tester.tap(find.byTooltip('Diagnosticar busca semântica'));
    await pumpFrames(tester);

    expect(find.text('Diagnóstico semântico'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Fechar'));
    await pumpFrames(tester);

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets('preserves context when reopening app from background', (
    tester,
  ) async {
    final dependencies = widgetDependencies();
    final navigatorKey = GlobalKey<NavigatorState>();
    addTearDown(() async {
      await disposeWidgetDependencies(tester, dependencies);
    });
    await dependencies.configurationService.update(
      (await dependencies.configurationService.load()).copyWith(
        onboardingCompleted: true,
      ),
    );

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const FinTrackShell(),
        ),
      ),
    );
    await pumpFrames(tester);

    await tester.tap(find.text('Ajustes'));
    await pumpFrames(tester);
    expect(find.text('Configurações'), findsOneWidget);

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Detalhe aberto')),
      ),
    );
    await pumpFrames(tester);
    expect(find.text('Detalhe aberto'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpFrames(tester);

    expect(find.text('Detalhe aberto'), findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets('opens confirmation and details without inherited widget error', (
    tester,
  ) async {
    final dependencies = widgetDependencies();
    addTearDown(() async {
      await disposeWidgetDependencies(tester, dependencies);
    });

    final category = (await dependencies.categoryService.list()).first;
    final receipt = await saveTestReceipt(
      tester,
      dependencies,
      Receipt(
        id: 1,
        type: ReceiptType.invoice,
        expense: true,
        fileName: 'fixture_widget.txt',
        fileType: 'text/plain',
        extractedContent: 'Mercado Central\nTotal R\$ 128,45',
        registeredAt: DateTime(2026, 4, 29),
        extractedData: ExtractedData(
          id: 1,
          receiptId: 1,
          amount: 128.45,
          transactionDate: DateTime(2026, 4, 29),
          establishment: 'Mercado Central',
          paymentMethod: 'Cartao de credito',
          ocrConfidence: 0.92,
        ),
        category: category,
      ),
    );

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: MaterialApp(
          home: ReceiptConfirmationPage(receiptId: receipt.id),
        ),
      ),
    );
    await pumpFrames(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Confirmar dados'), findsOneWidget);

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: MaterialApp(home: ReceiptDetailPage(receiptId: receipt.id)),
      ),
    );
    await pumpFrames(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Detalhes'), findsOneWidget);
    expect(find.text('Texto extraído'), findsNothing);

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets('keeps OCR dialog hidden when debug mode is inactive', (
    tester,
  ) async {
    final dependencies = widgetDependencies();
    addTearDown(() async {
      await disposeWidgetDependencies(tester, dependencies);
    });

    final category = (await dependencies.categoryService.list()).first;
    final receipt = await saveTestReceipt(
      tester,
      dependencies,
      Receipt(
        id: 1,
        type: ReceiptType.invoice,
        expense: true,
        fileName: 'ocr_edit_widget.txt',
        fileType: 'text/plain',
        extractedContent: 'Mercado Central\nTotal R\$ 128,45',
        registeredAt: DateTime(2026, 4, 30),
        extractedData: ExtractedData(
          id: 1,
          receiptId: 1,
          amount: 128.45,
          transactionDate: DateTime(2026, 4, 30),
          establishment: 'Mercado Central',
          paymentMethod: 'Cartao de credito',
          ocrConfidence: 0.58,
        ),
        category: category,
      ),
    );

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: MaterialApp(
          home: ReceiptConfirmationPage(receiptId: receipt.id),
        ),
      ),
    );
    await pumpFrames(tester);

    await tester.scrollUntilVisible(
      find.text('Confiança OCR 58%'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpFrames(tester);
    expect(find.text('Confiança OCR 58%'), findsOneWidget);
    expect(find.text('Resultado do OCR'), findsNothing);

    await tester.tap(find.text('Confiança OCR 58%'));
    await pumpFrames(tester);
    expect(find.text('Resultado do OCR'), findsNothing);

    final savedReceipt = await tester
        .runAsync(() => dependencies.receiptService.findById(receipt.id))
        .then((value) => value!);
    expect(savedReceipt.extractedContent, contains('Mercado Central'));
    expect(savedReceipt.embedding, isNotNull);

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets('shows OCR dialog when debug mode is active', (tester) async {
    final dependencies = widgetDependencies(debugMode: true);
    addTearDown(() async {
      await disposeWidgetDependencies(tester, dependencies);
    });

    final category = (await dependencies.categoryService.list()).first;
    final receipt = await saveTestReceipt(
      tester,
      dependencies,
      Receipt(
        id: 1,
        type: ReceiptType.invoice,
        expense: true,
        fileName: 'ocr_debug_widget.txt',
        fileType: 'text/plain',
        extractedContent: 'Mercado Central\nTotal R\$ 128,45',
        registeredAt: DateTime(2026, 4, 30),
        extractedData: ExtractedData(
          id: 1,
          receiptId: 1,
          amount: 128.45,
          transactionDate: DateTime(2026, 4, 30),
          establishment: 'Mercado Central',
          paymentMethod: 'Cartao de credito',
          ocrConfidence: 0.58,
        ),
        category: category,
      ),
    );

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: MaterialApp(
          home: ReceiptConfirmationPage(receiptId: receipt.id),
        ),
      ),
    );
    await pumpFrames(tester);

    await tester.scrollUntilVisible(
      find.text('Confiança OCR 58%'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpFrames(tester);
    expect(find.text('Resultado do OCR'), findsNothing);

    await tester.tap(find.text('Confiança OCR 58%'));
    await pumpFrames(tester);
    expect(find.text('Resultado do OCR'), findsOneWidget);
    expect(find.text('Mercado Central\nTotal R\$ 128,45'), findsOneWidget);
    expect(find.text('Fechar'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Fechar'));
    await tester.pumpAndSettle();
    expect(find.text('Resultado do OCR'), findsNothing);

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets('edits type, category, and payment method in confirmation', (
    tester,
  ) async {
    final dependencies = widgetDependencies();
    addTearDown(() async {
      await disposeWidgetDependencies(tester, dependencies);
    });

    final categories = await dependencies.categoryService.list();
    final currentCategories = categories.first;
    final newCategories = categories[1];
    final receipt = await saveTestReceipt(
      tester,
      dependencies,
      Receipt(
        id: 1,
        type: ReceiptType.invoice,
        expense: true,
        fileName: 'edit_dropdowns.txt',
        fileType: 'text/plain',
        extractedContent: 'Loja Central\nTotal R\$ 42,00',
        registeredAt: DateTime(2026, 4, 30),
        extractedData: ExtractedData(
          id: 1,
          receiptId: 1,
          amount: 42,
          transactionDate: DateTime(2026, 4, 30),
          establishment: 'Loja Central',
          paymentMethod: 'Cartao de credito',
          ocrConfidence: 0.92,
        ),
        category: currentCategories,
      ),
    );

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: MaterialApp(
          home: ReceiptConfirmationPage(receiptId: receipt.id),
        ),
      ),
    );
    await pumpFrames(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Nota fiscal'), findsOneWidget);
    expect(find.text('Cartão de crédito'), findsOneWidget);
    expect(find.text('42,00'), findsOneWidget);
    expect(find.text('30/04/2026'), findsOneWidget);

    await tester.tap(find.text('Nota fiscal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Outros').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cartão de crédito'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PIX').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text(currentCategories.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text(newCategories.name).last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Salvar'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    final savedReceipt = await tester
        .runAsync(() => dependencies.receiptService.findById(receipt.id))
        .then((value) => value!);
    expect(savedReceipt.type, ReceiptType.other);
    expect(savedReceipt.extractedData?.paymentMethod, 'PIX');
    expect(savedReceipt.category?.id, newCategories.id);

    await disposeWidgetDependencies(tester, dependencies);
  });
}
