import 'package:fin_track/presentation/theme/fin_track_theme.dart';
import 'package:fin_track/presentation/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('state views show actions and compact states', (tester) async {
    var actionCalled = false;
    var retryCalled = false;

    await tester.pumpWidget(
      _host(
        SizedBox(
          height: 260,
          child: Column(
            children: [
              Expanded(
                child: EmptyView(
                  title: 'Sem comprovantes',
                  message: 'Registre um comprovante para começar.',
                  icon: Icons.receipt_long_outlined,
                  actionLabel: 'Adicionar',
                  onAction: () => actionCalled = true,
                ),
              ),
              ErrorStateView(
                message: 'Falha ao load.',
                onRetry: () => retryCalled = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Sem comprovantes'), findsOneWidget);
    expect(find.text('Falha ao load.'), findsOneWidget);

    await tester.tap(find.text('Adicionar'));
    await tester.tap(find.text('Tentar novamente'));

    expect(actionCalled, isTrue);
    expect(retryCalled, isTrue);
  });

  testWidgets('loading and section header render auxiliary content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            LoadingView(message: 'Aguarde'),
            SectionHeader('Resumo', action: Icon(Icons.info_outline)),
          ],
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Aguarde'), findsOneWidget);
    expect(find.text('Resumo'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });
}

Widget _host(Widget child) {
  return MaterialApp(theme: FinTrackTheme.light(), home: child);
}
