import '../models/expense.dart';
import '../db/hive_service.dart';

// Category suggestion result
class CategorySuggestion {
  final String category;
  final double confidence;
  final String reason;

  const CategorySuggestion({
    required this.category,
    required this.confidence,
    required this.reason,
  });

  @override
  String toString() {
    return 'CategorySuggestion(category: $category, confidence: $confidence, reason: $reason)';
  }
}

class SuggestionService {
  // Rule-based category mapping
  static const Map<String, Map<String, List<String>>> _categoryRules = {
    'Food & Dining': {
      'merchants': [
        'mcdonald', 'burger', 'pizza', 'subway', 'starbucks', 'coffee',
        'restaurant', 'cafe', 'diner', 'bistro', 'grill', 'kitchen',
        'domino', 'kfc', 'taco', 'wendy', 'chipotle', 'panera',
        'dunkin', 'tim horton', 'dairy queen', 'sonic', 'arby',
        'food', 'dining', 'eat', 'meal', 'lunch', 'dinner', 'breakfast'
      ],
      'keywords': [
        'food', 'meal', 'lunch', 'dinner', 'breakfast', 'snack',
        'coffee', 'drink', 'beverage', 'restaurant', 'cafe', 'eat',
        'dining', 'takeout', 'delivery', 'catering'
      ]
    },
    'Transportation': {
      'merchants': [
        'uber', 'lyft', 'taxi', 'shell', 'exxon', 'bp', 'chevron',
        'mobil', 'gas', 'fuel', 'station', 'metro', 'bus', 'train',
        'airline', 'airport', 'parking', 'toll', 'car', 'auto',
        'mechanic', 'repair', 'service', 'oil change'
      ],
      'keywords': [
        'gas', 'fuel', 'uber', 'lyft', 'taxi', 'bus', 'train',
        'metro', 'parking', 'toll', 'car', 'auto', 'transport',
        'travel', 'commute', 'ride', 'flight', 'airline'
      ]
    },
    'Shopping': {
      'merchants': [
        'amazon', 'walmart', 'target', 'costco', 'best buy', 'home depot',
        'lowes', 'macy', 'nordstrom', 'gap', 'old navy', 'h&m',
        'zara', 'nike', 'adidas', 'apple', 'store', 'mall',
        'outlet', 'shop', 'retail', 'market', 'supermarket'
      ],
      'keywords': [
        'shopping', 'clothes', 'clothing', 'shoes', 'electronics',
        'gadget', 'phone', 'computer', 'laptop', 'tablet',
        'book', 'magazine', 'gift', 'present', 'online', 'purchase'
      ]
    },
    'Entertainment': {
      'merchants': [
        'netflix', 'spotify', 'apple music', 'disney', 'hulu',
        'cinema', 'theater', 'movie', 'amc', 'regal', 'imax',
        'concert', 'ticket', 'event', 'game', 'xbox', 'playstation',
        'steam', 'gym', 'fitness', 'club', 'bar', 'pub'
      ],
      'keywords': [
        'movie', 'cinema', 'theater', 'concert', 'show', 'event',
        'ticket', 'entertainment', 'music', 'streaming', 'subscription',
        'game', 'gaming', 'sport', 'gym', 'fitness', 'club', 'bar'
      ]
    },
    'Bills & Utilities': {
      'merchants': [
        'electric', 'electricity', 'power', 'gas company', 'water',
        'sewer', 'internet', 'phone', 'mobile', 'verizon', 'att',
        'comcast', 'spectrum', 'utility', 'bill', 'payment',
        'insurance', 'rent', 'mortgage', 'loan'
      ],
      'keywords': [
        'bill', 'utility', 'electric', 'electricity', 'gas', 'water',
        'sewer', 'internet', 'phone', 'mobile', 'cable', 'tv',
        'insurance', 'rent', 'mortgage', 'loan', 'payment'
      ]
    },
    'Healthcare': {
      'merchants': [
        'hospital', 'clinic', 'doctor', 'dentist', 'pharmacy',
        'cvs', 'walgreens', 'rite aid', 'medical', 'health',
        'dental', 'vision', 'optometry', 'urgent care'
      ],
      'keywords': [
        'medical', 'health', 'doctor', 'dentist', 'pharmacy',
        'medicine', 'prescription', 'hospital', 'clinic',
        'dental', 'vision', 'checkup', 'appointment'
      ]
    },
    'Travel': {
      'merchants': [
        'hotel', 'motel', 'airbnb', 'booking', 'expedia', 'airline',
        'airport', 'flight', 'vacation', 'resort', 'cruise',
        'rental car', 'hertz', 'enterprise', 'budget'
      ],
      'keywords': [
        'travel', 'trip', 'vacation', 'hotel', 'flight', 'airline',
        'airport', 'cruise', 'resort', 'rental', 'booking',
        'accommodation', 'tourism'
      ]
    },
    'Education': {
      'merchants': [
        'school', 'university', 'college', 'tuition', 'book',
        'textbook', 'course', 'class', 'education', 'learning',
        'training', 'certification'
      ],
      'keywords': [
        'education', 'school', 'tuition', 'book', 'textbook',
        'course', 'class', 'training', 'certification', 'learning',
        'study', 'exam', 'fee'
      ]
    },
    'Personal Care': {
      'merchants': [
        'salon', 'barber', 'spa', 'beauty', 'cosmetic', 'makeup',
        'hair', 'nail', 'massage', 'skincare', 'grooming'
      ],
      'keywords': [
        'beauty', 'cosmetic', 'makeup', 'hair', 'salon', 'barber',
        'spa', 'massage', 'skincare', 'grooming', 'personal care',
        'hygiene', 'nail'
      ]
    },
    'Home & Garden': {
      'merchants': [
        'home depot', 'lowes', 'ikea', 'furniture', 'garden',
        'hardware', 'tool', 'paint', 'lumber', 'appliance',
        'home improvement', 'decoration'
      ],
      'keywords': [
        'home', 'house', 'furniture', 'appliance', 'tool', 'hardware',
        'garden', 'plant', 'decoration', 'improvement', 'repair',
        'maintenance', 'cleaning'
      ]
    },
    'Gifts & Donations': {
      'merchants': [
        'charity', 'donation', 'gift', 'present', 'church',
        'nonprofit', 'foundation', 'fundraiser'
      ],
      'keywords': [
        'gift', 'present', 'donation', 'charity', 'church',
        'nonprofit', 'fundraiser', 'contribution', 'giving'
      ]
    },
    'Business': {
      'merchants': [
        'office', 'supply', 'business', 'professional', 'service',
        'consulting', 'meeting', 'conference', 'networking'
      ],
      'keywords': [
        'business', 'office', 'professional', 'work', 'meeting',
        'conference', 'networking', 'consulting', 'service',
        'supplies', 'equipment'
      ]
    }
  };

