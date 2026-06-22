import 'dart:convert';
import 'dart:io';

import 'package:fin_track/infrastructure/company/brasil_api_cnpj_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns null for invalid CNPJ without calling transport', () async {
    var calls = 0;
    final service = BrasilApiCnpjService(
      get: (_) async {
        calls++;
        return const BrasilApiResponse(statusCode: HttpStatus.ok, body: '{}');
      },
    );

    final result = await service.lookup('12.345');

    expect(result, isNull);
    expect(calls, 0);
  });

  test(
    'default constructor does not query network when CNPJ is invalid',
    () async {
      final service = BrasilApiCnpjService();

      expect(await service.lookup('inválido'), isNull);
    },
  );

  test('normalizes CNPJ and maps valid BrasilAPI JSON', () async {
    Uri? receivedUri;
    final service = BrasilApiCnpjService(
      get: (uri) async {
        receivedUri = uri;
        return BrasilApiResponse(
          statusCode: HttpStatus.ok,
          body: jsonEncode({
            'cnpj': ' 12.345.678/0001-90 ',
            'razao_social': ' Empresa Exemplo LTDA ',
            'nome_fantasia': ' Exemplo ',
            'cnae_fiscal_descricao': ' Comércio varejista ',
            'city': ' Salvador ',
            'state': ' BA ',
          }),
        );
      },
    );

    final result = await service.lookup('12.345.678/0001-90');

    expect(receivedUri?.host, 'brasilapi.com.br');
    expect(receivedUri?.path, '/api/cnpj/v1/12345678000190');
    expect(result, isNotNull);
    expect(result!.cnpj, '12.345.678/0001-90');
    expect(result.legalName, 'Empresa Exemplo LTDA');
    expect(result.tradeName, 'Exemplo');
    expect(result.fiscalCnaeDescription, 'Comércio varejista');
    expect(result.city, 'Salvador');
    expect(result.state, 'BA');
  });

  test('uses normalized CNPJ when response omits CNPJ', () async {
    final service = BrasilApiCnpjService(
      get: (_) async {
        return BrasilApiResponse(
          statusCode: HttpStatus.ok,
          body: jsonEncode({
            'cnpj': '',
            'razao_social': 'Sem CNPJ na resposta',
            'nome_fantasia': '   ',
          }),
        );
      },
    );

    final result = await service.lookup('12345678000190');

    expect(result, isNotNull);
    expect(result!.cnpj, '12345678000190');
    expect(result.legalName, 'Sem CNPJ na resposta');
    expect(result.tradeName, isNull);
    expect(result.fiscalCnaeDescription, isNull);
  });

  test('returns null for non-OK HTTP status', () async {
    final service = BrasilApiCnpjService(
      get: (_) async {
        return const BrasilApiResponse(
          statusCode: HttpStatus.notFound,
          body: '{"erro": "não encontrado"}',
        );
      },
    );

    expect(await service.lookup('12345678000190'), isNull);
  });

  test('returns null for invalid JSON or unexpected format', () async {
    final invalidJson = BrasilApiCnpjService(
      get: (_) async {
        return const BrasilApiResponse(
          statusCode: HttpStatus.ok,
          body: '{json',
        );
      },
    );
    final jsonList = BrasilApiCnpjService(
      get: (_) async {
        return const BrasilApiResponse(statusCode: HttpStatus.ok, body: '[]');
      },
    );

    expect(await invalidJson.lookup('12345678000190'), isNull);
    expect(await jsonList.lookup('12345678000190'), isNull);
  });

  test('returns null when transport throws exception', () async {
    final service = BrasilApiCnpjService(
      get: (_) async => throw const SocketException('sem rede'),
    );

    expect(await service.lookup('12345678000190'), isNull);
  });
}
