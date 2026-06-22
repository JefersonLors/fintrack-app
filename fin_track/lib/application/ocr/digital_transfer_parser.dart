import '../../domain/entities/receipt.dart';
import '../../domain/entities/extracted_data.dart';
import '../../domain/utils/ocr_parser_utils.dart';
import 'receipt_ocr_parser.dart';
import 'ocr_parser_result.dart';
import 'normalized_ocr_text.dart';
import 'digital_transaction_extractor.dart';
import 'digital_transfer_signals.dart';

class DigitalTransferParser implements ReceiptOcrParser {
  @override
  String get name => 'digital_transfer';

  @override
  ReceiptType get targetType => ReceiptType.pixReceipt;

  @override
  int get priority => 100;

  @override
  OcrParserResult tryExtract(
    NormalizedOcrText text,
    double ocrConfidence, {
    List<String> codes = const [],
  }) {
    final raw = text.normalized;
    final looksLikeFiscalDocument =
        DigitalTransferSignals.looksLikeFiscalDocument(raw);
    final hasExplicitDigitalReceipt =
        DigitalTransferSignals.hasExplicitDigitalReceipt(raw);
    if (looksLikeFiscalDocument && !hasExplicitDigitalReceipt) {
      return _failure(ocrConfidence);
    }

    final hasPrimarySignal = DigitalTransferSignals.hasPrimarySignal(raw);
    if (!hasPrimarySignal) {
      return _failure(ocrConfidence);
    }
    final signals = DigitalTransferSignals.countStrongSignals(raw);
    if (signals < 2) {
      return _failure(ocrConfidence);
    }

    final geometry = text.geometry;
    final structured = const DigitalTransactionExtractor().extract(text);
    final hasStructuredDestination = structured.hasDestination;
    final value =
        _amountByGeometry(geometry) ??
        structured.amount ??
        extractLargestAmount(raw);
    final date =
        _dateByGeometry(geometry) ?? structured.date ?? parseOcrDate(raw);
    final method =
        structured.paymentMethod ??
        (hasExplicitDigitalReceipt ? 'Transferência' : null);
    final name =
        _nameByGeometry(geometry) ??
        (hasStructuredDestination
            ? structured.destination?.name
            : _participantName(text.lines));
    final recipientCnpj =
        _cnpjByGeometry(geometry) ?? structured.destination?.cnpj;
    final hasIdentifier =
        containsAny(raw, ['e2e', 'id da transacao', 'cpf', 'cnpj']) ||
        structured.transactionId != null;
    final identifier =
        _identifierByGeometry(geometry) ?? structured.transactionId;
    final score = scoreDocumentConfidence(
      hasAmount: value != null,
      hasDate: date != null,
      hasStrongSignal: signals >= 2,
      hasParticipant: name != null,
      hasPaymentMethod: method != null,
      hasIdentifier: hasIdentifier,
    );

    return OcrParserResult(
      success: score >= 0.35,
      confidence: score,
      type: method == 'Pix' ? ReceiptType.pixReceipt : ReceiptType.receipt,
      parser: 'digital_transfer',
      data: ExtractedData(
        id: 0,
        receiptId: 0,
        amount: value,
        transactionDate: date,
        establishment: name,
        paymentMethod: method ?? 'Transferência',
        issuerCnpj: recipientCnpj,
        documentNumber: identifier,
        ocrConfidence: ocrConfidence.clamp(0, 1),
        valueConfidence: fieldConfidence(value, score, 0.25),
        dateConfidence: fieldConfidence(date, score, 0.20),
        establishmentConfidence: fieldConfidence(name, score, 0.15),
        paymentMethodConfidence: fieldConfidence(method, score, 0.10),
      ),
    );
  }

  OcrParserResult _failure(double ocrConfidence) {
    return OcrParserResult(
      success: false,
      confidence: 0,
      type: ReceiptType.other,
      parser: 'digital_transfer',
      data: ExtractedData(
        id: 0,
        receiptId: 0,
        ocrConfidence: ocrConfidence.clamp(0, 1),
      ),
    );
  }

  double? _amountByGeometry(NormalizedOcrGeometry? geometry) {
    if (geometry == null || geometry.isEmpty) {
      return null;
    }
    final amountText = geometry.nearbyValue(const [
      'valor',
      'valor da transferencia',
      'valor transferido',
      'total',
    ], ignoreInstitutionBlocks: true);
    return amountText == null ? null : parseCurrency(amountText);
  }

  DateTime? _dateByGeometry(NormalizedOcrGeometry? geometry) {
    final dateText = geometry?.nearbyValue(const [
      'data',
      'data da transacao',
      'data/hora',
      'realizado em',
    ], ignoreInstitutionBlocks: true);
    return dateText == null ? null : parseOcrDate(dateText);
  }

  String? _nameByGeometry(NormalizedOcrGeometry? geometry) {
    if (geometry == null || geometry.isEmpty) {
      return null;
    }
    final section = geometry.valueInSection(
      start: const [
        'quem recebeu',
        'destino',
        'favorecido',
        'beneficiario',
        'recebedor',
      ],
      valueLabels: const ['nome', 'estabelecimento'],
      end: const ['quem pagou', 'origem', 'pagador', 'remetente'],
    );
    final sectionName = section == null ? null : bestNameLine([section]);
    if (sectionName != null) {
      return sectionName;
    }
    final nearby = geometry.nearbyValue(const [
      'quem recebeu',
      'destino',
      'favorecido',
      'beneficiario',
      'recebedor',
      'nome',
    ], ignoreInstitutionBlocks: true);
    return nearby == null ? null : bestNameLine([nearby]);
  }

