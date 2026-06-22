import 'dart:async';

import 'package:fin_track/domain/entities/backup_record.dart';
import 'package:fin_track/domain/entities/configuration.dart';
import 'package:fin_track/main.dart';
import 'package:fin_track/presentation/theme/fin_track_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';

import '../main_app_test_helpers.dart';
import '../presentation_mockito_helpers.dart';
import '../presentation_mocks.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('runs automatic backup on start and when resuming app', (
    tester,
  ) async {
    final backupService = MockIBackupService();
    final dependencies = mainAppDependencies(backupService: backupService);
    final platform = FakeFinTrackPlatformGateway();
    when(
      backupService.runAutomaticBackupIfNeeded(),
    ).thenAnswer((_) async => null);

    await tester.pumpWidget(
      FinTrackApp(dependencies: dependencies, platformGateway: platform),
    );
    await tester.pump();

    verify(backupService.runAutomaticBackupIfNeeded()).called(1);
    expect(platform.listener, isNotNull);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    verify(backupService.runAutomaticBackupIfNeeded()).called(1);

    await disposeTestApp(tester, dependencies);
    expect(platform.listener, isNull);
  });

  testWidgets('automatic backup shows the blocking progress dialog', (
    tester,
  ) async {
    final backupService = MockIBackupService();
    final backupCompleter = Completer<BackupRecord?>();
    final dependencies = mainAppDependencies(
      backupService: backupService,
      configuration: const Configuration(
        id: 1,
        onboardingCompleted: true,
        backupReminderEnabled: true,
        linkedCloudAccount: 'account@fintrack.test',
        cloudTokenValid: true,
        backupPassword: 'password-segura',
      ),
    );
    when(
      backupService.runAutomaticBackupIfNeeded(),
    ).thenAnswer((_) => backupCompleter.future);

    await tester.pumpWidget(
      FinTrackApp(
        dependencies: dependencies,
        platformGateway: FakeFinTrackPlatformGateway(),
      ),
    );
    await pumpShortAppFrames(tester);

    expect(find.text('Fazendo backup'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.text('Aguarde enquanto seus dados são preparados e enviados.'),
      findsOneWidget,
    );

    backupCompleter.complete(testBackupRecord());
    await pumpAppFrames(tester);

    expect(find.text('Fazendo backup'), findsNothing);
    verify(backupService.runAutomaticBackupIfNeeded()).called(1);

    await disposeTestApp(tester, dependencies);
  });

  testWidgets('applies light theme from observed configuration', (
    tester,
  ) async {
    final dependencies = mainAppDependencies(
      configuration: const Configuration(
        id: 1,
        visualThemeMode: VisualThemeMode.light,
        onboardingCompleted: true,
      ),
    );

    await tester.pumpWidget(FinTrackApp(dependencies: dependencies));
    await pumpAppFrames(tester);

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final colors = materialApp.theme!.extension<FinTrackColorScheme>()!;
    expect(colors.background.toARGB32(), 0xFFF6F8FB);

    await disposeTestApp(tester, dependencies);
  });

  testWidgets('records automatic backup failure without breaking the app', (
    tester,
  ) async {
    final backupService = MockIBackupService();
    final dependencies = mainAppDependencies(backupService: backupService);
    final platform = FakeFinTrackPlatformGateway();
    when(
      backupService.runAutomaticBackupIfNeeded(),
    ).thenThrow(StateError('backup unavailable'));

    await tester.pumpWidget(
      FinTrackApp(dependencies: dependencies, platformGateway: platform),
    );
    await pumpAppFrames(tester);

    expect(find.byType(MaterialApp), findsOneWidget);
    verify(backupService.runAutomaticBackupIfNeeded()).called(1);

    await disposeTestApp(tester, dependencies);
  });
}
