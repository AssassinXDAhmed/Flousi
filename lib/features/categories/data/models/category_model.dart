import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';

/// Firestore-aware representation of a [Category]. Owns the codePoint →
/// [IconData] mapping and all serialization.
class CategoryModel {
  final Category entity;

  const CategoryModel(this.entity);

  static const Map<int, IconData> _iconMap = {
    58757: Icons.shopping_cart,
    57813: Icons.directions_bus,
    58674: Icons.restaurant,
    61462: Icons.shopping_bag,
    61568: Icons.electric_bolt,
    61705: Icons.medical_services,
    57427: Icons.add_chart,
  };

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    final codePoint = int.tryParse(map['iconCodePoint']?.toString() ?? '');
    return CategoryModel(Category(
      id: id,
      name: map['name'] ?? '',
      icon: _iconMap[codePoint] ?? Icons.category,
      color:
          Color(int.tryParse(map['color']?.toString() ?? '') ?? 0xFF9E9E9E),
      budget: map['budget'] != null ? (map['budget'] as num).toDouble() : null,
    ));
  }

  Category toEntity() => entity;
}
