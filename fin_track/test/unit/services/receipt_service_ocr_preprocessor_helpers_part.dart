part of 'receipt_service_test.dart';

class _FakeOcrService implements IOCRService {
  @override
  Future<OcrResult> process(File file) async {
    return const OcrResult(text: '', confidence: 0, provider: 'fake');
  }
}

class _StaticOcrService implements IOCRService {
  const _StaticOcrService({required this.text, required this.confidence});

  final String text;
  final double confidence;

  @override
  Future<OcrResult> process(File file) async {
    return OcrResult(text: text, confidence: confidence, provider: 'fake');
  }
}

class _RecordingOcrService implements IOCRService {
  File? received;

  @override
  Future<OcrResult> process(File file) async {
    received = file;
    return const OcrResult(
      text: 'Mercado Central\nData 28/04/2026\nTotal R\$ 128,45',
      confidence: 0.91,
      provider: 'fake',
      lines: [
        OcrLine(
          text: 'Mercado Central',
          left: 10,
          top: 10,
          right: 150,
          bottom: 28,
          blockIndex: 0,
          lineIndex: 0,
        ),
        OcrLine(
          text: 'Data 28/04/2026',
          left: 10,
          top: 40,
          right: 170,
          bottom: 58,
          blockIndex: 0,
          lineIndex: 1,
        ),
        OcrLine(
          text: 'Total R\$ 128,45',
          left: 10,
          top: 70,
          right: 180,
          bottom: 88,
          blockIndex: 0,
          lineIndex: 2,
        ),
      ],
    );
  }
}

class _StrongRecordingOcrService implements IOCRService {
  final receivedPaths = <String>[];

  @override
  Future<OcrResult> process(File file) async {
    receivedPaths.add(file.path);
    return const OcrResult(
      text: '''
Mercado Central
Nota fiscal eletronica
CNPJ 55.986.560/0001-59
Chave 35260455986560000159550010000001234567890123
Data 28/04/2026
Total R\$ 128,45
Item arroz
Item cafe
Item frutas
Item leite
Item pao
Item queijo
Item agua
Item sabao
''',
      confidence: 0.95,
      provider: 'fake',
    );
  }
}

class _RecordingImagePreprocessor implements IImagePreprocessorService {
  _RecordingImagePreprocessor(this.returnValue);

  final File returnValue;
  File? received;
  var cleanups = 0;

  @override
  Future<void> cleanOldTemporaryFiles() async {
    cleanups++;
  }

  @override
  Future<File> preprocess(File file) async {
    received = file;
    return returnValue;
  }

  @override
  Future<List<OcrImageVariant>> generateVariants(File file) async {
    received = file;
    return <OcrImageVariant>[
      OcrImageVariant(name: 'original', file: file),
      if (returnValue.path != file.path)
        OcrImageVariant(
          name: 'preprocessada',
          file: returnValue,
          temporary: true,
        ),
    ];
  }

  @override
  Future<OcrImageQuality> analyzeQuality(
    File file, {
    bool hasQrCode = false,
    bool hasBarcode = false,
  }) async {
    return OcrImageQuality(
      width: 1000,
      height: 700,
      sizeBytes: await file.length(),
      sharpness: 0.7,
      contrast: 0.6,
      brightness: 0.5,
      orientationDegrees: 0,
      hasQrCode: hasQrCode,
      hasBarcode: hasBarcode,
    );
  }
}

class _EmptyVariantsPreprocessor implements IImagePreprocessorService {
  @override
  Future<void> cleanOldTemporaryFiles() async {}

  @override
  Future<List<OcrImageVariant>> generateVariants(File file) async {
    return const <OcrImageVariant>[];
  }

  @override
  Future<File> preprocess(File file) async => file;

  @override
  Future<OcrImageQuality> analyzeQuality(
    File file, {
    bool hasQrCode = false,
    bool hasBarcode = false,
  }) {
    throw StateError('quality unavailable');
  }
}

class _ThrowingVariantsPreprocessor extends _EmptyVariantsPreprocessor {
  _ThrowingVariantsPreprocessor(this.returnValue);

  final File returnValue;

  @override
  Future<List<OcrImageVariant>> generateVariants(File file) {
    throw StateError('variantes indisponiveis');
  }

  @override
  Future<File> preprocess(File file) async => returnValue;
}

class _FailingPreprocessor extends _EmptyVariantsPreprocessor {
  @override
  Future<List<OcrImageVariant>> generateVariants(File file) {
    throw StateError('variantes indisponiveis');
  }

  @override
  Future<File> preprocess(File file) {
    throw StateError('preprocessing unavailable');
  }
}

class _SlowVisualCodeService implements IVisualCodeService {
  var _running = 0;
  var maxConcurrent = 0;

  @override
  Future<List<String>> readCodes(File file) async {
    _running++;
    maxConcurrent = max(maxConcurrent, _running);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    _running--;
    return ['shared', 'code-${file.uri.pathSegments.last}'];
  }
}

class _SlowVariantOcrService implements IOCRService {
  var _running = 0;
  var maxConcurrent = 0;

  @override
  Future<OcrResult> process(File file) async {
    _running++;
    maxConcurrent = max(maxConcurrent, _running);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    _running--;
    final name = file.uri.pathSegments.last;
    if (name == 'best.txt') {
      return const OcrResult(
        text: 'Mercado Central\nTotal R\$ 999,99',
        confidence: 0.99,
        provider: 'slow',
      );
    }
    if (name == 'medium.txt') {
      return const OcrResult(
        text: 'Mercado Central\nTotal R\$ 10,00',
        confidence: 0.70,
        provider: 'slow',
      );
    }
    return const OcrResult(text: 'x', confidence: 0.1, provider: 'slow');
  }
}
