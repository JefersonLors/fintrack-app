import 'dart:io';
import 'dart:typed_data';

class TemporaryRestoreDirectory {
  const TemporaryRestoreDirectory({
    required this.path,
    required this.rollbackPath,
  });

  final String path;
  final String rollbackPath;
}

abstract class IImageService {
  Future<File> capture();
  Future<List<File>> importMany();
  Future<String> saveToFileSystem(File file);
  Future<String> restoreToFileSystem(String fileName, Uint8List bytes);
  Future<TemporaryRestoreDirectory> createTemporaryRestore();
  Future<String> restoreToTemporaryDirectory(
    TemporaryRestoreDirectory session,
    String fileName,
    Uint8List bytes,
  );
  Future<void> promoteTemporaryRestore(TemporaryRestoreDirectory session);
  Future<void> revertTemporaryRestore(TemporaryRestoreDirectory session);
  Future<void> discardTemporaryRestore(TemporaryRestoreDirectory session);
  Future<void> delete(String fileName);
  bool managedByApp(String fileName);
  Future<void> deleteIfManaged(String fileName);
  Future<void> deleteAll();
  Future<int> deleteUnreferencedFiles(Set<String> fileNames);
  String rebuildPath(String fileName);
  Future<int> calculateUsedSpaceBytes();
  Future<void> share(String fileName, String fileType);
  Future<void> shareMany(List<String> fileNames);
  Future<void> saveToDevice(String fileName, String fileType);
  Future<void> saveManyToDevice(List<String> fileNames);
}
