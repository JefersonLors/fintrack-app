import 'dart:math' as math;

class DistilUseTokenizer {
  const DistilUseTokenizer({required this.vocab, this.maxTokens = 128});

  final Map<String, int> vocab;
  final int maxTokens;

  DistilUseEncoding encode(String text) {
    final cls = vocab['[CLS]'] ?? 101;
    final sep = vocab['[SEP]'] ?? 102;
    final pad = vocab['[PAD]'] ?? 0;
    final unk = vocab['[UNK]'] ?? 100;
    final tokens = <int>[cls];
    final tokenStrings = <String>['[CLS]'];

    for (final word in basicTokenize(text)) {
      if (tokens.length >= maxTokens - 1) {
        break;
      }
      final pieces = wordPiece(
        word,
        unk: unk,
        limit: maxTokens - 1 - tokens.length,
      );
      tokens.addAll(pieces.ids);
      tokenStrings.addAll(pieces.tokens);
    }
    tokens.add(sep);
    tokenStrings.add('[SEP]');

    final attentionMask = List<int>.filled(maxTokens, 0);
    final inputIds = List<int>.filled(maxTokens, pad);
    for (var i = 0; i < math.min(tokens.length, maxTokens); i++) {
      inputIds[i] = tokens[i];
      attentionMask[i] = 1;
    }

    return DistilUseEncoding(
      inputIds: inputIds,
      attentionMask: attentionMask,
      tokenTypeIds: List<int>.filled(maxTokens, 0),
      tokens: tokenStrings,
    );
  }

  List<String> basicTokenize(String text) {
    final tokens = <String>[];
    final buffer = StringBuffer();

    void flush() {
      if (buffer.isEmpty) {
        return;
      }
      tokens.add(buffer.toString());
      buffer.clear();
    }

    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (_isWhitespace(rune)) {
        flush();
      } else if (_isPunctuation(rune)) {
        flush();
        tokens.add(char);
      } else {
        buffer.write(char);
      }
    }
    flush();
    return tokens;
  }

  DistilUseWordPieceResult wordPiece(
    String word, {
    required int unk,
    required int limit,
  }) {
    if (limit <= 0) {
      return const DistilUseWordPieceResult(ids: <int>[], tokens: <String>[]);
    }
    if (vocab.containsKey(word)) {
      return DistilUseWordPieceResult(
        ids: <int>[vocab[word]!],
        tokens: <String>[word],
      );
    }

    final ids = <int>[];
    final tokens = <String>[];
    var start = 0;
    var unknown = false;
    while (start < word.length) {
      var end = word.length;
      String? subToken;
      while (start < end) {
        var piece = word.substring(start, end);
        if (start > 0) {
          piece = '##$piece';
        }
        if (vocab.containsKey(piece)) {
          subToken = piece;
          break;
        }
        end--;
      }
      if (subToken == null) {
        unknown = true;
        break;
      }
      ids.add(vocab[subToken]!);
      tokens.add(subToken);
      if (ids.length >= limit) {
        break;
      }
      start = end;
    }

    if (unknown || ids.isEmpty) {
      return DistilUseWordPieceResult(
        ids: <int>[unk],
        tokens: const <String>['[UNK]'],
      );
    }
    return DistilUseWordPieceResult(ids: ids, tokens: tokens);
  }

  bool _isWhitespace(int rune) {
    return rune == 0x20 ||
        rune == 0x09 ||
        rune == 0x0A ||
        rune == 0x0D ||
        rune == 0x0B ||
        rune == 0x0C;
  }

  bool _isPunctuation(int rune) {
    return (rune >= 33 && rune <= 47) ||
        (rune >= 58 && rune <= 64) ||
        (rune >= 91 && rune <= 96) ||
        (rune >= 123 && rune <= 126);
  }
}

class DistilUseEncoding {
  const DistilUseEncoding({
    required this.inputIds,
    required this.attentionMask,
    required this.tokenTypeIds,
    required this.tokens,
  });

  final List<int> inputIds;
  final List<int> attentionMask;
  final List<int> tokenTypeIds;
  final List<String> tokens;
}

class DistilUseWordPieceResult {
  const DistilUseWordPieceResult({required this.ids, required this.tokens});

  final List<int> ids;
  final List<String> tokens;
}
