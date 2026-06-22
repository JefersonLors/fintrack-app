import 'package:fin_track/domain/value_objects/establishment_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes establishment name with uppercase initials', () {
    expect(
      normalizeEstablishmentName('POSTO MATARIPE BONOCÔ'),
      'Posto Mataripe Bonocô',
    );
  });

  test('removes extra spaces and preserves empty string without name', () {
    expect(
      normalizeEstablishmentName('  MERCADO   CENTRAL  '),
      'Mercado Central',
    );
    expect(normalizeEstablishmentName('   '), '');
    expect(normalizeEstablishmentName(null), isNull);
  });

  test('preserves already reviewed names and known acronyms', () {
    expect(
      normalizeEstablishmentName('Mercado Fonte API'),
      'Mercado Fonte API',
    );
    expect(
      normalizeEstablishmentName('Texto estruturado corrigido'),
      'Texto estruturado corrigido',
    );
  });
}
