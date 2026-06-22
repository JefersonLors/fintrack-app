import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

import '../../../domain/entities/receipt.dart';
import '../../../domain/entities/extracted_data.dart';
import '../../../domain/entities/embedding.dart';
import '../../../domain/infrastructure/i_embedding_service.dart';
import '../../../domain/value_objects/embedding_vector.dart';

class ReceiptSemanticIndexer {
  ReceiptSemanticIndexer({required IEmbeddingService embeddings})
    : _embeddings = embeddings;

  static const semanticEmbeddingVersion =
      'distiluse-base-multilingual-cased-v2:field-composite-v3';
  static const _signaturePrefix = 'semantic-signature=';

  static const _establishmentWeight = 0.35;
  static const _categoriesWeight = 0.30;
  static const _contextWeight = 0.25;
  static const _paymentWeight = 0.10;

  final IEmbeddingService _embeddings;

  Future<Embedding> generateEmbedding(Receipt receipt) async {
    final vector = await _generateCompositeVector(_semanticFields(receipt));
    return Embedding(
      id: receipt.embedding?.id ?? 0,
      receiptId: receipt.id,
      vector: _serializeVector(vector.vector),
      model: _modelWithSignature(vector.model, receipt),
      dimension: vector.dimension,
      generatedAt: DateTime.now(),
    );
  }

  Future<EmbeddingVector> generateQueryEmbedding(String query) async {
    final vector = await _embeddings.generate(query);
    return EmbeddingVector(
      vector: [
        ..._weight(vector.vector, _establishmentWeight),
        ..._weight(vector.vector, _categoriesWeight),
        ..._weight(vector.vector, _contextWeight),
        ..._weight(vector.vector, _paymentWeight),
      ],
      model: _modelWithVersion(vector.model),
      dimension: vector.dimension * 4,
    );
  }

  String semanticText(Receipt receipt) {
    return _semanticFields(
      receipt,
    ).map((field) => field.text).where((text) => text.isNotEmpty).join('\n');
  }

  List<_SemanticField> _semanticFields(Receipt receipt) {
    final data = receipt.extractedData;
    final categories = _categoryText(receipt);
    final items = data?.items.join(' ').trim() ?? '';
    final establishment = data?.establishment?.trim();
    final context = _contextText(receipt);
    final payment = _paymentText(receipt);

    return [
      _SemanticField(
        text: _establishmentText(data, establishment),
        weight: _establishmentWeight,
      ),
      _SemanticField(
        text: [categories, items].where((text) => text.isNotEmpty).join(' '),
        weight: _categoriesWeight,
      ),
      _SemanticField(text: context, weight: _contextWeight),
      _SemanticField(text: payment, weight: _paymentWeight),
    ];
  }

  bool needsReindex(Receipt receipt) {
    final embedding = receipt.embedding;
    return embedding == null ||
        !embedding.model.contains(semanticEmbeddingVersion) ||
        !embedding.model.contains(_modelSignature(receipt));
  }

  bool hasCurrentSemanticEmbedding(Receipt receipt) {
    return !needsReindex(receipt);
  }

  String semanticSignature(Receipt receipt) {
    final data = receipt.extractedData;
    final category = receipt.category == null
        ? ''
        : [
            _normalize(receipt.category!.name),
            _normalize(receipt.category!.description ?? ''),
          ].join(':');
    final fields = [
      _normalize(_establishmentText(data, data?.establishment)),
      _normalize(data?.items.join(' ') ?? ''),
      category,
      _normalize(_contextText(receipt)),
      _normalize(_paymentText(receipt)),
    ];
    return sha256.convert(utf8.encode(fields.join('\n'))).toString();
  }

  Uint8List _serializeVector(List<double> vector) {
    final data = ByteData(vector.length * 8);
    for (var i = 0; i < vector.length; i++) {
      data.setFloat64(i * 8, vector[i], Endian.little);
    }
    return data.buffer.asUint8List();
  }

  String _categoryText(Receipt receipt) {
    final category = receipt.category;
    if (category == null) {
      return '';
    }
    final name = category.name.trim();
    final description = category.description?.trim();
    return [
      if (name.isNotEmpty) name,
      if (description != null && description.isNotEmpty) description,
    ].join(' - ');
  }

  String _establishmentText(ExtractedData? data, String? establishment) {
    return [
      establishment ?? '',
      data?.issuerTradeName ?? '',
      data?.issuerLegalName ?? '',
    ].where((text) => text.trim().isNotEmpty).join(' ');
  }

