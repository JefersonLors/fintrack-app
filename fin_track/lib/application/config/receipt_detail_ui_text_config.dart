part of 'app_config.dart';

class ReceiptDetailTextConfig {
  const ReceiptDetailTextConfig({
    required this.title,
    required this.moreOptionsTooltip,
    required this.loading,
    required this.loadError,
    required this.summaryTitle,
    required this.dataTitle,
    required this.establishment,
    required this.value,
    required this.nature,
    required this.expense,
    required this.income,
    required this.date,
    required this.paymentMethod,
    required this.unidentified,
    required this.receiptType,
    required this.category,
    required this.withoutCategory,
    required this.synced,
    required this.local,
    required this.deleteTitle,
    required this.deleteMessage,
    required this.deleted,
  });

  final String title;
  final String moreOptionsTooltip;
  final String loading;
  final String loadError;
  final String summaryTitle;
  final String dataTitle;
  final String establishment;
  final String value;
  final String nature;
  final String expense;
  final String income;
  final String date;
  final String paymentMethod;
  final String unidentified;
  final String receiptType;
  final String category;
  final String withoutCategory;
  final String synced;
  final String local;
  final String deleteTitle;
  final String deleteMessage;
  final String deleted;

  factory ReceiptDetailTextConfig.fromJson(
    Map<String, Object?> json,
    ReceiptDetailTextConfig fallback,
  ) {
    return ReceiptDetailTextConfig(
      title: _string(json['title'], fallback.title),
      moreOptionsTooltip: _string(
        json['moreOptionsTooltip'],
        fallback.moreOptionsTooltip,
      ),
      loading: _string(json['loading'], fallback.loading),
      loadError: _string(json['loadError'], fallback.loadError),
      summaryTitle: _string(json['summaryTitle'], fallback.summaryTitle),
      dataTitle: _string(json['dataTitle'], fallback.dataTitle),
      establishment: _string(json['establishment'], fallback.establishment),
      value: _string(json['value'], fallback.value),
      nature: _string(json['nature'], fallback.nature),
      expense: _string(json['expense'], fallback.expense),
      income: _string(json['income'], fallback.income),
      date: _string(json['date'], fallback.date),
      paymentMethod: _string(json['paymentMethod'], fallback.paymentMethod),
      unidentified: _string(json['unidentified'], fallback.unidentified),
      receiptType: _string(json['receiptType'], fallback.receiptType),
      category: _string(json['category'], fallback.category),
      withoutCategory: _string(
        json['withoutCategory'],
        fallback.withoutCategory,
      ),
      synced: _string(json['synced'], fallback.synced),
      local: _string(json['local'], fallback.local),
      deleteTitle: _string(json['deleteTitle'], fallback.deleteTitle),
      deleteMessage: _string(json['deleteMessage'], fallback.deleteMessage),
      deleted: _string(json['deleted'], fallback.deleted),
    );
  }
}
