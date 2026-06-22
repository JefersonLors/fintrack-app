import 'dart:async';

import 'package:fin_track/domain/entities/configuration.dart';
import 'package:fin_track/presentation/configuration/pages/configuration_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';

import '../presentation_mockito_helpers.dart';
import '../presentation_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('configurations shows error when stream fails', (tester) async {
    final service = MockIReceiptService();
    final configurationService = MockIConfigurationService();
    final dependencies = testDependencies(
      service,
      configurationService: configurationService,
    );
    final controller = StreamController<Configuration>();

    _stubBaseConfiguration(service, configurationService, controller);

    try {
      await tester.pumpWidget(
        testHost(dependencies, const ConfigurationPage(isActive: false)),
      );
      controller.addError(StateError('failure'));
      await tester.pump();

      expect(
        find.text('Não foi possível abrir as configurações.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
    } finally {
      await controller.close();
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('configurations shows exceeded storage and updates date', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final configurationService = MockIConfigurationService();
    final dependencies = testDependencies(
      service,
      configurationService: configurationService,
    );
    final controller = StreamController<Configuration>.broadcast();
    final config = const Configuration(id: 1, storageLimitMB: 2);

    _stubBaseConfiguration(
      service,
      configurationService,
      controller,
      config: config,
      espacoBytes: 3 * 1024 * 1024,
    );

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          const ConfigurationPage(scrollToStorageSection: true),
        ),
      );
      controller.add(config);
      await tester.pumpAndSettle();

      expect(find.text('Limite atingido'), findsOneWidget);
      expect(find.textContaining('3.00 MB de 2 MB'), findsOneWidget);
      expect(
        find.textContaining('O limite de armazenamento foi atingido'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Atualizar espaço'));
      await tester.pump();
      verify(service.deleteOrphanFiles()).called(greaterThanOrEqualTo(2));
    } finally {
      await controller.close();
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('configurations warns about high storage', (tester) async {
    final service = MockIReceiptService();
    final configurationService = MockIConfigurationService();
    final dependencies = testDependencies(
      service,
      configurationService: configurationService,
    );
    final controller = StreamController<Configuration>.broadcast();
    final config = const Configuration(id: 1, storageLimitMB: 2);

    _stubBaseConfiguration(
      service,
      configurationService,
      controller,
      config: config,
      espacoBytes: 1800 * 1024,
    );

    try {
      await tester.pumpWidget(
        testHost(dependencies, const ConfigurationPage(isActive: false)),
      );
      controller.add(config);
      await tester.pumpAndSettle();

      expect(find.text('Espaço alto'), findsOneWidget);
      expect(
        find.textContaining('acima de 85%. Considere liberar espaço'),
        findsOneWidget,
      );
    } finally {
      await controller.close();
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets(
    'configurations configure automatic backup with success and failure',
    (tester) async {
      final service = MockIReceiptService();
      final configurationService = MockIConfigurationService();
      final dependencies = testDependencies(
        service,
        configurationService: configurationService,
      );
      final controller = StreamController<Configuration>.broadcast();
      final config = const Configuration(
        id: 1,
        linkedCloudAccount: 'account@fintrack.test',
        cloudTokenValid: true,
        backupPassword: 'password-segura',
        backupReminderEnabled: true,
        reminderIntervalDays: 7,
      );
      var shouldFailBackup = false;

      _stubBaseConfiguration(
        service,
        configurationService,
        controller,
        config: config,
      );
      when(
        configurationService.configureAutomaticBackup(
          active: anyNamed('active'),
          intervalDays: anyNamed('intervalDays'),
        ),
      ).thenAnswer((_) async {
        if (shouldFailBackup) {
          throw StateError('failure');
        }
      });

      try {
        await tester.pumpWidget(
          testHost(dependencies, const ConfigurationPage(isActive: false)),
        );
        controller.add(config);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Backup automático'));
        await tester.pumpAndSettle();
        expect(find.text('Backup automático desativado.'), findsOneWidget);

        shouldFailBackup = true;
        ScaffoldMessenger.of(
          tester.element(find.text('Configurações')),
        ).clearSnackBars();
        await tester.drag(find.byType(Slider).first, const Offset(80, 0));
        await tester.pumpAndSettle();
        expect(
          find.text('Não foi possível configurar o backup automático.'),
          findsOneWidget,
        );
      } finally {
        await controller.close();
        await disposeTestApp(tester, dependencies);
      }
    },
  );

  testWidgets('configurations validates, changes, and removes backup password', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final configurationService = MockIConfigurationService();
    final dependencies = testDependencies(
      service,
      configurationService: configurationService,
    );
    final controller = StreamController<Configuration>.broadcast();
    final config = const Configuration(
      id: 1,
      backupPassword: 'password-antiga',
    );

    _stubBaseConfiguration(
      service,
      configurationService,
      controller,
      config: config,
    );

    try {
      await tester.pumpWidget(
        testHost(dependencies, const ConfigurationPage(isActive: false)),
      );
      controller.add(config);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Senha de backup'));
      await tester.pumpAndSettle();
      expect(find.text('Alterar senha de backup'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'errada');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password-antiga',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'password-antiga',
      );
      await tester.tap(find.text('Salvar'));
      await tester.pump();
      expect(find.text('Senha atual incorreta.'), findsOneWidget);
      expect(find.text('Use uma senha diferente da atual.'), findsOneWidget);

      await tester.tap(find.byTooltip('Mostrar senha'));
      await tester.pump();
      expect(find.byTooltip('Ocultar senha'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Senha de backup'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'password-antiga',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password-nova');
      await tester.enterText(find.byType(TextFormField).at(2), 'password-nova');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(find.text('Senha de backup atualizada.'), findsOneWidget);
      ScaffoldMessenger.of(
        tester.element(find.text('Configurações')),
      ).clearSnackBars();
      await tester.pump();

      await tester.tap(find.text('Remover senha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remover senha'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mostrar senha'));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'password-antiga');
      await tester.tap(find.text('Remover'));
      await tester.pump();

      expect(
        find.text(
          'Senha de backup removida. Defina outra para reativar backups automáticos.',
        ),
        findsOneWidget,
      );
      verify(configurationService.update(any)).called(greaterThanOrEqualTo(2));
    } finally {
      await controller.close();
      await disposeTestApp(tester, dependencies);
    }
  });
}

void _stubBaseConfiguration(
  MockIReceiptService service,
  MockIConfigurationService configurationService,
  StreamController<Configuration> controller, {
  Configuration config = const Configuration(id: 1),
  int espacoBytes = 0,
}) {
  stubReceiptStorage(service);
  when(configurationService.watch()).thenAnswer((_) => controller.stream);
  when(configurationService.load()).thenAnswer((_) async => config);
  when(configurationService.verifyCloudToken()).thenAnswer((_) async => true);
  when(
    configurationService.calculateUsedSpaceBytes(),
  ).thenAnswer((_) async => espacoBytes);
  when(configurationService.update(any)).thenAnswer((_) async {});
  when(configurationService.resetOnboarding()).thenAnswer((_) async {});
}
