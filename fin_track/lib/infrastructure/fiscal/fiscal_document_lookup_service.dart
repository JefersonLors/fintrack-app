import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/fiscal_document_data.dart';
import '../../domain/infrastructure/i_fiscal_document_lookup_service.dart';
import '../../domain/utils/ocr_parser_utils.dart';

class FiscalDocumentLookupService implements IFiscalDocumentLookupService {
  FiscalDocumentLookupService({HttpClient? client, bool allowLocalhost = false})
    : _client = client ?? HttpClient(),
      _allowLocalhost = allowLocalhost;

  final HttpClient _client;
  final bool _allowLocalhost;

  @override
  Future<FiscalDocumentData?> lookup({
    String? urlQrCode,
    String? accessKey,
  }) async {
    final uri = _uriFiscal(urlQrCode);
    if (uri == null) {
      return null;
    }

    try {
      final request = await _client
          .getUrl(uri)
          .timeout(const Duration(seconds: 5));
      request.headers.set(HttpHeaders.acceptHeader, 'text/html,*/*');
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 FinTrack/1.0',
      );
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<void>();
        return null;
      }
      final body = await utf8.decodeStream(response);
      final data = _FiscalLookupParser(
        html: body,
        url: uri.toString(),
        accessKey: accessKey,
      ).extract();
      return data.hasUsefulData ? data : null;
    } on Object {
      return null;
    }
  }

  Uri? _uriFiscal(String? raw) {
    var text = raw?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    final url = RegExp(
      r'(https?://[^\s|]+|www\.[^\s|]+)',
      caseSensitive: false,
    ).firstMatch(text)?.group(1);
    text = url ?? text;
    if (text.startsWith(RegExp(r'www\.', caseSensitive: false))) {
      text = 'https://$text';
    }
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return null;
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return null;
    }
    final host = uri.host.toLowerCase();
    final fiscal =
        host.contains('sefaz') || host.endsWith('.gov.br') || host == 'gov.br';
    final local =
        _allowLocalhost &&
        (host == 'localhost' || host == '127.0.0.1' || host == '::1');
    if (!fiscal && !local) {
      return null;
    }
    return uri;
  }
}

class _FiscalLookupParser {
  const _FiscalLookupParser({
    required this.html,
    required this.url,
    required this.accessKey,
  });

  final String html;
  final String url;
  final String? accessKey;

  FiscalDocumentData extract() {
    final text = _plainText(html);
    final key = _accessKey(text) ?? _accessKey(url) ?? accessKey;
    final keyData = key == null ? null : _accessKeyData(key);
    return FiscalDocumentData(
      amount: _totalAmount(text),
      issuedAt: _date(text),
      establishment: _issuer(text),
      issuerCnpj: _issuerCnpj(text) ?? keyData?.cnpj,
      accessKey: key,
      lookupUrl: url,
      documentNumber: _documentNumber(text) ?? keyData?.number,
      documentSeries: _documentSeries(text) ?? keyData?.series,
      documentState: keyData?.state,
      items: _items(text),
    );
  }

