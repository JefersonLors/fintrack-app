import 'dart:convert';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/receipt.dart';
import '../../../domain/entities/extracted_data.dart';
import '../../../domain/entities/embedding.dart';
import '../../../domain/value_objects/category_color_palette.dart';
import '../../diagnostics/error_handling.dart';
import '../app_database.dart';

class ReceiptRowMapper {
  const ReceiptRowMapper(this._database);

  final AppDatabase _database;

  Future<Receipt> mapReceipt(ReceiptRow row) async {
    final data = await (_database.select(
      _database.extractedDataTable,
    )..where((tbl) => tbl.receiptId.equals(row.id))).getSingleOrNull();
    final embedding = await (_database.select(
      _database.embeddings,
    )..where((tbl) => tbl.receiptId.equals(row.id))).getSingleOrNull();
    final category = await receiptCategory(row.categoryId);

    return Receipt(
      id: row.id,
      type: ReceiptType.fromPersisted(row.type),
      expense: row.expense,
      fileName: row.fileName,
      fileType: row.fileType,
      fileHash: row.fileHash,
      fileSize: row.fileSize,
      extractedContent: row.extractedContent,
      cloudSynced: row.cloudSynced,
      registeredAt: row.registeredAt,
      extractedData: data == null ? null : mapExtractedData(data),
      embedding: embedding == null ? null : mapEmbedding(embedding),
      category: category,
    );
  }

  Future<Category?> receiptCategory(int? categoryId) async {
    if (categoryId == null) {
      return null;
    }
    final row = await (_database.select(
      _database.categories,
    )..where((tbl) => tbl.id.equals(categoryId))).getSingleOrNull();
    return row == null ? null : mapCategory(row);
  }

  ExtractedData mapExtractedData(ExtractedDataRow row) {
    return ExtractedData(
      id: row.id,
      receiptId: row.receiptId,
      amount: row.amount,
      transactionDate: row.transactionDate,
      establishment: row.establishment,
      items: _itemsFromJson(row.items),
      paymentMethod: row.paymentMethod,
      issuerCnpj: row.issuerCnpj,
      accessKey: row.accessKey,
      urlQrCode: row.urlQrCode,
      documentNumber: row.documentNumber,
      documentSeries: row.documentSeries,
      documentState: row.documentState,
      issuerLegalName: row.issuerLegalName,
      issuerTradeName: row.issuerTradeName,
      fiscalCnaeDescription: row.fiscalCnaeDescription,
      issuerCity: row.issuerCity,
      issuerState: row.issuerState,
      ocrConfidence: row.ocrConfidence,
      extractionParser: row.extractionParser,
      extractionConfidence: row.extractionConfidence,
      valueConfidence: row.valueConfidence,
      dateConfidence: row.dateConfidence,
      establishmentConfidence: row.establishmentConfidence,
      paymentMethodConfidence: row.paymentMethodConfidence,
      qualityMetadata: _jsonMap(row.qualityMetadata),
    );
  }

  Embedding mapEmbedding(EmbeddingRow row) {
    return Embedding(
      id: row.id,
      receiptId: row.receiptId,
      vector: row.vector,
      model: row.model,
      dimension: row.dimension,
      generatedAt: row.generatedAt,
    );
  }

  Category mapCategory(CategoryRow row) {
    return Category(
      id: row.id,
      name: row.name,
      description: row.description,
      inferredAutomatically: row.inferredAutomatically,
      icon: row.icon,
      colorArgb: normalizeCategoryColorArgb(row.colorArgb),
    );
  }

  Map<String, Object?>? _jsonMap(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return syncFallbackOnFailure(
      () {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
        return null;
      },
      fallback: null,
      diagnosticContext: 'Falha ao interpretar metadados de qualidade do OCR',
    );
  }

  List<String> _itemsFromJson(String raw) {
    return syncFallbackOnFailure(
      () {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList();
        }
        return const <String>[];
      },
      fallback: const <String>[],
      diagnosticContext: 'Falha ao interpretar itens do comprovante',
    );
  }
}
