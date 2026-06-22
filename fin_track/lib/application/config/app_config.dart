import 'dart:convert';

import 'package:flutter/services.dart';

import '../../infrastructure/diagnostics/error_handling.dart';

part 'about_config.dart';
part 'app_config_defaults.dart';
part 'ui_text_config.dart';
part 'receipt_detail_ui_text_config.dart';
part 'receipt_ui_text_config.dart';

class AppConfig {
  const AppConfig({
    required this.version,
    required this.debugMode,
    required this.app,
    required this.support,
    required this.about,
    required this.onboarding,
    required this.ui,
  });

  static const assetPath = 'assets/config/app_config.json';
  static const defaultAppVersionFallback = '1.0.0+1';

  static const defaults = defaultAppConfig;

  final int version;
  final bool debugMode;
  final AppInfoConfig app;
  final SupportConfig support;
  final AboutConfig about;
  final OnboardingConfig onboarding;
  final UiTextConfig ui;

  static Future<AppConfig> loadFromAsset({
    String path = assetPath,
    Duration timeout = const Duration(milliseconds: 700),
  }) async {
    return fallbackOnFailure(
      () async {
        final raw = await rootBundle.loadString(path).timeout(timeout);
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, Object?>) {
          return defaults;
        }
        return AppConfig.fromJson(decoded);
      },
      fallback: defaults,
      diagnosticContext: 'Falha ao carregar configuração do aplicativo',
      report: true,
    );
  }

  factory AppConfig.fromJson(Map<String, Object?> json) {
    return AppConfig(
      version: _int(json['version'], defaults.version),
      debugMode: _bool(json['debugMode'], defaults.debugMode),
      app: AppInfoConfig.fromJson(_map(json['app']), defaults.app),
      support: SupportConfig.fromJson(_map(json['support']), defaults.support),
      about: AboutConfig.fromJson(_map(json['about']), defaults.about),
      onboarding: OnboardingConfig.fromJson(
        _map(json['onboarding']),
        defaults.onboarding,
      ),
      ui: UiTextConfig.fromJson(_map(json['ui']), defaults.ui),
    );
  }
}

Map<String, Object?> _map(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.from(value);
  }
  return const <String, Object?>{};
}

String _string(Object? value, String fallback) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

int _int(Object? value, int fallback) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _bool(Object? value, bool fallback) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return fallback;
}

List<String> _stringList(Object? value, List<String> fallback) {
  if (value is! List) {
    return fallback;
  }
  final parsed = value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  return parsed.isEmpty ? fallback : parsed;
}

List<FaqConfig> _faqList(Object? value, List<FaqConfig> fallback) {
  if (value is! List) {
    return fallback;
  }
  final parsed = <FaqConfig>[];
  for (final item in value) {
    if (item is Map) {
      parsed.add(
        FaqConfig.fromJson(Map<String, Object?>.from(item), fallback.first),
      );
    }
  }
  return parsed.isEmpty ? fallback : List<FaqConfig>.unmodifiable(parsed);
}

List<OnboardingSlideConfig> _slideList(
  Object? value,
  List<OnboardingSlideConfig> fallback,
) {
  if (value is! List) {
    return fallback;
  }
  final parsed = <OnboardingSlideConfig>[];
  for (var index = 0; index < value.length; index++) {
    final item = value[index];
    if (item is Map) {
      final itemFallback = index < fallback.length
          ? fallback[index]
          : fallback.first;
      parsed.add(
        OnboardingSlideConfig.fromJson(
          Map<String, Object?>.from(item),
          itemFallback,
        ),
      );
    }
  }
  return parsed.isEmpty
      ? fallback
      : List<OnboardingSlideConfig>.unmodifiable(parsed);
}
