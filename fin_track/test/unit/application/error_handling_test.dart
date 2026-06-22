import 'package:fin_track/domain/infrastructure/i_cloud_storage.dart';
import 'package:fin_track/infrastructure/diagnostics/error_handling.dart';
import 'package:fin_track/infrastructure/diagnostics/fin_track_error_log.dart';
import 'package:fin_track/infrastructure/diagnostics/user_error_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(FinTrackErrorLog.clear);

  test('fallback helpers return successful action values', () async {
    expect(
      await fallbackOnFailure(() async => 'ok', fallback: 'fallback'),
      'ok',
    );
    expect(syncFallbackOnFailure(() => 42, fallback: 0), 42);
    expect(FinTrackErrorLog.recent(), isEmpty);
  });

  test('fallback helpers return fallback and can record context', () async {
    expect(
      await fallbackOnFailure(
        () async => throw StateError('async boom'),
        fallback: 'fallback',
        diagnosticContext: 'async context',
        report: true,
      ),
      'fallback',
    );
    expect(
      syncFallbackOnFailure(
        () => throw StateError('sync boom'),
        fallback: 7,
        report: true,
      ),
      7,
    );

    final entries = FinTrackErrorLog.recent();
    expect(entries.first, contains('Bad state: sync boom'));
    expect(entries.last, contains('async context'));
    expect(entries.last, contains('Bad state: async boom'));
  });

  test('cleanup helpers ignore failures and optionally record them', () async {
    await ignoreCleanupFailure(
      () async => throw StateError('cleanup async'),
      diagnosticContext: 'cleanup context',
      report: true,
    );
    ignoreSyncCleanupFailure(
      () => throw StateError('cleanup sync'),
      report: true,
    );

    final entries = FinTrackErrorLog.recent();
    expect(entries.first, contains('Bad state: cleanup sync'));
    expect(entries.last, contains('cleanup context'));
    expect(entries.last, contains('Bad state: cleanup async'));
  });

  test(
    'handled error and logAndContinue record errors without throwing',
    () async {
      final stack = StackTrace.current;

      recordHandledError(
        StateError('handled'),
        stack,
        diagnosticContext: 'handled context',
      );
      await logAndContinue(
        () async => throw StateError('continued'),
        diagnosticContext: 'continue context',
      );

      final entries = FinTrackErrorLog.recent();
      expect(entries.first, contains('continue context'));
      expect(entries.first, contains('Bad state: continued'));
      expect(entries.last, contains('handled context'));
      expect(entries.last, contains('Bad state: handled'));
    },
  );

  test('cleanup helpers keep successful actions quiet', () async {
    var asyncCleaned = false;
    var syncCleaned = false;

    await ignoreCleanupFailure(() async => asyncCleaned = true);
    ignoreSyncCleanupFailure(() => syncCleaned = true);
    await logAndContinue(() async {}, diagnosticContext: 'quiet context');

    expect(asyncCleaned, isTrue);
    expect(syncCleaned, isTrue);
    expect(FinTrackErrorLog.recent(), isEmpty);
  });

  test(
    'userFriendlyErrorMessage keeps safe messages and hides technical ones',
    () {
      expect(
        userFriendlyErrorMessage(
          const FormatException('Informe um nome para a categoria.'),
        ),
        'Informe um nome para a categoria.',
      );
      expect(
        userFriendlyErrorMessage(
          const CloudStorageFailure('A sessão Google expirou.'),
        ),
        'A sessão Google expirou.',
      );

      const fallback = 'Mensagem segura.';
      expect(
        userFriendlyErrorMessage(
          StateError(
            'SqliteException(5): database is locked COMMIT TRANSACTION',
          ),
          fallback: fallback,
        ),
        fallback,
      );
      expect(
        userFriendlyErrorMessage(
          'PlatformException(error, Bad state: falha, package:app/main.dart)',
          fallback: fallback,
        ),
        fallback,
      );
    },
  );
}
