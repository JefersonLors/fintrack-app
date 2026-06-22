import 'package:flutter/material.dart';

import '../../widgets/app_scope.dart';
import '../../widgets/destructive_filled_button.dart';
import '../../widgets/dialog_actions.dart';

class BackupPasswordSettingsDialog extends StatefulWidget {
  const BackupPasswordSettingsDialog({
    super.key,
    required this.currentPasswordDefined,
    required this.currentPassword,
  });

  final bool currentPasswordDefined;
  final String? currentPassword;

  @override
  State<BackupPasswordSettingsDialog> createState() =>
      BackupPasswordSettingsDialogState();
}

class BackupPasswordSettingsDialogState
    extends State<BackupPasswordSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmationController = TextEditingController();
  var _obscure = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commonText = AppScope.of(context).appConfig.ui.common;
    final text = AppScope.of(context).appConfig.ui.configuration;
    return AlertDialog(
      title: Text(
        widget.currentPasswordDefined
            ? text.text('changeBackupPasswordTitle')
            : text.text('setBackupPasswordTitle'),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text.text('backupPasswordHelp')),
              const SizedBox(height: 16),
              if (widget.currentPasswordDefined) ...[
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: text.text('currentPassword'),
                  ),
                  validator: (value) {
                    if (value != widget.currentPassword) {
                      return text.text('wrongCurrentPassword');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: text.text('newPassword'),
                  suffixIcon: IconButton(
                    tooltip: _obscure
                        ? text.text('showPassword')
                        : text.text('hidePassword'),
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: _validateNewPassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmationController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: text.text('confirmNewPassword'),
                ),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return text.text('passwordMismatch');
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        FinTrackDialogActions(
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(commonText.cancel),
            ),
            FilledButton(onPressed: _save, child: Text(commonText.save)),
          ],
        ),
      ],
    );
  }

  String? _validateNewPassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.length < 8) {
      return AppScope.of(
        context,
      ).appConfig.ui.configuration.text('passwordTooShort');
    }
    if (widget.currentPasswordDefined && password == widget.currentPassword) {
      return AppScope.of(
        context,
      ).appConfig.ui.configuration.text('passwordSameAsCurrent');
    }
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(_newPasswordController.text);
  }
}

class RemoveBackupPasswordDialog extends StatefulWidget {
  const RemoveBackupPasswordDialog({super.key, required this.currentPassword});

  final String currentPassword;

  @override
  State<RemoveBackupPasswordDialog> createState() =>
      RemoveBackupPasswordDialogState();
}

class RemoveBackupPasswordDialogState
    extends State<RemoveBackupPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  var _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commonText = AppScope.of(context).appConfig.ui.common;
    final text = AppScope.of(context).appConfig.ui.configuration;
    return AlertDialog(
      title: Text(text.text('removeBackupPasswordTitle')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text.text('removeBackupPasswordMessage')),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: text.text('currentPassword'),
                  suffixIcon: IconButton(
                    tooltip: _obscure
                        ? text.text('showPassword')
                        : text.text('hidePassword'),
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value != widget.currentPassword) {
                    return text.text('wrongCurrentPassword');
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        FinTrackDialogActions(
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(commonText.cancel),
            ),
            FilledButton(
              style: destructiveFilledButtonStyle(context),
              onPressed: _remove,
              child: Text(text.text('remove')),
            ),
          ],
        ),
      ],
    );
  }

  void _remove() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(true);
  }
}
