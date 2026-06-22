import 'package:flutter/material.dart';

import '../../../domain/entities/configuration.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/dialog_actions.dart';
import 'backup_password_settings_dialog.dart';

Future<void> showAutomaticBackupPasswordRequiredDialog(BuildContext context) {
  final text = AppScope.of(context).appConfig.ui.configuration;
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(text.text('passwordRequiredTitle')),
      content: Text(text.text('passwordRequiredMessage')),
      actions: [
        FinTrackDialogActions(
          children: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ok'),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<bool> confirmApplicationExit(BuildContext context) async {
  final commonText = AppScope.of(context).appConfig.ui.common;
  final text = AppScope.of(context).appConfig.ui.configuration;
  final exit = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(text.text('exitTitle')),
        content: Text(text.text('exitMessage')),
        actions: [
          FinTrackDialogActions(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(commonText.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(text.text('exitAction')),
              ),
            ],
          ),
        ],
      );
    },
  );
  return exit == true;
}

Future<AuthenticationType?> selectAuthenticationMethodDialog(
  BuildContext context,
) {
  final text = AppScope.of(context).appConfig.ui.configuration;
  return showDialog<AuthenticationType>(
    context: context,
    builder: (context) {
      return SimpleDialog(
        title: Text(text.text('chooseProtection')),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(AuthenticationType.pin),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.pin_outlined),
              title: const Text('PIN'),
              subtitle: Text(text.text('pinSubtitle')),
            ),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.of(context).pop(AuthenticationType.biometric),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.fingerprint),
              title: Text(text.text('biometric')),
              subtitle: Text(text.text('biometricSubtitle')),
            ),
          ),
        ],
      );
    },
  );
}

Future<String?> configureBackupPasswordDialog(
  BuildContext context,
  Configuration configuration,
) {
  return showDialog<String>(
    context: context,
    builder: (context) => BackupPasswordSettingsDialog(
      currentPasswordDefined: configuration.hasBackupPassword,
      currentPassword: configuration.backupPassword,
    ),
  );
}

Future<bool> confirmRemoveBackupPasswordDialog(
  BuildContext context,
  Configuration configuration,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => RemoveBackupPasswordDialog(
      currentPassword: configuration.backupPassword ?? '',
    ),
  );
  return confirm == true;
}
