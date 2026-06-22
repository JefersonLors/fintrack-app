import 'dart:io';

abstract class IVisualCodeService {
  Future<List<String>> readCodes(File file);
}
