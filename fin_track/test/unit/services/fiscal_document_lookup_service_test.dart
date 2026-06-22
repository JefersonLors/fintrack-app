import 'dart:io';

import 'package:fin_track/infrastructure/fiscal/fiscal_document_lookup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('looks up fiscal document by URL and extracts page data', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final done = server.listen((request) {
      request.response
        ..headers.contentType = ContentType.html
        ..write('''
<!doctype html>
<html>
  <body>
    <h1>Consulta NFC-e</h1>
    <div>Razão Social: POSTO MATARIPE BONOCO</div>
    <div>CNPJ: 55.986.560/0001-59</div>
    <div>Chave de acesso: 29260455986560000159650210000156761007188082</div>
    <div>Número: 15676</div>
    <div>Série: 21</div>
    <div>Emissão: 02/04/2026 17:32:32</div>
    <div>GASOLINA COMUM 20,577 x 7,29 150,00</div>
    <strong>Valor total da nota R\$ 150,00</strong>
  </body>
</html>
''')
        ..close();
    });
    addTearDown(() async {
      await done.cancel();
      await server.close(force: true);
    });

    final service = FiscalDocumentLookupService(allowLocalhost: true);
    final extractedData = await service.lookup(
      urlQrCode: 'http://127.0.0.1:${server.port}/nfce?q=abc',
    );

    expect(extractedData, isNotNull);
    expect(extractedData!.amount, 150.00);
    expect(extractedData.issuedAt, DateTime(2026, 4, 2, 17, 32, 32));
    expect(extractedData.establishment, 'POSTO MATARIPE BONOCO');
    expect(extractedData.issuerCnpj, '55986560000159');
    expect(
      extractedData.accessKey,
      '29260455986560000159650210000156761007188082',
    );
    expect(extractedData.documentNumber, '15676');
    expect(extractedData.documentSeries, '21');
    expect(extractedData.documentState, 'BA');
    expect(extractedData.items, contains('GASOLINA COMUM'));
  });

  test('ignores URL that does not look fiscal', () async {
    final service = FiscalDocumentLookupService(allowLocalhost: false);

    final extractedData = await service.lookup(
      urlQrCode: 'https://example.com/nota',
    );

    expect(extractedData, isNull);
  });
}
