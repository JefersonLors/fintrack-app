import 'package:flutter/material.dart';

import '../../../domain/entities/cloud_provider.dart';
import '../../../domain/infrastructure/i_cloud_storage.dart';
import '../../theme/fin_track_theme.dart';
import 'backup_actions_widgets.dart';

Future<CloudProvider?> showCloudProviderPicker(
  BuildContext context,
  List<CloudProviderOption> options,
) {
  final colors = context.finTrackColors;
  return showModalBottomSheet<CloudProvider>(
    context: context,
    showDragHandle: true,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => CloudProviderPickerSheet(options: options),
  );
}

class CloudProviderPickerSheet extends StatelessWidget {
  const CloudProviderPickerSheet({super.key, required this.options});

  final List<CloudProviderOption> options;

  @override
  Widget build(BuildContext context) {
    final colors = context.finTrackColors;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_outlined, color: colors.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Escolha o serviço de nuvem',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final option in options) ...[
              _CloudProviderOptionTile(option: option),
              if (option != options.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _CloudProviderOptionTile extends StatelessWidget {
  const _CloudProviderOptionTile({required this.option});

  final CloudProviderOption option;

  @override
  Widget build(BuildContext context) {
    final available = option.available;
    final colors = context.finTrackColors;
    final color = available ? colors.backup : colors.textMuted;
    final borderColor = available
        ? color.withValues(alpha: 0.28)
        : colors.borderStrong.withValues(alpha: 0.72);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: available
            ? colors.surfaceAlt.withValues(alpha: 0.72)
            : colors.surfaceAlt.withValues(alpha: 0.42),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: available
              ? () => Navigator.of(context).pop(option.provider)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                BackupIcon(cloudProviderIcon(option.provider), color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.provider.label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        available
                            ? 'Disponível'
                            : option.unavailableReason ?? 'Indisponível',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  available ? Icons.chevron_right : Icons.lock_outline,
                  color: available ? colors.textMuted : color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
