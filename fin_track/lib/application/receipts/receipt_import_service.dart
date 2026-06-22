import 'dart:io';

import '../../domain/entities/receipt.dart';
import '../../domain/infrastructure/i_document_scanner_service.dart';
import 'receipt_file_service.dart';

typedef ProcessPreviewCallback = Future<Receipt> Function(File image);
typedef SaveConfirmedReceiptCallback =
    Future<Receipt> Function(Receipt receipt);

class ReceiptImportService {
  const ReceiptImportService({
    required ReceiptFileService fileService,
    IDocumentScannerService? scanner,
  }) : _fileService = fileService,
       _scanner = scanner;

  final ReceiptFileService _fileService;
  final IDocumentScannerService? _scanner;

  Future<File> scanDocument() {
    final scanner = _scanner;
    if (scanner == null) {
      throw const FormatException('Scanner de documentos indisponível.');
    }
    return scanner.scanDocument();
  }

  Future<File> captureImage() => _fileService.captureImage();

  Future<List<File>> importFiles() => _fileService.importFiles();

  Future<Receipt> register(
    File image, {
    required ProcessPreviewCallback processPreview,
    required SaveConfirmedReceiptCallback saveConfirmed,
  }) async {
    final preview = await processPreview(image);
    return saveConfirmed(preview);
  }
}
