import 'package:fin_track/domain/entities/configuration.dart';
import 'package:fin_track/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widget_test_helpers.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('local authentication blocks app until correct PIN', (
    tester,
  ) async {
    const channel = MethodChannel('fin_track/native');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return switch (call.method) {
            'pendingSharedFiles' => <String>[],
            'authenticateLocalPin' =>
              (call.arguments as Map<Object?, Object?>)['pin'] == '1234',
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
    await dependencies.configurationService.update(
      (await dependencies.configurationService.load()).copyWith(
        onboardingCompleted: true,
        localAuthEnabled: true,
        authenticationType: AuthenticationType.pin,
      ),
    );

    await tester.pumpWidget(FinTrackApp(dependencies: dependencies));
    await pumpFrames(tester);

    expect(find.text('FinTrack bloqueado'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Desbloquear').last);
    await pumpFrames(tester);

    expect(find.text('FinTrack bloqueado'), findsNothing);
    expect(find.text('Nenhum comprovante registrado'), findsOneWidget);

    await disposeWidgetDependencies(tester, dependencies);
  });
}
