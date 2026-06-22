import 'dart:io';

import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/entities/configuration.dart';
import 'package:fin_track/domain/value_objects/receipt_filter.dart';
import 'package:fin_track/main.dart';
import 'package:fin_track/presentation/receipts/pages/receipt_confirmation_page.dart';
import 'package:fin_track/presentation/widgets/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widget_test_helpers.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('confirmation shows shared temporary image preview', (
    tester,
  ) async {
    final file = File(
      '${Directory.systemTemp.path}/fin_track_share_preview_${DateTime.now().microsecondsSinceEpoch}.png',
    )..writeAsBytesSync(testPngBytes);
    addTearDown(() {
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    final dependencies = widgetDependencies();
    addTearDown(() async {
      await disposeWidgetDependencies(tester, dependencies);
    });

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: MaterialApp(
          home: ReceiptConfirmationPage(
            receipt: Receipt(
              id: 0,
              type: ReceiptType.other,
              expense: true,
              fileName: file.path,
              fileType: 'image/png',
              fileSize: file.lengthSync(),
              extractedContent: '',
              registeredAt: DateTime(2026, 4, 30),
            ),
          ),
        ),
      ),
    );
    await pumpFrames(tester);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(find.text('Confirmar dados'), findsOneWidget);
    expect(file.existsSync(), isTrue);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is FileImage &&
            (widget.image as FileImage).file.path == file.path,
      ),
      findsOneWidget,
    );
    expect(find.text(file.path), findsNothing);

    await disposeWidgetDependencies(tester, dependencies);
  });

  testWidgets('protected shared import discards file without PIN', (
    tester,
  ) async {
    const channel = MethodChannel('fin_track/native');
    final file = File(
      '${Directory.systemTemp.path}/fin_track_share_auth_${DateTime.now().microsecondsSinceEpoch}.txt',
    )..writeAsStringSync('temporary receipt');
    var consumed = false;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'pendingSharedFiles') {
            if (consumed) {
              return <String>[];
            }
            consumed = true;
            return <String>[file.path];
          }
          if (call.method == 'authenticateLocalPin') {
            return false;
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      if (file.existsSync()) {
        file.deleteSync();
      }
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

    await tester.enterText(find.byType(TextField).last, '9999');
    await tester.tap(find.widgetWithText(FilledButton, 'Desbloquear').last);
    await pumpFrames(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(file.existsSync(), isFalse);
    expect(
      await tester.runAsync(
        () => dependencies.receiptService.findByFilters(const ReceiptFilter()),
      ),
      isEmpty,
    );
    expect(find.text('Processando'), findsNothing);

    await disposeWidgetDependencies(tester, dependencies);
  });
}
