// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inferredAutomaticallyMeta =
      const VerificationMeta('inferredAutomatically');
  @override
  late final GeneratedColumn<bool> inferredAutomatically =
      GeneratedColumn<bool>(
        'inferred_automatically',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("inferred_automatically" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('category'),
  );
  static const VerificationMeta _colorArgbMeta = const VerificationMeta(
    'colorArgb',
  );
  @override
  late final GeneratedColumn<int> colorArgb = GeneratedColumn<int>(
    'color_argb',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFFD2D8E3),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    inferredAutomatically,
    icon,
    colorArgb,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('inferred_automatically')) {
      context.handle(
        _inferredAutomaticallyMeta,
        inferredAutomatically.isAcceptableOrUnknown(
          data['inferred_automatically']!,
          _inferredAutomaticallyMeta,
        ),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color_argb')) {
      context.handle(
        _colorArgbMeta,
        colorArgb.isAcceptableOrUnknown(data['color_argb']!, _colorArgbMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      inferredAutomatically: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}inferred_automatically'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      colorArgb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_argb'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final int id;
  final String name;
  final String? description;
  final bool inferredAutomatically;
  final String icon;
  final int colorArgb;
  const CategoryRow({
    required this.id,
    required this.name,
    this.description,
    required this.inferredAutomatically,
    required this.icon,
    required this.colorArgb,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['inferred_automatically'] = Variable<bool>(inferredAutomatically);
    map['icon'] = Variable<String>(icon);
    map['color_argb'] = Variable<int>(colorArgb);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      inferredAutomatically: Value(inferredAutomatically),
      icon: Value(icon),
      colorArgb: Value(colorArgb),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      inferredAutomatically: serializer.fromJson<bool>(
        json['inferredAutomatically'],
      ),
      icon: serializer.fromJson<String>(json['icon']),
      colorArgb: serializer.fromJson<int>(json['colorArgb']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'inferredAutomatically': serializer.toJson<bool>(inferredAutomatically),
      'icon': serializer.toJson<String>(icon),
      'colorArgb': serializer.toJson<int>(colorArgb),
    };
  }

  CategoryRow copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    bool? inferredAutomatically,
    String? icon,
    int? colorArgb,
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    inferredAutomatically: inferredAutomatically ?? this.inferredAutomatically,
    icon: icon ?? this.icon,
    colorArgb: colorArgb ?? this.colorArgb,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      inferredAutomatically: data.inferredAutomatically.present
          ? data.inferredAutomatically.value
          : this.inferredAutomatically,
      icon: data.icon.present ? data.icon.value : this.icon,
      colorArgb: data.colorArgb.present ? data.colorArgb.value : this.colorArgb,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('inferredAutomatically: $inferredAutomatically, ')
          ..write('icon: $icon, ')
          ..write('colorArgb: $colorArgb')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    inferredAutomatically,
    icon,
    colorArgb,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.inferredAutomatically == this.inferredAutomatically &&
          other.icon == this.icon &&
          other.colorArgb == this.colorArgb);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<bool> inferredAutomatically;
  final Value<String> icon;
  final Value<int> colorArgb;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.inferredAutomatically = const Value.absent(),
    this.icon = const Value.absent(),
    this.colorArgb = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.inferredAutomatically = const Value.absent(),
    this.icon = const Value.absent(),
    this.colorArgb = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CategoryRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? inferredAutomatically,
    Expression<String>? icon,
    Expression<int>? colorArgb,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (inferredAutomatically != null)
        'inferred_automatically': inferredAutomatically,
      if (icon != null) 'icon': icon,
      if (colorArgb != null) 'color_argb': colorArgb,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<bool>? inferredAutomatically,
    Value<String>? icon,
    Value<int>? colorArgb,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      inferredAutomatically:
          inferredAutomatically ?? this.inferredAutomatically,
      icon: icon ?? this.icon,
      colorArgb: colorArgb ?? this.colorArgb,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (inferredAutomatically.present) {
      map['inferred_automatically'] = Variable<bool>(
        inferredAutomatically.value,
      );
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (colorArgb.present) {
      map['color_argb'] = Variable<int>(colorArgb.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('inferredAutomatically: $inferredAutomatically, ')
          ..write('icon: $icon, ')
          ..write('colorArgb: $colorArgb')
          ..write(')'))
        .toString();
  }
}

class $ReceiptsTable extends Receipts
    with TableInfo<$ReceiptsTable, ReceiptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK(type IN (\'NOTA_FISCAL\',\'RECIBO\',\'COMPROVANTE_PIX\',\'OUTROS\'))',
  );
  static const VerificationMeta _expenseMeta = const VerificationMeta(
    'expense',
  );
  @override
  late final GeneratedColumn<bool> expense = GeneratedColumn<bool>(
    'is_expense',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_expense" IN (0, 1))',
    ),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _fileTypeMeta = const VerificationMeta(
    'fileType',
  );
  @override
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
    'file_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta(
    'fileHash',
  );
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extractedContentMeta = const VerificationMeta(
    'extractedContent',
  );
  @override
  late final GeneratedColumn<String> extractedContent = GeneratedColumn<String>(
    'extracted_content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES category (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _cloudSyncedMeta = const VerificationMeta(
    'cloudSynced',
  );
  @override
  late final GeneratedColumn<bool> cloudSynced = GeneratedColumn<bool>(
    'cloud_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cloud_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _registeredAtMeta = const VerificationMeta(
    'registeredAt',
  );
  @override
  late final GeneratedColumn<DateTime> registeredAt = GeneratedColumn<DateTime>(
    'registered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    expense,
    fileName,
    fileType,
    fileHash,
    fileSize,
    extractedContent,
    categoryId,
    cloudSynced,
    registeredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipt';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceiptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('is_expense')) {
      context.handle(
        _expenseMeta,
        expense.isAcceptableOrUnknown(data['is_expense']!, _expenseMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_type')) {
      context.handle(
        _fileTypeMeta,
        fileType.isAcceptableOrUnknown(data['file_type']!, _fileTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileTypeMeta);
    }
    if (data.containsKey('file_hash')) {
      context.handle(
        _fileHashMeta,
        fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('extracted_content')) {
      context.handle(
        _extractedContentMeta,
        extractedContent.isAcceptableOrUnknown(
          data['extracted_content']!,
          _extractedContentMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('cloud_synced')) {
      context.handle(
        _cloudSyncedMeta,
        cloudSynced.isAcceptableOrUnknown(
          data['cloud_synced']!,
          _cloudSyncedMeta,
        ),
      );
    }
    if (data.containsKey('registered_at')) {
      context.handle(
        _registeredAtMeta,
        registeredAt.isAcceptableOrUnknown(
          data['registered_at']!,
          _registeredAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_registeredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReceiptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceiptRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      expense: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_expense'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      fileType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_type'],
      )!,
      fileHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_hash'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      ),
      extractedContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extracted_content'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      cloudSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cloud_synced'],
      )!,
      registeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}registered_at'],
      )!,
    );
  }

  @override
  $ReceiptsTable createAlias(String alias) {
    return $ReceiptsTable(attachedDatabase, alias);
  }
}

class ReceiptRow extends DataClass implements Insertable<ReceiptRow> {
  final int id;
  final String type;
  final bool expense;
  final String fileName;
  final String fileType;
  final String? fileHash;
  final int? fileSize;
  final String extractedContent;
  final int? categoryId;
  final bool cloudSynced;
  final DateTime registeredAt;
  const ReceiptRow({
    required this.id,
    required this.type,
    required this.expense,
    required this.fileName,
    required this.fileType,
    this.fileHash,
    this.fileSize,
    required this.extractedContent,
    this.categoryId,
    required this.cloudSynced,
    required this.registeredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['is_expense'] = Variable<bool>(expense);
    map['file_name'] = Variable<String>(fileName);
    map['file_type'] = Variable<String>(fileType);
    if (!nullToAbsent || fileHash != null) {
      map['file_hash'] = Variable<String>(fileHash);
    }
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    map['extracted_content'] = Variable<String>(extractedContent);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['cloud_synced'] = Variable<bool>(cloudSynced);
    map['registered_at'] = Variable<DateTime>(registeredAt);
    return map;
  }

  ReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptsCompanion(
      id: Value(id),
      type: Value(type),
      expense: Value(expense),
      fileName: Value(fileName),
      fileType: Value(fileType),
      fileHash: fileHash == null && nullToAbsent
          ? const Value.absent()
          : Value(fileHash),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
      extractedContent: Value(extractedContent),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      cloudSynced: Value(cloudSynced),
      registeredAt: Value(registeredAt),
    );
  }

  factory ReceiptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceiptRow(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      expense: serializer.fromJson<bool>(json['expense']),
      fileName: serializer.fromJson<String>(json['fileName']),
      fileType: serializer.fromJson<String>(json['fileType']),
      fileHash: serializer.fromJson<String?>(json['fileHash']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
      extractedContent: serializer.fromJson<String>(json['extractedContent']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      cloudSynced: serializer.fromJson<bool>(json['cloudSynced']),
      registeredAt: serializer.fromJson<DateTime>(json['registeredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'expense': serializer.toJson<bool>(expense),
      'fileName': serializer.toJson<String>(fileName),
      'fileType': serializer.toJson<String>(fileType),
      'fileHash': serializer.toJson<String?>(fileHash),
      'fileSize': serializer.toJson<int?>(fileSize),
      'extractedContent': serializer.toJson<String>(extractedContent),
      'categoryId': serializer.toJson<int?>(categoryId),
      'cloudSynced': serializer.toJson<bool>(cloudSynced),
      'registeredAt': serializer.toJson<DateTime>(registeredAt),
    };
  }

  ReceiptRow copyWith({
    int? id,
    String? type,
    bool? expense,
    String? fileName,
    String? fileType,
    Value<String?> fileHash = const Value.absent(),
    Value<int?> fileSize = const Value.absent(),
    String? extractedContent,
    Value<int?> categoryId = const Value.absent(),
    bool? cloudSynced,
    DateTime? registeredAt,
  }) => ReceiptRow(
    id: id ?? this.id,
    type: type ?? this.type,
    expense: expense ?? this.expense,
    fileName: fileName ?? this.fileName,
    fileType: fileType ?? this.fileType,
    fileHash: fileHash.present ? fileHash.value : this.fileHash,
    fileSize: fileSize.present ? fileSize.value : this.fileSize,
    extractedContent: extractedContent ?? this.extractedContent,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    cloudSynced: cloudSynced ?? this.cloudSynced,
    registeredAt: registeredAt ?? this.registeredAt,
  );
  ReceiptRow copyWithCompanion(ReceiptsCompanion data) {
    return ReceiptRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      expense: data.expense.present ? data.expense.value : this.expense,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      extractedContent: data.extractedContent.present
          ? data.extractedContent.value
          : this.extractedContent,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      cloudSynced: data.cloudSynced.present
          ? data.cloudSynced.value
          : this.cloudSynced,
      registeredAt: data.registeredAt.present
          ? data.registeredAt.value
          : this.registeredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('expense: $expense, ')
          ..write('fileName: $fileName, ')
          ..write('fileType: $fileType, ')
          ..write('fileHash: $fileHash, ')
          ..write('fileSize: $fileSize, ')
          ..write('extractedContent: $extractedContent, ')
          ..write('categoryId: $categoryId, ')
          ..write('cloudSynced: $cloudSynced, ')
          ..write('registeredAt: $registeredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    expense,
    fileName,
    fileType,
    fileHash,
    fileSize,
    extractedContent,
    categoryId,
    cloudSynced,
    registeredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceiptRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.expense == this.expense &&
          other.fileName == this.fileName &&
          other.fileType == this.fileType &&
          other.fileHash == this.fileHash &&
          other.fileSize == this.fileSize &&
          other.extractedContent == this.extractedContent &&
          other.categoryId == this.categoryId &&
          other.cloudSynced == this.cloudSynced &&
          other.registeredAt == this.registeredAt);
}

class ReceiptsCompanion extends UpdateCompanion<ReceiptRow> {
  final Value<int> id;
  final Value<String> type;
  final Value<bool> expense;
  final Value<String> fileName;
  final Value<String> fileType;
  final Value<String?> fileHash;
  final Value<int?> fileSize;
  final Value<String> extractedContent;
  final Value<int?> categoryId;
  final Value<bool> cloudSynced;
  final Value<DateTime> registeredAt;
  const ReceiptsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.expense = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileType = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.extractedContent = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.cloudSynced = const Value.absent(),
    this.registeredAt = const Value.absent(),
  });
  ReceiptsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required bool expense,
    required String fileName,
    required String fileType,
    this.fileHash = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.extractedContent = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.cloudSynced = const Value.absent(),
    required DateTime registeredAt,
  }) : type = Value(type),
       expense = Value(expense),
       fileName = Value(fileName),
       fileType = Value(fileType),
       registeredAt = Value(registeredAt);
  static Insertable<ReceiptRow> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<bool>? expense,
    Expression<String>? fileName,
    Expression<String>? fileType,
    Expression<String>? fileHash,
    Expression<int>? fileSize,
    Expression<String>? extractedContent,
    Expression<int>? categoryId,
    Expression<bool>? cloudSynced,
    Expression<DateTime>? registeredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (expense != null) 'is_expense': expense,
      if (fileName != null) 'file_name': fileName,
      if (fileType != null) 'file_type': fileType,
      if (fileHash != null) 'file_hash': fileHash,
      if (fileSize != null) 'file_size': fileSize,
      if (extractedContent != null) 'extracted_content': extractedContent,
      if (categoryId != null) 'category_id': categoryId,
      if (cloudSynced != null) 'cloud_synced': cloudSynced,
      if (registeredAt != null) 'registered_at': registeredAt,
    });
  }

  ReceiptsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<bool>? expense,
    Value<String>? fileName,
    Value<String>? fileType,
    Value<String?>? fileHash,
    Value<int?>? fileSize,
    Value<String>? extractedContent,
    Value<int?>? categoryId,
    Value<bool>? cloudSynced,
    Value<DateTime>? registeredAt,
  }) {
    return ReceiptsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      expense: expense ?? this.expense,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileHash: fileHash ?? this.fileHash,
      fileSize: fileSize ?? this.fileSize,
      extractedContent: extractedContent ?? this.extractedContent,
      categoryId: categoryId ?? this.categoryId,
      cloudSynced: cloudSynced ?? this.cloudSynced,
      registeredAt: registeredAt ?? this.registeredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (expense.present) {
      map['is_expense'] = Variable<bool>(expense.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (extractedContent.present) {
      map['extracted_content'] = Variable<String>(extractedContent.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (cloudSynced.present) {
      map['cloud_synced'] = Variable<bool>(cloudSynced.value);
    }
    if (registeredAt.present) {
      map['registered_at'] = Variable<DateTime>(registeredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('expense: $expense, ')
          ..write('fileName: $fileName, ')
          ..write('fileType: $fileType, ')
          ..write('fileHash: $fileHash, ')
          ..write('fileSize: $fileSize, ')
          ..write('extractedContent: $extractedContent, ')
          ..write('categoryId: $categoryId, ')
          ..write('cloudSynced: $cloudSynced, ')
          ..write('registeredAt: $registeredAt')
          ..write(')'))
        .toString();
  }
}

class $ExtractedDataTableTable extends ExtractedDataTable
    with TableInfo<$ExtractedDataTableTable, ExtractedDataRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExtractedDataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<int> receiptId = GeneratedColumn<int>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES receipt (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionDateMeta = const VerificationMeta(
    'transactionDate',
  );
  @override
  late final GeneratedColumn<DateTime> transactionDate =
      GeneratedColumn<DateTime>(
        'transaction_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _establishmentMeta = const VerificationMeta(
    'establishment',
  );
  @override
  late final GeneratedColumn<String> establishment = GeneratedColumn<String>(
    'establishment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemsMeta = const VerificationMeta('items');
  @override
  late final GeneratedColumn<String> items = GeneratedColumn<String>(
    'items',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issuerCnpjMeta = const VerificationMeta(
    'issuerCnpj',
  );
  @override
  late final GeneratedColumn<String> issuerCnpj = GeneratedColumn<String>(
    'issuer_cnpj',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accessKeyMeta = const VerificationMeta(
    'accessKey',
  );
  @override
  late final GeneratedColumn<String> accessKey = GeneratedColumn<String>(
    'access_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlQrCodeMeta = const VerificationMeta(
    'urlQrCode',
  );
  @override
  late final GeneratedColumn<String> urlQrCode = GeneratedColumn<String>(
    'qr_code_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _documentNumberMeta = const VerificationMeta(
    'documentNumber',
  );
  @override
  late final GeneratedColumn<String> documentNumber = GeneratedColumn<String>(
    'document_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _documentSeriesMeta = const VerificationMeta(
    'documentSeries',
  );
  @override
  late final GeneratedColumn<String> documentSeries = GeneratedColumn<String>(
    'document_series',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _documentStateMeta = const VerificationMeta(
    'documentState',
  );
  @override
  late final GeneratedColumn<String> documentState = GeneratedColumn<String>(
    'document_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issuerLegalNameMeta = const VerificationMeta(
    'issuerLegalName',
  );
  @override
  late final GeneratedColumn<String> issuerLegalName = GeneratedColumn<String>(
    'issuer_legal_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issuerTradeNameMeta = const VerificationMeta(
    'issuerTradeName',
  );
  @override
  late final GeneratedColumn<String> issuerTradeName = GeneratedColumn<String>(
    'issuer_trade_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fiscalCnaeDescriptionMeta =
      const VerificationMeta('fiscalCnaeDescription');
  @override
  late final GeneratedColumn<String> fiscalCnaeDescription =
      GeneratedColumn<String>(
        'fiscal_cnae_description',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _issuerCityMeta = const VerificationMeta(
    'issuerCity',
  );
  @override
  late final GeneratedColumn<String> issuerCity = GeneratedColumn<String>(
    'issuer_city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issuerStateMeta = const VerificationMeta(
    'issuerState',
  );
  @override
  late final GeneratedColumn<String> issuerState = GeneratedColumn<String>(
    'issuer_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ocrConfidenceMeta = const VerificationMeta(
    'ocrConfidence',
  );
  @override
  late final GeneratedColumn<double> ocrConfidence = GeneratedColumn<double>(
    'ocr_confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extractionParserMeta = const VerificationMeta(
    'extractionParser',
  );
  @override
  late final GeneratedColumn<String> extractionParser = GeneratedColumn<String>(
    'extraction_parser',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extractionConfidenceMeta =
      const VerificationMeta('extractionConfidence');
  @override
  late final GeneratedColumn<double> extractionConfidence =
      GeneratedColumn<double>(
        'extraction_confidence',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _valueConfidenceMeta = const VerificationMeta(
    'valueConfidence',
  );
  @override
  late final GeneratedColumn<double> valueConfidence = GeneratedColumn<double>(
    'value_confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateConfidenceMeta = const VerificationMeta(
    'dateConfidence',
  );
  @override
  late final GeneratedColumn<double> dateConfidence = GeneratedColumn<double>(
    'date_confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _establishmentConfidenceMeta =
      const VerificationMeta('establishmentConfidence');
  @override
  late final GeneratedColumn<double> establishmentConfidence =
      GeneratedColumn<double>(
        'establishment_confidence',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _paymentMethodConfidenceMeta =
      const VerificationMeta('paymentMethodConfidence');
  @override
  late final GeneratedColumn<double> paymentMethodConfidence =
      GeneratedColumn<double>(
        'payment_method_confidence',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _qualityMetadataMeta = const VerificationMeta(
    'qualityMetadata',
  );
  @override
  late final GeneratedColumn<String> qualityMetadata = GeneratedColumn<String>(
    'quality_metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    receiptId,
    amount,
    transactionDate,
    establishment,
    items,
    paymentMethod,
    issuerCnpj,
    accessKey,
    urlQrCode,
    documentNumber,
    documentSeries,
    documentState,
    issuerLegalName,
    issuerTradeName,
    fiscalCnaeDescription,
    issuerCity,
    issuerState,
    ocrConfidence,
    extractionParser,
    extractionConfidence,
    valueConfidence,
    dateConfidence,
    establishmentConfidence,
    paymentMethodConfidence,
    qualityMetadata,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'extracted_data';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExtractedDataRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
        _transactionDateMeta,
        transactionDate.isAcceptableOrUnknown(
          data['transaction_date']!,
          _transactionDateMeta,
        ),
      );
    }
    if (data.containsKey('establishment')) {
      context.handle(
        _establishmentMeta,
        establishment.isAcceptableOrUnknown(
          data['establishment']!,
          _establishmentMeta,
        ),
      );
    }
    if (data.containsKey('items')) {
      context.handle(
        _itemsMeta,
        items.isAcceptableOrUnknown(data['items']!, _itemsMeta),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('issuer_cnpj')) {
      context.handle(
        _issuerCnpjMeta,
        issuerCnpj.isAcceptableOrUnknown(data['issuer_cnpj']!, _issuerCnpjMeta),
      );
    }
    if (data.containsKey('access_key')) {
      context.handle(
        _accessKeyMeta,
        accessKey.isAcceptableOrUnknown(data['access_key']!, _accessKeyMeta),
      );
    }
    if (data.containsKey('qr_code_url')) {
      context.handle(
        _urlQrCodeMeta,
        urlQrCode.isAcceptableOrUnknown(data['qr_code_url']!, _urlQrCodeMeta),
      );
    }
    if (data.containsKey('document_number')) {
      context.handle(
        _documentNumberMeta,
        documentNumber.isAcceptableOrUnknown(
          data['document_number']!,
          _documentNumberMeta,
        ),
      );
    }
    if (data.containsKey('document_series')) {
      context.handle(
        _documentSeriesMeta,
        documentSeries.isAcceptableOrUnknown(
          data['document_series']!,
          _documentSeriesMeta,
        ),
      );
    }
    if (data.containsKey('document_state')) {
      context.handle(
        _documentStateMeta,
        documentState.isAcceptableOrUnknown(
          data['document_state']!,
          _documentStateMeta,
        ),
      );
    }
    if (data.containsKey('issuer_legal_name')) {
      context.handle(
        _issuerLegalNameMeta,
        issuerLegalName.isAcceptableOrUnknown(
          data['issuer_legal_name']!,
          _issuerLegalNameMeta,
        ),
      );
    }
    if (data.containsKey('issuer_trade_name')) {
      context.handle(
        _issuerTradeNameMeta,
        issuerTradeName.isAcceptableOrUnknown(
          data['issuer_trade_name']!,
          _issuerTradeNameMeta,
        ),
      );
    }
    if (data.containsKey('fiscal_cnae_description')) {
      context.handle(
        _fiscalCnaeDescriptionMeta,
        fiscalCnaeDescription.isAcceptableOrUnknown(
          data['fiscal_cnae_description']!,
          _fiscalCnaeDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('issuer_city')) {
      context.handle(
        _issuerCityMeta,
        issuerCity.isAcceptableOrUnknown(data['issuer_city']!, _issuerCityMeta),
      );
    }
    if (data.containsKey('issuer_state')) {
      context.handle(
        _issuerStateMeta,
        issuerState.isAcceptableOrUnknown(
          data['issuer_state']!,
          _issuerStateMeta,
        ),
      );
    }
    if (data.containsKey('ocr_confidence')) {
      context.handle(
        _ocrConfidenceMeta,
        ocrConfidence.isAcceptableOrUnknown(
          data['ocr_confidence']!,
          _ocrConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('extraction_parser')) {
      context.handle(
        _extractionParserMeta,
        extractionParser.isAcceptableOrUnknown(
          data['extraction_parser']!,
          _extractionParserMeta,
        ),
      );
    }
    if (data.containsKey('extraction_confidence')) {
      context.handle(
        _extractionConfidenceMeta,
        extractionConfidence.isAcceptableOrUnknown(
          data['extraction_confidence']!,
          _extractionConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('value_confidence')) {
      context.handle(
        _valueConfidenceMeta,
        valueConfidence.isAcceptableOrUnknown(
          data['value_confidence']!,
          _valueConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('date_confidence')) {
      context.handle(
        _dateConfidenceMeta,
        dateConfidence.isAcceptableOrUnknown(
          data['date_confidence']!,
          _dateConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('establishment_confidence')) {
      context.handle(
        _establishmentConfidenceMeta,
        establishmentConfidence.isAcceptableOrUnknown(
          data['establishment_confidence']!,
          _establishmentConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('payment_method_confidence')) {
      context.handle(
        _paymentMethodConfidenceMeta,
        paymentMethodConfidence.isAcceptableOrUnknown(
          data['payment_method_confidence']!,
          _paymentMethodConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('quality_metadata')) {
      context.handle(
        _qualityMetadataMeta,
        qualityMetadata.isAcceptableOrUnknown(
          data['quality_metadata']!,
          _qualityMetadataMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExtractedDataRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExtractedDataRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receipt_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      ),
      transactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transaction_date'],
      ),
      establishment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}establishment'],
      ),
      items: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}items'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      issuerCnpj: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issuer_cnpj'],
      ),
      accessKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_key'],
      ),
      urlQrCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qr_code_url'],
      ),
      documentNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_number'],
      ),
      documentSeries: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_series'],
      ),
      documentState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_state'],
      ),
      issuerLegalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issuer_legal_name'],
      ),
      issuerTradeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issuer_trade_name'],
      ),
      fiscalCnaeDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fiscal_cnae_description'],
      ),
      issuerCity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issuer_city'],
      ),
      issuerState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issuer_state'],
      ),
      ocrConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ocr_confidence'],
      ),
      extractionParser: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extraction_parser'],
      ),
      extractionConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}extraction_confidence'],
      ),
      valueConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value_confidence'],
      ),
      dateConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}date_confidence'],
      ),
      establishmentConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}establishment_confidence'],
      ),
      paymentMethodConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}payment_method_confidence'],
      ),
      qualityMetadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality_metadata'],
      ),
    );
  }

  @override
  $ExtractedDataTableTable createAlias(String alias) {
    return $ExtractedDataTableTable(attachedDatabase, alias);
  }
}

class ExtractedDataRow extends DataClass
    implements Insertable<ExtractedDataRow> {
  final int id;
  final int receiptId;
  final double? amount;
  final DateTime? transactionDate;
  final String? establishment;
  final String items;
  final String? paymentMethod;
  final String? issuerCnpj;
  final String? accessKey;
  final String? urlQrCode;
  final String? documentNumber;
  final String? documentSeries;
  final String? documentState;
  final String? issuerLegalName;
  final String? issuerTradeName;
  final String? fiscalCnaeDescription;
  final String? issuerCity;
  final String? issuerState;
  final double? ocrConfidence;
  final String? extractionParser;
  final double? extractionConfidence;
  final double? valueConfidence;
  final double? dateConfidence;
  final double? establishmentConfidence;
  final double? paymentMethodConfidence;
  final String? qualityMetadata;
  const ExtractedDataRow({
    required this.id,
    required this.receiptId,
    this.amount,
    this.transactionDate,
    this.establishment,
    required this.items,
    this.paymentMethod,
    this.issuerCnpj,
    this.accessKey,
    this.urlQrCode,
    this.documentNumber,
    this.documentSeries,
    this.documentState,
    this.issuerLegalName,
    this.issuerTradeName,
    this.fiscalCnaeDescription,
    this.issuerCity,
    this.issuerState,
    this.ocrConfidence,
    this.extractionParser,
    this.extractionConfidence,
    this.valueConfidence,
    this.dateConfidence,
    this.establishmentConfidence,
    this.paymentMethodConfidence,
    this.qualityMetadata,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['receipt_id'] = Variable<int>(receiptId);
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<double>(amount);
    }
    if (!nullToAbsent || transactionDate != null) {
      map['transaction_date'] = Variable<DateTime>(transactionDate);
    }
    if (!nullToAbsent || establishment != null) {
      map['establishment'] = Variable<String>(establishment);
    }
    map['items'] = Variable<String>(items);
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    if (!nullToAbsent || issuerCnpj != null) {
      map['issuer_cnpj'] = Variable<String>(issuerCnpj);
    }
    if (!nullToAbsent || accessKey != null) {
      map['access_key'] = Variable<String>(accessKey);
    }
    if (!nullToAbsent || urlQrCode != null) {
      map['qr_code_url'] = Variable<String>(urlQrCode);
    }
    if (!nullToAbsent || documentNumber != null) {
      map['document_number'] = Variable<String>(documentNumber);
    }
    if (!nullToAbsent || documentSeries != null) {
      map['document_series'] = Variable<String>(documentSeries);
    }
    if (!nullToAbsent || documentState != null) {
      map['document_state'] = Variable<String>(documentState);
    }
    if (!nullToAbsent || issuerLegalName != null) {
      map['issuer_legal_name'] = Variable<String>(issuerLegalName);
    }
    if (!nullToAbsent || issuerTradeName != null) {
      map['issuer_trade_name'] = Variable<String>(issuerTradeName);
    }
    if (!nullToAbsent || fiscalCnaeDescription != null) {
      map['fiscal_cnae_description'] = Variable<String>(fiscalCnaeDescription);
    }
    if (!nullToAbsent || issuerCity != null) {
      map['issuer_city'] = Variable<String>(issuerCity);
    }
    if (!nullToAbsent || issuerState != null) {
      map['issuer_state'] = Variable<String>(issuerState);
    }
    if (!nullToAbsent || ocrConfidence != null) {
      map['ocr_confidence'] = Variable<double>(ocrConfidence);
    }
    if (!nullToAbsent || extractionParser != null) {
      map['extraction_parser'] = Variable<String>(extractionParser);
    }
    if (!nullToAbsent || extractionConfidence != null) {
      map['extraction_confidence'] = Variable<double>(extractionConfidence);
    }
    if (!nullToAbsent || valueConfidence != null) {
      map['value_confidence'] = Variable<double>(valueConfidence);
    }
    if (!nullToAbsent || dateConfidence != null) {
      map['date_confidence'] = Variable<double>(dateConfidence);
    }
    if (!nullToAbsent || establishmentConfidence != null) {
      map['establishment_confidence'] = Variable<double>(
        establishmentConfidence,
      );
    }
    if (!nullToAbsent || paymentMethodConfidence != null) {
      map['payment_method_confidence'] = Variable<double>(
        paymentMethodConfidence,
      );
    }
    if (!nullToAbsent || qualityMetadata != null) {
      map['quality_metadata'] = Variable<String>(qualityMetadata);
    }
    return map;
  }

  ExtractedDataTableCompanion toCompanion(bool nullToAbsent) {
    return ExtractedDataTableCompanion(
      id: Value(id),
      receiptId: Value(receiptId),
      amount: amount == null && nullToAbsent
          ? const Value.absent()
          : Value(amount),
      transactionDate: transactionDate == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionDate),
      establishment: establishment == null && nullToAbsent
          ? const Value.absent()
          : Value(establishment),
      items: Value(items),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      issuerCnpj: issuerCnpj == null && nullToAbsent
          ? const Value.absent()
          : Value(issuerCnpj),
      accessKey: accessKey == null && nullToAbsent
          ? const Value.absent()
          : Value(accessKey),
      urlQrCode: urlQrCode == null && nullToAbsent
          ? const Value.absent()
          : Value(urlQrCode),
      documentNumber: documentNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(documentNumber),
      documentSeries: documentSeries == null && nullToAbsent
          ? const Value.absent()
          : Value(documentSeries),
      documentState: documentState == null && nullToAbsent
          ? const Value.absent()
          : Value(documentState),
      issuerLegalName: issuerLegalName == null && nullToAbsent
          ? const Value.absent()
          : Value(issuerLegalName),
      issuerTradeName: issuerTradeName == null && nullToAbsent
          ? const Value.absent()
          : Value(issuerTradeName),
      fiscalCnaeDescription: fiscalCnaeDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(fiscalCnaeDescription),
      issuerCity: issuerCity == null && nullToAbsent
          ? const Value.absent()
          : Value(issuerCity),
      issuerState: issuerState == null && nullToAbsent
          ? const Value.absent()
          : Value(issuerState),
      ocrConfidence: ocrConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrConfidence),
      extractionParser: extractionParser == null && nullToAbsent
          ? const Value.absent()
          : Value(extractionParser),
      extractionConfidence: extractionConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(extractionConfidence),
      valueConfidence: valueConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(valueConfidence),
      dateConfidence: dateConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(dateConfidence),
      establishmentConfidence: establishmentConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(establishmentConfidence),
      paymentMethodConfidence: paymentMethodConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethodConfidence),
      qualityMetadata: qualityMetadata == null && nullToAbsent
          ? const Value.absent()
          : Value(qualityMetadata),
    );
  }

  factory ExtractedDataRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExtractedDataRow(
      id: serializer.fromJson<int>(json['id']),
      receiptId: serializer.fromJson<int>(json['receiptId']),
      amount: serializer.fromJson<double?>(json['amount']),
      transactionDate: serializer.fromJson<DateTime?>(json['transactionDate']),
      establishment: serializer.fromJson<String?>(json['establishment']),
      items: serializer.fromJson<String>(json['items']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      issuerCnpj: serializer.fromJson<String?>(json['issuerCnpj']),
      accessKey: serializer.fromJson<String?>(json['accessKey']),
      urlQrCode: serializer.fromJson<String?>(json['urlQrCode']),
      documentNumber: serializer.fromJson<String?>(json['documentNumber']),
      documentSeries: serializer.fromJson<String?>(json['documentSeries']),
      documentState: serializer.fromJson<String?>(json['documentState']),
      issuerLegalName: serializer.fromJson<String?>(json['issuerLegalName']),
      issuerTradeName: serializer.fromJson<String?>(json['issuerTradeName']),
      fiscalCnaeDescription: serializer.fromJson<String?>(
        json['fiscalCnaeDescription'],
      ),
      issuerCity: serializer.fromJson<String?>(json['issuerCity']),
      issuerState: serializer.fromJson<String?>(json['issuerState']),
      ocrConfidence: serializer.fromJson<double?>(json['ocrConfidence']),
      extractionParser: serializer.fromJson<String?>(json['extractionParser']),
      extractionConfidence: serializer.fromJson<double?>(
        json['extractionConfidence'],
      ),
      valueConfidence: serializer.fromJson<double?>(json['valueConfidence']),
      dateConfidence: serializer.fromJson<double?>(json['dateConfidence']),
      establishmentConfidence: serializer.fromJson<double?>(
        json['establishmentConfidence'],
      ),
      paymentMethodConfidence: serializer.fromJson<double?>(
        json['paymentMethodConfidence'],
      ),
      qualityMetadata: serializer.fromJson<String?>(json['qualityMetadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'receiptId': serializer.toJson<int>(receiptId),
      'amount': serializer.toJson<double?>(amount),
      'transactionDate': serializer.toJson<DateTime?>(transactionDate),
      'establishment': serializer.toJson<String?>(establishment),
      'items': serializer.toJson<String>(items),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'issuerCnpj': serializer.toJson<String?>(issuerCnpj),
      'accessKey': serializer.toJson<String?>(accessKey),
      'urlQrCode': serializer.toJson<String?>(urlQrCode),
      'documentNumber': serializer.toJson<String?>(documentNumber),
      'documentSeries': serializer.toJson<String?>(documentSeries),
      'documentState': serializer.toJson<String?>(documentState),
      'issuerLegalName': serializer.toJson<String?>(issuerLegalName),
      'issuerTradeName': serializer.toJson<String?>(issuerTradeName),
      'fiscalCnaeDescription': serializer.toJson<String?>(
        fiscalCnaeDescription,
      ),
      'issuerCity': serializer.toJson<String?>(issuerCity),
      'issuerState': serializer.toJson<String?>(issuerState),
      'ocrConfidence': serializer.toJson<double?>(ocrConfidence),
      'extractionParser': serializer.toJson<String?>(extractionParser),
      'extractionConfidence': serializer.toJson<double?>(extractionConfidence),
      'valueConfidence': serializer.toJson<double?>(valueConfidence),
      'dateConfidence': serializer.toJson<double?>(dateConfidence),
      'establishmentConfidence': serializer.toJson<double?>(
        establishmentConfidence,
      ),
      'paymentMethodConfidence': serializer.toJson<double?>(
        paymentMethodConfidence,
      ),
      'qualityMetadata': serializer.toJson<String?>(qualityMetadata),
    };
  }

  ExtractedDataRow copyWith({
    int? id,
    int? receiptId,
    Value<double?> amount = const Value.absent(),
    Value<DateTime?> transactionDate = const Value.absent(),
    Value<String?> establishment = const Value.absent(),
    String? items,
    Value<String?> paymentMethod = const Value.absent(),
    Value<String?> issuerCnpj = const Value.absent(),
    Value<String?> accessKey = const Value.absent(),
    Value<String?> urlQrCode = const Value.absent(),
    Value<String?> documentNumber = const Value.absent(),
    Value<String?> documentSeries = const Value.absent(),
    Value<String?> documentState = const Value.absent(),
    Value<String?> issuerLegalName = const Value.absent(),
    Value<String?> issuerTradeName = const Value.absent(),
    Value<String?> fiscalCnaeDescription = const Value.absent(),
    Value<String?> issuerCity = const Value.absent(),
    Value<String?> issuerState = const Value.absent(),
    Value<double?> ocrConfidence = const Value.absent(),
    Value<String?> extractionParser = const Value.absent(),
    Value<double?> extractionConfidence = const Value.absent(),
    Value<double?> valueConfidence = const Value.absent(),
    Value<double?> dateConfidence = const Value.absent(),
    Value<double?> establishmentConfidence = const Value.absent(),
    Value<double?> paymentMethodConfidence = const Value.absent(),
    Value<String?> qualityMetadata = const Value.absent(),
  }) => ExtractedDataRow(
    id: id ?? this.id,
    receiptId: receiptId ?? this.receiptId,
    amount: amount.present ? amount.value : this.amount,
    transactionDate: transactionDate.present
        ? transactionDate.value
        : this.transactionDate,
    establishment: establishment.present
        ? establishment.value
        : this.establishment,
    items: items ?? this.items,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    issuerCnpj: issuerCnpj.present ? issuerCnpj.value : this.issuerCnpj,
    accessKey: accessKey.present ? accessKey.value : this.accessKey,
    urlQrCode: urlQrCode.present ? urlQrCode.value : this.urlQrCode,
    documentNumber: documentNumber.present
        ? documentNumber.value
        : this.documentNumber,
    documentSeries: documentSeries.present
        ? documentSeries.value
        : this.documentSeries,
    documentState: documentState.present
        ? documentState.value
        : this.documentState,
    issuerLegalName: issuerLegalName.present
        ? issuerLegalName.value
        : this.issuerLegalName,
    issuerTradeName: issuerTradeName.present
        ? issuerTradeName.value
        : this.issuerTradeName,
    fiscalCnaeDescription: fiscalCnaeDescription.present
        ? fiscalCnaeDescription.value
        : this.fiscalCnaeDescription,
    issuerCity: issuerCity.present ? issuerCity.value : this.issuerCity,
    issuerState: issuerState.present ? issuerState.value : this.issuerState,
    ocrConfidence: ocrConfidence.present
        ? ocrConfidence.value
        : this.ocrConfidence,
    extractionParser: extractionParser.present
        ? extractionParser.value
        : this.extractionParser,
    extractionConfidence: extractionConfidence.present
        ? extractionConfidence.value
        : this.extractionConfidence,
    valueConfidence: valueConfidence.present
        ? valueConfidence.value
        : this.valueConfidence,
    dateConfidence: dateConfidence.present
        ? dateConfidence.value
        : this.dateConfidence,
    establishmentConfidence: establishmentConfidence.present
        ? establishmentConfidence.value
        : this.establishmentConfidence,
    paymentMethodConfidence: paymentMethodConfidence.present
        ? paymentMethodConfidence.value
        : this.paymentMethodConfidence,
    qualityMetadata: qualityMetadata.present
        ? qualityMetadata.value
        : this.qualityMetadata,
  );
  ExtractedDataRow copyWithCompanion(ExtractedDataTableCompanion data) {
    return ExtractedDataRow(
      id: data.id.present ? data.id.value : this.id,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      amount: data.amount.present ? data.amount.value : this.amount,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      establishment: data.establishment.present
          ? data.establishment.value
          : this.establishment,
      items: data.items.present ? data.items.value : this.items,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      issuerCnpj: data.issuerCnpj.present
          ? data.issuerCnpj.value
          : this.issuerCnpj,
      accessKey: data.accessKey.present ? data.accessKey.value : this.accessKey,
      urlQrCode: data.urlQrCode.present ? data.urlQrCode.value : this.urlQrCode,
      documentNumber: data.documentNumber.present
          ? data.documentNumber.value
          : this.documentNumber,
      documentSeries: data.documentSeries.present
          ? data.documentSeries.value
          : this.documentSeries,
      documentState: data.documentState.present
          ? data.documentState.value
          : this.documentState,
      issuerLegalName: data.issuerLegalName.present
          ? data.issuerLegalName.value
          : this.issuerLegalName,
      issuerTradeName: data.issuerTradeName.present
          ? data.issuerTradeName.value
          : this.issuerTradeName,
      fiscalCnaeDescription: data.fiscalCnaeDescription.present
          ? data.fiscalCnaeDescription.value
          : this.fiscalCnaeDescription,
      issuerCity: data.issuerCity.present
          ? data.issuerCity.value
          : this.issuerCity,
      issuerState: data.issuerState.present
          ? data.issuerState.value
          : this.issuerState,
      ocrConfidence: data.ocrConfidence.present
          ? data.ocrConfidence.value
          : this.ocrConfidence,
      extractionParser: data.extractionParser.present
          ? data.extractionParser.value
          : this.extractionParser,
      extractionConfidence: data.extractionConfidence.present
          ? data.extractionConfidence.value
          : this.extractionConfidence,
      valueConfidence: data.valueConfidence.present
          ? data.valueConfidence.value
          : this.valueConfidence,
      dateConfidence: data.dateConfidence.present
          ? data.dateConfidence.value
          : this.dateConfidence,
      establishmentConfidence: data.establishmentConfidence.present
          ? data.establishmentConfidence.value
          : this.establishmentConfidence,
      paymentMethodConfidence: data.paymentMethodConfidence.present
          ? data.paymentMethodConfidence.value
          : this.paymentMethodConfidence,
      qualityMetadata: data.qualityMetadata.present
          ? data.qualityMetadata.value
          : this.qualityMetadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExtractedDataRow(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('amount: $amount, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('establishment: $establishment, ')
          ..write('items: $items, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('issuerCnpj: $issuerCnpj, ')
          ..write('accessKey: $accessKey, ')
          ..write('urlQrCode: $urlQrCode, ')
          ..write('documentNumber: $documentNumber, ')
          ..write('documentSeries: $documentSeries, ')
          ..write('documentState: $documentState, ')
          ..write('issuerLegalName: $issuerLegalName, ')
          ..write('issuerTradeName: $issuerTradeName, ')
          ..write('fiscalCnaeDescription: $fiscalCnaeDescription, ')
          ..write('issuerCity: $issuerCity, ')
          ..write('issuerState: $issuerState, ')
          ..write('ocrConfidence: $ocrConfidence, ')
          ..write('extractionParser: $extractionParser, ')
          ..write('extractionConfidence: $extractionConfidence, ')
          ..write('valueConfidence: $valueConfidence, ')
          ..write('dateConfidence: $dateConfidence, ')
          ..write('establishmentConfidence: $establishmentConfidence, ')
          ..write('paymentMethodConfidence: $paymentMethodConfidence, ')
          ..write('qualityMetadata: $qualityMetadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    receiptId,
    amount,
    transactionDate,
    establishment,
    items,
    paymentMethod,
    issuerCnpj,
    accessKey,
    urlQrCode,
    documentNumber,
    documentSeries,
    documentState,
    issuerLegalName,
    issuerTradeName,
    fiscalCnaeDescription,
    issuerCity,
    issuerState,
    ocrConfidence,
    extractionParser,
    extractionConfidence,
    valueConfidence,
    dateConfidence,
    establishmentConfidence,
    paymentMethodConfidence,
    qualityMetadata,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtractedDataRow &&
          other.id == this.id &&
          other.receiptId == this.receiptId &&
          other.amount == this.amount &&
          other.transactionDate == this.transactionDate &&
          other.establishment == this.establishment &&
          other.items == this.items &&
          other.paymentMethod == this.paymentMethod &&
          other.issuerCnpj == this.issuerCnpj &&
          other.accessKey == this.accessKey &&
          other.urlQrCode == this.urlQrCode &&
          other.documentNumber == this.documentNumber &&
          other.documentSeries == this.documentSeries &&
          other.documentState == this.documentState &&
          other.issuerLegalName == this.issuerLegalName &&
          other.issuerTradeName == this.issuerTradeName &&
          other.fiscalCnaeDescription == this.fiscalCnaeDescription &&
          other.issuerCity == this.issuerCity &&
          other.issuerState == this.issuerState &&
          other.ocrConfidence == this.ocrConfidence &&
          other.extractionParser == this.extractionParser &&
          other.extractionConfidence == this.extractionConfidence &&
          other.valueConfidence == this.valueConfidence &&
          other.dateConfidence == this.dateConfidence &&
          other.establishmentConfidence == this.establishmentConfidence &&
          other.paymentMethodConfidence == this.paymentMethodConfidence &&
          other.qualityMetadata == this.qualityMetadata);
}

class ExtractedDataTableCompanion extends UpdateCompanion<ExtractedDataRow> {
  final Value<int> id;
  final Value<int> receiptId;
  final Value<double?> amount;
  final Value<DateTime?> transactionDate;
  final Value<String?> establishment;
  final Value<String> items;
  final Value<String?> paymentMethod;
  final Value<String?> issuerCnpj;
  final Value<String?> accessKey;
  final Value<String?> urlQrCode;
  final Value<String?> documentNumber;
  final Value<String?> documentSeries;
  final Value<String?> documentState;
  final Value<String?> issuerLegalName;
  final Value<String?> issuerTradeName;
  final Value<String?> fiscalCnaeDescription;
  final Value<String?> issuerCity;
  final Value<String?> issuerState;
  final Value<double?> ocrConfidence;
  final Value<String?> extractionParser;
  final Value<double?> extractionConfidence;
  final Value<double?> valueConfidence;
  final Value<double?> dateConfidence;
  final Value<double?> establishmentConfidence;
  final Value<double?> paymentMethodConfidence;
  final Value<String?> qualityMetadata;
  const ExtractedDataTableCompanion({
    this.id = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.amount = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.establishment = const Value.absent(),
    this.items = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.issuerCnpj = const Value.absent(),
    this.accessKey = const Value.absent(),
    this.urlQrCode = const Value.absent(),
    this.documentNumber = const Value.absent(),
    this.documentSeries = const Value.absent(),
    this.documentState = const Value.absent(),
    this.issuerLegalName = const Value.absent(),
    this.issuerTradeName = const Value.absent(),
    this.fiscalCnaeDescription = const Value.absent(),
    this.issuerCity = const Value.absent(),
    this.issuerState = const Value.absent(),
    this.ocrConfidence = const Value.absent(),
    this.extractionParser = const Value.absent(),
    this.extractionConfidence = const Value.absent(),
    this.valueConfidence = const Value.absent(),
    this.dateConfidence = const Value.absent(),
    this.establishmentConfidence = const Value.absent(),
    this.paymentMethodConfidence = const Value.absent(),
    this.qualityMetadata = const Value.absent(),
  });
  ExtractedDataTableCompanion.insert({
    this.id = const Value.absent(),
    required int receiptId,
    this.amount = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.establishment = const Value.absent(),
    this.items = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.issuerCnpj = const Value.absent(),
    this.accessKey = const Value.absent(),
    this.urlQrCode = const Value.absent(),
    this.documentNumber = const Value.absent(),
    this.documentSeries = const Value.absent(),
    this.documentState = const Value.absent(),
    this.issuerLegalName = const Value.absent(),
    this.issuerTradeName = const Value.absent(),
    this.fiscalCnaeDescription = const Value.absent(),
    this.issuerCity = const Value.absent(),
    this.issuerState = const Value.absent(),
    this.ocrConfidence = const Value.absent(),
    this.extractionParser = const Value.absent(),
    this.extractionConfidence = const Value.absent(),
    this.valueConfidence = const Value.absent(),
    this.dateConfidence = const Value.absent(),
    this.establishmentConfidence = const Value.absent(),
    this.paymentMethodConfidence = const Value.absent(),
    this.qualityMetadata = const Value.absent(),
  }) : receiptId = Value(receiptId);
  static Insertable<ExtractedDataRow> custom({
    Expression<int>? id,
    Expression<int>? receiptId,
    Expression<double>? amount,
    Expression<DateTime>? transactionDate,
    Expression<String>? establishment,
    Expression<String>? items,
    Expression<String>? paymentMethod,
    Expression<String>? issuerCnpj,
    Expression<String>? accessKey,
    Expression<String>? urlQrCode,
    Expression<String>? documentNumber,
    Expression<String>? documentSeries,
    Expression<String>? documentState,
    Expression<String>? issuerLegalName,
    Expression<String>? issuerTradeName,
    Expression<String>? fiscalCnaeDescription,
    Expression<String>? issuerCity,
    Expression<String>? issuerState,
    Expression<double>? ocrConfidence,
    Expression<String>? extractionParser,
    Expression<double>? extractionConfidence,
    Expression<double>? valueConfidence,
    Expression<double>? dateConfidence,
    Expression<double>? establishmentConfidence,
    Expression<double>? paymentMethodConfidence,
    Expression<String>? qualityMetadata,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (receiptId != null) 'receipt_id': receiptId,
      if (amount != null) 'amount': amount,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (establishment != null) 'establishment': establishment,
      if (items != null) 'items': items,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (issuerCnpj != null) 'issuer_cnpj': issuerCnpj,
      if (accessKey != null) 'access_key': accessKey,
      if (urlQrCode != null) 'qr_code_url': urlQrCode,
      if (documentNumber != null) 'document_number': documentNumber,
      if (documentSeries != null) 'document_series': documentSeries,
      if (documentState != null) 'document_state': documentState,
      if (issuerLegalName != null) 'issuer_legal_name': issuerLegalName,
      if (issuerTradeName != null) 'issuer_trade_name': issuerTradeName,
      if (fiscalCnaeDescription != null)
        'fiscal_cnae_description': fiscalCnaeDescription,
      if (issuerCity != null) 'issuer_city': issuerCity,
      if (issuerState != null) 'issuer_state': issuerState,
      if (ocrConfidence != null) 'ocr_confidence': ocrConfidence,
      if (extractionParser != null) 'extraction_parser': extractionParser,
      if (extractionConfidence != null)
        'extraction_confidence': extractionConfidence,
      if (valueConfidence != null) 'value_confidence': valueConfidence,
      if (dateConfidence != null) 'date_confidence': dateConfidence,
      if (establishmentConfidence != null)
        'establishment_confidence': establishmentConfidence,
      if (paymentMethodConfidence != null)
        'payment_method_confidence': paymentMethodConfidence,
      if (qualityMetadata != null) 'quality_metadata': qualityMetadata,
    });
  }

  ExtractedDataTableCompanion copyWith({
    Value<int>? id,
    Value<int>? receiptId,
    Value<double?>? amount,
    Value<DateTime?>? transactionDate,
    Value<String?>? establishment,
    Value<String>? items,
    Value<String?>? paymentMethod,
    Value<String?>? issuerCnpj,
    Value<String?>? accessKey,
    Value<String?>? urlQrCode,
    Value<String?>? documentNumber,
    Value<String?>? documentSeries,
    Value<String?>? documentState,
    Value<String?>? issuerLegalName,
    Value<String?>? issuerTradeName,
    Value<String?>? fiscalCnaeDescription,
    Value<String?>? issuerCity,
    Value<String?>? issuerState,
    Value<double?>? ocrConfidence,
    Value<String?>? extractionParser,
    Value<double?>? extractionConfidence,
    Value<double?>? valueConfidence,
    Value<double?>? dateConfidence,
    Value<double?>? establishmentConfidence,
    Value<double?>? paymentMethodConfidence,
    Value<String?>? qualityMetadata,
  }) {
    return ExtractedDataTableCompanion(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      establishment: establishment ?? this.establishment,
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      issuerCnpj: issuerCnpj ?? this.issuerCnpj,
      accessKey: accessKey ?? this.accessKey,
      urlQrCode: urlQrCode ?? this.urlQrCode,
      documentNumber: documentNumber ?? this.documentNumber,
      documentSeries: documentSeries ?? this.documentSeries,
      documentState: documentState ?? this.documentState,
      issuerLegalName: issuerLegalName ?? this.issuerLegalName,
      issuerTradeName: issuerTradeName ?? this.issuerTradeName,
      fiscalCnaeDescription:
          fiscalCnaeDescription ?? this.fiscalCnaeDescription,
      issuerCity: issuerCity ?? this.issuerCity,
      issuerState: issuerState ?? this.issuerState,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
      extractionParser: extractionParser ?? this.extractionParser,
      extractionConfidence: extractionConfidence ?? this.extractionConfidence,
      valueConfidence: valueConfidence ?? this.valueConfidence,
      dateConfidence: dateConfidence ?? this.dateConfidence,
      establishmentConfidence:
          establishmentConfidence ?? this.establishmentConfidence,
      paymentMethodConfidence:
          paymentMethodConfidence ?? this.paymentMethodConfidence,
      qualityMetadata: qualityMetadata ?? this.qualityMetadata,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<int>(receiptId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<DateTime>(transactionDate.value);
    }
    if (establishment.present) {
      map['establishment'] = Variable<String>(establishment.value);
    }
    if (items.present) {
      map['items'] = Variable<String>(items.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (issuerCnpj.present) {
      map['issuer_cnpj'] = Variable<String>(issuerCnpj.value);
    }
    if (accessKey.present) {
      map['access_key'] = Variable<String>(accessKey.value);
    }
    if (urlQrCode.present) {
      map['qr_code_url'] = Variable<String>(urlQrCode.value);
    }
    if (documentNumber.present) {
      map['document_number'] = Variable<String>(documentNumber.value);
    }
    if (documentSeries.present) {
      map['document_series'] = Variable<String>(documentSeries.value);
    }
    if (documentState.present) {
      map['document_state'] = Variable<String>(documentState.value);
    }
    if (issuerLegalName.present) {
      map['issuer_legal_name'] = Variable<String>(issuerLegalName.value);
    }
    if (issuerTradeName.present) {
      map['issuer_trade_name'] = Variable<String>(issuerTradeName.value);
    }
    if (fiscalCnaeDescription.present) {
      map['fiscal_cnae_description'] = Variable<String>(
        fiscalCnaeDescription.value,
      );
    }
    if (issuerCity.present) {
      map['issuer_city'] = Variable<String>(issuerCity.value);
    }
    if (issuerState.present) {
      map['issuer_state'] = Variable<String>(issuerState.value);
    }
    if (ocrConfidence.present) {
      map['ocr_confidence'] = Variable<double>(ocrConfidence.value);
    }
    if (extractionParser.present) {
      map['extraction_parser'] = Variable<String>(extractionParser.value);
    }
    if (extractionConfidence.present) {
      map['extraction_confidence'] = Variable<double>(
        extractionConfidence.value,
      );
    }
    if (valueConfidence.present) {
      map['value_confidence'] = Variable<double>(valueConfidence.value);
    }
    if (dateConfidence.present) {
      map['date_confidence'] = Variable<double>(dateConfidence.value);
    }
    if (establishmentConfidence.present) {
      map['establishment_confidence'] = Variable<double>(
        establishmentConfidence.value,
      );
    }
    if (paymentMethodConfidence.present) {
      map['payment_method_confidence'] = Variable<double>(
        paymentMethodConfidence.value,
      );
    }
    if (qualityMetadata.present) {
      map['quality_metadata'] = Variable<String>(qualityMetadata.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExtractedDataTableCompanion(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('amount: $amount, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('establishment: $establishment, ')
          ..write('items: $items, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('issuerCnpj: $issuerCnpj, ')
          ..write('accessKey: $accessKey, ')
          ..write('urlQrCode: $urlQrCode, ')
          ..write('documentNumber: $documentNumber, ')
          ..write('documentSeries: $documentSeries, ')
          ..write('documentState: $documentState, ')
          ..write('issuerLegalName: $issuerLegalName, ')
          ..write('issuerTradeName: $issuerTradeName, ')
          ..write('fiscalCnaeDescription: $fiscalCnaeDescription, ')
          ..write('issuerCity: $issuerCity, ')
          ..write('issuerState: $issuerState, ')
          ..write('ocrConfidence: $ocrConfidence, ')
          ..write('extractionParser: $extractionParser, ')
          ..write('extractionConfidence: $extractionConfidence, ')
          ..write('valueConfidence: $valueConfidence, ')
          ..write('dateConfidence: $dateConfidence, ')
          ..write('establishmentConfidence: $establishmentConfidence, ')
          ..write('paymentMethodConfidence: $paymentMethodConfidence, ')
          ..write('qualityMetadata: $qualityMetadata')
          ..write(')'))
        .toString();
  }
}

class $EmbeddingsTable extends Embeddings
    with TableInfo<$EmbeddingsTable, EmbeddingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmbeddingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<int> receiptId = GeneratedColumn<int>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES receipt (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _vectorMeta = const VerificationMeta('vector');
  @override
  late final GeneratedColumn<Uint8List> vector = GeneratedColumn<Uint8List>(
    'vector',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dimensionMeta = const VerificationMeta(
    'dimension',
  );
  @override
  late final GeneratedColumn<int> dimension = GeneratedColumn<int>(
    'dimension',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _generatedAtMeta = const VerificationMeta(
    'generatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
    'generated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    receiptId,
    vector,
    model,
    dimension,
    generatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'embedding';
  @override
  VerificationContext validateIntegrity(
    Insertable<EmbeddingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('vector')) {
      context.handle(
        _vectorMeta,
        vector.isAcceptableOrUnknown(data['vector']!, _vectorMeta),
      );
    } else if (isInserting) {
      context.missing(_vectorMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('dimension')) {
      context.handle(
        _dimensionMeta,
        dimension.isAcceptableOrUnknown(data['dimension']!, _dimensionMeta),
      );
    } else if (isInserting) {
      context.missing(_dimensionMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
        _generatedAtMeta,
        generatedAt.isAcceptableOrUnknown(
          data['generated_at']!,
          _generatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmbeddingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmbeddingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receipt_id'],
      )!,
      vector: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}vector'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      dimension: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dimension'],
      )!,
      generatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}generated_at'],
      )!,
    );
  }

  @override
  $EmbeddingsTable createAlias(String alias) {
    return $EmbeddingsTable(attachedDatabase, alias);
  }
}

class EmbeddingRow extends DataClass implements Insertable<EmbeddingRow> {
  final int id;
  final int receiptId;
  final Uint8List vector;
  final String model;
  final int dimension;
  final DateTime generatedAt;
  const EmbeddingRow({
    required this.id,
    required this.receiptId,
    required this.vector,
    required this.model,
    required this.dimension,
    required this.generatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['receipt_id'] = Variable<int>(receiptId);
    map['vector'] = Variable<Uint8List>(vector);
    map['model'] = Variable<String>(model);
    map['dimension'] = Variable<int>(dimension);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    return map;
  }

  EmbeddingsCompanion toCompanion(bool nullToAbsent) {
    return EmbeddingsCompanion(
      id: Value(id),
      receiptId: Value(receiptId),
      vector: Value(vector),
      model: Value(model),
      dimension: Value(dimension),
      generatedAt: Value(generatedAt),
    );
  }

  factory EmbeddingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmbeddingRow(
      id: serializer.fromJson<int>(json['id']),
      receiptId: serializer.fromJson<int>(json['receiptId']),
      vector: serializer.fromJson<Uint8List>(json['vector']),
      model: serializer.fromJson<String>(json['model']),
      dimension: serializer.fromJson<int>(json['dimension']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'receiptId': serializer.toJson<int>(receiptId),
      'vector': serializer.toJson<Uint8List>(vector),
      'model': serializer.toJson<String>(model),
      'dimension': serializer.toJson<int>(dimension),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
    };
  }

  EmbeddingRow copyWith({
    int? id,
    int? receiptId,
    Uint8List? vector,
    String? model,
    int? dimension,
    DateTime? generatedAt,
  }) => EmbeddingRow(
    id: id ?? this.id,
    receiptId: receiptId ?? this.receiptId,
    vector: vector ?? this.vector,
    model: model ?? this.model,
    dimension: dimension ?? this.dimension,
    generatedAt: generatedAt ?? this.generatedAt,
  );
  EmbeddingRow copyWithCompanion(EmbeddingsCompanion data) {
    return EmbeddingRow(
      id: data.id.present ? data.id.value : this.id,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      vector: data.vector.present ? data.vector.value : this.vector,
      model: data.model.present ? data.model.value : this.model,
      dimension: data.dimension.present ? data.dimension.value : this.dimension,
      generatedAt: data.generatedAt.present
          ? data.generatedAt.value
          : this.generatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmbeddingRow(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('vector: $vector, ')
          ..write('model: $model, ')
          ..write('dimension: $dimension, ')
          ..write('generatedAt: $generatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    receiptId,
    $driftBlobEquality.hash(vector),
    model,
    dimension,
    generatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmbeddingRow &&
          other.id == this.id &&
          other.receiptId == this.receiptId &&
          $driftBlobEquality.equals(other.vector, this.vector) &&
          other.model == this.model &&
          other.dimension == this.dimension &&
          other.generatedAt == this.generatedAt);
}

class EmbeddingsCompanion extends UpdateCompanion<EmbeddingRow> {
  final Value<int> id;
  final Value<int> receiptId;
  final Value<Uint8List> vector;
  final Value<String> model;
  final Value<int> dimension;
  final Value<DateTime> generatedAt;
  const EmbeddingsCompanion({
    this.id = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.vector = const Value.absent(),
    this.model = const Value.absent(),
    this.dimension = const Value.absent(),
    this.generatedAt = const Value.absent(),
  });
  EmbeddingsCompanion.insert({
    this.id = const Value.absent(),
    required int receiptId,
    required Uint8List vector,
    required String model,
    required int dimension,
    required DateTime generatedAt,
  }) : receiptId = Value(receiptId),
       vector = Value(vector),
       model = Value(model),
       dimension = Value(dimension),
       generatedAt = Value(generatedAt);
  static Insertable<EmbeddingRow> custom({
    Expression<int>? id,
    Expression<int>? receiptId,
    Expression<Uint8List>? vector,
    Expression<String>? model,
    Expression<int>? dimension,
    Expression<DateTime>? generatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (receiptId != null) 'receipt_id': receiptId,
      if (vector != null) 'vector': vector,
      if (model != null) 'model': model,
      if (dimension != null) 'dimension': dimension,
      if (generatedAt != null) 'generated_at': generatedAt,
    });
  }

  EmbeddingsCompanion copyWith({
    Value<int>? id,
    Value<int>? receiptId,
    Value<Uint8List>? vector,
    Value<String>? model,
    Value<int>? dimension,
    Value<DateTime>? generatedAt,
  }) {
    return EmbeddingsCompanion(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      vector: vector ?? this.vector,
      model: model ?? this.model,
      dimension: dimension ?? this.dimension,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<int>(receiptId.value);
    }
    if (vector.present) {
      map['vector'] = Variable<Uint8List>(vector.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (dimension.present) {
      map['dimension'] = Variable<int>(dimension.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmbeddingsCompanion(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('vector: $vector, ')
          ..write('model: $model, ')
          ..write('dimension: $dimension, ')
          ..write('generatedAt: $generatedAt')
          ..write(')'))
        .toString();
  }
}

class $CnpjCacheTable extends CnpjCache
    with TableInfo<$CnpjCacheTable, CnpjCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CnpjCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cnpjMeta = const VerificationMeta('cnpj');
  @override
  late final GeneratedColumn<String> cnpj = GeneratedColumn<String>(
    'cnpj',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _legalNameMeta = const VerificationMeta(
    'legalName',
  );
  @override
  late final GeneratedColumn<String> legalName = GeneratedColumn<String>(
    'legal_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tradeNameMeta = const VerificationMeta(
    'tradeName',
  );
  @override
  late final GeneratedColumn<String> tradeName = GeneratedColumn<String>(
    'trade_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confirmedNameMeta = const VerificationMeta(
    'confirmedName',
  );
  @override
  late final GeneratedColumn<String> confirmedName = GeneratedColumn<String>(
    'confirmed_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fiscalCnaeDescriptionMeta =
      const VerificationMeta('fiscalCnaeDescription');
  @override
  late final GeneratedColumn<String> fiscalCnaeDescription =
      GeneratedColumn<String>(
        'fiscal_cnae_description',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preferredCategoryIdMeta =
      const VerificationMeta('preferredCategoryId');
  @override
  late final GeneratedColumn<int> preferredCategoryId = GeneratedColumn<int>(
    'preferred_category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES category (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cnpj,
    legalName,
    tradeName,
    confirmedName,
    fiscalCnaeDescription,
    city,
    state,
    preferredCategoryId,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cnpj_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<CnpjCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cnpj')) {
      context.handle(
        _cnpjMeta,
        cnpj.isAcceptableOrUnknown(data['cnpj']!, _cnpjMeta),
      );
    } else if (isInserting) {
      context.missing(_cnpjMeta);
    }
    if (data.containsKey('legal_name')) {
      context.handle(
        _legalNameMeta,
        legalName.isAcceptableOrUnknown(data['legal_name']!, _legalNameMeta),
      );
    }
    if (data.containsKey('trade_name')) {
      context.handle(
        _tradeNameMeta,
        tradeName.isAcceptableOrUnknown(data['trade_name']!, _tradeNameMeta),
      );
    }
    if (data.containsKey('confirmed_name')) {
      context.handle(
        _confirmedNameMeta,
        confirmedName.isAcceptableOrUnknown(
          data['confirmed_name']!,
          _confirmedNameMeta,
        ),
      );
    }
    if (data.containsKey('fiscal_cnae_description')) {
      context.handle(
        _fiscalCnaeDescriptionMeta,
        fiscalCnaeDescription.isAcceptableOrUnknown(
          data['fiscal_cnae_description']!,
          _fiscalCnaeDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('preferred_category_id')) {
      context.handle(
        _preferredCategoryIdMeta,
        preferredCategoryId.isAcceptableOrUnknown(
          data['preferred_category_id']!,
          _preferredCategoryIdMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cnpj};
  @override
  CnpjCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CnpjCacheRow(
      cnpj: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cnpj'],
      )!,
      legalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legal_name'],
      ),
      tradeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trade_name'],
      ),
      confirmedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confirmed_name'],
      ),
      fiscalCnaeDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fiscal_cnae_description'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      ),
      preferredCategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}preferred_category_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CnpjCacheTable createAlias(String alias) {
    return $CnpjCacheTable(attachedDatabase, alias);
  }
}

class CnpjCacheRow extends DataClass implements Insertable<CnpjCacheRow> {
  final String cnpj;
  final String? legalName;
  final String? tradeName;
  final String? confirmedName;
  final String? fiscalCnaeDescription;
  final String? city;
  final String? state;
  final int? preferredCategoryId;
  final DateTime updatedAt;
  const CnpjCacheRow({
    required this.cnpj,
    this.legalName,
    this.tradeName,
    this.confirmedName,
    this.fiscalCnaeDescription,
    this.city,
    this.state,
    this.preferredCategoryId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cnpj'] = Variable<String>(cnpj);
    if (!nullToAbsent || legalName != null) {
      map['legal_name'] = Variable<String>(legalName);
    }
    if (!nullToAbsent || tradeName != null) {
      map['trade_name'] = Variable<String>(tradeName);
    }
    if (!nullToAbsent || confirmedName != null) {
      map['confirmed_name'] = Variable<String>(confirmedName);
    }
    if (!nullToAbsent || fiscalCnaeDescription != null) {
      map['fiscal_cnae_description'] = Variable<String>(fiscalCnaeDescription);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    if (!nullToAbsent || state != null) {
      map['state'] = Variable<String>(state);
    }
    if (!nullToAbsent || preferredCategoryId != null) {
      map['preferred_category_id'] = Variable<int>(preferredCategoryId);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CnpjCacheCompanion toCompanion(bool nullToAbsent) {
    return CnpjCacheCompanion(
      cnpj: Value(cnpj),
      legalName: legalName == null && nullToAbsent
          ? const Value.absent()
          : Value(legalName),
      tradeName: tradeName == null && nullToAbsent
          ? const Value.absent()
          : Value(tradeName),
      confirmedName: confirmedName == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedName),
      fiscalCnaeDescription: fiscalCnaeDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(fiscalCnaeDescription),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      state: state == null && nullToAbsent
          ? const Value.absent()
          : Value(state),
      preferredCategoryId: preferredCategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredCategoryId),
      updatedAt: Value(updatedAt),
    );
  }

  factory CnpjCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CnpjCacheRow(
      cnpj: serializer.fromJson<String>(json['cnpj']),
      legalName: serializer.fromJson<String?>(json['legalName']),
      tradeName: serializer.fromJson<String?>(json['tradeName']),
      confirmedName: serializer.fromJson<String?>(json['confirmedName']),
      fiscalCnaeDescription: serializer.fromJson<String?>(
        json['fiscalCnaeDescription'],
      ),
      city: serializer.fromJson<String?>(json['city']),
      state: serializer.fromJson<String?>(json['state']),
      preferredCategoryId: serializer.fromJson<int?>(
        json['preferredCategoryId'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cnpj': serializer.toJson<String>(cnpj),
      'legalName': serializer.toJson<String?>(legalName),
      'tradeName': serializer.toJson<String?>(tradeName),
      'confirmedName': serializer.toJson<String?>(confirmedName),
      'fiscalCnaeDescription': serializer.toJson<String?>(
        fiscalCnaeDescription,
      ),
      'city': serializer.toJson<String?>(city),
      'state': serializer.toJson<String?>(state),
      'preferredCategoryId': serializer.toJson<int?>(preferredCategoryId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CnpjCacheRow copyWith({
    String? cnpj,
    Value<String?> legalName = const Value.absent(),
    Value<String?> tradeName = const Value.absent(),
    Value<String?> confirmedName = const Value.absent(),
    Value<String?> fiscalCnaeDescription = const Value.absent(),
    Value<String?> city = const Value.absent(),
    Value<String?> state = const Value.absent(),
    Value<int?> preferredCategoryId = const Value.absent(),
    DateTime? updatedAt,
  }) => CnpjCacheRow(
    cnpj: cnpj ?? this.cnpj,
    legalName: legalName.present ? legalName.value : this.legalName,
    tradeName: tradeName.present ? tradeName.value : this.tradeName,
    confirmedName: confirmedName.present
        ? confirmedName.value
        : this.confirmedName,
    fiscalCnaeDescription: fiscalCnaeDescription.present
        ? fiscalCnaeDescription.value
        : this.fiscalCnaeDescription,
    city: city.present ? city.value : this.city,
    state: state.present ? state.value : this.state,
    preferredCategoryId: preferredCategoryId.present
        ? preferredCategoryId.value
        : this.preferredCategoryId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CnpjCacheRow copyWithCompanion(CnpjCacheCompanion data) {
    return CnpjCacheRow(
      cnpj: data.cnpj.present ? data.cnpj.value : this.cnpj,
      legalName: data.legalName.present ? data.legalName.value : this.legalName,
      tradeName: data.tradeName.present ? data.tradeName.value : this.tradeName,
      confirmedName: data.confirmedName.present
          ? data.confirmedName.value
          : this.confirmedName,
      fiscalCnaeDescription: data.fiscalCnaeDescription.present
          ? data.fiscalCnaeDescription.value
          : this.fiscalCnaeDescription,
      city: data.city.present ? data.city.value : this.city,
      state: data.state.present ? data.state.value : this.state,
      preferredCategoryId: data.preferredCategoryId.present
          ? data.preferredCategoryId.value
          : this.preferredCategoryId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CnpjCacheRow(')
          ..write('cnpj: $cnpj, ')
          ..write('legalName: $legalName, ')
          ..write('tradeName: $tradeName, ')
          ..write('confirmedName: $confirmedName, ')
          ..write('fiscalCnaeDescription: $fiscalCnaeDescription, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('preferredCategoryId: $preferredCategoryId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cnpj,
    legalName,
    tradeName,
    confirmedName,
    fiscalCnaeDescription,
    city,
    state,
    preferredCategoryId,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CnpjCacheRow &&
          other.cnpj == this.cnpj &&
          other.legalName == this.legalName &&
          other.tradeName == this.tradeName &&
          other.confirmedName == this.confirmedName &&
          other.fiscalCnaeDescription == this.fiscalCnaeDescription &&
          other.city == this.city &&
          other.state == this.state &&
          other.preferredCategoryId == this.preferredCategoryId &&
          other.updatedAt == this.updatedAt);
}

class CnpjCacheCompanion extends UpdateCompanion<CnpjCacheRow> {
  final Value<String> cnpj;
  final Value<String?> legalName;
  final Value<String?> tradeName;
  final Value<String?> confirmedName;
  final Value<String?> fiscalCnaeDescription;
  final Value<String?> city;
  final Value<String?> state;
  final Value<int?> preferredCategoryId;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CnpjCacheCompanion({
    this.cnpj = const Value.absent(),
    this.legalName = const Value.absent(),
    this.tradeName = const Value.absent(),
    this.confirmedName = const Value.absent(),
    this.fiscalCnaeDescription = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.preferredCategoryId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CnpjCacheCompanion.insert({
    required String cnpj,
    this.legalName = const Value.absent(),
    this.tradeName = const Value.absent(),
    this.confirmedName = const Value.absent(),
    this.fiscalCnaeDescription = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.preferredCategoryId = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : cnpj = Value(cnpj),
       updatedAt = Value(updatedAt);
  static Insertable<CnpjCacheRow> custom({
    Expression<String>? cnpj,
    Expression<String>? legalName,
    Expression<String>? tradeName,
    Expression<String>? confirmedName,
    Expression<String>? fiscalCnaeDescription,
    Expression<String>? city,
    Expression<String>? state,
    Expression<int>? preferredCategoryId,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cnpj != null) 'cnpj': cnpj,
      if (legalName != null) 'legal_name': legalName,
      if (tradeName != null) 'trade_name': tradeName,
      if (confirmedName != null) 'confirmed_name': confirmedName,
      if (fiscalCnaeDescription != null)
        'fiscal_cnae_description': fiscalCnaeDescription,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (preferredCategoryId != null)
        'preferred_category_id': preferredCategoryId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CnpjCacheCompanion copyWith({
    Value<String>? cnpj,
    Value<String?>? legalName,
    Value<String?>? tradeName,
    Value<String?>? confirmedName,
    Value<String?>? fiscalCnaeDescription,
    Value<String?>? city,
    Value<String?>? state,
    Value<int?>? preferredCategoryId,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CnpjCacheCompanion(
      cnpj: cnpj ?? this.cnpj,
      legalName: legalName ?? this.legalName,
      tradeName: tradeName ?? this.tradeName,
      confirmedName: confirmedName ?? this.confirmedName,
      fiscalCnaeDescription:
          fiscalCnaeDescription ?? this.fiscalCnaeDescription,
      city: city ?? this.city,
      state: state ?? this.state,
      preferredCategoryId: preferredCategoryId ?? this.preferredCategoryId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cnpj.present) {
      map['cnpj'] = Variable<String>(cnpj.value);
    }
    if (legalName.present) {
      map['legal_name'] = Variable<String>(legalName.value);
    }
    if (tradeName.present) {
      map['trade_name'] = Variable<String>(tradeName.value);
    }
    if (confirmedName.present) {
      map['confirmed_name'] = Variable<String>(confirmedName.value);
    }
    if (fiscalCnaeDescription.present) {
      map['fiscal_cnae_description'] = Variable<String>(
        fiscalCnaeDescription.value,
      );
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (preferredCategoryId.present) {
      map['preferred_category_id'] = Variable<int>(preferredCategoryId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CnpjCacheCompanion(')
          ..write('cnpj: $cnpj, ')
          ..write('legalName: $legalName, ')
          ..write('tradeName: $tradeName, ')
          ..write('confirmedName: $confirmedName, ')
          ..write('fiscalCnaeDescription: $fiscalCnaeDescription, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('preferredCategoryId: $preferredCategoryId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EstablishmentCategoryCacheTable extends EstablishmentCategoryCache
    with
        TableInfo<
          $EstablishmentCategoryCacheTable,
          EstablishmentCategoryCacheRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EstablishmentCategoryCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _establishmentKeyMeta = const VerificationMeta(
    'establishmentKey',
  );
  @override
  late final GeneratedColumn<String> establishmentKey = GeneratedColumn<String>(
    'establishment_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _establishmentMeta = const VerificationMeta(
    'establishment',
  );
  @override
  late final GeneratedColumn<String> establishment = GeneratedColumn<String>(
    'establishment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES category (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    establishmentKey,
    establishment,
    categoryId,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'establishment_category_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<EstablishmentCategoryCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('establishment_key')) {
      context.handle(
        _establishmentKeyMeta,
        establishmentKey.isAcceptableOrUnknown(
          data['establishment_key']!,
          _establishmentKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_establishmentKeyMeta);
    }
    if (data.containsKey('establishment')) {
      context.handle(
        _establishmentMeta,
        establishment.isAcceptableOrUnknown(
          data['establishment']!,
          _establishmentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_establishmentMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {establishmentKey};
  @override
  EstablishmentCategoryCacheRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EstablishmentCategoryCacheRow(
      establishmentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}establishment_key'],
      )!,
      establishment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}establishment'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EstablishmentCategoryCacheTable createAlias(String alias) {
    return $EstablishmentCategoryCacheTable(attachedDatabase, alias);
  }
}

class EstablishmentCategoryCacheRow extends DataClass
    implements Insertable<EstablishmentCategoryCacheRow> {
  final String establishmentKey;
  final String establishment;
  final int categoryId;
  final DateTime updatedAt;
  const EstablishmentCategoryCacheRow({
    required this.establishmentKey,
    required this.establishment,
    required this.categoryId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['establishment_key'] = Variable<String>(establishmentKey);
    map['establishment'] = Variable<String>(establishment);
    map['category_id'] = Variable<int>(categoryId);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EstablishmentCategoryCacheCompanion toCompanion(bool nullToAbsent) {
    return EstablishmentCategoryCacheCompanion(
      establishmentKey: Value(establishmentKey),
      establishment: Value(establishment),
      categoryId: Value(categoryId),
      updatedAt: Value(updatedAt),
    );
  }

  factory EstablishmentCategoryCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EstablishmentCategoryCacheRow(
      establishmentKey: serializer.fromJson<String>(json['establishmentKey']),
      establishment: serializer.fromJson<String>(json['establishment']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'establishmentKey': serializer.toJson<String>(establishmentKey),
      'establishment': serializer.toJson<String>(establishment),
      'categoryId': serializer.toJson<int>(categoryId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EstablishmentCategoryCacheRow copyWith({
    String? establishmentKey,
    String? establishment,
    int? categoryId,
    DateTime? updatedAt,
  }) => EstablishmentCategoryCacheRow(
    establishmentKey: establishmentKey ?? this.establishmentKey,
    establishment: establishment ?? this.establishment,
    categoryId: categoryId ?? this.categoryId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EstablishmentCategoryCacheRow copyWithCompanion(
    EstablishmentCategoryCacheCompanion data,
  ) {
    return EstablishmentCategoryCacheRow(
      establishmentKey: data.establishmentKey.present
          ? data.establishmentKey.value
          : this.establishmentKey,
      establishment: data.establishment.present
          ? data.establishment.value
          : this.establishment,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EstablishmentCategoryCacheRow(')
          ..write('establishmentKey: $establishmentKey, ')
          ..write('establishment: $establishment, ')
          ..write('categoryId: $categoryId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(establishmentKey, establishment, categoryId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EstablishmentCategoryCacheRow &&
          other.establishmentKey == this.establishmentKey &&
          other.establishment == this.establishment &&
          other.categoryId == this.categoryId &&
          other.updatedAt == this.updatedAt);
}

class EstablishmentCategoryCacheCompanion
    extends UpdateCompanion<EstablishmentCategoryCacheRow> {
  final Value<String> establishmentKey;
  final Value<String> establishment;
  final Value<int> categoryId;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EstablishmentCategoryCacheCompanion({
    this.establishmentKey = const Value.absent(),
    this.establishment = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EstablishmentCategoryCacheCompanion.insert({
    required String establishmentKey,
    required String establishment,
    required int categoryId,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : establishmentKey = Value(establishmentKey),
       establishment = Value(establishment),
       categoryId = Value(categoryId),
       updatedAt = Value(updatedAt);
  static Insertable<EstablishmentCategoryCacheRow> custom({
    Expression<String>? establishmentKey,
    Expression<String>? establishment,
    Expression<int>? categoryId,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (establishmentKey != null) 'establishment_key': establishmentKey,
      if (establishment != null) 'establishment': establishment,
      if (categoryId != null) 'category_id': categoryId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EstablishmentCategoryCacheCompanion copyWith({
    Value<String>? establishmentKey,
    Value<String>? establishment,
    Value<int>? categoryId,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EstablishmentCategoryCacheCompanion(
      establishmentKey: establishmentKey ?? this.establishmentKey,
      establishment: establishment ?? this.establishment,
      categoryId: categoryId ?? this.categoryId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (establishmentKey.present) {
      map['establishment_key'] = Variable<String>(establishmentKey.value);
    }
    if (establishment.present) {
      map['establishment'] = Variable<String>(establishment.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EstablishmentCategoryCacheCompanion(')
          ..write('establishmentKey: $establishmentKey, ')
          ..write('establishment: $establishment, ')
          ..write('categoryId: $categoryId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemCategoryCacheTable extends ItemCategoryCache
    with TableInfo<$ItemCategoryCacheTable, ItemCategoryCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemCategoryCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemKeyMeta = const VerificationMeta(
    'itemKey',
  );
  @override
  late final GeneratedColumn<String> itemKey = GeneratedColumn<String>(
    'item_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemMeta = const VerificationMeta('item');
  @override
  late final GeneratedColumn<String> item = GeneratedColumn<String>(
    'item',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES category (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _occurrencesMeta = const VerificationMeta(
    'occurrences',
  );
  @override
  late final GeneratedColumn<int> occurrences = GeneratedColumn<int>(
    'occurrences',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    itemKey,
    item,
    categoryId,
    occurrences,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_category_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemCategoryCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_key')) {
      context.handle(
        _itemKeyMeta,
        itemKey.isAcceptableOrUnknown(data['item_key']!, _itemKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_itemKeyMeta);
    }
    if (data.containsKey('item')) {
      context.handle(
        _itemMeta,
        item.isAcceptableOrUnknown(data['item']!, _itemMeta),
      );
    } else if (isInserting) {
      context.missing(_itemMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('occurrences')) {
      context.handle(
        _occurrencesMeta,
        occurrences.isAcceptableOrUnknown(
          data['occurrences']!,
          _occurrencesMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemKey, categoryId};
  @override
  ItemCategoryCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemCategoryCacheRow(
      itemKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_key'],
      )!,
      item: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      occurrences: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurrences'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ItemCategoryCacheTable createAlias(String alias) {
    return $ItemCategoryCacheTable(attachedDatabase, alias);
  }
}

class ItemCategoryCacheRow extends DataClass
    implements Insertable<ItemCategoryCacheRow> {
  final String itemKey;
  final String item;
  final int categoryId;
  final int occurrences;
  final DateTime updatedAt;
  const ItemCategoryCacheRow({
    required this.itemKey,
    required this.item,
    required this.categoryId,
    required this.occurrences,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_key'] = Variable<String>(itemKey);
    map['item'] = Variable<String>(item);
    map['category_id'] = Variable<int>(categoryId);
    map['occurrences'] = Variable<int>(occurrences);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ItemCategoryCacheCompanion toCompanion(bool nullToAbsent) {
    return ItemCategoryCacheCompanion(
      itemKey: Value(itemKey),
      item: Value(item),
      categoryId: Value(categoryId),
      occurrences: Value(occurrences),
      updatedAt: Value(updatedAt),
    );
  }

  factory ItemCategoryCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemCategoryCacheRow(
      itemKey: serializer.fromJson<String>(json['itemKey']),
      item: serializer.fromJson<String>(json['item']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      occurrences: serializer.fromJson<int>(json['occurrences']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemKey': serializer.toJson<String>(itemKey),
      'item': serializer.toJson<String>(item),
      'categoryId': serializer.toJson<int>(categoryId),
      'occurrences': serializer.toJson<int>(occurrences),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ItemCategoryCacheRow copyWith({
    String? itemKey,
    String? item,
    int? categoryId,
    int? occurrences,
    DateTime? updatedAt,
  }) => ItemCategoryCacheRow(
    itemKey: itemKey ?? this.itemKey,
    item: item ?? this.item,
    categoryId: categoryId ?? this.categoryId,
    occurrences: occurrences ?? this.occurrences,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ItemCategoryCacheRow copyWithCompanion(ItemCategoryCacheCompanion data) {
    return ItemCategoryCacheRow(
      itemKey: data.itemKey.present ? data.itemKey.value : this.itemKey,
      item: data.item.present ? data.item.value : this.item,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      occurrences: data.occurrences.present
          ? data.occurrences.value
          : this.occurrences,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemCategoryCacheRow(')
          ..write('itemKey: $itemKey, ')
          ..write('item: $item, ')
          ..write('categoryId: $categoryId, ')
          ..write('occurrences: $occurrences, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(itemKey, item, categoryId, occurrences, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemCategoryCacheRow &&
          other.itemKey == this.itemKey &&
          other.item == this.item &&
          other.categoryId == this.categoryId &&
          other.occurrences == this.occurrences &&
          other.updatedAt == this.updatedAt);
}

class ItemCategoryCacheCompanion extends UpdateCompanion<ItemCategoryCacheRow> {
  final Value<String> itemKey;
  final Value<String> item;
  final Value<int> categoryId;
  final Value<int> occurrences;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ItemCategoryCacheCompanion({
    this.itemKey = const Value.absent(),
    this.item = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.occurrences = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemCategoryCacheCompanion.insert({
    required String itemKey,
    required String item,
    required int categoryId,
    this.occurrences = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : itemKey = Value(itemKey),
       item = Value(item),
       categoryId = Value(categoryId),
       updatedAt = Value(updatedAt);
  static Insertable<ItemCategoryCacheRow> custom({
    Expression<String>? itemKey,
    Expression<String>? item,
    Expression<int>? categoryId,
    Expression<int>? occurrences,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemKey != null) 'item_key': itemKey,
      if (item != null) 'item': item,
      if (categoryId != null) 'category_id': categoryId,
      if (occurrences != null) 'occurrences': occurrences,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemCategoryCacheCompanion copyWith({
    Value<String>? itemKey,
    Value<String>? item,
    Value<int>? categoryId,
    Value<int>? occurrences,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ItemCategoryCacheCompanion(
      itemKey: itemKey ?? this.itemKey,
      item: item ?? this.item,
      categoryId: categoryId ?? this.categoryId,
      occurrences: occurrences ?? this.occurrences,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemKey.present) {
      map['item_key'] = Variable<String>(itemKey.value);
    }
    if (item.present) {
      map['item'] = Variable<String>(item.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (occurrences.present) {
      map['occurrences'] = Variable<int>(occurrences.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemCategoryCacheCompanion(')
          ..write('itemKey: $itemKey, ')
          ..write('item: $item, ')
          ..write('categoryId: $categoryId, ')
          ..write('occurrences: $occurrences, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConfigurationsTable extends Configurations
    with TableInfo<$ConfigurationsTable, ConfigurationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConfigurationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _localAuthEnabledMeta = const VerificationMeta(
    'localAuthEnabled',
  );
  @override
  late final GeneratedColumn<bool> localAuthEnabled = GeneratedColumn<bool>(
    'local_auth_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("local_auth_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _authenticationTypeMeta =
      const VerificationMeta('authenticationType');
  @override
  late final GeneratedColumn<String> authenticationType =
      GeneratedColumn<String>(
        'authentication_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _autoLockIntervalMinutesMeta =
      const VerificationMeta('autoLockIntervalMinutes');
  @override
  late final GeneratedColumn<int> autoLockIntervalMinutes =
      GeneratedColumn<int>(
        'auto_lock_interval_minutes',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(Configuration.defaultAutoLockIntervalMinutes),
      );
  static const VerificationMeta _cloudProviderMeta = const VerificationMeta(
    'cloudProvider',
  );
  @override
  late final GeneratedColumn<String> cloudProvider = GeneratedColumn<String>(
    'cloud_provider',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedCloudAccountMeta =
      const VerificationMeta('linkedCloudAccount');
  @override
  late final GeneratedColumn<String> linkedCloudAccount =
      GeneratedColumn<String>(
        'linked_cloud_account',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _cloudTokenValidMeta = const VerificationMeta(
    'cloudTokenValid',
  );
  @override
  late final GeneratedColumn<bool> cloudTokenValid = GeneratedColumn<bool>(
    'cloud_token_valid',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cloud_token_valid" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cloudLinkedAtMeta = const VerificationMeta(
    'cloudLinkedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cloudLinkedAt =
      GeneratedColumn<DateTime>(
        'cloud_linked_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _backupReminderEnabledMeta =
      const VerificationMeta('backupReminderEnabled');
  @override
  late final GeneratedColumn<bool> backupReminderEnabled =
      GeneratedColumn<bool>(
        'backup_reminder_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("backup_reminder_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _reminderIntervalDaysMeta =
      const VerificationMeta('reminderIntervalDays');
  @override
  late final GeneratedColumn<int> reminderIntervalDays = GeneratedColumn<int>(
    'reminder_interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(7),
  );
  static const VerificationMeta _storageLimitMbMeta = const VerificationMeta(
    'storageLimitMb',
  );
  @override
  late final GeneratedColumn<int> storageLimitMb = GeneratedColumn<int>(
    'storage_limit_mb',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(500),
  );
  static const VerificationMeta _onboardingCompletedMeta =
      const VerificationMeta('onboardingCompleted');
  @override
  late final GeneratedColumn<bool> onboardingCompleted = GeneratedColumn<bool>(
    'onboarding_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastSyncedExportAtMeta =
      const VerificationMeta('lastSyncedExportAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedExportAt =
      GeneratedColumn<DateTime>(
        'last_synced_export_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _backupAvailabilityMeta =
      const VerificationMeta('backupAvailability');
  @override
  late final GeneratedColumn<String> backupAvailability =
      GeneratedColumn<String>(
        'backup_availability',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('INATIVO'),
      );
  static const VerificationMeta _visualThemeModeMeta = const VerificationMeta(
    'visualThemeMode',
  );
  @override
  late final GeneratedColumn<String> visualThemeMode = GeneratedColumn<String>(
    'visual_theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ESCURO'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localAuthEnabled,
    authenticationType,
    autoLockIntervalMinutes,
    cloudProvider,
    linkedCloudAccount,
    cloudTokenValid,
    cloudLinkedAt,
    backupReminderEnabled,
    reminderIntervalDays,
    storageLimitMb,
    onboardingCompleted,
    lastSyncedExportAt,
    backupAvailability,
    visualThemeMode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'configuration';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConfigurationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_auth_enabled')) {
      context.handle(
        _localAuthEnabledMeta,
        localAuthEnabled.isAcceptableOrUnknown(
          data['local_auth_enabled']!,
          _localAuthEnabledMeta,
        ),
      );
    }
    if (data.containsKey('authentication_type')) {
      context.handle(
        _authenticationTypeMeta,
        authenticationType.isAcceptableOrUnknown(
          data['authentication_type']!,
          _authenticationTypeMeta,
        ),
      );
    }
    if (data.containsKey('auto_lock_interval_minutes')) {
      context.handle(
        _autoLockIntervalMinutesMeta,
        autoLockIntervalMinutes.isAcceptableOrUnknown(
          data['auto_lock_interval_minutes']!,
          _autoLockIntervalMinutesMeta,
        ),
      );
    }
    if (data.containsKey('cloud_provider')) {
      context.handle(
        _cloudProviderMeta,
        cloudProvider.isAcceptableOrUnknown(
          data['cloud_provider']!,
          _cloudProviderMeta,
        ),
      );
    }
    if (data.containsKey('linked_cloud_account')) {
      context.handle(
        _linkedCloudAccountMeta,
        linkedCloudAccount.isAcceptableOrUnknown(
          data['linked_cloud_account']!,
          _linkedCloudAccountMeta,
        ),
      );
    }
    if (data.containsKey('cloud_token_valid')) {
      context.handle(
        _cloudTokenValidMeta,
        cloudTokenValid.isAcceptableOrUnknown(
          data['cloud_token_valid']!,
          _cloudTokenValidMeta,
        ),
      );
    }
    if (data.containsKey('cloud_linked_at')) {
      context.handle(
        _cloudLinkedAtMeta,
        cloudLinkedAt.isAcceptableOrUnknown(
          data['cloud_linked_at']!,
          _cloudLinkedAtMeta,
        ),
      );
    }
    if (data.containsKey('backup_reminder_enabled')) {
      context.handle(
        _backupReminderEnabledMeta,
        backupReminderEnabled.isAcceptableOrUnknown(
          data['backup_reminder_enabled']!,
          _backupReminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('reminder_interval_days')) {
      context.handle(
        _reminderIntervalDaysMeta,
        reminderIntervalDays.isAcceptableOrUnknown(
          data['reminder_interval_days']!,
          _reminderIntervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('storage_limit_mb')) {
      context.handle(
        _storageLimitMbMeta,
        storageLimitMb.isAcceptableOrUnknown(
          data['storage_limit_mb']!,
          _storageLimitMbMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_completed')) {
      context.handle(
        _onboardingCompletedMeta,
        onboardingCompleted.isAcceptableOrUnknown(
          data['onboarding_completed']!,
          _onboardingCompletedMeta,
        ),
      );
    }
    if (data.containsKey('last_synced_export_at')) {
      context.handle(
        _lastSyncedExportAtMeta,
        lastSyncedExportAt.isAcceptableOrUnknown(
          data['last_synced_export_at']!,
          _lastSyncedExportAtMeta,
        ),
      );
    }
    if (data.containsKey('backup_availability')) {
      context.handle(
        _backupAvailabilityMeta,
        backupAvailability.isAcceptableOrUnknown(
          data['backup_availability']!,
          _backupAvailabilityMeta,
        ),
      );
    }
    if (data.containsKey('visual_theme_mode')) {
      context.handle(
        _visualThemeModeMeta,
        visualThemeMode.isAcceptableOrUnknown(
          data['visual_theme_mode']!,
          _visualThemeModeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConfigurationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConfigurationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      localAuthEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}local_auth_enabled'],
      )!,
      authenticationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}authentication_type'],
      ),
      autoLockIntervalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}auto_lock_interval_minutes'],
      )!,
      cloudProvider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_provider'],
      ),
      linkedCloudAccount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_cloud_account'],
      ),
      cloudTokenValid: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cloud_token_valid'],
      )!,
      cloudLinkedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cloud_linked_at'],
      ),
      backupReminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}backup_reminder_enabled'],
      )!,
      reminderIntervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_interval_days'],
      )!,
      storageLimitMb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}storage_limit_mb'],
      )!,
      onboardingCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_completed'],
      )!,
      lastSyncedExportAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_export_at'],
      ),
      backupAvailability: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backup_availability'],
      )!,
      visualThemeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visual_theme_mode'],
      )!,
    );
  }

  @override
  $ConfigurationsTable createAlias(String alias) {
    return $ConfigurationsTable(attachedDatabase, alias);
  }
}

class ConfigurationRow extends DataClass
    implements Insertable<ConfigurationRow> {
  final int id;
  final bool localAuthEnabled;
  final String? authenticationType;
  final int autoLockIntervalMinutes;
  final String? cloudProvider;
  final String? linkedCloudAccount;
  final bool cloudTokenValid;
  final DateTime? cloudLinkedAt;
  final bool backupReminderEnabled;
  final int reminderIntervalDays;
  final int storageLimitMb;
  final bool onboardingCompleted;
  final DateTime? lastSyncedExportAt;
  final String backupAvailability;
  final String visualThemeMode;
  const ConfigurationRow({
    required this.id,
    required this.localAuthEnabled,
    this.authenticationType,
    required this.autoLockIntervalMinutes,
    this.cloudProvider,
    this.linkedCloudAccount,
    required this.cloudTokenValid,
    this.cloudLinkedAt,
    required this.backupReminderEnabled,
    required this.reminderIntervalDays,
    required this.storageLimitMb,
    required this.onboardingCompleted,
    this.lastSyncedExportAt,
    required this.backupAvailability,
    required this.visualThemeMode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['local_auth_enabled'] = Variable<bool>(localAuthEnabled);
    if (!nullToAbsent || authenticationType != null) {
      map['authentication_type'] = Variable<String>(authenticationType);
    }
    map['auto_lock_interval_minutes'] = Variable<int>(autoLockIntervalMinutes);
    if (!nullToAbsent || cloudProvider != null) {
      map['cloud_provider'] = Variable<String>(cloudProvider);
    }
    if (!nullToAbsent || linkedCloudAccount != null) {
      map['linked_cloud_account'] = Variable<String>(linkedCloudAccount);
    }
    map['cloud_token_valid'] = Variable<bool>(cloudTokenValid);
    if (!nullToAbsent || cloudLinkedAt != null) {
      map['cloud_linked_at'] = Variable<DateTime>(cloudLinkedAt);
    }
    map['backup_reminder_enabled'] = Variable<bool>(backupReminderEnabled);
    map['reminder_interval_days'] = Variable<int>(reminderIntervalDays);
    map['storage_limit_mb'] = Variable<int>(storageLimitMb);
    map['onboarding_completed'] = Variable<bool>(onboardingCompleted);
    if (!nullToAbsent || lastSyncedExportAt != null) {
      map['last_synced_export_at'] = Variable<DateTime>(lastSyncedExportAt);
    }
    map['backup_availability'] = Variable<String>(backupAvailability);
    map['visual_theme_mode'] = Variable<String>(visualThemeMode);
    return map;
  }

  ConfigurationsCompanion toCompanion(bool nullToAbsent) {
    return ConfigurationsCompanion(
      id: Value(id),
      localAuthEnabled: Value(localAuthEnabled),
      authenticationType: authenticationType == null && nullToAbsent
          ? const Value.absent()
          : Value(authenticationType),
      autoLockIntervalMinutes: Value(autoLockIntervalMinutes),
      cloudProvider: cloudProvider == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudProvider),
      linkedCloudAccount: linkedCloudAccount == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedCloudAccount),
      cloudTokenValid: Value(cloudTokenValid),
      cloudLinkedAt: cloudLinkedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudLinkedAt),
      backupReminderEnabled: Value(backupReminderEnabled),
      reminderIntervalDays: Value(reminderIntervalDays),
      storageLimitMb: Value(storageLimitMb),
      onboardingCompleted: Value(onboardingCompleted),
      lastSyncedExportAt: lastSyncedExportAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedExportAt),
      backupAvailability: Value(backupAvailability),
      visualThemeMode: Value(visualThemeMode),
    );
  }

  factory ConfigurationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConfigurationRow(
      id: serializer.fromJson<int>(json['id']),
      localAuthEnabled: serializer.fromJson<bool>(json['localAuthEnabled']),
      authenticationType: serializer.fromJson<String?>(
        json['authenticationType'],
      ),
      autoLockIntervalMinutes: serializer.fromJson<int>(
        json['autoLockIntervalMinutes'],
      ),
      cloudProvider: serializer.fromJson<String?>(json['cloudProvider']),
      linkedCloudAccount: serializer.fromJson<String?>(
        json['linkedCloudAccount'],
      ),
      cloudTokenValid: serializer.fromJson<bool>(json['cloudTokenValid']),
      cloudLinkedAt: serializer.fromJson<DateTime?>(json['cloudLinkedAt']),
      backupReminderEnabled: serializer.fromJson<bool>(
        json['backupReminderEnabled'],
      ),
      reminderIntervalDays: serializer.fromJson<int>(
        json['reminderIntervalDays'],
      ),
      storageLimitMb: serializer.fromJson<int>(json['storageLimitMb']),
      onboardingCompleted: serializer.fromJson<bool>(
        json['onboardingCompleted'],
      ),
      lastSyncedExportAt: serializer.fromJson<DateTime?>(
        json['lastSyncedExportAt'],
      ),
      backupAvailability: serializer.fromJson<String>(
        json['backupAvailability'],
      ),
      visualThemeMode: serializer.fromJson<String>(json['visualThemeMode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localAuthEnabled': serializer.toJson<bool>(localAuthEnabled),
      'authenticationType': serializer.toJson<String?>(authenticationType),
      'autoLockIntervalMinutes': serializer.toJson<int>(
        autoLockIntervalMinutes,
      ),
      'cloudProvider': serializer.toJson<String?>(cloudProvider),
      'linkedCloudAccount': serializer.toJson<String?>(linkedCloudAccount),
      'cloudTokenValid': serializer.toJson<bool>(cloudTokenValid),
      'cloudLinkedAt': serializer.toJson<DateTime?>(cloudLinkedAt),
      'backupReminderEnabled': serializer.toJson<bool>(backupReminderEnabled),
      'reminderIntervalDays': serializer.toJson<int>(reminderIntervalDays),
      'storageLimitMb': serializer.toJson<int>(storageLimitMb),
      'onboardingCompleted': serializer.toJson<bool>(onboardingCompleted),
      'lastSyncedExportAt': serializer.toJson<DateTime?>(lastSyncedExportAt),
      'backupAvailability': serializer.toJson<String>(backupAvailability),
      'visualThemeMode': serializer.toJson<String>(visualThemeMode),
    };
  }

  ConfigurationRow copyWith({
    int? id,
    bool? localAuthEnabled,
    Value<String?> authenticationType = const Value.absent(),
    int? autoLockIntervalMinutes,
    Value<String?> cloudProvider = const Value.absent(),
    Value<String?> linkedCloudAccount = const Value.absent(),
    bool? cloudTokenValid,
    Value<DateTime?> cloudLinkedAt = const Value.absent(),
    bool? backupReminderEnabled,
    int? reminderIntervalDays,
    int? storageLimitMb,
    bool? onboardingCompleted,
    Value<DateTime?> lastSyncedExportAt = const Value.absent(),
    String? backupAvailability,
    String? visualThemeMode,
  }) => ConfigurationRow(
    id: id ?? this.id,
    localAuthEnabled: localAuthEnabled ?? this.localAuthEnabled,
    authenticationType: authenticationType.present
        ? authenticationType.value
        : this.authenticationType,
    autoLockIntervalMinutes:
        autoLockIntervalMinutes ?? this.autoLockIntervalMinutes,
    cloudProvider: cloudProvider.present
        ? cloudProvider.value
        : this.cloudProvider,
    linkedCloudAccount: linkedCloudAccount.present
        ? linkedCloudAccount.value
        : this.linkedCloudAccount,
    cloudTokenValid: cloudTokenValid ?? this.cloudTokenValid,
    cloudLinkedAt: cloudLinkedAt.present
        ? cloudLinkedAt.value
        : this.cloudLinkedAt,
    backupReminderEnabled: backupReminderEnabled ?? this.backupReminderEnabled,
    reminderIntervalDays: reminderIntervalDays ?? this.reminderIntervalDays,
    storageLimitMb: storageLimitMb ?? this.storageLimitMb,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    lastSyncedExportAt: lastSyncedExportAt.present
        ? lastSyncedExportAt.value
        : this.lastSyncedExportAt,
    backupAvailability: backupAvailability ?? this.backupAvailability,
    visualThemeMode: visualThemeMode ?? this.visualThemeMode,
  );
  ConfigurationRow copyWithCompanion(ConfigurationsCompanion data) {
    return ConfigurationRow(
      id: data.id.present ? data.id.value : this.id,
      localAuthEnabled: data.localAuthEnabled.present
          ? data.localAuthEnabled.value
          : this.localAuthEnabled,
      authenticationType: data.authenticationType.present
          ? data.authenticationType.value
          : this.authenticationType,
      autoLockIntervalMinutes: data.autoLockIntervalMinutes.present
          ? data.autoLockIntervalMinutes.value
          : this.autoLockIntervalMinutes,
      cloudProvider: data.cloudProvider.present
          ? data.cloudProvider.value
          : this.cloudProvider,
      linkedCloudAccount: data.linkedCloudAccount.present
          ? data.linkedCloudAccount.value
          : this.linkedCloudAccount,
      cloudTokenValid: data.cloudTokenValid.present
          ? data.cloudTokenValid.value
          : this.cloudTokenValid,
      cloudLinkedAt: data.cloudLinkedAt.present
          ? data.cloudLinkedAt.value
          : this.cloudLinkedAt,
      backupReminderEnabled: data.backupReminderEnabled.present
          ? data.backupReminderEnabled.value
          : this.backupReminderEnabled,
      reminderIntervalDays: data.reminderIntervalDays.present
          ? data.reminderIntervalDays.value
          : this.reminderIntervalDays,
      storageLimitMb: data.storageLimitMb.present
          ? data.storageLimitMb.value
          : this.storageLimitMb,
      onboardingCompleted: data.onboardingCompleted.present
          ? data.onboardingCompleted.value
          : this.onboardingCompleted,
      lastSyncedExportAt: data.lastSyncedExportAt.present
          ? data.lastSyncedExportAt.value
          : this.lastSyncedExportAt,
      backupAvailability: data.backupAvailability.present
          ? data.backupAvailability.value
          : this.backupAvailability,
      visualThemeMode: data.visualThemeMode.present
          ? data.visualThemeMode.value
          : this.visualThemeMode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConfigurationRow(')
          ..write('id: $id, ')
          ..write('localAuthEnabled: $localAuthEnabled, ')
          ..write('authenticationType: $authenticationType, ')
          ..write('autoLockIntervalMinutes: $autoLockIntervalMinutes, ')
          ..write('cloudProvider: $cloudProvider, ')
          ..write('linkedCloudAccount: $linkedCloudAccount, ')
          ..write('cloudTokenValid: $cloudTokenValid, ')
          ..write('cloudLinkedAt: $cloudLinkedAt, ')
          ..write('backupReminderEnabled: $backupReminderEnabled, ')
          ..write('reminderIntervalDays: $reminderIntervalDays, ')
          ..write('storageLimitMb: $storageLimitMb, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('lastSyncedExportAt: $lastSyncedExportAt, ')
          ..write('backupAvailability: $backupAvailability, ')
          ..write('visualThemeMode: $visualThemeMode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localAuthEnabled,
    authenticationType,
    autoLockIntervalMinutes,
    cloudProvider,
    linkedCloudAccount,
    cloudTokenValid,
    cloudLinkedAt,
    backupReminderEnabled,
    reminderIntervalDays,
    storageLimitMb,
    onboardingCompleted,
    lastSyncedExportAt,
    backupAvailability,
    visualThemeMode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConfigurationRow &&
          other.id == this.id &&
          other.localAuthEnabled == this.localAuthEnabled &&
          other.authenticationType == this.authenticationType &&
          other.autoLockIntervalMinutes == this.autoLockIntervalMinutes &&
          other.cloudProvider == this.cloudProvider &&
          other.linkedCloudAccount == this.linkedCloudAccount &&
          other.cloudTokenValid == this.cloudTokenValid &&
          other.cloudLinkedAt == this.cloudLinkedAt &&
          other.backupReminderEnabled == this.backupReminderEnabled &&
          other.reminderIntervalDays == this.reminderIntervalDays &&
          other.storageLimitMb == this.storageLimitMb &&
          other.onboardingCompleted == this.onboardingCompleted &&
          other.lastSyncedExportAt == this.lastSyncedExportAt &&
          other.backupAvailability == this.backupAvailability &&
          other.visualThemeMode == this.visualThemeMode);
}

class ConfigurationsCompanion extends UpdateCompanion<ConfigurationRow> {
  final Value<int> id;
  final Value<bool> localAuthEnabled;
  final Value<String?> authenticationType;
  final Value<int> autoLockIntervalMinutes;
  final Value<String?> cloudProvider;
  final Value<String?> linkedCloudAccount;
  final Value<bool> cloudTokenValid;
  final Value<DateTime?> cloudLinkedAt;
  final Value<bool> backupReminderEnabled;
  final Value<int> reminderIntervalDays;
  final Value<int> storageLimitMb;
  final Value<bool> onboardingCompleted;
  final Value<DateTime?> lastSyncedExportAt;
  final Value<String> backupAvailability;
  final Value<String> visualThemeMode;
  const ConfigurationsCompanion({
    this.id = const Value.absent(),
    this.localAuthEnabled = const Value.absent(),
    this.authenticationType = const Value.absent(),
    this.autoLockIntervalMinutes = const Value.absent(),
    this.cloudProvider = const Value.absent(),
    this.linkedCloudAccount = const Value.absent(),
    this.cloudTokenValid = const Value.absent(),
    this.cloudLinkedAt = const Value.absent(),
    this.backupReminderEnabled = const Value.absent(),
    this.reminderIntervalDays = const Value.absent(),
    this.storageLimitMb = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.lastSyncedExportAt = const Value.absent(),
    this.backupAvailability = const Value.absent(),
    this.visualThemeMode = const Value.absent(),
  });
  ConfigurationsCompanion.insert({
    this.id = const Value.absent(),
    this.localAuthEnabled = const Value.absent(),
    this.authenticationType = const Value.absent(),
    this.autoLockIntervalMinutes = const Value.absent(),
    this.cloudProvider = const Value.absent(),
    this.linkedCloudAccount = const Value.absent(),
    this.cloudTokenValid = const Value.absent(),
    this.cloudLinkedAt = const Value.absent(),
    this.backupReminderEnabled = const Value.absent(),
    this.reminderIntervalDays = const Value.absent(),
    this.storageLimitMb = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.lastSyncedExportAt = const Value.absent(),
    this.backupAvailability = const Value.absent(),
    this.visualThemeMode = const Value.absent(),
  });
  static Insertable<ConfigurationRow> custom({
    Expression<int>? id,
    Expression<bool>? localAuthEnabled,
    Expression<String>? authenticationType,
    Expression<int>? autoLockIntervalMinutes,
    Expression<String>? cloudProvider,
    Expression<String>? linkedCloudAccount,
    Expression<bool>? cloudTokenValid,
    Expression<DateTime>? cloudLinkedAt,
    Expression<bool>? backupReminderEnabled,
    Expression<int>? reminderIntervalDays,
    Expression<int>? storageLimitMb,
    Expression<bool>? onboardingCompleted,
    Expression<DateTime>? lastSyncedExportAt,
    Expression<String>? backupAvailability,
    Expression<String>? visualThemeMode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localAuthEnabled != null) 'local_auth_enabled': localAuthEnabled,
      if (authenticationType != null) 'authentication_type': authenticationType,
      if (autoLockIntervalMinutes != null)
        'auto_lock_interval_minutes': autoLockIntervalMinutes,
      if (cloudProvider != null) 'cloud_provider': cloudProvider,
      if (linkedCloudAccount != null)
        'linked_cloud_account': linkedCloudAccount,
      if (cloudTokenValid != null) 'cloud_token_valid': cloudTokenValid,
      if (cloudLinkedAt != null) 'cloud_linked_at': cloudLinkedAt,
      if (backupReminderEnabled != null)
        'backup_reminder_enabled': backupReminderEnabled,
      if (reminderIntervalDays != null)
        'reminder_interval_days': reminderIntervalDays,
      if (storageLimitMb != null) 'storage_limit_mb': storageLimitMb,
      if (onboardingCompleted != null)
        'onboarding_completed': onboardingCompleted,
      if (lastSyncedExportAt != null)
        'last_synced_export_at': lastSyncedExportAt,
      if (backupAvailability != null) 'backup_availability': backupAvailability,
      if (visualThemeMode != null) 'visual_theme_mode': visualThemeMode,
    });
  }

  ConfigurationsCompanion copyWith({
    Value<int>? id,
    Value<bool>? localAuthEnabled,
    Value<String?>? authenticationType,
    Value<int>? autoLockIntervalMinutes,
    Value<String?>? cloudProvider,
    Value<String?>? linkedCloudAccount,
    Value<bool>? cloudTokenValid,
    Value<DateTime?>? cloudLinkedAt,
    Value<bool>? backupReminderEnabled,
    Value<int>? reminderIntervalDays,
    Value<int>? storageLimitMb,
    Value<bool>? onboardingCompleted,
    Value<DateTime?>? lastSyncedExportAt,
    Value<String>? backupAvailability,
    Value<String>? visualThemeMode,
  }) {
    return ConfigurationsCompanion(
      id: id ?? this.id,
      localAuthEnabled: localAuthEnabled ?? this.localAuthEnabled,
      authenticationType: authenticationType ?? this.authenticationType,
      autoLockIntervalMinutes:
          autoLockIntervalMinutes ?? this.autoLockIntervalMinutes,
      cloudProvider: cloudProvider ?? this.cloudProvider,
      linkedCloudAccount: linkedCloudAccount ?? this.linkedCloudAccount,
      cloudTokenValid: cloudTokenValid ?? this.cloudTokenValid,
      cloudLinkedAt: cloudLinkedAt ?? this.cloudLinkedAt,
      backupReminderEnabled:
          backupReminderEnabled ?? this.backupReminderEnabled,
      reminderIntervalDays: reminderIntervalDays ?? this.reminderIntervalDays,
      storageLimitMb: storageLimitMb ?? this.storageLimitMb,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      lastSyncedExportAt: lastSyncedExportAt ?? this.lastSyncedExportAt,
      backupAvailability: backupAvailability ?? this.backupAvailability,
      visualThemeMode: visualThemeMode ?? this.visualThemeMode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localAuthEnabled.present) {
      map['local_auth_enabled'] = Variable<bool>(localAuthEnabled.value);
    }
    if (authenticationType.present) {
      map['authentication_type'] = Variable<String>(authenticationType.value);
    }
    if (autoLockIntervalMinutes.present) {
      map['auto_lock_interval_minutes'] = Variable<int>(
        autoLockIntervalMinutes.value,
      );
    }
    if (cloudProvider.present) {
      map['cloud_provider'] = Variable<String>(cloudProvider.value);
    }
    if (linkedCloudAccount.present) {
      map['linked_cloud_account'] = Variable<String>(linkedCloudAccount.value);
    }
    if (cloudTokenValid.present) {
      map['cloud_token_valid'] = Variable<bool>(cloudTokenValid.value);
    }
    if (cloudLinkedAt.present) {
      map['cloud_linked_at'] = Variable<DateTime>(cloudLinkedAt.value);
    }
    if (backupReminderEnabled.present) {
      map['backup_reminder_enabled'] = Variable<bool>(
        backupReminderEnabled.value,
      );
    }
    if (reminderIntervalDays.present) {
      map['reminder_interval_days'] = Variable<int>(reminderIntervalDays.value);
    }
    if (storageLimitMb.present) {
      map['storage_limit_mb'] = Variable<int>(storageLimitMb.value);
    }
    if (onboardingCompleted.present) {
      map['onboarding_completed'] = Variable<bool>(onboardingCompleted.value);
    }
    if (lastSyncedExportAt.present) {
      map['last_synced_export_at'] = Variable<DateTime>(
        lastSyncedExportAt.value,
      );
    }
    if (backupAvailability.present) {
      map['backup_availability'] = Variable<String>(backupAvailability.value);
    }
    if (visualThemeMode.present) {
      map['visual_theme_mode'] = Variable<String>(visualThemeMode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfigurationsCompanion(')
          ..write('id: $id, ')
          ..write('localAuthEnabled: $localAuthEnabled, ')
          ..write('authenticationType: $authenticationType, ')
          ..write('autoLockIntervalMinutes: $autoLockIntervalMinutes, ')
          ..write('cloudProvider: $cloudProvider, ')
          ..write('linkedCloudAccount: $linkedCloudAccount, ')
          ..write('cloudTokenValid: $cloudTokenValid, ')
          ..write('cloudLinkedAt: $cloudLinkedAt, ')
          ..write('backupReminderEnabled: $backupReminderEnabled, ')
          ..write('reminderIntervalDays: $reminderIntervalDays, ')
          ..write('storageLimitMb: $storageLimitMb, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('lastSyncedExportAt: $lastSyncedExportAt, ')
          ..write('backupAvailability: $backupAvailability, ')
          ..write('visualThemeMode: $visualThemeMode')
          ..write(')'))
        .toString();
  }
}

class $BackupRecordsTable extends BackupRecords
    with TableInfo<$BackupRecordsTable, BackupRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK(status IN (\'PENDENTE\',\'SINCRONIZADO\',\'FALHA\'))',
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'EXPORTACAO\' CHECK(operation IN (\'EXPORTACAO\',\'RESTAURACAO\'))',
    defaultValue: const CustomExpression('\'EXPORTACAO\''),
  );
  static const VerificationMeta _totalReceiptsMeta = const VerificationMeta(
    'totalReceipts',
  );
  @override
  late final GeneratedColumn<int> totalReceipts = GeneratedColumn<int>(
    'total_receipts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorDescriptionMeta = const VerificationMeta(
    'errorDescription',
  );
  @override
  late final GeneratedColumn<String> errorDescription = GeneratedColumn<String>(
    'error_description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cloudProviderMeta = const VerificationMeta(
    'cloudProvider',
  );
  @override
  late final GeneratedColumn<String> cloudProvider = GeneratedColumn<String>(
    'cloud_provider',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedCloudAccountMeta =
      const VerificationMeta('linkedCloudAccount');
  @override
  late final GeneratedColumn<String> linkedCloudAccount =
      GeneratedColumn<String>(
        'linked_cloud_account',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _availabilityMeta = const VerificationMeta(
    'availability',
  );
  @override
  late final GeneratedColumn<String> availability = GeneratedColumn<String>(
    'availability',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'INATIVO\' CHECK(availability IN (\'ATIVO\',\'INATIVO\',\'EXCLUIDO\'))',
    defaultValue: const CustomExpression('\'INATIVO\''),
  );
  static const VerificationMeta _configurationIdMeta = const VerificationMeta(
    'configurationId',
  );
  @override
  late final GeneratedColumn<int> configurationId = GeneratedColumn<int>(
    'configuration_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES configuration (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    status,
    operation,
    totalReceipts,
    errorDescription,
    cloudProvider,
    linkedCloudAccount,
    availability,
    configurationId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_record';
  @override
  VerificationContext validateIntegrity(
    Insertable<BackupRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    }
    if (data.containsKey('total_receipts')) {
      context.handle(
        _totalReceiptsMeta,
        totalReceipts.isAcceptableOrUnknown(
          data['total_receipts']!,
          _totalReceiptsMeta,
        ),
      );
    }
    if (data.containsKey('error_description')) {
      context.handle(
        _errorDescriptionMeta,
        errorDescription.isAcceptableOrUnknown(
          data['error_description']!,
          _errorDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('cloud_provider')) {
      context.handle(
        _cloudProviderMeta,
        cloudProvider.isAcceptableOrUnknown(
          data['cloud_provider']!,
          _cloudProviderMeta,
        ),
      );
    }
    if (data.containsKey('linked_cloud_account')) {
      context.handle(
        _linkedCloudAccountMeta,
        linkedCloudAccount.isAcceptableOrUnknown(
          data['linked_cloud_account']!,
          _linkedCloudAccountMeta,
        ),
      );
    }
    if (data.containsKey('availability')) {
      context.handle(
        _availabilityMeta,
        availability.isAcceptableOrUnknown(
          data['availability']!,
          _availabilityMeta,
        ),
      );
    }
    if (data.containsKey('configuration_id')) {
      context.handle(
        _configurationIdMeta,
        configurationId.isAcceptableOrUnknown(
          data['configuration_id']!,
          _configurationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_configurationIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BackupRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      totalReceipts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_receipts'],
      )!,
      errorDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_description'],
      ),
      cloudProvider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_provider'],
      ),
      linkedCloudAccount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_cloud_account'],
      ),
      availability: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}availability'],
      )!,
      configurationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}configuration_id'],
      )!,
    );
  }

  @override
  $BackupRecordsTable createAlias(String alias) {
    return $BackupRecordsTable(attachedDatabase, alias);
  }
}

class BackupRecordRow extends DataClass implements Insertable<BackupRecordRow> {
  final int id;
  final DateTime createdAt;
  final String status;
  final String operation;
  final int totalReceipts;
  final String? errorDescription;
  final String? cloudProvider;
  final String? linkedCloudAccount;
  final String availability;
  final int configurationId;
  const BackupRecordRow({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.operation,
    required this.totalReceipts,
    this.errorDescription,
    this.cloudProvider,
    this.linkedCloudAccount,
    required this.availability,
    required this.configurationId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<String>(status);
    map['operation'] = Variable<String>(operation);
    map['total_receipts'] = Variable<int>(totalReceipts);
    if (!nullToAbsent || errorDescription != null) {
      map['error_description'] = Variable<String>(errorDescription);
    }
    if (!nullToAbsent || cloudProvider != null) {
      map['cloud_provider'] = Variable<String>(cloudProvider);
    }
    if (!nullToAbsent || linkedCloudAccount != null) {
      map['linked_cloud_account'] = Variable<String>(linkedCloudAccount);
    }
    map['availability'] = Variable<String>(availability);
    map['configuration_id'] = Variable<int>(configurationId);
    return map;
  }

  BackupRecordsCompanion toCompanion(bool nullToAbsent) {
    return BackupRecordsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      status: Value(status),
      operation: Value(operation),
      totalReceipts: Value(totalReceipts),
      errorDescription: errorDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(errorDescription),
      cloudProvider: cloudProvider == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudProvider),
      linkedCloudAccount: linkedCloudAccount == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedCloudAccount),
      availability: Value(availability),
      configurationId: Value(configurationId),
    );
  }

  factory BackupRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupRecordRow(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
      operation: serializer.fromJson<String>(json['operation']),
      totalReceipts: serializer.fromJson<int>(json['totalReceipts']),
      errorDescription: serializer.fromJson<String?>(json['errorDescription']),
      cloudProvider: serializer.fromJson<String?>(json['cloudProvider']),
      linkedCloudAccount: serializer.fromJson<String?>(
        json['linkedCloudAccount'],
      ),
      availability: serializer.fromJson<String>(json['availability']),
      configurationId: serializer.fromJson<int>(json['configurationId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<String>(status),
      'operation': serializer.toJson<String>(operation),
      'totalReceipts': serializer.toJson<int>(totalReceipts),
      'errorDescription': serializer.toJson<String?>(errorDescription),
      'cloudProvider': serializer.toJson<String?>(cloudProvider),
      'linkedCloudAccount': serializer.toJson<String?>(linkedCloudAccount),
      'availability': serializer.toJson<String>(availability),
      'configurationId': serializer.toJson<int>(configurationId),
    };
  }

  BackupRecordRow copyWith({
    int? id,
    DateTime? createdAt,
    String? status,
    String? operation,
    int? totalReceipts,
    Value<String?> errorDescription = const Value.absent(),
    Value<String?> cloudProvider = const Value.absent(),
    Value<String?> linkedCloudAccount = const Value.absent(),
    String? availability,
    int? configurationId,
  }) => BackupRecordRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    operation: operation ?? this.operation,
    totalReceipts: totalReceipts ?? this.totalReceipts,
    errorDescription: errorDescription.present
        ? errorDescription.value
        : this.errorDescription,
    cloudProvider: cloudProvider.present
        ? cloudProvider.value
        : this.cloudProvider,
    linkedCloudAccount: linkedCloudAccount.present
        ? linkedCloudAccount.value
        : this.linkedCloudAccount,
    availability: availability ?? this.availability,
    configurationId: configurationId ?? this.configurationId,
  );
  BackupRecordRow copyWithCompanion(BackupRecordsCompanion data) {
    return BackupRecordRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      operation: data.operation.present ? data.operation.value : this.operation,
      totalReceipts: data.totalReceipts.present
          ? data.totalReceipts.value
          : this.totalReceipts,
      errorDescription: data.errorDescription.present
          ? data.errorDescription.value
          : this.errorDescription,
      cloudProvider: data.cloudProvider.present
          ? data.cloudProvider.value
          : this.cloudProvider,
      linkedCloudAccount: data.linkedCloudAccount.present
          ? data.linkedCloudAccount.value
          : this.linkedCloudAccount,
      availability: data.availability.present
          ? data.availability.value
          : this.availability,
      configurationId: data.configurationId.present
          ? data.configurationId.value
          : this.configurationId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupRecordRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('operation: $operation, ')
          ..write('totalReceipts: $totalReceipts, ')
          ..write('errorDescription: $errorDescription, ')
          ..write('cloudProvider: $cloudProvider, ')
          ..write('linkedCloudAccount: $linkedCloudAccount, ')
          ..write('availability: $availability, ')
          ..write('configurationId: $configurationId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    status,
    operation,
    totalReceipts,
    errorDescription,
    cloudProvider,
    linkedCloudAccount,
    availability,
    configurationId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupRecordRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.operation == this.operation &&
          other.totalReceipts == this.totalReceipts &&
          other.errorDescription == this.errorDescription &&
          other.cloudProvider == this.cloudProvider &&
          other.linkedCloudAccount == this.linkedCloudAccount &&
          other.availability == this.availability &&
          other.configurationId == this.configurationId);
}

class BackupRecordsCompanion extends UpdateCompanion<BackupRecordRow> {
  final Value<int> id;
  final Value<DateTime> createdAt;
  final Value<String> status;
  final Value<String> operation;
  final Value<int> totalReceipts;
  final Value<String?> errorDescription;
  final Value<String?> cloudProvider;
  final Value<String?> linkedCloudAccount;
  final Value<String> availability;
  final Value<int> configurationId;
  const BackupRecordsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.operation = const Value.absent(),
    this.totalReceipts = const Value.absent(),
    this.errorDescription = const Value.absent(),
    this.cloudProvider = const Value.absent(),
    this.linkedCloudAccount = const Value.absent(),
    this.availability = const Value.absent(),
    this.configurationId = const Value.absent(),
  });
  BackupRecordsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required String status,
    this.operation = const Value.absent(),
    this.totalReceipts = const Value.absent(),
    this.errorDescription = const Value.absent(),
    this.cloudProvider = const Value.absent(),
    this.linkedCloudAccount = const Value.absent(),
    this.availability = const Value.absent(),
    required int configurationId,
  }) : createdAt = Value(createdAt),
       status = Value(status),
       configurationId = Value(configurationId);
  static Insertable<BackupRecordRow> custom({
    Expression<int>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? status,
    Expression<String>? operation,
    Expression<int>? totalReceipts,
    Expression<String>? errorDescription,
    Expression<String>? cloudProvider,
    Expression<String>? linkedCloudAccount,
    Expression<String>? availability,
    Expression<int>? configurationId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (operation != null) 'operation': operation,
      if (totalReceipts != null) 'total_receipts': totalReceipts,
      if (errorDescription != null) 'error_description': errorDescription,
      if (cloudProvider != null) 'cloud_provider': cloudProvider,
      if (linkedCloudAccount != null)
        'linked_cloud_account': linkedCloudAccount,
      if (availability != null) 'availability': availability,
      if (configurationId != null) 'configuration_id': configurationId,
    });
  }

  BackupRecordsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? createdAt,
    Value<String>? status,
    Value<String>? operation,
    Value<int>? totalReceipts,
    Value<String?>? errorDescription,
    Value<String?>? cloudProvider,
    Value<String?>? linkedCloudAccount,
    Value<String>? availability,
    Value<int>? configurationId,
  }) {
    return BackupRecordsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      operation: operation ?? this.operation,
      totalReceipts: totalReceipts ?? this.totalReceipts,
      errorDescription: errorDescription ?? this.errorDescription,
      cloudProvider: cloudProvider ?? this.cloudProvider,
      linkedCloudAccount: linkedCloudAccount ?? this.linkedCloudAccount,
      availability: availability ?? this.availability,
      configurationId: configurationId ?? this.configurationId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (totalReceipts.present) {
      map['total_receipts'] = Variable<int>(totalReceipts.value);
    }
    if (errorDescription.present) {
      map['error_description'] = Variable<String>(errorDescription.value);
    }
    if (cloudProvider.present) {
      map['cloud_provider'] = Variable<String>(cloudProvider.value);
    }
    if (linkedCloudAccount.present) {
      map['linked_cloud_account'] = Variable<String>(linkedCloudAccount.value);
    }
    if (availability.present) {
      map['availability'] = Variable<String>(availability.value);
    }
    if (configurationId.present) {
      map['configuration_id'] = Variable<int>(configurationId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupRecordsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('operation: $operation, ')
          ..write('totalReceipts: $totalReceipts, ')
          ..write('errorDescription: $errorDescription, ')
          ..write('cloudProvider: $cloudProvider, ')
          ..write('linkedCloudAccount: $linkedCloudAccount, ')
          ..write('availability: $availability, ')
          ..write('configurationId: $configurationId')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ReceiptsTable receipts = $ReceiptsTable(this);
  late final $ExtractedDataTableTable extractedDataTable =
      $ExtractedDataTableTable(this);
  late final $EmbeddingsTable embeddings = $EmbeddingsTable(this);
  late final $CnpjCacheTable cnpjCache = $CnpjCacheTable(this);
  late final $EstablishmentCategoryCacheTable establishmentCategoryCache =
      $EstablishmentCategoryCacheTable(this);
  late final $ItemCategoryCacheTable itemCategoryCache =
      $ItemCategoryCacheTable(this);
  late final $ConfigurationsTable configurations = $ConfigurationsTable(this);
  late final $BackupRecordsTable backupRecords = $BackupRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    receipts,
    extractedDataTable,
    embeddings,
    cnpjCache,
    establishmentCategoryCache,
    itemCategoryCache,
    configurations,
    backupRecords,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'category',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('receipt', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'receipt',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('extracted_data', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'receipt',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('embedding', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'category',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cnpj_cache', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'category',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('establishment_category_cache', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'category',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('item_category_cache', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'configuration',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('backup_record', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      Value<bool> inferredAutomatically,
      Value<String> icon,
      Value<int> colorArgb,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<bool> inferredAutomatically,
      Value<String> icon,
      Value<int> colorArgb,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReceiptsTable, List<ReceiptRow>>
  _receiptsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.receipts,
    aliasName: $_aliasNameGenerator(db.categories.id, db.receipts.categoryId),
  );

  $$ReceiptsTableProcessedTableManager get receiptsRefs {
    final manager = $$ReceiptsTableTableManager(
      $_db,
      $_db.receipts,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_receiptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CnpjCacheTable, List<CnpjCacheRow>>
  _cnpjCacheRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cnpjCache,
    aliasName: $_aliasNameGenerator(
      db.categories.id,
      db.cnpjCache.preferredCategoryId,
    ),
  );

  $$CnpjCacheTableProcessedTableManager get cnpjCacheRefs {
    final manager = $$CnpjCacheTableTableManager($_db, $_db.cnpjCache).filter(
      (f) => f.preferredCategoryId.id.sqlEquals($_itemColumn<int>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_cnpjCacheRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $EstablishmentCategoryCacheTable,
    List<EstablishmentCategoryCacheRow>
  >
  _establishmentCategoryCacheRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.establishmentCategoryCache,
        aliasName: $_aliasNameGenerator(
          db.categories.id,
          db.establishmentCategoryCache.categoryId,
        ),
      );

  $$EstablishmentCategoryCacheTableProcessedTableManager
  get establishmentCategoryCacheRefs {
    final manager = $$EstablishmentCategoryCacheTableTableManager(
      $_db,
      $_db.establishmentCategoryCache,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _establishmentCategoryCacheRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ItemCategoryCacheTable,
    List<ItemCategoryCacheRow>
  >
  _itemCategoryCacheRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.itemCategoryCache,
        aliasName: $_aliasNameGenerator(
          db.categories.id,
          db.itemCategoryCache.categoryId,
        ),
      );

  $$ItemCategoryCacheTableProcessedTableManager get itemCategoryCacheRefs {
    final manager = $$ItemCategoryCacheTableTableManager(
      $_db,
      $_db.itemCategoryCache,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _itemCategoryCacheRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get inferredAutomatically => $composableBuilder(
    column: $table.inferredAutomatically,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorArgb => $composableBuilder(
    column: $table.colorArgb,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> receiptsRefs(
    Expression<bool> Function($$ReceiptsTableFilterComposer f) f,
  ) {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cnpjCacheRefs(
    Expression<bool> Function($$CnpjCacheTableFilterComposer f) f,
  ) {
    final $$CnpjCacheTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cnpjCache,
      getReferencedColumn: (t) => t.preferredCategoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CnpjCacheTableFilterComposer(
            $db: $db,
            $table: $db.cnpjCache,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> establishmentCategoryCacheRefs(
    Expression<bool> Function($$EstablishmentCategoryCacheTableFilterComposer f)
    f,
  ) {
    final $$EstablishmentCategoryCacheTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.establishmentCategoryCache,
          getReferencedColumn: (t) => t.categoryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EstablishmentCategoryCacheTableFilterComposer(
                $db: $db,
                $table: $db.establishmentCategoryCache,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> itemCategoryCacheRefs(
    Expression<bool> Function($$ItemCategoryCacheTableFilterComposer f) f,
  ) {
    final $$ItemCategoryCacheTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemCategoryCache,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemCategoryCacheTableFilterComposer(
            $db: $db,
            $table: $db.itemCategoryCache,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get inferredAutomatically => $composableBuilder(
    column: $table.inferredAutomatically,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorArgb => $composableBuilder(
    column: $table.colorArgb,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get inferredAutomatically => $composableBuilder(
    column: $table.inferredAutomatically,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get colorArgb =>
      $composableBuilder(column: $table.colorArgb, builder: (column) => column);

  Expression<T> receiptsRefs<T extends Object>(
    Expression<T> Function($$ReceiptsTableAnnotationComposer a) f,
  ) {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cnpjCacheRefs<T extends Object>(
    Expression<T> Function($$CnpjCacheTableAnnotationComposer a) f,
  ) {
    final $$CnpjCacheTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cnpjCache,
      getReferencedColumn: (t) => t.preferredCategoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CnpjCacheTableAnnotationComposer(
            $db: $db,
            $table: $db.cnpjCache,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> establishmentCategoryCacheRefs<T extends Object>(
    Expression<T> Function(
      $$EstablishmentCategoryCacheTableAnnotationComposer a,
    )
    f,
  ) {
    final $$EstablishmentCategoryCacheTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.establishmentCategoryCache,
          getReferencedColumn: (t) => t.categoryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$EstablishmentCategoryCacheTableAnnotationComposer(
                $db: $db,
                $table: $db.establishmentCategoryCache,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> itemCategoryCacheRefs<T extends Object>(
    Expression<T> Function($$ItemCategoryCacheTableAnnotationComposer a) f,
  ) {
    final $$ItemCategoryCacheTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.itemCategoryCache,
          getReferencedColumn: (t) => t.categoryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ItemCategoryCacheTableAnnotationComposer(
                $db: $db,
                $table: $db.itemCategoryCache,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryRow, $$CategoriesTableReferences),
          CategoryRow,
          PrefetchHooks Function({
            bool receiptsRefs,
            bool cnpjCacheRefs,
            bool establishmentCategoryCacheRefs,
            bool itemCategoryCacheRefs,
          })
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> inferredAutomatically = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> colorArgb = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                description: description,
                inferredAutomatically: inferredAutomatically,
                icon: icon,
                colorArgb: colorArgb,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<bool> inferredAutomatically = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> colorArgb = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                description: description,
                inferredAutomatically: inferredAutomatically,
                icon: icon,
                colorArgb: colorArgb,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                receiptsRefs = false,
                cnpjCacheRefs = false,
                establishmentCategoryCacheRefs = false,
                itemCategoryCacheRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (receiptsRefs) db.receipts,
                    if (cnpjCacheRefs) db.cnpjCache,
                    if (establishmentCategoryCacheRefs)
                      db.establishmentCategoryCache,
                    if (itemCategoryCacheRefs) db.itemCategoryCache,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (receiptsRefs)
                        await $_getPrefetchedData<
                          CategoryRow,
                          $CategoriesTable,
                          ReceiptRow
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._receiptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).receiptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cnpjCacheRefs)
                        await $_getPrefetchedData<
                          CategoryRow,
                          $CategoriesTable,
                          CnpjCacheRow
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._cnpjCacheRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).cnpjCacheRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.preferredCategoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (establishmentCategoryCacheRefs)
                        await $_getPrefetchedData<
                          CategoryRow,
                          $CategoriesTable,
                          EstablishmentCategoryCacheRow
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._establishmentCategoryCacheRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).establishmentCategoryCacheRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (itemCategoryCacheRefs)
                        await $_getPrefetchedData<
                          CategoryRow,
                          $CategoriesTable,
                          ItemCategoryCacheRow
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._itemCategoryCacheRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).itemCategoryCacheRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryRow, $$CategoriesTableReferences),
      CategoryRow,
      PrefetchHooks Function({
        bool receiptsRefs,
        bool cnpjCacheRefs,
        bool establishmentCategoryCacheRefs,
        bool itemCategoryCacheRefs,
      })
    >;
typedef $$ReceiptsTableCreateCompanionBuilder =
    ReceiptsCompanion Function({
      Value<int> id,
      required String type,
      required bool expense,
      required String fileName,
      required String fileType,
      Value<String?> fileHash,
      Value<int?> fileSize,
      Value<String> extractedContent,
      Value<int?> categoryId,
      Value<bool> cloudSynced,
      required DateTime registeredAt,
    });
typedef $$ReceiptsTableUpdateCompanionBuilder =
    ReceiptsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<bool> expense,
      Value<String> fileName,
      Value<String> fileType,
      Value<String?> fileHash,
      Value<int?> fileSize,
      Value<String> extractedContent,
      Value<int?> categoryId,
      Value<bool> cloudSynced,
      Value<DateTime> registeredAt,
    });

final class $$ReceiptsTableReferences
    extends BaseReferences<_$AppDatabase, $ReceiptsTable, ReceiptRow> {
  $$ReceiptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.receipts.categoryId, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ExtractedDataTableTable, List<ExtractedDataRow>>
  _extractedDataTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.extractedDataTable,
        aliasName: $_aliasNameGenerator(
          db.receipts.id,
          db.extractedDataTable.receiptId,
        ),
      );

  $$ExtractedDataTableTableProcessedTableManager get extractedDataTableRefs {
    final manager = $$ExtractedDataTableTableTableManager(
      $_db,
      $_db.extractedDataTable,
    ).filter((f) => f.receiptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _extractedDataTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EmbeddingsTable, List<EmbeddingRow>>
  _embeddingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.embeddings,
    aliasName: $_aliasNameGenerator(db.receipts.id, db.embeddings.receiptId),
  );

  $$EmbeddingsTableProcessedTableManager get embeddingsRefs {
    final manager = $$EmbeddingsTableTableManager(
      $_db,
      $_db.embeddings,
    ).filter((f) => f.receiptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_embeddingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ReceiptsTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get expense => $composableBuilder(
    column: $table.expense,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extractedContent => $composableBuilder(
    column: $table.extractedContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cloudSynced => $composableBuilder(
    column: $table.cloudSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get registeredAt => $composableBuilder(
    column: $table.registeredAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> extractedDataTableRefs(
    Expression<bool> Function($$ExtractedDataTableTableFilterComposer f) f,
  ) {
    final $$ExtractedDataTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.extractedDataTable,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtractedDataTableTableFilterComposer(
            $db: $db,
            $table: $db.extractedDataTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> embeddingsRefs(
    Expression<bool> Function($$EmbeddingsTableFilterComposer f) f,
  ) {
    final $$EmbeddingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.embeddings,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmbeddingsTableFilterComposer(
            $db: $db,
            $table: $db.embeddings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReceiptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get expense => $composableBuilder(
    column: $table.expense,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extractedContent => $composableBuilder(
    column: $table.extractedContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cloudSynced => $composableBuilder(
    column: $table.cloudSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get registeredAt => $composableBuilder(
    column: $table.registeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get expense =>
      $composableBuilder(column: $table.expense, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get extractedContent => $composableBuilder(
    column: $table.extractedContent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get cloudSynced => $composableBuilder(
    column: $table.cloudSynced,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get registeredAt => $composableBuilder(
    column: $table.registeredAt,
    builder: (column) => column,
  );

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> extractedDataTableRefs<T extends Object>(
    Expression<T> Function($$ExtractedDataTableTableAnnotationComposer a) f,
  ) {
    final $$ExtractedDataTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.extractedDataTable,
          getReferencedColumn: (t) => t.receiptId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExtractedDataTableTableAnnotationComposer(
                $db: $db,
                $table: $db.extractedDataTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> embeddingsRefs<T extends Object>(
    Expression<T> Function($$EmbeddingsTableAnnotationComposer a) f,
  ) {
    final $$EmbeddingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.embeddings,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmbeddingsTableAnnotationComposer(
            $db: $db,
            $table: $db.embeddings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReceiptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceiptsTable,
          ReceiptRow,
          $$ReceiptsTableFilterComposer,
          $$ReceiptsTableOrderingComposer,
          $$ReceiptsTableAnnotationComposer,
          $$ReceiptsTableCreateCompanionBuilder,
          $$ReceiptsTableUpdateCompanionBuilder,
          (ReceiptRow, $$ReceiptsTableReferences),
          ReceiptRow,
          PrefetchHooks Function({
            bool categoryId,
            bool extractedDataTableRefs,
            bool embeddingsRefs,
          })
        > {
  $$ReceiptsTableTableManager(_$AppDatabase db, $ReceiptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<bool> expense = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> fileType = const Value.absent(),
                Value<String?> fileHash = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<String> extractedContent = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<bool> cloudSynced = const Value.absent(),
                Value<DateTime> registeredAt = const Value.absent(),
              }) => ReceiptsCompanion(
                id: id,
                type: type,
                expense: expense,
                fileName: fileName,
                fileType: fileType,
                fileHash: fileHash,
                fileSize: fileSize,
                extractedContent: extractedContent,
                categoryId: categoryId,
                cloudSynced: cloudSynced,
                registeredAt: registeredAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required bool expense,
                required String fileName,
                required String fileType,
                Value<String?> fileHash = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<String> extractedContent = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<bool> cloudSynced = const Value.absent(),
                required DateTime registeredAt,
              }) => ReceiptsCompanion.insert(
                id: id,
                type: type,
                expense: expense,
                fileName: fileName,
                fileType: fileType,
                fileHash: fileHash,
                fileSize: fileSize,
                extractedContent: extractedContent,
                categoryId: categoryId,
                cloudSynced: cloudSynced,
                registeredAt: registeredAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReceiptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                extractedDataTableRefs = false,
                embeddingsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (extractedDataTableRefs) db.extractedDataTable,
                    if (embeddingsRefs) db.embeddings,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable: $$ReceiptsTableReferences
                                        ._categoryIdTable(db),
                                    referencedColumn: $$ReceiptsTableReferences
                                        ._categoryIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (extractedDataTableRefs)
                        await $_getPrefetchedData<
                          ReceiptRow,
                          $ReceiptsTable,
                          ExtractedDataRow
                        >(
                          currentTable: table,
                          referencedTable: $$ReceiptsTableReferences
                              ._extractedDataTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ReceiptsTableReferences(
                                db,
                                table,
                                p0,
                              ).extractedDataTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.receiptId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (embeddingsRefs)
                        await $_getPrefetchedData<
                          ReceiptRow,
                          $ReceiptsTable,
                          EmbeddingRow
                        >(
                          currentTable: table,
                          referencedTable: $$ReceiptsTableReferences
                              ._embeddingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ReceiptsTableReferences(
                                db,
                                table,
                                p0,
                              ).embeddingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.receiptId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceiptsTable,
      ReceiptRow,
      $$ReceiptsTableFilterComposer,
      $$ReceiptsTableOrderingComposer,
      $$ReceiptsTableAnnotationComposer,
      $$ReceiptsTableCreateCompanionBuilder,
      $$ReceiptsTableUpdateCompanionBuilder,
      (ReceiptRow, $$ReceiptsTableReferences),
      ReceiptRow,
      PrefetchHooks Function({
        bool categoryId,
        bool extractedDataTableRefs,
        bool embeddingsRefs,
      })
    >;
typedef $$ExtractedDataTableTableCreateCompanionBuilder =
    ExtractedDataTableCompanion Function({
      Value<int> id,
      required int receiptId,
      Value<double?> amount,
      Value<DateTime?> transactionDate,
      Value<String?> establishment,
      Value<String> items,
      Value<String?> paymentMethod,
      Value<String?> issuerCnpj,
      Value<String?> accessKey,
      Value<String?> urlQrCode,
      Value<String?> documentNumber,
      Value<String?> documentSeries,
      Value<String?> documentState,
      Value<String?> issuerLegalName,
      Value<String?> issuerTradeName,
      Value<String?> fiscalCnaeDescription,
      Value<String?> issuerCity,
      Value<String?> issuerState,
      Value<double?> ocrConfidence,
      Value<String?> extractionParser,
      Value<double?> extractionConfidence,
      Value<double?> valueConfidence,
      Value<double?> dateConfidence,
      Value<double?> establishmentConfidence,
      Value<double?> paymentMethodConfidence,
      Value<String?> qualityMetadata,
    });
typedef $$ExtractedDataTableTableUpdateCompanionBuilder =
    ExtractedDataTableCompanion Function({
      Value<int> id,
      Value<int> receiptId,
      Value<double?> amount,
      Value<DateTime?> transactionDate,
      Value<String?> establishment,
      Value<String> items,
      Value<String?> paymentMethod,
      Value<String?> issuerCnpj,
      Value<String?> accessKey,
      Value<String?> urlQrCode,
      Value<String?> documentNumber,
      Value<String?> documentSeries,
      Value<String?> documentState,
      Value<String?> issuerLegalName,
      Value<String?> issuerTradeName,
      Value<String?> fiscalCnaeDescription,
      Value<String?> issuerCity,
      Value<String?> issuerState,
      Value<double?> ocrConfidence,
      Value<String?> extractionParser,
      Value<double?> extractionConfidence,
      Value<double?> valueConfidence,
      Value<double?> dateConfidence,
      Value<double?> establishmentConfidence,
      Value<double?> paymentMethodConfidence,
      Value<String?> qualityMetadata,
    });

final class $$ExtractedDataTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ExtractedDataTableTable,
          ExtractedDataRow
        > {
  $$ExtractedDataTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ReceiptsTable _receiptIdTable(_$AppDatabase db) =>
      db.receipts.createAlias(
        $_aliasNameGenerator(db.extractedDataTable.receiptId, db.receipts.id),
      );

  $$ReceiptsTableProcessedTableManager get receiptId {
    final $_column = $_itemColumn<int>('receipt_id')!;

    final manager = $$ReceiptsTableTableManager(
      $_db,
      $_db.receipts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_receiptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExtractedDataTableTableFilterComposer
    extends Composer<_$AppDatabase, $ExtractedDataTableTable> {
  $$ExtractedDataTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get establishment => $composableBuilder(
    column: $table.establishment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get items => $composableBuilder(
    column: $table.items,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issuerCnpj => $composableBuilder(
    column: $table.issuerCnpj,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessKey => $composableBuilder(
    column: $table.accessKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get urlQrCode => $composableBuilder(
    column: $table.urlQrCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentNumber => $composableBuilder(
    column: $table.documentNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentSeries => $composableBuilder(
    column: $table.documentSeries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentState => $composableBuilder(
    column: $table.documentState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issuerLegalName => $composableBuilder(
    column: $table.issuerLegalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issuerTradeName => $composableBuilder(
    column: $table.issuerTradeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fiscalCnaeDescription => $composableBuilder(
    column: $table.fiscalCnaeDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issuerCity => $composableBuilder(
    column: $table.issuerCity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issuerState => $composableBuilder(
    column: $table.issuerState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ocrConfidence => $composableBuilder(
    column: $table.ocrConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extractionParser => $composableBuilder(
    column: $table.extractionParser,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get extractionConfidence => $composableBuilder(
    column: $table.extractionConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get valueConfidence => $composableBuilder(
    column: $table.valueConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dateConfidence => $composableBuilder(
    column: $table.dateConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get establishmentConfidence => $composableBuilder(
    column: $table.establishmentConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get paymentMethodConfidence => $composableBuilder(
    column: $table.paymentMethodConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qualityMetadata => $composableBuilder(
    column: $table.qualityMetadata,
    builder: (column) => ColumnFilters(column),
  );

  $$ReceiptsTableFilterComposer get receiptId {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExtractedDataTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ExtractedDataTableTable> {
  $$ExtractedDataTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get establishment => $composableBuilder(
    column: $table.establishment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get items => $composableBuilder(
    column: $table.items,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issuerCnpj => $composableBuilder(
    column: $table.issuerCnpj,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessKey => $composableBuilder(
    column: $table.accessKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get urlQrCode => $composableBuilder(
    column: $table.urlQrCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentNumber => $composableBuilder(
    column: $table.documentNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentSeries => $composableBuilder(
    column: $table.documentSeries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentState => $composableBuilder(
    column: $table.documentState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issuerLegalName => $composableBuilder(
    column: $table.issuerLegalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issuerTradeName => $composableBuilder(
    column: $table.issuerTradeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fiscalCnaeDescription => $composableBuilder(
    column: $table.fiscalCnaeDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issuerCity => $composableBuilder(
    column: $table.issuerCity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issuerState => $composableBuilder(
    column: $table.issuerState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ocrConfidence => $composableBuilder(
    column: $table.ocrConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extractionParser => $composableBuilder(
    column: $table.extractionParser,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get extractionConfidence => $composableBuilder(
    column: $table.extractionConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get valueConfidence => $composableBuilder(
    column: $table.valueConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dateConfidence => $composableBuilder(
    column: $table.dateConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get establishmentConfidence => $composableBuilder(
    column: $table.establishmentConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get paymentMethodConfidence => $composableBuilder(
    column: $table.paymentMethodConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qualityMetadata => $composableBuilder(
    column: $table.qualityMetadata,
    builder: (column) => ColumnOrderings(column),
  );

  $$ReceiptsTableOrderingComposer get receiptId {
    final $$ReceiptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableOrderingComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExtractedDataTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExtractedDataTableTable> {
  $$ExtractedDataTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get establishment => $composableBuilder(
    column: $table.establishment,
    builder: (column) => column,
  );

  GeneratedColumn<String> get items =>
      $composableBuilder(column: $table.items, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get issuerCnpj => $composableBuilder(
    column: $table.issuerCnpj,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accessKey =>
      $composableBuilder(column: $table.accessKey, builder: (column) => column);

  GeneratedColumn<String> get urlQrCode =>
      $composableBuilder(column: $table.urlQrCode, builder: (column) => column);

  GeneratedColumn<String> get documentNumber => $composableBuilder(
    column: $table.documentNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documentSeries => $composableBuilder(
    column: $table.documentSeries,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documentState => $composableBuilder(
    column: $table.documentState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get issuerLegalName => $composableBuilder(
    column: $table.issuerLegalName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get issuerTradeName => $composableBuilder(
    column: $table.issuerTradeName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fiscalCnaeDescription => $composableBuilder(
    column: $table.fiscalCnaeDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get issuerCity => $composableBuilder(
    column: $table.issuerCity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get issuerState => $composableBuilder(
    column: $table.issuerState,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ocrConfidence => $composableBuilder(
    column: $table.ocrConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extractionParser => $composableBuilder(
    column: $table.extractionParser,
    builder: (column) => column,
  );

  GeneratedColumn<double> get extractionConfidence => $composableBuilder(
    column: $table.extractionConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get valueConfidence => $composableBuilder(
    column: $table.valueConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get dateConfidence => $composableBuilder(
    column: $table.dateConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get establishmentConfidence => $composableBuilder(
    column: $table.establishmentConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get paymentMethodConfidence => $composableBuilder(
    column: $table.paymentMethodConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get qualityMetadata => $composableBuilder(
    column: $table.qualityMetadata,
    builder: (column) => column,
  );

  $$ReceiptsTableAnnotationComposer get receiptId {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExtractedDataTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExtractedDataTableTable,
          ExtractedDataRow,
          $$ExtractedDataTableTableFilterComposer,
          $$ExtractedDataTableTableOrderingComposer,
          $$ExtractedDataTableTableAnnotationComposer,
          $$ExtractedDataTableTableCreateCompanionBuilder,
          $$ExtractedDataTableTableUpdateCompanionBuilder,
          (ExtractedDataRow, $$ExtractedDataTableTableReferences),
          ExtractedDataRow,
          PrefetchHooks Function({bool receiptId})
        > {
  $$ExtractedDataTableTableTableManager(
    _$AppDatabase db,
    $ExtractedDataTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExtractedDataTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExtractedDataTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExtractedDataTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> receiptId = const Value.absent(),
                Value<double?> amount = const Value.absent(),
                Value<DateTime?> transactionDate = const Value.absent(),
                Value<String?> establishment = const Value.absent(),
                Value<String> items = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> issuerCnpj = const Value.absent(),
                Value<String?> accessKey = const Value.absent(),
                Value<String?> urlQrCode = const Value.absent(),
                Value<String?> documentNumber = const Value.absent(),
                Value<String?> documentSeries = const Value.absent(),
                Value<String?> documentState = const Value.absent(),
                Value<String?> issuerLegalName = const Value.absent(),
                Value<String?> issuerTradeName = const Value.absent(),
                Value<String?> fiscalCnaeDescription = const Value.absent(),
                Value<String?> issuerCity = const Value.absent(),
                Value<String?> issuerState = const Value.absent(),
                Value<double?> ocrConfidence = const Value.absent(),
                Value<String?> extractionParser = const Value.absent(),
                Value<double?> extractionConfidence = const Value.absent(),
                Value<double?> valueConfidence = const Value.absent(),
                Value<double?> dateConfidence = const Value.absent(),
                Value<double?> establishmentConfidence = const Value.absent(),
                Value<double?> paymentMethodConfidence = const Value.absent(),
                Value<String?> qualityMetadata = const Value.absent(),
              }) => ExtractedDataTableCompanion(
                id: id,
                receiptId: receiptId,
                amount: amount,
                transactionDate: transactionDate,
                establishment: establishment,
                items: items,
                paymentMethod: paymentMethod,
                issuerCnpj: issuerCnpj,
                accessKey: accessKey,
                urlQrCode: urlQrCode,
                documentNumber: documentNumber,
                documentSeries: documentSeries,
                documentState: documentState,
                issuerLegalName: issuerLegalName,
                issuerTradeName: issuerTradeName,
                fiscalCnaeDescription: fiscalCnaeDescription,
                issuerCity: issuerCity,
                issuerState: issuerState,
                ocrConfidence: ocrConfidence,
                extractionParser: extractionParser,
                extractionConfidence: extractionConfidence,
                valueConfidence: valueConfidence,
                dateConfidence: dateConfidence,
                establishmentConfidence: establishmentConfidence,
                paymentMethodConfidence: paymentMethodConfidence,
                qualityMetadata: qualityMetadata,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int receiptId,
                Value<double?> amount = const Value.absent(),
                Value<DateTime?> transactionDate = const Value.absent(),
                Value<String?> establishment = const Value.absent(),
                Value<String> items = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> issuerCnpj = const Value.absent(),
                Value<String?> accessKey = const Value.absent(),
                Value<String?> urlQrCode = const Value.absent(),
                Value<String?> documentNumber = const Value.absent(),
                Value<String?> documentSeries = const Value.absent(),
                Value<String?> documentState = const Value.absent(),
                Value<String?> issuerLegalName = const Value.absent(),
                Value<String?> issuerTradeName = const Value.absent(),
                Value<String?> fiscalCnaeDescription = const Value.absent(),
                Value<String?> issuerCity = const Value.absent(),
                Value<String?> issuerState = const Value.absent(),
                Value<double?> ocrConfidence = const Value.absent(),
                Value<String?> extractionParser = const Value.absent(),
                Value<double?> extractionConfidence = const Value.absent(),
                Value<double?> valueConfidence = const Value.absent(),
                Value<double?> dateConfidence = const Value.absent(),
                Value<double?> establishmentConfidence = const Value.absent(),
                Value<double?> paymentMethodConfidence = const Value.absent(),
                Value<String?> qualityMetadata = const Value.absent(),
              }) => ExtractedDataTableCompanion.insert(
                id: id,
                receiptId: receiptId,
                amount: amount,
                transactionDate: transactionDate,
                establishment: establishment,
                items: items,
                paymentMethod: paymentMethod,
                issuerCnpj: issuerCnpj,
                accessKey: accessKey,
                urlQrCode: urlQrCode,
                documentNumber: documentNumber,
                documentSeries: documentSeries,
                documentState: documentState,
                issuerLegalName: issuerLegalName,
                issuerTradeName: issuerTradeName,
                fiscalCnaeDescription: fiscalCnaeDescription,
                issuerCity: issuerCity,
                issuerState: issuerState,
                ocrConfidence: ocrConfidence,
                extractionParser: extractionParser,
                extractionConfidence: extractionConfidence,
                valueConfidence: valueConfidence,
                dateConfidence: dateConfidence,
                establishmentConfidence: establishmentConfidence,
                paymentMethodConfidence: paymentMethodConfidence,
                qualityMetadata: qualityMetadata,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExtractedDataTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({receiptId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (receiptId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.receiptId,
                                referencedTable:
                                    $$ExtractedDataTableTableReferences
                                        ._receiptIdTable(db),
                                referencedColumn:
                                    $$ExtractedDataTableTableReferences
                                        ._receiptIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExtractedDataTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExtractedDataTableTable,
      ExtractedDataRow,
      $$ExtractedDataTableTableFilterComposer,
      $$ExtractedDataTableTableOrderingComposer,
      $$ExtractedDataTableTableAnnotationComposer,
      $$ExtractedDataTableTableCreateCompanionBuilder,
      $$ExtractedDataTableTableUpdateCompanionBuilder,
      (ExtractedDataRow, $$ExtractedDataTableTableReferences),
      ExtractedDataRow,
      PrefetchHooks Function({bool receiptId})
    >;
typedef $$EmbeddingsTableCreateCompanionBuilder =
    EmbeddingsCompanion Function({
      Value<int> id,
      required int receiptId,
      required Uint8List vector,
      required String model,
      required int dimension,
      required DateTime generatedAt,
    });
typedef $$EmbeddingsTableUpdateCompanionBuilder =
    EmbeddingsCompanion Function({
      Value<int> id,
      Value<int> receiptId,
      Value<Uint8List> vector,
      Value<String> model,
      Value<int> dimension,
      Value<DateTime> generatedAt,
    });

final class $$EmbeddingsTableReferences
    extends BaseReferences<_$AppDatabase, $EmbeddingsTable, EmbeddingRow> {
  $$EmbeddingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ReceiptsTable _receiptIdTable(_$AppDatabase db) =>
      db.receipts.createAlias(
        $_aliasNameGenerator(db.embeddings.receiptId, db.receipts.id),
      );

  $$ReceiptsTableProcessedTableManager get receiptId {
    final $_column = $_itemColumn<int>('receipt_id')!;

    final manager = $$ReceiptsTableTableManager(
      $_db,
      $_db.receipts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_receiptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EmbeddingsTableFilterComposer
    extends Composer<_$AppDatabase, $EmbeddingsTable> {
  $$EmbeddingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get vector => $composableBuilder(
    column: $table.vector,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dimension => $composableBuilder(
    column: $table.dimension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ReceiptsTableFilterComposer get receiptId {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EmbeddingsTableOrderingComposer
    extends Composer<_$AppDatabase, $EmbeddingsTable> {
  $$EmbeddingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get vector => $composableBuilder(
    column: $table.vector,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dimension => $composableBuilder(
    column: $table.dimension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ReceiptsTableOrderingComposer get receiptId {
    final $$ReceiptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableOrderingComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EmbeddingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmbeddingsTable> {
  $$EmbeddingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<Uint8List> get vector =>
      $composableBuilder(column: $table.vector, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get dimension =>
      $composableBuilder(column: $table.dimension, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => column,
  );

  $$ReceiptsTableAnnotationComposer get receiptId {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EmbeddingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmbeddingsTable,
          EmbeddingRow,
          $$EmbeddingsTableFilterComposer,
          $$EmbeddingsTableOrderingComposer,
          $$EmbeddingsTableAnnotationComposer,
          $$EmbeddingsTableCreateCompanionBuilder,
          $$EmbeddingsTableUpdateCompanionBuilder,
          (EmbeddingRow, $$EmbeddingsTableReferences),
          EmbeddingRow,
          PrefetchHooks Function({bool receiptId})
        > {
  $$EmbeddingsTableTableManager(_$AppDatabase db, $EmbeddingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmbeddingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmbeddingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmbeddingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> receiptId = const Value.absent(),
                Value<Uint8List> vector = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<int> dimension = const Value.absent(),
                Value<DateTime> generatedAt = const Value.absent(),
              }) => EmbeddingsCompanion(
                id: id,
                receiptId: receiptId,
                vector: vector,
                model: model,
                dimension: dimension,
                generatedAt: generatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int receiptId,
                required Uint8List vector,
                required String model,
                required int dimension,
                required DateTime generatedAt,
              }) => EmbeddingsCompanion.insert(
                id: id,
                receiptId: receiptId,
                vector: vector,
                model: model,
                dimension: dimension,
                generatedAt: generatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EmbeddingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({receiptId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (receiptId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.receiptId,
                                referencedTable: $$EmbeddingsTableReferences
                                    ._receiptIdTable(db),
                                referencedColumn: $$EmbeddingsTableReferences
                                    ._receiptIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EmbeddingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmbeddingsTable,
      EmbeddingRow,
      $$EmbeddingsTableFilterComposer,
      $$EmbeddingsTableOrderingComposer,
      $$EmbeddingsTableAnnotationComposer,
      $$EmbeddingsTableCreateCompanionBuilder,
      $$EmbeddingsTableUpdateCompanionBuilder,
      (EmbeddingRow, $$EmbeddingsTableReferences),
      EmbeddingRow,
      PrefetchHooks Function({bool receiptId})
    >;
typedef $$CnpjCacheTableCreateCompanionBuilder =
    CnpjCacheCompanion Function({
      required String cnpj,
      Value<String?> legalName,
      Value<String?> tradeName,
      Value<String?> confirmedName,
      Value<String?> fiscalCnaeDescription,
      Value<String?> city,
      Value<String?> state,
      Value<int?> preferredCategoryId,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CnpjCacheTableUpdateCompanionBuilder =
    CnpjCacheCompanion Function({
      Value<String> cnpj,
      Value<String?> legalName,
      Value<String?> tradeName,
      Value<String?> confirmedName,
      Value<String?> fiscalCnaeDescription,
      Value<String?> city,
      Value<String?> state,
      Value<int?> preferredCategoryId,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$CnpjCacheTableReferences
    extends BaseReferences<_$AppDatabase, $CnpjCacheTable, CnpjCacheRow> {
  $$CnpjCacheTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _preferredCategoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(
          db.cnpjCache.preferredCategoryId,
          db.categories.id,
        ),
      );

  $$CategoriesTableProcessedTableManager? get preferredCategoryId {
    final $_column = $_itemColumn<int>('preferred_category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_preferredCategoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CnpjCacheTableFilterComposer
    extends Composer<_$AppDatabase, $CnpjCacheTable> {
  $$CnpjCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cnpj => $composableBuilder(
    column: $table.cnpj,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legalName => $composableBuilder(
    column: $table.legalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tradeName => $composableBuilder(
    column: $table.tradeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confirmedName => $composableBuilder(
    column: $table.confirmedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fiscalCnaeDescription => $composableBuilder(
    column: $table.fiscalCnaeDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get preferredCategoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.preferredCategoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CnpjCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $CnpjCacheTable> {
  $$CnpjCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cnpj => $composableBuilder(
    column: $table.cnpj,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legalName => $composableBuilder(
    column: $table.legalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tradeName => $composableBuilder(
    column: $table.tradeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confirmedName => $composableBuilder(
    column: $table.confirmedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fiscalCnaeDescription => $composableBuilder(
    column: $table.fiscalCnaeDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get preferredCategoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.preferredCategoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CnpjCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $CnpjCacheTable> {
  $$CnpjCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cnpj =>
      $composableBuilder(column: $table.cnpj, builder: (column) => column);

  GeneratedColumn<String> get legalName =>
      $composableBuilder(column: $table.legalName, builder: (column) => column);

  GeneratedColumn<String> get tradeName =>
      $composableBuilder(column: $table.tradeName, builder: (column) => column);

  GeneratedColumn<String> get confirmedName => $composableBuilder(
    column: $table.confirmedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fiscalCnaeDescription => $composableBuilder(
    column: $table.fiscalCnaeDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get preferredCategoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.preferredCategoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CnpjCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CnpjCacheTable,
          CnpjCacheRow,
          $$CnpjCacheTableFilterComposer,
          $$CnpjCacheTableOrderingComposer,
          $$CnpjCacheTableAnnotationComposer,
          $$CnpjCacheTableCreateCompanionBuilder,
          $$CnpjCacheTableUpdateCompanionBuilder,
          (CnpjCacheRow, $$CnpjCacheTableReferences),
          CnpjCacheRow,
          PrefetchHooks Function({bool preferredCategoryId})
        > {
  $$CnpjCacheTableTableManager(_$AppDatabase db, $CnpjCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CnpjCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CnpjCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CnpjCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cnpj = const Value.absent(),
                Value<String?> legalName = const Value.absent(),
                Value<String?> tradeName = const Value.absent(),
                Value<String?> confirmedName = const Value.absent(),
                Value<String?> fiscalCnaeDescription = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> state = const Value.absent(),
                Value<int?> preferredCategoryId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CnpjCacheCompanion(
                cnpj: cnpj,
                legalName: legalName,
                tradeName: tradeName,
                confirmedName: confirmedName,
                fiscalCnaeDescription: fiscalCnaeDescription,
                city: city,
                state: state,
                preferredCategoryId: preferredCategoryId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cnpj,
                Value<String?> legalName = const Value.absent(),
                Value<String?> tradeName = const Value.absent(),
                Value<String?> confirmedName = const Value.absent(),
                Value<String?> fiscalCnaeDescription = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> state = const Value.absent(),
                Value<int?> preferredCategoryId = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CnpjCacheCompanion.insert(
                cnpj: cnpj,
                legalName: legalName,
                tradeName: tradeName,
                confirmedName: confirmedName,
                fiscalCnaeDescription: fiscalCnaeDescription,
                city: city,
                state: state,
                preferredCategoryId: preferredCategoryId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CnpjCacheTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({preferredCategoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (preferredCategoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.preferredCategoryId,
                                referencedTable: $$CnpjCacheTableReferences
                                    ._preferredCategoryIdTable(db),
                                referencedColumn: $$CnpjCacheTableReferences
                                    ._preferredCategoryIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CnpjCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CnpjCacheTable,
      CnpjCacheRow,
      $$CnpjCacheTableFilterComposer,
      $$CnpjCacheTableOrderingComposer,
      $$CnpjCacheTableAnnotationComposer,
      $$CnpjCacheTableCreateCompanionBuilder,
      $$CnpjCacheTableUpdateCompanionBuilder,
      (CnpjCacheRow, $$CnpjCacheTableReferences),
      CnpjCacheRow,
      PrefetchHooks Function({bool preferredCategoryId})
    >;
typedef $$EstablishmentCategoryCacheTableCreateCompanionBuilder =
    EstablishmentCategoryCacheCompanion Function({
      required String establishmentKey,
      required String establishment,
      required int categoryId,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$EstablishmentCategoryCacheTableUpdateCompanionBuilder =
    EstablishmentCategoryCacheCompanion Function({
      Value<String> establishmentKey,
      Value<String> establishment,
      Value<int> categoryId,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$EstablishmentCategoryCacheTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $EstablishmentCategoryCacheTable,
          EstablishmentCategoryCacheRow
        > {
  $$EstablishmentCategoryCacheTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(
          db.establishmentCategoryCache.categoryId,
          db.categories.id,
        ),
      );

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EstablishmentCategoryCacheTableFilterComposer
    extends Composer<_$AppDatabase, $EstablishmentCategoryCacheTable> {
  $$EstablishmentCategoryCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get establishmentKey => $composableBuilder(
    column: $table.establishmentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get establishment => $composableBuilder(
    column: $table.establishment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EstablishmentCategoryCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $EstablishmentCategoryCacheTable> {
  $$EstablishmentCategoryCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get establishmentKey => $composableBuilder(
    column: $table.establishmentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get establishment => $composableBuilder(
    column: $table.establishment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EstablishmentCategoryCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $EstablishmentCategoryCacheTable> {
  $$EstablishmentCategoryCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get establishmentKey => $composableBuilder(
    column: $table.establishmentKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get establishment => $composableBuilder(
    column: $table.establishment,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EstablishmentCategoryCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EstablishmentCategoryCacheTable,
          EstablishmentCategoryCacheRow,
          $$EstablishmentCategoryCacheTableFilterComposer,
          $$EstablishmentCategoryCacheTableOrderingComposer,
          $$EstablishmentCategoryCacheTableAnnotationComposer,
          $$EstablishmentCategoryCacheTableCreateCompanionBuilder,
          $$EstablishmentCategoryCacheTableUpdateCompanionBuilder,
          (
            EstablishmentCategoryCacheRow,
            $$EstablishmentCategoryCacheTableReferences,
          ),
          EstablishmentCategoryCacheRow,
          PrefetchHooks Function({bool categoryId})
        > {
  $$EstablishmentCategoryCacheTableTableManager(
    _$AppDatabase db,
    $EstablishmentCategoryCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EstablishmentCategoryCacheTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EstablishmentCategoryCacheTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EstablishmentCategoryCacheTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> establishmentKey = const Value.absent(),
                Value<String> establishment = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EstablishmentCategoryCacheCompanion(
                establishmentKey: establishmentKey,
                establishment: establishment,
                categoryId: categoryId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String establishmentKey,
                required String establishment,
                required int categoryId,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => EstablishmentCategoryCacheCompanion.insert(
                establishmentKey: establishmentKey,
                establishment: establishment,
                categoryId: categoryId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EstablishmentCategoryCacheTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryId,
                                referencedTable:
                                    $$EstablishmentCategoryCacheTableReferences
                                        ._categoryIdTable(db),
                                referencedColumn:
                                    $$EstablishmentCategoryCacheTableReferences
                                        ._categoryIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EstablishmentCategoryCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EstablishmentCategoryCacheTable,
      EstablishmentCategoryCacheRow,
      $$EstablishmentCategoryCacheTableFilterComposer,
      $$EstablishmentCategoryCacheTableOrderingComposer,
      $$EstablishmentCategoryCacheTableAnnotationComposer,
      $$EstablishmentCategoryCacheTableCreateCompanionBuilder,
      $$EstablishmentCategoryCacheTableUpdateCompanionBuilder,
      (
        EstablishmentCategoryCacheRow,
        $$EstablishmentCategoryCacheTableReferences,
      ),
      EstablishmentCategoryCacheRow,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$ItemCategoryCacheTableCreateCompanionBuilder =
    ItemCategoryCacheCompanion Function({
      required String itemKey,
      required String item,
      required int categoryId,
      Value<int> occurrences,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ItemCategoryCacheTableUpdateCompanionBuilder =
    ItemCategoryCacheCompanion Function({
      Value<String> itemKey,
      Value<String> item,
      Value<int> categoryId,
      Value<int> occurrences,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ItemCategoryCacheTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ItemCategoryCacheTable,
          ItemCategoryCacheRow
        > {
  $$ItemCategoryCacheTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.itemCategoryCache.categoryId, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ItemCategoryCacheTableFilterComposer
    extends Composer<_$AppDatabase, $ItemCategoryCacheTable> {
  $$ItemCategoryCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemKey => $composableBuilder(
    column: $table.itemKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get item => $composableBuilder(
    column: $table.item,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurrences => $composableBuilder(
    column: $table.occurrences,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemCategoryCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemCategoryCacheTable> {
  $$ItemCategoryCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemKey => $composableBuilder(
    column: $table.itemKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get item => $composableBuilder(
    column: $table.item,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurrences => $composableBuilder(
    column: $table.occurrences,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemCategoryCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemCategoryCacheTable> {
  $$ItemCategoryCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemKey =>
      $composableBuilder(column: $table.itemKey, builder: (column) => column);

  GeneratedColumn<String> get item =>
      $composableBuilder(column: $table.item, builder: (column) => column);

  GeneratedColumn<int> get occurrences => $composableBuilder(
    column: $table.occurrences,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemCategoryCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemCategoryCacheTable,
          ItemCategoryCacheRow,
          $$ItemCategoryCacheTableFilterComposer,
          $$ItemCategoryCacheTableOrderingComposer,
          $$ItemCategoryCacheTableAnnotationComposer,
          $$ItemCategoryCacheTableCreateCompanionBuilder,
          $$ItemCategoryCacheTableUpdateCompanionBuilder,
          (ItemCategoryCacheRow, $$ItemCategoryCacheTableReferences),
          ItemCategoryCacheRow,
          PrefetchHooks Function({bool categoryId})
        > {
  $$ItemCategoryCacheTableTableManager(
    _$AppDatabase db,
    $ItemCategoryCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemCategoryCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemCategoryCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemCategoryCacheTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> itemKey = const Value.absent(),
                Value<String> item = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<int> occurrences = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemCategoryCacheCompanion(
                itemKey: itemKey,
                item: item,
                categoryId: categoryId,
                occurrences: occurrences,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemKey,
                required String item,
                required int categoryId,
                Value<int> occurrences = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ItemCategoryCacheCompanion.insert(
                itemKey: itemKey,
                item: item,
                categoryId: categoryId,
                occurrences: occurrences,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ItemCategoryCacheTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryId,
                                referencedTable:
                                    $$ItemCategoryCacheTableReferences
                                        ._categoryIdTable(db),
                                referencedColumn:
                                    $$ItemCategoryCacheTableReferences
                                        ._categoryIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ItemCategoryCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemCategoryCacheTable,
      ItemCategoryCacheRow,
      $$ItemCategoryCacheTableFilterComposer,
      $$ItemCategoryCacheTableOrderingComposer,
      $$ItemCategoryCacheTableAnnotationComposer,
      $$ItemCategoryCacheTableCreateCompanionBuilder,
      $$ItemCategoryCacheTableUpdateCompanionBuilder,
      (ItemCategoryCacheRow, $$ItemCategoryCacheTableReferences),
      ItemCategoryCacheRow,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$ConfigurationsTableCreateCompanionBuilder =
    ConfigurationsCompanion Function({
      Value<int> id,
      Value<bool> localAuthEnabled,
      Value<String?> authenticationType,
      Value<int> autoLockIntervalMinutes,
      Value<String?> cloudProvider,
      Value<String?> linkedCloudAccount,
      Value<bool> cloudTokenValid,
      Value<DateTime?> cloudLinkedAt,
      Value<bool> backupReminderEnabled,
      Value<int> reminderIntervalDays,
      Value<int> storageLimitMb,
      Value<bool> onboardingCompleted,
      Value<DateTime?> lastSyncedExportAt,
      Value<String> backupAvailability,
      Value<String> visualThemeMode,
    });
typedef $$ConfigurationsTableUpdateCompanionBuilder =
    ConfigurationsCompanion Function({
      Value<int> id,
      Value<bool> localAuthEnabled,
      Value<String?> authenticationType,
      Value<int> autoLockIntervalMinutes,
      Value<String?> cloudProvider,
      Value<String?> linkedCloudAccount,
      Value<bool> cloudTokenValid,
      Value<DateTime?> cloudLinkedAt,
      Value<bool> backupReminderEnabled,
      Value<int> reminderIntervalDays,
      Value<int> storageLimitMb,
      Value<bool> onboardingCompleted,
      Value<DateTime?> lastSyncedExportAt,
      Value<String> backupAvailability,
      Value<String> visualThemeMode,
    });

final class $$ConfigurationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ConfigurationsTable, ConfigurationRow> {
  $$ConfigurationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$BackupRecordsTable, List<BackupRecordRow>>
  _backupRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.backupRecords,
    aliasName: $_aliasNameGenerator(
      db.configurations.id,
      db.backupRecords.configurationId,
    ),
  );

  $$BackupRecordsTableProcessedTableManager get backupRecordsRefs {
    final manager = $$BackupRecordsTableTableManager(
      $_db,
      $_db.backupRecords,
    ).filter((f) => f.configurationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_backupRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ConfigurationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConfigurationsTable> {
  $$ConfigurationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get localAuthEnabled => $composableBuilder(
    column: $table.localAuthEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authenticationType => $composableBuilder(
    column: $table.authenticationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get autoLockIntervalMinutes => $composableBuilder(
    column: $table.autoLockIntervalMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudProvider => $composableBuilder(
    column: $table.cloudProvider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedCloudAccount => $composableBuilder(
    column: $table.linkedCloudAccount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cloudTokenValid => $composableBuilder(
    column: $table.cloudTokenValid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cloudLinkedAt => $composableBuilder(
    column: $table.cloudLinkedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get backupReminderEnabled => $composableBuilder(
    column: $table.backupReminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderIntervalDays => $composableBuilder(
    column: $table.reminderIntervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get storageLimitMb => $composableBuilder(
    column: $table.storageLimitMb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedExportAt => $composableBuilder(
    column: $table.lastSyncedExportAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backupAvailability => $composableBuilder(
    column: $table.backupAvailability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visualThemeMode => $composableBuilder(
    column: $table.visualThemeMode,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> backupRecordsRefs(
    Expression<bool> Function($$BackupRecordsTableFilterComposer f) f,
  ) {
    final $$BackupRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.backupRecords,
      getReferencedColumn: (t) => t.configurationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupRecordsTableFilterComposer(
            $db: $db,
            $table: $db.backupRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConfigurationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConfigurationsTable> {
  $$ConfigurationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get localAuthEnabled => $composableBuilder(
    column: $table.localAuthEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authenticationType => $composableBuilder(
    column: $table.authenticationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get autoLockIntervalMinutes => $composableBuilder(
    column: $table.autoLockIntervalMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudProvider => $composableBuilder(
    column: $table.cloudProvider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedCloudAccount => $composableBuilder(
    column: $table.linkedCloudAccount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cloudTokenValid => $composableBuilder(
    column: $table.cloudTokenValid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cloudLinkedAt => $composableBuilder(
    column: $table.cloudLinkedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get backupReminderEnabled => $composableBuilder(
    column: $table.backupReminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderIntervalDays => $composableBuilder(
    column: $table.reminderIntervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get storageLimitMb => $composableBuilder(
    column: $table.storageLimitMb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedExportAt => $composableBuilder(
    column: $table.lastSyncedExportAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backupAvailability => $composableBuilder(
    column: $table.backupAvailability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visualThemeMode => $composableBuilder(
    column: $table.visualThemeMode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConfigurationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConfigurationsTable> {
  $$ConfigurationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get localAuthEnabled => $composableBuilder(
    column: $table.localAuthEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authenticationType => $composableBuilder(
    column: $table.authenticationType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get autoLockIntervalMinutes => $composableBuilder(
    column: $table.autoLockIntervalMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cloudProvider => $composableBuilder(
    column: $table.cloudProvider,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedCloudAccount => $composableBuilder(
    column: $table.linkedCloudAccount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get cloudTokenValid => $composableBuilder(
    column: $table.cloudTokenValid,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cloudLinkedAt => $composableBuilder(
    column: $table.cloudLinkedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get backupReminderEnabled => $composableBuilder(
    column: $table.backupReminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderIntervalDays => $composableBuilder(
    column: $table.reminderIntervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get storageLimitMb => $composableBuilder(
    column: $table.storageLimitMb,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedExportAt => $composableBuilder(
    column: $table.lastSyncedExportAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backupAvailability => $composableBuilder(
    column: $table.backupAvailability,
    builder: (column) => column,
  );

  GeneratedColumn<String> get visualThemeMode => $composableBuilder(
    column: $table.visualThemeMode,
    builder: (column) => column,
  );

  Expression<T> backupRecordsRefs<T extends Object>(
    Expression<T> Function($$BackupRecordsTableAnnotationComposer a) f,
  ) {
    final $$BackupRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.backupRecords,
      getReferencedColumn: (t) => t.configurationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.backupRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConfigurationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConfigurationsTable,
          ConfigurationRow,
          $$ConfigurationsTableFilterComposer,
          $$ConfigurationsTableOrderingComposer,
          $$ConfigurationsTableAnnotationComposer,
          $$ConfigurationsTableCreateCompanionBuilder,
          $$ConfigurationsTableUpdateCompanionBuilder,
          (ConfigurationRow, $$ConfigurationsTableReferences),
          ConfigurationRow,
          PrefetchHooks Function({bool backupRecordsRefs})
        > {
  $$ConfigurationsTableTableManager(
    _$AppDatabase db,
    $ConfigurationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConfigurationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConfigurationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConfigurationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> localAuthEnabled = const Value.absent(),
                Value<String?> authenticationType = const Value.absent(),
                Value<int> autoLockIntervalMinutes = const Value.absent(),
                Value<String?> cloudProvider = const Value.absent(),
                Value<String?> linkedCloudAccount = const Value.absent(),
                Value<bool> cloudTokenValid = const Value.absent(),
                Value<DateTime?> cloudLinkedAt = const Value.absent(),
                Value<bool> backupReminderEnabled = const Value.absent(),
                Value<int> reminderIntervalDays = const Value.absent(),
                Value<int> storageLimitMb = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<DateTime?> lastSyncedExportAt = const Value.absent(),
                Value<String> backupAvailability = const Value.absent(),
                Value<String> visualThemeMode = const Value.absent(),
              }) => ConfigurationsCompanion(
                id: id,
                localAuthEnabled: localAuthEnabled,
                authenticationType: authenticationType,
                autoLockIntervalMinutes: autoLockIntervalMinutes,
                cloudProvider: cloudProvider,
                linkedCloudAccount: linkedCloudAccount,
                cloudTokenValid: cloudTokenValid,
                cloudLinkedAt: cloudLinkedAt,
                backupReminderEnabled: backupReminderEnabled,
                reminderIntervalDays: reminderIntervalDays,
                storageLimitMb: storageLimitMb,
                onboardingCompleted: onboardingCompleted,
                lastSyncedExportAt: lastSyncedExportAt,
                backupAvailability: backupAvailability,
                visualThemeMode: visualThemeMode,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> localAuthEnabled = const Value.absent(),
                Value<String?> authenticationType = const Value.absent(),
                Value<int> autoLockIntervalMinutes = const Value.absent(),
                Value<String?> cloudProvider = const Value.absent(),
                Value<String?> linkedCloudAccount = const Value.absent(),
                Value<bool> cloudTokenValid = const Value.absent(),
                Value<DateTime?> cloudLinkedAt = const Value.absent(),
                Value<bool> backupReminderEnabled = const Value.absent(),
                Value<int> reminderIntervalDays = const Value.absent(),
                Value<int> storageLimitMb = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<DateTime?> lastSyncedExportAt = const Value.absent(),
                Value<String> backupAvailability = const Value.absent(),
                Value<String> visualThemeMode = const Value.absent(),
              }) => ConfigurationsCompanion.insert(
                id: id,
                localAuthEnabled: localAuthEnabled,
                authenticationType: authenticationType,
                autoLockIntervalMinutes: autoLockIntervalMinutes,
                cloudProvider: cloudProvider,
                linkedCloudAccount: linkedCloudAccount,
                cloudTokenValid: cloudTokenValid,
                cloudLinkedAt: cloudLinkedAt,
                backupReminderEnabled: backupReminderEnabled,
                reminderIntervalDays: reminderIntervalDays,
                storageLimitMb: storageLimitMb,
                onboardingCompleted: onboardingCompleted,
                lastSyncedExportAt: lastSyncedExportAt,
                backupAvailability: backupAvailability,
                visualThemeMode: visualThemeMode,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConfigurationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({backupRecordsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (backupRecordsRefs) db.backupRecords,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (backupRecordsRefs)
                    await $_getPrefetchedData<
                      ConfigurationRow,
                      $ConfigurationsTable,
                      BackupRecordRow
                    >(
                      currentTable: table,
                      referencedTable: $$ConfigurationsTableReferences
                          ._backupRecordsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ConfigurationsTableReferences(
                            db,
                            table,
                            p0,
                          ).backupRecordsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.configurationId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ConfigurationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConfigurationsTable,
      ConfigurationRow,
      $$ConfigurationsTableFilterComposer,
      $$ConfigurationsTableOrderingComposer,
      $$ConfigurationsTableAnnotationComposer,
      $$ConfigurationsTableCreateCompanionBuilder,
      $$ConfigurationsTableUpdateCompanionBuilder,
      (ConfigurationRow, $$ConfigurationsTableReferences),
      ConfigurationRow,
      PrefetchHooks Function({bool backupRecordsRefs})
    >;
typedef $$BackupRecordsTableCreateCompanionBuilder =
    BackupRecordsCompanion Function({
      Value<int> id,
      required DateTime createdAt,
      required String status,
      Value<String> operation,
      Value<int> totalReceipts,
      Value<String?> errorDescription,
      Value<String?> cloudProvider,
      Value<String?> linkedCloudAccount,
      Value<String> availability,
      required int configurationId,
    });
typedef $$BackupRecordsTableUpdateCompanionBuilder =
    BackupRecordsCompanion Function({
      Value<int> id,
      Value<DateTime> createdAt,
      Value<String> status,
      Value<String> operation,
      Value<int> totalReceipts,
      Value<String?> errorDescription,
      Value<String?> cloudProvider,
      Value<String?> linkedCloudAccount,
      Value<String> availability,
      Value<int> configurationId,
    });

final class $$BackupRecordsTableReferences
    extends
        BaseReferences<_$AppDatabase, $BackupRecordsTable, BackupRecordRow> {
  $$BackupRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ConfigurationsTable _configurationIdTable(_$AppDatabase db) =>
      db.configurations.createAlias(
        $_aliasNameGenerator(
          db.backupRecords.configurationId,
          db.configurations.id,
        ),
      );

  $$ConfigurationsTableProcessedTableManager get configurationId {
    final $_column = $_itemColumn<int>('configuration_id')!;

    final manager = $$ConfigurationsTableTableManager(
      $_db,
      $_db.configurations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_configurationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BackupRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $BackupRecordsTable> {
  $$BackupRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalReceipts => $composableBuilder(
    column: $table.totalReceipts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorDescription => $composableBuilder(
    column: $table.errorDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudProvider => $composableBuilder(
    column: $table.cloudProvider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedCloudAccount => $composableBuilder(
    column: $table.linkedCloudAccount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => ColumnFilters(column),
  );

  $$ConfigurationsTableFilterComposer get configurationId {
    final $$ConfigurationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.configurationId,
      referencedTable: $db.configurations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConfigurationsTableFilterComposer(
            $db: $db,
            $table: $db.configurations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BackupRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $BackupRecordsTable> {
  $$BackupRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalReceipts => $composableBuilder(
    column: $table.totalReceipts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorDescription => $composableBuilder(
    column: $table.errorDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudProvider => $composableBuilder(
    column: $table.cloudProvider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedCloudAccount => $composableBuilder(
    column: $table.linkedCloudAccount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConfigurationsTableOrderingComposer get configurationId {
    final $$ConfigurationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.configurationId,
      referencedTable: $db.configurations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConfigurationsTableOrderingComposer(
            $db: $db,
            $table: $db.configurations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BackupRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BackupRecordsTable> {
  $$BackupRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<int> get totalReceipts => $composableBuilder(
    column: $table.totalReceipts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorDescription => $composableBuilder(
    column: $table.errorDescription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cloudProvider => $composableBuilder(
    column: $table.cloudProvider,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedCloudAccount => $composableBuilder(
    column: $table.linkedCloudAccount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => column,
  );

  $$ConfigurationsTableAnnotationComposer get configurationId {
    final $$ConfigurationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.configurationId,
      referencedTable: $db.configurations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConfigurationsTableAnnotationComposer(
            $db: $db,
            $table: $db.configurations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BackupRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BackupRecordsTable,
          BackupRecordRow,
          $$BackupRecordsTableFilterComposer,
          $$BackupRecordsTableOrderingComposer,
          $$BackupRecordsTableAnnotationComposer,
          $$BackupRecordsTableCreateCompanionBuilder,
          $$BackupRecordsTableUpdateCompanionBuilder,
          (BackupRecordRow, $$BackupRecordsTableReferences),
          BackupRecordRow,
          PrefetchHooks Function({bool configurationId})
        > {
  $$BackupRecordsTableTableManager(_$AppDatabase db, $BackupRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BackupRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BackupRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BackupRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<int> totalReceipts = const Value.absent(),
                Value<String?> errorDescription = const Value.absent(),
                Value<String?> cloudProvider = const Value.absent(),
                Value<String?> linkedCloudAccount = const Value.absent(),
                Value<String> availability = const Value.absent(),
                Value<int> configurationId = const Value.absent(),
              }) => BackupRecordsCompanion(
                id: id,
                createdAt: createdAt,
                status: status,
                operation: operation,
                totalReceipts: totalReceipts,
                errorDescription: errorDescription,
                cloudProvider: cloudProvider,
                linkedCloudAccount: linkedCloudAccount,
                availability: availability,
                configurationId: configurationId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime createdAt,
                required String status,
                Value<String> operation = const Value.absent(),
                Value<int> totalReceipts = const Value.absent(),
                Value<String?> errorDescription = const Value.absent(),
                Value<String?> cloudProvider = const Value.absent(),
                Value<String?> linkedCloudAccount = const Value.absent(),
                Value<String> availability = const Value.absent(),
                required int configurationId,
              }) => BackupRecordsCompanion.insert(
                id: id,
                createdAt: createdAt,
                status: status,
                operation: operation,
                totalReceipts: totalReceipts,
                errorDescription: errorDescription,
                cloudProvider: cloudProvider,
                linkedCloudAccount: linkedCloudAccount,
                availability: availability,
                configurationId: configurationId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BackupRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({configurationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (configurationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.configurationId,
                                referencedTable: $$BackupRecordsTableReferences
                                    ._configurationIdTable(db),
                                referencedColumn: $$BackupRecordsTableReferences
                                    ._configurationIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BackupRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BackupRecordsTable,
      BackupRecordRow,
      $$BackupRecordsTableFilterComposer,
      $$BackupRecordsTableOrderingComposer,
      $$BackupRecordsTableAnnotationComposer,
      $$BackupRecordsTableCreateCompanionBuilder,
      $$BackupRecordsTableUpdateCompanionBuilder,
      (BackupRecordRow, $$BackupRecordsTableReferences),
      BackupRecordRow,
      PrefetchHooks Function({bool configurationId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db, _db.receipts);
  $$ExtractedDataTableTableTableManager get extractedDataTable =>
      $$ExtractedDataTableTableTableManager(_db, _db.extractedDataTable);
  $$EmbeddingsTableTableManager get embeddings =>
      $$EmbeddingsTableTableManager(_db, _db.embeddings);
  $$CnpjCacheTableTableManager get cnpjCache =>
      $$CnpjCacheTableTableManager(_db, _db.cnpjCache);
  $$EstablishmentCategoryCacheTableTableManager
  get establishmentCategoryCache =>
      $$EstablishmentCategoryCacheTableTableManager(
        _db,
        _db.establishmentCategoryCache,
      );
  $$ItemCategoryCacheTableTableManager get itemCategoryCache =>
      $$ItemCategoryCacheTableTableManager(_db, _db.itemCategoryCache);
  $$ConfigurationsTableTableManager get configurations =>
      $$ConfigurationsTableTableManager(_db, _db.configurations);
  $$BackupRecordsTableTableManager get backupRecords =>
      $$BackupRecordsTableTableManager(_db, _db.backupRecords);
}
