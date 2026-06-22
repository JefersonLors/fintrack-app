import 'dart:io';

import 'package:fin_track/infrastructure/ocr/google_mlkit_service.dart';
import 'package:fin_track/infrastructure/ocr/google_mlkit_visual_code_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const mlkitChannel = MethodChannel('google_mlkit_text_recognizer');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(mlkitChannel, null);
  });

  test('OCR confidence considers structural signals and useful text', () async {
    final service = GoogleMLKitService();
    final file = await _temporaryFile('''
MERCADO CENTRAL LTDA
CNPJ 12.345.678/0001-90
Cupom fiscal eletrônico
Data 28/04/2026
Total R\$ 128,45
Pagamento PIX
''');

    final result = await service.process(file);

    expect(result.provider, 'text_plain');
    expect(result.confidence, greaterThanOrEqualTo(0.80));
  });

  test(
    'OCR confidence penalizes noisy text even with amount and date',
    () async {
      final service = GoogleMLKitService();
      final file = await _temporaryFile('''
@@@ ### ||| R\$ 128,45
xx 28/04/2026 %% %% %%
? ? ? ? ? ? ? ? ? ?
''');

      final result = await service.process(file);

      expect(result.confidence, lessThan(0.70));
    },
  );

  test(
    'OCR confidence does not drop readable receipt without standard date',
    () async {
      final service = GoogleMLKitService();
      final file = await _temporaryFile('''
RECIBO DE PAGAMENTO
Recebemos de Cliente Exemplo
A quantia de R\$ 250,00 referente ao serviço prestado
Pagamento em cash
Assinatura do responsável
''');

      final result = await service.process(file);

      expect(result.confidence, greaterThan(0.60));
    },
  );

  test('OCR confidence recognizes long fiscal key', () async {
    final service = GoogleMLKitService();
    final file = await _temporaryFile('''
NFCE
35260412345678000190550010000012341000012345
Total R\$ 42,90
Pagamento cartão
''');

    final result = await service.process(file);

    expect(result.confidence, greaterThan(0.70));
  });

  test('image processing maps geometry recognized by ML Kit', () async {
    messenger.setMockMethodCallHandler(mlkitChannel, (call) async {
      if (call.method == 'vision#closeTextRecognizer') {
        return null;
      }
      if (call.method == 'vision#startTextRecognizer') {
        return {
          'text': ' Mercado Central \n Total R\$ 128,45 ',
          'blocks': [
            {
              'text': ' Mercado Central ',
              'rect': _rect(left: 1, top: 2, right: 150, bottom: 80),
              'recognizedLanguages': ['pt'],
              'points': _points(),
              'lines': [
                {
                  'text': ' Total R\$ 128,45 ',
                  'rect': _rect(left: 3, top: 4, right: 120, bottom: 28),
                  'recognizedLanguages': ['pt'],
                  'points': _points(),
                  'confidence': 0.87,
                  'angle': 0.0,
                  'elements': [
                    {
                      'text': ' Total ',
                      'rect': _rect(left: 5, top: 6, right: 45, bottom: 18),
                      'recognizedLanguages': ['pt'],
                      'points': _points(),
                      'confidence': 0.74,
                      'angle': 0.0,
                      'symbols': [],
                    },
                    {
                      'text': ' R\$ 128,45 ',
                      'rect': _rect(left: 48, top: 6, right: 110, bottom: 18),
                      'recognizedLanguages': ['pt'],
                      'points': _points(),
                      'confidence': 0.92,
                      'angle': 0.0,
                      'symbols': [],
                    },
                  ],
                },
              ],
            },
          ],
        };
      }
      fail('Método inesperado: ${call.method}');
    });
    final service = GoogleMLKitService();
    final directory = await Directory.systemTemp.createTemp(
      'fintrack_ocr_image_success_test_',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final file = await File(
      '${directory.path}/cupom.jpg',
    ).writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);

    final result = await service.process(file);

    expect(result.text, 'Mercado Central \n Total R\$ 128,45');
    expect(result.provider, 'google_mlkit_text_recognition:on_device');
    expect(result.confidence, greaterThan(0.45));
    expect(result.blocks, hasLength(1));
    expect(result.blocks.single.text, 'Mercado Central');
    expect(result.blocks.single.left, 1);
    expect(result.blocks.single.bottom, 80);
    expect(result.lines, hasLength(1));
    expect(result.lines.single.text, 'Total R\$ 128,45');
    expect(result.lines.single.blockIndex, 0);
    expect(result.lines.single.lineIndex, 0);
    expect(result.lines.single.confidence, 0.87);
    expect(result.elements, hasLength(2));
    expect(result.elements.first.text, 'Total');
    expect(result.elements.first.elementIndex, 0);
    expect(result.elements.first.confidence, 0.74);
    expect(result.elements.last.text, 'R\$ 128,45');
    expect(result.elements.last.right, 110);
  });

  test('image processing without plugin returns empty OCR', () async {
    messenger.setMockMethodCallHandler(mlkitChannel, (call) async {
      if (call.method == 'vision#closeTextRecognizer') {
        return null;
      }
      throw PlatformException(code: 'missing');
    });
    final service = GoogleMLKitService();
    final directory = await Directory.systemTemp.createTemp(
      'fintrack_ocr_image_test_',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final file = await File(
      '${directory.path}/imagem.jpg',
    ).writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);

    final result = await service.process(file);

    expect(result.text, isEmpty);
    expect(result.confidence, 0);
    expect(result.provider, contains('google_mlkit_text_recognition'));
  });

  test('visual code normalization trims empty values and deduplicates', () {
    expect(normalizeVisualCodeValues([' NFCe ', '', null, 'PIX', 'NFCe']), [
      'NFCe',
      'PIX',
    ]);
  });
}

Future<File> _temporaryFile(String content) async {
  final directory = await Directory.systemTemp.createTemp('fintrack_ocr_test_');
  addTearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });
  final file = File('${directory.path}/ocr.txt');
  return file.writeAsString(content.trim());
}

Map<String, double> _rect({
  required double left,
  required double top,
  required double right,
  required double bottom,
}) {
  return {'left': left, 'top': top, 'right': right, 'bottom': bottom};
}

List<Map<String, int>> _points() {
  return [
    {'x': 0, 'y': 0},
    {'x': 1, 'y': 0},
    {'x': 1, 'y': 1},
    {'x': 0, 'y': 1},
  ];
}
