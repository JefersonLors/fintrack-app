import 'package:fin_track/presentation/configuration/pages/configuration_page.dart';
import 'package:fin_track/presentation/configuration/about_fin_track_page.dart';
import 'package:fin_track/presentation/widgets/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widget_test_helpers.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('settings navigates to About FinTrack with FAQ', (tester) async {
    final dependencies = widgetDependencies();
    addTearDown(() async {
      await disposeWidgetDependencies(tester, dependencies);
    });

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: const MaterialApp(home: ConfigurationPage(isActive: false)),
      ),
    );
    await pumpFrames(tester);

    expect(find.text('Configurações de backup'), findsOneWidget);
    expect(find.text('Consumo de espaço e limites'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Proteção do aplicativo'), findsOneWidget);
    expect(find.text('Privacidade'), findsNothing);
    await tester.ensureVisible(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(find.text('Sair'), findsOneWidget);

    await tester.ensureVisible(find.text('Sobre o FinTrack'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sobre o FinTrack').last);
    await tester.pumpAndSettle();

    expect(find.text('FinTrack'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Dúvidas frequentes'),
      find.byType(ListView).last,
      const Offset(0, -300),
    );

    expect(find.text('Dúvidas frequentes'), findsOneWidget);

    await tester.tap(find.text('Onde meus dados ficam armazenados?'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('armazenados no próprio dispositivo'),
      findsOneWidget,
    );

    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.textContaining('Versão '), findsOneWidget);

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets('about FinTrack confirms report before opening email', (
    tester,
  ) async {
    const channel = MethodChannel('fin_track/native');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'getDeviceInfo' => <String, String>{
              'androidVersion': 'Android 16 (SDK 36)',
              'deviceModel': 'Pixel 9',
            },
            'openReportEmail' => true,
            _ => null,
          };
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final dependencies = widgetDependencies();
    addTearDown(() async {
      await disposeWidgetDependencies(tester, dependencies);
    });

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: const MaterialApp(home: AboutFinTrackPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Reportar problema'),
      500,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reportar problema'));
    await tester.pumpAndSettle();

    expect(find.text('Descreva o que aconteceu'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Falha ao abrir relatório');
    tester.testTextInput.hide();
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Abrir e-mail de reporte?'), findsOneWidget);
    expect(calls, isEmpty);

    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Abrir e-mail'))
        .onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Abrir e-mail de reporte?'), findsNothing);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (calls.any((call) => call.method == 'openReportEmail')) {
        break;
      }
    }

    expect(calls.map((call) => call.method), contains('openReportEmail'));
    final emailCall = calls.singleWhere(
      (call) => call.method == 'openReportEmail',
    );
    final arguments = Map<Object?, Object?>.from(
      emailCall.arguments as Map<Object?, Object?>,
    );
    final body = arguments['body']! as String;

    expect(arguments['recipient'], '20212160060+Suporte_FinTrack@ifba.edu.br');
    expect(arguments['subject'], '[FinTrack] Reporte de problema');
    expect(body, contains('Falha ao abrir relatório'));
    expect(body, contains(RegExp(r'Versão do aplicativo: \d+\.\d+\.\d+\+\d+')));
    expect(body, contains('Android 16 (SDK 36)'));
    expect(body, contains('Pixel 9'));
  });
}
