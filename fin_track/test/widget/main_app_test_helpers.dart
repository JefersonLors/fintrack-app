import 'dart:io';

import 'package:fin_track/application/receipts/batch/receipt_batch_import_service.dart';
import 'package:fin_track/bootstrap/fin_track_dependencies.dart';
import 'package:fin_track/domain/entities/configuration.dart';
import 'package:fin_track/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'presentation_mockito_helpers.dart';
import 'presentation_mocks.dart';

Future<void> pumpAppFrames(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
  });
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> pumpShortAppFrames(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
  });
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> noNavigationWait() async {}

FinTrackDependencies mainAppDependencies({
  MockIReceiptService? receiptService,
  MockIBackupService? backupService,
  MockIConfigurationService? configurationService,
  MockILocalAuthenticationService? localAuthService,
  ReceiptBatchImportService? receiptBatchImportService,
  Configuration configuration = const Configuration(
    id: 1,
    onboardingCompleted: true,
  ),
}) {
  final resolvedReceipt = receiptService ?? MockIReceiptService();
  final resolvedBackup = backupService ?? MockIBackupService();
  final resolvedConfiguration =
      configurationService ?? MockIConfigurationService();
  stubShellList(resolvedReceipt);
  when(resolvedReceipt.validateSpaceForNewReceipt()).thenAnswer((_) async {});
  when(
    resolvedReceipt.validateSpaceForNewReceipt(any),
  ).thenAnswer((_) async {});
  when(resolvedConfiguration.load()).thenAnswer((_) async => configuration);
  when(
    resolvedConfiguration.watch(),
  ).thenAnswer((_) => Stream<Configuration>.value(configuration));
  when(
    resolvedBackup.runAutomaticBackupIfNeeded(),
  ).thenAnswer((_) async => null);

  return testDependencies(
    resolvedReceipt,
    backupService: resolvedBackup,
    configurationService: resolvedConfiguration,
    localAuthService: localAuthService,
    receiptBatchImportService: receiptBatchImportService,
  );
}

Widget singleSharedFilePage(
  BuildContext context,
  File file,
  Future<void> Function() onFinished,
) {
  return Scaffold(
    body: Column(
      children: [
        const Text('Arquivo compartilhado'),
        Text(file.path),
        TextButton(
          onPressed: () async {
            await onFinished();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Concluir importação'),
        ),
      ],
    ),
  );
}

Widget batchSharedFilePage(
  BuildContext context,
  List<File> files,
  Future<void> Function() onFinished,
) {
  return Scaffold(
    body: Column(
      children: [
        const Text('Lote compartilhado'),
        Text('${files.length} files'),
        TextButton(
          onPressed: () async {
            await onFinished();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Concluir lote'),
        ),
      ],
    ),
  );
}

class FakeFinTrackPlatformGateway implements FinTrackPlatformGateway {
  FakeFinTrackPlatformGateway({List<String> pendingFiles = const <String>[]})
    : _pendingFiles = List<String>.of(pendingFiles);

  final List<String> _pendingFiles;
  Future<void> Function(List<String> paths)? listener;

  @override
  void configureSharedFileListener(
    Future<void> Function(List<String> paths)? listener,
  ) {
    this.listener = listener;
  }

  @override
  Future<List<String>> pendingSharedFiles() async {
    return List<String>.unmodifiable(_pendingFiles);
  }
}
