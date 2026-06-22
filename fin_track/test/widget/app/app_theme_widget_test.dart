import 'package:fin_track/domain/entities/category.dart';
import 'package:fin_track/domain/entities/configuration.dart';
import 'package:fin_track/main.dart';
import 'package:fin_track/presentation/theme/fin_track_theme.dart';
import 'package:fin_track/presentation/widgets/category_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widget_test_helpers.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  test('light and dark themes register semantic colors', () {
    final darkColors = FinTrackTheme.dark().extension<FinTrackColorScheme>()!;
    final lightColors = FinTrackTheme.light().extension<FinTrackColorScheme>()!;

    expect(darkColors.surface, isNot(lightColors.surface));
    expect(darkColors.textPrimary, isNot(lightColors.textPrimary));
    expect(lightColors.background.computeLuminance(), greaterThan(0.8));
    expect(darkColors.background.computeLuminance(), lessThan(0.05));
  });

  testWidgets('category without color gets contrast in light theme', (
    tester,
  ) async {
    const category = Category(id: 1, name: 'Sem cor');
    late Color darkColor;
    late Color lightColor;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            return Theme(
              data: FinTrackTheme.dark(),
              child: Builder(
                builder: (context) {
                  darkColor = categoryColorFor(category, context);
                  return const SizedBox.shrink();
                },
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            return Theme(
              data: FinTrackTheme.light(),
              child: Builder(
                builder: (context) {
                  lightColor = categoryColorFor(category, context);
                  return const SizedBox.shrink();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(darkColor.toARGB32(), 0xFFD2D8E3);
    expect(lightColor.toARGB32(), 0xFF5F8FA3);
    expect(
      lightColor.computeLuminance(),
      lessThan(darkColor.computeLuminance()),
    );
  });

  testWidgets('uses initial configuration for first-frame theme', (
    tester,
  ) async {
    final dependencies = widgetDependencies();

    await tester.pumpWidget(
      FinTrackApp(
        dependencies: dependencies,
        initialConfiguration: const Configuration(
          id: 1,
          visualThemeMode: VisualThemeMode.light,
        ),
      ),
    );

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final colors = materialApp.theme!.extension<FinTrackColorScheme>()!;
    expect(colors.background.toARGB32(), 0xFFF6F8FB);

    await disposeWidgetDependencies(tester, dependencies);
  });
}
