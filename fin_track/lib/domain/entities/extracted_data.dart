import '../value_objects/establishment_name.dart';

class ExtractedData {
  const ExtractedData({
    required this.id,
    required this.receiptId,
    this.amount,
    this.transactionDate,
    this.establishment,
    this.items = const <String>[],
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

  final int id;
  final int receiptId;
  final double? amount;
  final DateTime? transactionDate;
  final String? establishment;
  final List<String> items;
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
  final Map<String, Object?>? qualityMetadata;

  ExtractedData copyWith({
    int? id,
    int? receiptId,
    double? amount,
    DateTime? transactionDate,
    String? establishment,
    List<String>? items,
    String? paymentMethod,
    String? issuerCnpj,
    String? accessKey,
    String? urlQrCode,
    String? documentNumber,
    String? documentSeries,
    String? documentState,
    String? issuerLegalName,
    String? issuerTradeName,
    String? fiscalCnaeDescription,
    String? issuerCity,
    String? issuerState,
    double? ocrConfidence,
    String? extractionParser,
    double? extractionConfidence,
    double? valueConfidence,
    double? dateConfidence,
    double? establishmentConfidence,
    double? paymentMethodConfidence,
    Map<String, Object?>? qualityMetadata,
  }) {
    return ExtractedData(
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

  ExtractedData withNormalizedEstablishment() {
    final normalized = normalizeEstablishmentName(establishment);
    if (normalized == establishment) {
      return this;
    }
    return ExtractedData(
      id: id,
      receiptId: receiptId,
      amount: amount,
      transactionDate: transactionDate,
      establishment: normalized,
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
    );
  }
}
