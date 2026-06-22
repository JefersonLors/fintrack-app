import 'dart:async';
import 'dart:io';

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

  testWidgets('shell captures through scanner and opens confirmation', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final configurationService = MockIConfigurationService();
    final dependencies = testDependencies(
      service,
      configurationService: configurationService,
    );
    final file = tempFile('shell-scan.txt');

    when(
      configurationService.watch(),
    ).thenAnswer((_) => Stream.value(testShellConfig()));
    stubShellList(service);
    when(service.validateSpaceForNewReceipt()).thenAnswer((_) async {});
    when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
    when(service.scanDocument()).thenAnswer((_) async => file);
    when(
      service.processPreview(any),
    ).thenAnswer((_) async => testReceipt(fileName: file.path));
    when(service.localFile(any)).thenAnswer((_) async => file);

    try {
      await tester.pumpWidget(testHost(dependencies, const FinTrackShell()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Escanear comprovante'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar dados'), findsOne);
      verify(service.scanDocument()).called(1);
      verify(service.processPreview(file)).called(1);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });
  testWidgets(
    'shell shows busy state and ignores a second capture while processing',
    (tester) async {
      final service = MockIReceiptService();
      final configurationService = MockIConfigurationService();
      final dependencies = testDependencies(
        service,
        configurationService: configurationService,
      );
      final completer = Completer<File>();
      final file = tempFile('shell-busy.txt');

      when(
        configurationService.watch(),
      ).thenAnswer((_) => Stream.value(testShellConfig()));
      stubShellList(service);
      when(service.validateSpaceForNewReceipt()).thenAnswer((_) async {});
      when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
      when(service.scanDocument()).thenAnswer((_) => completer.future);
      when(
        service.processPreview(any),
      ).thenAnswer((_) async => testReceipt(fileName: file.path));
      when(service.localFile(any)).thenAnswer((_) async => file);

      try {
        await tester.pumpWidget(testHost(dependencies, const FinTrackShell()));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Escanear comprovante'));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOne);

        await tester.tap(find.byTooltip('Escanear comprovante'));
        await tester.pump();
        verify(service.scanDocument()).called(1);

        completer.complete(file);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        expect(find.text('Confirmar dados'), findsOne);
      } finally {
        await disposeTestApp(tester, dependencies);
        deleteFile(file);
      }
    },
  );
}
