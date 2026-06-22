part of '../about_fin_track_page.dart';

class _AboutFooter extends StatelessWidget {
  const _AboutFooter({
    required this.author,
    required this.institution,
    required this.version,
  });

  final String author;
  final String institution;
  final String version;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final labelStyle = textTheme.labelSmall?.copyWith(
      color: mutedColor.withValues(alpha: 0.72),
    );
    final authorStyle = textTheme.bodySmall?.copyWith(
      color: mutedColor,
      fontWeight: FontWeight.w600,
    );
    final secondaryStyle = textTheme.bodySmall?.copyWith(
      color: mutedColor.withValues(alpha: 0.86),
    );
    final versionStyle = textTheme.labelSmall?.copyWith(
      color: mutedColor.withValues(alpha: 0.72),
    );
    return Column(
      children: [
        Text(
          'Desenvolvido por',
          textAlign: TextAlign.center,
          style: labelStyle,
        ),
        const SizedBox(height: 2),
        Text(author, textAlign: TextAlign.center, style: authorStyle),
        const SizedBox(height: 4),
        Text(institution, textAlign: TextAlign.center, style: secondaryStyle),
        const SizedBox(height: 12),
        Text(version, textAlign: TextAlign.center, style: versionStyle),
      ],
    );
  }
}

class _ReportProblemDialog extends StatefulWidget {
  const _ReportProblemDialog();

  @override
  State<_ReportProblemDialog> createState() => _ReportProblemDialogState();
}

class _ReportProblemDialogState extends State<_ReportProblemDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _controller.text.trim().isNotEmpty;
    return AlertDialog(
      title: const Text('Reportar problema'),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: _controller,
          minLines: 4,
          maxLines: 6,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            labelText: 'Descrição',
            hintText: 'Descreva o que aconteceu',
            helperText:
                'Detalhe o ocorrido e anexe screenshots da tela do aplicativo ao e-mail se necessário.',
            helperMaxLines: 3,
            alignLabelWithHint: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      actions: [
        FinTrackDialogActions(
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: canContinue
                  ? () => Navigator.of(context).pop(_controller.text.trim())
                  : null,
              child: const Text('Continuar'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.finTrackColors.surface,
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AboutHeader(icon: icon, title: title, color: color),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _AboutHeader extends StatelessWidget {
  const _AboutHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.finTrackColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AboutIcon extends StatelessWidget {
  const _AboutIcon(this.icon, {required this.color});

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

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList(this.items);

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AppVersionInfo {
  const _AppVersionInfo([this.raw = AppConfig.defaultAppVersionFallback]);

  final String raw;

  String get label {
    final parts = raw.split('+');
    if (parts.length >= 2 && parts[1].trim().isNotEmpty) {
      return 'Versão ${parts.first}';
    }
    return 'Versão $raw';
  }
}

Future<_AppVersionInfo> _loadAppVersion() async {
  return fallbackOnFailure(
    () async {
      final pubspec = await rootBundle
          .loadString('pubspec.yaml')
          .timeout(_versionLoadTimeout);
      final match = RegExp(
        r'^version:\s*([^\s#]+)',
        multiLine: true,
      ).firstMatch(pubspec);
      return _AppVersionInfo(
        match?.group(1) ?? AppConfig.defaultAppVersionFallback,
      );
    },
    fallback: const _AppVersionInfo(),
    diagnosticContext: 'Falha ao carregar versão do aplicativo',
  );
}

String _createEmailBody({
  required String description,
  required _AppVersionInfo version,
  required Map<String, String> deviceInfo,
  required DateTime reportDateTime,
  required List<String> errorLogs,
}) {
  final androidVersion = _infoOrFallback(
    deviceInfo['androidVersion'],
    'Indisponível',
  );
  final deviceModel = _infoOrFallback(
    deviceInfo['deviceModel'],
    'Indisponível',
  );
  final logs = errorLogs.isEmpty
      ? 'Nenhum registro de erro relevante disponível localmente.'
      : errorLogs.join('\n\n');

  return [
    'Relato do usuário:',
    description,
    '',
    'Informações técnicas:',
    '- Versão do aplicativo: ${version.raw}',
    '- Versão do Android: $androidVersion',
    '- Modelo do dispositivo: $deviceModel',
    '- Data e hora do reporte: ${_formatReportDateTime(reportDateTime)}',
    '',
    'Registros de erro relevantes:',
    logs,
    '',
    'Privacidade:',
    'Este relatório não inclui comprovantes, dados financeiros, imagens, informações extraídas por OCR ou outros dados sensíveis do usuário.',
  ].join('\n');
}

String _infoOrFallback(String? value, String fallback) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return fallback;
  }
  return trimmed;
}

String _formatReportDateTime(DateTime value) {
  final local = value.toLocal();
  final day = _twoDigits(local.day);
  final month = _twoDigits(local.month);
  final hour = _twoDigits(local.hour);
  final minute = _twoDigits(local.minute);
  final second = _twoDigits(local.second);
  return '$day/$month/${local.year} $hour:$minute:$second';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
