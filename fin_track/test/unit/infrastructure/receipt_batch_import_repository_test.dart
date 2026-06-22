import 'dart:io';

import 'package:fin_track/application/receipts/batch/receipt_batch_state.dart';
import 'package:fin_track/infrastructure/database/app_database.dart';
import 'package:fin_track/infrastructure/database/receipt_batch_import_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'batch item errors keep technical details out of user snapshots',
    () async {
      final database = AppDatabase.memory();
      final repository = ReceiptBatchImportRepository(database);
      final stagingDirectory = await Directory.systemTemp.createTemp(
        'fintrack_batch_repository_test_',
      );
      addTearDown(database.close);
      addTearDown(() async {
        if (await stagingDirectory.exists()) {
          await stagingDirectory.delete(recursive: true);
        }
      });

      final original = File('${stagingDirectory.path}/original.txt')
        ..writeAsStringSync('original');
      final staged = File('${stagingDirectory.path}/staged.txt')
        ..writeAsStringSync('staged');
      final sessionId = await repository.createSession(
        stagingDirectory: stagingDirectory,
        originalFiles: [original],
        stagedFiles: [staged],
      );
      final item = await repository.claimNextPendingItem(sessionId);

      await repository.markItemError(
        item!.id,
        StateError(
          'SqliteException(5): while executing, database is locked, '
          'Causing statement: COMMIT TRANSACTION',
        ),
      );

      final snapshot = await repository.findSnapshot(sessionId);
      final errorDescription = snapshot!.items.single.errorDescription!;
      expect(errorDescription, contains('Não foi possível processar'));
      expect(errorDescription, isNot(contains('SqliteException')));
      expect(errorDescription, isNot(contains('database is locked')));
      expect(errorDescription, isNot(contains('COMMIT TRANSACTION')));
    },
  );

  test('legacy technical batch error strings are sanitized for display', () {
    expect(
      receiptBatchUserErrorMessage(
        'DriftRemoteException SqliteException(5): database is locked '
        'COMMIT TRANSACTION package:drift/native.dart',
      ),
      contains('Não foi possível processar'),
    );
  });
}
