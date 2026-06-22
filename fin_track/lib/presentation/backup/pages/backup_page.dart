import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/entities/configuration.dart';
import '../../../domain/entities/cloud_provider.dart';
import '../../../application/config/app_config.dart';
import '../../theme/fin_track_theme.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/blocking_progress_dialog.dart';
import '../../widgets/destructive_filled_button.dart';
import '../../widgets/dialog_actions.dart';
import '../../widgets/fin_track_page_header.dart';
import '../../widgets/state_views.dart';
import '../../widgets/storage_limit_feedback.dart';
import '../controllers/backup_controller.dart';

import '../widgets/backup_actions_widgets.dart';
import '../widgets/backup_history_section.dart';
import '../widgets/backup_page_menu.dart';
import '../widgets/backup_password_dialog.dart';
import '../widgets/cloud_provider_picker_sheet.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  late final BackupController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controller = BackupController()..addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(AppScope.of(context).configurationService.verifyCloudToken());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    final commonText = deps.appConfig.ui.common;
    final backupText = deps.appConfig.ui.backup;
    return StreamBuilder<Configuration>(
      stream: deps.configurationService.watch(),
      builder: (context, configSnapshot) {
        final configuration = configSnapshot.data;
        final linked =
            configuration?.linkedCloudAccount != null &&
            configuration?.cloudTokenValid == true;

        return Scaffold(
          appBar: FinTrackPageHeader(
            automaticallyImplyLeading: true,
            title: Text(commonText.backup),
            actions: [
              BackupPageMenu(
                linked: linked,
                busy: _controller.busy,
                onClearCloudData: () => unawaited(_clearCloudData()),
              ),
            ],
          ),
          body: _buildBody(
            context,
            configSnapshot,
            configuration,
            linked,
            backupText,
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<Configuration> configSnapshot,
    Configuration? configuration,
    bool linked,
    BackupTextConfig backupText,
  ) {
    if (configSnapshot.connectionState == ConnectionState.waiting &&
        configuration == null) {
      return LoadingView(message: backupText.loading);
    }
    if (configuration == null) {
      return ErrorStateView(
        message: backupText.loadError,
        onRetry: () => setState(() {}),
      );
    }

    final deps = AppScope.of(context);
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (_controller.busy) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
        ],
        CloudStatus(
          configuration: configuration,
          busy: _controller.busy,
          onLink: _link,
          onUnlink: _unlink,
        ),
        const SizedBox(height: 12),
        BackupActionsPanel(
          busy: _controller.busy,
          linked: linked,
          backupPasswordDefined: configuration.hasBackupPassword,
          onRunBackup: () => _runBackup(configuration),
          onRestore: _restore,
        ),
        const SizedBox(height: 12),
        BackupHistorySection(
          recordsStream: deps.backupService.watchRecords(),
          backupText: backupText,
          busy: _controller.busy,
          parentScrollController: _scrollController,
          onClearHistory: _clearHistory,
        ),
      ],
    );
  }

  Future<void> _clearHistory() async {
    final commonText = AppScope.of(context).appConfig.ui.common;
    final backupText = AppScope.of(context).appConfig.ui.backup;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(backupText.clearHistoryTitle),
        content: Text(backupText.clearHistoryMessage),
        actions: [
          FinTrackDialogActions(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(commonText.cancel),
              ),
              FilledButton.icon(
                style: destructiveFilledButtonStyle(context),
                onPressed: () => Navigator.of(context).pop(true),
                icon: Icon(Icons.delete_outline),
                label: Text(backupText.clearHistoryAction),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    await _run(
      () => AppScope.of(context).backupService.clearHistory(),
      backupText.historyCleared,
    );
  }

  Future<void> _link() async {
    final backupText = AppScope.of(context).appConfig.ui.backup;
    final provider = await _selectCloudProvider();
    if (provider == null) {
      return;
    }
    await _run(
      () => AppScope.of(context).configurationService.linkCloud(provider),
      backupText.googleLinked,
    );
  }

  Future<CloudProvider?> _selectCloudProvider() {
    final options = AppScope.of(context).cloudStorageRegistry.providers();
    return showCloudProviderPicker(context, options);
  }

  Future<void> _unlink() async {
    final commonText = AppScope.of(context).appConfig.ui.common;
    final backupText = AppScope.of(context).appConfig.ui.backup;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(backupText.unlinkGoogleTitle),
        content: Text(backupText.unlinkGoogleMessage),
        actions: [
          FinTrackDialogActions(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(commonText.cancel),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.finTrackColors.danger,
                  side: BorderSide(color: context.finTrackColors.danger),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(backupText.unlinkGoogleAction),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _run(
        () => AppScope.of(context).configurationService.unlinkCloud(),
        backupText.googleUnlinked,
      );
    }
  }

  Future<void> _clearCloudData() async {
    final commonText = AppScope.of(context).appConfig.ui.common;
    final backupText = AppScope.of(context).appConfig.ui.backup;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(backupText.clearCloudTitle),
        content: Text(backupText.clearCloudMessage),
        actions: [
          FinTrackDialogActions(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(commonText.cancel),
              ),
              FilledButton.icon(
                style: destructiveFilledButtonStyle(context),
                onPressed: () => Navigator.of(context).pop(true),
                icon: Icon(Icons.delete_sweep_outlined),
                label: Text(commonText.clear),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }
    if (!mounted) return;

    final password = await requestBackupPassword(
      context,
      title: backupText.backupPasswordTitle,
      message: backupText.clearCloudPasswordMessage,
      actionLabel: commonText.clear,
    );
    if (password == null) {
      return;
    }
    if (!mounted) return;

    await _run(
      () => AppScope.of(context).backupService.deleteBackup(password: password),
      backupText.cloudDataCleared,
      progressTitle: backupText.clearCloudInProgress,
      progressMessage: backupText.clearCloudInProgressMessage,
    );
  }

  Future<void> _runBackup(Configuration configuration) async {
    final backupText = AppScope.of(context).appConfig.ui.backup;
    final password = configuration.backupPassword;
    if (password == null || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(backupText.backupPasswordRequired)),
        );
      }
      return;
    }
    await _run(
      () => AppScope.of(context).backupService.exportBackup(password: password),
      backupText.backupCompleted,
      progressTitle: backupText.backupInProgress,
      progressMessage: backupText.backupInProgressMessage,
    );
  }

  Future<void> _restore() async {
    final commonText = AppScope.of(context).appConfig.ui.common;
    final backupText = AppScope.of(context).appConfig.ui.backup;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(backupText.restoreTitle),
          content: Text(backupText.restoreMessage),
          actions: [
            FinTrackDialogActions(
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(commonText.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(commonText.restore),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (confirmado != true) {
      return;
    }
    if (!mounted) return;
    final password = await requestBackupPassword(context, confirmation: false);
    if (password == null) {
      return;
    }
    if (!mounted) return;

    await _run(
      () =>
          AppScope.of(context).backupService.restoreBackup(password: password),
      backupText.restoreCompleted,
      progressTitle: backupText.restoreInProgress,
      progressMessage: backupText.restoreInProgressMessage,
    );
  }

  Future<void> _run(
    Future<Object?> Function() action,
    String successMessage, {
    String? progressTitle,
    String? progressMessage,
  }) async {
    Future<BackupActionResult> runAction() {
      return _controller.run(action, successMessage);
    }

    final BackupActionResult result;
    if (progressTitle == null) {
      result = await runAction();
    } else {
      result = await runWithBlockingProgress(
        context: context,
        title: progressTitle,
        message: progressMessage,
        action: (_) => runAction(),
      );
    }
    if (!mounted) {
      return;
    }
    final storageLimitError = result.storageLimitError;
    if (storageLimitError != null) {
      showStorageLimitSnackBar(context, storageLimitError);
      return;
    }
    final message = result.message;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
