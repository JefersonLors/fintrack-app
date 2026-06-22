import 'dart:async';

import 'package:fin_track/domain/entities/cloud_provider.dart';
import 'package:fin_track/domain/entities/configuration.dart';
import 'package:fin_track/domain/entities/backup_record.dart';
import 'package:fin_track/domain/exceptions/storage_limit_exception.dart';
import 'package:fin_track/presentation/backup/pages/backup_page.dart';
import 'package:fin_track/presentation/backup/widgets/backup_history_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';

import '../presentation_mockito_helpers.dart';
import '../presentation_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('backup shows states and runs main operations', (tester) async {
    final receiptService = MockIReceiptService();
    final backupService = MockIBackupService();
    final configurationService = MockIConfigurationService();
    final configController = StreamController<Configuration>();
    final backup = testBackupRecord();
    final dependencies = testDependencies(
      receiptService,
      backupService: backupService,
      configurationService: configurationService,
    );

    when(configurationService.verifyCloudToken()).thenAnswer((_) async => true);
    when(
      configurationService.watch(),
    ).thenAnswer((_) => configController.stream);
    when(
      backupService.watchRecords(),
    ).thenAnswer((_) => Stream.value([backup]));
    when(
      backupService.exportBackup(password: anyNamed('password')),
    ).thenAnswer((_) async => backup);
    when(
      backupService.restoreBackup(password: anyNamed('password')),
    ).thenAnswer(
      (_) async => backup.copyWith(operation: BackupOperation.restore),
    );
    when(backupService.clearHistory()).thenAnswer((_) async {});

    try {
      await tester.pumpWidget(testHost(dependencies, const BackupPage()));
      await tester.pump();
      configController.add(testConfigBackup());
      await tester.pumpAndSettle();

      expect(find.text('Google Drive'), findsWidgets);
      expect(find.text('account@fintrack.test'), findsOne);
      expect(find.text('Backup'), findsWidgets);
      expect(find.text('Ativo'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Backup'));
      await tester.pumpAndSettle();
      expect(find.text('Backup concluído.'), findsOne);
      verify(backupService.exportBackup(password: 'password-segura')).called(1);

      await tester.tap(find.text('Restaurar'));
      await tester.pumpAndSettle();
      expect(find.text('Restaurar backup?'), findsOne);
      await tester.tap(find.widgetWithText(FilledButton, 'Restaurar').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Senha'),
        'password-segura',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Restaurar').last);
      await tester.pumpAndSettle();
      verify(
        backupService.restoreBackup(password: 'password-segura'),
      ).called(1);

      await tester.tap(find.byTooltip('Apagar histórico'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Apagar'));
      await tester.pumpAndSettle();
      verify(backupService.clearHistory()).called(1);

      configController.add(const Configuration(id: 1));
      await tester.pumpAndSettle();
      expect(find.text('Não vinculado'), findsOne);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('Limpar nuvem'), findsOneWidget);
      expect(
        find.text('Toque para vincular uma conta de armazenamento em nuvem.'),
        findsOne,
      );
    } finally {
      await configController.close();
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('backup links, unlinks and shows failures and missing password', (
    tester,
  ) async {
    final receiptService = MockIReceiptService();
    final backupService = MockIBackupService();
    final configurationService = MockIConfigurationService();
    final dependencies = testDependencies(
      receiptService,
      backupService: backupService,
      configurationService: configurationService,
    );
    final failure = testBackupRecord().copyWith(
      status: BackupStatus.failure,
      errorDescription: 'Drive recusou o backup',
    );

    when(configurationService.verifyCloudToken()).thenAnswer((_) async => true);
    when(
      configurationService.watch(),
    ).thenAnswer((_) => Stream.value(testConfigBackup()));
    when(
      backupService.watchRecords(),
    ).thenAnswer((_) => Stream.value([failure]));
    when(
      configurationService.linkCloud(CloudProvider.googleDrive),
    ).thenAnswer((_) async {});
    when(configurationService.unlinkCloud()).thenAnswer((_) async {});
    when(
      backupService.exportBackup(password: anyNamed('password')),
    ).thenAnswer((_) async => failure);
    when(
      backupService.deleteBackup(password: anyNamed('password')),
    ).thenThrow(const FormatException('Senha inválida.'));

    try {
      await tester.pumpWidget(testHost(dependencies, const BackupPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Backup'));
      await tester.pumpAndSettle();
      expect(find.text('Drive recusou o backup'), findsOne);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Limpar nuvem'));
      await tester.pumpAndSettle();
      expect(find.text('Limpar dados da nuvem?'), findsOne);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Limpar nuvem'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Limpar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Limpar'));
      await tester.pump();
      expect(find.text('Use pelo menos 8 caracteres.'), findsOne);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Senha'),
        'password-ok',
      );
      await tester.tap(find.byTooltip('Mostrar senha'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Limpar'));
      await tester.pump();
      verify(backupService.deleteBackup(password: 'password-ok')).called(1);

      await tester.tap(find.text('Google Drive').first);
      await tester.pumpAndSettle();
      expect(find.text('Desvincular conta de nuvem'), findsOne);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Google Drive').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Desvincular'));
      await tester.pumpAndSettle();
      verify(configurationService.unlinkCloud()).called(1);

      await tester.tap(find.widgetWithText(ListTile, 'Backup'));
      await tester.pumpAndSettle();
      expect(find.text('Detalhes do backup'), findsOne);
      expect(find.text('Drive recusou o backup'), findsWidgets);
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('backup operations show a blocking progress dialog', (
    tester,
  ) async {
    final receiptService = MockIReceiptService();
    final backupService = MockIBackupService();
    final configurationService = MockIConfigurationService();
    final backupCompleter = Completer<BackupRecord>();
    final dependencies = testDependencies(
      receiptService,
      backupService: backupService,
      configurationService: configurationService,
    );

    when(configurationService.verifyCloudToken()).thenAnswer((_) async => true);
    when(
      configurationService.watch(),
    ).thenAnswer((_) => Stream.value(testConfigBackup()));
    when(
      backupService.watchRecords(),
    ).thenAnswer((_) => Stream.value([testBackupRecord()]));
    when(
      backupService.exportBackup(password: anyNamed('password')),
    ).thenAnswer((_) => backupCompleter.future);

    try {
      await tester.pumpWidget(testHost(dependencies, const BackupPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Backup'));
      await tester.pump();
      expect(find.text('Fazendo backup'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.text('Aguarde enquanto seus dados são preparados e enviados.'),
        findsOneWidget,
      );

      backupCompleter.complete(testBackupRecord());
      await tester.pumpAndSettle();
      expect(find.text('Fazendo backup'), findsNothing);
      expect(find.text('Backup concluído.'), findsOneWidget);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('backup shows restore history and generic errors', (
    tester,
  ) async {
    final receiptService = MockIReceiptService();
    final backupService = MockIBackupService();
    final configurationService = MockIConfigurationService();
    final dependencies = testDependencies(
      receiptService,
      backupService: backupService,
      configurationService: configurationService,
    );
    final restoreRecord = testBackupRecord().copyWith(
      operation: BackupOperation.restore,
      status: BackupStatus.synced,
      availability: BackupAvailability.deleted,
    );

    when(configurationService.verifyCloudToken()).thenAnswer((_) async => true);
    when(
      configurationService.watch(),
    ).thenAnswer((_) => Stream.value(testConfigBackup()));
    when(
      backupService.watchRecords(),
    ).thenAnswer((_) => Stream.value([restoreRecord]));
    when(
      backupService.exportBackup(password: anyNamed('password')),
    ).thenThrow(StateError('controlled failure'));
    when(
      backupService.restoreBackup(password: anyNamed('password')),
    ).thenThrow(const StorageLimitException('Sem espaço.'));

    try {
      await tester.pumpWidget(testHost(dependencies, const BackupPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Backup'));
      await tester.pumpAndSettle();
      expect(find.text('controlled failure'), findsOne);

      await tester.tap(find.text('Restaurar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Restaurar').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Senha'),
        'password-ok',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Restaurar').last);
      await tester.pumpAndSettle();
      expect(find.text('Limite de armazenamento atingido.'), findsOne);
      await tester.pump(const Duration(seconds: 5));

      await tester.tap(find.widgetWithText(ListTile, 'Restauração'));
      await tester.pumpAndSettle();
      expect(find.text('Detalhes da restauração'), findsOne);
      expect(find.text('Restauração'), findsWidgets);
      expect(find.text('Concluído'), findsWidgets);
      expect(find.text('Excluído'), findsNothing);
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('backup history hands overscroll to the page scroll', (
    tester,
  ) async {
    final parentController = ScrollController(initialScrollOffset: 500);
    addTearDown(parentController.dispose);
    final records = List.generate(
      32,
      (index) => testBackupRecord().copyWith(
        id: index + 1,
        createdAt: DateTime(2026, 5, 22, 10, index),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 320,
            child: ListView(
              controller: parentController,
              children: [
                const SizedBox(height: 500),
                BackupHistoryList(
                  records: records,
                  parentScrollController: parentController,
                ),
                const SizedBox(height: 700),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final initialOffset = parentController.offset;
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(BackupHistoryList), const Offset(0, -320));
      await tester.pump();
      if (parentController.offset > initialOffset) {
        break;
      }
    }

    expect(parentController.offset, greaterThan(initialOffset));
  });
}
