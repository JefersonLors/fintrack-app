import 'package:fin_track/domain/exceptions/storage_limit_exception.dart';
import 'package:fin_track/domain/exceptions/operation_cancelled_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('exceptions', () {
    test('storage limit preserves FormatException contract', () {
      const exception = StorageLimitException('limite atingido');

      expect(exception, isA<FormatException>());
      expect(exception.message, 'limite atingido');
      expect(exception.source, isNull);
      expect(exception.offset, isNull);
      expect(exception.toString(), 'limite atingido');
    });

    test(
      'cancelled operation uses defaultException message and identification helper',
      () {
        const defaultException = OperationCancelledException();
        const customException = OperationCancelledException(
          'Scanner cancelado.',
        );

        expect(defaultException.message, 'Operação cancelada.');
        expect(defaultException.toString(), 'Operação cancelada.');
        expect(customException.message, 'Scanner cancelado.');
        expect(isOperationCancelled(customException), isTrue);
        expect(isOperationCancelled(StateError('other error')), isFalse);
      },
    );
  });
}
