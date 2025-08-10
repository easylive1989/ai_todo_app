import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final Color color;
  final IconData icon;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  static const List<Category> defaultCategories = [
    Category(
      id: 'work',
      name: '工作',
      color: Colors.blue,
      icon: Icons.work,
    ),
    Category(
      id: 'personal',
      name: '個人',
      color: Colors.green,
      icon: Icons.person,
    ),
    Category(
      id: 'shopping',
      name: '購物',
      color: Colors.orange,
      icon: Icons.shopping_cart,
    ),
    Category(
      id: 'health',
      name: '健康',
      color: Colors.red,
      icon: Icons.health_and_safety,
    ),
    Category(
      id: 'study',
      name: '學習',
      color: Colors.purple,
      icon: Icons.school,
    ),
    Category(
      id: 'accounting',
      name: '記帳',
      color: Colors.teal,
      icon: Icons.account_balance_wallet,
    ),
    Category(
      id: 'other',
      name: '其他',
      color: Colors.grey,
      icon: Icons.category,
    ),
  ];

  static Category findById(String id) {
    return defaultCategories.firstWhere(
      (category) => category.id == id,
      orElse: () => defaultCategories.last, // 預設返回 '其他'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32(),
      'icon': icon.codePoint,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.color == color &&
        other.icon == icon;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ color.hashCode ^ icon.hashCode;
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, color: $color, icon: $icon)';
  }
}