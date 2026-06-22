import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

class DistilUseEmbeddingOutputExtractor {
  const DistilUseEmbeddingOutputExtractor();

  List<double> extract({
    required List<String> outputNames,
    required List<Object?> outputs,
    required List<int> attentionMask,
  }) {
    final candidates = <DistilUseEmbeddingCandidate>[];
    for (var i = 0; i < outputs.length; i++) {
      final value = outputs[i];
      if (value == null) {
        continue;
      }
      final name = i < outputNames.length ? outputNames[i] : 'output_$i';
      final vector = outputVector(value, attentionMask);
      if (vector != null && vector.length >= 128) {
        candidates.add(DistilUseEmbeddingCandidate(name: name, vector: vector));
      }
    }

    if (candidates.isEmpty) {
      throw FormatException(
        'Nenhuma saída ONNX compatível com embedding. Saídas: $outputNames.',
      );
    }

    candidates.sort((a, b) {
      final aSentence = outputNamePriority(a.name);
      final bSentence = outputNamePriority(b.name);
      if (aSentence != bSentence) {
        return bSentence.compareTo(aSentence);
      }
      return a.vector.length.compareTo(b.vector.length);
    });
    return candidates.first.vector;
  }

  int outputNamePriority(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('sentence') ||
        normalized.contains('embedding') ||
        normalized.contains('pool')) {
      return 2;
    }
    if (normalized.contains('last_hidden') || normalized.contains('token')) {
      return 1;
    }
    return 0;
  }

  List<double>? outputVector(Object? value, List<int> attentionMask) {
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is num) {
        return value.map((item) => (item as num).toDouble()).toList();
      }
      if (first is List && first.isNotEmpty) {
        final second = first.first;
        if (second is num) {
          return first.map((item) => (item as num).toDouble()).toList();
        }
        if (second is List && second.isNotEmpty && second.first is num) {
          return meanPooling(first, attentionMask);
        }
      }
    }
    return null;
  }

  List<double> meanPooling(List<dynamic> tokenEmbeddings, List<int> mask) {
    final firstRow = tokenEmbeddings.cast<dynamic>().firstWhere(
      (item) => item is List && item.isNotEmpty,
      orElse: () => const <dynamic>[],
    );
    if (firstRow is! List || firstRow.isEmpty) {
      return const <double>[];
    }
    final dimension = firstRow.length;
    final accumulated = List<double>.filled(dimension, 0);
    var total = 0;

    for (var token = 0; token < tokenEmbeddings.length; token++) {
      if (token >= mask.length || mask[token] == 0) {
        continue;
      }
      final values = tokenEmbeddings[token];
      if (values is! List || values.length != dimension) {
        continue;
      }
      total++;
      for (var dim = 0; dim < dimension; dim++) {
        accumulated[dim] += (values[dim] as num).toDouble();
      }
    }

    if (total == 0) {
      return accumulated;
    }
    return accumulated.map((amount) => amount / total).toList();
  }
}

class DistilUseVectorMath {
  const DistilUseVectorMath();

  List<double> normalize(List<double> vector) {
    final currentNorm = norm(vector);
    if (currentNorm == 0) {
      return vector;
    }
    return vector.map((amount) => amount / currentNorm).toList(growable: false);
  }

  double norm(List<double> vector) {
    var sum = 0.0;
    for (final amount in vector) {
      sum += amount * amount;
    }
    return math.sqrt(sum);
  }

  String limitDiagnosticText(String text, int limit) {
    final normalized = text.replaceAll('\n', ' ');
    if (normalized.length <= limit) {
      return normalized;
    }
    return '${normalized.substring(0, limit)}...';
  }
}

class DistilUseDenseProjector {
  const DistilUseDenseProjector();

