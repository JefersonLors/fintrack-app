import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/infrastructure/i_secure_secrets.dart';

class FlutterSecureSecrets implements ISecureSecrets {
  FlutterSecureSecrets({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const _backupPasswordKey = 'fintrack.backup.password';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readBackupPassword() {
    return _storage.read(key: _backupPasswordKey);
  }

  @override
  Future<void> saveBackupPassword(String? password) {
    return _storage.write(
      key: _backupPasswordKey,
      value: password?.isEmpty == true ? null : password,
    );
  }
}
