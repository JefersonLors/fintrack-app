part of 'app_config.dart';

class UiTextConfig {
  const UiTextConfig({
    required this.common,
    required this.backup,
    required this.receiptDetail,
    required this.receipts,
    required this.categories,
    required this.configuration,
    required this.authentication,
  });

  final CommonTextConfig common;
  final BackupTextConfig backup;
  final ReceiptDetailTextConfig receiptDetail;
  final ReceiptsTextConfig receipts;
  final KeyedTextConfig categories;
  final KeyedTextConfig configuration;
  final KeyedTextConfig authentication;

  factory UiTextConfig.fromJson(
    Map<String, Object?> json,
    UiTextConfig fallback,
  ) {
    return UiTextConfig(
      common: CommonTextConfig.fromJson(_map(json['common']), fallback.common),
      backup: BackupTextConfig.fromJson(_map(json['backup']), fallback.backup),
      receiptDetail: ReceiptDetailTextConfig.fromJson(
        _map(json['receiptDetail']),
        fallback.receiptDetail,
      ),
      receipts: ReceiptsTextConfig.fromJson(
        _map(json['receipts']),
        fallback.receipts,
      ),
      categories: KeyedTextConfig.fromJson(
        _map(json['categories']),
        fallback.categories,
      ),
      configuration: KeyedTextConfig.fromJson(
        _map(json['configuration']),
        fallback.configuration,
      ),
      authentication: KeyedTextConfig.fromJson(
        _map(json['authentication']),
        fallback.authentication,
      ),
    );
  }
}

class KeyedTextConfig {
  const KeyedTextConfig(this.values);

  final Map<String, String> values;

  String text(String key) => values[key] ?? key;

  String format(String key, Map<String, Object?> replacements) {
    var result = text(key);
    for (final entry in replacements.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value.toString());
    }
    return result;
  }

  factory KeyedTextConfig.fromJson(
    Map<String, Object?> json,
    KeyedTextConfig fallback,
  ) {
    if (json.isEmpty) {
      return fallback;
    }
    final values = Map<String, String>.of(fallback.values);
    for (final entry in json.entries) {
      final text = entry.value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        values[entry.key] = text;
      }
    }
    return KeyedTextConfig(Map<String, String>.unmodifiable(values));
  }
}

class CommonTextConfig {
  const CommonTextConfig({
    required this.apply,
    required this.backup,
    required this.cancel,
    required this.clear,
    required this.close,
    required this.delete,
    required this.edit,
    required this.restore,
    required this.retry,
    required this.save,
    required this.share,
    required this.saveToDevice,
    required this.shareOpened,
    required this.shareFailed,
  });

  final String apply;
  final String backup;
  final String cancel;
  final String clear;
  final String close;
  final String delete;
  final String edit;
  final String restore;
  final String retry;
  final String save;
  final String share;
  final String saveToDevice;
  final String shareOpened;
  final String shareFailed;

  factory CommonTextConfig.fromJson(
    Map<String, Object?> json,
    CommonTextConfig fallback,
  ) {
    return CommonTextConfig(
      apply: _string(json['apply'], fallback.apply),
      backup: _string(json['backup'], fallback.backup),
      cancel: _string(json['cancel'], fallback.cancel),
      clear: _string(json['clear'], fallback.clear),
      close: _string(json['close'], fallback.close),
      delete: _string(json['delete'], fallback.delete),
      edit: _string(json['edit'], fallback.edit),
      restore: _string(json['restore'], fallback.restore),
      retry: _string(json['retry'], fallback.retry),
      save: _string(json['save'], fallback.save),
      share: _string(json['share'], fallback.share),
      saveToDevice: _string(json['saveToDevice'], fallback.saveToDevice),
      shareOpened: _string(json['shareOpened'], fallback.shareOpened),
      shareFailed: _string(json['shareFailed'], fallback.shareFailed),
    );
  }
}

class BackupTextConfig {
  const BackupTextConfig({
    required this.loading,
    required this.loadError,
    required this.historyTitle,
    required this.clearHistoryTooltip,
    required this.clearHistoryTitle,
    required this.clearHistoryMessage,
    required this.clearHistoryAction,
    required this.historyCleared,
    required this.googleLinked,
    required this.unlinkGoogleTitle,
    required this.unlinkGoogleMessage,
    required this.unlinkGoogleAction,
    required this.googleUnlinked,
    required this.clearCloudTitle,
    required this.clearCloudMessage,
    required this.backupPasswordTitle,
    required this.clearCloudPasswordMessage,
    required this.cloudDataCleared,
    required this.backupPasswordRequired,
    required this.backupCompleted,
    required this.backupInProgress,
    required this.backupInProgressMessage,
    required this.restoreTitle,
    required this.restoreMessage,
    required this.restoreCompleted,
    required this.restoreInProgress,
    required this.restoreInProgressMessage,
    required this.clearCloudInProgress,
    required this.clearCloudInProgressMessage,
  });

