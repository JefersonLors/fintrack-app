part of 'app_config.dart';

class AppInfoConfig {
  const AppInfoConfig({
    required this.displayName,
    required this.logoAsset,
    required this.institution,
    required this.author,
    required this.fallbackVersion,
  });

  final String displayName;
  final String logoAsset;
  final String institution;
  final String author;
  final String fallbackVersion;

  factory AppInfoConfig.fromJson(
    Map<String, Object?> json,
    AppInfoConfig fallback,
  ) {
    return AppInfoConfig(
      displayName: _string(json['displayName'], fallback.displayName),
      logoAsset: _string(json['logoAsset'], fallback.logoAsset),
      institution: _string(json['institution'], fallback.institution),
      author: _string(json['author'], fallback.author),
      fallbackVersion: _string(
        json['fallbackVersion'],
        fallback.fallbackVersion,
      ),
    );
  }
}

class SupportConfig {
  const SupportConfig({required this.email, required this.reportSubject});

  final String email;
  final String reportSubject;

  factory SupportConfig.fromJson(
    Map<String, Object?> json,
    SupportConfig fallback,
  ) {
    return SupportConfig(
      email: _string(json['email'], fallback.email),
      reportSubject: _string(json['reportSubject'], fallback.reportSubject),
    );
  }
}

class AboutConfig {
  const AboutConfig({
    required this.description,
    required this.howItWorks,
    required this.privacy,
    required this.openSource,
    required this.features,
    required this.faq,
  });

  final String description;
  final String howItWorks;
  final String privacy;
  final String openSource;
  final List<String> features;
  final List<FaqConfig> faq;

  factory AboutConfig.fromJson(
    Map<String, Object?> json,
    AboutConfig fallback,
  ) {
    return AboutConfig(
      description: _string(json['description'], fallback.description),
      howItWorks: _string(json['howItWorks'], fallback.howItWorks),
      privacy: _string(json['privacy'], fallback.privacy),
      openSource: _string(json['openSource'], fallback.openSource),
      features: _stringList(json['features'], fallback.features),
      faq: _faqList(json['faq'], fallback.faq),
    );
  }
}

class FaqConfig {
  const FaqConfig({required this.question, required this.answer});

  final String question;
  final String answer;

  factory FaqConfig.fromJson(Map<String, Object?> json, FaqConfig fallback) {
    return FaqConfig(
      question: _string(json['question'], fallback.question),
      answer: _string(json['answer'], fallback.answer),
    );
  }
}

class OnboardingConfig {
  const OnboardingConfig({required this.slides});

  final List<OnboardingSlideConfig> slides;

  factory OnboardingConfig.fromJson(
    Map<String, Object?> json,
    OnboardingConfig fallback,
  ) {
    return OnboardingConfig(
      slides: _slideList(json['slides'], fallback.slides),
    );
  }
}

class OnboardingSlideConfig {
  const OnboardingSlideConfig({
    required this.icon,
    required this.title,
    required this.body,
  });

  final String icon;
  final String title;
  final String body;

  factory OnboardingSlideConfig.fromJson(
    Map<String, Object?> json,
    OnboardingSlideConfig fallback,
  ) {
    return OnboardingSlideConfig(
      icon: _string(json['icon'], fallback.icon),
      title: _string(json['title'], fallback.title),
      body: _string(json['body'], fallback.body),
    );
  }
}
