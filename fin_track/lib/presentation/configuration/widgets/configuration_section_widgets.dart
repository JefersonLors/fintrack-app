import 'package:flutter/material.dart';

import '../../theme/fin_track_theme.dart';
import '../../widgets/fin_track_panel.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    required this.icon,
    required this.color,
    this.showDivider = true,
  });

  final String title;
  final List<Widget> children;
  final IconData icon;
  final Color color;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = context.finTrackColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          FinTrackDividedPanel(
            borderColor: color.withValues(alpha: 0.24),
            material: true,
            children: [
              for (final child in children)
                ListTileTheme(
                  data: ListTileThemeData(
                    titleTextStyle: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  child: child,
                ),
            ],
          ),
          if (showDivider) const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class SettingsIcon extends StatelessWidget {
  const SettingsIcon(this.icon, {super.key, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox.square(
        dimension: 40,
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class StorageTile extends StatelessWidget {
  const StorageTile({
    super.key,
    required this.future,
    required this.limitMb,
    required this.onRefresh,
  });

  final Future<int> future;
  final int limitMb;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        final colors = context.finTrackColors;
        final bytes = snapshot.data ?? 0;
        final usedMb = bytes / (1024 * 1024);
        final fraction = (usedMb / limitMb).clamp(0.0, 1.0);
        final high = fraction >= 0.85;
        final exceeded = fraction >= 1.0;
        final color = exceeded
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            border: Border.all(color: colors.borderStrong),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      high
                          ? Icons.warning_amber_outlined
                          : Icons.storage_outlined,
                      color: high ? color : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        exceeded
                            ? 'Limite atingido'
                            : high
                            ? 'Espaço alto'
                            : 'Espaço usado',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Atualizar espaço',
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: fraction,
                  color: color,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withAlpha((0.08 * 255).round()),
                ),
                const SizedBox(height: 8),
                Text('${usedMb.toStringAsFixed(2)} MB de $limitMb MB'),
                if (exceeded)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'O limite de armazenamento foi atingido. Libere espaço ou aumente o limite.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: color),
                    ),
                  )
                else if (high)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'O uso de armazenamento está acima de 85%. Considere liberar espaço.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: color),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
