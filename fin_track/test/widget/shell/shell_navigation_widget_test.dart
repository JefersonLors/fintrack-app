import 'package:fin_track/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widget_test_helpers.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('shows onboarding and then opens empty Search', (tester) async {
    final dependencies = widgetDependencies();

    await tester.pumpWidget(FinTrackApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.text('Escaneie com um toque'), findsOneWidget);

    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();

    expect(find.text('Arraste para buscar'), findsOneWidget);

    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();

    expect(find.text('Deslize entre abas'), findsOneWidget);

    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum comprovante registrado'), findsOneWidget);
    expect(find.text('Adicionar comprovante'), findsNothing);

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets('swipes horizontally to navigate navbar', (tester) async {
    final dependencies = widgetDependencies();
    addTearDown(() async {
      await disposeWidgetDependencies(tester, dependencies);
    });
    await dependencies.configurationService.update(
      (await dependencies.configurationService.load()).copyWith(
        onboardingCompleted: true,
      ),
    );

    await tester.pumpWidget(FinTrackApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum comprovante registrado'), findsOneWidget);

    await tester.dragFrom(const Offset(700, 300), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Categorias'), findsWidgets);
    expect(find.text('Alimentação'), findsOneWidget);

    await tester.dragFrom(const Offset(200, 300), const Offset(420, 0));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum comprovante registrado'), findsOneWidget);

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets('back button on main tab returns to search', (tester) async {
    final dependencies = widgetDependencies();
    addTearDown(() async {
      await disposeWidgetDependencies(tester, dependencies);
    });
    await dependencies.configurationService.update(
      (await dependencies.configurationService.load()).copyWith(
        onboardingCompleted: true,
      ),
    );

    await tester.pumpWidget(FinTrackApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Categorias').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajustes').last);
    await tester.pumpAndSettle();

    expect(find.text('Configurações de backup'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Nenhum comprovante registrado'), findsOneWidget);

    await disposeWidgetDependencies(tester, dependencies);
  });
}
