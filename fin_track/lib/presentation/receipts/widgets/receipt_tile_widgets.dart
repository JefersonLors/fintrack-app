import 'package:flutter/material.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/receipt.dart';
import '../../theme/fin_track_theme.dart';
import '../../widgets/category_visuals.dart';
import '../../widgets/fin_track_chip.dart';
import '../../widgets/formatters.dart';
import '../receipt_list_logic.dart';

class ReceiptTile extends StatelessWidget {
  const ReceiptTile({
    super.key,
    required this.receipt,
    required this.onTap,
    required this.onLongPress,
    required this.selecting,
    required this.selected,
    required this.showMatchType,
    this.matchType = SearchMatch.none,
  });

  final Receipt receipt;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool selecting;
  final bool selected;
  final bool showMatchType;
  final SearchMatch matchType;

  @override
  Widget build(BuildContext context) {
    final receiptData = receipt.extractedData;
    final natureColor = receipt.expense
        ? context.finTrackColors.expense
        : context.finTrackColors.income;
    final title = receiptData?.establishment ?? '';
    final category = receipt.category;
    final amount = receiptData?.amount;
    final amountLabel = formatReceiptCurrencyWithNature(
      amount,
      receipt.expense,
    );
    final amountSemanticLabel = amount == null
        ? 'Valor não identificado'
        : '${receipt.expense ? 'Despesa' : 'Receita'} de ${formatCurrencyForSpeech(amount)}';
    final bottomChips = <Widget>[
      if (category == null)
        _MetaChip(
          icon: Icons.category_outlined,
          label: 'Sem categoria',
          color: context.finTrackColors.info,
          semanticLabel: 'Categoria não definida',
        )
      else
        _MetaChip.category(category, context),
      _MetaChip(
        icon: Icons.receipt_outlined,
        label: receipt.type.label,
        color: context.finTrackColors.neutralAccent,
        semanticLabel: 'Tipo de comprovante: ${receipt.type.label}',
      ),
      if (showMatchType)
        switch (matchType) {
          SearchMatch.data => _MetaChip(
            icon: Icons.subject_outlined,
            label: 'Dados',
            color: context.finTrackColors.info,
            semanticLabel: 'Correspondência encontrada nos dados',
          ),
          SearchMatch.ocr => _MetaChip(
            icon: Icons.article_outlined,
            label: 'OCR',
            color: context.finTrackColors.info,
            semanticLabel: 'Correspondência encontrada no texto OCR',
          ),
          SearchMatch.semantic => _MetaChip(
            icon: Icons.hub_outlined,
            label: 'Semântica',
            color: context.finTrackColors.info,
            semanticLabel: 'Correspondência encontrada pela busca semântica',
          ),
          SearchMatch.none => const SizedBox.shrink(),
        },
    ];

    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReceiptAvatar(
                    icon: category == null
                        ? Icons.receipt_long_outlined
                        : categoryIconFor(category),
                    color: category == null
                        ? context.finTrackColors.info
                        : categoryColorFor(category, context),
                    selected: selecting && selected,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: context.finTrackColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 10,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _InlineMeta(
                                icon: Icons.calendar_today_outlined,
                                label: formatDate(receiptData?.transactionDate),
                              ),
                              _InlineMeta(
                                icon: receipt.expense
                                    ? Icons.remove_circle_outline
                                    : Icons.add_circle_outline,
                                label: receipt.expense ? 'Despesa' : 'Receita',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 104),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Semantics(
                          label: amountSemanticLabel,
                          child: Text(
                            amountLabel,
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: amount == null
                                      ? context.finTrackColors.textMuted
                                      : natureColor,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (
                      var index = 0;
                      index < bottomChips.length;
                      index++
                    ) ...[
                      if (index > 0) const SizedBox(width: 8),
                      bottomChips[index],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptAvatar extends StatelessWidget {
  const _ReceiptAvatar({
    required this.icon,
    required this.color,
    this.selected = false,
  });

  final IconData? icon;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.42)),
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(
        dimension: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: color, size: 23),
            if (selected)
              Positioned(
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.finTrackColors.primary,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(
                    dimension: 18,
                    child: Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: foreground),
        const SizedBox(width: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    this.icon,
    required this.label,
    this.color,
    this.semanticLabel,
  });

  factory _MetaChip.category(Category category, BuildContext context) {
    return _MetaChip(
      icon: categoryIconFor(category),
      label: category.name,
      color: categoryColorFor(category, context),
      semanticLabel: 'Categoria: ${category.name}',
    );
  }

  final IconData? icon;
  final String label;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return FinTrackChip(
      icon: icon,
      label: label,
      color: color,
      scrollable: true,
      semanticLabel: semanticLabel,
      tooltip: semanticLabel,
    );
  }
}
