import '../../domain/infrastructure/i_local_authentication_service.dart';
import '../../domain/value_objects/biometric_status.dart';
import '../image/fin_track_platform.dart';

class FinTrackLocalAuthenticationService
    implements ILocalAuthenticationService {
  const FinTrackLocalAuthenticationService();

  @override
  Future<bool> savePin(String pin) {
    return FinTrackPlatform.saveLocalPin(pin);
  }

  @override
  Future<bool> authenticatePin(String pin) {
    return FinTrackPlatform.authenticateLocalPin(pin);
  }

  @override
  Future<bool> removePin() {
    return FinTrackPlatform.removeLocalPin();
  }

  @override
  Future<BiometricStatus> checkBiometrics() {
    return FinTrackPlatform.checkBiometrics();
  }

  @override
  Future<bool> authenticateBiometrics({
    required String title,
    required String subtitle,
  }) {
    return FinTrackPlatform.authenticateBiometrics(
      title: title,
      subtitle: subtitle,
    );
  }
}
