import '../../domain/exceptions/storage_limit_exception.dart';
import '../../domain/infrastructure/i_cloud_storage.dart';

const defaultUserErrorMessage =
    'Não foi possível concluir a operação. Tente novamente.';

String userFriendlyErrorMessage(
  Object? error, {
  String fallback = defaultUserErrorMessage,
}) {
  final message = _candidateMessage(error);
  if (message == null || _looksLikeTechnicalError(message)) {
    return fallback;
  }
  return message;
}

bool isTechnicalErrorMessage(String message) {
  return _looksLikeTechnicalError(message);
}

String? _candidateMessage(Object? error) {
  return switch (error) {
    null => null,
    StorageLimitException(:final message) => _trim(message),
    CloudStorageFailure(:final userMessage) => _trim(userMessage),
    FormatException(:final message) => _trim(message),
    StateError(:final message) => _trim(message),
    String() => _trim(error),
    _ => null,
  };
}

String? _trim(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

bool _looksLikeTechnicalError(String message) {
  final normalized = message.toLowerCase();
  return normalized.contains('exception') ||
      normalized.contains('sqlite') ||
      normalized.contains('database is locked') ||
      normalized.contains('commit transaction') ||
      normalized.contains('drift') ||
      normalized.contains('stacktrace') ||
      normalized.contains('stack trace') ||
      normalized.contains('package:') ||
      normalized.contains('file://') ||
      normalized.contains('.dart') ||
      normalized.contains('platformexception') ||
      normalized.contains('filesystemexception') ||
      normalized.contains('os error') ||
      normalized.contains('bad state') ||
      normalized.contains('null check operator') ||
      normalized.contains('nosuchmethoderror') ||
      normalized.contains('typeerror') ||
      normalized.contains('type error') ||
      normalized.contains('rangeerror') ||
      normalized.contains('assertion failed');
}
