abstract class ISecureSecrets {
  Future<String?> readBackupPassword();
  Future<void> saveBackupPassword(String? password);
}
