import 'package:flutter/material.dart';

import '../../../domain/entities/receipt.dart';
import '../../../domain/value_objects/receipt_filter.dart';
import '../../theme/fin_track_theme.dart';

class SortBar extends StatelessWidget {
  const SortBar({
    super.key,
    required this.sortOrder,
    required this.sortDirection,
    required this.onChanged,
  });

  final ReceiptSort sortOrder;
  final SortDirection sortDirection;
  final ValueChanged<ReceiptSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ReceiptSort.values.map((value) {
          final selected = value == sortOrder;
          final label = selected
              ? _SortLabel(label: value.label, direction: sortDirection)
              : Text(
                  value.label,
                  style: TextStyle(color: context.finTrackColors.textSecondary),
                );
          final icon = Icon(
            _icon(value),
            size: 18,
            color: selected ? null : context.finTrackColors.info,
          );
          final selectedForeground = Theme.of(context).colorScheme.onSecondary;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: selected
                  ? 'Ordenar por ${value.label.toLowerCase()} (${sortDirection.label.toLowerCase()})'
                  : 'Ordenar por ${value.label.toLowerCase()}',
              child: selected
                  ? FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: context.finTrackColors.info,
                        foregroundColor: selectedForeground,
                        iconColor: selectedForeground,
                      ),
                      onPressed: () => onChanged(value),
                      icon: icon,
                      label: label,
                    )
                  : OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.finTrackColors.textSecondary,
                        iconColor: context.finTrackColors.info,
                        side: BorderSide(
                          color: context.finTrackColors.info.withValues(
                            alpha: 0.34,
                          ),
                        ),
                      ),
                      onPressed: () => onChanged(value),
                      icon: icon,
                      label: label,
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _icon(ReceiptSort value) {
    return switch (value) {
      ReceiptSort.date => Icons.calendar_month_outlined,
      ReceiptSort.amount => Icons.payments_outlined,
      ReceiptSort.establishment => Icons.storefront_outlined,
    };
  }
}

class _SortLabel extends StatelessWidget {
  const _SortLabel({required this.label, required this.direction});

  final String label;
  final SortDirection direction;

  @override
  Widget build(BuildContext context) {
    final icon = switch (direction) {
      SortDirection.ascending => Icons.arrow_upward,
      SortDirection.descending => Icons.arrow_downward,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Text(label), const SizedBox(width: 4), Icon(icon, size: 16)],
    );
  }
}
