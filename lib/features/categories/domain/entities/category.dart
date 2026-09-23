import 'package:flutter/material.dart';

/// Domain entity for a spending category.
///
/// NOTE: This entity intentionally carries [IconData] and [Color] because a
/// category is a UI-bearing value object consumed pervasively across the
/// presentation layer. This is a conscious, documented pragmatic departure
/// from "pure domain" (which would store iconCodePoint/colorValue) chosen to
/// avoid churning every widget that reads `cat.icon` / `cat.color`.
class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double? budget;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.budget,
  });

  Category copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    double? budget,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      budget: budget ?? this.budget,
    );
  }
}
