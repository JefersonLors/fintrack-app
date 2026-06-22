import 'package:fin_track/domain/entities/configuration.dart';
import 'package:fin_track/domain/entities/cloud_provider.dart';
import 'package:fin_track/presentation/configuration/pages/configuration_page.dart';
import 'package:fin_track/presentation/widgets/app_dropdown_field.dart';
import 'package:fin_track/presentation/widgets/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widget_test_helpers.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('configurations blocks automatic backup without Google account', (
    tester,
  ) async {
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

    expect(find.text('Backup automático'), findsOneWidget);
    expect(find.text('Configure backups automáticos.'), findsOneWidget);
    expect(find.text('Abrir Backup'), findsNothing);

    final switchTile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Backup automático'),
    );
    final slider = tester.widget<Slider>(find.byType(Slider).first);
    expect(switchTile.onChanged, isNotNull);
    expect(slider.onChanged, isNull);

    switchTile.onChanged!(true);
    await pumpFrames(tester);

    expect(find.text('Senha necessária'), findsOneWidget);
    expect(
      find.text(
        'Para ativar o backup automático, defina uma senha de backup primeiro.',
      ),
      findsOneWidget,
    );

    expect(find.text('Ok'), findsOneWidget);

    await tester.tap(find.text('Ok'));
    await pumpFrames(tester);

    await dependencies.configurationService.update(
      (await dependencies.configurationService.load()).copyWith(
        backupPassword: 'segredo123',
        cloudProvider: CloudProvider.googleDrive,
        linkedCloudAccount: 'usuario@fintrack.test',
        cloudTokenValid: true,
      ),
    );
    await pumpFrames(tester);

    tester
        .widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, 'Backup automático'),
        )
        .onChanged!(true);
    await pumpFrames(tester);

    expect(find.text('Backup automático definido.'), findsOneWidget);
    expect(
      (await dependencies.configurationService.load()).backupReminderEnabled,
      isTrue,
    );

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets('configurations saves light mode through theme button', (
    tester,
  ) async {
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

    expect(
      (await dependencies.configurationService.load()).visualThemeMode,
      VisualThemeMode.dark,
    );

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await pumpFrames(tester);

    expect(
      (await dependencies.configurationService.load()).visualThemeMode,
      VisualThemeMode.light,
    );

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await pumpFrames(tester);

    expect(
      (await dependencies.configurationService.load()).visualThemeMode,
      VisualThemeMode.dark,
    );

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets('configurations changes backup limit and password', (
    tester,
  ) async {
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

    final storageSlider = tester.widget<Slider>(find.byType(Slider).last);
    storageSlider.onChanged!(750);
    await pumpFrames(tester);

    expect(
      (await dependencies.configurationService.load()).storageLimitMB,
      750,
    );

    await tester.tap(find.text('Senha de backup'));
    await tester.pumpAndSettle();
    expect(find.text('Definir senha de backup'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nova senha'),
      'segredo123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar nova senha'),
      'segredo123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(
      (await dependencies.configurationService.load()).backupPassword,
      'segredo123',
    );
    expect(find.text('Remover senha'), findsOneWidget);

    await tester.tap(find.text('Remover senha'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha atual'),
      'errada',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Remover'));
    await tester.pumpAndSettle();
    expect(find.text('Senha atual incorreta.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha atual'),
      'segredo123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Remover'));
    await tester.pumpAndSettle();

    expect(
      (await dependencies.configurationService.load()).backupPassword,
      isNull,
    );

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets('exit button shows confirmation before closing', (tester) async {
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

    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('Sair'), findsOneWidget);
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.text('Sair do FinTrack?'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets(
    'configurations enables local authentication with confirmed PIN',
    (tester) async {
      const channel = MethodChannel('fin_track/native');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return switch (call.method) {
              'saveLocalPin' => true,
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
          child: const MaterialApp(home: ConfigurationPage(isActive: false)),
        ),
      );
      await pumpFrames(tester);

      await tester.scrollUntilVisible(
        find.text('Autenticação local'),
        400,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Autenticação local'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Escolha a proteção'), findsOneWidget);
      await tester.tap(find.text('PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Criar PIN'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar PIN'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Salvar PIN'));
      await tester.pumpAndSettle();

      final configuration = await dependencies.configurationService.load();
      expect(configuration.localAuthEnabled, isTrue);
      expect(configuration.authenticationType, AuthenticationType.pin);
      expect(find.text('Bloqueio automático'), findsOneWidget);
      expect(find.text('5 minutos'), findsOneWidget);

      await tester.tap(find.text('5 minutos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Imediatamente').last);
      await tester.pumpAndSettle();

      expect(
        (await dependencies.configurationService.load())
            .autoLockIntervalMinutes,
        0,
      );
      expect(
        calls.any(
          (call) =>
              call.method == 'saveLocalPin' &&
              (call.arguments as Map<Object?, Object?>)['pin'] == '1234',
        ),
        isTrue,
      );

      await disposeWidgetDependencies(tester, dependencies);
    },
  );

  testWidgets(
    'configurations does not persist PIN when creation is cancelled',
    (tester) async {
      const channel = MethodChannel('fin_track/native');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return switch (call.method) {
              'saveLocalPin' => true,
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
          child: const MaterialApp(home: ConfigurationPage(isActive: false)),
        ),
      );
      await pumpFrames(tester);

      await tester.scrollUntilVisible(
        find.text('Autenticação local'),
        400,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Autenticação local'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Escolha a proteção'), findsOneWidget);
      await tester.tap(find.text('PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Criar PIN'), findsOneWidget);
      var configuration = await dependencies.configurationService.load();
      expect(configuration.localAuthEnabled, isFalse);
      expect(configuration.authenticationType, isNull);

      await tester.tap(find.text('Cancelar'));
      await pumpFrames(tester);
      await tester.pump(const Duration(milliseconds: 300));

      configuration = await dependencies.configurationService.load();
      expect(configuration.localAuthEnabled, isFalse);
      expect(configuration.authenticationType, isNull);
      expect(calls.where((call) => call.method == 'saveLocalPin'), isEmpty);
      expect(
        find.textContaining('Configuração do PIN não concluída'),
        findsOneWidget,
      );

      await disposeWidgetDependencies(tester, dependencies);
    },
  );

  testWidgets('configurations keeps previous method when biometrics fail', (
    tester,
  ) async {
    const channel = MethodChannel('fin_track/native');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'authenticateLocalPin' => true,
            'checkBiometrics' => <String, Object?>{
              'available': true,
              'message': 'Biometria disponível.',
            },
            'authenticateBiometrics' => false,
            'removeLocalPin' => true,
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
        localAuthEnabled: true,
        authenticationType: AuthenticationType.pin,
        onboardingCompleted: true,
      ),
    );

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: const MaterialApp(home: ConfigurationPage(isActive: false)),
      ),
    );
    await pumpFrames(tester);

    await tester.scrollUntilVisible(
      find.text('Método de proteção'),
      400,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    final methodDropdown = find.byType(AppDropdownField<AuthenticationType>);
    expect(methodDropdown, findsOneWidget);

    await tester.tap(methodDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Biometria').last);
    await tester.pumpAndSettle();

    expect(
      (await dependencies.configurationService.load()).authenticationType,
      AuthenticationType.pin,
    );

    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Desbloquear'));
    await pumpFrames(tester);
    await tester.pump(const Duration(milliseconds: 300));

    final configuration = await dependencies.configurationService.load();
    final dropdown = tester.widget<AppDropdownField<AuthenticationType>>(
      methodDropdown,
    );

    expect(configuration.authenticationType, AuthenticationType.pin);
    expect(dropdown.initialValue, AuthenticationType.pin);
    expect(find.text('A biometria não foi confirmada.'), findsOneWidget);
    expect(calls.where((call) => call.method == 'removeLocalPin'), isEmpty);

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets('configurations disables local auth and opens utility actions', (
    tester,
  ) async {
    const channel = MethodChannel('fin_track/native');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'authenticateLocalPin' => true,
            'removeLocalPin' => true,
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
        localAuthEnabled: true,
        authenticationType: AuthenticationType.pin,
      ),
    );

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: const MaterialApp(home: ConfigurationPage(isActive: false)),
      ),
    );
    await pumpFrames(tester);

    await tester.tap(find.widgetWithText(ListTile, 'Backup'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Autenticação local'),
      400,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, 'Autenticação local'));
    await tester.pumpAndSettle();

    expect(find.text('Desbloquear'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Desbloquear'));
    await pumpFrames(tester);
    await tester.pump(const Duration(milliseconds: 300));

    final configuration = await dependencies.configurationService.load();
    expect(configuration.localAuthEnabled, isFalse);
    expect(configuration.authenticationType, isNull);
    expect(find.text('Autenticação local desativada.'), findsOneWidget);
    expect(calls.map((call) => call.method), contains('removeLocalPin'));

    await tester.scrollUntilVisible(
      find.text('Ver tutorial'),
      400,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Ver tutorial'));
    await tester.pumpAndSettle();
    expect(
      (await dependencies.configurationService.load()).onboardingCompleted,
      isFalse,
    );
    expect(find.text('Tutorial reiniciado.'), findsNothing);

    await disposeWidgetDependencies(tester, dependencies);
  });
}
