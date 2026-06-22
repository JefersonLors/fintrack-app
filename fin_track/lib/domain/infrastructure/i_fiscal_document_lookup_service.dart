import '../entities/fiscal_document_data.dart';

abstract class IFiscalDocumentLookupService {
  Future<FiscalDocumentData?> lookup({String? urlQrCode, String? accessKey});
}
