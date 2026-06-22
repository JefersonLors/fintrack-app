import 'package:flutter/material.dart';

import '../../theme/fin_track_theme.dart';

enum BackupPageMenuAction { clearCloudData }

class BackupPageMenu extends StatelessWidget {
  const BackupPageMenu({
    super.key,
    required this.linked,
    required this.busy,
    required this.onClearCloudData,
  });

  final bool linked;
  final bool busy;
  final VoidCallback onClearCloudData;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<BackupPageMenuAction>(
      tooltip: 'Mais opções',
      icon: Icon(Icons.more_vert),
      onSelected: (action) {
        switch (action) {
          case BackupPageMenuAction.clearCloudData:
            onClearCloudData();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<BackupPageMenuAction>(
          value: BackupPageMenuAction.clearCloudData,
          enabled: linked && !busy,
          child: Row(
            children: [
              Icon(
                Icons.delete_sweep_outlined,
                color: linked && !busy
                    ? context.finTrackColors.danger
                    : context.finTrackColors.textMuted,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Limpar nuvem',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
