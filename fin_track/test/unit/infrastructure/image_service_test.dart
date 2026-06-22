import 'dart:io';

import 'package:fin_track/infrastructure/image/image_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('fin_track/native');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('captures and imports multiple through native channel', () async {
    final dir = await Directory.systemTemp.createTemp('fin_track_img_service_');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });
    final captured = File('${dir.path}/captured.jpg')..writeAsBytesSync([1]);
    final multiple1 = File('${dir.path}/multiple1.png')..writeAsBytesSync([3]);
    final multiple2 = File('${dir.path}/multiple2.png')..writeAsBytesSync([4]);
    final service = ImageService(baseDirectory: Directory('${dir.path}/base'));

    messenger.setMockMethodCallHandler(channel, (call) async {
      return switch (call.method) {
        'captureImage' => captured.path,
        'selectFiles' => [
          multiple1.path,
          '${dir.path}/missing.png',
          multiple2.path,
        ],
        _ => null,
      };
    });

    expect((await service.capture()).path, captured.path);
    expect((await service.importMany()).map((file) => file.path), [
      multiple1.path,
      multiple2.path,
    ]);
  });

  test('saves restores promotes reverts and removes managed files', () async {
    final dir = await Directory.systemTemp.createTemp('fin_track_img_files_');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });
    final base = Directory('${dir.path}/base');
    final external = File('${dir.path}/source receipt.txt')
      ..writeAsStringSync('content');
    final service = ImageService(baseDirectory: base);

    final name = await service.saveToFileSystem(external);
    expect(name, contains('source_receipt.txt'));
    expect(File(service.rebuildPath(name)).existsSync(), isTrue);
    expect(service.managedByApp(name), isTrue);

    final sameDirectory = File('${base.path}/internal.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('internal');
    expect(await service.saveToFileSystem(sameDirectory), 'internal.txt');

    final restored = await service.restoreToFileSystem(
      'restored?.txt',
      Uint8List.fromList([9, 8]),
    );
    expect(File(service.rebuildPath(restored)).readAsBytesSync(), [9, 8]);

    final session = await service.createTemporaryRestore();
    final temporary = await service.restoreToTemporaryDirectory(
      session,
      'new.txt',
      Uint8List.fromList([7]),
    );
    expect(File('${session.path}/$temporary').existsSync(), isTrue);
    await service.promoteTemporaryRestore(session);
    expect(File('${base.path}/$temporary').existsSync(), isTrue);

    final revertSession = await service.createTemporaryRestore();
    await service.restoreToTemporaryDirectory(
      revertSession,
      'swap.txt',
      Uint8List.fromList([6]),
    );
    await service.promoteTemporaryRestore(revertSession);
    await service.revertTemporaryRestore(revertSession);
    await service.discardTemporaryRestore(revertSession);

    await service.deleteIfManaged(temporary);
    expect(File('${base.path}/$temporary').existsSync(), isFalse);
  });

  test('share and save to device propagate boolean failures', () async {
    final dir = await Directory.systemTemp.createTemp('fin_track_img_share_');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });
    final base = Directory('${dir.path}/base');
    final file = File('${base.path}/a.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('a');
    final service = ImageService(baseDirectory: base);
    final calls = <String>[];

    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return switch (call.method) {
        'shareFile' => false,
        'shareFiles' => false,
        'saveFileToDevice' => false,
        'saveFilesToDevice' => false,
        _ => null,
      };
    });

    await expectLater(
      service.share(file.path, 'text/plain'),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      service.shareMany([file.path]),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      service.saveToDevice(file.path, 'text/plain'),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      service.saveManyToDevice([file.path]),
      throwsA(isA<StateError>()),
    );
    expect(
      calls,
      containsAll(<String>[
        'shareFile',
        'shareFiles',
        'saveFileToDevice',
        'saveFilesToDevice',
      ]),
    );
  });

  test('handles cancellations and absolute paths', () async {
    final dir = await Directory.systemTemp.createTemp('fin_track_img_paths_');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });
    final base = Directory('${dir.path}/base');
    final absolute = File('${dir.path}/absolute.txt')
      ..writeAsStringSync('absolute');
    final service = ImageService(baseDirectory: base);

    messenger.setMockMethodCallHandler(channel, (_) async => null);

    await expectLater(service.capture(), throwsA(isA<FormatException>()));
    await expectLater(service.importMany(), throwsA(isA<FormatException>()));
    expect(service.rebuildPath(absolute.path), absolute.path);

    final referenced = File('${base.path}/referenced.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('ok');
    final unreferenced = File('${base.path}/loose.txt')
      ..writeAsStringSync('trash');
    final bytes = await service.deleteUnreferencedFiles({referenced.path});
    expect(bytes, greaterThan(0));
    expect(await unreferenced.exists(), isFalse);

    await service.deleteAll();
    expect(await referenced.exists(), isFalse);
  });

  test('temporary restore runs rollback reversion and discard', () async {
    final dir = await Directory.systemTemp.createTemp('fin_track_img_restore_');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });
    final base = Directory('${dir.path}/base')..createSync(recursive: true);
    File('${base.path}/current.txt').writeAsStringSync('current');
    final service = ImageService(baseDirectory: base);

    final session = await service.createTemporaryRestore();
    Directory(session.rollbackPath)
      ..createSync(recursive: true)
      ..listSync();
    await service.restoreToTemporaryDirectory(
      session,
      'new.txt',
      Uint8List.fromList([1]),
    );
    await service.promoteTemporaryRestore(session);
    expect(base.listSync().whereType<File>(), isNotEmpty);
    await service.revertTemporaryRestore(session);

    final discardSession = await service.createTemporaryRestore();
    Directory(discardSession.rollbackPath).createSync(recursive: true);
    await service.discardTemporaryRestore(discardSession);
    expect(Directory(discardSession.path).existsSync(), isFalse);
    expect(Directory(discardSession.rollbackPath).existsSync(), isFalse);
  });
}
