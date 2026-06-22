import 'dart:async';

import 'package:fin_track/main.dart';
import 'package:fin_track/presentation/authentication/authentication_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockito/mockito.dart';

import '../main_app_test_helpers.dart';
import '../presentation_mockito_helpers.dart';
import '../presentation_mocks.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('imports shared batch received by native listener', (
    tester,
  ) async {
    final receiptService = MockIReceiptService();
    final dependencies = mainAppDependencies(receiptService: receiptService);
    final firstItem = tempFile('batch_1.txt');
    final secondItem = tempFile('batch_2.txt');
    final platform = FakeFinTrackPlatformGateway();
    when(receiptService.validateSpaceForNewReceipt()).thenAnswer((_) async {});
    when(
      receiptService.validateSpaceForNewReceipt(any),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      FinTrackApp(
        dependencies: dependencies,
        platformGateway: platform,
        sharedFilePageBuilder: singleSharedFilePage,
        sharedFileBatchPageBuilder: batchSharedFilePage,
        waitBeforeSharedFileNavigation: noNavigationWait,
      ),
    );
    await pumpAppFrames(tester);

    expect(find.byType(AuthenticationGate), findsOneWidget);
    expect(platform.listener, isNotNull);
    await tester.runAsync(() async {
      unawaited(platform.listener?.call([firstItem.path, secondItem.path]));
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await pumpAppFrames(tester);

    verify(receiptService.validateSpaceForNewReceipt(any)).called(2);
    expect(find.text('Lote compartilhado'), findsOneWidget);
    expect(find.text('2 files'), findsOneWidget);

    await tester.tap(find.text('Concluir lote'));
    await pumpAppFrames(tester);

    expect(firstItem.existsSync(), isFalse);
    expect(secondItem.existsSync(), isFalse);
    await disposeTestApp(tester, dependencies);
  });

  testWidgets('storage observer reacts to route remove and replace', (
    tester,
  ) async {
    final dependencies = mainAppDependencies();

    await tester.pumpWidget(FinTrackApp(dependencies: dependencies));
    await pumpAppFrames(tester);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
    final removeRoute = MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('remover rota')),
    );
    navigator.push(removeRoute);
    await pumpShortAppFrames(tester);
    navigator.removeRoute(removeRoute);
    await pumpShortAppFrames(tester);

    final replaceRoute = MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('rota antiga')),
    );
    navigator.push(replaceRoute);
    await pumpShortAppFrames(tester);
    navigator.replace(
      oldRoute: replaceRoute,
      newRoute: MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('rota nova')),
      ),
    );
    await pumpShortAppFrames(tester);

    expect(find.byType(Navigator), findsWidgets);

    await disposeTestApp(tester, dependencies);
  });
}
