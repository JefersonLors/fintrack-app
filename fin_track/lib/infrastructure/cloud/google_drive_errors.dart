part of 'google_drive_service.dart';

extension GoogleDriveErrorMessages on GoogleDriveService {
  String _userMessage(int statusCode, String detail) {
    if (statusCode == HttpStatus.unauthorized) {
      return 'A sessão Google expirou. Vincule a conta novamente.';
    }
    if (statusCode == HttpStatus.forbidden) {
      final normalized = detail.toLowerCase();
      if (normalized.contains('access not configured') ||
          normalized.contains('api has not been used') ||
          normalized.contains('drive api')) {
        return 'A API do Google Drive não está habilitada para este app.';
      }
      if (normalized.contains('insufficient') || normalized.contains('scope')) {
        return 'A conta Google não autorizou o acesso de backup do FinTrack.';
      }
      return 'O Google Drive recusou o envio. Verifique as permissões do app.';
    }
    if (statusCode == HttpStatus.notFound) {
      return 'O backup não foi encontrado no espaço privado do Google Drive.';
    }
    if (statusCode == HttpStatus.tooManyRequests ||
        statusCode >= HttpStatus.internalServerError) {
      return 'O Google Drive está temporariamente indisponível. Tente novamente.';
    }
    return 'Não foi possível comunicar com o Google Drive.';
  }

  String _googleErrorDetail(_HttpResponse response) {
    final raw = utf8.decode(response.body, allowMalformed: true).trim();
    if (raw.isEmpty) {
      return 'Resposta vazia do Google Drive.';
    }
    return syncFallbackOnFailure(
          () {
            final decoded = jsonDecode(raw);
            if (decoded is Map) {
              final error = decoded['error'];
              if (error is Map) {
                final status = error['status']?.toString();
                final message = error['message']?.toString();
                final reason = _reason(error['errors']);
                return [
                  if (status != null && status.isNotEmpty) status,
                  if (reason != null && reason.isNotEmpty) reason,
                  if (message != null && message.isNotEmpty) message,
                ].join(' - ');
              }
            }
            return null;
          },
          fallback: null,
          diagnosticContext: 'Falha ao interpretar erro do Google Drive',
        ) ??
        (raw.length <= 500 ? raw : raw.substring(0, 500));
  }

  String? _reason(Object? errors) {
    if (errors is! List || errors.isEmpty) {
      return null;
    }
    final first = errors.first;
    if (first is Map) {
      return first['reason']?.toString();
    }
    return null;
  }
}
