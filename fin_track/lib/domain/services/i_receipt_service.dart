import 'dart:io';

import '../entities/receipt.dart';
import '../value_objects/receipt_filter.dart';

abstract class IReceiptService {
  Future<File> scanDocument();
  Future<File> captureImage();
  Future<List<File>> importFiles();
  Future<void> validateSpaceForNewReceipt([File? file]);
  Future<void> validateSpaceForNewReceipts(List<File> files);
  Future<Receipt> processPreview(File image);
  Future<Receipt> saveConfirmed(Receipt receipt);
  Future<void> discardPreview(Receipt receipt);
  Future<Receipt> register(File image);
  Future<File> localFile(Receipt receipt);
  Future<List<Receipt>> search(String query);
  Future<List<Receipt>> findByFilters(ReceiptFilter filter);
  Future<Receipt> findById(int id);
  Future<void> update(Receipt receipt);
  Future<void> delete(int id);
  Future<int> deleteOrphanFiles();
  Future<File> exportFile(int id);
  Future<void> shareImage(int id);
  Future<void> shareImages(List<int> ids);
  Future<void> saveImageToDevice(int id);
  Future<void> saveImagesToDevice(List<int> ids);
  Future<int> reindexPendingSemanticEmbeddings();
  Future<String> diagnoseSemanticSearch(String query, {int limit = 10});
  Stream<List<Receipt>> watchByFilters(ReceiptFilter filter);
  Stream<List<Receipt>> watchAll();
}
