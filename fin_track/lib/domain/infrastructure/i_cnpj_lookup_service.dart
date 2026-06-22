import '../entities/company_data.dart';

abstract class ICnpjLookupService {
  Future<CompanyData?> lookup(String cnpj);
}

abstract class ILocalCnpjLookupService {
  Future<CompanyData?> lookupLocal(String cnpj);
}
