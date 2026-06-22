import 'package:flutter/material.dart';

import '../../../domain/entities/category.dart';
import '../../theme/fin_track_theme.dart';
import '../../widgets/category_visuals.dart';
import '../../widgets/formatters.dart';
import 'category_style_widgets.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.stats,
    required this.selecting,
    required this.selected,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onLongPress,
    this.dragHandle,
  });

  final Category category;
  final CategoryStats stats;
  final bool selecting;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLongPress;
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final inUse = stats.totalReceipts > 0;
    final categoryColor = categoryColorFor(category, context);
    final iconData = iconDataFor(category.icon);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onOpen,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CategoryAvatar(
                        icon: category.inferredAutomatically
                            ? Icons.auto_awesome
                            : iconData,
                        color: category.inferredAutomatically
                            ? context.finTrackColors.primary
                            : categoryColor,
                        selected: selecting && selected,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: selecting ? 0 : 96),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color:
                                          context.finTrackColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                category.description ?? 'Sem descrição',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CategoryChip(
                              icon: inUse
                                  ? Icons.link_outlined
                                  : Icons.link_off_outlined,
                              label: inUse ? 'Em uso' : 'Sem uso',
                              semanticLabel: inUse
                                  ? 'Categoria em uso'
                                  : 'Categoria sem uso',
                            ),
                            const SizedBox(width: 8),
                            CategoryChip(
                              icon: Icons.receipt_long_outlined,
                              label:
                                  '${stats.totalReceipts} comprovante${stats.totalReceipts == 1 ? '' : 's'}',
                              semanticLabel:
                                  '${stats.totalReceipts} comprovante${stats.totalReceipts == 1 ? '' : 's'} nesta categoria',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (stats.totalExpenses > 0 || stats.totalIncome > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (stats.totalExpenses > 0)
                              CategoryChip(
                                icon: Icons.remove_circle_outline,
                                label:
                                    'Despesas: ${formatCurrency(stats.totalExpenses)}',
                                color: context.finTrackColors.expense,
                                semanticLabel:
                                    'Total em despesas: ${formatCurrencyForSpeech(stats.totalExpenses)}',
                              ),
                            if (stats.totalExpenses > 0 &&
                                stats.totalIncome > 0)
                              const SizedBox(width: 8),
                            if (stats.totalIncome > 0)
                              CategoryChip(
                                icon: Icons.add_circle_outline,
                                label:
                                    'Receitas: ${formatCurrency(stats.totalIncome)}',
                                color: context.finTrackColors.income,
                                semanticLabel:
                                    'Total em receitas: ${formatCurrencyForSpeech(stats.totalIncome)}',
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              if (!selecting)
                Positioned(
                  top: 0,
                  right: 0,
                  width: 88,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Semantics(
                            label: 'Excluir categoria',
                            button: true,
                            child: IconButton(
                              tooltip: 'Excluir',
                              onPressed: onDelete,
                              color: context.finTrackColors.danger,
                              style: IconButton.styleFrom(
                                minimumSize: const Size(40, 44),
                                fixedSize: const Size(40, 44),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                              ),
                              icon: Icon(Icons.delete_outline),
                            ),
                          ),
                          Semantics(
                            label: 'Editar categoria',
                            button: true,
                            child: IconButton(
                              tooltip: 'Renomear',
                              onPressed: onEdit,
                              style: IconButton.styleFrom(
                                minimumSize: const Size(40, 44),
                                fixedSize: const Size(40, 44),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                              ),
                              icon: Icon(Icons.edit_outlined),
                            ),
                          ),
                        ],
                      ),
                      if (dragHandle != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconTheme(
                            data: IconThemeData(
                              color: context.finTrackColors.textMuted,
                              size: 24,
                            ),
                            child: SizedBox.square(
                              dimension: 44,
                              child: Center(child: dragHandle!),
                            ),
                          ),
                        ),
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

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.icon,
    required this.color,
    this.selected = false,
  });

  final IconData icon;
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
            Icon(icon, color: color, size: 24),
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
