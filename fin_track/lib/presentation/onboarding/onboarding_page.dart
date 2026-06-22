import 'package:flutter/material.dart';

import '../../application/config/app_config.dart';
import '../widgets/app_scope.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  var _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _configuredSlides(context);
    final isLast = _index == slides.length - 1;
    return Scaffold(
      appBar: AppBar(
        actions: [TextButton(onPressed: _finish, child: const Text('Pular'))],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) => _SlideView(slides[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  Row(
                    children: List.generate(
                      slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: index == _index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: index == _index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: isLast ? _finish : _next,
                    icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                    label: Text(isLast ? 'Começar' : 'Próximo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _next() async {
    await _controller.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    await AppScope.of(context).configurationService.completeOnboarding();
    if (!mounted) {
      return;
    }
    widget.onFinished?.call();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  List<_OnboardingSlide> _configuredSlides(BuildContext context) {
    final config =
        AppScope.maybeOf(context)?.appConfig.onboarding ??
        AppConfig.defaults.onboarding;
    return config.slides
        .map(
          (slide) => _OnboardingSlide(
            icon: _icon(slide.icon),
            title: slide.title,
            body: slide.body,
          ),
        )
        .toList(growable: false);
  }

  IconData _icon(String key) {
    return switch (key) {
      'camera' => Icons.camera_alt_outlined,
      'scan' => Icons.document_scanner_outlined,
      'search_drag' => Icons.swipe_up_outlined,
      'swipe' => Icons.swipe_outlined,
      'share' => Icons.share_outlined,
      'category' => Icons.category_outlined,
      'filters' => Icons.manage_search_outlined,
      'backup' => Icons.cloud_upload_outlined,
      'reports' => Icons.bar_chart_outlined,
      'review' => Icons.fact_check_outlined,
      _ => Icons.info_outline,
    };
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView(this.slide);

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            slide.icon,
            size: 96,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 28),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
