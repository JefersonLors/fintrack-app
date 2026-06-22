import 'package:fin_track/presentation/widgets/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatCurrency applies Brazilian thousands separator and cents', () {
    expect(formatCurrency(1234.56), 'R\$ 1.234,56');
    expect(formatCurrency(42), 'R\$ 42,00');
  });

  test('formatCurrency preserves empty state', () {
    expect(formatCurrency(null), 'R\$ --');
  });
}
