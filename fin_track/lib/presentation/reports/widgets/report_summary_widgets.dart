part of 'report_widgets.dart';

class ReportSummary extends StatelessWidget {
  const ReportSummary({
    super.key,
    required this.incomes,
    required this.expenses,
    required this.balance,
    required this.count,
    required this.periodSummary,
    required this.onIncomeTap,
    required this.onExpensesTap,
  });

  final double incomes;
  final double expenses;
  final double balance;
  final int count;
  final String periodSummary;
  final VoidCallback onIncomeTap;
  final VoidCallback onExpensesTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.finTrackColors.surface,
        border: Border.all(color: context.finTrackColors.borderStrong),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: context.finTrackColors.primary.withValues(
                      alpha: 0.14,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: context.finTrackColors.primary.withValues(
                        alpha: 0.30,
                      ),
                    ),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: context.finTrackColors.primary,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saldo do período',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: context.finTrackColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  count == 1 ? '1 comprovante' : '$count comprovantes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.finTrackColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Semantics(
              label: 'Saldo do período: ${formatCurrencyForSpeech(balance)}',
              child: Text(
                formatCurrency(balance),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: context.finTrackColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              periodSummary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.finTrackColors.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SummaryAction(
                    label: 'Receitas',
                    value: incomes,
                    icon: Icons.add_circle_outline,
                    color: context.finTrackColors.income,
                    onTap: onIncomeTap,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryAction(
                    label: 'Despesas',
                    value: expenses,
                    icon: Icons.remove_circle_outline,
                    color: context.finTrackColors.expense,
                    onTap: onExpensesTap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryAction extends StatelessWidget {
  const _SummaryAction({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: ${formatCurrencyForSpeech(value)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.finTrackColors.surfaceAlt,
            border: Border.all(color: context.finTrackColors.borderStrong),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.finTrackColors.textMuted,
                        ),
                      ),
                      Text(
                        formatCurrency(value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: context.finTrackColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReportBarRow extends StatelessWidget {
  const ReportBarRow({
    super.key,
    required this.label,
    required this.value,
    required this.total,
    required this.onTap,
    required this.color,
    this.icon = Icons.category_outlined,
    this.iconColor,
  });

  final String label;
  final double value;
  final double total;
  final VoidCallback onTap;
  final Color color;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Semantics(
      button: true,
      label: '$label: ${formatCurrencyForSpeech(value)}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.finTrackColors.surface.withValues(alpha: 0.62),
              border: Border.all(
                color: context.finTrackColors.borderStrong.withValues(
                  alpha: 0.72,
                ),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _ReportLabel(
                            icon: icon,
                            label: label,
                            color: iconColor ?? color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatCurrency(value),
                        style: TextStyle(
                          color: context.finTrackColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        color: context.finTrackColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, right: 32),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 7,
                        color: color,
                        backgroundColor: context.finTrackColors.surfaceAlt,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportLabel extends StatelessWidget {
  const _ReportLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
