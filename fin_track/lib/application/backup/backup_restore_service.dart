import 'dart:typed_data';

import '../../domain/entities/configuration.dart';
import '../../domain/infrastructure/i_error_reporter.dart';
import '../../domain/infrastructure/i_image_service.dart';
import '../../domain/repositories/i_configuration_repository.dart';
import '../../domain/repositories/i_receipt_repository.dart';
import 'backup_payload_service.dart';

class BackupRestoreService {
  const BackupRestoreService({
    required BackupPayloadService payload,
    required IImageService images,
    required IReceiptRepository receipts,
    required IConfigurationRepository configurations,
    IErrorReporter? errorReporter,
  }) : _payload = payload,
       _images = images,
       _receipts = receipts,
       _configurations = configurations,
       _errorReporter = errorReporter;

  final BackupPayloadService _payload;
  final IImageService _images;
  final IReceiptRepository _receipts;
  final IConfigurationRepository _configurations;
  final IErrorReporter? _errorReporter;

  Future<int> restore({
    required List<Uint8List> files,
    required String password,
    required Configuration configuration,
  }) async {
    TemporaryRestoreDirectory? temporaryRestore;
    var filesPromoted = false;

    try {
      final package = await _payload.firstValidBackup(files, password);
      _payload.validateRestorePackage(package);
      await _payload.validateRestoreLimit(package, configuration);
      temporaryRestore = await _images.createTemporaryRestore();
      final receipts = await _payload.restoreFilesAndBuildReceipts(
        package,
        temporaryRestore,
      );
      await _images.promoteTemporaryRestore(temporaryRestore);
      filesPromoted = true;
      await _receipts.replaceAll(receipts);
      await _configurations.save(
        _payload.restoreConfiguration(package, configuration),
      );
      await _images.discardTemporaryRestore(temporaryRestore);
      return receipts.length;
    } catch (error, stackTrace) {
      await _rollbackTemporaryRestore(temporaryRestore, filesPromoted);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _rollbackTemporaryRestore(
    TemporaryRestoreDirectory? temporaryRestore,
    bool filesPromoted,
  ) async {
    if (temporaryRestore == null) {
      return;
    }
    try {
      if (filesPromoted) {
        await _images.revertTemporaryRestore(temporaryRestore);
      } else {
        await _images.discardTemporaryRestore(temporaryRestore);
      }
    } catch (rollbackError, rollbackStackTrace) {
      _errorReporter?.record(
        StateError('Falha ao desfazer restauração de backup. $rollbackError'),
        rollbackStackTrace,
      );
    }
  }
}
