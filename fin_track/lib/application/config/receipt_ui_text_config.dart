part of 'app_config.dart';

class ReceiptFilesTextConfig {
  const ReceiptFilesTextConfig({
    required this.fileSaved,
    required this.filesSaved,
    required this.fileSaveFailed,
    required this.filesSaveFailed,
  });

  final String fileSaved;
  final String filesSaved;
  final String fileSaveFailed;
  final String filesSaveFailed;

  ReceiptFilesTextConfig withLegacy(Map<String, Object?> json) {
    return ReceiptFilesTextConfig(
      fileSaved: _string(json['fileSaved'], fileSaved),
      filesSaved: _string(json['filesSaved'], filesSaved),
      fileSaveFailed: _string(json['fileSaveFailed'], fileSaveFailed),
      filesSaveFailed: _string(json['filesSaveFailed'], filesSaveFailed),
    );
  }

  factory ReceiptFilesTextConfig.fromJson(
    Map<String, Object?> json,
    ReceiptFilesTextConfig fallback,
  ) {
    return ReceiptFilesTextConfig(
      fileSaved: _string(json['fileSaved'], fallback.fileSaved),
      filesSaved: _string(json['filesSaved'], fallback.filesSaved),
      fileSaveFailed: _string(json['fileSaveFailed'], fallback.fileSaveFailed),
      filesSaveFailed: _string(
        json['filesSaveFailed'],
        fallback.filesSaveFailed,
      ),
    );
  }
}

class ReceiptsTextConfig {
  const ReceiptsTextConfig({
    required this.confirmationLoading,
    required this.confirmationNotFound,
    required this.confirmationTitle,
    required this.lowExtractionConfidence,
    required this.lowOcrConfidence,
    required this.saveFailed,
    required this.saved,
    required this.transactionDate,
    required this.paymentMethodForm,
    required this.selectTransactionDate,
    required this.clearDate,
    required this.selectDate,
    required this.confirm,
    required this.invalidDate,
    required this.dateOutOfRange,
    required this.pendingFieldsTitle,
    required this.pendingFieldsMessage,
    required this.review,
    required this.discardTitle,
    required this.discardMessage,
    required this.discard,
    required this.ocrResultTitle,
    required this.emptyOcrText,
    required this.ocrTextTab,
    required this.ocrStructuredTab,
    required this.searchHint,
    required this.searchHelper,
    required this.diagnoseSemanticSearch,
    required this.clearSearch,
    required this.noImportFiles,
    required this.importFailed,
    required this.diagnoseFailed,
    required this.files,
    required this.deleted,
    required this.deleteMany,
    required this.deleteFailed,
    required this.deletingSelection,
    required this.deletingSelectionMessage,
    required this.moreOptions,
    required this.shareSelected,
    required this.deleteSelected,
    required this.selectReceipts,
    required this.importReceipt,
    required this.filters,
    required this.loadingReceipts,
    required this.loadReceiptsFailed,
    required this.loadMoreReceiptsFailed,
    required this.searchingReceipts,
    required this.searchFailed,
    required this.noSearchResults,
    required this.noReceipts,
    required this.noSearchResultsMessage,
    required this.noReceiptsMessage,
    required this.selectedSingular,
    required this.selectedPlural,
    required this.all,
    required this.allCategories,
    required this.category,
    required this.withoutCategory,
    required this.expenses,
    required this.incomes,
    required this.period,
    required this.selectRange,
    required this.clearPeriod,
    required this.choosePeriod,
    required this.start,
    required this.end,
    required this.invalidRange,
    required this.invalidRangeOrder,
    required this.deleteSelectionTitleSingular,
    required this.deleteSelectionTitlePlural,
    required this.deleteSelectionMessage,
  });

