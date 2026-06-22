import 'dart:async';

import 'package:fin_track/domain/entities/configuration.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/presentation/onboarding/onboarding_page.dart';
import 'package:fin_track/presentation/shell/fin_track_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';

import '../presentation_mockito_helpers.dart';
import '../presentation_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('shell shows loading and onboarding according to configuration', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final configurationService = MockIConfigurationService();
    final controller = StreamController<Configuration>();
    final dependencies = testDependencies(
      service,
      configurationService: configurationService,
    );

    when(configurationService.watch()).thenAnswer((_) => controller.stream);

    try {
      await tester.pumpWidget(testHost(dependencies, const FinTrackShell()));
      await tester.pump();

      expect(find.text('Abrindo FinTrack'), findsOne);

      controller.add(const Configuration(id: 1, onboardingCompleted: false));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsOne);
    } finally {
      await controller.close();
      await disposeTestApp(tester, dependencies);
    }
  });
  testWidgets('shell navigates through tabs and horizontal gestures', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final configurationService = MockIConfigurationService();
    final dependencies = testDependencies(
      service,
      configurationService: configurationService,
    );

    when(
      configurationService.watch(),
    ).thenAnswer((_) => Stream.value(testShellConfig()));
    stubShellList(service);

    try {
      await tester.pumpWidget(testHost(dependencies, const FinTrackShell()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Categorias'));
      await tester.pumpAndSettle();
      expect(find.text('Categorias'), findsWidgets);

      await tester.tap(find.text('Relatórios'));
      await tester.pumpAndSettle();
      expect(find.text('Relatórios'), findsWidgets);

      await tester.drag(find.byType(IndexedStack), const Offset(140, 0));
      await tester.pumpAndSettle();
      expect(find.text('Categorias'), findsWidgets);

      await tester.drag(find.byType(IndexedStack), const Offset(-140, 0));
      await tester.pumpAndSettle();
      expect(find.text('Relatórios'), findsWidgets);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(IndexedStack)),
      );
      await gesture.moveBy(const Offset(20, 0));
      await gesture.cancel();
      await tester.pump();
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });
  testWidgets('shell returns to search and closes app on search back', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final configurationService = MockIConfigurationService();
    final platformCalls = <MethodCall>[];
    final dependencies = testDependencies(
      service,
      configurationService: configurationService,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });

    when(
      configurationService.watch(),
    ).thenAnswer((_) => Stream.value(testShellConfig()));
    stubShellList(service);

    try {
      await tester.pumpWidget(testHost(dependencies, const FinTrackShell()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajustes'));
      await tester.pumpAndSettle();
      expect(find.text('Configurações'), findsOne);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Nenhum comprovante registrado'), findsOne);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(
        platformCalls.where((call) => call.method == 'SystemNavigator.pop'),
        isNotEmpty,
      );
    } finally {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
      await disposeTestApp(tester, dependencies);
    }
  });
  testWidgets('shell responds to capture button vertical gestures', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final configurationService = MockIConfigurationService();
    final dependencies = testDependencies(
      service,
      configurationService: configurationService,
    );

    when(
      configurationService.watch(),
    ).thenAnswer((_) => Stream.value(testShellConfig()));
    stubShellList(service);

    try {
      await tester.pumpWidget(testHost(dependencies, const FinTrackShell()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajustes'));
      await tester.pumpAndSettle();
      expect(find.text('Configurações'), findsOne);

      await tester.drag(
        find.byTooltip('Escanear comprovante'),
        const Offset(0, -160),
      );
      await tester.pump(const Duration(milliseconds: 380));
      await tester.pump(const Duration(milliseconds: 540));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum comprovante registrado'), findsOne);

      await tester.tap(find.text('Ajustes'));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byTooltip('Escanear comprovante'),
        const Offset(0, -24),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Configurações'), findsOne);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byTooltip('Escanear comprovante')),
      );
      await gesture.moveBy(const Offset(0, -28));
      await gesture.cancel();
      await tester.pump(const Duration(milliseconds: 430));
      await tester.pumpAndSettle();
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });
  testWidgets('shell returns to search after captured receipt is saved', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final configurationService = MockIConfigurationService();
    final dependencies = testDependencies(
      service,
      configurationService: configurationService,
    );
    final file = tempFile('shell-capture-saved.txt');
    final category = (await dependencies.categoryService.list()).first;
    final preview = testReceipt(fileName: file.path, category: category);

    when(
      configurationService.watch(),
    ).thenAnswer((_) => Stream.value(testShellConfig()));
    stubShellList(service);
    when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
    when(service.scanDocument()).thenAnswer((_) async => file);
    when(service.processPreview(file)).thenAnswer((_) async => preview);
    when(service.localFile(any)).thenAnswer((_) async => file);
    when(service.saveConfirmed(any)).thenAnswer((invocation) async {
      final receipt = invocation.positionalArguments.first as Receipt;
      return receipt.copyWith(id: 301);
    });

    try {
      await tester.pumpWidget(testHost(dependencies, const FinTrackShell()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajustes'));
      await tester.pumpAndSettle();
      expect(find.text('Configurações'), findsOne);

      await tester.tap(find.byTooltip('Escanear comprovante'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Salvar'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar').last);
      await tester.pumpAndSettle();

      expect(find.text('Nenhum comprovante registrado'), findsOne);
      verify(service.saveConfirmed(any)).called(1);
    } finally {
      await disposeTestApp(tester, dependencies);
      deleteFile(file);
    }
  });
}
