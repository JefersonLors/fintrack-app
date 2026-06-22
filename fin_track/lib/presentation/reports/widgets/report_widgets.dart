import 'package:flutter/material.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/receipt.dart';
import '../../../domain/value_objects/report_period.dart';
import '../../theme/fin_track_theme.dart';
import '../../widgets/category_visuals.dart';
import '../../widgets/formatters.dart';

part 'report_summary_widgets.dart';
part 'report_total_models.dart';

class ReportPeriodSelector extends StatelessWidget {
  const ReportPeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ReportPeriod.values.map((period) {
          final active = period == selected;
          final label = SizedBox(
            width: 112,
            child: Text(
              period.label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          );

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: active
                ? FilledButton(
                    onPressed: () => onChanged(period),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.finTrackColors.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      fixedSize: const Size(124, 42),
                      padding: EdgeInsets.zero,
                    ),
                    child: label,
                  )
                : OutlinedButton(
                    onPressed: () => onChanged(period),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.finTrackColors.textSecondary,
                      side: BorderSide(
                        color: context.finTrackColors.borderStrong,
                      ),
                      fixedSize: const Size(124, 42),
                      padding: EdgeInsets.zero,
                    ),
                    child: label,
                  ),
          );
        }).toList(),
      ),
    );
  }
}
