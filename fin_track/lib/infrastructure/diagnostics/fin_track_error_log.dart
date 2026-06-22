import 'package:flutter/foundation.dart';

import '../../domain/infrastructure/i_error_reporter.dart';

class FinTrackErrorLog {
  FinTrackErrorLog._();

  static const _maxEntries = 20;
  static final List<String> _entries = <String>[];

  static void record(Object error, StackTrace? stackTrace) {
    final timestamp = DateTime.now().toIso8601String();
    final stack = _summarizeStack(stackTrace);
    final message = error.toString();
    final entry = [
      '$timestamp - ${error.runtimeType}',
      if (message.isNotEmpty) _truncate(message),
      if (stack.isNotEmpty) stack,
    ].join('\n');

    _entries.insert(0, entry);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
    debugPrint('FinTrackErrorLog\n$entry');
  }

  static void recordDiagnostic(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final entry = '$timestamp - Diagnóstico\n${_truncate(message, 4000)}';
    _entries.insert(0, entry);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
    debugPrint('FinTrackErrorLog\n$entry');
  }

  static List<String> recent() {
    return List<String>.unmodifiable(_entries);
  }

  @visibleForTesting
  static void clear() {
    _entries.clear();
  }

  static String _summarizeStack(StackTrace? stackTrace) {
    if (stackTrace == null) {
      return '';
    }

    return stackTrace
        .toString()
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .take(12)
        .join('\n');
  }

  static String _truncate(String text, [int limit = 800]) {
    return text.length <= limit ? text : text.substring(0, limit);
  }
}

class FinTrackErrorReporter implements IErrorReporter {
  const FinTrackErrorReporter();

  @override
  void record(Object error, StackTrace? stackTrace) {
    FinTrackErrorLog.record(error, stackTrace);
  }

  @override
  void recordDiagnostic(String message) {
    FinTrackErrorLog.recordDiagnostic(message);
  }
}
