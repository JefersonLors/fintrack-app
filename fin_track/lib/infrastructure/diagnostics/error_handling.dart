import 'fin_track_error_log.dart';

Future<T> fallbackOnFailure<T>(
  Future<T> Function() action, {
  required T fallback,
  String? diagnosticContext,
  bool report = false,
}) async {
  try {
    return await action();
  } catch (error, stackTrace) {
    if (report) {
      _recordContext(error, stackTrace, diagnosticContext);
    }
    return fallback;
  }
}

T syncFallbackOnFailure<T>(
  T Function() action, {
  required T fallback,
  String? diagnosticContext,
  bool report = false,
}) {
  try {
    return action();
  } catch (error, stackTrace) {
    if (report) {
      _recordContext(error, stackTrace, diagnosticContext);
    }
    return fallback;
  }
}

Future<void> ignoreCleanupFailure(
  Future<void> Function() action, {
  String? diagnosticContext,
  bool report = false,
}) async {
  try {
    await action();
  } catch (error, stackTrace) {
    if (report) {
      _recordContext(error, stackTrace, diagnosticContext);
    }
  }
}

void ignoreSyncCleanupFailure(
  void Function() action, {
  String? diagnosticContext,
  bool report = false,
}) {
  try {
    action();
  } catch (error, stackTrace) {
    if (report) {
      _recordContext(error, stackTrace, diagnosticContext);
    }
  }
}

void recordHandledError(
  Object error,
  StackTrace stackTrace, {
  required String diagnosticContext,
}) {
  _recordContext(error, stackTrace, diagnosticContext);
}

Future<void> logAndContinue(
  Future<void> Function() action, {
  required String diagnosticContext,
}) async {
  try {
    await action();
  } catch (error, stackTrace) {
    _recordContext(error, stackTrace, diagnosticContext);
  }
}

void _recordContext(
  Object error,
  StackTrace stackTrace,
  String? diagnosticContext,
) {
  if (diagnosticContext == null || diagnosticContext.isEmpty) {
    FinTrackErrorLog.record(error, stackTrace);
    return;
  }
  FinTrackErrorLog.record(StateError('$diagnosticContext: $error'), stackTrace);
}