  final String confirmationLoading;
  final String confirmationNotFound;
  final String confirmationTitle;
  final String lowExtractionConfidence;
  final String lowOcrConfidence;
  final String saveFailed;
  final String saved;
  final String transactionDate;
  final String paymentMethodForm;
  final String selectTransactionDate;
  final String clearDate;
  final String selectDate;
  final String confirm;
  final String invalidDate;
  final String dateOutOfRange;
  final String pendingFieldsTitle;
  final String pendingFieldsMessage;
  final String review;
  final String discardTitle;
  final String discardMessage;
  final String discard;
  final String ocrResultTitle;
  final String emptyOcrText;
  final String ocrTextTab;
  final String ocrStructuredTab;
  final String searchHint;
  final String searchHelper;
  final String diagnoseSemanticSearch;
  final String clearSearch;
  final String noImportFiles;
  final String importFailed;
  final String diagnoseFailed;
  final ReceiptFilesTextConfig files;
  final String deleted;
  final String deleteMany;
  final String deleteFailed;
  final String deletingSelection;
  final String deletingSelectionMessage;
  final String moreOptions;
  final String shareSelected;
  final String deleteSelected;
  final String selectReceipts;
  final String importReceipt;
  final String filters;
  final String loadingReceipts;
  final String loadReceiptsFailed;
  final String loadMoreReceiptsFailed;
  final String searchingReceipts;
  final String searchFailed;
  final String noSearchResults;
  final String noReceipts;
  final String noSearchResultsMessage;
  final String noReceiptsMessage;
  final String selectedSingular;
  final String selectedPlural;
  final String all;
  final String allCategories;
  final String category;
  final String withoutCategory;
  final String expenses;
  final String incomes;
  final String period;
  final String selectRange;
  final String clearPeriod;
  final String choosePeriod;
  final String start;
  final String end;
  final String invalidRange;
  final String invalidRangeOrder;
  final String deleteSelectionTitleSingular;
  final String deleteSelectionTitlePlural;
  final String deleteSelectionMessage;

  String pendingFieldsMessageFor(String fields) {
    return pendingFieldsMessage.replaceAll('{fields}', fields);
  }

  String deleteManyFor(int total) {
    return deleteMany.replaceAll('{total}', '$total');
  }

  String deleteSelectionTitleFor(int total) {
    return (total == 1
            ? deleteSelectionTitleSingular
            : deleteSelectionTitlePlural)
        .replaceAll('{total}', '$total');
  }

