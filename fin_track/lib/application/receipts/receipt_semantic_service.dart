import 'dart:async';
import 'dart:typed_data';

import '../../domain/entities/receipt.dart';
import '../../domain/infrastructure/i_embedding_diagnostics.dart';
import '../../domain/infrastructure/i_embedding_service.dart';
import '../../domain/infrastructure/i_error_reporter.dart';
import '../../domain/infrastructure/i_semantic_index_scheduler.dart';
import '../../domain/repositories/i_receipt_repository.dart';
import '../../domain/repositories/i_semantic_index_task_repository.dart';
import '../../domain/value_objects/receipt_filter.dart';
import '../../domain/value_objects/composite_embedding_score.dart';
import '../../domain/value_objects/embedding_vector.dart';
import 'semantic/receipt_semantic_indexer.dart';

class ReceiptSemanticService {
  ReceiptSemanticService({
    required IReceiptRepository receipts,
    required ISemanticIndexTaskRepository semanticTasks,
    required IEmbeddingService embeddings,
    required ReceiptSemanticIndexer semanticIndexer,
    ISemanticIndexScheduler scheduler = const NoopSemanticIndexScheduler(),
    IEmbeddingDiagnostics? embeddingDiagnostics,
    IErrorReporter? errorReporter,
  }) : _receipts = receipts,
       _semanticTasks = semanticTasks,
       _embeddings = embeddings,
       _semanticIndexer = semanticIndexer,
       _scheduler = scheduler,
       _embeddingDiagnostics = embeddingDiagnostics,
       _errorReporter = errorReporter;

  static const double _semanticDiagnosticThreshold = 0.30;
  static const _processingRecoveryAge = Duration(minutes: 15);

  final IReceiptRepository _receipts;
  final ISemanticIndexTaskRepository _semanticTasks;
  final IEmbeddingService _embeddings;
  final ReceiptSemanticIndexer _semanticIndexer;
  final ISemanticIndexScheduler _scheduler;
  final IEmbeddingDiagnostics? _embeddingDiagnostics;
  final IErrorReporter? _errorReporter;

  Future<List<Receipt>> searchSemantically(String term) async {
    try {
      final reindex = _enqueueAndProcessPendingSemanticEmbeddings();
      await Future.any([
        reindex,
        Future<void>.delayed(const Duration(milliseconds: 10)),
      ]);
      final queryVector = await _semanticIndexer.generateQueryEmbedding(term);
      return _receipts.findSimilar(queryVector, 20);
    } catch (error, stackTrace) {
      _registerError(
        StateError('Falha na busca semântica. $error'),
        stackTrace,
      );
      return const <Receipt>[];
    }
  }

  void scheduleBackgroundSemanticReindex() {
    final reindex = _enqueueAndProcessPendingSemanticEmbeddings();
    unawaited(
      reindex.catchError((Object error, StackTrace stackTrace) {
        _registerError(
          StateError('Falha na reindexação semântica em segundo plano. $error'),
          stackTrace,
        );
        return 0;
      }),
    );
  }

  Future<void> ensureSemanticIndexUpdated() async {
    await _enqueueAndProcessPendingSemanticEmbeddings();
  }

  void scheduleBackgroundSemanticEmbedding(Receipt receipt) {
    final task = _enqueueAndProcessReceipt(receipt.id);
    unawaited(
      task.catchError((Object error, StackTrace stackTrace) {
        if (_isDatabaseClosedError(error)) {
          return;
        }
        _registerError(
          StateError('Falha na geração de embedding em segundo plano. $error'),
          stackTrace,
        );
      }),
    );
  }

  Future<void> generateAndSaveSemanticEmbedding(Receipt receipt) async {
    if (!_semanticIndexer.needsReindex(receipt)) {
      return;
    }
    await _receipts.saveEmbedding(
      await _semanticIndexer.generateEmbedding(receipt),
    );
  }

  Future<void> waitForBackgroundEmbeddings() async {
    await processPendingSemanticIndexTasks();
  }

  Future<Receipt> withUpdatedEmbedding(Receipt receipt) async {
    final embedding = await _semanticIndexer.generateEmbedding(receipt);
    return receipt.copyWith(embedding: embedding);
  }

  Future<Receipt> withUpdatedEmbeddingIfNeeded(Receipt receipt) async {
    if (receipt.id == 0) {
      return withUpdatedEmbedding(receipt);
    }

    final current = await _receipts.findById(receipt.id);
    final currentEmbedding = current.embedding;
    if (currentEmbedding != null &&
        _semanticIndexer.hasCurrentSemanticEmbedding(current) &&
        _semanticIndexer.semanticSignature(current) ==
            _semanticIndexer.semanticSignature(receipt)) {
      return receipt.copyWith(embedding: currentEmbedding);
    }

    return withUpdatedEmbedding(receipt);
  }