  // Suggest category based on merchant and notes
  static List<CategorySuggestion> suggestCategory({
    String? merchant,
    String? notes,
  }) {
    final List<CategorySuggestion> suggestions = [];
    final Map<String, double> categoryScores = {};

    // Initialize scores
    for (final category in ExpenseCategoryHelper.categories) {
      categoryScores[category] = 0.0;
    }

    // Analyze merchant
    if (merchant != null && merchant.isNotEmpty) {
      final merchantLower = merchant.toLowerCase();
      
      for (final entry in _categoryRules.entries) {
        final category = entry.key;
        final rules = entry.value;
        
        // Check merchant keywords
        for (final merchantKeyword in rules['merchants'] ?? []) {
          if (merchantLower.contains(merchantKeyword.toLowerCase())) {
            categoryScores[category] = categoryScores[category]! + 2.0;
          }
        }
      }
    }

    // Analyze notes
    if (notes != null && notes.isNotEmpty) {
      final notesLower = notes.toLowerCase();
      
      for (final entry in _categoryRules.entries) {
        final category = entry.key;
        final rules = entry.value;
        
        // Check notes keywords
        for (final keyword in rules['keywords'] ?? []) {
          if (notesLower.contains(keyword.toLowerCase())) {
            categoryScores[category] = categoryScores[category]! + 1.0;
          }
        }
      }
    }

    // Convert scores to suggestions
    final sortedEntries = categoryScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedEntries) {
      if (entry.value > 0) {
        final confidence = (entry.value / 5.0).clamp(0.0, 1.0);
        final reason = _generateReason(entry.key, merchant, notes);
        
        suggestions.add(CategorySuggestion(
          category: entry.key,
          confidence: confidence,
          reason: reason,
        ));
      }
    }

    // If no suggestions found, add historical suggestions
    if (suggestions.isEmpty) {
      suggestions.addAll(_getHistoricalSuggestions(merchant: merchant, notes: notes));
    }

