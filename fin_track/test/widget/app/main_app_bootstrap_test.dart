import 'package:fin_track/domain/entities/configuration.dart';
import 'package:fin_track/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';

import '../main_app_test_helpers.dart';
import '../presentation_mocks.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  test('loadInitialConfiguration returns loaded configuration', () async {
    final configurationService = MockIConfigurationService();
    final dependencies = mainAppDependencies(
      configurationService: configurationService,
    );
    const configuration = Configuration(
      id: 7,
      visualThemeMode: VisualThemeMode.light,
    );
    when(configurationService.load()).thenAnswer((_) async => configuration);

    final result = await loadInitialConfiguration(dependencies);

    expect(result, configuration);
    await dependencies.database.close();
  });

  test('loadInitialConfiguration uses fallback when service fails', () async {
    final configurationService = MockIConfigurationService();
    final dependencies = mainAppDependencies(
      configurationService: configurationService,
    );
    when(configurationService.load()).thenThrow(StateError('sem config'));

    final result = await loadInitialConfiguration(dependencies);

    expect(result, const Configuration(id: 1));
    await dependencies.database.close();
  });
}
