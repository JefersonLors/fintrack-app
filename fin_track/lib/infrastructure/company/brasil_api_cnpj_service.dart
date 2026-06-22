import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/company_data.dart';
import '../../domain/infrastructure/i_cnpj_lookup_service.dart';

typedef BrasilApiGet = Future<BrasilApiResponse> Function(Uri uri);

class BrasilApiResponse {
  const BrasilApiResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

class BrasilApiCnpjService implements ICnpjLookupService {
  BrasilApiCnpjService({HttpClient? client, BrasilApiGet? get})
    : _get = get ?? _httpClientGet(client ?? HttpClient());

  final BrasilApiGet _get;

  @override
  Future<CompanyData?> lookup(String cnpj) async {
    final normalized = cnpj.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\d{14}$').hasMatch(normalized)) {
      return null;
    }

    try {
      final uri = Uri.https('brasilapi.com.br', '/api/cnpj/v1/$normalized');
      final response = await _get(uri);
      if (response.statusCode != HttpStatus.ok) {
        return null;
      }
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) {
        return null;
      }
      return CompanyData(
        cnpj: _text(json['cnpj']) ?? normalized,
        legalName: _text(json['razao_social']),
        tradeName: _text(json['nome_fantasia']),
        fiscalCnaeDescription: _text(json['cnae_fiscal_descricao']),
        city: _text(json['city']),
        state: _text(json['state']),
      );
    } on Object {
      return null;
    }
  }

  // coverage:ignore-start
  static BrasilApiGet _httpClientGet(HttpClient client) {
    return (uri) async {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 4));
      final response = await request.close().timeout(
        const Duration(seconds: 4),
      );
      final body = response.statusCode == HttpStatus.ok
          ? await utf8.decodeStream(response)
          : '';
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
      }
      return BrasilApiResponse(statusCode: response.statusCode, body: body);
    };
  }
  // coverage:ignore-end

  String? _text(Object? raw) {
    final text = raw?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}
