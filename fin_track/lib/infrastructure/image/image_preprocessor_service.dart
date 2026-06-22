import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

import '../../domain/infrastructure/i_image_preprocessor_service.dart';
import '../diagnostics/error_handling.dart';

class ImagePreprocessorService implements IImagePreprocessorService {
  ImagePreprocessorService({Directory? temporaryDirectory})
    : _temporaryDirectory =
          temporaryDirectory ??
          Directory('${Directory.systemTemp.path}/fintrack/tmp_ocr');

  final Directory _temporaryDirectory;

  @override
  Future<File> preprocess(File file) async {
    final variants = await generateVariants(file);
    return variants
        .firstWhere(
          (variant) => variant.temporary,
          orElse: () => variants.first,
        )
        .file;
  }

  @override
  Future<List<OcrImageVariant>> generateVariants(File file) async {
    return fallbackOnFailure(
      () async {
        final variants = await Isolate.run(
          () => _generateImageVariantsSync(file.path, _temporaryDirectory.path),
        );
        return variants
            .map(
              (variant) => OcrImageVariant(
                name: variant['name']! as String,
                file: File(variant['path']! as String),
                temporary: variant['temporary']! as bool,
              ),
            )
            .toList(growable: false);
      },
      fallback: <OcrImageVariant>[
        OcrImageVariant(name: 'original', file: file),
      ],
      diagnosticContext: 'Falha ao gerar variantes da imagem para OCR',
      report: true,
    );
  }

  @override
  Future<OcrImageQuality> analyzeQuality(
    File file, {
    bool hasQrCode = false,
    bool hasBarcode = false,
  }) async {
    final sizeBytes = await file.exists() ? await file.length() : 0;
    return fallbackOnFailure(
      () async {
        final metrics = await Isolate.run(
          () => _analyzeImageQualitySync(file.path, sizeBytes),
        );
        return OcrImageQuality(
          width: metrics['width']! as int,
          height: metrics['height']! as int,
          sizeBytes: sizeBytes,
          sharpness: metrics['sharpness']! as double,
          contrast: metrics['contrast']! as double,
          brightness: metrics['brightness']! as double,
          orientationDegrees: metrics['orientationDegrees']! as int,
          hasQrCode: hasQrCode,
          hasBarcode: hasBarcode,
        );
      },
      fallback: OcrImageQuality(
        width: 0,
        height: 0,
        sizeBytes: sizeBytes,
        sharpness: 0,
        contrast: 0,
        brightness: 0,
        orientationDegrees: 0,
        hasQrCode: hasQrCode,
        hasBarcode: hasBarcode,
      ),
      diagnosticContext: 'Falha ao analisar qualidade da imagem para OCR',
      report: true,
    );
  }

  @override
  Future<void> cleanOldTemporaryFiles() async {
    if (!await _temporaryDirectory.exists()) {
      return;
    }
    final limit = DateTime.now().subtract(const Duration(days: 1));
    await for (final item in _temporaryDirectory.list()) {
      if (item is! File) {
        continue;
      }
      await ignoreCleanupFailure(() async {
        final modified = await item.lastModified();
        if (modified.isBefore(limit) && await item.exists()) {
          await item.delete();
        }
      });
    }
  }
}

List<Map<String, Object>> _generateImageVariantsSync(
  String filePath,
  String temporaryDirectoryPath,
) {
  final file = File(filePath);
  final variants = <Map<String, Object>>[
    {'name': 'original', 'path': filePath, 'temporary': false},
  ];

  if (!_shouldProcessSync(file)) {
    return variants;
  }

  final image = img.decodeImage(file.readAsBytesSync());
  if (image == null) {
    return variants;
  }

  final oriented = img.bakeOrientation(image);
  final grayscaleContrast = _grayscaleContrast(oriented);
  variants.add({
    'name': 'grayscale_contrast',
    'path': _saveTemporarySync(file, temporaryDirectoryPath, grayscaleContrast),
    'temporary': true,
  });

  final binarized = _adaptiveBinarize(oriented);
  variants.add({
    'name': 'adaptive_binarized',
    'path': _saveTemporarySync(file, temporaryDirectoryPath, binarized),
    'temporary': true,
  });

  return variants;
}

