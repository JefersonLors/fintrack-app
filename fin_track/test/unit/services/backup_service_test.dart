import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fin_track/application/backup/backup_service.dart';
import 'package:fin_track/application/backup/backup_payload_service.dart';
import 'package:fin_track/application/backup/backup_restore_service.dart';
import 'package:fin_track/application/configuration/configuration_service.dart';
import 'package:fin_track/bootstrap/fin_track_dependencies.dart';
import 'package:fin_track/domain/entities/category.dart';
import 'package:fin_track/domain/entities/configuration.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/entities/extracted_data.dart';
import 'package:fin_track/domain/entities/embedding.dart';
import 'package:fin_track/domain/entities/backup_record.dart';
import 'package:fin_track/domain/infrastructure/i_cloud_storage.dart';
import 'package:fin_track/domain/infrastructure/i_error_reporter.dart';
import 'package:fin_track/domain/infrastructure/i_image_service.dart';
import 'package:fin_track/domain/repositories/i_receipt_repository.dart';
import 'package:fin_track/domain/value_objects/receipt_filter.dart';
import 'package:fin_track/domain/value_objects/embedding_vector.dart';
import 'package:fin_track/infrastructure/cryptography/aes256_service.dart';
import 'package:fin_track/infrastructure/database/app_database.dart';
import 'package:fin_track/infrastructure/database/backup_repository.dart';
import 'package:fin_track/infrastructure/database/repositories/receipt_repository.dart';
import 'package:fin_track/infrastructure/database/configuration_repository.dart';
import 'package:fin_track/infrastructure/image/image_service.dart';
import 'package:fin_track/presentation/backup/pages/backup_page.dart';
import 'package:fin_track/presentation/widgets/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

part 'backup_service_crypto_config_part.dart';
part 'backup_service_export_delete_part.dart';
part 'backup_service_restore_part.dart';
part 'backup_service_helpers_part.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  registerBackupCryptoConfigTests();
  registerBackupExportDeleteTests();
  registerBackupRestoreTests();
}
