import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/exceptions/storage_limit_exception.dart';
import '../configuration/pages/configuration_page.dart';
import '../theme/fin_track_theme.dart';

bool isStorageLimitError(Object error) {
  return error is StorageLimitException;
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
_storageLimitSnackBar;
Timer? _storageLimitSnackBarTimer;

void hideStorageLimitSnackBarIfVisible() {
  final controller = _storageLimitSnackBar;
  if (controller == null) {
    return;
  }
  _storageLimitSnackBarTimer?.cancel();
  _storageLimitSnackBarTimer = null;
  _storageLimitSnackBar = null;
  controller.close();
}

void showStorageLimitSnackBar(
  BuildContext context,
  Object error, {
  bool avoidScanButton = false,
}) {
  const message = 'Limite de armazenamento atingido.';
  final colors = context.finTrackColors;
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  _storageLimitSnackBarTimer?.cancel();
  final controller = messenger.showSnackBar(
    SnackBar(
      content: const Text(message),
      duration: const Duration(days: 1),
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.down,
      margin: EdgeInsets.fromLTRB(16, 0, 16, avoidScanButton ? 40 : 16),
      showCloseIcon: true,
      closeIconColor: colors.textSecondary,
      action: SnackBarAction(
        label: 'Ajustar',
        textColor: colors.backup,
        onPressed: () {
          hideStorageLimitSnackBarIfVisible();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  const ConfigurationPage(scrollToStorageSection: true),
            ),
          );
        },
      ),
    ),
  );
  _storageLimitSnackBar = controller;
  _storageLimitSnackBarTimer = Timer(
    const Duration(seconds: 3),
    hideStorageLimitSnackBarIfVisible,
  );
  controller.closed.whenComplete(() {
    if (identical(_storageLimitSnackBar, controller)) {
      _storageLimitSnackBar = null;
    }
    _storageLimitSnackBarTimer?.cancel();
    _storageLimitSnackBarTimer = null;
  });
}
