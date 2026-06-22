part of 'app_database.dart';

// coverage:ignore-start
@DataClassName('ReceiptRow')
class Receipts extends Table {
  @override
  String get tableName => 'receipt';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()
      .named('type')
      .customConstraint(
        "NOT NULL CHECK(type IN ('NOTA_FISCAL','RECIBO','COMPROVANTE_PIX','OUTROS'))",
      )();
  BoolColumn get expense => boolean().named('is_expense')();
  TextColumn get fileName => text().named('file_name').unique()();
  TextColumn get fileType => text().named('file_type')();
  TextColumn get fileHash => text().named('file_hash').nullable()();
  IntColumn get fileSize => integer().named('file_size').nullable()();
  TextColumn get extractedContent =>
      text().named('extracted_content').withDefault(const Constant(''))();
  IntColumn get categoryId => integer()
      .named('category_id')
      .nullable()
      .references(Categories, #id, onDelete: KeyAction.setNull)();
  BoolColumn get cloudSynced =>
      boolean().named('cloud_synced').withDefault(const Constant(false))();
  DateTimeColumn get registeredAt => dateTime().named('registered_at')();
}

@DataClassName('ExtractedDataRow')
class ExtractedDataTable extends Table {
  @override
  String get tableName => 'extracted_data';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get receiptId => integer()
      .named('receipt_id')
      .unique()
      .references(Receipts, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real().named('amount').nullable()();
  DateTimeColumn get transactionDate =>
      dateTime().named('transaction_date').nullable()();
  TextColumn get establishment => text().named('establishment').nullable()();
  TextColumn get items =>
      text().named('items').withDefault(const Constant('[]'))();
  TextColumn get paymentMethod => text().named('payment_method').nullable()();
  TextColumn get issuerCnpj => text().named('issuer_cnpj').nullable()();
  TextColumn get accessKey => text().named('access_key').nullable()();
  TextColumn get urlQrCode => text().named('qr_code_url').nullable()();
  TextColumn get documentNumber => text().named('document_number').nullable()();
  TextColumn get documentSeries => text().named('document_series').nullable()();
  TextColumn get documentState => text().named('document_state').nullable()();
  TextColumn get issuerLegalName =>
      text().named('issuer_legal_name').nullable()();
  TextColumn get issuerTradeName =>
      text().named('issuer_trade_name').nullable()();
  TextColumn get fiscalCnaeDescription =>
      text().named('fiscal_cnae_description').nullable()();
  TextColumn get issuerCity => text().named('issuer_city').nullable()();
  TextColumn get issuerState => text().named('issuer_state').nullable()();
  RealColumn get ocrConfidence => real().named('ocr_confidence').nullable()();
  TextColumn get extractionParser =>
      text().named('extraction_parser').nullable()();
  RealColumn get extractionConfidence =>
      real().named('extraction_confidence').nullable()();
  RealColumn get valueConfidence =>
      real().named('value_confidence').nullable()();
  RealColumn get dateConfidence => real().named('date_confidence').nullable()();
  RealColumn get establishmentConfidence =>
      real().named('establishment_confidence').nullable()();
  RealColumn get paymentMethodConfidence =>
      real().named('payment_method_confidence').nullable()();
  TextColumn get qualityMetadata =>
      text().named('quality_metadata').nullable()();
}

@DataClassName('EmbeddingRow')
class Embeddings extends Table {
  @override
  String get tableName => 'embedding';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get receiptId => integer()
      .named('receipt_id')
      .unique()
      .references(Receipts, #id, onDelete: KeyAction.cascade)();
  BlobColumn get vector => blob().named('vector')();
  TextColumn get model => text().named('model')();
  IntColumn get dimension => integer().named('dimension')();
  DateTimeColumn get generatedAt => dateTime().named('generated_at')();
}

@DataClassName('CategoryRow')
class Categories extends Table {
  @override
  String get tableName => 'category';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().named('name').unique()();
  TextColumn get description => text().named('description').nullable()();
  BoolColumn get inferredAutomatically => boolean()
      .named('inferred_automatically')
      .withDefault(const Constant(false))();
  TextColumn get icon =>
      text().named('icon').withDefault(const Constant('category'))();
  IntColumn get colorArgb =>
      integer().named('color_argb').withDefault(const Constant(0xFFD2D8E3))();
}

@DataClassName('CnpjCacheRow')
class CnpjCache extends Table {
  @override
  String get tableName => 'cnpj_cache';

