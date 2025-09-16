import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../services/ocr_service.dart';
import '../services/suggestion_service.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import 'add_edit_expense_screen.dart';

class ReceiptScanScreen extends ConsumerStatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  ConsumerState<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends ConsumerState<ReceiptScanScreen> {
  bool _isScanning = false;
  Expense? _lastScanResult;
  List<CategorySuggestion> _suggestions = [];
  String? _selectedCategory;
  
  @override
  void initState() {
    super.initState();
    _loadPersistedScanResult();
  }
  
  // Load persisted scan result from shared preferences
  Future<void> _loadPersistedScanResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scanResultJson = prefs.getString('last_scan_result');
      final suggestionsJson = prefs.getString('scan_suggestions');
      final selectedCategory = prefs.getString('selected_category');
      
      if (scanResultJson != null) {
        final scanData = json.decode(scanResultJson);
        setState(() {
          _lastScanResult = Expense(
             id: scanData['id'] ?? '',
             amount: (scanData['amount'] ?? 0.0).toDouble(),
             category: scanData['category'] ?? ExpenseCategoryHelper.categories.first,
             date: DateTime.parse(scanData['date'] ?? DateTime.now().toIso8601String()),
             merchant: scanData['merchant'],
             notes: scanData['notes'],
             createdAt: DateTime.parse(scanData['createdAt'] ?? DateTime.now().toIso8601String()),
             updatedAt: DateTime.parse(scanData['updatedAt'] ?? DateTime.now().toIso8601String()),
             isFromReceipt: scanData['isFromReceipt'] ?? true,
           );
        });
      }
      
      if (suggestionsJson != null) {
        final suggestionsData = json.decode(suggestionsJson) as List;
        setState(() {
          _suggestions = suggestionsData.map((s) => CategorySuggestion(
            category: s['category'],
            confidence: s['confidence'].toDouble(),
            reason: s['reason'],
          )).toList();
        });
      }
      
      if (selectedCategory != null) {
        setState(() {
          _selectedCategory = selectedCategory;
        });
      }
    } catch (e) {
      // Ignore errors when loading persisted data
    }
  }
  
  // Persist scan result to shared preferences
  Future<void> _persistScanResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_lastScanResult != null) {
        final scanData = {
           'id': _lastScanResult!.id,
           'amount': _lastScanResult!.amount,
           'category': _lastScanResult!.category,
           'date': _lastScanResult!.date.toIso8601String(),
           'merchant': _lastScanResult!.merchant,
           'notes': _lastScanResult!.notes,
           'createdAt': _lastScanResult!.createdAt.toIso8601String(),
           'updatedAt': _lastScanResult!.updatedAt.toIso8601String(),
           'isFromReceipt': _lastScanResult!.isFromReceipt,
         };
        await prefs.setString('last_scan_result', json.encode(scanData));
      }
      
      if (_suggestions.isNotEmpty) {
        final suggestionsData = _suggestions.map((s) => {
          'category': s.category,
          'confidence': s.confidence,
          'reason': s.reason,
        }).toList();
        await prefs.setString('scan_suggestions', json.encode(suggestionsData));
      }
      
      if (_selectedCategory != null) {
        await prefs.setString('selected_category', _selectedCategory!);
      }
    } catch (e) {
      // Ignore errors when persisting data
    }
  }
  
  // Clear persisted scan data
  Future<void> _clearPersistedScanResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_scan_result');
      await prefs.remove('scan_suggestions');
      await prefs.remove('selected_category');
    } catch (e) {
      // Ignore errors when clearing data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        actions: [
          if (_lastScanResult != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createExpenseFromScan,
              tooltip: 'Create Expense',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scan Options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scan Your Receipt',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose camera or gallery to scan receipt',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isScanning ? null : () => _scanReceipt(useCamera: true),
                            icon: _isScanning
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.camera_alt),
                            label: Text(_isScanning ? 'Scanning...' : 'Camera'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isScanning ? null : () => _scanReceipt(useCamera: false),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Scan Results
            if (_lastScanResult != null) ...[
              const SizedBox(height: 16),
              _buildScanResults(),
            ],
            
            // Category Suggestions
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCategorySuggestions(),
            ],
            


          ],
        ),
      ),
    );
  }
  

  
  Widget _buildScanResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Scan Results',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _scanReceipt(useCamera: true),
                  tooltip: 'Scan Again',
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Amount
            _buildResultItem(
              'Amount',
              '\$${_lastScanResult!.amount.toStringAsFixed(2)}',
              Icons.attach_money,
            ),
            
            // Merchant
            if (_lastScanResult!.merchant != null && _lastScanResult!.merchant!.isNotEmpty)
              _buildResultItem(
                'Merchant',
                _lastScanResult!.merchant!,
                Icons.store,
              ),
            
            // Date
            _buildResultItem(
              'Date',
              '${_lastScanResult!.date.day}/${_lastScanResult!.date.month}/${_lastScanResult!.date.year}',
              Icons.calendar_today,
            ),
            
            // Notes (if available)
            if (_lastScanResult!.notes != null && _lastScanResult!.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text('Notes'),
                leading: const Icon(Icons.text_fields),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _lastScanResult!.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _scanReceipt(useCamera: true),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Scan Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _createExpenseFromScan,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Expense'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // <-- Green color
                      foregroundColor: Colors.white, // <-- Text & icon color
                    ),
                  ),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategorySuggestions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Category Suggestions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestions.map((suggestion) => FilterChip(
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      suggestion.category,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${(suggestion.confidence * 100).toInt()}% confidence',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                selected: _selectedCategory == suggestion.category,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? suggestion.category : null;
                  });
                },
                avatar: Icon(
                  ExpenseCategoryHelper.getIcon(suggestion.category),
                  size: 16,
                ),
              )).toList(),
            ),
            if (_selectedCategory != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      ExpenseCategoryHelper.getIcon(_selectedCategory!),
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Selected: $_selectedCategory',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Future<void> _scanReceipt({bool useCamera = true}) async {
    setState(() {
      _isScanning = true;
      _lastScanResult = null;
      _suggestions = [];
      _selectedCategory = null;
    });
    
    // Clear any previously persisted scan data when starting a new scan
    await _clearPersistedScanResult();
    
    try {
      final result = await OCRService.scanReceipt(
        source: useCamera ? ImageSource.camera : ImageSource.gallery,
      );
      
      if (result != null) {
        setState(() {
          _lastScanResult = result;
        });
        
        // Generate category suggestions
        final suggestions = SuggestionService.getSmartSuggestions(
          merchant: result.merchant,
          notes: result.notes,
          amount: result.amount,
        );
        
        setState(() {
          _suggestions = suggestions;
        });
        
        // Persist scan results to survive screen rebuilds
        await _persistScanResult();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receipt scanned successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No receipt data found. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to scan receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }
  
  void _createExpenseFromScan() async {
    if (_lastScanResult == null) return;
    
    try {
      // Create a pre-filled expense from scan results
      final expense = Expense.create(
        amount: _lastScanResult!.amount ?? 0.0,
        category: _selectedCategory ?? ExpenseCategoryHelper.categories.first,
        date: _lastScanResult!.date ?? DateTime.now(),
        merchant: _lastScanResult!.merchant,
        notes: _lastScanResult!.notes,
        isFromReceipt: true,
      );
      
      // Auto-save the expense to prevent data loss
      await ref.read(expenseListProvider.notifier).addExpense(expense);
      
      // Clear persisted scan data since expense has been created
      await _clearPersistedScanResult();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense saved successfully! You can edit it from the home screen.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate back to home screen after saving expense
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}