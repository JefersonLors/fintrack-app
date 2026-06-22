import 'dart:typed_data';

import 'package:fin_track/infrastructure/cloud/google_drive_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleDriveService simulated', () {
    test('blocks operations without linked account', () async {
      final service = GoogleDriveService.simulated();

      expect(await service.verifyToken(), isFalse);
      await expectLater(
        service.upload([
          Uint8List.fromList([1]),
        ]),
        throwsA(isA<StateError>()),
      );
      await expectLater(service.download(), throwsA(isA<StateError>()));
      await expectLater(service.deleteBackup(), throwsA(isA<StateError>()));
    });

    test('links uploads copies downloads and deletes backup', () async {
      final service = GoogleDriveService.simulated();
      final account = await service.linkAccount();
      final bytes = Uint8List.fromList([1, 2, 3]);

      expect(account.email, 'usuario.fintrack@gmail.com');
      expect(await service.verifyToken(), isTrue);

      await service.upload([bytes]);
      bytes[0] = 9;

      var restored = await service.download();
      expect(restored, hasLength(1));
      expect(restored.single, [1, 2, 3]);

      restored.single[1] = 8;
      expect((await service.download()).single, [1, 2, 3]);

      await service.deleteBackup();
      expect(await service.download(), isEmpty);

      await service.unlinkAccount();
      expect(await service.verifyToken(), isFalse);
    });
  });
}
