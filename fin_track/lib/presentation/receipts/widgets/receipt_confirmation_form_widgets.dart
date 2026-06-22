import 'package:flutter/material.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/receipt.dart';
import '../../../domain/value_objects/receipt_payment_method.dart';
import '../../theme/fin_track_theme.dart';
import '../../widgets/app_dropdown_field.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/formatters.dart';
import '../../widgets/input_formatters.dart';
import '../receipt_form_helpers.dart';

const double receiptConfirmationDropdownMenuMaxHeight = 280;

class ReceiptConfirmationFormFields extends StatelessWidget {
  const ReceiptConfirmationFormFields({
    super.key,
    required this.receipt,
    required this.categories,
    required this.amountController,
    required this.dateController,
    required this.establishmentController,
    required this.type,
    required this.expense,
    required this.paymentMethod,
    required this.categoryId,
    required this.transactionDate,
    required this.fieldScrollPadding,
    required this.onClearDate,
    required this.onSelectDate,
    required this.onTypeChanged,
    required this.onExpenseChanged,
    required this.onPaymentMethodChanged,
    required this.onCategoryChanged,
  });

  final Receipt receipt;
  final List<Category> categories;
  final TextEditingController amountController;
  final TextEditingController dateController;
  final TextEditingController establishmentController;
  final ReceiptType type;
  final bool expense;
  final String? paymentMethod;
  final int? categoryId;
  final DateTime? transactionDate;
  final EdgeInsets fieldScrollPadding;
  final VoidCallback onClearDate;
  final VoidCallback onSelectDate;
  final ValueChanged<ReceiptType> onTypeChanged;
  final ValueChanged<bool> onExpenseChanged;
  final ValueChanged<String?> onPaymentMethodChanged;
  final ValueChanged<int?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final receiptData = receipt.extractedData;
    final detailText = AppScope.of(context).appConfig.ui.receiptDetail;
    final receiptsText = AppScope.of(context).appConfig.ui.receipts;
    return ConfirmationPanel(
      children: [
        TextFormField(
          controller: establishmentController,
          scrollPadding: fieldScrollPadding,
          decoration: receiptConfirmationFieldDecoration(
            context,
            receiptData?.establishmentConfidence,
            labelText: detailText.establishment,
            icon: Icons.storefront_outlined,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: amountController,
          scrollPadding: fieldScrollPadding,
          decoration: receiptConfirmationFieldDecoration(
            context,
            receiptData?.valueConfidence,
            labelText: detailText.value,
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
          scrollPadding: fieldScrollPadding,
          decoration:
              receiptConfirmationFieldDecoration(
                context,
                receiptData?.dateConfidence,
                labelText: receiptsText.transactionDate,
                icon: Icons.calendar_month_outlined,
              ).copyWith(
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (transactionDate != null)
                      IconButton(
                        tooltip: receiptsText.clearDate,
                        icon: Icon(Icons.close),
                        onPressed: onClearDate,
                      ),
                    IconButton(
                      tooltip: receiptsText.selectDate,
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
          initialValue: type,
          menuMaxHeight: receiptConfirmationDropdownMenuMaxHeight,
          decoration: InputDecoration(
            labelText: detailText.receiptType,
            prefixIcon: const Icon(Icons.receipt_outlined),
          ),
          items: ReceiptType.values
              .map(
                (type) => DropdownMenuItem<ReceiptType>(
                  value: type,
                  child: Text(
                    type.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onTypeChanged(value);
            }
          },
        ),
        const SizedBox(height: 12),
        FinancialTypeSelector(expense: expense, onChanged: onExpenseChanged),
        const SizedBox(height: 12),
        AppDropdownField<String?>(
          initialValue: paymentMethod,
          menuMaxHeight: receiptConfirmationDropdownMenuMaxHeight,
          decoration: receiptConfirmationFieldDecoration(
            context,
            receiptData?.paymentMethodConfidence,
            labelText: receiptsText.paymentMethodForm,
            icon: Icons.credit_card_outlined,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text(
                ReceiptPaymentMethod.unidentified,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...ReceiptPaymentMethod.options.map(
              (option) => DropdownMenuItem<String?>(
                value: option,
                child: Text(
                  option,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: onPaymentMethodChanged,
        ),
        const SizedBox(height: 12),
        AppDropdownField<int?>(
          initialValue: categoryId,
          menuMaxHeight: receiptConfirmationDropdownMenuMaxHeight,
          decoration: InputDecoration(
            labelText: detailText.category,
            prefixIcon: const Icon(Icons.category_outlined),
          ),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(
                detailText.withoutCategory,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...categories.map(
              (category) => DropdownMenuItem<int?>(
                value: category.id,
                child: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: onCategoryChanged,
        ),
      ],
    );
  }
}

class ReceiptConfirmationConfidenceTile extends StatelessWidget {
  const ReceiptConfirmationConfidenceTile({
    super.key,
    required this.confidence,
    required this.extractionConfidence,
    required this.extractionParser,
    required this.debugMode,
    required this.onTap,
  });

  final double confidence;
  final double? extractionConfidence;
  final String? extractionParser;
  final bool debugMode;
  final VoidCallback onTap;

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
          onTap: debugMode ? onTap : null,
          leading: Icon(
            Icons.verified_outlined,
            color: confidenceColor(context, confidence),
          ),
          title: Text('Confiança OCR ${(confidence * 100).round()}%'),
          subtitle: extractionConfidence == null
              ? null
              : Text(
                  'Extração ${_parserLabel(extractionParser)} ${(extractionConfidence! * 100).round()}%',
                ),
          trailing: debugMode ? const Icon(Icons.article_outlined) : null,
        ),
      ),
    );
  }
}

class ConfirmationPanel extends StatelessWidget {
  const ConfirmationPanel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.finTrackColors.surface,
        border: Border.all(color: context.finTrackColors.borderStrong),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class FinancialTypeSelector extends StatelessWidget {
  const FinancialTypeSelector({
    super.key,
    required this.expense,
    required this.onChanged,
  });

  final bool expense;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedColor = expense
        ? context.finTrackColors.expense
        : context.finTrackColors.income;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: AppScope.of(context).appConfig.ui.receiptDetail.nature,
        prefixIcon: const Icon(Icons.swap_vert_circle_outlined),
        helperText: 'Revise se o valor representa saída ou recebimento.',
      ),
      child: SegmentedButton<bool>(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: selectedColor.withValues(alpha: 0.10),
          selectedForegroundColor: selectedColor,
          side: BorderSide(color: context.finTrackColors.borderStrong),
        ),
        segments: [
          ButtonSegment<bool>(
            value: true,
            icon: Icon(Icons.remove_circle_outline),
            label: Text(
              AppScope.of(context).appConfig.ui.receiptDetail.expense,
            ),
          ),
          ButtonSegment<bool>(
            value: false,
            icon: Icon(Icons.add_circle_outline),
            label: Text(AppScope.of(context).appConfig.ui.receiptDetail.income),
          ),
        ],
        selected: {expense},
        onSelectionChanged: (value) => onChanged(value.first),
      ),
    );
  }
}

InputDecoration receiptConfirmationFieldDecoration(
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

String _parserLabel(String? parser) {
  return switch (parser) {
    'digital_transfer' => 'transferência',
    'card_payment' => 'cartão',
    'fiscal_document' => 'documento fiscal',
    'generic_receipt' => 'recibo',
    'fallback' => 'genérica',
    null || '' => 'automática',
    _ => parser.replaceAll('_', ' '),
  };
}
