import 'dart:async';

import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/exceptions/storage_limit_exception.dart';
import 'package:fin_track/domain/exceptions/operation_cancelled_exception.dart';
import 'package:fin_track/presentation/camera/processing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';

import '../presentation_mockito_helpers.dart';
import '../presentation_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('processing shows error and allows retry', (tester) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file = tempFile('processing-error.txt');

    when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
    when(service.processPreview(any)).thenThrow(StateError('ocr falhou'));

    try {
      await tester.pumpWidget(
        testHost(dependencies, ProcessingPage(file: file)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Não foi possível processar o comprovante.'), findsOne);
      expect(find.text('Tentar novamente'), findsOne);
      verify(service.processPreview(any)).called(1);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Não foi possível processar o comprovante.'), findsOne);
      verify(service.processPreview(any)).called(1);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });

  testWidgets('processing finishes successfully and opens confirmation', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file = tempFile('processing-success.txt');

    when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
    when(
      service.processPreview(any),
    ).thenAnswer((_) async => testReceipt(fileName: file.path));
    when(service.localFile(any)).thenAnswer((_) async => file);

    try {
      await tester.pumpWidget(
        testHost(dependencies, ProcessingPage(file: file)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar dados'), findsOne);
      verify(service.validateSpaceForNewReceipt(file)).called(1);
      verify(service.processPreview(file)).called(1);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });

  testWidgets('processing shows timeout and storage limit', (tester) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file = tempFile('processing-timeout.txt');

    when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
    when(
      service.processPreview(any),
    ).thenAnswer((_) => Completer<Receipt>().future);

    try {
      await tester.pumpWidget(
        testHost(dependencies, ProcessingPage(file: file)),
      );
      await tester.pump(const Duration(seconds: 46));

      expect(
        find.textContaining('A leitura demorou mais que o esperado'),
        findsOne,
      );

      when(
        service.validateSpaceForNewReceipt(any),
      ).thenThrow(const StorageLimitException('limite atingido'));
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Limite de armazenamento atingido.'), findsOne);
      expect(find.textContaining('Ajuste o limite de armazenamento'), findsOne);
      await tester.pump(const Duration(seconds: 3));
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });

  testWidgets('processing cancels when service reports cancelled operation', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final file = tempFile('processing-cancelled.txt');

    when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
    when(
      service.processPreview(any),
    ).thenThrow(const OperationCancelledException());

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => ProcessingPage(file: file),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Processando'), findsNothing);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });

  testWidgets('processing confirms or cancels cancellation dialog', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final completer = Completer<Receipt>();
    final file = tempFile('processing-dialog.txt');

    when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
    when(service.processPreview(any)).thenAnswer((_) => completer.future);

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              builder: (context) {
                if (settings.name == '/processing') {
                  return ProcessingPage(file: file);
                }
                return Scaffold(
                  body: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/processing'),
                    child: const Text('Abrir processamento'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir processamento'));
      await tester.pump(const Duration(milliseconds: 300));

      unawaited(
        tester.state<NavigatorState>(find.byType(Navigator).last).maybePop(),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cancelar processamento?'), findsOne);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Processando'), findsOne);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });

  testWidgets('processing discards preview when cancelled after reading', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final receipt = testReceipt(id: 0);
    final completer = Completer<Receipt>();
    final file = tempFile('processing-discard.txt');

    when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
    when(service.processPreview(any)).thenAnswer((_) => completer.future);
    when(service.discardPreview(any)).thenAnswer((_) async {});

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              builder: (context) {
                if (settings.name == '/processing') {
                  return ProcessingPage(file: file);
                }
                return Scaffold(
                  body: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/processing'),
                    child: const Text('Abrir processamento'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir processamento'));
      await tester.pump(const Duration(milliseconds: 300));
      unawaited(
        tester.state<NavigatorState>(find.byType(Navigator).last).maybePop(),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pump();
      completer.complete(receipt);
      await tester.pump(const Duration(milliseconds: 600));

      verify(service.processPreview(file)).called(1);
      expect(find.text('Processando'), findsNothing);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });
}
