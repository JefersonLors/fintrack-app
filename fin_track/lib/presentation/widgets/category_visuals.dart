import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';
import '../../domain/value_objects/category_color_palette.dart';
import '../theme/fin_track_theme.dart';

IconData categoryIconData(String key) {
  return switch (key) {
    'restaurant' => Icons.restaurant_outlined,
    'directions_car' => Icons.directions_car_outlined,
    'medical_services' => Icons.medical_services_outlined,
    'home' => Icons.home_outlined,
    'school' => Icons.school_outlined,
    'sports_esports' => Icons.sports_esports_outlined,
    'pix' => Icons.pix_outlined,
    'shopping_bag' => Icons.shopping_bag_outlined,
    'work' => Icons.work_outline,
    'savings' => Icons.savings_outlined,
    'subscriptions' => Icons.subscriptions_outlined,
    'flight' => Icons.flight_outlined,
    'request_quote' => Icons.request_quote_outlined,
    'more_horiz' => Icons.more_horiz,
    _ => Icons.category_outlined,
  };
}

IconData categoryIconFor(Category category) {
  if (category.inferredAutomatically) {
    return Icons.auto_awesome;
  }
  return categoryIconData(category.icon);
}

Color categoryColorFor(Category category, [BuildContext? context]) {
  final color = normalizedCategoryColor(category.colorArgb);
  if (context == null ||
      color.toARGB32() != CategoryColorPalette.noColor ||
      Theme.of(context).brightness != Brightness.light) {
    return color;
  }
  return context.finTrackColors.neutralAccent;
}

Color normalizedCategoryColor(int argb) {
  return Color(normalizeCategoryColorArgb(argb));
}
