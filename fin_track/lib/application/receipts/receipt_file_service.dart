import 'dart:io';

import '../../domain/entities/receipt.dart';
import '../../domain/infrastructure/i_image_service.dart';
import '../../domain/repositories/i_receipt_repository.dart';
import '../../domain/value_objects/receipt_filter.dart';

class ReceiptFileService {
  const ReceiptFileService({
    required IReceiptRepository receipts,
    required IImageService images,
  }) : _receipts = receipts,
       _images = images;

  final IReceiptRepository _receipts;
  final IImageService _images;

  Future<File> captureImage() => _images.capture();

  Future<List<File>> importFiles() => _images.importMany();

  Future<void> discardPreview(Receipt receipt) async {
    if (receipt.id != 0) {
      return;
    }
    await _images.deleteIfManaged(receipt.fileName);
  }

  Future<File> localFile(Receipt receipt) async {
    if (receipt.id == 0) {
      final previewFile = File(receipt.fileName);
      if (await previewFile.exists()) {
        return previewFile;
      }
    }
    return File(_images.rebuildPath(receipt.fileName));
  }

  Future<File> previewFile(Receipt receipt) async {
    final direct = File(receipt.fileName);
    if (await direct.exists()) {
      return direct;
    }

    final rebuilt = File(_images.rebuildPath(receipt.fileName));
    if (await rebuilt.exists()) {
      return rebuilt;
    }

    throw const FormatException(
      'Arquivo temporário do comprovante não encontrado.',
    );
  }

  Future<void> delete(int id) async {
    final receipt = await _receipts.findById(id);
    await _images.delete(receipt.fileName);
    await _receipts.delete(id);
  }

  Future<int> deleteOrphanFiles() async {
    final receipts = await _receipts.findByFilters(const ReceiptFilter());
    return _images.deleteUnreferencedFiles(
      receipts.map((receipt) => receipt.fileName).toSet(),
    );
  }

  Future<File> exportFile(int id) async {
    final receipt = await _receipts.findById(id);
    return File(_images.rebuildPath(receipt.fileName));
  }

  Future<void> shareImage(int id) async {
    final receipt = await _receipts.findById(id);
    await _images.share(receipt.fileName, receipt.fileType);
  }

  Future<void> shareImages(List<int> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final receipts = <Receipt>[];
    for (final id in ids) {
      receipts.add(await _receipts.findById(id));
    }
    await _images.shareMany(
      receipts.map((receipt) => receipt.fileName).toList(),
    );
  }

  Future<void> saveImageToDevice(int id) async {
    final receipt = await _receipts.findById(id);
    await _images.saveToDevice(receipt.fileName, receipt.fileType);
  }

  Future<void> saveImagesToDevice(List<int> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final receipts = <Receipt>[];
    for (final id in ids) {
      receipts.add(await _receipts.findById(id));
    }
    await _images.saveManyToDevice(
      receipts.map((receipt) => receipt.fileName).toList(),
    );
  }
}
