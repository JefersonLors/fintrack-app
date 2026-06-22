import '../entities/fiscal_document_data.dart';
import '../entities/extracted_data.dart';

abstract class IFiscalDocumentCacheService {
  Future<FiscalDocumentData?> find({String? accessKey, String? urlQrCode});

  Future<void> save(ExtractedData data);
}
