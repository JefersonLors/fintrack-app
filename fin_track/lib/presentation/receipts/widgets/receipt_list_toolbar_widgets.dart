import 'package:flutter/material.dart';

import '../../theme/fin_track_theme.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/fin_track_page_header.dart';

class DefaultListToolbar extends StatelessWidget {
  const DefaultListToolbar({
    super.key,
    required this.importBusy,
    required this.selecting,
    required this.processingSelection,
    required this.selectedCount,
    required this.onImport,
    required this.onOpenFilters,
    required this.onStartSelection,
    required this.onShareSelected,
    required this.onSaveSelected,
    required this.onDeleteSelected,
    this.automaticallyImplyLeading = false,
    this.showSelectionAction = true,
  });

  final bool importBusy;
  final bool selecting;
  final bool processingSelection;
  final int selectedCount;
  final VoidCallback onImport;
  final VoidCallback onOpenFilters;
  final VoidCallback onStartSelection;
  final VoidCallback onShareSelected;
  final VoidCallback onSaveSelected;
  final VoidCallback onDeleteSelected;
  final bool automaticallyImplyLeading;
  final bool showSelectionAction;

  @override
  Widget build(BuildContext context) {
    final commonText = AppScope.of(context).appConfig.ui.common;
    final receiptsText = AppScope.of(context).appConfig.ui.receipts;
    return FinTrackPageHeader(
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: const Text('FinTrack'),
      actions: [
        if (selecting) ...[
          PopupMenuButton<SelectionAction>(
            tooltip: receiptsText.moreOptions,
            enabled: selectedCount > 0 && !processingSelection,
            icon: const Icon(Icons.more_vert),
            constraints: const BoxConstraints.tightFor(width: 56),
            onSelected: (action) {
              switch (action) {
                case SelectionAction.share:
                  onShareSelected();
                  break;
                case SelectionAction.save:
                  onSaveSelected();
                  break;
                case SelectionAction.delete:
                  onDeleteSelected();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<SelectionAction>(
                value: SelectionAction.share,
                child: _ActionMenuIcon(
                  tooltip: receiptsText.shareSelected,
                  icon: Icons.share_outlined,
                ),
              ),
              PopupMenuItem<SelectionAction>(
                value: SelectionAction.save,
                child: _ActionMenuIcon(
                  tooltip: commonText.saveToDevice,
                  icon: Icons.download_outlined,
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem<SelectionAction>(
                value: SelectionAction.delete,
                child: _ActionMenuIcon(
                  tooltip: receiptsText.deleteSelected,
                  icon: Icons.delete_outline,
                  color: context.finTrackColors.danger,
                ),
              ),
            ],
          ),
        ] else ...[
          if (showSelectionAction)
            IconButton(
              tooltip: receiptsText.selectReceipts,
              onPressed: onStartSelection,
              icon: const Icon(Icons.checklist_outlined),
            ),
          IconButton(
            tooltip: receiptsText.importReceipt,
            onPressed: importBusy ? null : onImport,
            icon: importBusy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
          ),
          IconButton(
            tooltip: receiptsText.filters,
            onPressed: onOpenFilters,
            icon: const Icon(Icons.tune),
          ),
        ],
      ],
    );
  }
}

enum SelectionAction { share, save, delete }

class _ActionMenuIcon extends StatelessWidget {
  const _ActionMenuIcon({
    required this.tooltip,
    required this.icon,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Center(child: Icon(icon, color: color)),
    );
  }
}