  List<double> applyIfNeeded(List<double> vector, DistilUseDenseLayer? dense) {
    if (vector.length != 768) {
      return vector;
    }
    if (dense == null) {
      return vector;
    }
    final outputVector = List<double>.filled(dense.outputSize, 0);
    for (var output = 0; output < dense.outputSize; output++) {
      var amount = dense.bias[output];
      final weightOffset = output * dense.inputSize;
      for (var input = 0; input < dense.inputSize; input++) {
        amount += vector[input] * dense.weight[weightOffset + input];
      }
      outputVector[output] = tanh(amount);
    }
    return outputVector;
  }

  double tanh(double amount) {
    if (amount > 20) {
      return 1;
    }
    if (amount < -20) {
      return -1;
    }
    final exp2x = math.exp(2 * amount);
    return (exp2x - 1) / (exp2x + 1);
  }
}

class DistilUseSafetensorsDenseReader {
  const DistilUseSafetensorsDenseReader();

  DistilUseDenseLayer read(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final headerLength = data.getUint64(0, Endian.little);
    final headerStart = 8;
    final headerEnd = headerStart + headerLength;
    final header =
        jsonDecode(utf8.decode(bytes.sublist(headerStart, headerEnd)))
            as Map<String, dynamic>;

    final bias = readTensorFloat32(
      data: data,
      baseOffset: headerEnd,
      metadata: header['linear.bias'] as Map<String, dynamic>,
    );
    final weight = readTensorFloat32(
      data: data,
      baseOffset: headerEnd,
      metadata: header['linear.weight'] as Map<String, dynamic>,
    );
    return DistilUseDenseLayer(
      inputSize: 768,
      outputSize: 512,
      weight: weight,
      bias: bias,
    );
  }

  List<double> readTensorFloat32({
    required ByteData data,
    required int baseOffset,
    required Map<String, dynamic> metadata,
  }) {
    if (metadata['dtype'] != 'F32') {
      throw FormatException('Tensor Dense em formato inesperado: $metadata');
    }
    final offsets = (metadata['data_offsets'] as List).cast<int>();
    final start = baseOffset + offsets[0];
    final end = baseOffset + offsets[1];
    final values = <double>[];
    for (var offset = start; offset + 4 <= end; offset += 4) {
      values.add(data.getFloat32(offset, Endian.little));
    }
    return values;
  }
}

class DistilUseVocabParser {
  const DistilUseVocabParser();

  Map<String, int> parse(String content) {
    final vocab = <String, int>{};
    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final token = lines[i].trim();
      if (token.isNotEmpty) {
        vocab[token] = i;
      }
    }
    return vocab;
  }
}

class DistilUseInputMapper {
  const DistilUseInputMapper();

  Map<String, T> map<T>({
    required List<String> inputNames,
    required T inputIds,
    required T attentionMask,
    required T tokenTypeIds,
  }) {
    final inputs = <String, T>{};
    for (var index = 0; index < inputNames.length; index++) {
      final name = inputNames[index];
      final normalized = name.toLowerCase();
      if (normalized.contains('input_ids') ||
          normalized == 'ids' ||
          normalized.contains('word')) {
        inputs[name] = inputIds;
      } else if (normalized.contains('attention') ||
          normalized.contains('mask')) {
        inputs[name] = attentionMask;
      } else if (normalized.contains('token_type') ||
          normalized.contains('segment') ||
          normalized.contains('type')) {
        inputs[name] = tokenTypeIds;
      } else if (index == 0) {
        inputs[name] = inputIds;
      } else if (index == 1) {
        inputs[name] = attentionMask;
      } else {
        inputs[name] = tokenTypeIds;
      }
    }
    return inputs;
  }
}

class DistilUseEmbeddingCandidate {
  const DistilUseEmbeddingCandidate({required this.name, required this.vector});

  final String name;
  final List<double> vector;
}

class DistilUseDenseLayer {
  const DistilUseDenseLayer({
    required this.inputSize,
    required this.outputSize,
    required this.weight,
    required this.bias,
  });

  final int inputSize;
  final int outputSize;
  final List<double> weight;
  final List<double> bias;
}
