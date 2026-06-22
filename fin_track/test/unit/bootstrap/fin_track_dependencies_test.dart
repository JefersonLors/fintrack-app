import 'dart:io';

import 'package:fin_track/bootstrap/fin_track_dependencies.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(pathProviderChannel, null);
  });

  test('local uses provided image directory and can be disposed', () async {
    final temp = await Directory.systemTemp.createTemp('fintrack_deps_test_');
    addTearDown(() async {
      if (await temp.exists()) {
        await temp.delete(recursive: true);
      }
    });

    final dependencies = FinTrackDependencies.local(
      imagesDirectory: Directory(p.join(temp.path, 'receipts')),
    );
    addTearDown(dependencies.dispose);

    expect(dependencies.receiptService, isNotNull);
    expect(dependencies.backupService, isNotNull);
    expect(dependencies.configurationService, isNotNull);
    expect(dependencies.categoryService, isNotNull);
    expect(dependencies.localAuthenticationService, isNotNull);
    expect(dependencies.problemReportService, isNotNull);
    expect(dependencies.appConfig.app.displayName, 'FinTrack');
  });

  test('local without directory uses default temporary storage', () {
    final dependencies = FinTrackDependencies.local();
    addTearDown(dependencies.dispose);

    expect(dependencies.receiptService, isNotNull);
    expect(dependencies.configurationService, isNotNull);
  });

  test(
    'persistent builds dependencies with platform documents directory',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'fintrack_persistent_test_',
      );
      messenger.setMockMethodCallHandler(pathProviderChannel, (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return temp.path;
        }
        return null;
      });
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });

      final dependencies = await FinTrackDependencies.persistent();
      addTearDown(dependencies.dispose);

      expect(dependencies.appConfig.app.displayName, isNotEmpty);
      expect(dependencies.configurationService, isNotNull);
    },
  );
}
