import 'package:flutter/material.dart';

import '../../widgets/dialog_actions.dart';

Future<String?> requestBackupPassword(
  BuildContext context, {
  bool confirmation = false,
  String? title,
  String? message,
  String? actionLabel,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => BackupPasswordDialog(
      confirmation: confirmation,
      title: title,
      message: message,
      actionLabel: actionLabel,
    ),
  );
}

class BackupPasswordDialog extends StatefulWidget {
  const BackupPasswordDialog({
    super.key,
    required this.confirmation,
    this.title,
    this.message,
    this.actionLabel,
  });

  final bool confirmation;
  final String? title;
  final String? message;
  final String? actionLabel;

  @override
  State<BackupPasswordDialog> createState() => BackupPasswordDialogState();
}

class BackupPasswordDialogState extends State<BackupPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  var _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title ??
            (widget.confirmation ? 'Senha do backup' : 'Senha para restaurar'),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.message ??
                  'Guarde esta senha. Sem ela, não será possível restaurar o backup em outro dispositivo.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Senha',
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: _validatePassword,
            ),
            if (widget.confirmation) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmationController,
                obscureText: _obscure,
                decoration: const InputDecoration(labelText: 'Confirmar senha'),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'As senhas não conferem.';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        FinTrackDialogActions(
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: _confirm,
              child: Text(
                widget.actionLabel ??
                    (widget.confirmation ? 'Fazer backup' : 'Restaurar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.length < 8) {
      return 'Use pelo menos 8 caracteres.';
    }
    return null;
  }

  void _confirm() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(_passwordController.text);
  }
}
