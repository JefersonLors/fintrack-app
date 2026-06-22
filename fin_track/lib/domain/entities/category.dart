import '../value_objects/category_color_palette.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    this.description,
    this.inferredAutomatically = false,
    this.icon = 'category',
    this.colorArgb = CategoryColorPalette.noColor,
  });

  final int id;
  final String name;
  final String? description;
  final bool inferredAutomatically;
  final String icon;
  final int colorArgb;

  Category copyWith({
    int? id,
    String? name,
    String? description,
    bool? inferredAutomatically,
    String? icon,
    int? colorArgb,
    bool clearDescription = false,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: clearDescription ? null : description ?? this.description,
      inferredAutomatically:
          inferredAutomatically ?? this.inferredAutomatically,
      icon: icon ?? this.icon,
      colorArgb: colorArgb ?? this.colorArgb,
    );
  }
}
