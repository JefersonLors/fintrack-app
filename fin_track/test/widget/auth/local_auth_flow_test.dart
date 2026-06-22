import 'dart:async';

import 'package:fin_track/domain/entities/configuration.dart';
import 'package:fin_track/domain/value_objects/biometric_status.dart';
import 'package:fin_track/presentation/authentication/authentication_gate.dart';
import 'package:fin_track/presentation/authentication/local_auth_flow.dart';
import 'package:fin_track/presentation/widgets/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';

import '../presentation_mockito_helpers.dart';
import '../presentation_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('creates PIN when validation fails and confirmation differs', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final auth = MockILocalAuthenticationService();
    final dependencies = testDependencies(service, localAuthService: auth);

    when(auth.savePin(any)).thenAnswer((_) async => false);

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => LocalAuthFlow.createPin(context),
                child: const Text('Criar PIN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Criar PIN'));
      await tester.pumpAndSettle();
      expect(find.text('Criar PIN'), findsWidgets);

      await tester.enterText(find.byType(TextField), '123');
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(find.text('Informe ao menos 4 dígitos.'), findsOne);

      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(find.text('Confirmar PIN'), findsOne);

      await tester.enterText(find.byType(TextField), '4321');
      await tester.tap(find.text('Salvar PIN'));
      await tester.pump();
      expect(find.text('Os PINs não conferem. Comece novamente.'), findsOne);

      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Salvar PIN'));
      await tester.pumpAndSettle();

      verify(auth.savePin('1234')).called(1);
      expect(
        find.text('Não foi possível salvar o PIN de forma segura.'),
        findsOne,
      );
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('authenticates user when PIN and biometrics are used', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final auth = MockILocalAuthenticationService();
    final dependencies = testDependencies(service, localAuthService: auth);
    var pinResult = false;

    when(auth.authenticatePin(any)).thenAnswer((_) async => pinResult);
    when(auth.removePin()).thenAnswer((_) async => true);
    when(auth.checkBiometrics()).thenAnswer(
      (_) async => const BiometricStatus(
        available: false,
        message: 'Biometria indisponível',
      ),
    );

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  FilledButton(
                    onPressed: () => LocalAuthFlow.authenticate(
                      context,
                      const Configuration(
                        id: 1,
                        localAuthEnabled: true,
                        authenticationType: AuthenticationType.pin,
                      ),
                      reason: 'Motivo do teste',
                    ),
                    child: const Text('Autenticar PIN'),
                  ),
                  FilledButton(
                    onPressed: () => LocalAuthFlow.configureBiometrics(context),
                    child: const Text('Biometria'),
                  ),
                  FilledButton(
                    onPressed: () => LocalAuthFlow.removePin(context),
                    child: const Text('Remover PIN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Autenticar PIN'));
      await tester.pumpAndSettle();
      expect(find.text('Motivo do teste'), findsOne);

      await tester.enterText(find.byType(TextField), '123');
      await tester.tap(find.text('Desbloquear'));
      await tester.pump();
      expect(find.text('Informe o PIN cadastrado.'), findsOne);

      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Desbloquear'));
      await tester.pumpAndSettle();
      expect(find.text('PIN incorreto. Acesso não autorizado.'), findsOne);

      pinResult = true;
      await tester.tap(find.text('Autenticar PIN'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Desbloquear'));
      await tester.pumpAndSettle();
      verify(auth.authenticatePin('1234')).called(greaterThanOrEqualTo(2));

      await tester.tap(find.text('Biometria'));
      await tester.pump();
      verify(auth.checkBiometrics()).called(1);

      when(auth.checkBiometrics()).thenAnswer(
        (_) async => const BiometricStatus(available: true, message: 'ok'),
      );
      when(
        auth.authenticateBiometrics(
          title: anyNamed('title'),
          subtitle: anyNamed('subtitle'),
        ),
      ).thenAnswer((_) async => false);

      await tester.tap(find.text('Biometria'));
      await tester.pump();
      verify(
        auth.authenticateBiometrics(
          title: anyNamed('title'),
          subtitle: anyNamed('subtitle'),
        ),
      ).called(1);

      await tester.tap(find.text('Remover PIN'));
      await tester.pump();
      verify(auth.removePin()).called(1);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('blocks content when PIN is required', (tester) async {
    final service = MockIReceiptService();
    final configurationService = MockIConfigurationService();
    final auth = MockILocalAuthenticationService();
    final controller = StreamController<Configuration>();
    final navigatorKey = GlobalKey<NavigatorState>();
    final gateKey = GlobalKey<AuthenticationGateState>();
    final dependencies = testDependencies(
      service,
      configurationService: configurationService,
      localAuthService: auth,
    );
    const config = Configuration(
      id: 1,
      localAuthEnabled: true,
      authenticationType: AuthenticationType.pin,
      autoLockIntervalMinutes: 0,
    );

    when(configurationService.watch()).thenAnswer((_) => controller.stream);
    when(configurationService.load()).thenAnswer((_) async => config);
    when(auth.authenticatePin('1111')).thenAnswer((_) async => false);
    when(auth.authenticatePin('1234')).thenAnswer((_) async => true);

    try {
      await tester.pumpWidget(
        AppScope(
          dependencies: dependencies,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: AuthenticationGate(
              key: gateKey,
              navigatorKey: navigatorKey,
              child: const Scaffold(body: Text('Conteúdo protegido')),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Verificando proteção local'), findsOne);

      controller.add(config);
      await tester.pumpAndSettle();
      expect(find.text('FinTrack bloqueado'), findsOne);

      await tester.enterText(find.byType(TextField), '123');
      await tester.tap(find.text('Desbloquear'));
      await tester.pump();
      expect(find.text('Informe o PIN cadastrado.'), findsOne);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('FinTrack bloqueado'), findsOne);

      await tester.enterText(find.byType(TextField), '1111');
      await tester.tap(find.text('Desbloquear'));
      await tester.pumpAndSettle();
      verify(auth.authenticatePin('1111')).called(1);

      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Desbloquear'));
      await tester.pumpAndSettle();
      verify(auth.authenticatePin('1234')).called(1);
      expect(find.text('Conteúdo protegido'), findsOne);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('FinTrack bloqueado'), findsOne);

      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Desbloquear'));
      await tester.pumpAndSettle();
      verify(auth.authenticatePin('1234')).called(1);
      expect(find.text('Conteúdo protegido'), findsOne);
    } finally {
      await controller.close();
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('returns result when local configuration is incomplete', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final dependencies = testDependencies(service);
    final results = <bool>[];

    try {
      await tester.pumpWidget(
        testHost(
          dependencies,
          Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  FilledButton(
                    onPressed: () async {
                      results.add(
                        await LocalAuthFlow.authenticate(
                          context,
                          const Configuration(id: 1),
                        ),
                      );
                    },
                    child: const Text('Sem proteção'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      results.add(
                        await LocalAuthFlow.authenticate(
                          context,
                          const Configuration(id: 1, localAuthEnabled: true),
                        ),
                      );
                    },
                    child: const Text('Sem type'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sem proteção'));
      await tester.pump();
      await tester.tap(find.text('Sem type'));
      await tester.pump();

      expect(results, [true, false]);
    } finally {
      await disposeTestApp(tester, dependencies);
    }
  });

  testWidgets('unlocks content when biometrics become available', (
    tester,
  ) async {
    final service = MockIReceiptService();
    final configurationService = MockIConfigurationService();
    final auth = MockILocalAuthenticationService();
    final controller = StreamController<Configuration>();
    final navigatorKey = GlobalKey<NavigatorState>();
    final dependencies = testDependencies(
      service,
      configurationService: configurationService,
      localAuthService: auth,
    );
    const config = Configuration(
      id: 1,
      localAuthEnabled: true,
      authenticationType: AuthenticationType.biometric,
    );

    when(configurationService.watch()).thenAnswer((_) => controller.stream);
    when(configurationService.load()).thenAnswer((_) async => config);
    when(auth.checkBiometrics()).thenAnswer(
      (_) async => const BiometricStatus(
        available: false,
        message: 'Biometria fora do ar',
      ),
    );
    when(
      auth.authenticateBiometrics(
        title: anyNamed('title'),
        subtitle: anyNamed('subtitle'),
      ),
    ).thenAnswer((_) async => true);

    try {
      await tester.pumpWidget(
        AppScope(
          dependencies: dependencies,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: AuthenticationGate(
              navigatorKey: navigatorKey,
              child: const Scaffold(body: Text('Área protegida')),
            ),
          ),
        ),
      );
      controller.add(config);
      await tester.pumpAndSettle();

      expect(find.text('Biometria fora do ar'), findsWidgets);
      expect(find.text('Desbloquear'), findsOne);

      when(auth.checkBiometrics()).thenAnswer(
        (_) async => const BiometricStatus(available: true, message: 'ok'),
      );
      await tester.tap(find.text('Desbloquear'));
      await tester.pumpAndSettle();

      expect(find.text('Área protegida'), findsOne);
      verify(
        auth.authenticateBiometrics(
          title: 'Desbloquear FinTrack',
          subtitle: anyNamed('subtitle'),
        ),
      ).called(1);
    } finally {
      await controller.close();
      await disposeTestApp(tester, dependencies);
    }
  });
}
