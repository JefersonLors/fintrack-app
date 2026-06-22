import 'dart:io';

abstract class IDocumentScannerService {
  Future<File> scanDocument();
}
