import 'dart:io';
import 'dart:typed_data';

import '../../domain/exceptions/operation_cancelled_exception.dart';
import '../../domain/infrastructure/i_image_service.dart';
import '../diagnostics/error_handling.dart';
import 'fin_track_platform.dart';

class ImageService implements IImageService {
  ImageService({Directory? baseDirectory})
    : _baseDirectory =
          baseDirectory ??
          Directory('${Directory.systemTemp.path}/fin_track_private_files') {
    _baseDirectory.createSync(recursive: true);
  }

  final Directory _baseDirectory;

  @override
  Future<File> capture() async {
    final nativePath = await FinTrackPlatform.captureImage();
    if (nativePath != null) {
      final file = File(nativePath);
      if (await file.exists()) {
        return file;
      }
    }

    if (Platform.isAndroid) {
      throw const OperationCancelledException('Captura cancelada.');
    }

    throw const FormatException('Captura indisponível neste ambiente.');
  }

  @override
  Future<List<File>> importMany() async {
    final paths = await FinTrackPlatform.selectFiles();
    final files = <File>[];
    for (final path in paths) {
      final file = File(path);
      if (await file.exists()) {
        files.add(file);
      }
    }

    if (files.isNotEmpty) {
      return files;
    }

    if (Platform.isAndroid) {
      throw const OperationCancelledException('Importação cancelada.');
    }

    throw const FormatException('Importação indisponível neste ambiente.');
  }

  @override
  Future<String> saveToFileSystem(File file) async {
    await _baseDirectory.create(recursive: true);

    if (_sameDirectory(file.parent, _baseDirectory)) {
      return _basename(file.path);
    }

    final name = _uniqueName(_basename(file.path));
    final destination = File('${_baseDirectory.path}/$name');
    if (file.path != destination.path) {
      await file.copy(destination.path);
    }
    return name;
  }

  @override
  Future<String> restoreToFileSystem(String fileName, Uint8List bytes) async {
    await _baseDirectory.create(recursive: true);
    final name = _uniqueName(_basename(fileName));
    final destination = File('${_baseDirectory.path}/$name');
    await destination.writeAsBytes(bytes, flush: true);
    return name;
  }

  @override
  Future<TemporaryRestoreDirectory> createTemporaryRestore() async {
    final parent = _baseDirectory.parent;
    await parent.create(recursive: true);
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final staging = Directory('${parent.path}/restore_staging/$timestamp');
    final rollback = Directory('${parent.path}/restore_rollback_$timestamp');
    await staging.create(recursive: true);
    return TemporaryRestoreDirectory(
      path: staging.path,
      rollbackPath: rollback.path,
    );
  }

  @override
  Future<String> restoreToTemporaryDirectory(
    TemporaryRestoreDirectory session,
    String fileName,
    Uint8List bytes,
  ) async {
    final directory = Directory(session.path);
    await directory.create(recursive: true);
    final name = _uniqueName(_basename(fileName));
    final destination = File('${directory.path}/$name');
    await destination.writeAsBytes(bytes, flush: true);
    return name;
  }

