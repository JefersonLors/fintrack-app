class NormalizedOcrText {
  const NormalizedOcrText({
    required this.original,
    required this.normalized,
    required this.lines,
    this.geometry,
  });

  final String original;
  final String normalized;
  final List<String> lines;
  final NormalizedOcrGeometry? geometry;
}

class NormalizedOcrGeometry {
  const NormalizedOcrGeometry({required this.lines, required this.bands});

  final List<VisualOcrLine> lines;
  final List<VisualOcrBand> bands;

  bool get isEmpty => lines.isEmpty;

  String? nearbyValue(
    List<String> labels, {
    bool preferRight = true,
    bool ignoreInstitutionBlocks = false,
    int maxBandsBelow = 3,
  }) {
    for (final line in lines) {
      if (ignoreInstitutionBlocks && line.inInstitutionBlock) {
        continue;
      }
      final label = _labelInLine(line.text, labels);
      if (label == null) {
        continue;
      }
      final inline = _inlineValue(line.text, label);
      if (inline != null) {
        return inline;
      }
      if (preferRight) {
        final rightValue = _valueOnRight(line, ignoreInstitutionBlocks);
        if (rightValue != null) {
          return rightValue;
        }
      }
      final belowValue = _valueBelow(
        line,
        ignoreInstitutionBlocks,
        maxBandsBelow,
      );
      if (belowValue != null) {
        return belowValue;
      }
    }
    return null;
  }

  String? valueInSection({
    required List<String> start,
    required List<String> valueLabels,
    required List<String> end,
    bool ignoreInstitutionBlocks = true,
  }) {
    final startIndex = lines.indexWhere((line) {
      if (ignoreInstitutionBlocks && line.inInstitutionBlock) {
        return false;
      }
      final text = _normalize(line.text);
      return start.any((label) => text.contains(_normalize(label)));
    });
    if (startIndex < 0) {
      return null;
    }

    final relativeEndIndex = lines.skip(startIndex + 1).toList().indexWhere((
      line,
    ) {
      final text = _normalize(line.text);
      return end.any((label) => text.contains(_normalize(label)));
    });
    final endIndex = relativeEndIndex < 0
        ? (startIndex + 8).clamp(0, lines.length)
        : startIndex + 1 + relativeEndIndex;
    final section = NormalizedOcrGeometry(
      lines: lines.sublist(startIndex + 1, endIndex),
      bands: bands,
    );
    final labeled = section.nearbyValue(
      valueLabels,
      ignoreInstitutionBlocks: ignoreInstitutionBlocks,
    );
    if (labeled != null) {
      return labeled;
    }
    for (final line in section.lines) {
      if (ignoreInstitutionBlocks && line.inInstitutionBlock) {
        continue;
      }
      if (_looksLikeLabel(line.text)) {
        continue;
      }
      return line.text.trim();
    }
    return null;
  }

  String? _valueOnRight(VisualOcrLine label, bool ignoreInstitutionBlocks) {
    final sameBand = lines.where((line) {
      if (identical(line, label)) {
        return false;
      }
      if (ignoreInstitutionBlocks && line.inInstitutionBlock) {
        return false;
      }
      final sameY = line.centerY >= label.top && line.centerY <= label.bottom;
      return sameY && line.left >= label.right - 4;
    }).toList()..sort((a, b) => a.left.compareTo(b.left));
    return sameBand.isEmpty ? null : sameBand.first.text.trim();
  }

  String? _valueBelow(
    VisualOcrLine label,
    bool ignoreInstitutionBlocks,
    int maxBandsBelow,
  ) {
    final bandIndex = bands.indexWhere((band) => band.lines.contains(label));
    if (bandIndex < 0) {
      return null;
    }
    final limit = (bandIndex + maxBandsBelow + 1).clamp(0, bands.length);
    for (var i = bandIndex + 1; i < limit; i++) {
      final candidates = bands[i].lines.where((line) {
        if (ignoreInstitutionBlocks && line.inInstitutionBlock) {
          return false;
        }
        return !_looksLikeLabel(line.text);
      }).toList()..sort((a, b) => a.left.compareTo(b.left));
      if (candidates.isNotEmpty) {
        return candidates.first.text.trim();
      }
    }
    return null;
  }
}

class VisualOcrBand {
  const VisualOcrBand({required this.lines});

  final List<VisualOcrLine> lines;

  String get text => lines.map((line) => line.text).join(' ').trim();
}

class VisualOcrLine {
  const VisualOcrLine({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.blockIndex,
    required this.lineIndex,
    this.inInstitutionBlock = false,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final int blockIndex;
  final int lineIndex;
  final bool inInstitutionBlock;

  double get centerY => (top + bottom) / 2;
}

String? _labelInLine(String text, List<String> labels) {
  final normalized = _normalize(text);
  for (final label in labels) {
    final normalizedLabel = _normalize(label);
    if (normalized == normalizedLabel ||
        normalized.startsWith('$normalizedLabel ') ||
        normalized.startsWith('$normalizedLabel:')) {
      return label;
    }
  }
  return null;
}

String? _inlineValue(String text, String label) {
  final value = text
      .replaceFirst(RegExp(RegExp.escape(label), caseSensitive: false), '')
      .replaceFirst(RegExp(r'[:\-]+'), '')
      .trim();
  return value.isEmpty ? null : value;
}

bool _looksLikeLabel(String text) {
  final normalized = _normalize(text);
  return const {
    'valor',
    'nome',
    'cpf',
    'cnpj',
    'cpf/cnpj',
    'destino',
    'origem',
    'quem recebeu',
    'quem pagou',
    'favorecido',
    'beneficiario',
    'recebedor',
    'instituicao',
    'banco',
    'agencia',
    'account',
    'ispb',
  }.contains(normalized);
}

String _normalize(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c')
      .trim();
}
