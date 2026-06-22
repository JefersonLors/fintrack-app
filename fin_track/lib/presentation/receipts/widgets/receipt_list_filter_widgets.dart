import 'package:flutter/material.dart';

import '../../widgets/app_scope.dart';
import '../../widgets/formatters.dart';

class DateRangeFilterField extends StatelessWidget {
  const DateRangeFilterField({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onSelect,
    required this.onClear,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onSelect;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final receiptsText = AppScope.of(context).appConfig.ui.receipts;
    final hasRange = startDate != null && endDate != null;
    final label = hasRange
        ? '${formatDate(startDate)} - ${formatDate(endDate)}'
        : receiptsText.selectRange;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: receiptsText.period,
        prefixIcon: const Icon(Icons.date_range_outlined),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          if (onClear != null)
            IconButton(
              tooltip: receiptsText.clearPeriod,
              onPressed: onClear,
              icon: Icon(Icons.close),
            ),
          IconButton(
            tooltip: receiptsText.choosePeriod,
            onPressed: onSelect,
            icon: Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
    );
  }
}
