import 'dart:io';

import '../../domain/exceptions/storage_limit_exception.dart';
import '../../domain/services/i_configuration_service.dart';

class StorageLimitPolicy {
  const StorageLimitPolicy({required IConfigurationService configuration})
    : _configuration = configuration;

  final IConfigurationService _configuration;

  Future<void> validateSpaceForNewReceipt([File? file]) async {
    await validateStorageLimitBytes(
      file == null ? 0 : await fileSize(file),
      plural: false,
    );
  }

  Future<void> validateSpaceForNewReceipts(List<File> files) async {
    var totalBytes = 0;
    for (final file in files) {
      final sizeBytes = await fileSize(file);
      await validateStorageLimitBytes(sizeBytes, plural: false);
      totalBytes += sizeBytes;
    }
    await validateStorageLimitBytes(totalBytes, plural: true);
  }

  Future<void> validateStorageLimitBytes(
    int fileSizeBytes, {
    required bool plural,
  }) async {
    final configuration = await _configuration.load();
    final limitBytes = configuration.storageLimitMB * 1024 * 1024;
    final subject = plural ? 'Os comprovantes' : 'O comprovante';
    final action = plural
        ? 'Adicionar estes comprovantes'
        : 'Adicionar este comprovante';
    if (fileSizeBytes > limitBytes) {
      throw StorageLimitException('$subject excede o limite de armazenamento.');
    }

    final usedBytes = await _configuration.calculateUsedSpaceBytes();
    if (usedBytes + fileSizeBytes > limitBytes) {
      throw StorageLimitException(
        '$action ultrapassaria o limite de armazenamento.',
      );
    }
  }

  Future<int> fileSize(File file) async {
    if (!await file.exists()) {
      return 0;
    }
    return file.length();
  }
}
