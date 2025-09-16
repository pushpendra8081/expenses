import 'expense.dart';

class ExpenseStatistics {
  final double totalAmount;
  final int totalCount;
  final double averageAmount;
  final Map<String, double> categoryTotals;
  final Map<String, int> categoryCounts;
  final double todayAmount;
  final double weekAmount;
  final double monthAmount;
  final double yearAmount;
  final String topCategory;
  final double topCategoryAmount;

  const ExpenseStatistics({
    required this.totalAmount,
    required this.totalCount,
    required this.averageAmount,
    required this.categoryTotals,
    required this.categoryCounts,
    required this.todayAmount,
    required this.weekAmount,
    required this.monthAmount,
    required this.yearAmount,
    required this.topCategory,
    required this.topCategoryAmount,
  });

  factory ExpenseStatistics.empty() {
    return const ExpenseStatistics(
      totalAmount: 0.0,
      totalCount: 0,
      averageAmount: 0.0,
      categoryTotals: {},
      categoryCounts: {},
      todayAmount: 0.0,
      weekAmount: 0.0,
      monthAmount: 0.0,
      yearAmount: 0.0,
      topCategory: '',
      topCategoryAmount: 0.0,
    );
  }

  factory ExpenseStatistics.fromExpenses(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return ExpenseStatistics.empty();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final yearStart = DateTime(now.year, 1, 1);

    double totalAmount = 0.0;
    double todayAmount = 0.0;
    double weekAmount = 0.0;
    double monthAmount = 0.0;
    double yearAmount = 0.0;
    
    Map<String, double> categoryTotals = {};
    Map<String, int> categoryCounts = {};

    for (final expense in expenses) {
      totalAmount += expense.amount;
      
      // Category totals
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0.0) + expense.amount;
      categoryCounts[expense.category] = 
          (categoryCounts[expense.category] ?? 0) + 1;
      
      // Time-based totals
      final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
      
      if (expenseDate.isAtSameMomentAs(today)) {
        todayAmount += expense.amount;
      }
      
      if (expenseDate.isAfter(weekStart.subtract(const Duration(days: 1)))) {
        weekAmount += expense.amount;
      }
      
      if (expenseDate.isAfter(monthStart.subtract(const Duration(days: 1)))) {
        monthAmount += expense.amount;
      }
      
      if (expenseDate.isAfter(yearStart.subtract(const Duration(days: 1)))) {
        yearAmount += expense.amount;
      }
    }

    // Find top category
    String topCategory = '';
    double topCategoryAmount = 0.0;
    
    categoryTotals.forEach((category, amount) {
      if (amount > topCategoryAmount) {
        topCategory = category;
        topCategoryAmount = amount;
      }
    });

    return ExpenseStatistics(
      totalAmount: totalAmount,
      totalCount: expenses.length,
      averageAmount: totalAmount / expenses.length,
      categoryTotals: categoryTotals,
      categoryCounts: categoryCounts,
      todayAmount: todayAmount,
      weekAmount: weekAmount,
      monthAmount: monthAmount,
      yearAmount: yearAmount,
      topCategory: topCategory,
      topCategoryAmount: topCategoryAmount,
    );
  }

  // Getter methods for compatibility with UI code
  double get dailyAverage => todayAmount;
  double get weeklyTotal => weekAmount;
  double get monthlyTotal => monthAmount;
}