  factory ReceiptsTextConfig.fromJson(
    Map<String, Object?> json,
    ReceiptsTextConfig fallback,
  ) {
    return ReceiptsTextConfig(
      confirmationLoading: _string(
        json['confirmationLoading'],
        fallback.confirmationLoading,
      ),
      confirmationNotFound: _string(
        json['confirmationNotFound'],
        fallback.confirmationNotFound,
      ),
      confirmationTitle: _string(
        json['confirmationTitle'],
        fallback.confirmationTitle,
      ),
      lowExtractionConfidence: _string(
        json['lowExtractionConfidence'],
        fallback.lowExtractionConfidence,
      ),
      lowOcrConfidence: _string(
        json['lowOcrConfidence'],
        fallback.lowOcrConfidence,
      ),
      saveFailed: _string(json['saveFailed'], fallback.saveFailed),
      saved: _string(json['saved'], fallback.saved),
      transactionDate: _string(
        json['transactionDate'],
        fallback.transactionDate,
      ),
      paymentMethodForm: _string(
        json['paymentMethodForm'],
        fallback.paymentMethodForm,
      ),
      selectTransactionDate: _string(
        json['selectTransactionDate'],
        fallback.selectTransactionDate,
      ),
      clearDate: _string(json['clearDate'], fallback.clearDate),
      selectDate: _string(json['selectDate'], fallback.selectDate),
      confirm: _string(json['confirm'], fallback.confirm),
      invalidDate: _string(json['invalidDate'], fallback.invalidDate),
      dateOutOfRange: _string(json['dateOutOfRange'], fallback.dateOutOfRange),
      pendingFieldsTitle: _string(
        json['pendingFieldsTitle'],
        fallback.pendingFieldsTitle,
      ),
      pendingFieldsMessage: _string(
        json['pendingFieldsMessage'],
        fallback.pendingFieldsMessage,
      ),
      review: _string(json['review'], fallback.review),
      discardTitle: _string(json['discardTitle'], fallback.discardTitle),
      discardMessage: _string(json['discardMessage'], fallback.discardMessage),
      discard: _string(json['discard'], fallback.discard),
      ocrResultTitle: _string(json['ocrResultTitle'], fallback.ocrResultTitle),
      emptyOcrText: _string(json['emptyOcrText'], fallback.emptyOcrText),
      ocrTextTab: _string(json['ocrTextTab'], fallback.ocrTextTab),
      ocrStructuredTab: _string(
        json['ocrStructuredTab'],
        fallback.ocrStructuredTab,
      ),
      searchHint: _string(json['searchHint'], fallback.searchHint),
      searchHelper: _string(json['searchHelper'], fallback.searchHelper),
      diagnoseSemanticSearch: _string(
        json['diagnoseSemanticSearch'],
        fallback.diagnoseSemanticSearch,
      ),
      clearSearch: _string(json['clearSearch'], fallback.clearSearch),
      noImportFiles: _string(json['noImportFiles'], fallback.noImportFiles),
      importFailed: _string(json['importFailed'], fallback.importFailed),
      diagnoseFailed: _string(json['diagnoseFailed'], fallback.diagnoseFailed),
      files: ReceiptFilesTextConfig.fromJson(
        _map(json['files']),
        fallback.files,
      ).withLegacy(json),
      deleted: _string(json['deleted'], fallback.deleted),
      deleteMany: _string(json['deleteMany'], fallback.deleteMany),
      deleteFailed: _string(json['deleteFailed'], fallback.deleteFailed),
      deletingSelection: _string(
        json['deletingSelection'],
        fallback.deletingSelection,
      ),
      deletingSelectionMessage: _string(
        json['deletingSelectionMessage'],
        fallback.deletingSelectionMessage,
      ),
      moreOptions: _string(json['moreOptions'], fallback.moreOptions),
      shareSelected: _string(json['shareSelected'], fallback.shareSelected),
      deleteSelected: _string(json['deleteSelected'], fallback.deleteSelected),
      selectReceipts: _string(json['selectReceipts'], fallback.selectReceipts),
      importReceipt: _string(json['importReceipt'], fallback.importReceipt),
      filters: _string(json['filters'], fallback.filters),
      loadingReceipts: _string(
        json['loadingReceipts'],
        fallback.loadingReceipts,
      ),
      loadReceiptsFailed: _string(
        json['loadReceiptsFailed'],
        fallback.loadReceiptsFailed,
      ),
      loadMoreReceiptsFailed: _string(
        json['loadMoreReceiptsFailed'],
        fallback.loadMoreReceiptsFailed,
      ),
      searchingReceipts: _string(
        json['searchingReceipts'],
        fallback.searchingReceipts,
      ),
      searchFailed: _string(json['searchFailed'], fallback.searchFailed),
      noSearchResults: _string(
        json['noSearchResults'],
        fallback.noSearchResults,
      ),
      noReceipts: _string(json['noReceipts'], fallback.noReceipts),
      noSearchResultsMessage: _string(
        json['noSearchResultsMessage'],
        fallback.noSearchResultsMessage,
      ),
      noReceiptsMessage: _string(
        json['noReceiptsMessage'],
        fallback.noReceiptsMessage,
      ),
      selectedSingular: _string(
        json['selectedSingular'],
        fallback.selectedSingular,
      ),
      selectedPlural: _string(json['selectedPlural'], fallback.selectedPlural),
      all: _string(json['all'], fallback.all),
      allCategories: _string(json['allCategories'], fallback.allCategories),
      category: _string(json['category'], fallback.category),
      withoutCategory: _string(
        json['withoutCategory'],
        fallback.withoutCategory,
      ),
      expenses: _string(json['expenses'], fallback.expenses),
      incomes: _string(json['incomes'], fallback.incomes),
      period: _string(json['period'], fallback.period),
      selectRange: _string(json['selectRange'], fallback.selectRange),
      clearPeriod: _string(json['clearPeriod'], fallback.clearPeriod),
      choosePeriod: _string(json['choosePeriod'], fallback.choosePeriod),
      start: _string(json['start'], fallback.start),
      end: _string(json['end'], fallback.end),
      invalidRange: _string(json['invalidRange'], fallback.invalidRange),
      invalidRangeOrder: _string(
        json['invalidRangeOrder'],
        fallback.invalidRangeOrder,
      ),
      deleteSelectionTitleSingular: _string(
        json['deleteSelectionTitleSingular'],
        fallback.deleteSelectionTitleSingular,
      ),
      deleteSelectionTitlePlural: _string(
        json['deleteSelectionTitlePlural'],
        fallback.deleteSelectionTitlePlural,
      ),
      deleteSelectionMessage: _string(
        json['deleteSelectionMessage'],
        fallback.deleteSelectionMessage,
      ),
    );
  }
}
