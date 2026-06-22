import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/receipt.dart';
import '../../domain/exceptions/operation_cancelled_exception.dart';
import '../../domain/services/i_receipt_service.dart';
import '../receipts/receipt_flow_result.dart';
import '../receipts/pages/receipt_confirmation_page.dart';
import '../widgets/app_scope.dart';
import '../widgets/destructive_filled_button.dart';
import '../widgets/dialog_actions.dart';
import '../widgets/fin_track_page_header.dart';
import '../widgets/storage_limit_feedback.dart';

class ProcessingPage extends StatefulWidget {
  const ProcessingPage({super.key, required this.file, this.onFinished});

  final File file;
  final Future<void> Function()? onFinished;

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage> {
  static const _processingTimeout = Duration(seconds: 45);

  String _step = 'Preparando arquivo';
  Object? _error;
  String? _errorMessage;
  var _finishTransferred = false;
  var _cancelled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _process());
  }

  @override
  void dispose() {
    if (!_finishTransferred) {
      _cancelled = true;
    }
    final onFinished = widget.onFinished;
    if (!_finishTransferred && onFinished != null) {
      unawaited(onFinished());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _error != null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        unawaited(_cancelProcessing());
      },
      child: Scaffold(
        appBar: const FinTrackPageHeader(
          title: Text('Processando'),
          automaticallyImplyLeading: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error == null) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 18),
                  Text(_step, textAlign: TextAlign.center),
                ] else ...[
                  Icon(
                    Icons.error_outline,
                    size: 56,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Não foi possível processar o comprovante.',
                    textAlign: TextAlign.center,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _process,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cancelProcessing() async {
    if (_cancelled) {
      return;
    }
    if (_error == null && !await _confirmCancellation()) {
      return;
    }
    _cancelled = true;
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _confirmCancellation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar processamento?'),
        content: const Text(
          'A leitura em andamento será ignorada e o comprovante não será adicionado.',
        ),
        actions: [
          FinTrackDialogActions(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continuar'),
              ),
              FilledButton(
                style: destructiveFilledButtonStyle(context),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ],
      ),
    );
    return confirm == true;
  }

  Future<void> _process() async {
    if (!mounted) {
      return;
    }
    _cancelled = false;
    setState(() {
      _error = null;
      _errorMessage = null;
      _step = 'Lendo comprovante';
    });

    try {
      final service = AppScope.of(context).receiptService;
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        setState(() => _step = 'Extraindo dados e classificando');
      }
      final input = widget.file;
      await service.validateSpaceForNewReceipt(input);
      final receipt = await service
          .processPreview(input)
          .timeout(_processingTimeout);
      if (_cancelled || !mounted) {
        await _discardCancelledPreview(service, receipt);
        return;
      }
      setState(() => _step = 'Gerando busca semântica');
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (_cancelled || !mounted) {
        await _discardCancelledPreview(service, receipt);
        return;
      }
      _finishTransferred = true;
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ReceiptConfirmationPage(
            receipt: receipt,
            onFinished: widget.onFinished,
          ),
        ),
      );
      if (mounted) {
        Navigator.of(
          context,
        ).pop(result == true ? ReceiptFlowResult.saved : null);
      }
    } on OperationCancelledException {
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on TimeoutException catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _errorMessage =
              'A leitura demorou mais que o esperado. Tente novamente com a imagem mais nítida e bem enquadrada.';
        });
      }
    } catch (error) {
      if (mounted) {
        if (isStorageLimitError(error)) {
          showStorageLimitSnackBar(context, error);
        }
        setState(() {
          _error = error;
          _errorMessage = isStorageLimitError(error)
              ? 'Ajuste o limite de armazenamento ou libere espaço antes de tentar novamente.'
              : null;
        });
      }
    }
  }

  Future<void> _discardCancelledPreview(
    IReceiptService service,
    Receipt receipt,
  ) async {
    if (receipt.id == 0) {
      await service.discardPreview(receipt);
    }
  }
}
