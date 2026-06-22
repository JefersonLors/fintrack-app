import 'dart:io';

import 'package:flutter/material.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/receipt.dart';
import '../../../domain/value_objects/ocr_result.dart';
import '../../../domain/value_objects/receipt_payment_method.dart';
import '../../theme/fin_track_theme.dart';
import '../../widgets/app_dropdown_field.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/formatters.dart';
import '../../widgets/input_formatters.dart';
import '../controllers/receipt_batch_controller.dart';
import '../receipt_form_helpers.dart';
import 'batch_item_card.dart';

const double batchReviewDropdownMenuMaxHeight = 280;

class ReceiptBatchItemForm extends StatelessWidget {
  const ReceiptBatchItemForm({
    super.key,
    required this.item,
    required this.formKey,
    required this.currentIndex,
    required this.categories,
    required this.amountController,
    required this.dateController,
    required this.merchantController,
    required this.categoryId,
    required this.receiptType,
    required this.expense,
    required this.paymentMethod,
    required this.transactionDate,
    required this.onClearDate,
    required this.onSelectDate,
    required this.onReceiptTypeChanged,
    required this.onExpenseChanged,
    required this.onPaymentMethodChanged,
    required this.onCategoryChanged,
  });

  final ReceiptBatchItem item;
  final GlobalKey<FormState>? formKey;
  final int currentIndex;
  final List<Category> categories;
  final TextEditingController amountController;
  final TextEditingController dateController;
  final TextEditingController merchantController;
  final int? categoryId;
  final ReceiptType receiptType;
  final bool expense;
  final String? paymentMethod;
  final DateTime? transactionDate;
  final VoidCallback onClearDate;
  final VoidCallback onSelectDate;
  final ValueChanged<ReceiptType> onReceiptTypeChanged;
  final ValueChanged<bool> onExpenseChanged;
  final ValueChanged<String?> onPaymentMethodChanged;
  final ValueChanged<int?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final receipt = item.receipt;
    if (receipt == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final confidence = receipt.extractedData?.ocrConfidence ?? 0;
    final lowConfidence = confidence < OcrResult.acceptableConfidenceThreshold;

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          FutureBuilder<File>(
            future: AppScope.of(context).receiptService.localFile(receipt),
            builder: (context, snapshot) => ReceiptFilePreview(
              file: snapshot.data,
              fileName: receipt.fileName,
              fileType: receipt.fileType,
            ),
          ),
          const SizedBox(height: 16),
          if (lowConfidence) ...[
            MaterialBanner(
              leading: Icon(
                Icons.warning_amber_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              content: const Text(
                'A leitura automática ficou incerta. Revise os campos antes de salvar.',
              ),
              actions: const [SizedBox.shrink()],
            ),
            const SizedBox(height: 12),
          ],
          ConfirmationPanel(
            children: [
              TextFormField(
                controller: merchantController,
                decoration: _fieldDecoration(
                  context,
                  receipt.extractedData?.establishmentConfidence,
                  labelText: 'Estabelecimento',
                  icon: Icons.storefront_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountController,
                decoration: _fieldDecoration(
                  context,
                  receipt.extractedData?.valueConfidence,
                  labelText: 'Valor',
                  icon: Icons.payments_outlined,
                  iconColor: expense
                      ? context.finTrackColors.expense
                      : context.finTrackColors.income,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: const [CurrencyMaskInputFormatter()],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  return parseEditableCurrencyValue(value) == null
                      ? 'Informe um valor válido'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: dateController,
                readOnly: true,
                decoration:
                    _fieldDecoration(
                      context,
                      receipt.extractedData?.dateConfidence,
                      labelText: 'Data da transação',
                      icon: Icons.calendar_month_outlined,
                    ).copyWith(
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (transactionDate != null)
                            IconButton(
                              tooltip: 'Limpar data',
                              icon: Icon(Icons.close),
                              onPressed: onClearDate,
                            ),
                          IconButton(
                            tooltip: 'Selecionar data',
                            icon: Icon(Icons.event_outlined),
                            onPressed: onSelectDate,
                          ),
                        ],
                      ),
                    ),
                onTap: onSelectDate,
              ),
              const SizedBox(height: 12),
              AppDropdownField<ReceiptType>(
                key: ValueKey('tipo_$currentIndex'),
                initialValue: receiptType,
                menuMaxHeight: batchReviewDropdownMenuMaxHeight,
                decoration: const InputDecoration(
                  labelText: 'Tipo de comprovante',
                  prefixIcon: Icon(Icons.receipt_outlined),
                ),
                items: ReceiptType.values
                    .map(
                      (type) => DropdownMenuItem<ReceiptType>(
                        value: type,
                        child: Text(
                          type.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    onReceiptTypeChanged(value);
                  }
                },
              ),
              const SizedBox(height: 12),
              FinancialTypeSelector(
                expense: expense,
                onChanged: onExpenseChanged,
              ),
              const SizedBox(height: 12),
              AppDropdownField<String?>(
                key: ValueKey('payment_$currentIndex'),
                initialValue: paymentMethod,
                menuMaxHeight: batchReviewDropdownMenuMaxHeight,
                decoration: _fieldDecoration(
                  context,
                  receipt.extractedData?.paymentMethodConfidence,
                  labelText: 'Forma de pagamento',
                  icon: Icons.credit_card_outlined,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(ReceiptPaymentMethod.unidentified),
                  ),
                  ...ReceiptPaymentMethod.options.map(
                    (option) => DropdownMenuItem<String?>(
                      value: option,
                      child: Text(option, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: onPaymentMethodChanged,
              ),
              const SizedBox(height: 12),
              AppDropdownField<int?>(
                key: ValueKey('category_$currentIndex'),
                initialValue: categoryId,
                menuMaxHeight: batchReviewDropdownMenuMaxHeight,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Sem categoria'),
                  ),
                  ...categories.map(
                    (category) => DropdownMenuItem<int?>(
                      value: category.id,
                      child: Text(
                        category.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: onCategoryChanged,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _OcrConfidenceTile(confidence: confidence),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration(
  BuildContext context,
  double? confidence, {
  required String labelText,
  required IconData icon,
  Color? iconColor,
}) {
  final low = confidence != null && confidence < 0.65;
  return InputDecoration(
    labelText: labelText,
    prefixIcon: Icon(icon, color: iconColor),
    helperText: low ? 'Baixa confiança. Confira este campo.' : null,
    helperStyle: low
        ? TextStyle(color: Theme.of(context).colorScheme.error)
        : null,
  );
}

class _OcrConfidenceTile extends StatelessWidget {
  const _OcrConfidenceTile({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.finTrackColors.surfaceAlt,
        border: Border.all(color: context.finTrackColors.borderStrong),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(
            Icons.verified_outlined,
            color: confidenceColor(context, confidence),
          ),
          title: Text('Confiança OCR ${(confidence * 100).round()}%'),
        ),
      ),
    );
  }
}
