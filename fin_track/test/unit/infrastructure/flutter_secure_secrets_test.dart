import 'package:fin_track/infrastructure/security/flutter_secure_secrets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const backupPasswordKey = 'fintrack.backup.password';

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('reads backup password using expected key', () async {
    FlutterSecureStorage.setMockInitialValues({
      backupPasswordKey: 'password-already-saved',
    });
    final secrets = FlutterSecureSecrets();

    expect(await secrets.readBackupPassword(), 'password-already-saved');
  });

  test('saves filled password to secure storage', () async {
    final storage = const FlutterSecureStorage();
    final secrets = FlutterSecureSecrets(storage: storage);

    await secrets.saveBackupPassword('password-segura');

    expect(await storage.read(key: backupPasswordKey), 'password-segura');
  });

  test('empty or null password clears stored value', () async {
    final storage = const FlutterSecureStorage();
    final secrets = FlutterSecureSecrets(storage: storage);

    await secrets.saveBackupPassword('password-segura');
    await secrets.saveBackupPassword('');
    expect(await storage.read(key: backupPasswordKey), isNull);

    await secrets.saveBackupPassword('outra-password');
    await secrets.saveBackupPassword(null);
    expect(await storage.read(key: backupPasswordKey), isNull);
  });
}