  String _contextText(Receipt receipt) {
    final data = receipt.extractedData;
    return [
      'type ${receipt.type.label}',
      receipt.expense
          ? 'despesa saida gasto pagamento'
          : 'receita entrada recebimento',
      if (data?.amount != null) ..._amountTexts(data!.amount!),
      if (data?.transactionDate != null) ..._dateTexts(data!.transactionDate!),
      data?.issuerCnpj == null ? '' : 'cnpj ${data!.issuerCnpj}',
      data?.accessKey == null ? '' : 'chave fiscal ${data!.accessKey}',
      data?.documentNumber == null
          ? ''
          : 'documento fiscal numero ${data!.documentNumber}',
      data?.documentSeries == null ? '' : 'serie ${data!.documentSeries}',
      data?.documentState == null ? '' : 'state ${data!.documentState}',
      data?.fiscalCnaeDescription ?? '',
      data?.issuerCity ?? '',
      data?.issuerState ?? '',
      _ocrSummary(receipt.extractedContent),
    ].where((text) => text.trim().isNotEmpty).join(' ');
  }

  String _paymentText(Receipt receipt) {
    final method = receipt.extractedData?.paymentMethod?.trim();
    return [
      if (method != null && method.isNotEmpty) 'pagamento $method',
      if (method != null && method.isNotEmpty) method,
      receipt.type == ReceiptType.pixReceipt ? 'pix transferencia' : '',
      receipt.expense ? 'pago pagamento' : 'recebido recebimento',
    ].where((text) => text.trim().isNotEmpty).join(' ');
  }

  List<String> _amountTexts(double amount) {
    final formattedAmount = amount.toStringAsFixed(2).replaceAll('.', ',');
    final range = switch (amount) {
      < 20 => 'amount pequeno baixo ate 20',
      < 100 => 'amount medio entre 20 e 100',
      < 500 => 'amount alto entre 100 e 500',
      _ => 'amount muito alto acima de 500',
    };
    return ['amount $formattedAmount', range];
  }

  List<String> _dateTexts(DateTime data) {
    final month = _months[data.month - 1];
    final day = data.day.toString().padLeft(2, '0');
    final monthNumber = data.month.toString().padLeft(2, '0');
    final year = data.year.toString();
    return [
      'data $day/$monthNumber/$year',
      'mes $month',
      'ano $year',
      'periodo ${data.year}-$monthNumber',
    ];
  }

  String _ocrSummary(String text) {
    final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 360) {
      return normalized;
    }
    return normalized.substring(0, 360);
  }

  Future<EmbeddingVector> _generateCompositeVector(
    List<_SemanticField> fields,
  ) async {
    final vectors = <List<double>?>[];
    EmbeddingVector? reference;

    for (final field in fields) {
      if (field.text.trim().isEmpty) {
        vectors.add(null);
        continue;
      }
      final vector = await _embeddings.generate(field.text);
      reference ??= vector;
      vectors.add(vector.vector);
    }

    final base = reference;
    if (base == null) {
      final vector = await _embeddings.generate('');
      final composite = <double>[];
      for (final field in fields) {
        composite.addAll(_weight(vector.vector, field.weight));
      }
      return EmbeddingVector(
        vector: composite,
        model: _modelWithVersion(vector.model),
        dimension: composite.length,
      );
    }

    final baseDimension = base.vector.length;
    final composite = <double>[];
    for (var i = 0; i < fields.length; i++) {
      final vector = vectors[i];
      final normalized = vector == null || vector.length != baseDimension
          ? List<double>.filled(baseDimension, 0)
          : vector;
      composite.addAll(_weight(normalized, fields[i].weight));
    }

    return EmbeddingVector(
      vector: composite,
      model: _modelWithVersion(base.model),
      dimension: composite.length,
    );
  }

  List<double> _weight(List<double> vector, double weight) {
    final scale = math.sqrt(weight);
    return [for (final amount in vector) amount * scale];
  }

  String _modelWithVersion(String model) {
    return model.contains(semanticEmbeddingVersion)
        ? model
        : '$model:$semanticEmbeddingVersion';
  }

  String _modelWithSignature(String model, Receipt receipt) {
    final modelWithVersion = _modelWithVersion(model);
    final signature = _modelSignature(receipt);
    return modelWithVersion.contains(signature)
        ? modelWithVersion
        : '$modelWithVersion:$signature';
  }

  String _modelSignature(Receipt receipt) {
    return '$_signaturePrefix${semanticSignature(receipt)}';
  }

  String _normalize(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static const _months = [
    'janeiro',
    'fevereiro',
    'marco',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
}

class _SemanticField {
  const _SemanticField({required this.text, required this.weight});

  final String text;
  final double weight;
}