  @override
  Future<void> promoteTemporaryRestore(
    TemporaryRestoreDirectory session,
  ) async {
    final staging = Directory(session.path);
    final rollback = Directory(session.rollbackPath);
    if (!await staging.exists()) {
      throw const FileSystemException(
        'Diretório temporário de restauração não encontrado.',
      );
    }

    if (await rollback.exists()) {
      await rollback.delete(recursive: true);
    }

    var rollbackCreated = false;
    try {
      if (await _baseDirectory.exists()) {
        await _baseDirectory.rename(rollback.path);
        rollbackCreated = true;
      }
      await staging.rename(_baseDirectory.path);
      await _cleanTemporaryRestoreRoot();
    } catch (error, stackTrace) {
      await _rollbackPromotion(staging, rollback, rollbackCreated);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<void> revertTemporaryRestore(TemporaryRestoreDirectory session) async {
    final rollback = Directory(session.rollbackPath);
    if (!await rollback.exists()) {
      return;
    }

    if (await _baseDirectory.exists()) {
      await _baseDirectory.delete(recursive: true);
    }
    await rollback.rename(_baseDirectory.path);

    final staging = Directory(session.path);
    if (await staging.exists()) {
      await staging.delete(recursive: true);
    }
    await _cleanTemporaryRestoreRoot();
  }

  @override
  Future<void> discardTemporaryRestore(
    TemporaryRestoreDirectory session,
  ) async {
    final staging = Directory(session.path);
    if (await staging.exists()) {
      await staging.delete(recursive: true);
    }
    final rollback = Directory(session.rollbackPath);
    if (await rollback.exists()) {
      await rollback.delete(recursive: true);
    }
    await _cleanTemporaryRestoreRoot();
  }

  @override
  Future<void> delete(String fileName) async {
    final file = File(rebuildPath(fileName));
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  bool managedByApp(String fileName) {
    final path = rebuildPath(fileName);
    final parent = _normalizeDirectory(File(path).parent.path);
    return parent == _normalizeDirectory(_baseDirectory.path);
  }

  @override
  Future<void> deleteIfManaged(String fileName) async {
    if (!managedByApp(fileName)) {
      return;
    }
    await delete(fileName);
  }

  @override
  Future<void> deleteAll() async {
    if (!await _baseDirectory.exists()) {
      return;
    }
    await for (final item in _baseDirectory.list(recursive: false)) {
      if (item is File && await item.exists()) {
        await item.delete();
      }
    }
  }

  @override
  Future<int> deleteUnreferencedFiles(Set<String> fileNames) async {
    final referenced = _referencedPaths(fileNames);
    var deletedBytes = 0;
    if (!await _baseDirectory.exists()) {
      return 0;
    }
    await for (final item in _baseDirectory.list(recursive: false)) {
      if (item is! File || !await item.exists()) {
        continue;
      }
      final path = _normalizeDirectory(item.path);
      if (referenced.contains(path)) {
        continue;
      }
      deletedBytes += await item.length();
      await item.delete();
    }
    return deletedBytes;
  }

  @override
  String rebuildPath(String fileName) {
    final direct = File(fileName);
    if (_isAbsolutePath(fileName) && direct.existsSync()) {
      return direct.path;
    }

    final name = _basename(fileName);
    return File('${_baseDirectory.path}/$name').path;
  }

  @override
  Future<int> calculateUsedSpaceBytes() async {
    var total = 0;
    if (!await _baseDirectory.exists()) {
      return 0;
    }
    await for (final item in _baseDirectory.list(recursive: false)) {
      if (item is File) {
        total += await item.length();
      }
    }
    return total;
  }

  Set<String> _referencedPaths(Set<String> fileNames) {
    final paths = <String>{};
    for (final fileName in fileNames) {
      final name = _basename(fileName);
      if (_isAbsolutePath(fileName)) {
        paths.add(_normalizeDirectory(fileName));
      }
      paths.add(_normalizeDirectory('${_baseDirectory.path}/$name'));
    }
    return paths;
  }

  @override
  Future<void> share(String fileName, String fileType) async {
    final path = rebuildPath(fileName);
    final shared = await FinTrackPlatform.shareFile(
      path: path,
      mimeType: fileType,
    );
    if (!shared) {
      throw StateError('Não foi possível abrir o compartilhamento.');
    }
  }

  @override
  Future<void> shareMany(List<String> fileNames) async {
    final paths = fileNames.map(rebuildPath).toList();
    final shared = await FinTrackPlatform.shareFiles(paths: paths);
    if (!shared) {
      throw StateError('Não foi possível abrir o compartilhamento.');
    }
  }

  @override
  Future<void> saveToDevice(String fileName, String fileType) async {
    final path = rebuildPath(fileName);
    final saved = await FinTrackPlatform.saveFileToDevice(
      path: path,
      mimeType: fileType,
    );
    if (!saved) {
      throw StateError('Não foi possível salvar no dispositivo.');
    }
  }

  @override
  Future<void> saveManyToDevice(List<String> fileNames) async {
    final paths = fileNames.map(rebuildPath).toList();
    final saved = await FinTrackPlatform.saveFilesToDevice(paths: paths);
    if (!saved) {
      throw StateError('Não foi possível salvar no dispositivo.');
    }
  }

  String _uniqueName(String originalName) {
    final safe = originalName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return '${DateTime.now().millisecondsSinceEpoch}_$safe';
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  bool _sameDirectory(Directory a, Directory b) {
    return _normalizeDirectory(a.path) == _normalizeDirectory(b.path);
  }

  String _normalizeDirectory(String path) {
    return path.replaceAll('\\', '/').replaceFirst(RegExp(r'/$'), '');
  }

  Future<void> _rollbackPromotion(
    Directory staging,
    Directory rollback,
    bool rollbackCreated,
  ) async {
    await ignoreCleanupFailure(
      () async {
        if (await _baseDirectory.exists()) {
          await _baseDirectory.delete(recursive: true);
        }
        if (rollbackCreated && await rollback.exists()) {
          await rollback.rename(_baseDirectory.path);
        }
      },
      diagnosticContext: 'Falha ao restaurar arquivos durante rollback',
      report: true,
    );

    await ignoreCleanupFailure(() async {
      if (await staging.exists()) {
        await staging.delete(recursive: true);
      }
    });
  }

  Future<void> _cleanTemporaryRestoreRoot() async {
    final root = Directory('${_baseDirectory.parent.path}/restore_staging');
    if (!await root.exists()) {
      return;
    }
    await ignoreCleanupFailure(() async {
      if (await root.list(recursive: false).isEmpty) {
        await root.delete();
      }
    });
  }

  bool _isAbsolutePath(String path) {
    return path.startsWith('/') || RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(path);
  }
}
