part of 'authentication_gate.dart';

class _LocalLockView extends StatelessWidget {
  const _LocalLockView({
    required this.message,
    required this.reason,
    required this.usePin,
    required this.validatingPin,
    required this.authenticating,
    required this.onRetry,
    required this.onCancelPin,
    required this.onSubmitPin,
  });

  final String? message;
  final String reason;
  final bool usePin;
  final bool validatingPin;
  final bool authenticating;
  final VoidCallback onRetry;
  final VoidCallback onCancelPin;
  final ValueChanged<String> onSubmitPin;

  @override
  Widget build(BuildContext context) {
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: Scaffold(
              appBar: AppBar(title: const Text('FinTrack')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'FinTrack bloqueado',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message ??
                            'Autentique-se para acessar seus comprovantes locais.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (usePin)
                        _PinUnlockForm(
                          reason: reason,
                          validating: validatingPin,
                          onCancel: onCancelPin,
                          onSubmit: onSubmitPin,
                        )
                      else
                        FilledButton.icon(
                          onPressed: authenticating ? null : onRetry,
                          icon: const Icon(Icons.lock_open_outlined),
                          label: Text(
                            authenticating ? 'Aguardando' : 'Desbloquear',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PinUnlockForm extends StatefulWidget {
  const _PinUnlockForm({
    required this.reason,
    required this.validating,
    required this.onCancel,
    required this.onSubmit,
  });

  final String reason;
  final bool validating;
  final VoidCallback onCancel;
  final ValueChanged<String> onSubmit;

  @override
  State<_PinUnlockForm> createState() => _PinUnlockFormState();
}

class _PinUnlockFormState extends State<_PinUnlockForm> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.reason, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            enabled: !widget.validating,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 12,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'PIN',
              errorText: _error,
              counterText: '',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            runSpacing: 8,
            spacing: 12,
            children: [
              TextButton(
                onPressed: widget.validating ? null : widget.onCancel,
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: widget.validating ? null : _submit,
                icon: const Icon(Icons.lock_open_outlined),
                label: Text(widget.validating ? 'Validando' : 'Desbloquear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    final pin = _controller.text.trim();
    if (pin.length < 4) {
      setState(() => _error = 'Informe o PIN cadastrado.');
      return;
    }

    setState(() => _error = null);
    widget.onSubmit(pin);
  }
}
