part of 'receipt_service_test.dart';

class _FakeScannerService implements IDocumentScannerService {
  const _FakeScannerService(this.file);

  final File file;

  @override
  Future<File> scanDocument() async => file;
}

class _FakeImageService implements IImageService {
  @override
  Future<int> calculateUsedSpaceBytes() async => 0;

  @override
  Future<File> capture() => throw UnimplementedError();

  @override
  Future<void> share(String fileName, String fileType) async {}

  @override
  Future<void> shareMany(List<String> fileNames) async {}

  @override
  Future<void> saveToDevice(String fileName, String fileType) async {}

  @override
  Future<void> saveManyToDevice(List<String> fileNames) async {}

  @override
  Future<void> delete(String fileName) async {}

  @override
  bool managedByApp(String fileName) => false;

  @override
  Future<void> deleteIfManaged(String fileName) async {}

  @override
  Future<void> deleteAll() async {}

  @override
  Future<int> deleteUnreferencedFiles(Set<String> fileNames) async {
    return 0;
  }

  @override
  Future<List<File>> importMany() => throw UnimplementedError();

  @override
  String rebuildPath(String fileName) => fileName;

  @override
  Future<String> saveToFileSystem(File file) async => file.path;

  @override
  Future<String> restoreToFileSystem(String fileName, Uint8List bytes) async {
    await File(fileName).writeAsBytes(bytes);
    return fileName;
  }

  @override
  Future<TemporaryRestoreDirectory> createTemporaryRestore() async {
    return const TemporaryRestoreDirectory(path: '', rollbackPath: '');
  }

  @override
  Future<String> restoreToTemporaryDirectory(
    TemporaryRestoreDirectory session,
    String fileName,
    Uint8List bytes,
  ) async {
    await File(fileName).writeAsBytes(bytes);
    return fileName;
  }

  @override
  Future<void> promoteTemporaryRestore(
    TemporaryRestoreDirectory session,
  ) async {}

  @override
  Future<void> revertTemporaryRestore(
    TemporaryRestoreDirectory session,
  ) async {}

  @override
  Future<void> discardTemporaryRestore(
    TemporaryRestoreDirectory session,
  ) async {}
}

class _RecordingImageService extends _FakeImageService {
  _RecordingImageService({
    File? captured,
    List<File>? multiple,
    this.usedSpaceBytes = 0,
    this.rebuiltPath,
  }) : captured = captured ?? File('captured.txt'),
       multiple = multiple ?? const <File>[];

  final File captured;
  final List<File> multiple;
  final int usedSpaceBytes;
  final String? rebuiltPath;
  final sharedFiles = <String>[];
  final savedToDevice = <String>[];
  final deletedIfManaged = <String>[];
  Set<String>? receivedReferences;
  var captures = 0;

  @override
  Future<int> calculateUsedSpaceBytes() async => usedSpaceBytes;

  @override
  Future<void> share(String fileName, String fileType) async {
    sharedFiles.add('$fileName:$fileType');
  }

  @override
  Future<void> saveToDevice(String fileName, String fileType) async {
    savedToDevice.add('$fileName:$fileType');
  }

  @override
  Future<void> deleteIfManaged(String fileName) async {
    deletedIfManaged.add(fileName);
  }

  @override
  Future<int> deleteUnreferencedFiles(Set<String> fileNames) async {
    receivedReferences = fileNames;
    return 123;
  }

  @override
  Future<File> capture() async {
    captures++;
    return captured;
  }

  @override
  Future<List<File>> importMany() async => multiple;

  @override
  String rebuildPath(String fileName) {
    return rebuiltPath ?? super.rebuildPath(fileName);
  }
}

class _FakeConfigurationService implements IConfigurationService {
  @override
  Future<void> update(Configuration configuration) async {}

  @override
  Future<Configuration> load() async => const Configuration(id: 0);

  @override
  Future<void> configureAutomaticBackup({
    required bool active,
    required int intervalDays,
  }) async {}

  @override
  Future<bool> verifyGoogleToken() async => false;

  @override
  Future<bool> verifyCloudToken() async => false;

  @override
  Future<void> linkGoogle() async {}

  @override
  Future<void> linkCloud(CloudProvider provider) async {}

  @override
  Future<void> unlinkGoogle() async {}

  @override
  Future<void> unlinkCloud() async {}

  @override
  Future<void> normalizeAutomaticBackupIfNeeded() async {}

  @override
  Future<int> calculateUsedSpaceBytes() async => 0;

  @override
  Future<void> completeOnboarding() async {}

  @override
  Future<void> resetOnboarding() async {}

  @override
  Stream<Configuration> watch() async* {}
}

class _StorageLimitConfigurationService extends _FakeConfigurationService {
  _StorageLimitConfigurationService({
    required this.limitMb,
    this.usedSpaceBytes = 0,
  });

  final int limitMb;
  final int usedSpaceBytes;

  @override
  Future<Configuration> load() async {
    return Configuration(id: 0, storageLimitMB: limitMb);
  }

  @override
  Future<int> calculateUsedSpaceBytes() async => usedSpaceBytes;
}
