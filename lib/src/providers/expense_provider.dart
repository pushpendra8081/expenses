import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../db/hive_service.dart';

// State class for expense list
class ExpenseListState {
  final List<Expense> expenses;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? selectedCategory;
  final DateTime? startDate;
  final DateTime? endDate;

  const ExpenseListState({
    this.expenses = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedCategory,
    this.startDate,
    this.endDate,
  });

  ExpenseListState copyWith({
    List<Expense>? expenses,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? selectedCategory,
    DateTime? startDate,
    DateTime? endDate,
    bool clearError = false,
    bool clearCategory = false,
    bool clearDateRange = false,
  }) {
    return ExpenseListState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      startDate: clearDateRange ? null : (startDate ?? this.startDate),
      endDate: clearDateRange ? null : (endDate ?? this.endDate),
    );
  }
}

// Expense list notifier
class ExpenseListNotifier extends StateNotifier<ExpenseListState> {
  ExpenseListNotifier() : super(const ExpenseListState()) {
    loadExpenses();
  }

  // Load all expenses
  Future<void> loadExpenses() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final expenses = _getFilteredExpenses();
      state = state.copyWith(
        expenses: expenses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load expenses: $e',
      );
    }
  }

  // Add a new expense
  Future<void> addExpense(Expense expense) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await HiveService.addExpense(expense);
      await loadExpenses();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add expense: $e',
      );
    }
  }

  // Update an existing expense
  Future<void> updateExpense(Expense expense) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await HiveService.updateExpense(expense);
      await loadExpenses();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update expense: $e',
      );
    }
  }

  // Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await HiveService.deleteExpense(expenseId);
      await loadExpenses();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete expense: $e',
      );
    }
  }

  // Search expenses
  void searchExpenses(String query) {
    state = state.copyWith(searchQuery: query);
    final expenses = _getFilteredExpenses();
    state = state.copyWith(expenses: expenses);
  }

  // Filter by category
  void filterByCategory(String? category) {
    state = state.copyWith(
      selectedCategory: category,
      clearCategory: category == null,
    );
    final expenses = _getFilteredExpenses();
    state = state.copyWith(expenses: expenses);
  }

  // Filter by date range
  void filterByDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(
      startDate: startDate,
      endDate: endDate,
      clearDateRange: startDate == null && endDate == null,
    );
    final expenses = _getFilteredExpenses();
    state = state.copyWith(expenses: expenses);
  }

  // Clear all filters
  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearCategory: true,
      clearDateRange: true,
    );
    final expenses = _getFilteredExpenses();
    state = state.copyWith(expenses: expenses);
  }

  // Get filtered expenses based on current state
  List<Expense> _getFilteredExpenses() {
    List<Expense> expenses = HiveService.getExpensesSortedByDate();

    // Apply search filter
    if (state.searchQuery.isNotEmpty) {
      expenses = expenses.where((expense) {
        final query = state.searchQuery.toLowerCase();
        return (expense.notes?.toLowerCase().contains(query) ?? false) ||
               (expense.merchant?.toLowerCase().contains(query) ?? false) ||
               expense.category.toLowerCase().contains(query);
      }).toList();
    }

    // Apply category filter
    if (state.selectedCategory != null) {
      expenses = expenses.where((expense) => 
          expense.category == state.selectedCategory).toList();
    }

    // Apply date range filter
    if (state.startDate != null && state.endDate != null) {
      expenses = expenses.where((expense) => 
          expense.date.isAfter(state.startDate!.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(state.endDate!.add(const Duration(days: 1)))).toList();
    }

    return expenses;
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Expense statistics state
class ExpenseStatisticsState {
  final Map<String, double> categoryTotals;
  final double totalAmount;
  final int totalExpenses;
  final double averageAmount;
  final bool isLoading;
  final String? error;

  const ExpenseStatisticsState({
    this.categoryTotals = const {},
    this.totalAmount = 0.0,
    this.totalExpenses = 0,
    this.averageAmount = 0.0,
    this.isLoading = false,
    this.error,
  });

  ExpenseStatisticsState copyWith({
    Map<String, double>? categoryTotals,
    double? totalAmount,
    int? totalExpenses,
    double? averageAmount,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ExpenseStatisticsState(
      categoryTotals: categoryTotals ?? this.categoryTotals,
      totalAmount: totalAmount ?? this.totalAmount,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      averageAmount: averageAmount ?? this.averageAmount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Expense statistics notifier
class ExpenseStatisticsNotifier extends StateNotifier<ExpenseStatisticsState> {
  ExpenseStatisticsNotifier() : super(const ExpenseStatisticsState()) {
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final stats = HiveService.getExpenseStatistics();
      state = state.copyWith(
        categoryTotals: stats['categoryTotals'] as Map<String, double>,
        totalAmount: stats['totalAmount'] as double,
        totalExpenses: stats['totalExpenses'] as int,
        averageAmount: stats['averageAmount'] as double,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load statistics: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Providers
final expenseListProvider = StateNotifierProvider<ExpenseListNotifier, ExpenseListState>(
  (ref) => ExpenseListNotifier(),
);

final expenseStatisticsProvider = StateNotifierProvider<ExpenseStatisticsNotifier, ExpenseStatisticsState>(
  (ref) => ExpenseStatisticsNotifier(),
);

// Provider for getting a specific expense by ID
final expenseByIdProvider = Provider.family<Expense?, String>((ref, id) {
  return HiveService.getExpense(id);
});

// Provider for current month expenses
final currentMonthExpensesProvider = Provider<List<Expense>>((ref) {
  return HiveService.getCurrentMonthExpenses();
});

// Provider for current week expenses
final currentWeekExpensesProvider = Provider<List<Expense>>((ref) {
  return HiveService.getCurrentWeekExpenses();
});

// Provider for expenses with location
final expensesWithLocationProvider = Provider<List<Expense>>((ref) {
  return HiveService.getExpensesWithLocation();
});

// Provider for expense categories
final expenseCategoriesProvider = Provider<List<String>>((ref) {
  return ExpenseCategoryHelper.categories;
});

// Provider for category icons
final categoryIconsProvider = Provider<Map<String, String>>((ref) {
  return ExpenseCategoryHelper.categoryIcons;
});