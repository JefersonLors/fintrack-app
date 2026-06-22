import 'dart:convert';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/extracted_data.dart';
import '../../../domain/entities/receipt.dart';

Map<String, Object?> receiptBatchReceiptToJson(Receipt receipt) {
  return <String, Object?>{
    'id': receipt.id,
    'type': receipt.type.persistedValue,
    'expense': receipt.expense,
    'fileName': receipt.fileName,
    'fileType': receipt.fileType,
    'fileHash': receipt.fileHash,
    'fileSize': receipt.fileSize,
    'extractedContent': receipt.extractedContent,
    'cloudSynced': receipt.cloudSynced,
    'registeredAt': receipt.registeredAt.toIso8601String(),
    'extractedData': _dataToJson(receipt.extractedData),
    'category': _categoryToJson(receipt.category),
  };
}

String receiptBatchReceiptToJsonString(Receipt receipt) {
  return jsonEncode(receiptBatchReceiptToJson(receipt));
}

Receipt? receiptBatchReceiptFromJsonString(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    return null;
  }
  return _receiptFromJson(decoded.cast<String, Object?>());
}

Map<String, Object?>? _dataToJson(ExtractedData? data) {
  if (data == null) {
    return null;
  }
  return <String, Object?>{
    'amount': data.amount,
    'transactionDate': data.transactionDate?.toIso8601String(),
    'establishment': data.establishment,
    'items': data.items,
    'paymentMethod': data.paymentMethod,
    'issuerCnpj': data.issuerCnpj,
    'accessKey': data.accessKey,
    'urlQrCode': data.urlQrCode,
    'documentNumber': data.documentNumber,
    'documentSeries': data.documentSeries,
    'documentState': data.documentState,
    'issuerLegalName': data.issuerLegalName,
    'issuerTradeName': data.issuerTradeName,
    'fiscalCnaeDescription': data.fiscalCnaeDescription,
    'issuerCity': data.issuerCity,
    'issuerState': data.issuerState,
    'ocrConfidence': data.ocrConfidence,
    'extractionParser': data.extractionParser,
    'extractionConfidence': data.extractionConfidence,
    'valueConfidence': data.valueConfidence,
    'dateConfidence': data.dateConfidence,
    'establishmentConfidence': data.establishmentConfidence,
    'paymentMethodConfidence': data.paymentMethodConfidence,
    'qualityMetadata': data.qualityMetadata,
  };
}

Map<String, Object?>? _categoryToJson(Category? category) {
  if (category == null) {
    return null;
  }
  return <String, Object?>{
    'id': category.id,
    'name': category.name,
    'description': category.description,
    'inferredAutomatically': category.inferredAutomatically,
    'icon': category.icon,
    'colorArgb': category.colorArgb,
  };
}

Receipt _receiptFromJson(Map<String, Object?> json) {
  return Receipt(
    id: _int(json['id']) ?? 0,
    type: ReceiptType.fromPersisted(json['type']?.toString() ?? ''),
    expense: json['expense'] == true,
    fileName: json['fileName']?.toString() ?? '',
    fileType: json['fileType']?.toString() ?? 'application/octet-stream',
    fileHash: json['fileHash']?.toString(),
    fileSize: _int(json['fileSize']),
    extractedContent: json['extractedContent']?.toString() ?? '',
    cloudSynced: json['cloudSynced'] == true,
    registeredAt:
        DateTime.tryParse(json['registeredAt']?.toString() ?? '') ??
        DateTime.now(),
    extractedData: _dataFromJson(json['extractedData']),
    category: _categoryFromJson(json['category']),
  );
}

ExtractedData? _dataFromJson(Object? raw) {
  if (raw is! Map) {
    return null;
  }
  final json = raw.cast<String, Object?>();
  return ExtractedData(
    id: 0,
    receiptId: 0,
    amount: _double(json['amount']),
    transactionDate: DateTime.tryParse(
      json['transactionDate']?.toString() ?? '',
    ),
    establishment: json['establishment']?.toString(),
    items:
        (json['items'] as List?)?.whereType<String>().toList() ??
        const <String>[],
    paymentMethod: json['paymentMethod']?.toString(),
    issuerCnpj: json['issuerCnpj']?.toString(),
    accessKey: json['accessKey']?.toString(),
    urlQrCode: json['urlQrCode']?.toString(),
    documentNumber: json['documentNumber']?.toString(),
    documentSeries: json['documentSeries']?.toString(),
    documentState: json['documentState']?.toString(),
    issuerLegalName: json['issuerLegalName']?.toString(),
    issuerTradeName: json['issuerTradeName']?.toString(),
    fiscalCnaeDescription: json['fiscalCnaeDescription']?.toString(),
    issuerCity: json['issuerCity']?.toString(),
    issuerState: json['issuerState']?.toString(),
    ocrConfidence: _double(json['ocrConfidence']),
    extractionParser: json['extractionParser']?.toString(),
    extractionConfidence: _double(json['extractionConfidence']),
    valueConfidence: _double(json['valueConfidence']),
    dateConfidence: _double(json['dateConfidence']),
    establishmentConfidence: _double(json['establishmentConfidence']),
    paymentMethodConfidence: _double(json['paymentMethodConfidence']),
    qualityMetadata: (json['qualityMetadata'] as Map?)?.cast<String, Object?>(),
  );
}

Category? _categoryFromJson(Object? raw) {
  if (raw is! Map) {
    return null;
  }
  final json = raw.cast<String, Object?>();
  final name = json['name']?.toString();
  if (name == null || name.isEmpty) {
    return null;
  }
  return Category(
    id: _int(json['id']) ?? 0,
    name: name,
    description: json['description']?.toString(),
    inferredAutomatically: json['inferredAutomatically'] == true,
    icon: json['icon']?.toString() ?? 'category',
    colorArgb: _int(json['colorArgb']) ?? 0xFFD2D8E3,
  );
}

int? _int(Object? raw) {
  if (raw is int) {
    return raw;
  }
  return int.tryParse(raw?.toString() ?? '');
}

double? _double(Object? raw) {
  if (raw is num) {
    return raw.toDouble();
  }
  return double.tryParse(raw?.toString() ?? '');
}
