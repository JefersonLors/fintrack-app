import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/configuration.dart';
import '../../infrastructure/diagnostics/user_error_message.dart';
import '../widgets/dialog_actions.dart';
import '../widgets/app_scope.dart';

class LocalAuthFlow {
  const LocalAuthFlow._();

  static Future<bool> createPin(BuildContext context) async {
    final auth = AppScope.of(context).localAuthenticationService;
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PinCreationDialog(),
    );
    if (pin == null || !context.mounted) {
      return false;
    }

    final saved = await auth.savePin(pin);
    if (!context.mounted) {
      return false;
    }
    if (!saved) {
      _showMessage(
        context,
        AppScope.of(context).appConfig.ui.authentication.text('pinSaveFailed'),
      );
    }
    return saved;
  }

  static Future<bool> configureBiometrics(BuildContext context) async {
    final auth = AppScope.of(context).localAuthenticationService;
    final status = await auth.checkBiometrics();
    if (!context.mounted) {
      return false;
    }
    if (!status.available) {
      _showMessage(
        context,
        userFriendlyErrorMessage(
          status.message,
          fallback: 'Biometria indisponível neste dispositivo.',
        ),
      );
      return false;
    }

    final authenticated = await auth.authenticateBiometrics(
      title: AppScope.of(
        context,
      ).appConfig.ui.authentication.text('enableBiometricTitle'),
      subtitle: AppScope.of(
        context,
      ).appConfig.ui.authentication.text('enableBiometricSubtitle'),
    );
    if (!context.mounted) {
      return false;
    }
    if (!authenticated) {
      _showMessage(
        context,
        AppScope.of(
          context,
        ).appConfig.ui.authentication.text('biometricNotConfirmed'),
      );
    }
    return authenticated;
  }

  static Future<bool> authenticate(
    BuildContext context,
    Configuration configuration, {
    String? reason,
  }) async {
    reason ??= AppScope.of(
      context,
    ).appConfig.ui.authentication.text('defaultReason');
    if (!configuration.localAuthEnabled) {
      return true;
    }

    return switch (configuration.authenticationType) {
      AuthenticationType.pin => _authenticatePin(context, reason),
      AuthenticationType.biometric => _authenticateBiometrics(context, reason),
      null => false,
    };
  }

  static Future<bool> removePin(BuildContext context) {
    return AppScope.of(context).localAuthenticationService.removePin();
  }

  static Future<bool> _authenticatePin(
    BuildContext context,
    String reason,
  ) async {
    final auth = AppScope.of(context).localAuthenticationService;
    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PinAuthDialog(reason: reason),
    );
    if (pin == null) {
      return false;
    }

    final authenticated = await auth.authenticatePin(pin);
    if (!context.mounted) {
      return false;
    }
    if (!authenticated) {
      _showMessage(
        context,
        AppScope.of(context).appConfig.ui.authentication.text('wrongPin'),
      );
    }
    return authenticated;
  }

  static Future<bool> _authenticateBiometrics(
    BuildContext context,
    String reason,
  ) async {
    final auth = AppScope.of(context).localAuthenticationService;
    final status = await auth.checkBiometrics();
    if (!context.mounted) {
      return false;
    }
    if (!status.available) {
      _showMessage(
        context,
        userFriendlyErrorMessage(
          status.message,
          fallback: 'Biometria indisponível neste dispositivo.',
        ),
      );
      return false;
    }

    final authenticated = await auth.authenticateBiometrics(
      title: AppScope.of(
        context,
      ).appConfig.ui.authentication.text('unlockTitle'),
      subtitle: reason,
    );
    if (!context.mounted) {
      return false;
    }
    if (!authenticated) {
      _showMessage(
        context,
        AppScope.of(
          context,
        ).appConfig.ui.authentication.text('biometricFailed'),
      );
    }
    return authenticated;
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PinCreationDialog extends StatefulWidget {
  const _PinCreationDialog();

  @override
  State<_PinCreationDialog> createState() => _PinCreationDialogState();
}

class _PinCreationDialogState extends State<_PinCreationDialog> {
  final _controller = TextEditingController();
  String? _firstPin;
  String? _error;

  bool get _confirming => _firstPin != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commonText = AppScope.of(context).appConfig.ui.common;
    final authText = AppScope.of(context).appConfig.ui.authentication;
    return AlertDialog(
      title: Text(
        _confirming
            ? authText.text('confirmPinTitle')
            : authText.text('createPinTitle'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _confirming
                ? authText.text('repeatPin')
                : authText.text('pinInstructions'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 12,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: authText.text('pin'),
              errorText: _error,
              counterText: '',
            ),
            onSubmitted: (_) => _continuar(),
          ),
        ],
      ),
      actions: [
        FinTrackDialogActions(
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(commonText.cancel),
            ),
            FilledButton(
              onPressed: _continuar,
              child: Text(
                _confirming
                    ? authText.text('savePin')
                    : authText.text('continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _continuar() {
    final pin = _controller.text.trim();
    if (pin.length < 4) {
      setState(
        () => _error = AppScope.of(
          context,
        ).appConfig.ui.authentication.text('pinTooShort'),
      );
      return;
    }

    final firstPin = _firstPin;
    if (firstPin == null) {
      setState(() {
        _firstPin = pin;
        _error = null;
        _controller.clear();
      });
      return;
    }

    if (pin != firstPin) {
      setState(() {
        _firstPin = null;
        _error = AppScope.of(
          context,
        ).appConfig.ui.authentication.text('pinMismatch');
        _controller.clear();
      });
      return;
    }

    Navigator.of(context).pop(pin);
  }
}

class _PinAuthDialog extends StatefulWidget {
  const _PinAuthDialog({required this.reason});

  final String reason;

  @override
  State<_PinAuthDialog> createState() => _PinAuthDialogState();
}

class _PinAuthDialogState extends State<_PinAuthDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commonText = AppScope.of(context).appConfig.ui.common;
    final authText = AppScope.of(context).appConfig.ui.authentication;
    return AlertDialog(
      title: Text(authText.text('unlockTitle')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.reason),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 12,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: authText.text('pin'),
              errorText: _error,
              counterText: '',
            ),
            onSubmitted: (_) => _confirm(),
          ),
        ],
      ),
      actions: [
        FinTrackDialogActions(
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(commonText.cancel),
            ),
            FilledButton(
              onPressed: _confirm,
              child: Text(authText.text('unlock')),
            ),
          ],
        ),
      ],
    );
  }

  void _confirm() {
    final pin = _controller.text.trim();
    if (pin.length < 4) {
      setState(
        () => _error = AppScope.of(
          context,
        ).appConfig.ui.authentication.text('pinRequired'),
      );
      return;
    }
    Navigator.of(context).pop(pin);
  }
}