  final String loading;
  final String loadError;
  final String historyTitle;
  final String clearHistoryTooltip;
  final String clearHistoryTitle;
  final String clearHistoryMessage;
  final String clearHistoryAction;
  final String historyCleared;
  final String googleLinked;
  final String unlinkGoogleTitle;
  final String unlinkGoogleMessage;
  final String unlinkGoogleAction;
  final String googleUnlinked;
  final String clearCloudTitle;
  final String clearCloudMessage;
  final String backupPasswordTitle;
  final String clearCloudPasswordMessage;
  final String cloudDataCleared;
  final String backupPasswordRequired;
  final String backupCompleted;
  final String backupInProgress;
  final String backupInProgressMessage;
  final String restoreTitle;
  final String restoreMessage;
  final String restoreCompleted;
  final String restoreInProgress;
  final String restoreInProgressMessage;
  final String clearCloudInProgress;
  final String clearCloudInProgressMessage;

  factory BackupTextConfig.fromJson(
    Map<String, Object?> json,
    BackupTextConfig fallback,
  ) {
    return BackupTextConfig(
      loading: _string(json['loading'], fallback.loading),
      loadError: _string(json['loadError'], fallback.loadError),
      historyTitle: _string(json['historyTitle'], fallback.historyTitle),
      clearHistoryTooltip: _string(
        json['clearHistoryTooltip'],
        fallback.clearHistoryTooltip,
      ),
      clearHistoryTitle: _string(
        json['clearHistoryTitle'],
        fallback.clearHistoryTitle,
      ),
      clearHistoryMessage: _string(
        json['clearHistoryMessage'],
        fallback.clearHistoryMessage,
      ),
      clearHistoryAction: _string(
        json['clearHistoryAction'],
        fallback.clearHistoryAction,
      ),
      historyCleared: _string(json['historyCleared'], fallback.historyCleared),
      googleLinked: _string(json['googleLinked'], fallback.googleLinked),
      unlinkGoogleTitle: _string(
        json['unlinkGoogleTitle'],
        fallback.unlinkGoogleTitle,
      ),
      unlinkGoogleMessage: _string(
        json['unlinkGoogleMessage'],
        fallback.unlinkGoogleMessage,
      ),
      unlinkGoogleAction: _string(
        json['unlinkGoogleAction'],
        fallback.unlinkGoogleAction,
      ),
      googleUnlinked: _string(json['googleUnlinked'], fallback.googleUnlinked),
      clearCloudTitle: _string(
        json['clearCloudTitle'],
        fallback.clearCloudTitle,
      ),
      clearCloudMessage: _string(
        json['clearCloudMessage'],
        fallback.clearCloudMessage,
      ),
      backupPasswordTitle: _string(
        json['backupPasswordTitle'],
        fallback.backupPasswordTitle,
      ),
      clearCloudPasswordMessage: _string(
        json['clearCloudPasswordMessage'],
        fallback.clearCloudPasswordMessage,
      ),
      cloudDataCleared: _string(
        json['cloudDataCleared'],
        fallback.cloudDataCleared,
      ),
      backupPasswordRequired: _string(
        json['backupPasswordRequired'],
        fallback.backupPasswordRequired,
      ),
      backupCompleted: _string(
        json['backupCompleted'],
        fallback.backupCompleted,
      ),
      backupInProgress: _string(
        json['backupInProgress'],
        fallback.backupInProgress,
      ),
      backupInProgressMessage: _string(
        json['backupInProgressMessage'],
        fallback.backupInProgressMessage,
      ),
      restoreTitle: _string(json['restoreTitle'], fallback.restoreTitle),
      restoreMessage: _string(json['restoreMessage'], fallback.restoreMessage),
      restoreCompleted: _string(
        json['restoreCompleted'],
        fallback.restoreCompleted,
      ),
      restoreInProgress: _string(
        json['restoreInProgress'],
        fallback.restoreInProgress,
      ),
      restoreInProgressMessage: _string(
        json['restoreInProgressMessage'],
        fallback.restoreInProgressMessage,
      ),
      clearCloudInProgress: _string(
        json['clearCloudInProgress'],
        fallback.clearCloudInProgress,
      ),
      clearCloudInProgressMessage: _string(
        json['clearCloudInProgressMessage'],
        fallback.clearCloudInProgressMessage,
      ),
    );
  }
}
