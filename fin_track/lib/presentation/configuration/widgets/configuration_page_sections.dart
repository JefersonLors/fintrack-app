import 'package:flutter/material.dart';

import '../../../domain/entities/configuration.dart';
import '../../widgets/app_dropdown_field.dart';
import '../../widgets/app_scope.dart';
import 'configuration_action_widgets.dart';
import 'configuration_section_widgets.dart';

const double configurationDropdownMenuMaxHeight = 280;

class ConfigurationBackupSection extends StatelessWidget {
  const ConfigurationBackupSection({
    super.key,
    required this.configuration,
    required this.color,
    required this.onOpenBackup,
    required this.onConfigurePassword,
    required this.onRemovePassword,
    required this.onConfigureAutomaticBackup,
    required this.onRequirePassword,
  });

  final Configuration configuration;
  final Color color;
  final VoidCallback onOpenBackup;
  final VoidCallback onConfigurePassword;
  final VoidCallback onRemovePassword;
  final Future<void> Function({required bool active, required int intervalDays})
  onConfigureAutomaticBackup;
  final VoidCallback onRequirePassword;

  @override
  Widget build(BuildContext context) {
    final text = AppScope.of(context).appConfig.ui.configuration;
    final automaticBackupAvailable =
        configuration.linkedCloudAccount != null &&
        configuration.cloudTokenValid &&
        configuration.hasBackupPassword;
    final automaticBackupActive =
        automaticBackupAvailable && configuration.backupReminderEnabled;
    final automaticBackupBlockedByPassword = !configuration.hasBackupPassword;
    final automaticBackupBlockedByAccount =
        configuration.hasBackupPassword && !automaticBackupAvailable;
    final currentInterval = Configuration.validBackupReminderIntervalDays(
      configuration.reminderIntervalDays,
    );
    final intervalIndex = Configuration.backupReminderIntervalDayOptions
        .indexOf(currentInterval)
        .clamp(0, Configuration.backupReminderIntervalDayOptions.length - 1);

    return SettingsSection(
      title: text.text('backupSection'),
      icon: Icons.cloud_upload_outlined,
      color: color,
      children: [
        ListTile(
          leading: SettingsIcon(Icons.cloud_upload_outlined, color: color),
          title: Text(AppScope.of(context).appConfig.ui.common.backup),
          subtitle: Text(text.text('backupSubtitle')),
          trailing: const Icon(Icons.chevron_right),
          onTap: onOpenBackup,
        ),
        ListTile(
          leading: SettingsIcon(Icons.password_outlined, color: color),
          title: Text(text.text('backupPassword')),
          subtitle: Text(
            configuration.hasBackupPassword
                ? text.text('backupPasswordDefined')
                : text.text('backupPasswordDefine'),
          ),
          trailing: const Icon(Icons.lock_outline),
          onTap: onConfigurePassword,
        ),
        if (configuration.hasBackupPassword)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: onRemovePassword,
                icon: const Icon(Icons.lock_open_outlined),
                label: Text(text.text('removePassword')),
              ),
            ),
          ),
        SwitchListTile(
          value: automaticBackupActive,
          secondary: SettingsIcon(Icons.cloud_sync_outlined, color: color),
          title: Text(text.text('automaticBackup')),
          subtitle: Text(text.text('automaticBackupSubtitle')),
          onChanged: automaticBackupAvailable
              ? (value) => onConfigureAutomaticBackup(
                  active: value,
                  intervalDays: currentInterval,
                )
              : automaticBackupBlockedByPassword
              ? (_) => onRequirePassword()
              : null,
        ),
        if (automaticBackupBlockedByAccount)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onOpenBackup,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(text.text('openBackup')),
              ),
            ),
          ),
        ListTile(
          leading: SettingsIcon(Icons.event_repeat_outlined, color: color),
          title: Text(text.text('automaticBackupInterval')),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Configuration.backupReminderIntervalLabel(currentInterval)),
              const SizedBox(height: 6),
              Slider(
                value: intervalIndex.toDouble(),
                padding: EdgeInsets.zero,
                min: 0,
                max: (Configuration.backupReminderIntervalDayOptions.length - 1)
                    .toDouble(),
                divisions:
                    Configuration.backupReminderIntervalDayOptions.length - 1,
                label: Configuration.backupReminderIntervalLabel(
                  currentInterval,
                ),
                onChanged: automaticBackupActive ? (_) {} : null,
                onChangeEnd: automaticBackupActive
                    ? (value) {
                        final index = value.round();
                        final interval = Configuration
                            .backupReminderIntervalDayOptions[index];
                        onConfigureAutomaticBackup(
                          active: true,
                          intervalDays: interval,
                        );
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ConfigurationStorageSection extends StatelessWidget {
  const ConfigurationStorageSection({
    super.key,
    required this.configuration,
    required this.color,
    required this.spaceFuture,
    required this.onRefresh,
    required this.onStorageLimitChanged,
  });

  final Configuration configuration;
  final Color color;
  final Future<int> spaceFuture;
  final VoidCallback onRefresh;
  final ValueChanged<int> onStorageLimitChanged;

  @override
  Widget build(BuildContext context) {
    final text = AppScope.of(context).appConfig.ui.configuration;
    return SettingsSection(
      title: text.text('storageSection'),
      icon: Icons.storage_outlined,
      color: color,
      children: [
        StorageTile(
          future: spaceFuture,
          limitMb: configuration.storageLimitMB,
          onRefresh: onRefresh,
        ),
        ListTile(
          leading: SettingsIcon(
            Icons.storage_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          title: Text(text.text('storageLimit')),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Slider(
                value: configuration.storageLimitMB.toDouble(),
                padding: EdgeInsets.zero,
                min: 2,
                max: 2000,
                label: '${configuration.storageLimitMB} MB',
                onChanged: (value) {
                  final limit = ((value / 10).round() * 10)
                      .clamp(2, 2000)
                      .toInt();
                  onStorageLimitChanged(limit);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ConfigurationAuthenticationSection extends StatelessWidget {
  const ConfigurationAuthenticationSection({
    super.key,
    required this.configuration,
    required this.color,
    required this.onToggleLocalAuthentication,
    required this.onAuthenticationMethodChanged,
    required this.onAutoLockChanged,
  });

  final Configuration configuration;
  final Color color;
  final Future<void> Function(bool enabled) onToggleLocalAuthentication;
  final Future<void> Function(
    AuthenticationType? method, {
    bool forceConfiguration,
  })
  onAuthenticationMethodChanged;
  final ValueChanged<int> onAutoLockChanged;

  @override
  Widget build(BuildContext context) {
    final text = AppScope.of(context).appConfig.ui.configuration;
    return SettingsSection(
      title: text.text('authSection'),
      icon: Icons.lock_outline,
      color: color,
      children: [
        SwitchListTile(
          value: configuration.localAuthEnabled,
          secondary: SettingsIcon(Icons.lock_outline, color: color),
          title: Text(text.text('localAuth')),
          subtitle: Text(
            configuration.authenticationType?.label ??
                text.text('localAuthSubtitle'),
          ),
          onChanged: onToggleLocalAuthentication,
        ),
        if (configuration.localAuthEnabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AppDropdownField<AuthenticationType>(
              initialValue: configuration.authenticationType,
              menuMaxHeight: configurationDropdownMenuMaxHeight,
              hint: Text(text.text('selectMethod')),
              decoration: InputDecoration(
                labelText: text.text('authType'),
                prefixIcon: Icon(Icons.verified_user_outlined, color: color),
              ),
              items: AuthenticationType.values
                  .map(
                    (type) => DropdownMenuItem<AuthenticationType>(
                      value: type,
                      child: Text(
                        type.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onAuthenticationMethodChanged,
            ),
          ),
        if (configuration.localAuthEnabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AppDropdownField<int>(
              initialValue: Configuration.validAutoLockIntervalMinutes(
                configuration.autoLockIntervalMinutes,
              ),
              menuMaxHeight: configurationDropdownMenuMaxHeight,
              decoration: InputDecoration(
                labelText: text.text('autoLock'),
                prefixIcon: Icon(Icons.timer_outlined, color: color),
              ),
              items: Configuration.autoLockIntervalMinuteOptions
                  .map(
                    (minutes) => DropdownMenuItem<int>(
                      value: minutes,
                      child: Text(Configuration.autoLockIntervalLabel(minutes)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onAutoLockChanged(value);
                }
              },
            ),
          ),
        if (configuration.localAuthEnabled &&
            configuration.authenticationType == AuthenticationType.pin)
          ListTile(
            leading: SettingsIcon(Icons.pin_outlined, color: color),
            title: Text(text.text('changePin')),
            subtitle: Text(text.text('changePinSubtitle')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onAuthenticationMethodChanged(
              AuthenticationType.pin,
              forceConfiguration: true,
            ),
          ),
      ],
    );
  }
}

class ConfigurationInfoSection extends StatelessWidget {
  const ConfigurationInfoSection({
    super.key,
    required this.color,
    required this.onResetOnboarding,
    required this.onOpenAbout,
    required this.onExit,
  });

  final Color color;
  final VoidCallback onResetOnboarding;
  final VoidCallback onOpenAbout;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final text = AppScope.of(context).appConfig.ui.configuration;
    return SettingsSection(
      title: text.text('infoSection'),
      icon: Icons.info_outline,
      color: color,
      showDivider: false,
      children: [
        ListTile(
          leading: SettingsIcon(Icons.school_outlined, color: color),
          title: Text(text.text('viewTutorial')),
          subtitle: Text(text.text('viewTutorialSubtitle')),
          trailing: const Icon(Icons.chevron_right),
          onTap: onResetOnboarding,
        ),
        ListTile(
          leading: SettingsIcon(Icons.info_outline, color: color),
          title: Text(text.text('aboutTitle')),
          subtitle: Text(text.text('aboutSubtitle')),
          trailing: const Icon(Icons.chevron_right),
          onTap: onOpenAbout,
        ),
        ExitTile(onTap: onExit),
      ],
    );
  }
}
