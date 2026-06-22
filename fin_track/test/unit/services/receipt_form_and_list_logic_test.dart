import 'dart:io';

import 'package:fin_track/domain/entities/category.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/entities/extracted_data.dart';
import 'package:fin_track/domain/value_objects/receipt_filter.dart';
import 'package:fin_track/presentation/receipts/receipt_form_helpers.dart';
import 'package:fin_track/presentation/receipts/receipt_list_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('receipt form helpers', () {
    test('identifies pending fields when required fields are missing', () {
      final completeReceipt = _receipt(category: _category());
      final incompleteReceipt = _receipt(
        category: null,
        extractedData: const ExtractedData(
          id: 1,
          receiptId: 1,
          establishment: ' ',
        ),
      );

      expect(receiptPendingFields(completeReceipt), isEmpty);
      expect(receiptPendingFields(incompleteReceipt), [
        'valor',
        'data',
        'estabelecimento',
        'categoria',
      ]);
      expect(formatPendingFieldsList(['valor']), 'valor');
      expect(
        formatPendingFieldsList(['valor', 'data', 'categoria']),
        'valor, data e categoria',
      );
    });

    test('normalizes values when editable fields vary', () {
      expect(parseEditableCurrencyValue(null), isNull);
      expect(parseEditableCurrencyValue(''), isNull);
      expect(parseEditableCurrencyValue('1.234,56'), 1234.56);
      expect(parseEditableCurrencyValue('42.5'), 42.5);
      expect(parseEditableCurrencyValue('abc'), isNull);
      expect(formatEditableCurrencyValue(null), '');
      expect(formatEditableCurrencyValue(1234.56), '1.234,56');
      expect(formatDateField(null), '');
      expect(formatDateField(DateTime(2026, 5, 24)), '24/05/2026');
    });

    test('identifies images when type or extension indicate receipt', () {
      expect(looksLikeReceiptImage('image/png', 'file.bin'), isTrue);
      expect(looksLikeReceiptImage('application/pdf', 'foto.HEIC'), isTrue);
      expect(looksLikeReceiptImage('text/plain', 'nota.txt'), isFalse);
      expect(fileNameFromPath(r'C:\temp\Cupom Fiscal.pdf'), 'Cupom Fiscal.pdf');
      expect(
        stagingFileName(7, '/tmp/Cupom Fiscal (1).pdf'),
        'item_007_Cupom_Fiscal_1_.pdf',
      );
      expect(looksLikeTemporaryImport('/tmp/shared_imports/item.pdf'), isTrue);
      expect(looksLikeTemporaryImport('/tmp/manual/item.pdf'), isFalse);
    });

    test('cleans stagings when old directories exist', () async {
      final base = await Directory.systemTemp.createTemp(
        'fintrack_staging_test_',
      );
      final oldDirectory = await Directory('${base.path}/old').create();
      final recentDirectory = await Directory('${base.path}/new').create();
      final plainFile = File('${base.path}/file.txt')..writeAsStringSync('x');
      await Process.run('touch', ['-d', '2 days ago', oldDirectory.path]);

      await cleanOldStagingDirectories(base);

      expect(await oldDirectory.exists(), isFalse);
      expect(await recentDirectory.exists(), isTrue);
      expect(await plainFile.exists(), isTrue);
      await deleteDirectorySilently(base);
      await deleteDirectorySilently(Directory('${base.path}/missing'));
      expect(await base.exists(), isFalse);
    });
  });

  group('receipts list logic', () {
    test('generates labels when advanced filters change count', () {
      const emptyFilter = ReceiptFilter();
      final advancedFilter = ReceiptFilter(
        categoryId: 1,
        startDate: DateTime(2026, 5, 1),
      );

      expect(
        hasAdvancedReceiptFilter(
          categoryId: null,
          type: null,
          expense: null,
          startDate: null,
          endDate: null,
        ),
        isFalse,
      );
      expect(
        hasAdvancedReceiptFilter(
          categoryId: null,
          withoutCategory: true,
          type: null,
          expense: null,
          startDate: null,
          endDate: null,
        ),
        isTrue,
      );
      expect(
        receiptResultCountLabel(total: 1, filter: emptyFilter, searching: true),
        '1 comprovante encontrado',
      );
      expect(
        receiptResultCountLabel(
          total: 2,
          filter: emptyFilter,
          searching: false,
        ),
        '2 comprovantes cadastrados',
      );
      expect(
        receiptResultCountLabel(
          total: 2,
          filter: advancedFilter,
          searching: false,
        ),
        '2 comprovantes no filtro atual',
      );
    });

    test('filters receipts when category nature type and period change', () {
      final homeCategory = _category(id: 2, name: 'Casa');
      final homeReceipt = _receipt(id: 1, category: homeCategory);
      final incomeReceipt = _receipt(
        id: 2,
        isExpense: false,
        category: null,
        data: DateTime(2026, 5, 28),
      );
      final oldReceipt = _receipt(
        id: 3,
        category: homeCategory,
        data: DateTime(2026, 4, 1),
      );
      final receipts = [homeReceipt, incomeReceipt, oldReceipt];

      expect(
        applyAdvancedReceiptFilters(
          receipts,
          const ReceiptFilter(withoutCategory: true),
        ),
        [incomeReceipt],
      );
      expect(
        applyAdvancedReceiptFilters(
          receipts,
          ReceiptFilter(categoryId: homeCategory.id),
        ),
        [homeReceipt, oldReceipt],
      );
      expect(
        applyAdvancedReceiptFilters(
          receipts,
          const ReceiptFilter(expense: false),
        ),
        [incomeReceipt],
      );
      expect(
        applyAdvancedReceiptFilters(
          receipts,
          ReceiptFilter(
            type: ReceiptType.receipt,
            startDate: DateTime(2026, 5, 1),
            endDate: DateTime(2026, 5, 31, 23, 59),
          ),
        ),
        [homeReceipt, incomeReceipt],
      );
    });

    test('sorts receipts when criterion and direction change', () {
      final undatedReceipt = _receipt(
        id: 1,
        extractedData: const ExtractedData(id: 1, receiptId: 1),
      );
      final cheapReceipt = _receipt(id: 2, value: 10, establishment: 'Beta');
      final expensiveReceipt = _receipt(
        id: 3,
        value: 20,
        isExpense: false,
        establishment: 'Alfa',
        data: DateTime(2026, 5, 30),
      );

      expect(
        sortReceipts(
          [undatedReceipt, cheapReceipt, expensiveReceipt],
          ReceiptSort.date,
          SortDirection.ascending,
        ).map((item) => item.id),
        [cheapReceipt.id, expensiveReceipt.id, undatedReceipt.id],
      );
      expect(
        sortReceipts(
          [cheapReceipt, expensiveReceipt],
          ReceiptSort.amount,
          SortDirection.descending,
        ).map((item) => item.id),
        [expensiveReceipt.id, cheapReceipt.id],
      );
      expect(
        sortReceipts(
          [cheapReceipt, expensiveReceipt],
          ReceiptSort.establishment,
          SortDirection.ascending,
        ).map((item) => item.id),
        [expensiveReceipt.id, cheapReceipt.id],
      );
      expect(applySortDirection(3, SortDirection.descending), -3);
      expect(signedReceiptValue(cheapReceipt), -10);
      expect(signedReceiptValue(expensiveReceipt), 20);
      expect(signedReceiptValue(undatedReceipt), isNull);
    });

    test('classifies search when text appears in data or OCR', () {
      final category = _category(name: 'Alimentação');
      final receipt = _receipt(
        category: category,
        establishment: 'Café São João',
        content: 'linha OCR com cupom especial',
      );

      expect(normalizeReceiptSearchText('Café São João'), 'cafe sao joao');
      expect(structuredReceiptSearchText(receipt), contains('alimentacao'));
      expect(ocrReceiptSearchText(receipt), contains('cupom especial'));
      expect(receiptSearchMatch(receipt, 'sao joao'), SearchMatch.data);
      expect(receiptSearchMatch(receipt, 'cupom'), SearchMatch.ocr);
      expect(receiptSearchMatch(receipt, 'vector'), SearchMatch.semantic);
      expect(formatReceiptCurrencyWithNature(null, true), 'R\$ --');
      expect(formatReceiptCurrencyWithNature(12.3, true), '- R\$ 12,30');
      expect(formatReceiptCurrencyWithNature(12.3, false), '+ R\$ 12,30');
    });

    test('normalizes dates when calculating day boundaries', () {
      final data = DateTime(2026, 5, 24, 13, 45, 30);

      expect(startOfDay(data), DateTime(2026, 5, 24));
      expect(endOfDay(data), DateTime(2026, 5, 24, 23, 59, 59, 999));
    });
  });
}

Category _category({int id = 1, String name = 'Alimentação'}) {
  return Category(id: id, name: name);
}

Receipt _receipt({
  int id = 1,
  bool isExpense = true,
  Category? category,
  ExtractedData? extractedData,
  double value = 42.5,
  DateTime? data,
  String establishment = 'Mercado Modelo',
  String content = 'OCR original',
}) {
  return Receipt(
    id: id,
    type: ReceiptType.receipt,
    expense: isExpense,
    fileName: 'receipt_$id.txt',
    fileType: 'text/plain',
    extractedContent: content,
    registeredAt: DateTime(2026, 5, 24, 10),
    extractedData:
        extractedData ??
        ExtractedData(
          id: id,
          receiptId: id,
          amount: value,
          transactionDate: data ?? DateTime(2026, 5, 20),
          establishment: establishment,
          paymentMethod: 'Pix',
        ),
    category: category,
  );
}
