import 'package:flutter/material.dart';

import '../../../domain/entities/backup_record.dart';
import '../../../infrastructure/diagnostics/user_error_message.dart';
import '../../theme/fin_track_theme.dart';
import '../../widgets/dialog_actions.dart';
import '../../widgets/fin_track_chip.dart';
import '../../widgets/fin_track_panel.dart';
import '../../widgets/formatters.dart';
import 'backup_actions_widgets.dart';

class BackupTile extends StatelessWidget {
  const BackupTile(this.record, {super.key});

  final BackupRecord record;

  @override
  Widget build(BuildContext context) {
    final color = _historyIconColor(context);
    return ListTile(
      leading: BackupIcon(_historyIcon, color: color),
      title: Row(
        children: [
          Expanded(child: Text(_historyTitle)),
          const SizedBox(width: 8),
          Text(
            formatDateTime(record.createdAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.finTrackColors.textMuted,
            ),
          ),
        ],
      ),
      subtitle: _BackupHistorySummary(record: record),
      onTap: () => _showBackupDetails(context),
    );
  }

  String get _historyTitle {
    return record.operation == BackupOperation.restore
        ? 'Restauração'
        : 'Backup';
  }

  IconData get _historyIcon {
    if (record.operation == BackupOperation.restore) {
      return Icons.cloud_download_outlined;
    }
    return Icons.cloud_upload_outlined;
  }

  Color _historyIconColor(BuildContext context) {
    return switch (record.status) {
      BackupStatus.pending => context.finTrackColors.textSecondary,
      BackupStatus.synced => context.finTrackColors.income,
      BackupStatus.failure => context.finTrackColors.danger,
    };
  }

  void _showBackupDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_historyIcon, color: _historyIconColor(context)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                record.operation == BackupOperation.restore
                    ? 'Detalhes da restauração'
                    : 'Detalhes do backup',
              ),
            ),
          ],
        ),
        content: _BackupDetailsPanel(
          record: record,
          statusLabel: _operationStatus,
          statusColor: _historyIconColor(context),
        ),
        actions: [
          FinTrackDialogActions(
            children: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _operationStatus {
    return switch (record.status) {
      BackupStatus.pending => 'Em andamento',
      BackupStatus.synced => 'Concluído',
      BackupStatus.failure => 'Não concluído',
    };
  }
}

String _formatReceiptCount(int count) {
  return count == 1 ? '1 comprovante' : '$count comprovantes';
}

class _BackupHistorySummary extends StatelessWidget {
  const _BackupHistorySummary({required this.record});

  final BackupRecord record;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _BackupHistoryChip(
            icon: cloudProviderIcon(record.cloudProvider!),
            label: record.cloudProvider!.label,
            semanticLabel: 'Plataforma: ${record.cloudProvider!.label}',
          ),
          _BackupHistoryChip(
            icon: _statusIcon(record.status),
            label: _statusLabel(record.status),
            color: context.finTrackColors.textMuted,
            semanticLabel:
                'Status de conclusão: ${_statusLabel(record.status)}',
          ),
          _BackupHistoryChip(
            icon: Icons.receipt_long_outlined,
            label: _formatReceiptCount(record.totalReceipts),
            semanticLabel:
                'Comprovantes no backup: ${_formatReceiptCount(record.totalReceipts)}',
          ),
          if (record.operation == BackupOperation.export)
            _BackupHistoryChip(
              icon: _availabilityIcon(record.availability),
              label: record.availability.label,
              color: context.finTrackColors.textMuted,
              semanticLabel:
                  'Status de atividade: ${record.availability.label}',
            ),
        ],
      ),
    );
  }

  IconData _availabilityIcon(BackupAvailability availability) {
    return switch (availability) {
      BackupAvailability.active => Icons.cloud_done_outlined,
      BackupAvailability.inactive => Icons.cloud_off_outlined,
      BackupAvailability.deleted => Icons.delete_outline,
    };
  }

  IconData _statusIcon(BackupStatus status) {
    return switch (status) {
      BackupStatus.pending => Icons.sync_outlined,
      BackupStatus.synced => Icons.check_circle_outline,
      BackupStatus.failure => Icons.error_outline,
    };
  }

  String _statusLabel(BackupStatus status) {
    return switch (status) {
      BackupStatus.pending => 'Em andamento',
      BackupStatus.synced => 'Concluído',
      BackupStatus.failure => 'Falha',
    };
  }
}

class _BackupHistoryChip extends StatelessWidget {
  const _BackupHistoryChip({
    required this.icon,
    required this.label,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return FinTrackChip(
      icon: icon,
      label: label,
      color: color,
      semanticLabel: semanticLabel,
      tooltip: semanticLabel,
    );
  }
}

class _BackupDetailsPanel extends StatelessWidget {
  const _BackupDetailsPanel({
    required this.record,
    required this.statusLabel,
    required this.statusColor,
  });

  final BackupRecord record;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final error = record.status == BackupStatus.failure
        ? userFriendlyErrorMessage(
            record.errorDescription,
            fallback: 'A operação não foi concluída.',
          )
        : null;
    return SizedBox(
      width: double.maxFinite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: SingleChildScrollView(
          child: FinTrackPanel(
            backgroundColor: context.finTrackColors.surfaceAlt,
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailRow(title: 'Operação', value: record.operation.label),
                _DetailRow(
                  title: 'Status',
                  valueWidget: _StatusChip(
                    label: statusLabel,
                    color: statusColor,
                  ),
                ),
                _DetailRow(
                  title: 'Data e hora',
                  value: formatDateTime(record.createdAt),
                ),
                if (record.cloudProvider != null)
                  _DetailRow(
                    title: 'Serviço de nuvem',
                    value: record.cloudProvider!.label,
                  ),
                if (record.linkedCloudAccount != null)
                  _DetailRow(title: 'Conta', value: record.linkedCloudAccount!),
                if (record.operation == BackupOperation.export)
                  _DetailRow(
                    title: 'Situação do arquivo',
                    value: record.availability.label,
                  ),
                _DetailRow(
                  title: 'Comprovantes',
                  value: _formatReceiptCount(record.totalReceipts),
                  isLast: error == null || error.isEmpty,
                ),
                if (error != null && error.isNotEmpty)
                  _ErrorDetail(message: error),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.title,
    this.value,
    this.valueWidget,
    this.isLast = false,
  }) : assert(value != null || valueWidget != null);

  final String title;
  final String? value;
  final Widget? valueWidget;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: context.finTrackColors.borderStrong.withValues(
                    alpha: 0.48,
                  ),
                ),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.finTrackColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          valueWidget ??
              Text(
                value!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.finTrackColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FinTrackChip(
        label: label,
        color: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}

class _ErrorDetail extends StatelessWidget {
  const _ErrorDetail({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = context.finTrackColors.danger;
    return FinTrackPanel(
      backgroundColor: color.withValues(alpha: 0.08),
      borderColor: color.withValues(alpha: 0.28),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Erro',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.finTrackColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
