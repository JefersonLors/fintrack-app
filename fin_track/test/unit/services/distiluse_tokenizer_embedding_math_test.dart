import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fin_track/infrastructure/embedding/distiluse_embedding_math.dart';
import 'package:fin_track/infrastructure/embedding/distiluse_multilingual_service.dart';
import 'package:fin_track/infrastructure/embedding/distiluse_tokenizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DistilUseTokenizer', () {
    const vocab = {
      '[PAD]': 0,
      '[UNK]': 100,
      '[CLS]': 101,
      '[SEP]': 102,
      'ola': 200,
      ',': 201,
      'mun': 202,
      '##do': 203,
      '!': 204,
    };
    const tokenizer = DistilUseTokenizer(vocab: vocab, maxTokens: 8);

    test('tokenizes text when punctuation is attached to words', () {
      expect(tokenizer.basicTokenize('ola, mundo!'), [
        'ola',
        ',',
        'mundo',
        '!',
      ]);
    });

    test('applies wordpiece when tokens exist or are unknown', () {
      expect(tokenizer.wordPiece('ola', unk: 100, limit: 4).ids, [200]);
      expect(tokenizer.wordPiece('mundo', unk: 100, limit: 4).tokens, [
        'mun',
        '##do',
      ]);
      expect(tokenizer.wordPiece('desconhecido', unk: 100, limit: 4).tokens, [
        '[UNK]',
      ]);
      expect(tokenizer.wordPiece('ola', unk: 100, limit: 0).ids, isEmpty);
    });

    test('encodes input when cls sep padding and mask are needed', () {
      final encoding = tokenizer.encode('ola, mundo!');

      expect(encoding.tokens, [
        '[CLS]',
        'ola',
        ',',
        'mun',
        '##do',
        '!',
        '[SEP]',
      ]);
      expect(encoding.inputIds, [101, 200, 201, 202, 203, 204, 102, 0]);
      expect(encoding.attentionMask, [1, 1, 1, 1, 1, 1, 1, 0]);
      expect(encoding.tokenTypeIds, List<int>.filled(8, 0));
    });
  });

  group('DistilUseVocabParser and input mapper', () {
    const parser = DistilUseVocabParser();
    const mapper = DistilUseInputMapper();

    test('parser preserves original index and ignores empty lines', () {
      expect(parser.parse('[PAD]\n\n [UNK] \ntexto'), {
        '[PAD]': 0,
        '[UNK]': 2,
        'texto': 3,
      });
    });

    test('mapper recognizes semantic names and uses order fallback', () {
      final semantic = mapper.map<String>(
        inputNames: const ['attention_mask', 'input_ids', 'token_type_ids'],
        inputIds: 'ids',
        attentionMask: 'mask',
        tokenTypeIds: 'types',
      );
      expect(semantic, {
        'attention_mask': 'mask',
        'input_ids': 'ids',
        'token_type_ids': 'types',
      });

      final fallback = mapper.map<String>(
        inputNames: const ['x', 'y', 'z'],
        inputIds: 'ids',
        attentionMask: 'mask',
        tokenTypeIds: 'types',
      );
      expect(fallback, {'x': 'ids', 'y': 'mask', 'z': 'types'});
    });
  });

  group('DistilUseEmbeddingOutputExtractor', () {
    const extractor = DistilUseEmbeddingOutputExtractor();

    test('extracts vector when sentence outputVector is available', () {
      final result = extractor.extract(
        outputNames: ['last_hidden_state', 'sentence_embedding'],
        outputs: [
          List<double>.generate(128, (index) => index.toDouble()),
          List<double>.generate(129, (index) => (index + 1).toDouble()),
        ],
        attentionMask: const [1, 1],
      );

      expect(result.length, 129);
      expect(result.first, 1);
      expect(extractor.outputNamePriority('pooler_output'), 2);
      expect(extractor.outputNamePriority('last_hidden_state'), 1);
      expect(extractor.outputNamePriority('out'), 0);
    });

    test('does mean pooling when mask ignores padding', () {
      final pooled = extractor.meanPooling(
        [
          [1, 3],
          [3, 5],
          [100, 100],
        ],
        const [1, 1, 0],
      );

      expect(pooled, [2, 4]);
      expect(
        extractor.outputVector(
          [
            [1, 2, 3],
          ],
          const [1],
        ),
        [1, 2, 3],
      );
      expect(
        extractor.outputVector(
          [
            [
              [1, 1],
              [3, 3],
            ],
          ],
          const [1, 1],
        ),
        [2, 2],
      );
      expect(extractor.outputVector('invalid', const [1]), isNull);
      expect(extractor.meanPooling(const [], const []), isEmpty);
    });

    test('fails when no outputVector looks like embedding', () {
      expect(
        () => extractor.extract(
          outputNames: const ['curta'],
          outputs: const [
            [1, 2, 3],
          ],
          attentionMask: const [1],
        ),
        throwsFormatException,
      );
    });
  });

  group('DistilUseVectorMath and dense', () {
    const math = DistilUseVectorMath();
    const projector = DistilUseDenseProjector();

    test('normalizes vector when calculating norm and diagnostic', () {
      expect(math.normalize(const [0, 0]), [0, 0]);
      expect(math.normalize(const [3, 4]), [0.6, 0.8]);
      expect(math.norm(const [3, 4]), 5);
      expect(math.limitDiagnosticText('linha\nquebra', 50), 'linha quebra');
      expect(math.limitDiagnosticText('abcdef', 3), 'abc...');
    });

    test('applies dense when vector has expected dimension', () {
      expect(projector.applyIfNeeded(const [1, 2], null), [1, 2]);

      final vector = List<double>.filled(768, 0)..[0] = 1;
      final dense = DistilUseDenseLayer(
        inputSize: 768,
        outputSize: 2,
        weight: [
          0.5,
          ...List<double>.filled(767, 0),
          -0.5,
          ...List<double>.filled(767, 0),
        ],
        bias: const [0, 0],
      );
      final projected = projector.applyIfNeeded(vector, dense);

      expect(projected[0], closeTo(projector.tanh(0.5), 0.000001));
      expect(projected[1], closeTo(projector.tanh(-0.5), 0.000001));
      expect(projector.tanh(21), 1);
      expect(projector.tanh(-21), -1);
    });
  });

  group('DistilUseSafetensorsDenseReader', () {
    const reader = DistilUseSafetensorsDenseReader();

    test('reads tensor when safetensors file is minimal', () {
      final bytes = _safetensorsBytes(
        bias: const [1, 2],
        weight: const [3, 4, 5, 6],
      );
      final layer = reader.read(bytes);

      expect(layer.inputSize, 768);
      expect(layer.outputSize, 512);
      expect(layer.bias, [1, 2]);
      expect(layer.weight, [3, 4, 5, 6]);
    });

    test('rejects tensor when dtype is unexpected', () {
      final data = ByteData(8);

      expect(
        () => reader.readTensorFloat32(
          data: data,
          baseOffset: 0,
          metadata: const {
            'dtype': 'I64',
            'data_offsets': [0, 8],
          },
        ),
        throwsFormatException,
      );
    });
  });

  group('DistilUse asset loading', () {
    test('extracts only the ByteData window used by Flutter assets', () {
      final backing = Uint8List.fromList([9, 8, 1, 2, 3, 7]);
      final window = ByteData.sublistView(backing, 2, 5);

      expect(distilUseAssetBytes(window), [1, 2, 3]);
    });

    test(
      'model asset is the real ONNX file instead of a Git LFS pointer',
      () async {
        final model = File(
          'assets/models/distiluse_base_multilingual_cased_v2/model_qint8_arm64.onnx',
        );
        final prefix = await model
            .openRead(0, 128)
            .fold<BytesBuilder>(
              BytesBuilder(copy: false),
              (builder, chunk) => builder..add(chunk),
            );

        expect(model.lengthSync(), greaterThan(1024 * 1024));
        expect(
          distilUseAssetLooksLikeGitLfsPointer(prefix.takeBytes()),
          isFalse,
        );
      },
    );
  });
}

Uint8List _safetensorsBytes({
  required List<double> bias,
  required List<double> weight,
}) {
  final tensorBytesLength = (bias.length + weight.length) * 4;
  final biasEnd = bias.length * 4;
  final header = jsonEncode({
    'linear.bias': {
      'dtype': 'F32',
      'shape': [bias.length],
      'data_offsets': [0, biasEnd],
    },
    'linear.weight': {
      'dtype': 'F32',
      'shape': [weight.length],
      'data_offsets': [biasEnd, tensorBytesLength],
    },
  });
  final headerBytes = utf8.encode(header);
  final bytes = Uint8List(8 + headerBytes.length + tensorBytesLength);
  final data = ByteData.sublistView(bytes);
  data.setUint64(0, headerBytes.length, Endian.little);
  bytes.setRange(8, 8 + headerBytes.length, headerBytes);
  var offset = 8 + headerBytes.length;
  for (final value in [...bias, ...weight]) {
    data.setFloat32(offset, value, Endian.little);
    offset += 4;
  }
  return bytes;
}