  String _plainText(String html) {
    var text = html
        .replaceAll(RegExp(r'<script\b[^>]*>.*?</script>', dotAll: true), ' ')
        .replaceAll(RegExp(r'<style\b[^>]*>.*?</style>', dotAll: true), ' ')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(
            r'</(?:div|p|tr|li|td|th|span|label|h\d)>',
            caseSensitive: false,
          ),
          '\n',
        )
        .replaceAll(RegExp(r'<[^>]+>'), ' ');
    const entities = {
      '&nbsp;': ' ',
      '&amp;': '&',
      '&quot;': '"',
      '&#39;': "'",
      '&apos;': "'",
      '&ccedil;': 'ç',
      '&Ccedil;': 'Ç',
      '&atilde;': 'ã',
      '&Atilde;': 'Ã',
      '&otilde;': 'õ',
      '&Otilde;': 'Õ',
      '&aacute;': 'á',
      '&Aacute;': 'Á',
      '&eacute;': 'é',
      '&Eacute;': 'É',
      '&iacute;': 'í',
      '&Iacute;': 'Í',
      '&oacute;': 'ó',
      '&Oacute;': 'Ó',
      '&uacute;': 'ú',
      '&Uacute;': 'Ú',
      '&ecirc;': 'ê',
      '&Ecirc;': 'Ê',
    };
    for (final entry in entities.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      final code = int.tryParse(match.group(1)!);
      return code == null ? ' ' : String.fromCharCode(code);
    });
    return text
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  double? _totalAmount(String text) {
    final labels = [
      r'valor\s+total\s+da\s+nota',
      r'valor\s+total',
      r'valor\s+pago',
      r'total\s+(?:r?\$|pago)',
    ];
    for (final label in labels) {
      final match = RegExp(
        '$label\\s*[:\\-]?\\s*(?:R\\s*\\\$\\s*)?'
        r'(\d{1,3}(?:[.\s]\d{3})*,\d{2}|\d+,\d{2})',
        caseSensitive: false,
      ).firstMatch(text);
      if (match != null) {
        return parseCurrency(match.group(1)!);
      }
    }
    return null;
  }

  DateTime? _date(String text) {
    final labeled = RegExp(
      r'(?:emiss[aã]o|data\s+(?:de\s+)?emiss[aã]o|emitida\s+em)\s*[:\-]?\s*'
      r'(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})'
      r'(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?',
      caseSensitive: false,
    ).firstMatch(text);
    if (labeled != null) {
      return _buildDate(labeled);
    }
    final generic = RegExp(
      r'(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})'
      r'(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?',
    ).firstMatch(text);
    return generic == null ? null : _buildDate(generic);
  }

  DateTime? _buildDate(RegExpMatch match) {
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final rawYear = int.tryParse(match.group(3)!);
    if (day == null || month == null || rawYear == null) return null;
    final year = rawYear < 100 ? 2000 + rawYear : rawYear;
    return DateTime(
      year,
      month,
      day,
      int.tryParse(match.group(4) ?? '0') ?? 0,
      int.tryParse(match.group(5) ?? '0') ?? 0,
      int.tryParse(match.group(6) ?? '0') ?? 0,
    );
  }

  String? _issuer(String text) {
    final labels = [
      r'raz[aã]o\s+social',
      r'name\s+empresarial',
      r'emitente',
      r'estabelecimento',
    ];
    for (final label in labels) {
      final match = RegExp(
        '$label\\s*[:\\-]?\\s*([^\\n]{3,80})',
        caseSensitive: false,
      ).firstMatch(text);
      final candidate = match?.group(1)?.trim();
      if (_looksLikeName(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  String? _issuerCnpj(String text) {
    final match = RegExp(
      r'(?:cnpj|cnp3)\s*[:\-]?\s*(\d{2})\D?(\d{3})\D?(\d{3})\D?(\d{4})\D?(\d{2})',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;
    return [
      match.group(1),
      match.group(2),
      match.group(3),
      match.group(4),
      match.group(5),
    ].join();
  }

  String? _accessKey(String text) {
    final match = RegExp(r'(?<!\d)(?:\d[ .-]?){44}(?!\d)').firstMatch(text);
    return match?.group(0)?.replaceAll(RegExp(r'\D'), '');
  }

  String? _documentNumber(String text) {
    return RegExp(
      r'(?:n[úu]mero|n[ºo]\.?)\s*[:\-]?\s*(\d{3,12})',
      caseSensitive: false,
    ).firstMatch(text)?.group(1);
  }

  String? _documentSeries(String text) {
    return RegExp(
      r's[ée]rie\s*[:\-]?\s*(\d{1,4})',
      caseSensitive: false,
    ).firstMatch(text)?.group(1);
  }

  List<String> _items(String text) {
    final lines = text.split('\n');
    final items = <String>[];
    for (final line in lines) {
      final normalized = normalizeSearch(line);
      if (!RegExp(r'\d+,\d{2}').hasMatch(line)) continue;
      if (containsAny(normalized, [
        'valor total',
        'valor pago',
        'tributo',
        'subtotal',
        'troco',
        'desconto',
      ])) {
        continue;
      }
      var item = line
          .replaceAll(RegExp(r'^\d{1,14}\s+'), '')
          .replaceAll(
            RegExp(r'\b\d+(?:[,.]\d+)?\s*x\b.*$', caseSensitive: false),
            '',
          )
          .replaceAll(RegExp(r'\b\d+[,.]\d{2}\b.*$'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (_looksLikeName(item)) {
        items.add(item);
      }
    }
    return items.toSet().take(20).toList();
  }

  bool _looksLikeName(String? text) {
    if (text == null) return false;
    final clean = text.trim();
    if (clean.length < 3) return false;
    if (!RegExp(r'[A-Za-zÀ-ÿ]{3,}').hasMatch(clean)) return false;
    if (RegExp(r'^[\d\s.,:/\-]+$').hasMatch(clean)) return false;
    return true;
  }

  _AccessKeyData? _accessKeyData(String key) {
    if (!RegExp(r'^\d{44}$').hasMatch(key)) {
      return null;
    }
    return _AccessKeyData(
      state: _stateByCode(key.substring(0, 2)),
      cnpj: key.substring(6, 20),
      series: int.parse(key.substring(22, 25)).toString(),
      number: int.parse(key.substring(25, 34)).toString(),
    );
  }

  String? _stateByCode(String code) {
    const states = {
      '11': 'RO',
      '12': 'AC',
      '13': 'AM',
      '14': 'RR',
      '15': 'PA',
      '16': 'AP',
      '17': 'TO',
      '21': 'MA',
      '22': 'PI',
      '23': 'CE',
      '24': 'RN',
      '25': 'PB',
      '26': 'PE',
      '27': 'AL',
      '28': 'SE',
      '29': 'BA',
      '31': 'MG',
      '32': 'ES',
      '33': 'RJ',
      '35': 'SP',
      '41': 'PR',
      '42': 'SC',
      '43': 'RS',
      '50': 'MS',
      '51': 'MT',
      '52': 'GO',
      '53': 'DF',
    };
    return states[code];
  }
}

class _AccessKeyData {
  const _AccessKeyData({
    required this.state,
    required this.cnpj,
    required this.series,
    required this.number,
  });

  final String? state;
  final String cnpj;
  final String series;
  final String number;
}
