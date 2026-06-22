import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../bootstrap/fin_track_dependencies.dart';
import '../../../infrastructure/diagnostics/fin_track_error_log.dart';
import '../../../infrastructure/diagnostics/user_error_message.dart';

const _backgroundSemanticIndexChannel = MethodChannel(
  'fin_track/background_semantic_index',
);

Future<void> runFinTrackBackgroundSemanticIndex() async {
  WidgetsFlutterBinding.ensureInitialized();
  FinTrackDependencies? dependencies;
  try {
    dependencies = await FinTrackDependencies.persistent();
    await dependencies.receiptService.reindexPendingSemanticEmbeddings();
    await _backgroundSemanticIndexChannel.invokeMethod<void>(
      'backgroundSemanticIndexFinished',
      {'success': true},
    );
  } catch (error, stackTrace) {
    FinTrackErrorLog.record(error, stackTrace);
    await _backgroundSemanticIndexChannel
        .invokeMethod<void>('backgroundSemanticIndexFinished', {
          'success': false,
          'message': userFriendlyErrorMessage(
            error,
            fallback: 'Não foi possível atualizar a busca semântica.',
          ),
        });
  } finally {
    dependencies?.dispose();
  }
}
