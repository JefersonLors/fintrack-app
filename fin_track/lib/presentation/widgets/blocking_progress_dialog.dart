import 'dart:async';

import 'package:flutter/material.dart';

class BlockingProgressController extends ChangeNotifier {
  BlockingProgressController({this.total, int current = 0, String? message})
    : _current = current,
      _message = message;

  final int? total;
  int _current;
  String? _message;

  int get current => _current;
  String? get message => _message;

  void update({int? current, String? message}) {
    var changed = false;
    if (current != null && current != _current) {
      _current = current;
      changed = true;
    }
    if (message != null && message != _message) {
      _message = message;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }
}

class BlockingProgressDialog extends StatelessWidget {
  const BlockingProgressDialog({
    super.key,
    required this.title,
    required this.controller,
    this.initialMessage,
  });

  final String title;
  final String? initialMessage;
  final BlockingProgressController controller;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(title),
        content: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final message = controller.message ?? initialMessage;
            final total = controller.total;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: CircularProgressIndicator()),
                if (message != null && message.trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(message, textAlign: TextAlign.center),
                ],
                if (total != null && total > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${controller.current.clamp(0, total)} de $total',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

Future<T> runWithBlockingProgress<T>({
  required BuildContext context,
  required String title,
  required Future<T> Function(BlockingProgressController controller) action,
  String? message,
  int? total,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final controller = BlockingProgressController(total: total, message: message);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => BlockingProgressDialog(
        title: title,
        initialMessage: message,
        controller: controller,
      ),
    ),
  );

  try {
    return await action(controller);
  } finally {
    if (navigator.mounted && navigator.canPop()) {
      navigator.pop();
    }
    controller.dispose();
  }
}
