import 'dart:io';

class OcrImageQuality {
  const OcrImageQuality({
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.sharpness,
    required this.contrast,
    required this.brightness,
    required this.orientationDegrees,
    required this.hasQrCode,
    required this.hasBarcode,
  });

  final int width;
  final int height;
  final int sizeBytes;
  final double sharpness;
  final double contrast;
  final double brightness;
  final int orientationDegrees;
  final bool hasQrCode;
  final bool hasBarcode;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'width': width,
      'height': height,
      'sizeBytes': sizeBytes,
      'sharpness': sharpness,
      'contrast': contrast,
      'brightness': brightness,
      'orientationDegrees': orientationDegrees,
      'hasQrCode': hasQrCode,
      'hasBarcode': hasBarcode,
    };
  }
}

class OcrImageVariant {
  const OcrImageVariant({
    required this.name,
    required this.file,
    this.temporary = false,
  });

  final String name;
  final File file;
  final bool temporary;
}

abstract class IImagePreprocessorService {
  Future<File> preprocess(File file);

  Future<List<OcrImageVariant>> generateVariants(File file);

  Future<OcrImageQuality> analyzeQuality(
    File file, {
    bool hasQrCode = false,
    bool hasBarcode = false,
  });

  Future<void> cleanOldTemporaryFiles();
}
