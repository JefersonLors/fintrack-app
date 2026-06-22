import '../../domain/infrastructure/i_secure_secrets.dart';

class MemorySecureSecrets implements ISecureSecrets {
  MemorySecureSecrets({String? backupPassword})
    : _backupPassword = backupPassword;

  String? _backupPassword;

  @override
  Future<String?> readBackupPassword() async {
    return _backupPassword;
  }

  @override
  Future<void> saveBackupPassword(String? password) async {
    _backupPassword = password?.isEmpty == true ? null : password;
  }
}
