import 'package:drift/drift.dart';

import '../../domain/entities/company_data.dart';
import '../../domain/infrastructure/i_cnpj_lookup_service.dart';
import '../database/app_database.dart';

class CachedCnpjLookupService
    implements ICnpjLookupService, ILocalCnpjLookupService {
  CachedCnpjLookupService({
    required AppDatabase database,
    required ICnpjLookupService remote,
  }) : _database = database,
       _remote = remote;

  final AppDatabase _database;
  final ICnpjLookupService _remote;

  @override
  Future<CompanyData?> lookup(String cnpj) async {
    final normalized = cnpj.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\d{14}$').hasMatch(normalized)) {
      return null;
    }

    final local = await _lookupLocal(normalized);
    if (local != null) {
      return local;
    }

    final remote = await _remote.lookup(normalized);
    if (remote != null) {
      await _saveLocal(remote);
    }
    return remote;
  }

  @override
  Future<CompanyData?> lookupLocal(String cnpj) async {
    final normalized = cnpj.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\d{14}$').hasMatch(normalized)) {
      return null;
    }
    return _lookupLocal(normalized);
  }

  Future<CompanyData?> _lookupLocal(String cnpj) async {
    final row = await (_database.select(
      _database.cnpjCache,
    )..where((tbl) => tbl.cnpj.equals(cnpj))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    final hasCompanyData = [
      row.legalName,
      row.tradeName,
      row.confirmedName,
      row.fiscalCnaeDescription,
      row.city,
      row.state,
    ].any((amount) => amount != null && amount.trim().isNotEmpty);
    if (!hasCompanyData) {
      return null;
    }
    return CompanyData(
      cnpj: row.cnpj,
      legalName: row.legalName,
      tradeName: row.tradeName,
      confirmedName: row.confirmedName,
      fiscalCnaeDescription: row.fiscalCnaeDescription,
      city: row.city,
      state: row.state,
    );
  }

  Future<void> _saveLocal(CompanyData company) async {
    final cnpj = company.cnpj.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\d{14}$').hasMatch(cnpj)) {
      return;
    }
    final existing = await (_database.select(
      _database.cnpjCache,
    )..where((tbl) => tbl.cnpj.equals(cnpj))).getSingleOrNull();
    await _database
        .into(_database.cnpjCache)
        .insertOnConflictUpdate(
          CnpjCacheCompanion.insert(
            cnpj: cnpj,
            legalName: Value(company.legalName),
            tradeName: Value(company.tradeName),
            confirmedName: Value(existing?.confirmedName),
            fiscalCnaeDescription: Value(company.fiscalCnaeDescription),
            city: Value(company.city),
            state: Value(company.state),
            preferredCategoryId: Value(existing?.preferredCategoryId),
            updatedAt: DateTime.now(),
          ),
        );
  }
}
