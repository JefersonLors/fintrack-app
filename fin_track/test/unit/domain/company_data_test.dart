import 'package:fin_track/domain/entities/company_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preferredName prioritizes confirmed trade and legal names', () {
    expect(
      const CompanyData(
        cnpj: '123',
        confirmedName: '  Nome validado  ',
        tradeName: 'Fantasia',
        legalName: 'Razao',
      ).preferredName,
      'Nome validado',
    );
    expect(
      const CompanyData(
        cnpj: '123',
        confirmedName: ' ',
        tradeName: '  Fantasia  ',
        legalName: 'Razao',
      ).preferredName,
      'Fantasia',
    );
    expect(
      const CompanyData(
        cnpj: '123',
        tradeName: '',
        legalName: '  Razao Social  ',
      ).preferredName,
      'Razao Social',
    );
    expect(const CompanyData(cnpj: '123').preferredName, isNull);
  });

  test('keeps complementary registration data', () {
    const extractedData = CompanyData(
      cnpj: '11222333000181',
      legalName: 'Empresa LTDA',
      tradeName: 'Empresa',
      fiscalCnaeDescription: 'Comercio',
      city: 'Salvador',
      state: 'BA',
    );

    expect(extractedData.cnpj, '11222333000181');
    expect(extractedData.fiscalCnaeDescription, 'Comercio');
    expect(extractedData.city, 'Salvador');
    expect(extractedData.state, 'BA');
  });
}
