part of 'receipt_service_test.dart';

void registerReceiptImageServiceTests() {
  test('ImageService copies files into managed receipt directory', () async {
    final root = await Directory.systemTemp.createTemp('fin_track_image_');
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    final baseDirectory = Directory(
      '${root.path}/app_flutter/fintrack/receipts',
    );
    final importDirectory = Directory('${root.path}/imports');
    await importDirectory.create(recursive: true);
    final source = File('${importDirectory.path}/capture.jpg');
    await source.writeAsBytes(<int>[1, 2, 3, 4]);

    final service = ImageService(baseDirectory: baseDirectory);
    final savedName = await service.saveToFileSystem(source);
    final savedFile = File('${baseDirectory.path}/$savedName');

    expect(savedName, isNot('capture.jpg'));
    expect(await source.exists(), isTrue);
    expect(await savedFile.exists(), isTrue);
    expect(service.rebuildPath(savedName), savedFile.path);
  });

  test(
    'ImageService calculates used space and deletes managed files',
    () async {
      final root = await Directory.systemTemp.createTemp('fin_track_storage_');
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });

      final baseDirectory = Directory(
        '${root.path}/app_flutter/fintrack/receipts',
      );
      final service = ImageService(baseDirectory: baseDirectory);

      final current = File('${baseDirectory.path}/saved.txt');
      await current.create(recursive: true);
      await current.writeAsBytes(List<int>.filled(512, 1));

      final unreferenced = File('${baseDirectory.path}/loose.txt');
      await unreferenced.create(recursive: true);
      await unreferenced.writeAsBytes(List<int>.filled(256, 1));

      expect(await service.calculateUsedSpaceBytes(), 768);
      final removed = await service.deleteUnreferencedFiles({'saved.txt'});
      expect(removed, 256);
      expect(await current.exists(), isTrue);
      expect(await unreferenced.exists(), isFalse);
      expect(await service.calculateUsedSpaceBytes(), 512);

      await service.deleteAll();
      expect(await service.calculateUsedSpaceBytes(), 0);
    },
  );
}
