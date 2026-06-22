import 'package:fin_track/domain/entities/category.dart';
import 'package:fin_track/presentation/widgets/category_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('category visuals map icons and prioritize inferred category', () {
    expect(categoryIconData('restaurant'), Icons.restaurant_outlined);
    expect(categoryIconData('directions_car'), Icons.directions_car_outlined);
    expect(
      categoryIconData('medical_services'),
      Icons.medical_services_outlined,
    );
    expect(categoryIconData('home'), Icons.home_outlined);
    expect(categoryIconData('school'), Icons.school_outlined);
    expect(categoryIconData('sports_esports'), Icons.sports_esports_outlined);
    expect(categoryIconData('pix'), Icons.pix_outlined);
    expect(categoryIconData('shopping_bag'), Icons.shopping_bag_outlined);
    expect(categoryIconData('work'), Icons.work_outline);
    expect(categoryIconData('savings'), Icons.savings_outlined);
    expect(categoryIconData('subscriptions'), Icons.subscriptions_outlined);
    expect(categoryIconData('flight'), Icons.flight_outlined);
    expect(categoryIconData('request_quote'), Icons.request_quote_outlined);
    expect(categoryIconData('desconhecido'), Icons.category_outlined);
    expect(
      categoryIconFor(
        const Category(id: 1, name: 'Inferida', inferredAutomatically: true),
      ),
      Icons.auto_awesome,
    );
  });
}
