import 'dart:io';

import 'package:fin_track/domain/entities/category.dart';
import 'package:fin_track/domain/entities/configuration.dart';
import 'package:fin_track/domain/entities/extracted_data.dart';
import 'package:fin_track/domain/entities/receipt.dart';
import 'package:fin_track/domain/services/i_category_service.dart';
import 'package:fin_track/domain/value_objects/receipt_filter.dart';
import 'package:fin_track/presentation/categories/controllers/categories_controller.dart';
import 'package:fin_track/presentation/categories/widgets/category_style_widgets.dart';
import 'package:fin_track/presentation/receipts/controllers/receipt_batch_controller.dart';
import 'package:fin_track/presentation/receipts/controllers/receipt_batch_review_controller.dart';
import 'package:fin_track/presentation/receipts/controllers/receipt_confirmation_controller.dart';
import 'package:fin_track/presentation/receipts/controllers/receipt_list_controller.dart';
import 'package:fin_track/presentation/configuration/controllers/configuration_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../widget/presentation_mocks.dart';

void main() {
  group('CategoriesController', () {
    test(
      'orders categories optimistically and clears invalid or applied order',
      () {
        final controller = CategoriesController();
        final categories = [_category(1, 'A'), _category(2, 'B')];

        controller.applyOptimisticOrder([2, 1]);
        expect(
          controller.categoriesWithOptimisticOrder(categories).map((c) => c.id),
          [2, 1],
        );

        controller.applyOptimisticOrder([1, 2]);
        expect(
          controller.categoriesWithOptimisticOrder(categories),
          categories,
        );
        expect(controller.optimisticOrderIds, isNull);

        controller.applyOptimisticOrder([1, 2, 3]);
        expect(
          controller.categoriesWithOptimisticOrder(categories),
          categories,
        );
        expect(controller.optimisticOrderIds, [1, 2, 3]);
      },
    );

    test('clears optimistic order when reorder fails', () async {
      final controller = CategoriesController();
      final service = _FakeCategoryService()..reorderError = StateError('x');

      await expectLater(
        controller.reorder(service, [2, 1]),
        throwsA(isA<StateError>()),
      );

      expect(controller.optimisticOrderIds, isNull);
    });

    test('plans and deletes selected categories', () async {
      final controller = CategoriesController();
      final service = _FakeCategoryService(associatedIds: {2});
      final categories = [_category(1, 'Free'), _category(2, 'Used')];

      expect(
        await controller.planSelectedDeletion(service, categories, const {}),
        isA<CategoryDeletionPlan>()
            .having((plan) => plan.free, 'free', isEmpty)
            .having((plan) => plan.used, 'used', isEmpty),
      );

      controller.selectVisible(categories);
      final plan = await controller.planSelectedDeletion(service, categories, {
        2: const CategoryStats(totalReceipts: 1),
      });
      expect(plan.free.map((category) => category.id), [1]);
      expect(plan.used.map((category) => category.id), [2]);

      await controller.deleteCategories(service, plan.free);
      expect(service.deletedIds, [1]);
      expect(controller.hasSelection, isFalse);
      expect(controller.processingSelection, isFalse);
    });

    test('checks associations through service and receipt fallback', () async {
      final controller = CategoriesController();
      final category = _category(9, 'Food');
      final receiptService = MockIReceiptService();
      final categoryService = _FakeCategoryService();

      when(
        receiptService.watchAll(),
      ).thenAnswer((_) => Stream.value([_receipt(3, category: category)]));

      expect(
        await controller.categoryHasAssociations(
          categoryService: categoryService,
          receiptService: receiptService,
          category: category,
          stats: const {},
        ),
        isTrue,
      );
    });

    test('toggles and cancels selection state', () {
      final controller = CategoriesController();
      final category = _category(1, 'A');

      controller.startSelection();
      controller.toggleSelection(category);
      expect(controller.selectedCategoryIds, {1});
      controller.toggleSelection(category);
      expect(controller.selectedCategoryIds, isEmpty);

      controller.selectVisible([category]);
      expect(controller.hasSelection, isTrue);
      controller.cancelSelection();
      expect(controller.selecting, isFalse);
      expect(controller.processingSelection, isFalse);
      expect(controller.selectedCategoryIds, isEmpty);
    });
  });

  group('ConfigurationController', () {
    test('delegates configuration actions and guards theme changes', () async {
      final controller = ConfigurationController();
      final service = MockIConfigurationService();
      final receipts = MockIReceiptService();
      const config = Configuration(id: 1);

      when(receipts.deleteOrphanFiles()).thenAnswer((_) async => 2);
      when(service.calculateUsedSpaceBytes()).thenAnswer((_) async => 42);
      when(
        service.configureAutomaticBackup(
          active: anyNamed('active'),
          intervalDays: anyNamed('intervalDays'),
        ),
      ).thenAnswer((_) async {});
      when(service.update(any)).thenAnswer((_) async {});
      when(service.resetOnboarding()).thenAnswer((_) async {});

      expect(
        await controller.calculateUpdatedSpace(
          receiptService: receipts,
          configurationService: service,
        ),
        42,
      );
      await controller.changeThemeMode(service, config, lightTheme: false);
      verifyNever(service.update(any));

      await controller.changeThemeMode(service, config, lightTheme: true);
      await controller.updateBackupPassword(service, config, 'secret');
      await controller.removeBackupPassword(service, config);
      await controller.updateStorageLimit(service, config, 128);
      await controller.updateAutoLockInterval(service, config, 30);
      await controller.resetOnboarding(service);

      verify(receipts.deleteOrphanFiles()).called(1);
      verify(
        service.configureAutomaticBackup(active: false, intervalDays: 7),
      ).called(1);
      verify(service.resetOnboarding()).called(1);
      verify(service.update(any)).called(5);
    });

    test('runs local authentication enable and disable flows', () async {
      final controller = ConfigurationController();
      final service = MockIConfigurationService();
      const config = Configuration(
        id: 1,
        localAuthEnabled: true,
        authenticationType: AuthenticationType.pin,
      );
      var pinRemoved = 0;

      when(service.update(any)).thenAnswer((_) async {});

      expect(
        await controller.enableLocalAuthentication(
          service,
          config,
          selectMethod: () async => null,
          configureMethod: (_) async => true,
        ),
        isA<AuthenticationFlowResult>().having(
          (r) => r.changed,
          'changed',
          false,
        ),
      );

      final incomplete = await controller.enableLocalAuthentication(
        service,
        config,
        selectMethod: () async => AuthenticationType.pin,
        configureMethod: (_) async => false,
      );
      expect(incomplete.incompleteMethod, AuthenticationType.pin);

      expect(
        await controller.disableLocalAuthentication(
          service,
          config,
          authenticate: (_) async => false,
          removePin: () async => pinRemoved++ == -1,
        ),
        isFalse,
      );

      expect(
        await controller.disableLocalAuthentication(
          service,
          config,
          authenticate: (_) async => true,
          removePin: () async {
            pinRemoved++;
            return true;
          },
        ),
        isTrue,
      );
      expect(pinRemoved, 1);
    });

    test(
      'changes authentication method with auth and biometric pin cleanup',
      () async {
        final controller = ConfigurationController();
        final service = MockIConfigurationService();
        const config = Configuration(
          id: 1,
          authenticationType: AuthenticationType.pin,
        );
        var pinRemoved = false;

        when(service.update(any)).thenAnswer((_) async {});

        expect(
          await controller.changeAuthenticationMethod(
            service,
            config,
            AuthenticationType.pin,
            forceConfiguration: false,
            authenticate: (_) async => true,
            configureMethod: (_) async => true,
            removePin: () async => true,
          ),
          isA<AuthenticationFlowResult>().having(
            (r) => r.changed,
            'changed',
            false,
          ),
        );

        expect(
          await controller.changeAuthenticationMethod(
            service,
            config,
            AuthenticationType.biometric,
            forceConfiguration: true,
            authenticate: (_) async => false,
            configureMethod: (_) async => true,
            removePin: () async => true,
          ),
          isA<AuthenticationFlowResult>().having(
            (r) => r.changed,
            'changed',
            false,
          ),
        );

        final result = await controller.changeAuthenticationMethod(
          service,
          config,
          AuthenticationType.biometric,
          forceConfiguration: true,
          authenticate: (_) async => true,
          configureMethod: (_) async => true,
          removePin: () async {
            pinRemoved = true;
            return true;
          },
        );

        expect(result.changed, isTrue);
        expect(pinRemoved, isTrue);
      },
    );
  });

  group('ReceiptBatchController', () {
    test('stages files, marks item states, and discards previews', () async {
      final first = _tempFile('batch_a.txt');
      final second = _tempFile('batch_b.txt');
      final controller = ReceiptBatchController.fromFiles([first, second]);
      final service = MockIReceiptService();
      final preview = _receipt(0, fileName: first.path);

      when(service.discardPreview(any)).thenAnswer((_) async {});

      expect(controller.progress.total, 2);
      await controller.prepareStaging();
      await controller.prepareStaging();
      expect(controller.stagingDirectory, isNotNull);
      expect(controller.items.first.file.path, isNot(first.path));

      controller.markProcessing(controller.items.first);
      controller.markReady(controller.items.first, preview);
      controller.markError(controller.items.last, StateError('bad'));
      expect(controller.hasUnsavedItems(), isTrue);
      expect(controller.hasErrorItems(), isTrue);
      expect(controller.pendingReceipts(), [preview]);

      await controller.discardPendingPreviews(service);
      verify(service.discardPreview(preview)).called(1);

      controller.markSaved(controller.items.first, _receipt(5));
      controller.markAllAsError(StateError('all'));
      expect(controller.progress.errors, 2);
      await controller.discardStaging();
      expect(controller.stagingDirectory, isNull);

      var finished = false;
      await controller.finish(() async => finished = true);
      await controller.finish(null);
      expect(finished, isTrue);
    });
  });

  group('ReceiptListController', () {
    test('applies filters, labels, sort, and selection', () {
      final controller = ReceiptListController(
        initialFilter: ReceiptFilter(categoryId: 1, withoutCategory: true),
        activeFilterLabel: 'Filtro',
      );
      final receipt = _receipt(1);

      expect(controller.withoutCategory, isFalse);
      controller.applyInitialFilter(
        const ReceiptFilter(categoryId: 1, withoutCategory: true),
        activeLabel: 'Filtro',
      );
      expect(controller.categoryId, isNull);
      expect(controller.withoutCategory, isTrue);
      expect(controller.activeFilterLabel, 'Filtro');

      controller.changeSortOrder(ReceiptSort.amount);
      controller.changeSortOrder(ReceiptSort.amount);
      expect(controller.sortDirection, SortDirection.descending);

      controller.toggleSelection(receipt);
      expect(controller.hasSelection, isTrue);
      controller.selectVisible([receipt]);
      expect(controller.hasSelection, isFalse);

      controller.applyFilters(
        selectedCategoryId: 2,
        selectedType: ReceiptType.invoice,
        selectedExpense: false,
        selectedStart: DateTime(2026),
        selectedEnd: null,
        selectedCategoryName: 'Mercado',
      );
      expect(
        controller.buildFilterLabel(categoryName: 'Mercado'),
        contains('Receitas'),
      );
      expect(
        controller.selectedCategoryName([_category(2, 'Mercado')], 2),
        'Mercado',
      );
      expect(controller.selectedCategoryName([], null), isNull);
      expect(controller.selectedCategoryName([], 99), isNull);

      controller.resetSearchState();
      expect(controller.advancedFiltersActive, isFalse);
    });

    test(
      'imports, diagnoses, shares, saves, and deletes through service',
      () async {
        final controller = ReceiptListController();
        final service = MockIReceiptService();
        final file = _tempFile('import.txt');

        when(service.importFiles()).thenAnswer((_) async => [file]);
        when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
        when(
          service.diagnoseSemanticSearch(any),
        ).thenAnswer((_) async => 'diag');
        when(service.shareImages(any)).thenAnswer((_) async {});
        when(service.saveImagesToDevice(any)).thenAnswer((_) async {});
        when(service.delete(any)).thenAnswer((_) async {});

        controller.setImporting(true);
        expect(await controller.importFiles(service), isEmpty);
        controller.setImporting(false);
        expect(await controller.importFiles(service), [file]);

        controller.setDiagnosingSearch(true);
        expect(await controller.diagnoseSemanticSearch(service, 'x'), isNull);
        controller.setDiagnosingSearch(false);
        expect(await controller.diagnoseSemanticSearch(service, '  '), isNull);
        expect(
          await controller.diagnoseSemanticSearch(service, ' mercado '),
          'diag',
        );

        expect(await controller.saveSelectedToDevice(service), 0);
        await controller.shareSelected(service);

        controller.toggleSelection(_receipt(7));
        await controller.shareSelected(service);
        verify(service.shareImages([7])).called(1);

        controller.toggleSelection(_receipt(8));
        expect(await controller.saveSelectedToDevice(service), 1);
        verify(service.saveImagesToDevice([8])).called(1);

        controller.toggleSelection(_receipt(9));
        expect(await controller.deleteSelected(service), 1);
        verify(service.delete(9)).called(1);
      },
    );
  });

  group('ReceiptConfirmationController', () {
    test('loads, builds, saves existing receipt, and formats date', () async {
      final controller = ReceiptConfirmationController();
      final receiptService = MockIReceiptService();
      final categoryService = _FakeCategoryService(
        categories: [_category(2, 'Food')],
      );
      final receipt = _receipt(5, category: _category(99, 'Old'));

      when(receiptService.findById(5)).thenAnswer((_) async => receipt);
      when(receiptService.update(any)).thenAnswer((_) async {});

      expect(controller.requestLoad(), isTrue);
      expect(controller.requestLoad(), isFalse);

      await controller.loadInitial(
        receiptService: receiptService,
        categoryService: categoryService,
        initialReceipt: null,
        receiptId: 5,
      );
      controller.setTransactionDate(DateTime(2026, 5, 27, 15));
      expect(controller.transactionDate, DateTime(2026, 5, 27));
      controller.clearDate();
      expect(controller.transactionDate, isNull);

      controller.setCategoryId(99);
      expect(controller.selectedCategory(receipt)?.id, 99);
      controller.setCategoryId(123);
      expect(controller.selectedCategory(receipt), isNull);

      await controller.saveReceipt(controller.buildUpdatedReceipt());
      expect(controller.exitConfirmed, isTrue);
      verify(receiptService.update(any)).called(1);
      controller.dispose();
    });

    test('saves and discards preview receipts', () async {
      final controller = ReceiptConfirmationController();
      final service = MockIReceiptService();
      final preview = _receipt(0);
      final saved = _receipt(10);

      when(service.saveConfirmed(any)).thenAnswer((_) async => saved);
      when(service.discardPreview(any)).thenAnswer((_) async {});

      controller.applyReceipt(preview, const []);
      await controller.loadInitial(
        receiptService: service,
        categoryService: _FakeCategoryService(),
        initialReceipt: preview,
        receiptId: null,
      );
      await controller.saveReceipt(controller.buildUpdatedReceipt());
      expect(controller.previewSaved, isTrue);

      controller.applyReceipt(preview, const []);
      await controller.discardPreviewIfNeeded();
      verify(service.discardPreview(preview)).called(1);
      controller.dispose();
    });
  });

  group('ReceiptBatchReviewController', () {
    test(
      'handles empty, save boundaries, remove, reprocess, and category fallback',
      () async {
        final amount = TextEditingController();
        final date = TextEditingController();
        final merchant = TextEditingController();
        final empty = ReceiptBatchReviewController(
          items: const [],
          formKey: GlobalKey<FormState>(),
          amountController: amount,
          dateController: date,
          merchantController: merchant,
        );
        expect(empty.currentItem, isNull);
        empty.loadCurrentItem();
        expect(empty.persistCurrentItemEdits(validate: true), isTrue);

        final file = _tempFile('review.txt');
        final item = ReceiptBatchItem(file: file, number: 1)
          ..status = ReceiptBatchItemStatus.ready
          ..receipt = _receipt(0, category: _category(4, 'Fallback'));
        final controller = ReceiptBatchReviewController(
          items: [item],
          formKey: GlobalKey<FormState>(),
          amountController: amount,
          dateController: date,
          merchantController: merchant,
        )..loadCurrentItem();
        final service = MockIReceiptService();

        when(service.saveConfirmed(any)).thenAnswer((_) async => _receipt(20));
        when(service.validateSpaceForNewReceipt(any)).thenAnswer((_) async {});
        when(service.processPreview(any)).thenAnswer((_) async => _receipt(0));
        when(service.discardPreview(any)).thenAnswer((_) async {});

        controller.categoryId = 4;
        expect(controller.buildUpdatedReceipt(item.receipt!).category?.id, 4);
        controller.removeSavedItemFromReview(item, _receipt(20));
        expect(controller.currentIndex, 0);
        expect(controller.items, isEmpty);

        controller.items.add(item);
        expect(await controller.reprocessItem(service, 0), isNull);
        expect(item.status, ReceiptBatchItemStatus.ready);
        await controller.removeItem(service, 0);
        expect(controller.currentIndex, 0);
        verify(service.discardPreview(any)).called(1);

        amount.dispose();
        date.dispose();
        merchant.dispose();
      },
    );
  });
}