  String? _cnpjByGeometry(NormalizedOcrGeometry? geometry) {
    if (geometry == null || geometry.isEmpty) {
      return null;
    }
    final inDestinationSection = geometry.valueInSection(
      start: const [
        'quem recebeu',
        'destino',
        'favorecido',
        'beneficiario',
        'recebedor',
      ],
      valueLabels: const ['cnpj', 'cpf/cnpj'],
      end: const ['quem pagou', 'origem', 'pagador', 'remetente'],
    );
    final sectionCnpj = inDestinationSection == null
        ? null
        : extractValidCnpj(inDestinationSection);
    if (sectionCnpj != null) {
      return sectionCnpj;
    }
    final nearby = geometry.nearbyValue(const [
      'cnpj',
      'cpf/cnpj',
    ], ignoreInstitutionBlocks: true);
    return nearby == null ? null : extractValidCnpj(nearby);
  }

  String? _identifierByGeometry(NormalizedOcrGeometry? geometry) {
    final value = geometry?.nearbyValue(const [
      'id da transacao',
      'e2e',
      'identifier',
      'autorizacao',
      'nsu',
    ], ignoreInstitutionBlocks: true);
    if (value == null) {
      return null;
    }
    final match = RegExp(
      r'[A-Z0-9]{8,}',
      caseSensitive: false,
    ).firstMatch(value);
    return match?.group(0);
  }

  String? _participantName(List<String> lines) {
    final establishment = _valueAfterLabel(lines, const ['estabelecimento']);
    if (establishment != null) {
      return establishment;
    }

    final recipientName = _nameInSection(
      lines,
      start: const [
        'quem recebeu',
        'destino',
        'favorecido',
        'recebedor',
        'beneficiario',
      ],
      end: const ['quem pagou', 'origem', 'pagador', 'remetente'],
    );
    if (recipientName != null) {
      return recipientName;
    }

    final candidates = <String>[];
    for (var i = 0; i < lines.length; i++) {
      final line = normalizeSearch(lines[i]);
      if (line == 'nome' ||
          line.contains('favorecido') ||
          line.contains('recebedor') ||
          line.contains('beneficiario') ||
          line.contains('quem recebeu') ||
          line.contains('destino')) {
        for (var j = i + 1; j < lines.length && j <= i + 6; j++) {
          if (_isLabelLine(lines[j])) {
            continue;
          }
          final candidate = bestNameLine([lines[j]]);
          if (candidate != null) {
            candidates.add(candidate);
          }
        }
      }
    }
    if (candidates.isNotEmpty) {
      return candidates.first;
    }
    return bestNameLine(lines.where((line) => !_isLabelLine(line)).toList());
  }

  String? _nameInSection(
    List<String> lines, {
    required List<String> start,
    required List<String> end,
  }) {
    final startIndex = lines.indexWhere((line) {
      final text = normalizeSearch(line);
      return start.any((label) => text.contains(label));
    });
    if (startIndex < 0) {
      return null;
    }
    final relativeEndIndex = lines.skip(startIndex + 1).toList().indexWhere((
      line,
    ) {
      final text = normalizeSearch(line);
      return end.any((label) => text.contains(label));
    });
    final endIndex = relativeEndIndex < 0
        ? (startIndex + 8).clamp(0, lines.length)
        : startIndex + 1 + relativeEndIndex;
    final section = lines.sublist(
      startIndex + 1,
      endIndex.clamp(startIndex + 1, lines.length),
    );
    return _valueAfterLabel(section, const ['nome', 'estabelecimento']) ??
        bestNameLine(section.where((line) => !_isLabelLine(line)).toList());
  }

  String? _valueAfterLabel(List<String> lines, List<String> labels) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final normalizedLine = normalizeSearch(line);
      final label = labels.firstWhere(
        (label) =>
            normalizedLine == label || normalizedLine.startsWith('$label '),
        orElse: () => '',
      );
      if (label.isEmpty) {
        continue;
      }
      final inline = line
          .replaceFirst(RegExp(label, caseSensitive: false), '')
          .replaceFirst(RegExp(r'[:\-]+'), '')
          .trim();
      final inlineName = bestNameLine([inline]);
      if (inlineName != null) {
        return inlineName;
      }
      for (var j = i + 1; j < lines.length && j <= i + 5; j++) {
        if (_isLabelLine(lines[j])) {
          continue;
        }
        final candidate = bestNameLine([lines[j]]);
        if (candidate != null) {
          return candidate;
        }
      }
    }
    return null;
  }

  bool _isLabelLine(String line) {
    final text = normalizeSearch(line.trim());
    return const {
      'valor',
      'tipo de transferencia',
      'pagamento',
      'cartao',
      'codigo de autorizacao',
      'nsu',
      'destino',
      'origem',
      'nome',
      'cpf',
      'cpf/cnpj',
      'cnpj',
      'instituicao',
      'instituição',
      'agencia',
      'numero da account',
      'banco',
      'quem recebeu',
      'quem pagou',
      'estabelecimento',
      'favorecido',
      'recebedor',
      'beneficiario',
      'remetente',
      'pagador',
    }.contains(text);
  }
}
