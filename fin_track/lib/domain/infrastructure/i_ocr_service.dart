import 'dart:io';

import '../value_objects/ocr_result.dart';

abstract class IOCRService {
  Future<OcrResult> process(File file);
}