Map<String, Object> _analyzeImageQualitySync(String filePath, int sizeBytes) {
  final image = img.decodeImage(File(filePath).readAsBytesSync());
  if (image == null) {
    return _emptyMetrics(sizeBytes);
  }
  final oriented = img.bakeOrientation(image);
  final metrics = _calculateMetrics(oriented);
  return <String, Object>{
    'width': oriented.width,
    'height': oriented.height,
    'sizeBytes': sizeBytes,
    'sharpness': metrics.sharpness,
    'contrast': metrics.contrast,
    'brightness': metrics.brightness,
    'orientationDegrees': oriented.width >= oriented.height ? 0 : 90,
  };
}

Map<String, Object> _emptyMetrics(int sizeBytes) {
  return <String, Object>{
    'width': 0,
    'height': 0,
    'sizeBytes': sizeBytes,
    'sharpness': 0.0,
    'contrast': 0.0,
    'brightness': 0.0,
    'orientationDegrees': 0,
  };
}

bool _shouldProcessSync(File file) {
  if (!file.existsSync()) {
    return false;
  }
  final lower = file.path.toLowerCase();
  if (lower.endsWith('.txt') || lower.endsWith('.pdf')) {
    return false;
  }
  return true;
}

img.Image _grayscaleContrast(img.Image image) {
  var processed = img.grayscale(image);
  processed = img.adjustColor(
    processed,
    contrast: 1.18,
    brightness: 1.03,
    saturation: 0,
  );
  if (processed.width >= 3 && processed.height >= 3) {
    processed = img.convolution(
      processed,
      filter: const <num>[0, -1, 0, -1, 5, -1, 0, -1, 0],
    );
  }
  return processed.convert(numChannels: 3);
}

img.Image _adaptiveBinarize(img.Image image) {
  final grayscale = img.grayscale(image);
  final metrics = _calculateMetrics(grayscale);
  final threshold = (metrics.brightness * 255).clamp(92, 180).round();
  final output = img.Image(width: grayscale.width, height: grayscale.height);
  for (var y = 0; y < grayscale.height; y++) {
    for (var x = 0; x < grayscale.width; x++) {
      final pixel = grayscale.getPixel(x, y);
      final luminance = img.getLuminance(pixel).round();
      final color = luminance >= threshold ? 255 : 0;
      output.setPixelRgb(x, y, color, color, color);
    }
  }
  return output.convert(numChannels: 3);
}

_ImageMetrics _calculateMetrics(img.Image image) {
  if (image.width == 0 || image.height == 0) {
    return const _ImageMetrics(sharpness: 0, contrast: 0, brightness: 0);
  }

  var sum = 0.0;
  var sumSquares = 0.0;
  var sumEdges = 0.0;
  var edgeSamples = 0;
  final total = image.width * image.height;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final luminance = img.getLuminance(image.getPixel(x, y)).toDouble();
      sum += luminance;
      sumSquares += luminance * luminance;
      if (x > 0 && y > 0) {
        final left = img.getLuminance(image.getPixel(x - 1, y)).toDouble();
        final above = img.getLuminance(image.getPixel(x, y - 1)).toDouble();
        sumEdges += (luminance - left).abs() + (luminance - above).abs();
        edgeSamples += 2;
      }
    }
  }

  final mean = sum / total;
  final variance = (sumSquares / total) - (mean * mean);
  final contrast = (variance <= 0 ? 0.0 : math.sqrt(variance) / 128).clamp(
    0.0,
    1.0,
  );
  final sharpness = edgeSamples == 0
      ? 0.0
      : (sumEdges / edgeSamples / 32).clamp(0.0, 1.0);
  return _ImageMetrics(
    sharpness: sharpness,
    contrast: contrast,
    brightness: (mean / 255).clamp(0.0, 1.0),
  );
}

String _saveTemporarySync(
  File file,
  String temporaryDirectoryPath,
  img.Image image,
) {
  final destination = _createTemporaryFileSync(file, temporaryDirectoryPath);
  destination.writeAsBytesSync(img.encodeJpg(image, quality: 95), flush: true);
  return destination.path;
}

File _createTemporaryFileSync(File file, String temporaryDirectoryPath) {
  Directory(temporaryDirectoryPath).createSync(recursive: true);
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final name = file.uri.pathSegments.isEmpty
      ? 'receipt'
      : file.uri.pathSegments.last;
  final safe = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  return File('$temporaryDirectoryPath/${timestamp}_$safe.jpg');
}

class _ImageMetrics {
  const _ImageMetrics({
    required this.sharpness,
    required this.contrast,
    required this.brightness,
  });

  final double sharpness;
  final double contrast;
  final double brightness;
}
