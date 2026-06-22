part of 'configuration_page.dart';

extension _ConfigurationPageActions on _ConfigurationPageState {
  void _refreshSpace() {
    if (!mounted) {
      return;
    }
    _controller.refreshSpace(_calculateUpdatedSpace);
  }

  void _scrollToStorageSectionIfNeeded() {
    if (!widget.scrollToStorageSection ||
        !_controller.consumeStorageScrollRequest()) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _storageSectionKey.currentContext;
      if (!mounted || context == null) {
        return;
      }
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }

  Future<void> _changeThemeMode(
    Configuration configuration, {
    required bool lightTheme,
  }) async {
    await _controller.changeThemeMode(
      AppScope.of(context).configurationService,
      configuration,
      lightTheme: lightTheme,
    );
  }

  Future<void> _updateStorageLimit(
    Configuration configuration,
    int storageLimitMB,
  ) {
    return _controller.updateStorageLimit(
      AppScope.of(context).configurationService,
      configuration,
      storageLimitMB,
    );
  }

  Future<void> _changeAutoLockInterval(
    Configuration configuration,
    int minutes,
  ) {
    return _controller.updateAutoLockInterval(
      AppScope.of(context).configurationService,
      configuration,
      minutes,
    );
  }

  Future<void> _toggleLocalAuthentication(
    Configuration configuration, {
    required bool enable,
  }) async {
    final service = AppScope.of(context).configurationService;
    if (enable) {
      final result = await _controller.enableLocalAuthentication(
        service,
        configuration,
        selectMethod: () => selectAuthenticationMethodDialog(context),
        configureMethod: _configureMethod,
      );
      if (!mounted) {
        return;
      }
      final incompleteMethod = result.incompleteMethod;
      if (incompleteMethod != null) {
        _showIncompleteConfiguration(
          incompleteMethod,
          enablingAuthentication: true,
        );
        return;
      }
      if (result.changed) {
        _showMessage(
          AppScope.of(
            context,
          ).appConfig.ui.configuration.text('localAuthEnabled'),
        );
      }
      return;
    }

    final disabled = await _controller.disableLocalAuthentication(
      service,
      configuration,
      authenticate: (config) => _authenticateLocalAuth(
        config,
        AppScope.of(
          context,
        ).appConfig.ui.configuration.text('disableLocalAuthReason'),
      ),
      removePin: () => LocalAuthFlow.removePin(context),
    );
    if (!mounted || !disabled) {
      return;
    }
    _showMessage(
      AppScope.of(context).appConfig.ui.configuration.text('localAuthDisabled'),
    );
  }

  Future<void> _configureAutomaticBackup({
    required bool active,
    required int intervalDays,
  }) async {
    final service = AppScope.of(context).configurationService;
    final configurationText = AppScope.of(context).appConfig.ui.configuration;
    try {
      await _controller.configureAutomaticBackup(
        service,
        active: active,
        intervalDays: intervalDays,
      );
      if (mounted) {
        _showMessage(
          active
              ? configurationText.text('backupAutoEnabled')
              : configurationText.text('backupAutoDisabled'),
        );
      }
    } catch (error, stackTrace) {
      recordHandledError(
        error,
        stackTrace,
        diagnosticContext: 'Falha ao configurar backup automático',
      );
      if (mounted) {
        _showMessage(configurationText.text('backupAutoFailed'));
      }
    }
  }

  Future<void> _configureBackupPassword(Configuration configuration) async {
    final password = await configureBackupPasswordDialog(
      context,
      configuration,
    );
    if (!mounted || password == null) {
      return;
    }

    await _controller.updateBackupPassword(
      AppScope.of(context).configurationService,
      configuration,
      password,
    );
    if (mounted) {
      _showMessage(
        AppScope.of(
          context,
        ).appConfig.ui.configuration.text('backupPasswordUpdated'),
      );
    }
  }

  Future<void> _removeBackupPassword(Configuration configuration) async {
    final confirm = await confirmRemoveBackupPasswordDialog(
      context,
      configuration,
    );
    if (!mounted || !confirm) {
      return;
    }

    await _controller.removeBackupPassword(
      AppScope.of(context).configurationService,
      configuration,
    );
    if (mounted) {
      _showMessage(
        AppScope.of(
          context,
        ).appConfig.ui.configuration.text('backupPasswordRemoved'),
      );
    }
  }

  void _openBackup() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const BackupPage()));
  }

  Future<void> _confirmExit() async {
    if (await confirmApplicationExit(context)) {
      SystemNavigator.pop();
    }
  }

  Future<void> _changeAuthenticationMethod(
    Configuration configuration,
    AuthenticationType? method, {
    bool forceConfiguration = false,
  }) async {
    if (method == null) {
      return;
    }
    final result = await _controller.changeAuthenticationMethod(
      AppScope.of(context).configurationService,
      configuration,
      method,
      forceConfiguration: forceConfiguration,
      authenticate: (config) => _authenticateLocalAuth(
        config,
        AppScope.of(
          context,
        ).appConfig.ui.configuration.text('changeAuthReason'),
      ),
      configureMethod: _configureMethod,
      removePin: () => LocalAuthFlow.removePin(context),
    );
    if (!mounted) {
      return;
    }
    final incompleteMethod = result.incompleteMethod;
    if (incompleteMethod != null) {
      _showIncompleteConfiguration(
        incompleteMethod,
        enablingAuthentication: false,
      );
      return;
    }
    if (result.changed) {
      _showMessage(
        AppScope.of(
          context,
        ).appConfig.ui.configuration.text('authMethodUpdated'),
      );
    }
  }

  Future<bool> _configureMethod(AuthenticationType method) {
    return switch (method) {
      AuthenticationType.pin => LocalAuthFlow.createPin(context),
      AuthenticationType.biometric => LocalAuthFlow.configureBiometrics(
        context,
      ),
    };
  }

  Future<bool> _authenticateLocalAuth(
    Configuration configuration,
    String reason,
  ) {
    return LocalAuthFlow.authenticate(context, configuration, reason: reason);
  }

  Future<void> _resetOnboarding() async {
    await _controller.resetOnboarding(
      AppScope.of(context).configurationService,
    );
  }

  void _openAbout() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AboutFinTrackPage()));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showIncompleteConfiguration(
    AuthenticationType method, {
    required bool enablingAuthentication,
  }) {
    if (method == AuthenticationType.biometric) {
      return;
    }
    _showMessage(
      enablingAuthentication
          ? AppScope.of(
              context,
            ).appConfig.ui.configuration.text('pinConfigIncompleteEnable')
          : AppScope.of(
              context,
            ).appConfig.ui.configuration.text('pinConfigIncompleteKeep'),
    );
  }
}
