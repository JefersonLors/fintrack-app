import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/config/app_config.dart';
import '../../infrastructure/diagnostics/error_handling.dart';
import '../theme/fin_track_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/dialog_actions.dart';
import '../widgets/fin_track_page_header.dart';

part 'widgets/about_fin_track_widgets.dart';

const _versionLoadTimeout = Duration(milliseconds: 500);

class AboutFinTrackPage extends StatefulWidget {
  const AboutFinTrackPage({super.key});

  @override
  State<AboutFinTrackPage> createState() => _AboutFinTrackPageState();
}

class _AboutFinTrackPageState extends State<AboutFinTrackPage> {
  late final Future<_AppVersionInfo> _appVersionFuture;

  @override
  void initState() {
    super.initState();
    _appVersionFuture = _loadAppVersion();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig =
        AppScope.maybeOf(context)?.appConfig ?? AppConfig.defaults;
    final app = appConfig.app;
    final about = appConfig.about;
    return Scaffold(
      appBar: FinTrackPageHeader(
        automaticallyImplyLeading: true,
        title: Text('Sobre o ${app.displayName}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.finTrackColors.surface,
              border: Border.all(color: context.finTrackColors.borderStrong),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Image.asset(
                      app.logoAsset,
                      width: 96,
                      height: 96,
                      semanticLabel: 'Logo do ${app.displayName}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    app.displayName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: context.finTrackColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Paragraph(about.description),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _AboutSection(
            icon: Icons.route_outlined,
            title: 'Como funciona',
            color: context.finTrackColors.textSecondary,
            child: _Paragraph(about.howItWorks),
          ),
          const SizedBox(height: 12),
          _AboutSection(
            icon: Icons.verified_user_outlined,
            title: 'Seus dados são seus',
            color: context.finTrackColors.income,
            child: _Paragraph(about.privacy),
          ),
          const SizedBox(height: 12),
          _AboutSection(
            icon: Icons.auto_awesome_outlined,
            title: 'Principais recursos',
            color: context.finTrackColors.textSecondary,
            child: _BulletList(about.features),
          ),
          const SizedBox(height: 12),
          _AboutSection(
            icon: Icons.code_outlined,
            title: 'Código aberto',
            color: context.finTrackColors.textSecondary,
            child: _Paragraph(about.openSource),
          ),
          const SizedBox(height: 24),
          _AboutHeader(
            icon: Icons.help_outline,
            title: 'Dúvidas frequentes',
            color: context.finTrackColors.textSecondary,
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.finTrackColors.surface,
              border: Border.all(color: context.finTrackColors.borderStrong),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Theme(
                data: Theme.of(context).copyWith(
                  cardColor: context.finTrackColors.surface,
                  dividerColor: context.finTrackColors.borderStrong,
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    surface: context.finTrackColors.surface,
                  ),
                ),
                child: ExpansionPanelList.radio(
                  elevation: 0,
                  expandedHeaderPadding: EdgeInsets.zero,
                  dividerColor: context.finTrackColors.borderStrong,
                  materialGapSize: 0,
                  children: about.faq
                      .map(
                        (item) => ExpansionPanelRadio(
                          value: item.question,
                          canTapOnHeader: true,
                          backgroundColor: context.finTrackColors.surface,
                          headerBuilder: (context, isExpanded) {
                            return ListTile(
                              leading: _AboutIcon(
                                Icons.question_answer_outlined,
                                color: context.finTrackColors.textSecondary,
                              ),
                              title: Text(
                                item.question,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color:
                                          context.finTrackColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            );
                          },
                          body: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item.answer,
                                textAlign: TextAlign.justify,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _reportProblem,
            icon: Icon(Icons.report_problem_outlined),
            label: const Text('Reportar problema'),
          ),
          const SizedBox(height: 28),
          FutureBuilder<_AppVersionInfo>(
            future: _appVersionFuture,
            builder: (context, snapshot) {
              final version = snapshot.data ?? const _AppVersionInfo();
              return _AboutFooter(
                author: app.author,
                institution: app.institution,
                version: version.label,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _reportProblem() async {
    final description = await showDialog<String>(
      context: context,
      builder: (_) => const _ReportProblemDialog(),
    );
    if (description == null || description.trim().isEmpty || !mounted) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Abrir e-mail de reporte?'),
          content: const Text(
            'O FinTrack vai preencher uma mensagem com o relato e informações técnicas básicas. Você poderá revisar tudo antes de enviar.',
          ),
          actions: [
            FinTrackDialogActions(
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Abrir e-mail'),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (confirm != true || !mounted) {
      return;
    }

    final appConfig =
        AppScope.maybeOf(context)?.appConfig ?? AppConfig.defaults;
    final reportService = AppScope.of(context).problemReportService;
    final version = await _appVersionFuture;
    final deviceInfo = await reportService.getDeviceInfo();
    final body = _createEmailBody(
      description: description.trim(),
      version: version,
      deviceInfo: deviceInfo,
      reportDateTime: DateTime.now(),
      errorLogs: reportService.getRecentLogs(),
    );
    final opened = await reportService.openReportEmail(
      recipient: appConfig.support.email,
      subject: appConfig.support.reportSubject,
      body: body,
    );

    if (!mounted || opened) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível abrir o aplicativo de e-mail.'),
      ),
    );
  }
}