  Receipt withoutEmbedding(Receipt receipt) {
    return Receipt(
      id: receipt.id,
      type: receipt.type,
      expense: receipt.expense,
      fileName: receipt.fileName,
      fileType: receipt.fileType,
      fileHash: receipt.fileHash,
      fileSize: receipt.fileSize,
      extractedContent: receipt.extractedContent,
      cloudSynced: receipt.cloudSynced,
      registeredAt: receipt.registeredAt,
      extractedData: receipt.extractedData,
      category: receipt.category,
    );
  }

  Future<int> reindexPendingSemanticEmbeddings() async {
    await _enqueueOutdatedReceipts();
    await _scheduler.schedulePendingSemanticIndex();
    return processPendingSemanticIndexTasks();
  }

  Future<int> processPendingSemanticIndexTasks() async {
    await _semanticTasks.resetStaleProcessingTasks(_processingRecoveryAge);
    var total = 0;
    while (true) {
      final task = await _semanticTasks.claimNextPending();
      if (task == null) {
        break;
      }
      try {
        final receipt = await _receipts.findById(task.receiptId);
        await generateAndSaveSemanticEmbedding(receipt);
        await _semanticTasks.markCompleted(task.receiptId);
        total++;
      } catch (error, stackTrace) {
        if (error.toString().contains('Comprovante não encontrado')) {
          await _semanticTasks.markCompleted(task.receiptId);
          continue;
        }
        await _semanticTasks.markFailed(task.receiptId, error);
        _registerError(
          StateError('Falha ao indexar comprovante ${task.receiptId}. $error'),
          stackTrace,
        );
      }
    }
    if (await _semanticTasks.hasRunnableTasks()) {
      await _scheduler.schedulePendingSemanticIndex();
    } else {
      await _scheduler.cancelPendingSemanticIndex();
    }
    return total;
  }

  Future<void> _enqueueOutdatedReceipts() async {
    final receipts = await _receipts.findByFilters(const ReceiptFilter());
    final pending = <int>[];
    for (final receipt in receipts) {
      if (_semanticIndexer.needsReindex(receipt)) {
        pending.add(receipt.id);
      }
    }
    await _semanticTasks.enqueueReceipts(pending);
  }

  Future<int> _enqueueAndProcessPendingSemanticEmbeddings() async {
    await _enqueueOutdatedReceipts();
    await _scheduler.schedulePendingSemanticIndex();
    return processPendingSemanticIndexTasks();
  }

  Future<void> _enqueueAndProcessReceipt(int receiptId) async {
    await _semanticTasks.enqueueReceipt(receiptId);
    await _scheduler.schedulePendingSemanticIndex();
    await processPendingSemanticIndexTasks();
  }

  bool _isDatabaseClosedError(Object error) {
    final message = error.toString();
    return message.contains("Can't re-open a database") ||
        message.contains('database has already been closed');
  }

  Future<String> diagnoseSemanticSearch(String query, {int limit = 10}) async {
    final term = query.trim();
    if (term.isEmpty) {
      throw const FormatException('Informe uma consulta para diagnosticar.');
    }

    await ensureSemanticIndexUpdated();
    final baseQueryVector = await _embeddings.generate(term);
    final queryEmbeddingDiagnostic = _embeddingDiagnostics?.lastDiagnostic;
    final queryVector = await _semanticIndexer.generateQueryEmbedding(term);
    final probes = await _semanticProbes(term, baseQueryVector);
    final receipts = await _receipts.findByFilters(const ReceiptFilter());
    final results = <_SearchDiagnosticResult>[];
    var skippedWithoutEmbedding = 0;
    var skippedIncompatible = 0;

    for (final receipt in receipts) {
      final embedding = receipt.embedding;
      if (embedding == null) {
        skippedWithoutEmbedding++;
        continue;
      }
      final persistedVector = _deserializeVector(embedding.vector);
      if (persistedVector.length != queryVector.vector.length ||
          embedding.dimension != queryVector.dimension) {
        skippedIncompatible++;
        continue;
      }

      final score = CompositeEmbeddingScore.calculate(
        query: queryVector,
        persisted: EmbeddingVector(
          vector: persistedVector,
          model: embedding.model,
          dimension: embedding.dimension,
        ),
      );
      CompositeEmbeddingScore? currentTextScore;
      try {
        final currentEmbedding = await _semanticIndexer.generateEmbedding(
          receipt,
        );
        final currentTextVector = EmbeddingVector(
          vector: _deserializeVector(currentEmbedding.vector),
          model: currentEmbedding.model,
          dimension: currentEmbedding.dimension,
        );
        if (currentTextVector.dimension == queryVector.dimension &&
            currentTextVector.vector.length == queryVector.vector.length) {
          currentTextScore = CompositeEmbeddingScore.calculate(
            query: queryVector,
            persisted: currentTextVector,
          );
        }
      } catch (error, stackTrace) {
        _registerError(
          StateError(
            'Falha ao recalcular score semântico atual para diagnóstico. $error',
          ),
          stackTrace,
        );
      }
      results.add(
        _SearchDiagnosticResult(
          receipt: receipt,
          persistedScore: score,
          currentTextScore: currentTextScore,
        ),
      );
    }

    results.sort(
      (a, b) =>
          b.persistedScore.finalScore.compareTo(a.persistedScore.finalScore),
    );
    final top = results.take(limit.clamp(1, 50)).toList();
    final lines = <String>[
      'Semantic search diagnostic',
      'query="$term"',
      'queryModel=${baseQueryVector.model}',
      'queryDimension=${baseQueryVector.dimension}',
      'compositeQueryModel=${queryVector.model}',
      'compositeQueryDimension=${queryVector.dimension}',
      'totalReceipts=${receipts.length}',
      'compared=${results.length}',
      'skippedWithoutEmbedding=$skippedWithoutEmbedding',
      'skippedIncompatible=$skippedIncompatible',
      'currentSearchThreshold=$_semanticDiagnosticThreshold',
      'note=this diagnostic shows the highest scores even when they are not included in the search',
      if (queryEmbeddingDiagnostic != null)
        'queryEmbeddingDiagnostic=$queryEmbeddingDiagnostic',
      'probes:',
      ...probes.map(
        (probe) => '- ${probe.label}=${probe.score.toStringAsFixed(6)}',
      ),
      for (var i = 0; i < top.length; i++)
        _searchDiagnosticLine(position: i + 1, result: top[i]),
    ];
    final diagnostic = lines.join('\n');
    _errorReporter?.recordDiagnostic(diagnostic);
    return diagnostic;
  }

