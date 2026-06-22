import 'dart:async';

import 'package:fin_track/bootstrap/fin_track_dependencies.dart';
import 'package:fin_track/domain/exceptions/storage_limit_exception.dart';
import 'package:fin_track/domain/exceptions/operation_cancelled_exception.dart';
import 'package:fin_track/presentation/shell/fin_track_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';

import '../presentation_mockito_helpers.dart';
import '../presentation_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets(
    'shell uses camera fallback and handles cancellation and errors',
    (tester) async {
      final file = tempFile('shell-camera.txt');

      Future<FinTrackDependencies> pumpShell(
        MockIReceiptService service,
        MockIConfigurationService configurationService,
      ) async {
        final dependencies = testDependencies(
          service,
          configurationService: configurationService,
        );
        when(
          configurationService.watch(),
        ).thenAnswer((_) => Stream.value(testShellConfig()));
        stubShellList(service);
        await tester.pumpWidget(testHost(dependencies, const FinTrackShell()));
        await tester.pumpAndSettle();
        return dependencies;
      }

      final scannerFailure = MockIReceiptService();
      final scannerFailureConfig = MockIConfigurationService();
      final scannerFailureDeps = testDependencies(
        scannerFailure,
        configurationService: scannerFailureConfig,
      );
      when(
        scannerFailureConfig.watch(),
      ).thenAnswer((_) => Stream.value(testShellConfig()));
      stubShellList(scannerFailure);
      when(
        scannerFailure.validateSpaceForNewReceipt(),
      ).thenAnswer((_) async {});
      when(
        scannerFailure.validateSpaceForNewReceipt(any),
      ).thenAnswer((_) async {});
      when(scannerFailure.scanDocument()).thenThrow(const FormatException());
      when(scannerFailure.captureImage()).thenAnswer((_) async => file);
      when(
        scannerFailure.processPreview(any),
      ).thenAnswer((_) async => testReceipt(fileName: file.path));
      when(scannerFailure.localFile(any)).thenAnswer((_) async => file);

      try {
        await tester.pumpWidget(
          testHost(scannerFailureDeps, const FinTrackShell()),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Escanear comprovante'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Scanner indisponível'), findsOne);
        await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        verifyNever(scannerFailure.captureImage());

        await tester.tap(find.byTooltip('Escanear comprovante'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.widgetWithText(FilledButton, 'Usar câmera'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        expect(find.text('Confirmar dados'), findsOne);
        verify(scannerFailure.captureImage()).called(1);
      } finally {
        await disposeTestApp(tester, scannerFailureDeps);
      }

      final canceledService = MockIReceiptService();
      final canceledConfig = MockIConfigurationService();
      final canceledDeps = await pumpShell(canceledService, canceledConfig);
      when(
        canceledService.validateSpaceForNewReceipt(),
      ).thenAnswer((_) async {});
      when(
        canceledService.scanDocument(),
      ).thenThrow(const OperationCancelledException());
      await tester.tap(find.byTooltip('Escanear comprovante'));
      await tester.pumpAndSettle();
      verify(canceledService.scanDocument()).called(1);
      verifyNever(canceledService.captureImage());
      await disposeTestApp(tester, canceledDeps);

      final limit = MockIReceiptService();
      final limitConfig = MockIConfigurationService();
      final limitDeps = await pumpShell(limit, limitConfig);
      when(
        limit.validateSpaceForNewReceipt(),
      ).thenThrow(const StorageLimitException('Limite atingido.'));
      await tester.tap(find.byTooltip('Escanear comprovante'));
      await tester.pump();
      expect(find.textContaining('Limite'), findsWidgets);
      await tester.pump(const Duration(seconds: 5));
      await disposeTestApp(tester, limitDeps);

      final genericService = MockIReceiptService();
      final genericConfig = MockIConfigurationService();
      final genericDeps = await pumpShell(genericService, genericConfig);
      when(
        genericService.validateSpaceForNewReceipt(),
      ).thenAnswer((_) async {});
      when(genericService.scanDocument()).thenThrow(StateError('falhou'));
      await tester.tap(find.byTooltip('Escanear comprovante'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await disposeTestApp(tester, genericDeps);

      deleteFile(file);
    },
  );
  testWidgets('shell shows snackbar on generic error after scanner', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final configurationService = MockIConfigurationService();
    final dependencies = testDependencies(
      service,
      configurationService: configurationService,
    );
    final file = tempFile('shell-validation-error.txt');

    when(
      configurationService.watch(),
    ).thenAnswer((_) => Stream.value(testShellConfig()));
    stubShellList(service);
    when(service.validateSpaceForNewReceipt()).thenAnswer((_) async {});
    when(
      service.validateSpaceForNewReceipt(any),
    ).thenThrow(StateError('failure depois do scanner'));
    when(service.scanDocument()).thenAnswer((_) async => file);

    try {
      await tester.pumpWidget(testHost(dependencies, const FinTrackShell()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Escanear comprovante'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Não foi possível capturar o comprovante.'), findsOne);
      await tester.pump(const Duration(seconds: 5));
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });
}
