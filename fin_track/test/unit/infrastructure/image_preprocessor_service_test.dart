import 'dart:io';

import 'package:fin_track/infrastructure/image/image_preprocessor_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('txt file returns same file', () async {
    final dir = await Directory.systemTemp.createTemp('fin_track_pre_txt_');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });
    final file = File('${dir.path}/receipt.txt')..writeAsStringSync('text');
    final service = ImagePreprocessorService(
      temporaryDirectory: Directory('${dir.path}/tmp_ocr'),
    );

    final result = await service.preprocess(file);

    expect(result.path, file.path);
  });

  test('invalid image returns same file without error', () async {
    final dir = await Directory.systemTemp.createTemp('fin_track_pre_bad_');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });
    final file = File('${dir.path}/broken.jpg')
      ..writeAsBytesSync(<int>[1, 2, 3, 4]);
    final service = ImagePreprocessorService(
      temporaryDirectory: Directory('${dir.path}/tmp_ocr'),
    );

    final result = await service.preprocess(file);

    expect(result.path, file.path);
  });

  test('valid image generates existing new jpeg file', () async {
    final dir = await Directory.systemTemp.createTemp('fin_track_pre_img_');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });
    final image = img.Image(width: 8, height: 8);
    img.fill(image, color: img.ColorRgb8(245, 245, 230));
    final file = File('${dir.path}/capture.png')
      ..writeAsBytesSync(img.encodePng(image));
    final service = ImagePreprocessorService(
      temporaryDirectory: Directory('${dir.path}/tmp_ocr'),
    );

    final result = await service.preprocess(file);
    final bytes = await result.readAsBytes();

    expect(result.path, isNot(file.path));
    expect(await result.exists(), isTrue);
    expect(bytes.take(2), <int>[0xff, 0xd8]);
  });

  test('preprocessor processes real image fallback and cleanup', () async {
    final dir = await Directory.systemTemp.createTemp('fin_track_pre_img_');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });
    final tmp = Directory('${dir.path}/tmp');
    final service = ImagePreprocessorService(temporaryDirectory: tmp);
    final image = img.Image(width: 4, height: 5);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        image.setPixelRgb(x, y, x * 30, y * 20, 120);
      }
    }
    final file = File('${dir.path}/cupom.png')
      ..writeAsBytesSync(img.encodePng(image));
    final invalid = File('${dir.path}/invalid.jpg')..writeAsStringSync('x');

    final variants = await service.generateVariants(file);
    expect(variants.map((variante) => variante.name), contains('original'));
    expect(variants.any((variante) => variante.temporary), isTrue);
    expect(await service.preprocess(file), isA<File>());

    final quality = await service.analyzeQuality(
      file,
      hasQrCode: true,
      hasBarcode: true,
    );
    expect(quality.width, 4);
    expect(quality.height, 5);
    expect(quality.hasQrCode, isTrue);
    expect(quality.hasBarcode, isTrue);

    final fallback = await service.analyzeQuality(invalid);
    expect(fallback.width, 0);

    final oldFile = File('${tmp.path}/antigo.tmp')
      ..createSync(recursive: true)
      ..writeAsStringSync('old');
    await oldFile.setLastModified(
      DateTime.now().subtract(const Duration(days: 2)),
    );
    Directory('${tmp.path}/subdir').createSync(recursive: true);
    await service.cleanOldTemporaryFiles();
    expect(await oldFile.exists(), isFalse);
  });
}
