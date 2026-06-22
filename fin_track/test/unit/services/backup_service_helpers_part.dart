part of 'backup_service_test.dart';

Future<_BackupEnvironment> _createEnvironment({
  _FakeCloudStorage? cloud,
}) async {
  final database = AppDatabase.memory();
  final images = ImageService(
    baseDirectory: Directory(
      '${Directory.systemTemp.path}/fin_track_backup_test_${DateTime.now().microsecondsSinceEpoch}',
    ),
  );
  final receipts = ReceiptRepository(database);
  final configurations = ConfigurationRepository(database);
  final backups = BackupRepository(database);
  final resolvedCloud = cloud ?? _FakeCloudStorage();
  return _BackupEnvironment(
    database: database,
    images: images,
    receipts: receipts,
    configurations: configurations,
    backups: backups,
    cloud: resolvedCloud,
    backupService: BackupService(
      receipts: receipts,
      backups: backups,
      configurations: configurations,
      cryptography: AES256Service(iterations: 1000),
      cloud: resolvedCloud,
      images: images,
    ),
    configurationService: ConfigurationService(
      configurations: configurations,
      cloud: resolvedCloud,
      images: images,
    ),
  );
}

Future<Receipt> _saveReceipt(
  IReceiptRepository receipts,
  ImageService images, {
  String fileText = 'comprovante em texto claro',
  String extractedContent = 'Mercado Central Total R\$ 128,45',
}) async {
  final source = File(
    '${Directory.systemTemp.path}/fin_track_backup_receipt_${DateTime.now().microsecondsSinceEpoch}.txt',
  );
  await source.writeAsString(fileText);
  final fileName = await images.saveToFileSystem(source);
  return receipts.save(
    Receipt(
      id: 0,
      type: ReceiptType.invoice,
      expense: true,
      fileName: fileName,
      fileType: 'text/plain',
      fileHash: 'test-hash',
      fileSize: await source.length(),
      extractedContent: extractedContent,
      registeredAt: DateTime(2026, 4, 28, 10, 30),
      extractedData: ExtractedData(
        id: 0,
        receiptId: 0,
        amount: 128.45,
        transactionDate: DateTime(2026, 4, 28),
        establishment: 'Mercado Central',
        paymentMethod: 'cartao de credito',
        ocrConfidence: 0.91,
      ),
      embedding: Embedding(
        id: 0,
        receiptId: 0,
        vector: Uint8List.fromList(<int>[1, 2, 3, 4]),
        model: 'test',
        dimension: 4,
        generatedAt: DateTime(2026, 4, 28, 10, 31),
      ),
      category: const Category(
        id: 1,
        name: 'Alimentação',
        description: 'Mercado',
      ),
    ),
  );
}

Future<Uint8List> _encryptedBackup({
  required String password,
  required Map<String, Object?> payload,
}) {
  return AES256Service(
    iterations: 1000,
  ).encrypt(Uint8List.fromList(utf8.encode(jsonEncode(payload))), password);
}

class _FailingReplaceReceiptRepository implements IReceiptRepository {
  const _FailingReplaceReceiptRepository(this._delegate);

  final IReceiptRepository _delegate;

  @override
  Future<Receipt> save(Receipt receipt) {
    return _delegate.save(receipt);
  }

  @override
  Future<void> update(Receipt receipt) {
    return _delegate.update(receipt);
  }

  @override
  Future<void> markCloudSynced(Iterable<int> ids) {
    return _delegate.markCloudSynced(ids);
  }

  @override
  Future<void> markAllAsNotCloudSynced() {
    return _delegate.markAllAsNotCloudSynced();
  }

  @override
  Future<void> replaceAll(List<Receipt> receipts) {
    throw StateError('Falha simulada ao substituir banco.');
  }

  @override
  Future<void> delete(int id) {
    return _delegate.delete(id);
  }

  @override
  Future<Receipt> findById(int id) {
    return _delegate.findById(id);
  }

  @override
  Future<List<Receipt>> findByFilters(ReceiptFilter filter) {
    return _delegate.findByFilters(filter);
  }

  @override
  Future<List<Receipt>> findByTerms(String text) {
    return _delegate.findByTerms(text);
  }

  @override
  Future<List<Receipt>> findSimilar(EmbeddingVector vector, int limit) {
    return _delegate.findSimilar(vector, limit);
  }

  @override
  Future<List<Receipt>> findSimilarByFilters(
    EmbeddingVector vector,
    ReceiptFilter filter,
    int limit,
  ) {
    return _delegate.findSimilarByFilters(vector, filter, limit);
  }

  @override
  Future<void> saveEmbedding(Embedding embedding) {
    return _delegate.saveEmbedding(embedding);
  }

  @override
  Future<Embedding?> findEmbeddingByReceipt(int receiptId) {
    return _delegate.findEmbeddingByReceipt(receiptId);
  }

