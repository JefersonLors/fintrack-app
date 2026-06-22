part of 'receipt_service_test.dart';

Future<File> _receiptFixture(String name, String content) async {
  final file = File('${Directory.systemTemp.path}/fin_track_test_$name');
  await file.writeAsString(content);
  return file;
}

Future<void> _saveWithControlledEmbedding(
  ReceiptRepository repository, {
  required String fileId,
  required Embedding embedding,
}) async {
  final saved = await repository.save(
    Receipt(
      id: 0,
      type: ReceiptType.receipt,
      expense: true,
      fileName: '$fileId.txt',
      fileType: 'text/plain',
      registeredAt: DateTime(2026, 5, 9),
    ),
  );
  await repository.saveEmbedding(embedding.copyWith(receiptId: saved.id));
}

EmbeddingVector _controlledSemanticQuery() {
  return const EmbeddingVector(
    vector: [1, 0, 1, 0],
    model: 'fake:field-composite-hybrid',
    dimension: 4,
  );
}

Embedding _embeddingWithSemanticScore(double score) {
  return Embedding(
    id: 0,
    receiptId: 0,
    vector: _serializeVector([score, _complementaryNorm(score), 0, 1]),
    model: 'fake:field-composite-hybrid',
    dimension: 4,
    generatedAt: DateTime(2026, 5, 9),
  );
}

double _complementaryNorm(double score) {
  return sqrt(1 - (score * score));
}

