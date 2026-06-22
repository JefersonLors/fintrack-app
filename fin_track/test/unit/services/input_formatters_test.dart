import 'package:fin_track/presentation/widgets/input_formatters.dart';
import 'package:fin_track/presentation/widgets/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CurrencyMaskInputFormatter applies Brazilian currency mask', () {
    const formatter = CurrencyMaskInputFormatter();

    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '123456'),
    );

    expect(result.text, '1.234,56');

    expect(
      const CurrencyMaskInputFormatter(maxDigits: 4)
          .formatEditUpdate(result, const TextEditingValue(text: 'abc123456'))
          .text,
      '12,34',
    );
    expect(
      formatter.formatEditUpdate(result, const TextEditingValue(text: 'abc')),
      TextEditingValue.empty,
    );
  });

  testWidgets('formatters apply currency date time and confidence', (
    tester,
  ) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(formatCurrency(null), 'R\$ --');
    expect(formatCurrency(-1234.5), '-R\$ 1.234,50');
    expect(formatDate(null), '--/--/----');
    expect(formatDate(DateTime(2026, 5, 3)), '03/05/2026');
    expect(formatDateTime(DateTime(2026, 5, 3, 7, 8)), '03/05/2026 07:08');
    expect(
      confidenceColor(capturedContext, 0.2),
      Theme.of(capturedContext).colorScheme.error,
    );
    expect(
      confidenceColor(capturedContext, 0.9),
      Theme.of(capturedContext).colorScheme.primary,
    );
  });
}
