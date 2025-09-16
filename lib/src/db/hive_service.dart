import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';

class HiveService {
  static const String _expenseBoxName = 'expenses';
  static Box<Expense>? _expenseBox;

  // Initialize Hive and register adapters
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register the Expense adapter
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ExpenseAdapter());
    }
    
    // Open the expense box
    _expenseBox = await Hive.openBox<Expense>(_expenseBoxName);
  }

  // Get the expense box
  static Box<Expense> get expenseBox {
    if (_expenseBox == null || !_expenseBox!.isOpen) {
      throw Exception('Hive not initialized. Call HiveService.init() first.');
    }
    return _expenseBox!;
  }

  // Add a new expense
  static Future<void> addExpense(Expense expense) async {
    await expenseBox.put(expense.id, expense);
  }

  // Update an existing expense
  static Future<void> updateExpense(Expense expense) async {
    final updatedExpense = expense.copyWith(updatedAt: DateTime.now());
    await expenseBox.put(expense.id, updatedExpense);
  }

  // Delete an expense
  static Future<void> deleteExpense(String expenseId) async {
    await expenseBox.delete(expenseId);
  }

  // Get an expense by ID
  static Expense? getExpense(String expenseId) {
    return expenseBox.get(expenseId);
  }

  // Get all expenses
  static List<Expense> getAllExpenses() {
    return expenseBox.values.toList();
  }

  // Get expenses sorted by date (newest first)
  static List<Expense> getExpensesSortedByDate({bool ascending = false}) {
    final expenses = getAllExpenses();
    expenses.sort((a, b) => ascending 
        ? a.date.compareTo(b.date) 
        : b.date.compareTo(a.date));
    return expenses;
  }

  // Get expenses by category
  static List<Expense> getExpensesByCategory(String category) {
    return expenseBox.values
        .where((expense) => expense.category == category)
        .toList();
  }

  // Get expenses by date range
  static List<Expense> getExpensesByDateRange(DateTime startDate, DateTime endDate) {
    return expenseBox.values
        .where((expense) => 
            expense.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            expense.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }

  // Get expenses by merchant
  static List<Expense> getExpensesByMerchant(String merchant) {
    return expenseBox.values
        .where((expense) => 
            expense.merchant?.toLowerCase().contains(merchant.toLowerCase()) ?? false)
        .toList();
  }

  // Search expenses by notes or merchant
  static List<Expense> searchExpenses(String query) {
    final lowerQuery = query.toLowerCase();
    return expenseBox.values
        .where((expense) => 
            (expense.notes?.toLowerCase().contains(lowerQuery) ?? false) ||
            (expense.merchant?.toLowerCase().contains(lowerQuery) ?? false) ||
            expense.category.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // Get total amount for all expenses
  static double getTotalAmount() {
    return expenseBox.values
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Get total amount by category
  static Map<String, double> getTotalAmountByCategory() {
    final Map<String, double> categoryTotals = {};
    
    for (final expense in expenseBox.values) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0.0) + expense.amount;
    }
    
    return categoryTotals;
  }

  // Get total amount by date range
  static double getTotalAmountByDateRange(DateTime startDate, DateTime endDate) {
    return getExpensesByDateRange(startDate, endDate)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Get monthly expenses (current month)
  static List<Expense> getCurrentMonthExpenses() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return getExpensesByDateRange(startOfMonth, endOfMonth);
  }

  // Get weekly expenses (current week)
  static List<Expense> getCurrentWeekExpenses() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return getExpensesByDateRange(
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
        DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day));
  }

  // Get expenses with location data
  static List<Expense> getExpensesWithLocation() {
    return expenseBox.values
        .where((expense) => expense.hasLocation)
        .toList();
  }

  // Get expenses from receipts only
  static List<Expense> getReceiptExpenses() {
    return expenseBox.values
        .where((expense) => expense.isFromReceipt)
        .toList();
  }

  // Get manually entered expenses only
  static List<Expense> getManualExpenses() {
    return expenseBox.values
        .where((expense) => !expense.isFromReceipt)
        .toList();
  }

  // Get receipt expenses by date range
  static List<Expense> getReceiptExpensesByDateRange(DateTime startDate, DateTime endDate) {
    return getExpensesByDateRange(startDate, endDate)
        .where((expense) => expense.isFromReceipt)
        .toList();
  }

  // Get total amount from receipt expenses
  static double getTotalReceiptAmount() {
    return getReceiptExpenses()
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Get receipt expense count
  static int getReceiptExpenseCount() {
    return getReceiptExpenses().length;
  }

  // Get expense statistics
  static Map<String, dynamic> getExpenseStatistics() {
    final expenses = getAllExpenses();
    if (expenses.isEmpty) {
      return {
        'totalExpenses': 0,
        'totalAmount': 0.0,
        'averageAmount': 0.0,
        'categoryCounts': <String, int>{},
        'categoryTotals': <String, double>{},
      };
    }

    final totalAmount = getTotalAmount();
    final categoryTotals = getTotalAmountByCategory();
    final Map<String, int> categoryCounts = {};
    
    for (final expense in expenses) {
      categoryCounts[expense.category] = 
          (categoryCounts[expense.category] ?? 0) + 1;
    }

    final receiptExpenses = getReceiptExpenses();
    final manualExpenses = getManualExpenses();
    final receiptAmount = getTotalReceiptAmount();
    final manualAmount = totalAmount - receiptAmount;

    return {
      'totalExpenses': expenses.length,
      'totalAmount': totalAmount,
      'averageAmount': totalAmount / expenses.length,
      'categoryCounts': categoryCounts,
      'categoryTotals': categoryTotals,
      'receiptExpenseCount': receiptExpenses.length,
      'manualExpenseCount': manualExpenses.length,
      'receiptAmount': receiptAmount,
      'manualAmount': manualAmount,
      'receiptPercentage': expenses.isNotEmpty ? (receiptExpenses.length / expenses.length) * 100 : 0.0,
    };
  }

  // Clear all expenses (for testing or reset)
  static Future<void> clearAllExpenses() async {
    await expenseBox.clear();
  }

  // Close the database
  static Future<void> close() async {
    await _expenseBox?.close();
  }

  // Get box size (number of expenses)
  static int getExpenseCount() {
    return expenseBox.length;
  }

  // Check if box is empty
  static bool isEmpty() {
    return expenseBox.isEmpty;
  }

  // Listen to box changes
  static Stream<BoxEvent> watchExpenses() {
    return expenseBox.watch();
  }
}