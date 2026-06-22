import '../../domain/entities/receipt.dart';
import '../../domain/entities/extracted_data.dart';
import '../../domain/utils/cnpj_extractor.dart';
import '../../domain/value_objects/receipt_payment_method.dart';
import '../../domain/value_objects/ocr_result.dart';
import 'ocr_text_normalizer_service.dart';
import '../../domain/utils/ocr_parser_utils.dart' as ocr_utils;
import 'receipt_ocr_parser.dart';
import 'fiscal_document_parser.dart';
import 'fallback_receipt_parser.dart';
import 'card_payment_parser.dart';
import 'generic_receipt_parser.dart';
import 'digital_transfer_parser.dart';
import 'ocr_processing_result.dart';
import 'ocr_parser_result.dart';
import 'normalized_ocr_text.dart';

class DataExtractorService {
  DataExtractorService({
    OcrTextNormalizerService? normalizer,
    List<ReceiptOcrParser>? parsers,
  }) : _normalizer = normalizer ?? OcrTextNormalizerService(),
       _fallback = FallbackReceiptParser(),
       _parsers =
           (parsers ??
                   <ReceiptOcrParser>[
                     DigitalTransferParser(),
                     CardPaymentParser(),
                     FiscalDocumentParser(),
                     GenericReceiptParser(),
                   ])
               .toList()
             ..sort((a, b) => b.priority.compareTo(a.priority));

  final OcrTextNormalizerService _normalizer;
  final List<ReceiptOcrParser> _parsers;
  final FallbackReceiptParser _fallback;
  final CnpjExtractor _cnpjExtractor = const CnpjExtractor();

  OcrProcessingResult process(
    String text,
    double ocrConfidence, {
    List<String> codes = const [],
  }) {
    final normalized = _normalizer.normalize(text);
    return _processNormalized(normalized, ocrConfidence, codes: codes);
  }

  OcrProcessingResult processResult(
    OcrResult result, {
    List<String> codes = const [],
  }) {
    final normalized = _normalizer.normalizeResult(result);
    return _processNormalized(normalized, result.confidence, codes: codes);
  }

  OcrProcessingResult _processNormalized(
    NormalizedOcrText normalized,
    double ocrConfidence, {
    List<String> codes = const [],
  }) {
    final results =
        <OcrParserResult>[
            for (final parser in _parsers)
              parser.tryExtract(normalized, ocrConfidence, codes: codes),
          ].where((result) => result.success).toList()
          ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final best = results.isEmpty
        ? _fallback.tryExtract(normalized, ocrConfidence, codes: codes)
        : results.first;
    final extractedCnpj = _cnpjExtractor.extract(
      normalized.normalized,
      codes: codes,
      context: _cnpjContext(best.parser),
    );
    final dataWithCnpj = _applyCentralCnpj(best.data, extractedCnpj);

    return OcrProcessingResult(
      originalText: normalized.original,
      normalizedText: normalized.normalized,
      type: best.type,
      extractedData: dataWithCnpj.copyWith(
        extractionParser: best.parser,
        extractionConfidence: best.confidence.clamp(0, 1),
      ),
      ocrConfidence: ocrConfidence.clamp(0, 1),
      extractionConfidence: best.confidence.clamp(0, 1),
      parser: best.parser,
    );
  }

  ExtractedData extract(String text, double confidence) {
    return process(text, confidence).extractedData;
  }

  ExtractedData _applyCentralCnpj(
    ExtractedData data,
    CnpjExtractionResult? result,
  ) {
    if (result == null) {
      return data;
    }
    final best = result.best;
    final currentCnpj = data.issuerCnpj?.replaceAll(RegExp(r'\D'), '');
    final shouldReplace =
        best.source != CnpjSource.text ||
        best.score >= 75 ||
        ((currentCnpj == null || currentCnpj.isEmpty) && best.score >= 50);
    return data.copyWith(
      issuerCnpj: shouldReplace ? best.cnpj : data.issuerCnpj,
      accessKey: data.accessKey ?? best.accessKey,
      urlQrCode: data.urlQrCode ?? best.urlQrCode,
    );
  }

  CnpjDocumentContext _cnpjContext(String parser) {
    return switch (parser) {
      'fiscal_document' => CnpjDocumentContext.fiscal,
      'digital_transfer' => CnpjDocumentContext.transfer,
      'card_payment' => CnpjDocumentContext.payment,
      _ => CnpjDocumentContext.general,
    };
  }

  ReceiptType inferType(String text) {
    return process(text, 0).type;
  }

