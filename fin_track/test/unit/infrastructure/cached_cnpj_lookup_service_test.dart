import 'package:drift/drift.dart' show Value;
import 'package:fin_track/domain/entities/company_data.dart';
import 'package:fin_track/domain/infrastructure/i_cnpj_lookup_service.dart';
import 'package:fin_track/infrastructure/database/app_database.dart';
import 'package:fin_track/infrastructure/company/cached_cnpj_lookup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('invalid lookup does not trigger remote service', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final remote = _FakeCnpjLookup();
    final service = CachedCnpjLookupService(database: database, remote: remote);

    expect(await service.lookup('123'), isNull);
    expect(await service.lookupLocal('123'), isNull);
    expect(remote.calls, isEmpty);
  });

  test('remote lookup saves local cache preserving confirmed data', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final updatedAt = DateTime(2026, 5, 1);
    await database
        .into(database.cnpjCache)
        .insert(
          CnpjCacheCompanion.insert(
            cnpj: '12345678000195',
            legalName: const Value('Nome antigo'),
            confirmedName: const Value('Nome confirmado pelo usuario'),
            updatedAt: updatedAt,
          ),
        );
    final remote = _FakeCnpjLookup(
      response: const CompanyData(
        cnpj: '12.345.678/0001-95',
        legalName: 'Nova razao',
        tradeName: 'Nova fantasia',
        fiscalCnaeDescription: 'Comercio varejista',
        city: 'Salvador',
        state: 'BA',
      ),
    );
    final service = CachedCnpjLookupService(database: database, remote: remote);

    final local = await service.lookup('12.345.678/0001-95');
    expect(local?.confirmedName, 'Nome confirmado pelo usuario');
    expect(remote.calls, isEmpty);

    await database.delete(database.cnpjCache).go();
    final remoteResult = await service.lookup('12.345.678/0001-95');
    expect(remoteResult?.legalName, 'Nova razao');
    expect(remote.calls, ['12345678000195']);

    final cache = await service.lookupLocal('12345678000195');
    expect(cache?.tradeName, 'Nova fantasia');
    expect(cache?.fiscalCnaeDescription, 'Comercio varejista');
    expect(cache?.city, 'Salvador');
    expect(cache?.state, 'BA');
  });

  test('local row without company data is ignored', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    await database
        .into(database.cnpjCache)
        .insert(
          CnpjCacheCompanion.insert(
            cnpj: '12345678000195',
            updatedAt: DateTime(2026, 5, 1),
          ),
        );
    final remote = _FakeCnpjLookup();
    final service = CachedCnpjLookupService(database: database, remote: remote);

    expect(await service.lookupLocal('12345678000195'), isNull);
    expect(await service.lookup('12345678000195'), isNull);
    expect(remote.calls, ['12345678000195']);
  });
}

class _FakeCnpjLookup implements ICnpjLookupService {
  _FakeCnpjLookup({this.response});

  final CompanyData? response;
  final List<String> calls = <String>[];

  @override
  Future<CompanyData?> lookup(String cnpj) async {
    calls.add(cnpj);
    return response;
  }
}
