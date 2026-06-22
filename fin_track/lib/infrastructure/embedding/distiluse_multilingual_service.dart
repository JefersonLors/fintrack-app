import 'dart:async';

import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

import '../../domain/infrastructure/i_embedding_diagnostics.dart';
import '../../domain/infrastructure/i_embedding_service.dart';
import '../../domain/infrastructure/i_error_reporter.dart';
import '../../domain/value_objects/embedding_vector.dart';
import '../diagnostics/fin_track_error_log.dart';
import 'distiluse_embedding_math.dart';
import 'distiluse_tokenizer.dart';

// coverage:ignore-start
class DistilUseMultilingualService
    implements IEmbeddingService, IEmbeddingDiagnostics {
  DistilUseMultilingualService({
    IErrorReporter errorReporter = const FinTrackErrorReporter(),
  }) : _errorReporter = errorReporter;

  static const int _maxTokens = 128;
  static const String _modelPath =
      'assets/models/distiluse_base_multilingual_cased_v2/model_qint8_arm64.onnx';
  static const String _vocabPath =
      'assets/models/distiluse_base_multilingual_cased_v2/vocab.txt';
  static const String _densePath =
      'assets/models/distiluse_base_multilingual_cased_v2/2_Dense/model.safetensors';
  static const String _model = 'distiluse-base-multilingual-cased-v2-qint8';

  OrtSession? _session;
  Map<String, int>? _vocab;
  DistilUseDenseLayer? _dense;
  String? _lastDiagnostic;
  Future<void> _inferenceQueue = Future.value();
  final IErrorReporter _errorReporter;
  final _outputExtractor = const DistilUseEmbeddingOutputExtractor();
  final _vectorMath = const DistilUseVectorMath();
  final _denseProjector = const DistilUseDenseProjector();
  final _vocabParser = const DistilUseVocabParser();
  final _inputMapper = const DistilUseInputMapper();

  @override
  String? get lastDiagnostic => _lastDiagnostic;

  Future<void> _initialize() async {
    if (_session != null && _vocab != null && _dense != null) {
      return;
    }

    OrtEnv.instance.init();
    final options = OrtSessionOptions()
      ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);
    final modelBytes = await _loadModelBytes();
    _session = OrtSession.fromBuffer(modelBytes, options);
    _vocab = await _loadVocab();
    _dense = await _loadDense();
  }

  Future<Uint8List> _loadModelBytes() async {
    final rawModel = await rootBundle.load(_modelPath);
    final bytes = distilUseAssetBytes(rawModel);
    if (distilUseAssetLooksLikeGitLfsPointer(bytes)) {
      throw StateError(
        'Asset ONNX DistilUSE não contém o modelo real. '
        'O arquivo parece ser um ponteiro Git LFS.',
      );
    }
    if (bytes.lengthInBytes < 1024 * 1024) {
      throw StateError(
        'Asset ONNX DistilUSE inválido ou truncado '
        '(${bytes.lengthInBytes} bytes).',
      );
    }
    return bytes;
  }

  Future<Map<String, int>> _loadVocab() async {
    final content = await rootBundle.loadString(_vocabPath);
    return _vocabParser.parse(content);
  }

  @override
  Future<EmbeddingVector> generate(String text) {
    return _runSequentially(() => _generateInternal(text));
  }

  Future<T> _runSequentially<T>(Future<T> Function() action) async {
    final previous = _inferenceQueue.catchError((_) {});
    final current = Completer<void>();
    _inferenceQueue = current.future;
    await previous;
    try {
      return await action();
    } finally {
      current.complete();
    }
  }

  Future<EmbeddingVector> _generateInternal(String text) async {
    try {
      await _initialize();
      final session = _session!;
      final encoding = DistilUseTokenizer(
        vocab: _vocab!,
        maxTokens: _maxTokens,
      ).encode(text);
      final inputIds = OrtValueTensor.createTensorWithDataList(
        [encoding.inputIds],
        [1, _maxTokens],
      );
      final attentionMask = OrtValueTensor.createTensorWithDataList(
        [encoding.attentionMask],
        [1, _maxTokens],
      );
      final tokenTypeIds = OrtValueTensor.createTensorWithDataList(
        [encoding.tokenTypeIds],
        [1, _maxTokens],
      );
      final inputs = _mapInputs(
        session: session,
        inputIds: inputIds,
        attentionMask: attentionMask,
        tokenTypeIds: tokenTypeIds,
      );
      final runOptions = OrtRunOptions();
      List<OrtValue?> outputs = const [];
      try {
        outputs = session.run(runOptions, inputs);
        final vector = _outputExtractor.extract(
          outputNames: session.outputNames,
          outputs: outputs.map((output) => output?.value).toList(),
          attentionMask: encoding.attentionMask,
        );
        final finalVector = _denseProjector.applyIfNeeded(vector, _dense);
        final normalized = _vectorMath.normalize(finalVector);
        _lastDiagnostic = [
          'text="${_vectorMath.limitDiagnosticText(text, 120)}"',
          'inputNames=${session.inputNames.join('|')}',
          'outputNames=${session.outputNames.join('|')}',
          'activeTokens=${encoding.attentionMask.where((item) => item == 1).length}',
          'tokens=${encoding.tokens.take(24).join(' ')}',
          'inputIds=${encoding.inputIds.take(24).join(' ')}',
          'baseVectorDim=${vector.length}',
          'finalVectorDim=${normalized.length}',
          'denseApplied=${vector.length == 768 && normalized.length == 512}',
          'finalNorm=${_vectorMath.norm(normalized).toStringAsFixed(6)}',
        ].join(' ');
        return EmbeddingVector(
          vector: normalized,
          model: _model,
          dimension: normalized.length,
        );
      } finally {
        runOptions.release();
        for (final output in outputs) {
          output?.release();
        }
        inputIds.release();
        attentionMask.release();
        tokenTypeIds.release();
      }
    } catch (error, stackTrace) {
      _errorReporter.record(
        StateError('Falha no embedding ONNX DistilUSE. $error'),
        stackTrace,
      );
      rethrow;
    }
  }

  Future<DistilUseDenseLayer> _loadDense() async {
    final raw = await rootBundle.load(_densePath);
    return const DistilUseSafetensorsDenseReader().read(
      distilUseAssetBytes(raw),
    );
  }

  Map<String, OrtValue> _mapInputs({
    required OrtSession session,
    required OrtValueTensor inputIds,
    required OrtValueTensor attentionMask,
    required OrtValueTensor tokenTypeIds,
  }) {
    return _inputMapper.map<OrtValue>(
      inputNames: session.inputNames,
      inputIds: inputIds,
      attentionMask: attentionMask,
      tokenTypeIds: tokenTypeIds,
    );
  }
}

Uint8List distilUseAssetBytes(ByteData data) {
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

bool distilUseAssetLooksLikeGitLfsPointer(Uint8List bytes) {
  const signature = 'version https://git-lfs.github.com/spec/v1';
  if (bytes.length < signature.length) {
    return false;
  }
  for (var index = 0; index < signature.length; index++) {
    if (bytes[index] != signature.codeUnitAt(index)) {
      return false;
    }
  }
  return true;
}

// coverage:ignore-end
