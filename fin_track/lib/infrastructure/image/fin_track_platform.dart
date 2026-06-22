import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/value_objects/biometric_status.dart';
import '../diagnostics/error_handling.dart';

class FinTrackPlatform {
  static const MethodChannel _channel = MethodChannel('fin_track/native');
  static Future<void> Function(List<String> paths)? _onSharedFiles;

  static void configureSharedFileListener(
    Future<void> Function(List<String> paths)? listener,
  ) {
    _onSharedFiles = listener;
    _updateMethodCallHandler();
  }

  static void _updateMethodCallHandler() {
    if (_onSharedFiles == null) {
      _channel.setMethodCallHandler(null);
      return;
    }

    _channel.setMethodCallHandler((call) async {
      if (call.method != 'sharedFiles') {
        throw MissingPluginException('Unknown native method: ${call.method}');
      }

      final arguments = call.arguments;
      final paths = _extractPaths(arguments);
      if (paths.isEmpty) {
        return false;
      }

      final listener = _onSharedFiles;
      if (listener != null) {
        unawaited(listener(paths));
      }
      return true;
    });
  }

  static Future<List<String>> pendingSharedFiles() async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeListMethod<String>(
          'pendingSharedFiles',
        );
        return List<String>.unmodifiable(result ?? const <String>[]);
      },
      fallback: const <String>[],
      diagnosticContext: 'Falha ao consultar arquivos compartilhados pendentes',
    );
  }

  static Future<bool> scheduleAutomaticBackup({
    required int intervalDays,
  }) async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMethod<bool>(
          'scheduleAutomaticBackup',
          {'intervalDays': intervalDays},
        );
        return result ?? false;
      },
      fallback: false,
      diagnosticContext: 'Falha ao agendar backup automático nativo',
    );
  }

  static Future<bool> cancelAutomaticBackup() async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMethod<bool>(
          'cancelAutomaticBackup',
        );
        return result ?? false;
      },
      fallback: false,
      diagnosticContext: 'Falha ao cancelar backup automático nativo',
    );
  }

  static Future<bool> runAutomaticBackupNowForTesting() async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMethod<bool>(
          'runAutomaticBackupNowForTesting',
        );
        return result ?? false;
      },
      fallback: false,
      diagnosticContext: 'Falha ao executar backup automático nativo em teste',
    );
  }

  static Future<bool> schedulePendingBatchImports() async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMethod<bool>(
          'schedulePendingBatchImports',
        );
        return result ?? false;
      },
      fallback: false,
      diagnosticContext: 'Falha ao agendar importações em lote pendentes',
    );
  }

  static Future<bool> cancelPendingBatchImports() async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMethod<bool>(
          'cancelPendingBatchImports',
        );
        return result ?? false;
      },
      fallback: false,
      diagnosticContext: 'Falha ao cancelar importações em lote pendentes',
    );
  }

  static Future<bool> schedulePendingSemanticIndex() async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMethod<bool>(
          'schedulePendingSemanticIndex',
        );
        return result ?? false;
      },
      fallback: false,
      diagnosticContext: 'Falha ao agendar indexação semântica pendente',
    );
  }

  static Future<bool> cancelPendingSemanticIndex() async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMethod<bool>(
          'cancelPendingSemanticIndex',
        );
        return result ?? false;
      },
      fallback: false,
      diagnosticContext: 'Falha ao cancelar indexação semântica pendente',
    );
  }

  static Future<String?> captureImage() async {
    return fallbackOnFailure(
      () => _channel.invokeMethod<String>('captureImage'),
      fallback: null,
      diagnosticContext: 'Falha ao capturar imagem pelo método nativo',
    );
  }

  static Future<List<String>> selectFiles() async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMethod<Object?>('selectFiles');
        if (result is String && result.isNotEmpty) {
          return <String>[result];
        }
        if (result is List) {
          return List<String>.unmodifiable(
            result.whereType<String>().where((path) => path.isNotEmpty),
          );
        }
        return const <String>[];
      },
      fallback: const <String>[],
      diagnosticContext: 'Falha ao selecionar arquivos pelo método nativo',
    );
  }

  static Future<String?> processOcr(String path) async {
    return fallbackOnFailure(
      () => _channel.invokeMethod<String>('processOcr', {'path': path}),
      fallback: null,
      diagnosticContext: 'Falha ao processar OCR pelo método nativo',
    );
  }

  static Future<bool> shareFile({
    required String path,
    required String mimeType,
  }) async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMethod<bool>('shareFile', {
          'path': path,
          'mimeType': mimeType,
        });
        return result ?? false;
      },
      fallback: false,
      diagnosticContext: 'Falha ao compartilhar arquivo pelo método nativo',
    );
  }

  static Future<bool> shareFiles({required List<String> paths}) async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMethod<bool>('shareFiles', {
          'paths': paths,
        });
        return result ?? false;
      },
      fallback: false,
      diagnosticContext: 'Falha ao compartilhar arquivos pelo método nativo',
    );
  }

  static Future<bool> saveFileToDevice({
    required String path,
    required String mimeType,
  }) async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMethod<bool>('saveFileToDevice', {
          'path': path,
          'mimeType': mimeType,
        });
        return result ?? false;
      },
      fallback: false,
      diagnosticContext: 'Falha ao salvar arquivo no dispositivo',
    );
  }

  static Future<bool> saveFilesToDevice({required List<String> paths}) async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMethod<bool>('saveFilesToDevice', {
          'paths': paths,
        });
        return result ?? false;
      },
      fallback: false,
      diagnosticContext: 'Falha ao salvar arquivos no dispositivo',
    );
  }

  static Future<Map<String, String>> getDeviceInfo() async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMapMethod<String, String>(
          'getDeviceInfo',
        );
        return Map<String, String>.from(result ?? const <String, String>{});
      },
      fallback: const <String, String>{},
      diagnosticContext: 'Falha ao obter informações do dispositivo',
    );
  }

  static Future<bool> openReportEmail({
    required String recipient,
    required String subject,
    required String body,
  }) async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMethod<bool>('openReportEmail', {
          'recipient': recipient,
          'subject': subject,
          'body': body,
        });
        return result ?? false;
      },
      fallback: false,
      diagnosticContext: 'Falha ao abrir e-mail de relatório',
    );
  }

  static Future<bool> saveLocalPin(String pin) async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMethod<bool>('saveLocalPin', {
          'pin': pin,
        });
        return result ?? false;
      },
      fallback: false,
      diagnosticContext: 'Falha ao salvar PIN local',
    );
  }

  static Future<bool> authenticateLocalPin(String pin) async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMethod<bool>(
          'authenticateLocalPin',
          {'pin': pin},
        );
        return result ?? false;
      },
      fallback: false,
      diagnosticContext: 'Falha ao autenticar PIN local',
    );
  }

  static Future<bool> removeLocalPin() async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMethod<bool>('removeLocalPin');
        return result ?? false;
      },
      fallback: false,
      diagnosticContext: 'Falha ao remover PIN local',
    );
  }

  static Future<BiometricStatus> checkBiometrics() async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMapMethod<String, Object?>(
          'checkBiometrics',
        );
        return _biometricStatusFromMap(result ?? const <String, Object?>{});
      },
      fallback: const BiometricStatus(
        available: false,
        message: 'Não foi possível verificar a biometria do dispositivo.',
      ),
      diagnosticContext: 'Falha ao verificar biometria',
    );
  }

  static Future<bool> authenticateBiometrics({
    required String title,
    required String subtitle,
  }) async {
    return fallbackOnFailure(
      () async {
        final result = await _channel.invokeMethod<bool>(
          'authenticateBiometrics',
          {'title': title, 'subtitle': subtitle},
        );
        return result ?? false;
      },
      fallback: false,
      diagnosticContext: 'Falha ao autenticar biometria',
    );
  }

  static List<String> _extractPaths(Object? arguments) {
    if (arguments is! Map) {
      return const <String>[];
    }

    final paths = arguments['paths'];
    if (paths is List) {
      return paths
          .whereType<String>()
          .where((path) => path.isNotEmpty)
          .toList();
    }

    final path = arguments['path'];
    if (path is String && path.isNotEmpty) {
      return <String>[path];
    }

    return const <String>[];
  }
}

BiometricStatus _biometricStatusFromMap(Map<String, Object?> map) {
  return BiometricStatus(
    available: map['available'] == true,
    message:
        map['message'] as String? ??
        'Não foi possível verificar a biometria do dispositivo.',
  );
}
