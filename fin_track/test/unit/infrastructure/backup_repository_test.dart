import 'package:fin_track/domain/entities/backup_record.dart';
import 'package:fin_track/domain/entities/cloud_provider.dart';
import 'package:fin_track/infrastructure/database/app_database.dart';
import 'package:fin_track/infrastructure/database/backup_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.memory();
  });

  tearDown(() async {
    await database.close();
  });

  test('backup saves lists updates watches and clears history', () async {
    final repository = BackupRepository(database);
    final data = DateTime(2026, 5, 23, 8, 30);

    expect(await repository.findLatest(), isNull);

    final saved = await repository.save(
      BackupRecord(
        id: 0,
        createdAt: data,
        operation: BackupOperation.restore,
        status: BackupStatus.pending,
        totalReceipts: 3,
        errorDescription: null,
        configurationId: 1,
        cloudProvider: CloudProvider.googleDrive,
        linkedCloudAccount: 'account@fintrack.test',
        availability: BackupAvailability.active,
      ),
    );

    final updated = await repository.update(
      saved.copyWith(
        status: BackupStatus.synced,
        totalReceipts: 4,
        errorDescription: 'ignored',
        availability: BackupAvailability.deleted,
      ),
    );

    expect(updated.status, BackupStatus.synced);
    expect(updated.operation, BackupOperation.restore);
    expect(updated.cloudProvider, CloudProvider.googleDrive);
    expect(updated.linkedCloudAccount, 'account@fintrack.test');
    expect((await repository.findLatest())?.id, updated.id);
    expect(await repository.watchAll().first, hasLength(1));

    await repository.clearHistory();
    expect(await repository.list(), isEmpty);
  });

  test('backup converts unknown persisted values to defaults', () async {
    final repository = BackupRepository(database);
    final saved = await repository.save(
      BackupRecord(
        id: 0,
        createdAt: DateTime(2026, 5, 24, 9),
        status: BackupStatus.pending,
        totalReceipts: 1,
        configurationId: 1,
        availability: BackupAvailability.active,
      ),
    );

    await database.customStatement('PRAGMA ignore_check_constraints = ON');
    await database.customStatement(
      "UPDATE backup_record SET status = 'QUEBRADO', "
      "operation = 'OUTRA', availability = 'SUMIU' WHERE id = ?",
      [saved.id],
    );

    final record = (await repository.list()).single;
    expect(record.status, BackupStatus.failure);
    expect(record.operation, BackupOperation.export);
    expect(record.availability, BackupAvailability.inactive);
  });
}