Uint8List _serializeVector(List<double> vector) {
  final data = ByteData(vector.length * 8);
  for (var i = 0; i < vector.length; i++) {
    data.setFloat64(i * 8, vector[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

FinTrackDependencies _dependencies() {
  return FinTrackDependencies.local(
    embeddings: _TestEmbeddingService(),
    cnpjLookup: const _NoopCnpjLookupService(),
  );
}

Future<Receipt> _fetchAfterBackgroundEmbeddings(
  FinTrackDependencies dependencies,
  int receiptId,
) async {
  await (dependencies.receiptService as ReceiptService)
      .waitForBackgroundEmbeddings();
  return dependencies.receiptService.findById(receiptId);
}

class _NoopCnpjLookupService implements ICnpjLookupService {
  const _NoopCnpjLookupService();

  @override
  Future<CompanyData?> lookup(String cnpj) async => null;
}

class _FakeVisualCodeService implements IVisualCodeService {
  const _FakeVisualCodeService(this.codigos);

  final List<String> codigos;

  @override
  Future<List<String>> readCodes(File file) async => codigos;
}

class _FakeFiscalDocumentLookupService implements IFiscalDocumentLookupService {
  const _FakeFiscalDocumentLookupService();

  @override
  Future<FiscalDocumentData?> lookup({
    String? urlQrCode,
    String? accessKey,
  }) async {
    if (urlQrCode == null || !urlQrCode.contains('sefaz.ba.gov.br')) {
      return null;
    }
    return FiscalDocumentData(
      amount: 150,
      issuedAt: DateTime(2026, 4, 2, 17, 32, 32),
      establishment: 'POSTO MATARIPE BONOCO',
      issuerCnpj: '55986560000159',
      accessKey: '29260455986560000159650210000156761007188082',
      lookupUrl: urlQrCode,
      documentNumber: '15676',
      documentSeries: '21',
      documentState: 'BA',
      items: const ['GASOLINA COMUM'],
    );
  }
}

class _NeverFiscalDocumentLookupService
    implements IFiscalDocumentLookupService {
  const _NeverFiscalDocumentLookupService();

  @override
  Future<FiscalDocumentData?> lookup({String? urlQrCode, String? accessKey}) {
    return Completer<FiscalDocumentData?>().future;
  }
}

class _FakeLocalCnpjLookupService
    implements ICnpjLookupService, ILocalCnpjLookupService {
  const _FakeLocalCnpjLookupService();

  @override
  Future<CompanyData?> lookup(String cnpj) => lookupLocal(cnpj);

  @override
  Future<CompanyData?> lookupLocal(String cnpj) async {
    return const CompanyData(
      cnpj: '55986560000159',
      legalName: 'MERCADO CENTRAL LTDA',
      tradeName: 'Mercado Fonte API',
      fiscalCnaeDescription: 'Comercio varejista de mercadorias em geral',
      city: 'SALVADOR',
      state: 'BA',
    );
  }
}

class _FakeHealthCnaeLookupService
    implements ICnpjLookupService, ILocalCnpjLookupService {
  const _FakeHealthCnaeLookupService();

  @override
  Future<CompanyData?> lookup(String cnpj) => lookupLocal(cnpj);

  @override
  Future<CompanyData?> lookupLocal(String cnpj) async {
    return const CompanyData(
      cnpj: '55986560000159',
      legalName: 'EMPRESA GENERICA LTDA',
      tradeName: 'Empresa Generica',
      fiscalCnaeDescription:
          'Saúde medicamentos consultas comercio varejista farmacêutico',
      city: 'SALVADOR',
      state: 'BA',
    );
  }
}

class _NeverCnpjLookupService implements ICnpjLookupService {
  const _NeverCnpjLookupService();

  @override
  Future<CompanyData?> lookup(String cnpj) {
    return Completer<CompanyData?>().future;
  }
}

class _TestEmbeddingService implements IEmbeddingService {
  static const dimension = 32;

  @override
  Future<EmbeddingVector> generate(String text) async {
    final vector = List<double>.filled(dimension, 0);
    final terms = text
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty);

    for (final term in terms) {
      var hash = 2166136261;
      for (final unit in term.codeUnits) {
        hash ^= unit;
        hash = (hash * 16777619) & 0xffffffff;
      }
      vector[hash % vector.length] += 1;
    }

    return EmbeddingVector(
      vector: vector,
      model: 'test-lexical-no-canonical',
      dimension: dimension,
    );
  }
}

class _CountingEmbeddingService extends _TestEmbeddingService {
  final calls = <String, int>{};

  int get totalCalls => calls.values.fold(0, (total, item) => total + item);

  @override
  Future<EmbeddingVector> generate(String text) {
    calls[text] = (calls[text] ?? 0) + 1;
    return super.generate(text);
  }
}

class _DiagnosticEmbeddingService extends _TestEmbeddingService
    implements IEmbeddingDiagnostics {
  @override
  String? get lastDiagnostic => 'model=diagnostico';

  @override
  Future<EmbeddingVector> generate(String text) async {
    return const EmbeddingVector(
      vector: [1, 0, 1, 0],
      model: 'diagnostic-base',
      dimension: 4,
    );
  }
}

class _StaticEmbeddingDiagnostics implements IEmbeddingDiagnostics {
  const _StaticEmbeddingDiagnostics(this.lastDiagnostic);

  @override
  final String? lastDiagnostic;
}

class _FailingEmbeddingService implements IEmbeddingService {
  @override
  Future<EmbeddingVector> generate(String text) {
    throw StateError('Falha simulada ao gerar embedding.');
  }
}

class _RecordingEmbeddingService implements IEmbeddingService {
  String? lastText;

  @override
  Future<EmbeddingVector> generate(String text) async {
    lastText = text;
    return EmbeddingVector(
      vector: List<double>.filled(4, 0.25),
      model: 'fake',
      dimension: 4,
    );
  }
}

class _PendingReindexSemanticIndexer extends ReceiptSemanticIndexer {
  _PendingReindexSemanticIndexer()
    : super(embeddings: _RecordingEmbeddingService());

  final reindexacaoIniciada = Completer<void>();

  @override
  bool needsReindex(Receipt receipt) => true;

  @override
  Future<Embedding> generateEmbedding(Receipt receipt) async {
    if (!reindexacaoIniciada.isCompleted) {
      reindexacaoIniciada.complete();
    }
    return Completer<Embedding>().future;
  }

  @override
  Future<EmbeddingVector> generateQueryEmbedding(String query) async {
    return const EmbeddingVector(
      vector: [1, 0, 1, 0],
      model: 'fake:field-composite',
      dimension: 4,
    );
  }
}

class _DiagnosticSemanticIndexer extends ReceiptSemanticIndexer {
  _DiagnosticSemanticIndexer()
    : super(embeddings: _DiagnosticEmbeddingService());

  @override
  bool needsReindex(Receipt receipt) => false;

  @override
  Future<EmbeddingVector> generateQueryEmbedding(String query) async {
    return const EmbeddingVector(
      vector: [1, 0, 1, 0],
      model: 'fake:field-composite',
      dimension: 4,
    );
  }

  @override
  Future<Embedding> generateEmbedding(Receipt receipt) async {
    return Embedding(
      id: 0,
      receiptId: receipt.id,
      vector: _serializeVector([1, 0, 1, 0]),
      model: 'fake:field-composite',
      dimension: 4,
      generatedAt: DateTime(2026, 5, 20),
    );
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
