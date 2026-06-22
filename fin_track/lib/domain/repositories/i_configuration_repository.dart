import '../entities/configuration.dart';

abstract class IConfigurationRepository {
  Future<Configuration> load();
  Future<void> save(Configuration configuration);
  Stream<Configuration> watch();
}
