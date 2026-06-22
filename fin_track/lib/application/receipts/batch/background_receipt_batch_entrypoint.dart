import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../bootstrap/fin_track_dependencies.dart';
import '../../../infrastructure/diagnostics/error_handling.dart';
import '../../../infrastructure/diagnostics/fin_track_error_log.dart';
import '../../../infrastructure/diagnostics/user_error_message.dart';

const _backgroundBatchChannel = MethodChannel(
  'fin_track/background_receipt_batch',
);

Future<void> runFinTrackBackgroundReceiptBatchImport() async {
  WidgetsFlutterBinding.ensureInitialized();
  var success = false;
  String? message;
  FinTrackDependencies? dependencies;

  try {
    dependencies = await FinTrackDependencies.persistent();
    await dependencies.receiptBatchImportService.processPendingSessions();
    success = true;
  } catch (error, stackTrace) {
    FinTrackErrorLog.record(error, stackTrace);
    message = userFriendlyErrorMessage(
      error,
      fallback: 'Não foi possível processar a importação em lote.',
    );
  } finally {
    dependencies?.dispose();
    await ignoreCleanupFailure(() async {
      await _backgroundBatchChannel.invokeMethod<void>(
        'backgroundReceiptBatchFinished',
        <String, Object?>{'success': success, 'message': message},
      );
    });
  }
}
