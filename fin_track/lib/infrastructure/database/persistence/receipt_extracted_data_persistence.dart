import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/entities/extracted_data.dart';
import '../app_database.dart';

class ReceiptExtractedDataPersistence {
  const ReceiptExtractedDataPersistence(this._database);

  final AppDatabase _database;

  Future<void> save(ExtractedData? data, {required int receiptId}) async {
    await (_database.delete(
      _database.extractedDataTable,
    )..where((tbl) => tbl.receiptId.equals(receiptId))).go();
    if (data == null) {
      return;
    }

    await _database
        .into(_database.extractedDataTable)
        .insert(
          ExtractedDataTableCompanion.insert(
            receiptId: receiptId,
            amount: Value(data.amount),
            transactionDate: Value(data.transactionDate),
            establishment: Value(data.establishment),
            items: Value(jsonEncode(data.items)),
            paymentMethod: Value(data.paymentMethod),
            issuerCnpj: Value(data.issuerCnpj),
            accessKey: Value(data.accessKey),
            urlQrCode: Value(data.urlQrCode),
            documentNumber: Value(data.documentNumber),
            documentSeries: Value(data.documentSeries),
            documentState: Value(data.documentState),
            issuerLegalName: Value(data.issuerLegalName),
            issuerTradeName: Value(data.issuerTradeName),
            fiscalCnaeDescription: Value(data.fiscalCnaeDescription),
            issuerCity: Value(data.issuerCity),
            issuerState: Value(data.issuerState),
            ocrConfidence: Value(data.ocrConfidence),
            extractionParser: Value(data.extractionParser),
            extractionConfidence: Value(data.extractionConfidence),
            valueConfidence: Value(data.valueConfidence),
            dateConfidence: Value(data.dateConfidence),
            establishmentConfidence: Value(data.establishmentConfidence),
            paymentMethodConfidence: Value(data.paymentMethodConfidence),
            qualityMetadata: Value(
              data.qualityMetadata == null
                  ? null
                  : jsonEncode(data.qualityMetadata),
            ),
          ),
        );
  }
}
