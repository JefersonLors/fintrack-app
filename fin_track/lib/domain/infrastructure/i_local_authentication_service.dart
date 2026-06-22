import '../value_objects/biometric_status.dart';

abstract class ILocalAuthenticationService {
  Future<bool> savePin(String pin);

  Future<bool> authenticatePin(String pin);

  Future<bool> removePin();

  Future<BiometricStatus> checkBiometrics();

  Future<bool> authenticateBiometrics({
    required String title,
    required String subtitle,
  });
}
