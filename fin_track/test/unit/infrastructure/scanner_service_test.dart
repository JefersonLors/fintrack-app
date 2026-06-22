import 'dart:io';

import 'package:fin_track/domain/exceptions/operation_cancelled_exception.dart';
import 'package:fin_track/infrastructure/scanner/mlkit_document_scanner_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const scannerChannel = MethodChannel('google_mlkit_document_scanner');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(scannerChannel, null);
  });

  test('scanner returns existing file and closes adapter', () async {
    final temp = await Directory.systemTemp.createTemp(
      'fintrack_scanner_test_',
    );
    addTearDown(() async {
      if (await temp.exists()) {
        await temp.delete(recursive: true);
      }
    });
    final image = await File('${temp.path}/scan.jpg').writeAsBytes([1, 2, 3]);
    final adapter = _ScannerAdapterFake(paths: [image.path]);
    final service = MLKitDocumentScannerService(
      isAndroid: () => true,
      scannerFactory: () => adapter,
    );

    final result = await service.scanDocument();

    expect(result.path, image.path);
    expect(adapter.closed, isTrue);
  });

  test('scanner converts cancellation and empty result', () async {
    final cancelled = _ScannerAdapterFake(
      error: PlatformException(code: 'cancelled', message: 'User cancel'),
    );
    final cancelledService = MLKitDocumentScannerService(
      isAndroid: () => true,
      scannerFactory: () => cancelled,
    );

    await expectLater(
      cancelledService.scanDocument(),
      throwsA(isA<OperationCancelledException>()),
    );
    expect(cancelled.closed, isTrue);

    final empty = _ScannerAdapterFake();
    final emptyService = MLKitDocumentScannerService(
      isAndroid: () => true,
      scannerFactory: () => empty,
    );

    await expectLater(
      emptyService.scanDocument(),
      throwsA(isA<OperationCancelledException>()),
    );
    expect(empty.closed, isTrue);
  });

  test('scanner propagates plugin error and missing file', () async {
    final failure = _ScannerAdapterFake(
      error: PlatformException(code: 'boom', message: 'Camera unavailable'),
    );
    final failureService = MLKitDocumentScannerService(
      isAndroid: () => true,
      scannerFactory: () => failure,
    );

    await expectLater(
      failureService.scanDocument(),
      throwsA(isA<PlatformException>()),
    );
    expect(failure.closed, isTrue);

    final missing = _ScannerAdapterFake(paths: ['/tmp/fintrack-missing.jpg']);
    final missingService = MLKitDocumentScannerService(
      isAndroid: () => true,
      scannerFactory: () => missing,
    );

    await expectLater(
      missingService.scanDocument(),
      throwsA(isA<FormatException>()),
    );
    expect(missing.closed, isTrue);
  });

  test('scanner uses default MLKit adapter through MethodChannel', () async {
    final temp = await Directory.systemTemp.createTemp(
      'fintrack_scanner_mlkit_',
    );
    addTearDown(() async {
      if (await temp.exists()) {
        await temp.delete(recursive: true);
      }
    });
    final image = await File('${temp.path}/scan.jpg').writeAsBytes([1, 2, 3]);
    final calls = <String>[];
    messenger.setMockMethodCallHandler(scannerChannel, (call) async {
      calls.add(call.method);
      if (call.method == 'vision#startDocumentScanner') {
        return {
          'images': [image.path],
        };
      }
      if (call.method == 'vision#closeDocumentScanner') {
        return null;
      }
      throw PlatformException(code: 'not_mocked');
    });
    final service = MLKitDocumentScannerService(isAndroid: () => true);

    final result = await service.scanDocument();

    expect(result.path, image.path);
    expect(calls, [
      'vision#startDocumentScanner',
      'vision#closeDocumentScanner',
    ]);
  });

  test('MLKit scanner reports unavailability outside Android', () async {
    final service = MLKitDocumentScannerService();

    await expectLater(
      service.scanDocument(),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('apenas no Android'),
        ),
      ),
    );
  });
}

class _ScannerAdapterFake implements FinTrackDocumentScannerAdapter {
  _ScannerAdapterFake({this.paths = const <String>[], this.error});

  final List<String> paths;
  final Object? error;
  var closed = false;

  @override
  Future<List<String>> scanDocument() async {
    final error = this.error;
    if (error != null) {
      throw error;
    }
    return paths;
  }

  @override
  void close() {
    closed = true;
  }
}
