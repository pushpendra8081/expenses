import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import '../widgets/expense_tile.dart';
import 'add_edit_expense_screen.dart';
import 'receipt_scan_screen.dart';
import '../models/expense.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedCategory = 'All';
  String _selectedSource = 'All';
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    final expenseList = ref.watch(expenseListProvider);
    final expenseStats = ref.watch(expenseStatisticsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          // Quick receipt filter toggle
          IconButton(
            icon: Icon(
              _selectedSource == 'Receipt' ? Icons.receipt : Icons.receipt_outlined,
              color: _selectedSource == 'Receipt' ? Colors.green : null,
            ),
            onPressed: () {
              setState(() {
                _selectedSource = _selectedSource == 'Receipt' ? 'All' : 'Receipt';
              });
            },
            tooltip: _selectedSource == 'Receipt' ? 'Show All Expenses' : 'Show Receipt Expenses Only',
          ),
        ],
      ),
      body: _buildBody(expenseList, expenseStats),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Scan',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ExpenseListState expenseList, ExpenseStatisticsState expenseStats) {
    if (expenseList.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (expenseList.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading expenses: ${expenseList.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(expenseListProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    return _buildHomeContent(expenseList.expenses, expenseStats);
  }

  Widget _buildHomeContent(List<Expense> expenses, ExpenseStatisticsState stats) {
    // Apply filters
    final filteredExpenses = _applyFilters(expenses);
    
    // Get the expense list state for the detailed summary
    final expenseListState = ref.watch(expenseListProvider);
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(expenseListProvider);
        ref.refresh(expenseStatisticsProvider);
      },
      child: CustomScrollView(
        slivers: [
          // Summary Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailedSummarySection(expenseListState, stats),
                  const SizedBox(height: 16),
                  _buildReceiptSummary(filteredExpenses),
                  // _buildQuickStats(filteredExpenses),
                  // const SizedBox(height: 16),
                  if (filteredExpenses.isNotEmpty) ...[
                    // _buildChartSection(filteredExpenses),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
          
          // Expense List Header with Filters
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Expenses (${filteredExpenses.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.filter_list,
                              color: _hasActiveFilters() ? Colors.blue : Colors.grey,
                            ),
                            onPressed: _showFilterDialog,
                            tooltip: 'Filter Expenses',
                          ),
                          if (_hasActiveFilters())
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.red),
                              onPressed: _clearAllFilters,
                              tooltip: 'Clear Filters',
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (_hasActiveFilters()) ...[
                    const SizedBox(height: 8),
                    _buildActiveFiltersChips(),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          
          // Total Amount Row
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtered Results',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (filteredExpenses.isNotEmpty)
                    Text(
                      'Total: \$${filteredExpenses.fold(0.0, (sum, expense) => sum + expense.amount).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Expense List
          if (filteredExpenses.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No expenses found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start by scanning a receipt or adding an expense manually',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final expense = filteredExpenses[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ExpenseTile(
                      expense: expense,
                      onEdit: () => _editExpense(expense),
                      onDelete: () => _deleteExpense(expense),
                    ),
                  );
                },
                childCount: filteredExpenses.length,
              ),
            ),
        ],
      ),
    );
  }

  List<Expense> _applyFilters(List<Expense> expenses) {
    var filtered = expenses;
    
    // Category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((expense) => expense.category == _selectedCategory).toList();
    }
    
    // Receipt source filter
    if (_selectedSource != 'All') {
      if (_selectedSource == 'Receipt') {
        filtered = filtered.where((expense) => expense.isFromReceipt).toList();
      } else if (_selectedSource == 'Manual') {
        filtered = filtered.where((expense) => !expense.isFromReceipt).toList();
      }
    }
    
    // Date range filter
    if (_selectedDateRange != null) {
      filtered = filtered.where((expense) {
        final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
        final startDate = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        final endDate = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day);
        return expenseDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               expenseDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    }
    
    // Sort by date (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));
    
    return filtered;
  }



  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddEditExpenseScreen(),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReceiptScanScreen(),
          ),
        );
        break;
    }
    
    // Reset to home tab after navigation
    if (index != 0) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      });
    }
  }

  void _editExpense(Expense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditExpenseScreen(expense: expense),
      ),
    );
  }

  Widget _buildDetailedSummarySection(ExpenseListState expenseList, ExpenseStatisticsState expenseStats) {
    if (expenseList.isLoading) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final expenses = expenseList.expenses;
    final filteredExpenses = _applyFilters(expenses);
    
    // Calculate comprehensive statistics
    final totalAmount = filteredExpenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
    final totalCount = filteredExpenses.length;
    final expensesFromReceipts = filteredExpenses.where((e) => e.isFromReceipt == true).length;
    final averageExpense = totalCount > 0 ? totalAmount / totalCount : 0.0;
    
    // Calculate today's expenses
    final today = DateTime.now();
    final todayExpenses = filteredExpenses.where((expense) {
      final expenseDate = expense.date;
      return expenseDate.year == today.year &&
             expenseDate.month == today.month &&
             expenseDate.day == today.day;
    });
    final todayTotal = todayExpenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
    final todayCount = todayExpenses.length;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row - Main statistics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryStatItem(
                'Total Amount',
                '\$${totalAmount.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                Colors.green,
              ),
              _buildSummaryStatItem(
                'Total Expenses',
                '$totalCount',
                Icons.receipt_long,
                Colors.blue,
              ),
              _buildSummaryStatItem(
                'Average',
                '\$${averageExpense.toStringAsFixed(2)}',
                Icons.trending_up,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bottom row - Today's statistics and receipt info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryStatItem(
                'Today',
                '\$${todayTotal.toStringAsFixed(2)} ($todayCount)',
                Icons.today,
                Colors.purple,
              ),
              _buildSummaryStatItem(
                'From Receipts',
                '$expensesFromReceipts',
                Icons.camera_alt,
                Colors.teal,
              ),
              _buildSummaryStatItem(
                'Coverage',
                '${totalCount > 0 ? (expensesFromReceipts / totalCount * 100).toStringAsFixed(1) : 0}%',
                Icons.pie_chart,
                Colors.indigo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStatItem(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptSummary(List<Expense> expenses) {
     if (expenses.isEmpty) return const SizedBox.shrink();
     
     final expensesFromReceipts = expenses.where((e) => e.isFromReceipt == true).length;
     final totalExpenses = expenses.length;
     final receiptPercentage = totalExpenses > 0 ? (expensesFromReceipts / totalExpenses * 100) : 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Receipt Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceAround,
               children: [
                 _buildReceiptStatItem('From Receipts', '$expensesFromReceipts'),
                 _buildReceiptStatItem('Total Expenses', '$totalExpenses'),
                 _buildReceiptStatItem('Coverage', '${receiptPercentage.toStringAsFixed(1)}%'),
               ],
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _deleteExpense(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete this expense of \$${expense.amount.toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(expenseListProvider.notifier).deleteExpense(expense.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Expense deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Filter helper methods
  bool _hasActiveFilters() {
    return _selectedCategory != 'All' || 
           _selectedSource != 'All' || 
           _selectedDateRange != null;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedSource = 'All';
      _selectedDateRange = null;
    });
  }

  Widget _buildActiveFiltersChips() {
    final chips = <Widget>[];
    
    if (_selectedCategory != 'All') {
      chips.add(
        Chip(
          label: Text(_selectedCategory),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () {
            setState(() {
              _selectedCategory = 'All';
            });
          },
        ),
      );
    }
    
    if (_selectedSource != 'All') {
      chips.add(
        Chip(
          label: Text(_selectedSource),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () {
            setState(() {
              _selectedSource = 'All';
            });
          },
        ),
      );
    }
    
    if (_selectedDateRange != null) {
      chips.add(
        Chip(
          label: Text(
            '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}'
          ),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () {
            setState(() {
              _selectedDateRange = null;
            });
          },
        ),
      );
    }
    
    return Wrap(
      spacing: 8,
      children: chips,
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Expenses'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Filter
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ['All', ...ExpenseCategoryHelper.categories]
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedCategory = value ?? 'All';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Source Filter
                    Text(
                      'Source',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSource,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ['All', 'Receipt', 'Manual']
                          .map((source) => DropdownMenuItem(
                                value: source,
                                child: Text(source),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedSource = value ?? 'All';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Date Range Filter
                    Text(
                      'Date Range',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final DateTimeRange? picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDateRange: _selectedDateRange,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            _selectedDateRange = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _selectedDateRange == null
                              ? 'Select date range'
                              : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}',
                          style: TextStyle(
                            color: _selectedDateRange == null ? Colors.grey[600] : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    if (_selectedDateRange != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            _selectedDateRange = null;
                          });
                        },
                        child: const Text('Clear date range'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Reset to original values
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _selectedCategory = 'All';
                      _selectedSource = 'All';
                      _selectedDateRange = null;
                    });
                  },
                  child: const Text('Clear All'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Apply the filters
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}