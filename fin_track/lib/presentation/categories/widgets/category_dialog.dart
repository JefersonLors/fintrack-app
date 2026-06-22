import 'package:flutter/material.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/value_objects/category_color_palette.dart';
import '../../widgets/app_scope.dart';
import '../../widgets/category_visuals.dart';
import '../../widgets/dialog_actions.dart';
import 'category_style_widgets.dart';

class CategoryDialog extends StatefulWidget {
  const CategoryDialog({super.key, this.category});

  final Category? category;

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _selectedIcon;
  late Color _selectedColor;
  Object? _error;
  var _saving = false;
  var _initialColorAdjustedToTheme = false;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _descriptionController = TextEditingController(
      text: category?.description ?? '',
    );
    _selectedIcon = category?.icon ?? 'category';
    _selectedColor = normalizedCategoryColor(category?.colorArgb ?? 0xFFD2D8E3);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialColorAdjustedToTheme || widget.category != null) {
      return;
    }
    _initialColorAdjustedToTheme = true;
    if (Theme.of(context).brightness == Brightness.light &&
        _selectedColor.toARGB32() == CategoryColorPalette.noColor) {
      _selectedColor = const Color(CategoryColorPalette.primary);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 96).clamp(280.0, 460.0);
    final category = widget.category;
    final commonText = AppScope.of(context).appConfig.ui.common;
    final categoriesText = AppScope.of(context).appConfig.ui.categories;

    return AlertDialog(
      title: Text(
        category == null
            ? categoriesText.text('newDialogTitle')
            : categoriesText.text('editDialogTitle'),
      ),
      content: SizedBox(
        width: width,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CategoryStylePicker(
                  selectedIcon: _selectedIcon,
                  selectedColor: _selectedColor,
                  onIconSelected: (value) =>
                      setState(() => _selectedIcon = value),
                  onColorSelected: (value) =>
                      setState(() => _selectedColor = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  maxLength: 48,
                  minLines: 1,
                  maxLines: 2,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    labelText: categoriesText.text('name'),
                    prefixIcon: const Icon(Icons.category_outlined),
                    counterText: '',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? categoriesText.text('nameRequired')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: 220,
                  minLines: 3,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    labelText: categoriesText.text('description'),
                    prefixIcon: const Icon(Icons.notes_outlined),
                    counterText: '',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  categoriesText.text('descriptionHelper'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: _error == null
                      ? const SizedBox.shrink()
                      : Text(
                          categoryErrorMessage(_error!),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        FinTrackDialogActions(
          children: [
            OutlinedButton(
              onPressed: _saving ? null : () => Navigator.pop(context, false),
              child: Text(commonText.cancel),
            ),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.save_outlined),
              label: Text(commonText.save),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });

    try {
      final service = AppScope.of(context).categoryService;
      final category = widget.category;
      if (category == null) {
        await service.create(
          _nameController.text,
          _descriptionController.text,
          _selectedIcon,
          _selectedColor.toARGB32(),
        );
      } else {
        final description = _descriptionController.text.trim();
        await service.update(
          category.copyWith(
            name: _nameController.text,
            description: description.isEmpty ? null : description,
            clearDescription: description.isEmpty,
            icon: _selectedIcon,
            colorArgb: _selectedColor.toARGB32(),
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _saving = false;
        });
      }
    }
  }
}
