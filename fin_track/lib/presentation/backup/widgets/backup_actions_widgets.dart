import 'package:flutter/material.dart';

import '../../../domain/entities/configuration.dart';
import '../../../domain/entities/cloud_provider.dart';
import '../../theme/fin_track_theme.dart';

class BackupActionsPanel extends StatelessWidget {
  const BackupActionsPanel({
    super.key,
    required this.busy,
    required this.linked,
    required this.backupPasswordDefined,
    required this.onRunBackup,
    required this.onRestore,
  });

  final bool busy;
  final bool linked;
  final bool backupPasswordDefined;
  final Future<void> Function() onRunBackup;
  final Future<void> Function() onRestore;

  @override
  Widget build(BuildContext context) {
    final panelColor = context.finTrackColors.textSecondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.finTrackColors.surface,
        border: Border.all(color: panelColor.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BackupSectionHeader(
              icon: Icons.cloud_sync_outlined,
              title: 'Operações',
              color: panelColor,
            ),
            const SizedBox(height: 8),
            if (linked && !backupPasswordDefined) ...[
              Text(
                'Defina uma senha de backup nas configurações para proteger seus arquivos.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy || !linked || !backupPasswordDefined
                        ? null
                        : onRunBackup,
                    icon: Icon(Icons.cloud_upload_outlined),
                    label: const Text('Backup'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy || !linked ? null : onRestore,
                    icon: Icon(
                      Icons.cloud_download_outlined,
                      color: panelColor,
                    ),
                    label: const Text('Restaurar'),
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

class CloudStatus extends StatelessWidget {
  const CloudStatus({
    super.key,
    required this.configuration,
    required this.busy,
    required this.onLink,
    required this.onUnlink,
  });

  final Configuration configuration;
  final bool busy;
  final Future<void> Function() onLink;
  final Future<void> Function() onUnlink;

  @override
  Widget build(BuildContext context) {
    final linked =
        configuration.linkedCloudAccount != null &&
        configuration.cloudTokenValid;
    final account = configuration.linkedCloudAccount;
    final provider = configuration.cloudProvider ?? CloudProvider.googleDrive;
    final color = linked
        ? context.finTrackColors.income
        : context.finTrackColors.textMuted;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.finTrackColors.surfaceAlt,
        border: Border.all(color: color.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: busy ? null : (linked ? onUnlink : onLink),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                BackupIcon(
                  linked
                      ? cloudProviderIcon(provider)
                      : Icons.cloud_off_outlined,
                  color: color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        linked ? provider.label : 'Não vinculado',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: context.finTrackColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        linked
                            ? account ?? ''
                            : 'Toque para vincular uma conta de armazenamento em nuvem.',
                        maxLines: linked ? 1 : null,
                        overflow: linked ? TextOverflow.ellipsis : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  linked ? Icons.link_off : Icons.link,
                  color: busy ? context.finTrackColors.textMuted : color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData cloudProviderIcon(CloudProvider provider) {
  return switch (provider) {
    CloudProvider.googleDrive => Icons.add_to_drive_outlined,
    CloudProvider.oneDrive => Icons.cloud_queue_outlined,
    CloudProvider.dropbox => Icons.inventory_2_outlined,
  };
}

class BackupSectionHeader extends StatelessWidget {
  const BackupSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    this.action,
    this.prominent = false,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Widget? action;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: prominent ? 20 : 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.finTrackColors.textSecondary,
              fontSize: prominent ? 18 : null,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}

class BackupIcon extends StatelessWidget {
  const BackupIcon(this.icon, {super.key, required this.color});

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
