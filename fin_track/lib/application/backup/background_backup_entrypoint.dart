import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../bootstrap/fin_track_dependencies.dart';
import '../../domain/entities/backup_record.dart';
import '../../infrastructure/diagnostics/error_handling.dart';
import '../../infrastructure/diagnostics/fin_track_error_log.dart';
import '../../infrastructure/diagnostics/user_error_message.dart';

const _backgroundBackupChannel = MethodChannel('fin_track/background_backup');

Future<void> runFinTrackBackgroundBackup() async {
  WidgetsFlutterBinding.ensureInitialized();
  var success = false;
  var skipped = false;
  var retryable = true;
  String? message;
  FinTrackDependencies? dependencies;

  try {
    dependencies = await FinTrackDependencies.persistent();
    final record = await dependencies.backupService
        .runAutomaticBackupIfNeeded();
    skipped = record == null;
    success = record == null || record.status != BackupStatus.failure;
    message = record?.errorDescription;
    retryable = !success && !_isNonRetryableAutomaticFailure(message);
  } catch (error, stackTrace) {
    FinTrackErrorLog.record(error, stackTrace);
    message = userFriendlyErrorMessage(
      error,
      fallback: 'Não foi possível executar o backup automático.',
    );
  } finally {
    dependencies?.dispose();
    await _notifyNativeBackupFinished(
      success: success,
      skipped: skipped,
      retryable: retryable,
      message: message,
    );
  }
}

bool _isNonRetryableAutomaticFailure(String? message) {
  final normalized = message?.toLowerCase() ?? '';
  return normalized.contains('senha de backup ausente') ||
      normalized.contains('conta de nuvem expirou') ||
      normalized.contains('sessão da conta de nuvem expirou') ||
      normalized.contains('conta de nuvem não vinculada');
}

Future<void> _notifyNativeBackupFinished({
  required bool success,
  required bool skipped,
  required bool retryable,
  String? message,
}) async {
  await ignoreCleanupFailure(() async {
    await _backgroundBackupChannel.invokeMethod<void>(
      'backgroundBackupFinished',
      <String, Object?>{
        'success': success,
        'skipped': skipped,
        'retryable': retryable,
        'message': message,
      },
    );
  });
}
