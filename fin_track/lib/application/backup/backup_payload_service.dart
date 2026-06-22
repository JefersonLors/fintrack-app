import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../domain/entities/category.dart';
import '../../domain/entities/configuration.dart';
import '../../domain/entities/embedding.dart';
import '../../domain/entities/extracted_data.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/exceptions/storage_limit_exception.dart';
import '../../domain/infrastructure/i_cryptography_service.dart';
import '../../domain/infrastructure/i_image_service.dart';
import '../../domain/value_objects/category_color_palette.dart';

class BackupPayloadService {
  const BackupPayloadService({
    required IImageService images,
    required ICryptographyService cryptography,
  }) : _images = images,
       _cryptography = cryptography;

  static const _currentBackupVersion = 2;

  final IImageService _images;
  final ICryptographyService _cryptography;

  Future<Uint8List> serializeBackup(
    List<Receipt> receipts,
    Configuration configuration,
  ) async {
    final files = <Map<String, Object?>>[];
    final items = <Map<String, Object?>>[];

    for (final receipt in receipts) {
      final fileName = _basename(receipt.fileName);
      final file = File(_images.rebuildPath(receipt.fileName));
      if (!await file.exists()) {
        throw const FormatException('Arquivo do comprovante não encontrado.');
      }
      files.add(<String, Object?>{
        'fileName': fileName,
        'fileType': receipt.fileType,
        'bytesBase64': base64Encode(await file.readAsBytes()),
      });
      items.add(_receiptToJson(receipt, fileName));
    }

    final payload = <String, Object?>{
      'version': _currentBackupVersion,
      'generatedAt': DateTime.now().toIso8601String(),
      'configuration': <String, Object?>{
        'backupReminderEnabled': configuration.backupReminderEnabled,
        'reminderIntervalDays': configuration.reminderIntervalDays,
        'storageLimitMB': configuration.storageLimitMB,
      },
      'receipts': items,
      'files': files,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  }

  Future<Map<String, dynamic>> firstValidBackup(
    List<Uint8List> files,
    String password,
  ) async {
    for (final file in files) {
      try {
        final decrypted = await _cryptography.decrypt(file, password);
        final json = jsonDecode(utf8.decode(decrypted));
        if (json is Map<String, dynamic>) {
          return json;
        }
      } on FormatException catch (error) {
        if (error.message == 'Senha incorreta ou backup corrompido.') {
          rethrow;
        }
        continue;
      }
    }
    throw const FormatException('Nenhum backup válido encontrado.');
  }

  void validateRestorePackage(Map<String, dynamic> package) {
    if (package['version'] != _currentBackupVersion) {
      throw const FormatException('Versão de backup incompatível.');
    }
    final receipts = package['receipts'];
    final files = package['files'];
    if (receipts is! List || files is! List) {
      throw const FormatException('Estrutura de backup inválida.');
    }

    final fileNames = <String>{};
    for (final item in files) {
      if (item is! Map) {
        throw const FormatException('Estrutura de arquivo inválida.');
      }
      final name = item['fileName']?.toString();
      final bytes = item['bytesBase64']?.toString();
      if (name == null || name.trim().isEmpty || bytes == null) {
        throw const FormatException('Arquivo de backup inválido.');
      }
      _decodedBase64Size(bytes);
      fileNames.add(_basename(name));
    }

    for (final item in receipts) {
      if (item is! Map) {
        throw const FormatException('Estrutura de comprovante inválida.');
      }
      final name = item['fileName']?.toString();
      if (name == null || !fileNames.contains(_basename(name))) {
        throw const FormatException(
          'Arquivo de comprovante ausente no backup.',
        );
      }
    }
  }

  Future<void> validateRestoreLimit(
    Map<String, dynamic> package,
    Configuration configuration,
  ) async {
    final byteLimit = configuration.storageLimitMB * 1024 * 1024;
    var totalBytes = 0;
    for (final item in (package['files'] as List<dynamic>? ?? const [])) {
      if (item is! Map) {
        continue;
      }
      final bytesBase64 = item['bytesBase64']?.toString();
      if (bytesBase64 == null) {
        continue;
      }
      totalBytes += _decodedBase64Size(bytesBase64);
    }

    if (totalBytes > byteLimit) {
      throw const StorageLimitException(
        'Restaurar o backup ultrapassaria o limite de armazenamento.',
      );
    }
  }

  Future<List<Receipt>> restoreFilesAndBuildReceipts(
    Map<String, dynamic> package,
    TemporaryRestoreDirectory session,
  ) async {
    final files = <String, Map<dynamic, dynamic>>{};
    for (final item in (package['files'] as List<dynamic>? ?? const [])) {
      if (item is! Map) {
        continue;
      }
      final name = item['fileName']?.toString();
      if (name == null) {
        continue;
      }
      files[_basename(name)] = item;
    }

    final receiptsJson =
        package['receipts'] as List<dynamic>? ?? const <dynamic>[];
    final receipts = <Receipt>[];
    for (final item in receiptsJson) {
      if (item is! Map) {
        continue;
      }
      final json = item.cast<String, dynamic>();
      final originalName = json['fileName']?.toString() ?? 'receipt.bin';
      final file = files[_basename(originalName)];
      final bytesBase64 = file?['bytesBase64']?.toString();
      if (bytesBase64 == null) {
        throw const FormatException(
          'Arquivo de comprovante ausente no backup.',
        );
      }
      final restoredName = await _images.restoreToTemporaryDirectory(
        session,
        originalName,
        base64Decode(bytesBase64),
      );
      receipts.add(_receiptFromJson(json, restoredName));
    }
    return receipts;
  }

  Configuration restoreConfiguration(
    Map<String, dynamic> package,
    Configuration current,
  ) {
    final raw = package['configuration'];
    if (raw is! Map) {
      return current;
    }
    final json = raw.cast<String, dynamic>();
    return current.copyWith(
      backupReminderEnabled: json['backupReminderEnabled'] == true,
      reminderIntervalDays:
          _nullableInt(json['reminderIntervalDays']) ??
          current.reminderIntervalDays,
      storageLimitMB:
          _nullableInt(json['storageLimitMB']) ?? current.storageLimitMB,
    );
  }

  int _decodedBase64Size(String amount) {
    final normalized = base64.normalize(amount);
    final withoutSpaces = normalized.replaceAll(RegExp(r'\s'), '');
    if (withoutSpaces.isEmpty) {
      return 0;
    }
    final padding = withoutSpaces.endsWith('==')
        ? 2
        : withoutSpaces.endsWith('=')
        ? 1
        : 0;
    return (withoutSpaces.length ~/ 4) * 3 - padding;
  }

  Map<String, Object?> _receiptToJson(Receipt receipt, String fileName) {
    return <String, Object?>{
      'type': receipt.type.persistedValue,
      'expense': receipt.expense,
      'fileName': fileName,
      'fileType': receipt.fileType,
      'fileHash': receipt.fileHash,
      'fileSize': receipt.fileSize,
      'extractedContent': receipt.extractedContent,
      'cloudSynced': true,
      'registeredAt': receipt.registeredAt.toIso8601String(),
      'extractedData': _dataToJson(receipt.extractedData),
      'embedding': _embeddingToJson(receipt.embedding),
      'category': receipt.category == null
          ? null
          : _categoryToJson(receipt.category!),
    };
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

  Map<String, Object?>? _embeddingToJson(Embedding? embedding) {
    if (embedding == null) {
      return null;
    }
    return <String, Object?>{
      'vetorBase64': base64Encode(embedding.vector),
      'model': embedding.model,
      'dimension': embedding.dimension,
      'generatedAt': embedding.generatedAt.toIso8601String(),
    };
  }

  Map<String, Object?> _categoryToJson(Category category) {
    return <String, Object?>{
      'name': category.name,
      'description': category.description,
      'inferredAutomatically': category.inferredAutomatically,
      'icon': category.icon,
      'colorArgb': normalizeCategoryColorArgb(category.colorArgb),
    };
  }

  Receipt _receiptFromJson(Map<String, dynamic> json, String fileName) {
    return Receipt(
      id: 0,
      type: ReceiptType.fromPersisted(json['type']?.toString() ?? ''),
      expense: json['expense'] == true,
      fileName: fileName,
      fileType: json['fileType']?.toString() ?? 'application/octet-stream',
      fileHash: json['fileHash']?.toString(),
      fileSize: _nullableInt(json['fileSize']),
      extractedContent: json['extractedContent']?.toString() ?? '',
      cloudSynced: true,
      registeredAt:
          DateTime.tryParse(json['registeredAt']?.toString() ?? '') ??
          DateTime.now(),
      extractedData: _dataFromJson(json['extractedData']),
      embedding: _embeddingFromJson(json['embedding']),
      category: _categoryFromJson(json['category']),
    );
  }

  ExtractedData? _dataFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final json = raw.cast<String, dynamic>();
    return ExtractedData(
      id: 0,
      receiptId: 0,
      amount: _nullableDouble(json['amount']),
      transactionDate: DateTime.tryParse(
        json['transactionDate']?.toString() ?? '',
      ),
      establishment: json['establishment']?.toString(),
      items: _stringList(json['items']),
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
      ocrConfidence: _nullableDouble(json['ocrConfidence']),
      extractionParser: json['extractionParser']?.toString(),
      extractionConfidence: _nullableDouble(json['extractionConfidence']),
      valueConfidence: _nullableDouble(json['valueConfidence']),
      dateConfidence: _nullableDouble(json['dateConfidence']),
      establishmentConfidence: _nullableDouble(json['establishmentConfidence']),
      paymentMethodConfidence: _nullableDouble(json['paymentMethodConfidence']),
      qualityMetadata: _stringObjectMap(json['qualityMetadata']),
    ).withNormalizedEstablishment();
  }

  Map<String, Object?>? _stringObjectMap(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  List<String> _stringList(Object? raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Embedding? _embeddingFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final json = raw.cast<String, dynamic>();
    final vector = json['vetorBase64']?.toString();
    if (vector == null) {
      return null;
    }
    return Embedding(
      id: 0,
      receiptId: 0,
      vector: base64Decode(vector),
      model: json['model']?.toString() ?? 'desconhecido',
      dimension: _nullableInt(json['dimension']) ?? 0,
      generatedAt:
          DateTime.tryParse(json['generatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Category? _categoryFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final json = raw.cast<String, dynamic>();
    return Category(
      id: 0,
      name: json['name']?.toString() ?? 'Outros',
      description: json['description']?.toString(),
      inferredAutomatically: json['inferredAutomatically'] == true,
      icon: json['icon']?.toString() ?? 'category',
      colorArgb: normalizeCategoryColorArgb(
        _nullableInt(json['colorArgb']) ?? CategoryColorPalette.noColor,
      ),
    );
  }

  int? _nullableInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }

  double? _nullableDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }
}
