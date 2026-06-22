import 'dart:io';

import '../../../infrastructure/diagnostics/error_handling.dart';

class BatchStagingResult {
  const BatchStagingResult({required this.directory, required this.files});

  final Directory directory;
  final List<File> files;
}

class BatchStagingService {
  const BatchStagingService();

  Future<BatchStagingResult> stage(List<File> files) async {
    final base = Directory(
      '${Directory.systemTemp.path}/fintrack/pending_imports',
    );
    await base.create(recursive: true);
    await _cleanOldStagingDirectories(base);

    final staging = Directory(
      '${base.path}/batch_${DateTime.now().microsecondsSinceEpoch}',
    );
    await staging.create(recursive: true);

    final stagedFiles = <File>[];
    try {
      for (var index = 0; index < files.length; index++) {
        final source = files[index];
        final target = File(
          '${staging.path}/${_stagingFileName(index + 1, source.path)}',
        );
        await source.copy(target.path);
        if (!await target.exists() || await target.length() == 0) {
          throw const FileSystemException(
            'Não foi possível preparar a importação em lote.',
          );
        }
        stagedFiles.add(target);
      }
    } catch (error, stackTrace) {
      await _deleteDirectorySilently(staging);
      Error.throwWithStackTrace(error, stackTrace);
    }

    await discardTemporaryOriginals(files);
    return BatchStagingResult(directory: staging, files: stagedFiles);
  }

  Future<void> discardTemporaryOriginals(List<File> files) async {
    for (final file in files) {
      if (!_looksLikeTemporaryImport(file.path)) {
        continue;
      }
      await ignoreCleanupFailure(() async {
        if (await file.exists()) {
          await file.delete();
        }
      });
    }
  }

  Future<void> deleteDirectorySilently(Directory directory) {
    return _deleteDirectorySilently(directory);
  }
}

String _stagingFileName(int number, String path) {
  final originalName = _fileNameFromPath(path);
  final safeName = originalName
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  return 'item_${number.toString().padLeft(3, '0')}_$safeName';
}

String _fileNameFromPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.split('/').last;
}

bool _looksLikeTemporaryImport(String path) {
  final normalized = path.replaceAll('\\', '/').toLowerCase();
  return normalized.contains('/shared_imports/');
}

Future<void> _cleanOldStagingDirectories(Directory base) async {
  if (!await base.exists()) {
    return;
  }
  final limit = DateTime.now().subtract(const Duration(days: 1));
  await for (final item in base.list(recursive: false)) {
    if (item is! Directory) {
      continue;
    }
    await ignoreCleanupFailure(() async {
      final modified = await item.stat().then((stat) => stat.modified);
      if (modified.isBefore(limit)) {
        await item.delete(recursive: true);
      }
    });
  }
}

Future<void> _deleteDirectorySilently(Directory directory) async {
  await ignoreCleanupFailure(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });
}
