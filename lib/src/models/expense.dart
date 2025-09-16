import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String category;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String? notes;

  @HiveField(5)
  String? merchant;

  @HiveField(6)
  double? latitude;

  @HiveField(7)
  double? longitude;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  bool isFromReceipt;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    this.merchant,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.isFromReceipt = false,
  });

  // Factory constructor for creating a new expense
  factory Expense.create({
    required double amount,
    required String category,
    required DateTime date,
    String? notes,
    String? merchant,
    double? latitude,
    double? longitude,
    bool isFromReceipt = false,
  }) {
    final now = DateTime.now();
    return Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      category: category,
      date: date,
      notes: notes,
      merchant: merchant,
      latitude: latitude,
      longitude: longitude,
      createdAt: now,
      updatedAt: now,
      isFromReceipt: isFromReceipt,
    );
  }

  // Copy with method for updating expenses
  Expense copyWith({
    String? id,
    double? amount,
    String? category,
    DateTime? date,
    String? notes,
    String? merchant,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFromReceipt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      merchant: merchant ?? this.merchant,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isFromReceipt: isFromReceipt ?? this.isFromReceipt,
    );
  }

  // Check if expense has location data
  bool get hasLocation => latitude != null && longitude != null;

  // Get formatted amount
  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';

  @override
  String toString() {
    return 'Expense(id: $id, amount: $amount, category: $category, date: $date, notes: $notes, merchant: $merchant, latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Predefined expense categories
enum ExpenseCategories {
  food,
  transport,
  shopping,
  entertainment,
  utilities,
  health,
  travel,
  education,
  business,
  other,
}

class ExpenseCategoryHelper {
  static const List<String> categories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Travel',
    'Education',
    'Personal Care',
    'Home & Garden',
    'Gifts & Donations',
    'Business',
    'Other',
  ];

  static const Map<String, String> categoryIcons = {
    'Food & Dining': '🍽️',
    'Transportation': '🚗',
    'Shopping': '🛍️',
    'Entertainment': '🎬',
    'Bills & Utilities': '💡',
    'Healthcare': '🏥',
    'Travel': '✈️',
    'Education': '📚',
    'Personal Care': '💄',
    'Home & Garden': '🏠',
    'Gifts & Donations': '🎁',
    'Business': '💼',
    'Other': '📝',
  };

  // Convert string category to enum
  static ExpenseCategories fromString(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining':
      case 'food':
        return ExpenseCategories.food;
      case 'transportation':
      case 'transport':
        return ExpenseCategories.transport;
      case 'shopping':
        return ExpenseCategories.shopping;
      case 'entertainment':
        return ExpenseCategories.entertainment;
      case 'bills & utilities':
      case 'utilities':
        return ExpenseCategories.utilities;
      case 'healthcare':
      case 'health':
        return ExpenseCategories.health;
      case 'travel':
        return ExpenseCategories.travel;
      case 'education':
        return ExpenseCategories.education;
      case 'business':
        return ExpenseCategories.business;
      default:
        return ExpenseCategories.other;
    }
  }

  // Get icon for a category string
  static IconData getIcon(String category) {
    return getIconFromEnum(fromString(category));
  }

  // Get icon for a category enum
  static IconData getIconFromEnum(ExpenseCategories category) {
    // Map categories to Material Design icons
    switch (category) {
      case ExpenseCategories.food:
        return Icons.restaurant;
      case ExpenseCategories.transport:
        return Icons.directions_car;
      case ExpenseCategories.shopping:
        return Icons.shopping_bag;
      case ExpenseCategories.entertainment:
        return Icons.movie;
      case ExpenseCategories.health:
        return Icons.local_hospital;
      case ExpenseCategories.education:
        return Icons.school;
      case ExpenseCategories.utilities:
        return Icons.electrical_services;
      case ExpenseCategories.travel:
        return Icons.flight;
      case ExpenseCategories.business:
        return Icons.business;
      case ExpenseCategories.other:
        return Icons.category;
    }
  }
}