  double? extractAmount(String text) {
    // 1st attempt: labeled amount; captures the number after
    // "amount", "total", "transfer amount", etc.
    final labeled = RegExp(
      r'(?:amount(?:\s+da\s+transfer[eê]ncia)?|total(?:\s+pago)?|'
      r'amount\s+cobrado|quantia)\s*:?\s*'
      r'R?\$?\s*(\d{1,3}(?:[.\s]\d{3})*(?:,\d{2})?|\d+(?:,\d{2})?)',
      caseSensitive: false,
    );

    final labeledMatch = labeled.firstMatch(text);
    if (labeledMatch != null) {
      final amount = _parseCurrency(labeledMatch.group(1)!);
      if (amount != null && amount > 0) return amount;
    }

    // 2nd attempt: amount preceded by R$.
    final withSymbol = RegExp(
      r'R\$\s*(\d{1,3}(?:[.\s]\d{3})*(?:,\d{2})?|\d+(?:,\d{2})?)',
      caseSensitive: false,
    );
    final amountsWithSymbol = withSymbol
        .allMatches(text)
        .map((m) => _parseCurrency(m.group(1)!))
        .whereType<double>()
        .where((v) => v > 0)
        .toList();

    if (amountsWithSymbol.isNotEmpty) {
      // Returns the highest amount with a symbol, which is usually the total.
      return amountsWithSymbol.reduce((a, b) => a > b ? a : b);
    }

    // 3rd attempt: any monetary pattern in the text.
    final generic = RegExp(r'(\d{1,3}(?:\.\d{3})+,\d{2}|\d+,\d{2})');
    final genericAmounts = generic
        .allMatches(text)
        .map((m) => _parseCurrency(m.group(1)!))
        .whereType<double>()
        .where((v) => v > 0)
        .toList();

    if (genericAmounts.isNotEmpty) {
      return genericAmounts.reduce((a, b) => a > b ? a : b);
    }

    return null;
  }

  double? _parseCurrency(String raw) {
    return ocr_utils.parseCurrency(raw);
  }

  DateTime? extractDate(String text) {
    final ocr = ocr_utils.parseOcrDate(text);
    if (ocr != null) return ocr;

    // yyyy-MM-dd  (ISO)
    final iso = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
    if (iso != null) {
      final dt = DateTime.tryParse(iso.group(0)!);
      if (dt != null) return dt;
    }

    // dd de <written-out month> de yyyy
    final writtenOut = RegExp(
      r'(\d{1,2})\s+de\s+(janeiro|fevereiro|mar[cç]o|abril|maio|junho|'
      r'julho|agosto|setembro|outubro|novembro|dezembro)\s+de\s+(\d{4})',
      caseSensitive: false,
    ).firstMatch(text);
    if (writtenOut != null) {
      final month = _monthToNumber(writtenOut.group(2)!);
      final dt = DateTime.tryParse(
        '${writtenOut.group(3)}-${month.toString().padLeft(2, '0')}'
        '-${writtenOut.group(1)!.padLeft(2, '0')}',
      );
      if (dt != null) return dt;
    }

    // dd-MM-yyyy
    final dashed = RegExp(r'(\d{2})-(\d{2})-(\d{4})').firstMatch(text);
    if (dashed != null) {
      final dt = DateTime.tryParse(
        '${dashed.group(3)}-${dashed.group(2)}'
        '-${dashed.group(1)}',
      );
      if (dt != null) return dt;
    }

    return null;
  }

  int _monthToNumber(String month) {
    const months = {
      'janeiro': 1,
      'fevereiro': 2,
      'marco': 3,
      'abril': 4,
      'maio': 5,
      'junho': 6,
      'julho': 7,
      'agosto': 8,
      'setembro': 9,
      'outubro': 10,
      'novembro': 11,
      'dezembro': 12,
    };
    return months[_normalize(month)] ?? 1;
  }

  String? extractEstablishment(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.length > 2)
        .toList();

    return ocr_utils.bestNameLine(lines);
  }

  String? extractPaymentMethod(String text) {
    final n = _normalize(text);

    if (_hasAny(n, [
      'key pix',
      'transferencia pix',
      'pix enviado',
      'pix recebido',
      'comprovante pix',
      'via pix',
    ])) {
      return ReceiptPaymentMethod.pix;
    }
    if (_hasAny(n, [
      'cartao de credito',
      'credito',
      'cred.',
      'visa',
      'mastercard',
      'elo',
      'amex',
      'american express',
      'hipercard',
      'parcelado',
    ])) {
      return ReceiptPaymentMethod.creditCard;
    }
    if (_hasAny(n, ['cartao de debito', 'debito', 'deb.'])) {
      return ReceiptPaymentMethod.debitCard;
    }
    if (_hasAny(n, ['boleto', 'codigo de barras', 'line digitavel'])) {
      return ReceiptPaymentMethod.boleto;
    }
    if (_hasAny(n, [
      'ted',
      'transferencia eletroncia',
      'transferencia bancaria',
    ])) {
      return ReceiptPaymentMethod.ted;
    }
    if (_hasAny(n, ['doc', 'documento de ordem de credito'])) {
      return ReceiptPaymentMethod.doc;
    }
    if (_hasAny(n, ['cash', 'especie', 'em especie', 'caixa'])) {
      return ReceiptPaymentMethod.cash;
    }
    if (n.contains('pix')) {
      return ReceiptPaymentMethod.pix;
    }

    return null;
  }

  bool _hasAny(String text, List<String> terms) => terms.any(text.contains);

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }
}
