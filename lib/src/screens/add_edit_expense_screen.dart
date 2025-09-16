import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../services/ocr_service.dart';
import '../services/location_service.dart';
import '../services/suggestion_service.dart';

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final Expense? expense;
  
  const AddEditExpenseScreen({super.key, this.expense});

  @override
  ConsumerState<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedCategory = ExpenseCategoryHelper.categories.first;
  DateTime _selectedDate = DateTime.now();
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  List<CategorySuggestion> _suggestions = [];
  
  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _initializeWithExpense(widget.expense!);
    }
    _loadCurrentLocation();
  }
  
  void _initializeWithExpense(Expense expense) {
    _amountController.text = expense.amount.toString();
    _merchantController.text = expense.merchant ?? '';
    _notesController.text = expense.notes ?? '';
    _selectedCategory = expense.category;
    _selectedDate = expense.date;
    _latitude = expense.latitude;
    _longitude = expense.longitude;
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Add Expense' : 'Edit Expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _scanReceipt,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                  helperText: 'Enter the expense amount',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
                onChanged: _onFieldChanged,
              ),
              const SizedBox(height: 16),
              
              // Category Field with Suggestions
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: ExpenseCategoryHelper.categories
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(
                                    ExpenseCategoryHelper.getIcon(category),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                  if (_suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Suggestions:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: _suggestions.map((suggestion) => ActionChip(
                        label: Text(
                          '${suggestion.category} (${(suggestion.confidence * 100).toInt()}%)',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedCategory = suggestion.category;
                          });
                        },
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      )).toList(),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              
              // Merchant Field
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(
                  labelText: 'Merchant (Optional)',
                  border: OutlineInputBorder(),
                  helperText: 'Where did you make this purchase?',
                ),
                onChanged: _onFieldChanged,
              ),
              const SizedBox(height: 16),
              
              // Date Field
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Notes Field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  helperText: 'Add any additional details',
                ),
                maxLines: 3,
                onChanged: _onFieldChanged,
              ),
              const SizedBox(height: 16),
              
              // Location Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on),
                          const SizedBox(width: 8),
                          Text(
                            'Location',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          if (_isLoadingLocation)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.my_location),
                              onPressed: _loadCurrentLocation,
                              tooltip: 'Get current location',
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getLocationText(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _scanReceipt,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt),
                          SizedBox(width: 8),
                          Text('Scan Receipt'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveExpense,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.expense == null ? 'Add Expense' : 'Update Expense'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _onFieldChanged(String value) {
    // Generate suggestions when merchant or notes change
    final amount = double.tryParse(_amountController.text);
    final merchant = _merchantController.text.trim();
    final notes = _notesController.text.trim();
    
    if (merchant.isNotEmpty || notes.isNotEmpty || amount != null) {
      final suggestions = SuggestionService.getSmartSuggestions(
        merchant: merchant.isNotEmpty ? merchant : null,
        notes: notes.isNotEmpty ? notes : null,
        amount: amount,
      );
      
      setState(() {
        _suggestions = suggestions;
      });
    } else {
      setState(() {
        _suggestions = [];
      });
    }
  }
  
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }
  
  Future<void> _loadCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    
    try {
      final locationResult = await LocationService.getCurrentLocation();
      if (locationResult.isSuccess && locationResult.location != null) {
        setState(() {
          _latitude = locationResult.location!.latitude;
          _longitude = locationResult.location!.longitude;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locationResult.error ?? 'Failed to get location'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }
  
  String _getLocationText() {
    if (_latitude != null && _longitude != null) {
      return 'Location captured: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}';
    }
    return 'No location captured. Tap the location button to get current location.';
  }
  
  Future<void> _scanReceipt() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final ocrResult = await OCRService.scanReceipt();
      
      if (ocrResult != null) {
        // Update form fields with OCR results
        if (ocrResult.amount != null) {
          _amountController.text = ocrResult.amount!.toStringAsFixed(2);
        }
        
        if (ocrResult.merchant != null && ocrResult.merchant!.isNotEmpty) {
          _merchantController.text = ocrResult.merchant!;
        }
        
        if (ocrResult.date != null) {
          setState(() {
            _selectedDate = ocrResult.date!;
          });
        }
        
        // Generate suggestions based on OCR results
        _onFieldChanged('');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receipt scanned successfully!'),
              backgroundColor: Colors.green,
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
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final amount = double.parse(_amountController.text);
      final merchant = _merchantController.text.trim();
      final notes = _notesController.text.trim();
      
      if (widget.expense == null) {
        // Create new expense
        final expense = Expense.create(
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          merchant: merchant.isNotEmpty ? merchant : null,
          notes: notes.isNotEmpty ? notes : null,
          latitude: _latitude,
          longitude: _longitude,
        );
        
        await ref.read(expenseListProvider.notifier).addExpense(expense);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update existing expense
        final updatedExpense = widget.expense!.copyWith(
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          merchant: merchant.isNotEmpty ? merchant : null,
          notes: notes.isNotEmpty ? notes : null,
          latitude: _latitude,
          longitude: _longitude,
          updatedAt: DateTime.now(),
        );
        
        await ref.read(expenseListProvider.notifier).updateExpense(updatedExpense);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      if (mounted) {
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}