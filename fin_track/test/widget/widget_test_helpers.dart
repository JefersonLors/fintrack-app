import 'dart:convert';
import 'dart:io';

import 'package:fin_track/application/config/app_config.dart';
import 'package:fin_track/bootstrap/fin_track_dependencies.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/entities/company_data.dart';
import 'package:fin_track/domain/infrastructure/i_cnpj_lookup_service.dart';
import 'package:fin_track/domain/infrastructure/i_embedding_service.dart';
import 'package:fin_track/domain/value_objects/embedding_vector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpFrames(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> disposeWidgetDependencies(
  WidgetTester tester,
  FinTrackDependencies dependencies,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
  try {
    await dependencies.database.close();
  } catch (_) {}
  await tester.pump(const Duration(milliseconds: 1));
}

final testPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
);

FinTrackDependencies widgetDependencies({bool? debugMode}) {
  return FinTrackDependencies.local(
    embeddings: WidgetEmbeddingService(),
    cnpjLookup: const WidgetCnpjLookupService(),
    appConfig: assetAppConfig(debugMode: debugMode),
  );
}

AppConfig assetAppConfig({bool? debugMode}) {
  final raw = File(AppConfig.assetPath).readAsStringSync();
  final json = Map<String, Object?>.from(jsonDecode(raw) as Map);
  if (debugMode != null) {
    json['debugMode'] = debugMode;
  }
  return AppConfig.fromJson(json);
}

Future<Receipt> saveTestReceipt(
  WidgetTester tester,
  FinTrackDependencies dependencies,
  Receipt receipt,
) async {
  return tester
      .runAsync(() async {
        final file = File(
          '${Directory.systemTemp.path}/fin_track_widget_${DateTime.now().microsecondsSinceEpoch}_${receipt.fileName}',
        );
        await file.writeAsString(
          receipt.extractedContent.isEmpty
              ? 'test receipt'
              : receipt.extractedContent,
        );
        return dependencies.receiptService.saveConfirmed(
          receipt.copyWith(id: 0, fileName: file.path),
        );
      })
      .then((value) => value!);
}

class WidgetEmbeddingService implements IEmbeddingService {
  static const dimension = 32;

  @override
  Future<EmbeddingVector> generate(String text) async {
    final vector = List<double>.filled(dimension, 0);
    final terms = text
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty);

    for (final term in terms) {
      var hash = 2166136261;
      for (final unit in term.codeUnits) {
        hash ^= unit;
        hash = (hash * 16777619) & 0xffffffff;
      }
      vector[hash % vector.length] += 1;
    }

    return EmbeddingVector(
      vector: vector,
      model: 'widget-test-lexical',
      dimension: dimension,
    );
  }
}

class WidgetCnpjLookupService implements ICnpjLookupService {
  const WidgetCnpjLookupService();

  @override
  Future<CompanyData?> lookup(String cnpj) async => null;
}
