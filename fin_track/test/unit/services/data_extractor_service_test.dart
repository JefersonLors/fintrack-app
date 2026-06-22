import 'dart:io';

import 'package:fin_track/application/ocr/data_extractor_service.dart';
import 'package:fin_track/application/ocr/ocr_text_normalizer_service.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/value_objects/ocr_result.dart';
import 'package:flutter_test/flutter_test.dart';

part 'data_extractor_service_normalization_part.dart';
part 'data_extractor_service_transfer_part.dart';
part 'data_extractor_service_card_part.dart';
part 'data_extractor_service_fiscal_receipt_part.dart';
part 'data_extractor_service_helpers_part.dart';

void main() {
  registerExtractorNormalizationTests();
  registerTransferExtractorTests();
  registerCardExtractorTests();
  registerFiscalReceiptExtractorTests();
}
