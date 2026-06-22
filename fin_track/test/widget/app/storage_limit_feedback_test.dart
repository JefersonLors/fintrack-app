import 'package:fin_track/bootstrap/fin_track_dependencies.dart';
import 'package:fin_track/domain/exceptions/storage_limit_exception.dart';
import 'package:fin_track/presentation/theme/fin_track_theme.dart';
import 'package:fin_track/presentation/widgets/app_scope.dart';
import 'package:fin_track/presentation/widgets/storage_limit_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('storage limit snackbar can be shown and hidden', (tester) async {
    final key = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      _host(
        Scaffold(
          key: key,
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showStorageLimitSnackBar(
                context,
                const StorageLimitException('limit'),
                avoidScanButton: true,
              ),
              child: const Text('Mostrar limite'),
            ),
          ),
        ),
      ),
    );

    expect(isStorageLimitError(const StorageLimitException('limit')), isTrue);
    expect(isStorageLimitError(StateError('outro')), isFalse);

    await tester.tap(find.text('Mostrar limite'));
    await tester.pump();

    expect(find.text('Limite de armazenamento atingido.'), findsOneWidget);
    expect(find.text('Ajustar'), findsOneWidget);

    hideStorageLimitSnackBarIfVisible();
    await tester.pumpAndSettle();

    expect(find.text('Limite de armazenamento atingido.'), findsNothing);
  });

  testWidgets('storage limit snackbar opens settings through action', (
    tester,
  ) async {
    final dependencies = FinTrackDependencies.local();

    try {
      await tester.pumpWidget(
        AppScope(
          dependencies: dependencies,
          child: MaterialApp(
            theme: FinTrackTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () => showStorageLimitSnackBar(
                    context,
                    const StorageLimitException('limit'),
                  ),
                  child: const Text('Mostrar ajuste'),
                ),
              ),
            ),
          ),
        ),
      );

      hideStorageLimitSnackBarIfVisible();
      await tester.tap(find.text('Mostrar ajuste'));
      await tester.pump();
      tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
      await tester.pumpAndSettle();

      expect(find.text('Configurações'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      dependencies.dispose();
    }
  });
}

Widget _host(Widget child) {
  return MaterialApp(theme: FinTrackTheme.light(), home: child);
}
