import 'dart:async';

import 'package:fin_track/infrastructure/image/fin_track_platform.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('fin_track/native');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    FinTrackPlatform.configureSharedFileListener(null);
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('selectFiles accepts a single string and filtered lists', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return switch (call.method) {
        'selectFiles' => ['a.pdf', '', 3, 'b.png'],
        _ => null,
      };
    });

    expect(await FinTrackPlatform.selectFiles(), ['a.pdf', 'b.png']);
    expect(calls, ['selectFiles']);

    messenger.setMockMethodCallHandler(channel, (call) async {
      return switch (call.method) {
        'selectFiles' => 'single.jpg',
        _ => null,
      };
    });

    expect(await FinTrackPlatform.selectFiles(), ['single.jpg']);
  });

  test('selectFiles returns empty list when native selection fails', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'selectFiles') {
        throw PlatformException(code: 'error');
      }
      return null;
    });

    expect(await FinTrackPlatform.selectFiles(), isEmpty);
  });

  test('pending sharedFiles uses list and returns empty on failure', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      return switch (call.method) {
        'pendingSharedFiles' => ['a.jpg', 'b.pdf'],
        _ => null,
      };
    });

    expect(await FinTrackPlatform.pendingSharedFiles(), ['a.jpg', 'b.pdf']);

    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'pendingSharedFiles') {
        throw PlatformException(code: 'error');
      }
      return null;
    });

    expect(await FinTrackPlatform.pendingSharedFiles(), isEmpty);
  });

  test(
    'boolean methods return false when native fails or returns null',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return switch (call.method) {
          'shareFile' => true,
          'shareFiles' => null,
          'saveFileToDevice' => throw PlatformException(code: 'error'),
          'saveFilesToDevice' => true,
          'openReportEmail' => true,
          'saveLocalPin' => true,
          'authenticateLocalPin' => false,
          'removeLocalPin' => null,
          'authenticateBiometrics' => true,
          'scheduleAutomaticBackup' => true,
          'cancelAutomaticBackup' => true,
          'runAutomaticBackupNowForTesting' => false,
          'schedulePendingBatchImports' => true,
          'cancelPendingBatchImports' => true,
          'schedulePendingSemanticIndex' => true,
          'cancelPendingSemanticIndex' => true,
          _ => null,
        };
      });

      expect(
        await FinTrackPlatform.shareFile(
          path: 'a.pdf',
          mimeType: 'application/pdf',
        ),
        isTrue,
      );
      expect(await FinTrackPlatform.shareFiles(paths: ['a.pdf']), isFalse);
      expect(
        await FinTrackPlatform.saveFileToDevice(
          path: 'a.pdf',
          mimeType: 'application/pdf',
        ),
        isFalse,
      );
      expect(
        await FinTrackPlatform.saveFilesToDevice(paths: ['a.pdf']),
        isTrue,
      );
      expect(
        await FinTrackPlatform.openReportEmail(
          recipient: 'suporte@ifba.edu.br',
          subject: 'Erro',
          body: 'Detalhes',
        ),
        isTrue,
      );
      expect(await FinTrackPlatform.saveLocalPin('1234'), isTrue);
      expect(await FinTrackPlatform.authenticateLocalPin('1234'), isFalse);
      expect(await FinTrackPlatform.removeLocalPin(), isFalse);
      expect(
        await FinTrackPlatform.authenticateBiometrics(
          title: 'Entrar',
          subtitle: 'Use a biometric',
        ),
        isTrue,
      );
      expect(
        await FinTrackPlatform.scheduleAutomaticBackup(intervalDays: 7),
        isTrue,
      );
      expect(await FinTrackPlatform.cancelAutomaticBackup(), isTrue);
      expect(await FinTrackPlatform.runAutomaticBackupNowForTesting(), isFalse);
      expect(await FinTrackPlatform.schedulePendingBatchImports(), isTrue);
      expect(await FinTrackPlatform.cancelPendingBatchImports(), isTrue);
      expect(await FinTrackPlatform.schedulePendingSemanticIndex(), isTrue);
      expect(await FinTrackPlatform.cancelPendingSemanticIndex(), isTrue);
    },
  );

  test('device info and biometrics handle returns and failures', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      return switch (call.method) {
        'getDeviceInfo' => {'manufacturer': 'Google', 'model': 'Pixel'},
        'checkBiometrics' => {'available': true, 'message': 'Available'},
        _ => null,
      };
    });

    expect(await FinTrackPlatform.getDeviceInfo(), {
      'manufacturer': 'Google',
      'model': 'Pixel',
    });
    final biometric = await FinTrackPlatform.checkBiometrics();
    expect(biometric.available, isTrue);
    expect(biometric.message, 'Available');

    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'error');
    });

    expect(await FinTrackPlatform.getDeviceInfo(), isEmpty);
    final unavailable = await FinTrackPlatform.checkBiometrics();
    expect(unavailable.available, isFalse);
    expect(unavailable.message, contains('Não foi possível'));
  });

  test('shared file listener filters received arguments', () async {
    final received = <List<String>>[];
    FinTrackPlatform.configureSharedFileListener((paths) async {
      received.add(paths);
    });

    expect(
      await _invokeRegisteredHandler('sharedFiles', <String, Object?>{
        'paths': ['a.jpg', '', 1, 'b.pdf'],
      }),
      isTrue,
    );
    await pumpEventQueue();
    expect(received, [
      ['a.jpg', 'b.pdf'],
    ]);

    expect(
      await _invokeRegisteredHandler('sharedFiles', {'path': 'single.png'}),
      isTrue,
    );
    await pumpEventQueue();
    expect(received.last, ['single.png']);

    expect(
      await _invokeRegisteredHandler('sharedFiles', {'path': ''}),
      isFalse,
    );
    expect(await _invokeRegisteredHandler('sharedFiles', 'invalid'), isFalse);
  });

  test('shared file listener rejects unknown method', () async {
    FinTrackPlatform.configureSharedFileListener((_) async {});

    expect(
      await _invokeRegisteredHandler('otherMethod', const <String, Object?>{}),
      isNull,
    );
  });

  test('simple wrappers return values or null fallback', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return switch (call.method) {
        'captureImage' => '/tmp/camera.jpg',
        'processOcr' => 'extracted text',
        _ => throw PlatformException(code: 'not_mocked'),
      };
    });

    expect(await FinTrackPlatform.captureImage(), '/tmp/camera.jpg');
    expect(
      await FinTrackPlatform.processOcr('/tmp/document.pdf'),
      'extracted text',
    );
    expect(calls, ['captureImage', 'processOcr']);

    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'error');
    });
    expect(await FinTrackPlatform.captureImage(), isNull);
    expect(await FinTrackPlatform.processOcr('/tmp/document.pdf'), isNull);
  });
}

Future<Object?> _invokeRegisteredHandler(
  String method,
  Object? arguments,
) async {
  const codec = StandardMethodCodec();
  final completer = Completer<ByteData?>();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        'fin_track/native',
        codec.encodeMethodCall(MethodCall(method, arguments)),
        completer.complete,
      );
  final response = await completer.future;
  return response == null ? null : codec.decodeEnvelope(response);
}