Category _category(int id, String name) => Category(id: id, name: name);

Receipt _receipt(
  int id, {
  String fileName = 'receipt.txt',
  Category? category,
}) {
  return Receipt(
    id: id,
    type: ReceiptType.receipt,
    expense: true,
    fileName: fileName,
    fileType: 'text/plain',
    extractedContent: 'Mercado',
    registeredAt: DateTime(2026, 5, 27),
    extractedData: ExtractedData(
      id: id,
      receiptId: id,
      amount: 12.5,
      transactionDate: DateTime(2026, 5, 27),
      establishment: 'Mercado',
      paymentMethod: 'PIX',
    ),
    category: category,
  );
}

File _tempFile(String name) {
  final file = File(
    '${Directory.systemTemp.path}/fintrack_controller_${DateTime.now().microsecondsSinceEpoch}_$name',
  );
  file.writeAsStringSync('test');
  return file;
}

class _FakeCategoryService implements ICategoryService {
  _FakeCategoryService({
    this.associatedIds = const <int>{},
    this.categories = const <Category>[],
  });

  final Set<int> associatedIds;
  final List<Category> categories;
  final deletedIds = <int>[];
  Object? reorderError;

  @override
  Future<Category> create(
    String name, [
    String? description,
    String? icon,
    int? colorArgb,
  ]) async {
    return Category(id: 1, name: name, description: description);
  }

  @override
  Future<void> delete(int id) async {
    deletedIds.add(id);
  }

  @override
  Future<bool> hasAssociatedReceipts(int id) async =>
      associatedIds.contains(id);

  @override
  Future<List<Category>> list() async => categories;

  @override
  Future<void> reorder(List<int> orderedIds) async {
    final error = reorderError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> update(Category category) async {}

  @override
  Stream<List<Category>> watchAll() => Stream.value(categories);
}
