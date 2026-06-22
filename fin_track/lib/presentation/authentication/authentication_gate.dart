import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/configuration.dart';
import '../widgets/app_scope.dart';
import '../widgets/state_views.dart';
import 'local_auth_flow.dart';

part 'authentication_lock_widgets.dart';

class AuthenticationGate extends StatefulWidget {
  const AuthenticationGate({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<AuthenticationGate> createState() => AuthenticationGateState();
}

class AuthenticationGateState extends State<AuthenticationGate>
    with WidgetsBindingObserver {
  bool _authenticated = false;
  bool _automaticPromptRequested = false;
  Future<bool>? _authenticationInProgress;
  Completer<bool>? _pinCompleter;
  DateTime? _sentToBackgroundAt;
  String? _message;
  String _currentReason = 'Confirme sua identidade para acessar o FinTrack.';
  bool _validatingPin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      _sentToBackgroundAt ??= DateTime.now();
      return;
    }

    if (state != AppLifecycleState.resumed) {
      return;
    }

    _checkLockOnReturn();
  }

  Future<void> _checkLockOnReturn() async {
    final start = _sentToBackgroundAt;
    if (start == null) {
      return;
    }

    final configuration = await AppScope.of(
      context,
    ).configurationService.load();
    if (!mounted) {
      return;
    }

    _sentToBackgroundAt = null;
    if (!_lockTimeExceeded(configuration, start)) {
      return;
    }

    _lockAndOpenAuthentication(configuration);
  }

  Future<bool> ensureAuthenticated({
    String reason = 'Confirme sua identidade para acessar o FinTrack.',
  }) async {
    final configuration = await AppScope.of(
      context,
    ).configurationService.load();
    if (!configuration.localAuthEnabled) {
      return true;
    }
    final requiresReauthentication = _lockTimeExceeded(
      configuration,
      _sentToBackgroundAt,
    );
    if (_authenticated && !requiresReauthentication) {
      return true;
    }
    if (!mounted) {
      return false;
    }

    if (requiresReauthentication) {
      setState(() => _authenticated = false);
    }
    return _runAuthentication(configuration, reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Configuration>(
      stream: AppScope.of(context).configurationService.watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _withOverlay(
            const Scaffold(
              body: LoadingView(message: 'Verificando proteção local'),
            ),
          );
        }

        final configuration = snapshot.data!;
        if (!configuration.localAuthEnabled) {
          if (!_authenticated) {
            _authenticated = true;
          }
          _automaticPromptRequested = false;
          return widget.child;
        }

        if (_authenticated) {
          return widget.child;
        }

        if (!_automaticPromptRequested) {
          _automaticPromptRequested = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _runAuthentication(configuration);
            }
          });
        }

        return _withOverlay(
          _LocalLockView(
            message: _message,
            reason: _currentReason,
            usePin: configuration.authenticationType == AuthenticationType.pin,
            validatingPin: _validatingPin,
            authenticating: _authenticationInProgress != null,
            onRetry: () => _runAuthentication(configuration),
            onCancelPin: _cancelPin,
            onSubmitPin: _confirmPin,
          ),
        );
      },
    );
  }

  Widget _withOverlay(Widget overlay) {
    return Stack(fit: StackFit.expand, children: [widget.child, overlay]);
  }

  Future<bool> _runAuthentication(
    Configuration configuration, {
    String reason = 'Confirme sua identidade para acessar o FinTrack.',
  }) {
    final inProgress = _authenticationInProgress;
    if (inProgress != null) {
      return inProgress;
    }

    if (configuration.authenticationType == AuthenticationType.pin) {
      return _runPinAuthentication(reason);
    }

    final future =
        LocalAuthFlow.authenticate(
          _dialogContext,
          configuration,
          reason: reason,
        ).then((success) {
          if (mounted) {
            setState(() {
              _authenticated = success;
              if (success) {
                _sentToBackgroundAt = null;
              }
              _message = success
                  ? null
                  : 'Autenticação não concluída. Seus comprovantes continuam protegidos.';
              _authenticationInProgress = null;
            });
          }
          return success;
        });

    setState(() {
      _message = null;
      _automaticPromptRequested = true;
      _authenticationInProgress = future;
    });
    return future;
  }

  BuildContext get _dialogContext {
    return widget.navigatorKey.currentContext ?? context;
  }

  Future<bool> _runPinAuthentication(String reason) {
    final completer = Completer<bool>();
    final future = completer.future.then((success) {
      if (mounted) {
        setState(() {
          _authenticated = success;
          if (success) {
            _sentToBackgroundAt = null;
          }
          _message = success
              ? null
              : _message ??
                    'Autenticação não concluída. Seus comprovantes continuam protegidos.';
          _authenticationInProgress = null;
          _pinCompleter = null;
          _validatingPin = false;
        });
      }
      return success;
    });

    setState(() {
      _message = null;
      _currentReason = reason;
      _automaticPromptRequested = true;
      _authenticationInProgress = future;
      _pinCompleter = completer;
      _validatingPin = false;
    });
    return future;
  }

  Future<void> _confirmPin(String pin) async {
    var completer = _pinCompleter;
    if (completer == null) {
      _runPinAuthentication(_currentReason);
      completer = _pinCompleter;
    }
    if (completer == null || completer.isCompleted || _validatingPin) {
      return;
    }

    setState(() {
      _validatingPin = true;
      _message = null;
    });
    final authenticated = await AppScope.of(
      context,
    ).localAuthenticationService.authenticatePin(pin);
    if (!mounted || completer.isCompleted) {
      return;
    }

    if (!authenticated) {
      setState(() {
        _message = 'PIN incorreto. Acesso não autorizado.';
      });
    }
    completer.complete(authenticated);
  }

  void _cancelPin() {
    final completer = _pinCompleter;
    if (completer == null || completer.isCompleted) {
      return;
    }
    completer.complete(false);
  }

  void _lockAndOpenAuthentication([Configuration? configuration]) async {
    configuration ??= await AppScope.of(context).configurationService.load();
    if (!mounted || !configuration.localAuthEnabled) {
      return;
    }

    setState(() {
      _authenticated = false;
      _automaticPromptRequested = true;
    });
    await _runAuthentication(configuration);
  }

  bool _lockTimeExceeded(Configuration configuration, DateTime? start) {
    if (start == null || !configuration.localAuthEnabled) {
      return false;
    }
    final interval = _lockInterval(configuration);
    return DateTime.now().difference(start) >= interval;
  }

  Duration _lockInterval(Configuration configuration) {
    return Duration(
      minutes: Configuration.validAutoLockIntervalMinutes(
        configuration.autoLockIntervalMinutes,
      ),
    );
  }
}
