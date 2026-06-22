import 'package:flutter/material.dart';

import '../../../domain/entities/backup_record.dart';
import '../../../application/config/app_config.dart';
import '../../theme/fin_track_theme.dart';
import 'backup_actions_widgets.dart';
import 'backup_history_widgets.dart';

class BackupHistorySection extends StatelessWidget {
  const BackupHistorySection({
    super.key,
    required this.recordsStream,
    required this.backupText,
    required this.busy,
    required this.parentScrollController,
    required this.onClearHistory,
  });

  final Stream<List<BackupRecord>> recordsStream;
  final BackupTextConfig backupText;
  final bool busy;
  final ScrollController parentScrollController;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BackupRecord>>(
      stream: recordsStream,
      builder: (context, snapshot) {
        final records = snapshot.data ?? const <BackupRecord>[];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BackupSectionHeader(
              icon: Icons.history,
              title: backupText.historyTitle,
              color: context.finTrackColors.neutralAccent,
              prominent: true,
              action: IconButton(
                tooltip: backupText.clearHistoryTooltip,
                onPressed: records.isEmpty || busy ? null : onClearHistory,
                icon: Icon(Icons.delete_outline),
                color: context.finTrackColors.danger,
              ),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.finTrackColors.surface,
                border: Border.all(color: context.finTrackColors.borderStrong),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                type: MaterialType.transparency,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: BackupHistoryList(
                  records: records,
                  parentScrollController: parentScrollController,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
