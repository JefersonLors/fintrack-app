import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite_vector/sqlite_vector.dart';

import '../../domain/entities/category.dart' as domain;
import '../../domain/entities/configuration.dart';
import '../../domain/value_objects/category_color_palette.dart';

part 'app_tables.dart';
part 'app_database_initial_categories.dart';
part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Receipts,
    ExtractedDataTable,
    Embeddings,
    Categories,
    CnpjCache,
    EstablishmentCategoryCache,
    ItemCategoryCache,
    Configurations,
    BackupRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? _openConnection()) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  factory AppDatabase.memory() {
    return AppDatabase(
      NativeDatabase.memory(
        sqlite3: _sqliteWithVector,
        setup: _configureSqliteConnection,
      ),
    );
  }

  @override
  int get schemaVersion => 25;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) async {
        await migrator.createAll();
        await _ensureSearchStructures();
        await _ensureFiscalCacheStructure();
        await _ensureCategoryOrderStructure();
        await _ensureReceiptBatchImportStructure();
        await _ensureSemanticIndexTaskStructure();
        await _ensureInitialData();
      },
      // coverage:ignore-start
      onUpgrade: (migrator, from, to) async {
        await _recreateSchema(migrator);
      },
      // coverage:ignore-end
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        await _ensureIndexes();
        await _ensureSearchStructures();
        await _ensureFiscalCacheStructure();
        await _ensureCategoryOrderStructure();
        await _ensureReceiptBatchImportStructure();
        await _ensureSemanticIndexTaskStructure();
        await _normalizeCategoryColors();
        await _ensureCategoryOrder();
      },
    );
  }

  Future<void> _ensureSearchStructures() async {
    await customStatement(
      "CREATE VIRTUAL TABLE IF NOT EXISTS receipt_fts USING fts5("
      "text, structured, ocr, tokenize='unicode61 remove_diacritics 2')",
    );
    await customStatement(
      'CREATE TABLE IF NOT EXISTS embedding_vector ('
      'receipt_id INTEGER PRIMARY KEY REFERENCES receipt(id) ON DELETE CASCADE, '
      'vector BLOB NOT NULL, '
      'model TEXT NOT NULL, '
      'dimension INTEGER NOT NULL'
      ')',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_embedding_vector_dimension '
      'ON embedding_vector(dimension)',
    );
  }

  Future<void> _ensureFiscalCacheStructure() async {
    await customStatement(
      'CREATE TABLE IF NOT EXISTS fiscal_document_cache ('
      'access_key TEXT PRIMARY KEY, '
      'qr_code_url TEXT UNIQUE, '
      'issuer_cnpj TEXT, '
      'establishment TEXT, '
      'amount REAL, '
      'issued_at INTEGER, '
      'updated_at INTEGER NOT NULL'
      ')',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_fiscal_document_cache_issuer_cnpj '
      'ON fiscal_document_cache(issuer_cnpj)',
    );
  }

  Future<void> _ensureCategoryOrderStructure() async {
    await customStatement(
      'CREATE TABLE IF NOT EXISTS category_order ('
      'category_id INTEGER PRIMARY KEY REFERENCES category(id) ON DELETE CASCADE, '
      'sort_order INTEGER NOT NULL'
      ')',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_category_order_sort_order '
      'ON category_order(sort_order)',
    );
  }

  Future<void> _ensureReceiptBatchImportStructure() async {
    await customStatement(
      'CREATE TABLE IF NOT EXISTS receipt_batch_import_session ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'created_at INTEGER NOT NULL, '
      'updated_at INTEGER NOT NULL, '
      "status TEXT NOT NULL CHECK(status IN ('PENDENTE','PROCESSANDO','REVISAO','CONCLUIDO','CANCELADO')), "
      'staging_directory TEXT NOT NULL, '
      'total_items INTEGER NOT NULL'
      ')',
    );
    await customStatement(
      'CREATE TABLE IF NOT EXISTS receipt_batch_import_item ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'session_id INTEGER NOT NULL REFERENCES receipt_batch_import_session(id) ON DELETE CASCADE, '
      'item_number INTEGER NOT NULL, '
      'original_path TEXT NOT NULL, '
      'staged_path TEXT NOT NULL, '
      "status TEXT NOT NULL CHECK(status IN ('PENDENTE','PROCESSANDO','PRONTO','FALHA','SALVO')), "
      'error_description TEXT, '
      'receipt_json TEXT, '
      'updated_at INTEGER NOT NULL'
      ')',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_receipt_batch_import_item_session '
      'ON receipt_batch_import_item(session_id, item_number)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_receipt_batch_import_session_status '
      'ON receipt_batch_import_session(status, updated_at)',
    );
  }

  Future<void> _ensureSemanticIndexTaskStructure() async {
    await customStatement(
      'CREATE TABLE IF NOT EXISTS semantic_index_task ('
      'receipt_id INTEGER PRIMARY KEY REFERENCES receipt(id) ON DELETE CASCADE, '
      "status TEXT NOT NULL CHECK(status IN ('PENDENTE','PROCESSANDO','CONCLUIDO','FALHA')), "
      'attempts INTEGER NOT NULL DEFAULT 0, '
      'error_description TEXT, '
      'updated_at INTEGER NOT NULL'
      ')',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_semantic_index_task_status '
      'ON semantic_index_task(status, updated_at)',
    );
  }

  Future<void> _ensureCategoryOrder() async {
    await customStatement(
      'INSERT INTO category_order (category_id, sort_order) '
      'SELECT c.id, c.id FROM category c '
      'WHERE NOT EXISTS ('
      'SELECT 1 FROM category_order o WHERE o.category_id = c.id'
      ')',
    );
  }

  Future<void> _ensureIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_receipt_type ON receipt(type)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_receipt_registered_at ON receipt(registered_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_extracted_data_transaction_date ON extracted_data(transaction_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_extracted_data_amount ON extracted_data(amount)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_extracted_data_establishment ON extracted_data(establishment)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_receipt_category ON receipt(category_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_category_name ON category(name)',
    );
  }

  Future<void> _recreateSchema(Migrator migrator) async {
    // coverage:ignore-start
    await customStatement('PRAGMA foreign_keys = OFF');
    await customStatement('DROP TABLE IF EXISTS receipt_fts');
    await customStatement('DROP TABLE IF EXISTS embedding_vector');
    await customStatement('DROP TABLE IF EXISTS category_order');
    for (final table in allTables) {
      await migrator.deleteTable(table.actualTableName);
    }
    await migrator.createAll();
    await _ensureSearchStructures();
    await _ensureFiscalCacheStructure();
    await _ensureCategoryOrderStructure();
    await _ensureReceiptBatchImportStructure();
    await _ensureSemanticIndexTaskStructure();
    await customStatement('PRAGMA foreign_keys = ON');
    // coverage:ignore-end
  }

  Future<void> _ensureInitialData() async {
    await into(configurations).insert(
      const ConfigurationsCompanion(id: Value(1)),
      mode: InsertMode.insertOrIgnore,
    );

    final existing = await select(categories).get();
    final initial = _initialCategories();
    if (existing.isEmpty) {
      await batch((batch) {
        batch.insertAll(
          categories,
          initial.map(_initialCategoryCompanion).toList(),
          mode: InsertMode.insertOrIgnore,
        );
      });
      return;
    }

    final existingNames = existing
        .map((row) => row.name.trim().toLowerCase())
        .toSet();
    final missing = initial.where(
      (category) => !existingNames.contains(category.name.toLowerCase()),
    );
    await batch((batch) {
      batch.insertAll(
        categories,
        missing
            .map(
              (category) => _initialCategoryCompanion(
                category.copyWith(id: 0),
                includeId: false,
              ),
            )
            .toList(),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  Future<void> ensureInitialDataForTesting() {
    return _ensureInitialData();
  }

  CategoriesCompanion _initialCategoryCompanion(
    domain.Category category, {
    bool includeId = true,
  }) {
    return CategoriesCompanion.insert(
      id: includeId ? Value(category.id) : const Value.absent(),
      name: category.name,
      description: Value(category.description),
      inferredAutomatically: Value(category.inferredAutomatically),
      icon: Value(category.icon),
      colorArgb: Value(category.colorArgb),
    );
  }

  Future<void> _normalizeCategoryColors() async {
    const primary = CategoryColorPalette.primary;
    const noColor = CategoryColorPalette.noColor;
    const info = CategoryColorPalette.info;
    const blue = CategoryColorPalette.blue;
    const mint = CategoryColorPalette.mint;
    await customStatement(
      'UPDATE category SET color_argb = CASE color_argb '
      'WHEN 0xFFC47A4A THEN $noColor '
      'WHEN 0xFFDFA85B THEN $noColor '
      'WHEN 0xFF74C69D THEN $mint '
      'WHEN 0xFFB98CE8 THEN $info '
      'WHEN 0xFFA9A7D9 THEN $noColor '
      'WHEN 0xFFD6B86F THEN $noColor '
      'WHEN 0xFFE88AA2 THEN $noColor '
      'WHEN 0xFFB08AC7 THEN $noColor '
      'WHEN 0xFFD56B6B THEN $noColor '
      'WHEN 0xFF6FD6C4 THEN $mint '
      'WHEN 0xFFA8B0BE THEN $info '
      'WHEN 0xFF6FAF7A THEN $mint '
      'WHEN $noColor THEN $noColor '
      'WHEN $primary THEN $primary '
      'WHEN $info THEN $info '
      'WHEN $blue THEN $blue '
      'WHEN $mint THEN $mint '
      'ELSE $noColor END '
      'WHERE color_argb NOT IN ($noColor, $primary, $info, $blue, $mint)',
    );
  }

  static QueryExecutor _openConnection() {
    // Uses path_provider and the device filesystem. Tests use
    // AppDatabase.memory to cover the schema without depending on the platform.
    // coverage:ignore-start
    return LazyDatabase(() async {
      final documentsDir = await getApplicationDocumentsDirectory();
      final dbFolder = Directory(p.join(documentsDir.path, 'fintrack'));
      await dbFolder.create(recursive: true);
      final file = File(p.join(dbFolder.path, 'fin_track.sqlite'));
      return NativeDatabase.createInBackground(
        file,
        sqlite3: _sqliteWithVector,
        setup: _configureSqliteConnection,
      );
    });
    // coverage:ignore-end
  }
}

void _configureSqliteConnection(Database database) {
  database.execute('PRAGMA busy_timeout = 5000');
  database.execute('PRAGMA journal_mode = WAL');
}

Sqlite3 _sqliteWithVector() {
  sqlite3.loadSqliteVectorExtension();
  return sqlite3;
}