  @override
  Stream<List<Receipt>> watchByFilters(ReceiptFilter filter) {
    return _delegate.watchByFilters(filter);
  }

  @override
  Stream<List<Receipt>> watchAll() {
    return _delegate.watchAll();
  }
}

class _BackupEnvironment {
  const _BackupEnvironment({
    required this.database,
    required this.images,
    required this.receipts,
    required this.configurations,
    required this.backups,
    required this.cloud,
    required this.backupService,
    required this.configurationService,
  });

  final AppDatabase database;
  final ImageService images;
  final ReceiptRepository receipts;
  final ConfigurationRepository configurations;
  final BackupRepository backups;
  final _FakeCloudStorage cloud;
  final BackupService backupService;
  final ConfigurationService configurationService;

  Future<void> dispose() async {
    await database.close();
  }
}

class _FakeCloudStorage implements ICloudStorage {
  final files = <Uint8List>[];
  var linked = false;
  var failUpload = false;
  var cancelLink = false;
  var linkCount = 0;

  @override
  Future<CloudAccount> linkAccount() async {
    if (cancelLink) {
      throw StateError('Autenticação cancelada.');
    }
    linkCount++;
    linked = true;
    return CloudAccount(
      email: 'usuario@fintrack.test',
      linkedAt: DateTime(2026, 5),
    );
  }

  @override
  Future<void> unlinkAccount() async {
    linked = false;
  }

  @override
  Future<bool> verifyToken() async => linked;

  @override
  Future<void> upload(List<Uint8List> files) async {
    if (!linked) {
      throw StateError('Sem vínculo.');
    }
    if (failUpload) {
      throw StateError('Falha simulada.');
    }
    this.files
      ..clear()
      ..addAll(files.map(Uint8List.fromList));
  }

  @override
  Future<List<Uint8List>> download() async {
    if (!linked) {
      throw StateError('Sem vínculo.');
    }
    return files.map(Uint8List.fromList).toList();
  }

  @override
  Future<void> deleteBackup() async {
    if (!linked) {
      throw StateError('Sem vínculo.');
    }
    files.clear();
  }
}

class _FailingTemporaryRestoreImageService implements IImageService {
  var createdTemporaryRestore = false;
  var discardAttempts = 0;

  @override
  Future<TemporaryRestoreDirectory> createTemporaryRestore() async {
    createdTemporaryRestore = true;
    return const TemporaryRestoreDirectory(
      path: 'temporary-restore',
      rollbackPath: 'rollback',
    );
  }

  @override
  Future<String> restoreToTemporaryDirectory(
    TemporaryRestoreDirectory session,
    String fileName,
    Uint8List bytes,
  ) {
    throw StateError('Falha simulada ao restaurar arquivo temporário.');
  }

  @override
  Future<void> discardTemporaryRestore(TemporaryRestoreDirectory session) {
    discardAttempts++;
    throw StateError('Falha simulada ao descartar restauração temporária.');
  }

  @override
  Future<File> capture() => throw UnimplementedError();

  @override
  Future<int> calculateUsedSpaceBytes() => throw UnimplementedError();

  @override
  Future<void> delete(String fileName) => throw UnimplementedError();

  @override
  Future<void> deleteAll() => throw UnimplementedError();

  @override
  Future<void> deleteIfManaged(String fileName) => throw UnimplementedError();

  @override
  Future<int> deleteUnreferencedFiles(Set<String> fileNames) {
    throw UnimplementedError();
  }

  @override
  Future<List<File>> importMany() => throw UnimplementedError();

  @override
  bool managedByApp(String fileName) => true;

  @override
  Future<void> promoteTemporaryRestore(TemporaryRestoreDirectory session) {
    throw UnimplementedError();
  }

  @override
  String rebuildPath(String fileName) => fileName;

  @override
  Future<void> revertTemporaryRestore(TemporaryRestoreDirectory session) {
    throw UnimplementedError();
  }

  @override
  Future<String> restoreToFileSystem(String fileName, Uint8List bytes) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveManyToDevice(List<String> fileNames) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveToDevice(String fileName, String fileType) {
    throw UnimplementedError();
  }

  @override
  Future<String> saveToFileSystem(File file) {
    throw UnimplementedError();
  }

  @override
  Future<void> share(String fileName, String fileType) {
    throw UnimplementedError();
  }

  @override
  Future<void> shareMany(List<String> fileNames) {
    throw UnimplementedError();
  }
}

class _RecordingErrorReporter implements IErrorReporter {
  final errors = <Object>[];
  final diagnostics = <String>[];

  @override
  void record(Object error, StackTrace? stackTrace) {
    errors.add(error);
  }

  @override
  void recordDiagnostic(String message) {
    diagnostics.add(message);
  }
}