  TextColumn get cnpj => text()();
  TextColumn get legalName => text().named('legal_name').nullable()();
  TextColumn get tradeName => text().named('trade_name').nullable()();
  TextColumn get confirmedName => text().named('confirmed_name').nullable()();
  TextColumn get fiscalCnaeDescription =>
      text().named('fiscal_cnae_description').nullable()();
  TextColumn get city => text().named('city').nullable()();
  TextColumn get state => text().named('state').nullable()();
  IntColumn get preferredCategoryId => integer()
      .named('preferred_category_id')
      .nullable()
      .references(Categories, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {cnpj};
}

@DataClassName('EstablishmentCategoryCacheRow')
class EstablishmentCategoryCache extends Table {
  @override
  String get tableName => 'establishment_category_cache';

  TextColumn get establishmentKey => text().named('establishment_key')();
  TextColumn get establishment => text().named('establishment')();
  IntColumn get categoryId => integer()
      .named('category_id')
      .references(Categories, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {establishmentKey};
}

@DataClassName('ItemCategoryCacheRow')
class ItemCategoryCache extends Table {
  @override
  String get tableName => 'item_category_cache';

  TextColumn get itemKey => text().named('item_key')();
  TextColumn get item => text()();
  IntColumn get categoryId => integer()
      .named('category_id')
      .references(Categories, #id, onDelete: KeyAction.cascade)();
  IntColumn get occurrences =>
      integer().named('occurrences').withDefault(const Constant(1))();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column<Object>> get primaryKey => {itemKey, categoryId};
}

@DataClassName('ConfigurationRow')
class Configurations extends Table {
  @override
  String get tableName => 'configuration';

  IntColumn get id => integer().autoIncrement()();
  BoolColumn get localAuthEnabled => boolean()
      .named('local_auth_enabled')
      .withDefault(const Constant(false))();
  TextColumn get authenticationType =>
      text().named('authentication_type').nullable()();
  IntColumn get autoLockIntervalMinutes => integer()
      .named('auto_lock_interval_minutes')
      .withDefault(Constant(Configuration.defaultAutoLockIntervalMinutes))();
  TextColumn get cloudProvider => text().named('cloud_provider').nullable()();
  TextColumn get linkedCloudAccount =>
      text().named('linked_cloud_account').nullable()();
  BoolColumn get cloudTokenValid =>
      boolean().named('cloud_token_valid').withDefault(const Constant(false))();
  DateTimeColumn get cloudLinkedAt =>
      dateTime().named('cloud_linked_at').nullable()();
  BoolColumn get backupReminderEnabled => boolean()
      .named('backup_reminder_enabled')
      .withDefault(const Constant(false))();
  IntColumn get reminderIntervalDays => integer()
      .named('reminder_interval_days')
      .withDefault(const Constant(7))();
  IntColumn get storageLimitMb =>
      integer().named('storage_limit_mb').withDefault(const Constant(500))();
  BoolColumn get onboardingCompleted => boolean()
      .named('onboarding_completed')
      .withDefault(const Constant(false))();
  DateTimeColumn get lastSyncedExportAt =>
      dateTime().named('last_synced_export_at').nullable()();
  TextColumn get backupAvailability => text()
      .named('backup_availability')
      .withDefault(const Constant('INATIVO'))();
  TextColumn get visualThemeMode =>
      text().named('visual_theme_mode').withDefault(const Constant('ESCURO'))();
}

@DataClassName('BackupRecordRow')
class BackupRecords extends Table {
  @override
  String get tableName => 'backup_record';

  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  TextColumn get status => text().customConstraint(
    "NOT NULL CHECK(status IN ('PENDENTE','SINCRONIZADO','FALHA'))",
  )();
  TextColumn get operation => text()
      .named('operation')
      .customConstraint(
        "NOT NULL DEFAULT 'EXPORTACAO' CHECK(operation IN ('EXPORTACAO','RESTAURACAO'))",
      )();
  IntColumn get totalReceipts =>
      integer().named('total_receipts').withDefault(const Constant(0))();
  TextColumn get errorDescription =>
      text().named('error_description').nullable()();
  TextColumn get cloudProvider => text().named('cloud_provider').nullable()();
  TextColumn get linkedCloudAccount =>
      text().named('linked_cloud_account').nullable()();
  TextColumn get availability => text()
      .named('availability')
      .customConstraint(
        "NOT NULL DEFAULT 'INATIVO' CHECK(availability IN ('ATIVO','INATIVO','EXCLUIDO'))",
      )();
  IntColumn get configurationId => integer()
      .named('configuration_id')
      .references(Configurations, #id, onDelete: KeyAction.cascade)();
}

// coverage:ignore-end
