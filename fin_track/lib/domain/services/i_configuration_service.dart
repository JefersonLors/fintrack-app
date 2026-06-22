import '../entities/configuration.dart';
import '../entities/cloud_provider.dart';

abstract class IConfigurationService {
  Future<Configuration> load();
  Future<void> update(Configuration configuration);
  Future<void> linkCloud(CloudProvider provider);
  Future<void> unlinkCloud();
  Future<bool> verifyCloudToken();
  Future<void> linkGoogle();
  Future<void> unlinkGoogle();
  Future<bool> verifyGoogleToken();
  Future<void> configureAutomaticBackup({
    required bool active,
    required int intervalDays,
  });
  Future<void> normalizeAutomaticBackupIfNeeded();
  Future<int> calculateUsedSpaceBytes();
  Future<void> completeOnboarding();
  Future<void> resetOnboarding();
  Stream<Configuration> watch();
}
