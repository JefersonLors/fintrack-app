import 'package:flutter/material.dart';

import '../../../domain/entities/receipt.dart';
import '../../../domain/value_objects/category_color_palette.dart';
import '../../../infrastructure/diagnostics/user_error_message.dart';
import '../../theme/fin_track_theme.dart';
import 'category_card_widgets.dart';
import '../../widgets/fin_track_chip.dart';

class CategoryIconOption {
  const CategoryIconOption(this.key, this.icon, this.tooltip);

  final String key;
  final IconData icon;
  final String tooltip;
}

const _categoryIconOptions = <CategoryIconOption>[
  CategoryIconOption('category', Icons.category_outlined, 'Categoria'),
  CategoryIconOption('restaurant', Icons.restaurant_outlined, 'Alimentação'),
  CategoryIconOption(
    'directions_car',
    Icons.directions_car_outlined,
    'Transporte',
  ),
  CategoryIconOption(
    'medical_services',
    Icons.medical_services_outlined,
    'Saúde',
  ),
  CategoryIconOption('home', Icons.home_outlined, 'Moradia'),
  CategoryIconOption('school', Icons.school_outlined, 'Educação'),
  CategoryIconOption('sports_esports', Icons.sports_esports_outlined, 'Lazer'),
  CategoryIconOption('pix', Icons.pix_outlined, 'Pix'),
  CategoryIconOption('shopping_bag', Icons.shopping_bag_outlined, 'Compras'),
  CategoryIconOption('work', Icons.work_outline, 'Trabalho'),
  CategoryIconOption('savings', Icons.savings_outlined, 'Economia'),
  CategoryIconOption(
    'subscriptions',
    Icons.subscriptions_outlined,
    'Assinaturas',
  ),
  CategoryIconOption('flight', Icons.flight_outlined, 'Viagens'),
  CategoryIconOption('request_quote', Icons.request_quote_outlined, 'Impostos'),
  CategoryIconOption('more_horiz', Icons.more_horiz, 'Outros'),
];

const _categoryColorOptions = <Color>[
  Color(0xFFD2D8E3),
  Color(0xFF5F8FA3),
  Color(0xFF7F9BAE),
  Color(0xFF7AA7E8),
  Color(0xFF8ED1C6),
];

IconData iconDataFor(String key) {
  for (final option in _categoryIconOptions) {
    if (option.key == key) {
      return option.icon;
    }
  }
  return Icons.category_outlined;
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.semanticLabel,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final String? semanticLabel;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return FinTrackChip(
      icon: icon,
      label: label,
      color: color,
      scrollable: true,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
    );
  }
}

class CategoryStats {
  const CategoryStats({
    this.totalReceipts = 0,
    this.totalExpenses = 0,
    this.totalIncome = 0,
  });

  final int totalReceipts;
  final double totalExpenses;
  final double totalIncome;

  CategoryStats add(Receipt receipt, double amount) {
    return CategoryStats(
      totalReceipts: totalReceipts + 1,
      totalExpenses: totalExpenses + (receipt.expense ? amount : 0),
      totalIncome: totalIncome + (receipt.expense ? 0 : amount),
    );
  }
}

String normalizeCategoryText(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c');
}

String categoryErrorMessage(Object error) {
  return userFriendlyErrorMessage(
    error,
    fallback: 'Não foi possível salvar a categoria.',
  );
}

class CategoryStylePicker extends StatelessWidget {
  const CategoryStylePicker({
    super.key,
    required this.selectedIcon,
    required this.selectedColor,
    required this.onIconSelected,
    required this.onColorSelected,
  });

  final String selectedIcon;
  final Color selectedColor;
  final ValueChanged<String> onIconSelected;
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    final selectedColorVisual =
        Theme.of(context).brightness == Brightness.light &&
            selectedColor.toARGB32() == CategoryColorPalette.noColor
        ? const Color(CategoryColorPalette.primary)
        : selectedColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CategoryAvatar(
              icon: iconDataFor(selectedIcon),
              color: selectedColorVisual,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Escolha uma identidade visual para reconhecer a categoria rapidamente.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ChoiceGrid(
          children: [
            for (final option in _categoryIconOptions)
              _IconChoiceButton(
                option: option,
                selected: option.key == selectedIcon,
                color: selectedColorVisual,
                onPressed: () => onIconSelected(option.key),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _ChoiceGrid(
          children: [
            for (final color in _categoryColorOptions)
              _ColorChoiceButton(
                color: color,
                selected: color.toARGB32() == selectedColorVisual.toARGB32(),
                tooltip: color.toARGB32() == 0xFFD2D8E3 ? 'Sem cor' : 'Cor',
                onPressed: () => onColorSelected(color),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({required this.children});

  static const _columns = 5;
  static const _spacing = 8.0;
  static const _tileHeight = 44.0;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final tileWidth = (width - ((_columns - 1) * _spacing)) / _columns;
        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, height: _tileHeight, child: child),
          ],
        );
      },
    );
  }
}

class _IconChoiceButton extends StatelessWidget {
  const _IconChoiceButton({
    required this.option,
    required this.selected,
    required this.color,
    required this.onPressed,
  });

  final CategoryIconOption option;
  final bool selected;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: option.tooltip,
      child: IconButton.filledTonal(
        isSelected: selected,
        onPressed: onPressed,
        color: selected ? color : context.finTrackColors.textMuted,
        style: IconButton.styleFrom(
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: selected
              ? color.withValues(alpha: 0.16)
              : context.finTrackColors.surfaceAlt,
          side: BorderSide(
            color: selected
                ? color.withValues(alpha: 0.55)
                : context.finTrackColors.borderStrong,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(option.icon),
      ),
    );
  }
}

class _ColorChoiceButton extends StatelessWidget {
  const _ColorChoiceButton({
    required this.color,
    required this.selected,
    required this.tooltip,
    required this.onPressed,
  });

  final Color color;
  final bool selected;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          selected ? Icons.check_circle : Icons.circle,
          color: color,
          size: selected ? 28 : 24,
        ),
        style: IconButton.styleFrom(
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: color.withValues(alpha: selected ? 0.14 : 0.08),
          side: BorderSide(
            color: selected
                ? color.withValues(alpha: 0.65)
                : context.finTrackColors.borderStrong,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
