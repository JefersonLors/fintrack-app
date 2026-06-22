import 'package:flutter/material.dart';

import '../../../domain/entities/backup_record.dart';
import '../../theme/fin_track_theme.dart';
import 'backup_actions_widgets.dart';
import 'backup_history_tile_widgets.dart';

class BackupHistoryList extends StatefulWidget {
  const BackupHistoryList({
    super.key,
    required this.records,
    this.parentScrollController,
  });

  final List<BackupRecord> records;
  final ScrollController? parentScrollController;

  @override
  State<BackupHistoryList> createState() => _BackupHistoryListState();
}

class _BackupHistoryListState extends State<BackupHistoryList> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.finTrackColors;
    if (widget.records.isEmpty) {
      return ListTile(
        leading: BackupIcon(Icons.history, color: colors.neutralAccent),
        title: Text('Nenhum backup registrado'),
        subtitle: Text('As operações aparecerão aqui.'),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: ScrollbarTheme(
        data: ScrollbarTheme.of(context).copyWith(
          thumbVisibility: const WidgetStatePropertyAll(false),
          trackVisibility: const WidgetStatePropertyAll(false),
          thickness: const WidgetStatePropertyAll(3),
          mainAxisMargin: 10,
          crossAxisMargin: 4,
          radius: const Radius.circular(8),
          thumbColor: WidgetStatePropertyAll(
            colors.textMuted.withValues(alpha: 0.42),
          ),
        ),
        child: Scrollbar(
          controller: _controller,
          interactive: false,
          child: NotificationListener<OverscrollNotification>(
            onNotification: (notification) {
              _transferOverscrollToParent(notification.overscroll);
              return false;
            },
            child: ListView.separated(
              controller: _controller,
              shrinkWrap: true,
              padding: const EdgeInsets.only(right: 8),
              itemCount: widget.records.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) =>
                  BackupTile(widget.records[index]),
            ),
          ),
        ),
      ),
    );
  }

  void _transferOverscrollToParent(double overscroll) {
    if (overscroll == 0) {
      return;
    }
    final parent = widget.parentScrollController;
    if (parent == null || !parent.hasClients) {
      return;
    }
    final position = parent.position;
    final target = (position.pixels + overscroll).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target != position.pixels) {
      position.jumpTo(target);
    }
  }
}
