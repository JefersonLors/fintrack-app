import 'package:flutter/foundation.dart';

import '../../../domain/entities/configuration.dart';
import '../../../domain/services/i_receipt_service.dart';
import '../../../domain/services/i_configuration_service.dart';

typedef AuthenticationMethodSelector = Future<AuthenticationType?> Function();
typedef AuthenticationConfigurer =
    Future<bool> Function(AuthenticationType method);
typedef AuthenticationVerifier = Future<bool> Function(Configuration config);
typedef PinRemover = Future<bool> Function();

class AuthenticationFlowResult {
  const AuthenticationFlowResult._({
    required this.changed,
    this.incompleteMethod,
  });

  const AuthenticationFlowResult.unchanged() : this._(changed: false);
  const AuthenticationFlowResult.changed() : this._(changed: true);
  const AuthenticationFlowResult.incomplete(AuthenticationType method)
    : this._(changed: false, incompleteMethod: method);

  final bool changed;
  final AuthenticationType? incompleteMethod;
}

class ConfigurationController extends ChangeNotifier {
  Future<int>? _spaceFuture;
  var cloudVerificationRequested = false;
  var storageScrollRequested = false;

  Future<int>? get spaceFuture => _spaceFuture;

  void configureSpaceFuture(Future<int> Function() loader) {
    _spaceFuture ??= loader();
  }

  void refreshSpace(Future<int> Function() loader) {
    _spaceFuture = loader();
    notifyListeners();
  }

  Future<int> calculateUpdatedSpace({
    required IReceiptService receiptService,
    required IConfigurationService configurationService,
  }) async {
    await receiptService.deleteOrphanFiles();
    return configurationService.calculateUsedSpaceBytes();
  }

  Future<void> verifyCloudToken(IConfigurationService service) {
    return service.verifyCloudToken();
  }

  Future<void> changeThemeMode(
    IConfigurationService service,
    Configuration configuration, {
    required bool lightTheme,
  }) async {
    final mode = lightTheme ? VisualThemeMode.light : VisualThemeMode.dark;
    if (configuration.visualThemeMode == mode) {
      return;
    }
    await service.update(configuration.copyWith(visualThemeMode: mode));
  }

  Future<void> configureAutomaticBackup(
    IConfigurationService service, {
    required bool active,
    required int intervalDays,
  }) {
    return service.configureAutomaticBackup(
      active: active,
      intervalDays: intervalDays,
    );
  }

  Future<void> updateBackupPassword(
    IConfigurationService service,
    Configuration configuration,
    String password,
  ) {
    return service.update(configuration.copyWith(backupPassword: password));
  }

  Future<void> removeBackupPassword(
    IConfigurationService service,
    Configuration configuration,
  ) async {
    await service.configureAutomaticBackup(
      active: false,
      intervalDays: configuration.reminderIntervalDays,
    );
    await service.update(
      configuration.copyWith(
        clearBackupPassword: true,
        backupReminderEnabled: false,
      ),
    );
  }

  Future<void> updateStorageLimit(
    IConfigurationService service,
    Configuration configuration,
    int storageLimitMB,
  ) {
    return service.update(
      configuration.copyWith(storageLimitMB: storageLimitMB),
    );
  }

  Future<void> updateAutoLockInterval(
    IConfigurationService service,
    Configuration configuration,
    int minutes,
  ) {
    return service.update(
      configuration.copyWith(autoLockIntervalMinutes: minutes),
    );
  }

  Future<void> resetOnboarding(IConfigurationService service) {
    return service.resetOnboarding();
  }

  Future<AuthenticationFlowResult> enableLocalAuthentication(
    IConfigurationService service,
    Configuration configuration, {
    required AuthenticationMethodSelector selectMethod,
    required AuthenticationConfigurer configureMethod,
  }) async {
    final method = await selectMethod();
    if (method == null) {
      return const AuthenticationFlowResult.unchanged();
    }
    final configured = await configureMethod(method);
    if (!configured) {
      return AuthenticationFlowResult.incomplete(method);
    }
    await service.update(
      configuration.copyWith(
        localAuthEnabled: true,
        authenticationType: method,
      ),
    );
    return const AuthenticationFlowResult.changed();
  }

  Future<bool> disableLocalAuthentication(
    IConfigurationService service,
    Configuration configuration, {
    required AuthenticationVerifier authenticate,
    required PinRemover removePin,
  }) async {
    final authenticated = await authenticate(configuration);
    if (!authenticated) {
      return false;
    }
    await removePin();
    await service.update(
      configuration.copyWith(
        localAuthEnabled: false,
        clearAuthenticationType: true,
      ),
    );
    return true;
  }

  Future<AuthenticationFlowResult> changeAuthenticationMethod(
    IConfigurationService service,
    Configuration configuration,
    AuthenticationType method, {
    required bool forceConfiguration,
    required AuthenticationVerifier authenticate,
    required AuthenticationConfigurer configureMethod,
    required PinRemover removePin,
  }) async {
    if (!forceConfiguration && method == configuration.authenticationType) {
      return const AuthenticationFlowResult.unchanged();
    }

    if (configuration.authenticationType != null) {
      final authenticated = await authenticate(configuration);
      if (!authenticated) {
        return const AuthenticationFlowResult.unchanged();
      }
    }

    final configured = await configureMethod(method);
    if (!configured) {
      return AuthenticationFlowResult.incomplete(method);
    }

    if (method == AuthenticationType.biometric) {
      await removePin();
    }
    await service.update(configuration.copyWith(authenticationType: method));
    return const AuthenticationFlowResult.changed();
  }

  bool consumeCloudVerificationRequest() {
    if (cloudVerificationRequested) {
      return false;
    }
    cloudVerificationRequested = true;
    return true;
  }

  bool consumeStorageScrollRequest() {
    if (storageScrollRequested) {
      return false;
    }
    storageScrollRequested = true;
    return true;
  }
}