  String _searchDiagnosticLine({
    required int position,
    required _SearchDiagnosticResult result,
  }) {
    final receipt = result.receipt;
    final data = receipt.extractedData;
    final category = receipt.category?.name ?? '';
    final semanticText = _semanticIndexer
        .semanticText(receipt)
        .replaceAll('\n', ' / ');
    return [
      '$position.',
      'persistedScore=${result.persistedScore.finalScore.toStringAsFixed(6)}',
      if (result.currentTextScore != null)
        'currentTextScore=${result.currentTextScore!.finalScore.toStringAsFixed(6)}',
      'fullScore=${result.persistedScore.fullCosineScore.toStringAsFixed(6)}',
      if (result.persistedScore.usedFieldScore)
        'fields=establishment:${result.persistedScore.establishment.toStringAsFixed(6)} categories:${result.persistedScore.categories.toStringAsFixed(6)} context:${result.persistedScore.context.toStringAsFixed(6)} payment:${result.persistedScore.payment.toStringAsFixed(6)}',
      'wouldEnterSearch=${result.persistedScore.finalScore >= _semanticDiagnosticThreshold}',
      'id=${receipt.id}',
      'type=${receipt.type.name}',
      'expense=${receipt.expense}',
      'establishment="${data?.establishment ?? ''}"',
      'categories="${category.isEmpty ? '-' : category}"',
      'model="${receipt.embedding?.model ?? '-'}"',
      'dimension=${receipt.embedding?.dimension ?? 0}',
      'text="${_limitDiagnostic(semanticText, 260)}"',
    ].join(' ');
  }

  Future<List<_SearchDiagnosticProbe>> _semanticProbes(
    String term,
    EmbeddingVector queryVector,
  ) async {
    final texts = <String>[
      term,
      'Saúde',
      'Farmácia',
      'Remédio',
      'Medicamento',
      'Mercado',
      'Alimentação',
      'Gasolina',
      'Posto',
      'Combustível',
    ];
    final probes = <_SearchDiagnosticProbe>[];
    for (final text in texts) {
      try {
        final vector = await _embeddings.generate(text);
        if (vector.dimension != queryVector.dimension ||
            vector.vector.length != queryVector.vector.length) {
          continue;
        }
        probes.add(
          _SearchDiagnosticProbe(
            label: text,
            score: queryVector.cosineSimilarity(vector),
          ),
        );
      } catch (error, stackTrace) {
        _registerError(
          StateError('Falha ao gerar probe de diagnóstico semântico. $error'),
          stackTrace,
        );
      }
    }
    return probes;
  }

  void _registerError(Object error, StackTrace? stackTrace) {
    _errorReporter?.record(error, stackTrace);
  }

  List<double> _deserializeVector(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final values = <double>[];
    for (var i = 0; i + 8 <= bytes.length; i += 8) {
      values.add(data.getFloat64(i, Endian.little));
    }
    return values;
  }

  String _limitDiagnostic(String text, int limit) {
    if (text.length <= limit) {
      return text;
    }
    return '${text.substring(0, limit)}...';
  }
}

class _SearchDiagnosticResult {
  const _SearchDiagnosticResult({
    required this.receipt,
    required this.persistedScore,
    required this.currentTextScore,
  });

  final Receipt receipt;
  final CompositeEmbeddingScore persistedScore;
  final CompositeEmbeddingScore? currentTextScore;
}

class _SearchDiagnosticProbe {
  const _SearchDiagnosticProbe({required this.label, required this.score});

  final String label;
  final double score;
}
