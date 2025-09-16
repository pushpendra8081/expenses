import 'package:flutter/material.dart';

class ExpenseCategories {
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
    'Groceries',
    'Gas & Fuel',
    'Home & Garden',
    'Gifts & Donations',
    'Business',
    'Other',
  ];

  static const Map<String, IconData> _categoryIcons = {
    'Food & Dining': Icons.restaurant,
    'Transportation': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Entertainment': Icons.movie,
    'Bills & Utilities': Icons.receipt_long,
    'Healthcare': Icons.local_hospital,
    'Travel': Icons.flight,
    'Education': Icons.school,
    'Personal Care': Icons.face,
    'Groceries': Icons.local_grocery_store,
    'Gas & Fuel': Icons.local_gas_station,
    'Home & Garden': Icons.home,
    'Gifts & Donations': Icons.card_giftcard,
    'Business': Icons.business,
    'Other': Icons.category,
  };

  static const Map<String, Color> _categoryColors = {
    'Food & Dining': Colors.orange,
    'Transportation': Colors.blue,
    'Shopping': Colors.purple,
    'Entertainment': Colors.pink,
    'Bills & Utilities': Colors.red,
    'Healthcare': Colors.green,
    'Travel': Colors.teal,
    'Education': Colors.indigo,
    'Personal Care': Colors.amber,
    'Groceries': Colors.lightGreen,
    'Gas & Fuel': Colors.grey,
    'Home & Garden': Colors.brown,
    'Gifts & Donations': Colors.deepPurple,
    'Business': Colors.blueGrey,
    'Other': Colors.cyan,
  };

  static IconData getIcon(String category) {
    return _categoryIcons[category] ?? Icons.category;
  }

  static Color getColor(String category) {
    return _categoryColors[category] ?? Colors.grey;
  }

  static String getDefaultCategory() {
    return categories.first;
  }

  static bool isValidCategory(String category) {
    return categories.contains(category);
  }

  static List<String> searchCategories(String query) {
    if (query.isEmpty) return categories;
    
    return categories
        .where((category) => 
            category.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Category icons as strings for provider compatibility
  static const Map<String, String> categoryIcons = {
    'Food & Dining': 'restaurant',
    'Transportation': 'directions_car',
    'Shopping': 'shopping_bag',
    'Entertainment': 'movie',
    'Bills & Utilities': 'receipt_long',
    'Healthcare': 'local_hospital',
    'Travel': 'flight',
    'Education': 'school',
    'Personal Care': 'face',
    'Groceries': 'local_grocery_store',
    'Gas & Fuel': 'local_gas_station',
    'Home & Garden': 'home',
    'Gifts & Donations': 'card_giftcard',
    'Business': 'business',
    'Other': 'category',
  };

  static String getCategoryFromKeywords(String text) {
    final lowerText = text.toLowerCase();
    
    // Food & Dining keywords
    if (lowerText.contains('restaurant') || 
        lowerText.contains('food') || 
        lowerText.contains('cafe') ||
        lowerText.contains('pizza') ||
        lowerText.contains('burger') ||
        lowerText.contains('coffee')) {
      return 'Food & Dining';
    }
    
    // Transportation keywords
    if (lowerText.contains('uber') || 
        lowerText.contains('taxi') || 
        lowerText.contains('bus') ||
        lowerText.contains('train') ||
        lowerText.contains('metro')) {
      return 'Transportation';
    }
    
    // Gas & Fuel keywords
    if (lowerText.contains('gas') || 
        lowerText.contains('fuel') || 
        lowerText.contains('petrol') ||
        lowerText.contains('shell') ||
        lowerText.contains('bp')) {
      return 'Gas & Fuel';
    }
    
    // Groceries keywords
    if (lowerText.contains('grocery') || 
        lowerText.contains('supermarket') || 
        lowerText.contains('walmart') ||
        lowerText.contains('target') ||
        lowerText.contains('costco')) {
      return 'Groceries';
    }
    
    // Shopping keywords
    if (lowerText.contains('amazon') || 
        lowerText.contains('shop') || 
        lowerText.contains('store') ||
        lowerText.contains('mall')) {
      return 'Shopping';
    }
    
    // Healthcare keywords
    if (lowerText.contains('hospital') || 
        lowerText.contains('doctor') || 
        lowerText.contains('pharmacy') ||
        lowerText.contains('medical')) {
      return 'Healthcare';
    }
    
    // Bills & Utilities keywords
    if (lowerText.contains('electric') || 
        lowerText.contains('water') || 
        lowerText.contains('internet') ||
        lowerText.contains('phone') ||
        lowerText.contains('utility')) {
      return 'Bills & Utilities';
    }
    
    return 'Other';
  }
}