    // Limit to top 3 suggestions
    return suggestions.take(3).toList();
  }

  // Generate reason for suggestion
  static String _generateReason(String category, String? merchant, String? notes) {
    final reasons = <String>[];
    
    if (merchant != null && merchant.isNotEmpty) {
      reasons.add('merchant "$merchant"');
    }
    
    if (notes != null && notes.isNotEmpty) {
      reasons.add('notes content');
    }
    
    if (reasons.isEmpty) {
      return 'Based on category patterns';
    }
    
    return 'Based on ${reasons.join(' and ')}';
  }

  // Get suggestions based on historical data
  static List<CategorySuggestion> _getHistoricalSuggestions({
    String? merchant,
    String? notes,
  }) {
    final suggestions = <CategorySuggestion>[];
    
    try {
      final expenses = HiveService.getAllExpenses();
      final Map<String, int> categoryFrequency = {};
      
      // Count category frequency
      for (final expense in expenses) {
        categoryFrequency[expense.category] = 
            (categoryFrequency[expense.category] ?? 0) + 1;
      }
      
      // Find similar expenses
      if (merchant != null && merchant.isNotEmpty) {
        final similarExpenses = expenses.where((expense) => 
            expense.merchant?.toLowerCase().contains(merchant.toLowerCase()) ?? false
        ).toList();
        
        if (similarExpenses.isNotEmpty) {
          final mostCommonCategory = _getMostCommonCategory(similarExpenses);
          if (mostCommonCategory != null) {
            suggestions.add(CategorySuggestion(
              category: mostCommonCategory,
              confidence: 0.8,
              reason: 'Previously used for similar merchant',
            ));
          }
        }
      }
      
      // Add most frequent categories as fallback
      final sortedCategories = categoryFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (final entry in sortedCategories.take(2)) {
        if (!suggestions.any((s) => s.category == entry.key)) {
          suggestions.add(CategorySuggestion(
            category: entry.key,
            confidence: 0.3,
            reason: 'Frequently used category',
          ));
        }
      }
    } catch (e) {
      // If historical analysis fails, return default suggestions
      suggestions.addAll([
        const CategorySuggestion(
          category: 'Food & Dining',
          confidence: 0.2,
          reason: 'Common expense category',
        ),
        const CategorySuggestion(
          category: 'Shopping',
          confidence: 0.2,
          reason: 'Common expense category',
        ),
      ]);
    }
    
    return suggestions;
  }

  // Get most common category from a list of expenses
  static String? _getMostCommonCategory(List<Expense> expenses) {
    if (expenses.isEmpty) return null;
    
    final Map<String, int> categoryCount = {};
    for (final expense in expenses) {
      categoryCount[expense.category] = 
          (categoryCount[expense.category] ?? 0) + 1;
    }
    
    return categoryCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Get smart suggestions based on amount
  static List<CategorySuggestion> suggestCategoryByAmount(double amount) {
    final suggestions = <CategorySuggestion>[];
    
    // Amount-based heuristics
    if (amount < 5.0) {
      suggestions.add(const CategorySuggestion(
        category: 'Food & Dining',
        confidence: 0.6,
        reason: 'Small amount typical for snacks/coffee',
      ));
    } else if (amount >= 5.0 && amount < 25.0) {
      suggestions.addAll([
        const CategorySuggestion(
          category: 'Food & Dining',
          confidence: 0.5,
          reason: 'Amount typical for meals',
        ),
        const CategorySuggestion(
          category: 'Transportation',
          confidence: 0.4,
          reason: 'Amount typical for ride-sharing',
        ),
      ]);
    } else if (amount >= 25.0 && amount < 100.0) {
      suggestions.addAll([
        const CategorySuggestion(
          category: 'Shopping',
          confidence: 0.4,
          reason: 'Amount typical for shopping',
        ),
        const CategorySuggestion(
          category: 'Entertainment',
          confidence: 0.3,
          reason: 'Amount typical for entertainment',
        ),
      ]);
    } else if (amount >= 100.0) {
      suggestions.addAll([
        const CategorySuggestion(
          category: 'Bills & Utilities',
          confidence: 0.4,
          reason: 'Large amount typical for bills',
        ),
        const CategorySuggestion(
          category: 'Shopping',
          confidence: 0.3,
          reason: 'Large amount typical for major purchases',
        ),
      ]);
    }
    
    return suggestions;
  }

  // Combine multiple suggestion methods
  static List<CategorySuggestion> getSmartSuggestions({
    String? merchant,
    String? notes,
    double? amount,
  }) {
    final allSuggestions = <CategorySuggestion>[];
    
    // Get rule-based suggestions
    allSuggestions.addAll(suggestCategory(
      merchant: merchant,
      notes: notes,
    ));
    
    // Get amount-based suggestions
    if (amount != null) {
      allSuggestions.addAll(suggestCategoryByAmount(amount));
    }
    
    // Merge and deduplicate suggestions
    final Map<String, CategorySuggestion> mergedSuggestions = {};
    
    for (final suggestion in allSuggestions) {
      if (mergedSuggestions.containsKey(suggestion.category)) {
        // Combine confidence scores
        final existing = mergedSuggestions[suggestion.category]!;
        final combinedConfidence = (existing.confidence + suggestion.confidence) / 2;
        mergedSuggestions[suggestion.category] = CategorySuggestion(
          category: suggestion.category,
          confidence: combinedConfidence,
          reason: '${existing.reason} and ${suggestion.reason}',
        );
      } else {
        mergedSuggestions[suggestion.category] = suggestion;
      }
    }
    
    // Sort by confidence and return top suggestions
    final sortedSuggestions = mergedSuggestions.values.toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    
    return sortedSuggestions.take(3).toList();
  }
}