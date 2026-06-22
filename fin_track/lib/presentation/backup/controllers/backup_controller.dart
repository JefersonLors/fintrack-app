import 'package:flutter/foundation.dart';

import '../../../domain/entities/backup_record.dart';
import '../../../domain/exceptions/storage_limit_exception.dart';
import '../../../infrastructure/diagnostics/user_error_message.dart';

class BackupController extends ChangeNotifier {
  var _busy = false;

  bool get busy => _busy;

  Future<BackupActionResult> run(
    Future<Object?> Function() action,
    String successMessage,
  ) async {
    _setBusy(true);
    try {
      final result = await action();
      final backupFailure =
          result is BackupRecord && result.status == BackupStatus.failure;
      return BackupActionResult.success(
        backupFailure
            ? userFriendlyErrorMessage(
                result.errorDescription,
                fallback: 'A operação não foi concluída.',
              )
            : successMessage,
      );
    } on StorageLimitException catch (error) {
      return BackupActionResult.storageLimit(error);
    } catch (error) {
      return BackupActionResult.failure(_errorMessage(error));
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    if (_busy == value) {
      return;
    }
    _busy = value;
    notifyListeners();
  }

  String _errorMessage(Object error) {
    return userFriendlyErrorMessage(error);
  }
}

class BackupActionResult {
  const BackupActionResult._({
    required this.message,
    required this.storageLimitError,
  });

  factory BackupActionResult.success(String message) {
    return BackupActionResult._(message: message, storageLimitError: null);
  }

  factory BackupActionResult.failure(String message) {
    return BackupActionResult._(message: message, storageLimitError: null);
  }

  factory BackupActionResult.storageLimit(StorageLimitException error) {
    return BackupActionResult._(message: null, storageLimitError: error);
  }

  final String? message;
  final StorageLimitException? storageLimitError;
}
