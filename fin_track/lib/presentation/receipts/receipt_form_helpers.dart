import 'dart:io';

import '../../domain/entities/receipt.dart';
import '../../infrastructure/diagnostics/error_handling.dart';
import '../widgets/formatters.dart';

List<String> receiptPendingFields(Receipt receipt) {
  final receiptData = receipt.extractedData;
  return <String>[
    if (receiptData?.amount == null) 'valor',
    if (receiptData?.transactionDate == null) 'data',
    if ((receiptData?.establishment ?? '').trim().isEmpty) 'estabelecimento',
    if (receipt.category == null) 'categoria',
  ];
}

String formatPendingFieldsList(List<String> pendingFields) {
  if (pendingFields.length == 1) {
    return pendingFields.single;
  }
  return '${pendingFields.take(pendingFields.length - 1).join(', ')} e ${pendingFields.last}';
}

double? parseEditableCurrencyValue(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final normalized = raw.contains(',')
      ? raw.replaceAll('.', '').replaceAll(',', '.')
      : raw;
  return double.tryParse(normalized);
}

String formatEditableCurrencyValue(double? value) {
  if (value == null) {
    return '';
  }
  return formatCurrency(value).replaceFirst('R\$ ', '');
}

String formatDateField(DateTime? date) => date == null ? '' : formatDate(date);

bool looksLikeReceiptImage(String fileType, String fileName) {
  final type = fileType.toLowerCase();
  final name = fileName.toLowerCase();
  return type.startsWith('image/') ||
      name.endsWith('.jpg') ||
      name.endsWith('.jpeg') ||
      name.endsWith('.png') ||
      name.endsWith('.webp') ||
      name.endsWith('.heic') ||
      name.endsWith('.heif');
}

String stagingFileName(int number, String path) {
  final originalName = fileNameFromPath(path);
  final safe = originalName
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  return 'item_${number.toString().padLeft(3, '0')}_$safe';
}

String fileNameFromPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.split('/').last;
}

bool looksLikeTemporaryImport(String path) {
  final normalized = path.replaceAll('\\', '/').toLowerCase();
  return normalized.contains('/shared_imports/');
}

Future<void> cleanOldStagingDirectories(Directory base) async {
  if (!await base.exists()) {
    return;
  }
  final limit = DateTime.now().subtract(const Duration(days: 1));
  await for (final item in base.list(recursive: false)) {
    if (item is! Directory) {
      continue;
    }
    await ignoreCleanupFailure(() async {
      final modified = await item.stat().then((stat) => stat.modified);
      if (modified.isBefore(limit)) {
        await item.delete(recursive: true);
      }
    });
  }
}

Future<void> deleteDirectorySilently(Directory directory) async {
  await ignoreCleanupFailure(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });
}
