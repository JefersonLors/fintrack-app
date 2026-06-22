import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../../domain/infrastructure/i_visual_code_service.dart';
import '../diagnostics/error_handling.dart';

class GoogleMLKitVisualCodeService implements IVisualCodeService {
  @override
  Future<List<String>> readCodes(File file) async {
    // coverage:ignore-start
    final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    try {
      final inputImage = InputImage.fromFile(file);
      final barcodes = await scanner.processImage(inputImage);
      return normalizeVisualCodeValues(
        barcodes.map((barcode) => barcode.rawValue ?? barcode.displayValue),
      );
    } catch (error, stackTrace) {
      recordHandledError(
        error,
        stackTrace,
        diagnosticContext: 'Falha ao ler QR code/código visual com ML Kit',
      );
      return const [];
    } finally {
      await ignoreCleanupFailure(() async {
        await scanner.close();
      });
    }
    // coverage:ignore-end
  }
}

@visibleForTesting
List<String> normalizeVisualCodeValues(Iterable<String?> values) {
  return values
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();
}
