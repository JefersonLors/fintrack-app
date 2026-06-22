import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/configuration.dart';
import '../../../infrastructure/diagnostics/error_handling.dart';
import '../../authentication/local_auth_flow.dart';
import '../../backup/pages/backup_page.dart';
import '../../theme/fin_track_theme.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/fin_track_page_header.dart';
import '../../widgets/state_views.dart';
import '../controllers/configuration_controller.dart';
import '../about_fin_track_page.dart';
import '../widgets/configuration_action_widgets.dart';
import '../widgets/configuration_dialogs.dart';
import '../widgets/configuration_page_sections.dart';

part 'configuration_page_actions.dart';

class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({
    super.key,
    this.isActive = true,
    this.scrollToStorageSection = false,
  });

  final bool isActive;
  final bool scrollToStorageSection;

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  final _storageSectionKey = GlobalKey();
  late final ConfigurationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfigurationController()..addListener(_onControllerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = AppScope.of(context).configurationService;
    _controller.configureSpaceFuture(_calculateUpdatedSpace);
    if (_controller.consumeCloudVerificationRequest()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.verifyCloudToken(service);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant ConfigurationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _refreshSpace();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    final service = deps.configurationService;
    final configurationText = deps.appConfig.ui.configuration;
    return StreamBuilder<Configuration>(
      stream: service.watch(),
      builder: (context, snapshot) {
        final configuration = snapshot.data;
        return Scaffold(
          appBar: FinTrackPageHeader(
            title: Text(configurationText.text('title')),
            actions: [
              if (configuration != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: ThemeModeToggle(
                      lightModeSelected:
                          configuration.visualThemeMode ==
                          VisualThemeMode.light,
                      onChanged: (value) {
                        _changeThemeMode(configuration, lightTheme: value);
                      },
                    ),
                  ),
                ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return LoadingView(message: configurationText.text('loading'));
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return ErrorStateView(
                  message: configurationText.text('loadError'),
                  onRetry: () => setState(() {}),
                );
              }

              final configuration = snapshot.data!;
              final settingsAccent = context.finTrackColors.neutralAccent;
              _scrollToStorageSectionIfNeeded();
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  ConfigurationBackupSection(
                    configuration: configuration,
                    color: settingsAccent,
                    onOpenBackup: _openBackup,
                    onConfigurePassword: () =>
                        _configureBackupPassword(configuration),
                    onRemovePassword: () =>
                        _removeBackupPassword(configuration),
                    onConfigureAutomaticBackup: _configureAutomaticBackup,
                    onRequirePassword: () =>
                        showAutomaticBackupPasswordRequiredDialog(context),
                  ),
                  ConfigurationStorageSection(
                    key: _storageSectionKey,
                    configuration: configuration,
                    color: settingsAccent,
                    spaceFuture:
                        _controller.spaceFuture ?? _calculateUpdatedSpace(),
                    onRefresh: _refreshSpace,
                    onStorageLimitChanged: (value) =>
                        _updateStorageLimit(configuration, value),
                  ),
                  ConfigurationAuthenticationSection(
                    configuration: configuration,
                    color: settingsAccent,
                    onToggleLocalAuthentication: (value) =>
                        _toggleLocalAuthentication(
                          configuration,
                          enable: value,
                        ),
                    onAuthenticationMethodChanged:
                        (value, {forceConfiguration = false}) =>
                            _changeAuthenticationMethod(
                              configuration,
                              value,
                              forceConfiguration: forceConfiguration,
                            ),
                    onAutoLockChanged: (value) =>
                        _changeAutoLockInterval(configuration, value),
                  ),
                  ConfigurationInfoSection(
                    color: settingsAccent,
                    onResetOnboarding: _resetOnboarding,
                    onOpenAbout: _openAbout,
                    onExit: _confirmExit,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<int> _calculateUpdatedSpace() async {
    final deps = AppScope.of(context);
    return _controller.calculateUpdatedSpace(
      receiptService: deps.receiptService,
      configurationService: deps.configurationService,
    );
  }
}
