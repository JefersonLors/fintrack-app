import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

import '../../domain/exceptions/operation_cancelled_exception.dart';
import '../../domain/infrastructure/i_document_scanner_service.dart';

class MLKitDocumentScannerService implements IDocumentScannerService {
  MLKitDocumentScannerService({
    FinTrackDocumentScannerAdapter Function()? scannerFactory,
    bool Function()? isAndroid,
  }) : _scannerFactory = scannerFactory ?? _MLKitDocumentScannerAdapter.new,
       _isAndroid = isAndroid ?? (() => Platform.isAndroid);

  final FinTrackDocumentScannerAdapter Function() _scannerFactory;
  final bool Function() _isAndroid;

  @override
  Future<File> scanDocument() async {
    if (!_isAndroid()) {
      throw const FormatException(
        'Scanner de documentos disponível apenas no Android.',
      );
    }

    final scanner = _scannerFactory();

    try {
      final images = await scanner.scanDocument().onError<PlatformException>((
        error,
        stackTrace,
      ) {
        final message = error.message?.toLowerCase() ?? '';
        if (message.contains('cancel')) {
          throw const OperationCancelledException('Scanner cancelado.');
        }
        throw error;
      });
      final path = images.isEmpty ? null : images.first;
      if (path == null || path.isEmpty) {
        throw const OperationCancelledException('Scanner cancelado.');
      }
      final file = File(path);
      if (!await file.exists()) {
        throw const FormatException('Imagem escaneada não encontrada.');
      }
      return file;
    } finally {
      scanner.close();
    }
  }
}

abstract class FinTrackDocumentScannerAdapter {
  Future<List<String>> scanDocument();
  void close();
}

class _MLKitDocumentScannerAdapter implements FinTrackDocumentScannerAdapter {
  _MLKitDocumentScannerAdapter()
    : _scanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormats: const {DocumentFormat.jpeg},
          mode: ScannerMode.base,
          pageLimit: 1,
          isGalleryImport: false,
        ),
      );

  final DocumentScanner _scanner;

  @override
  Future<List<String>> scanDocument() async {
    final result = await _scanner.scanDocument();
    return result.images ?? const <String>[];
  }

  @override
  void close() {
    _scanner.close();
  }
}
