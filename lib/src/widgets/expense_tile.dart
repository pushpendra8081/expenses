import 'package:flutter/material.dart';
import '../models/expense.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool showLocation;
  final bool showDate;
  final bool compact;

  const ExpenseTile({
    super.key,
    required this.expense,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.showLocation = true,
    this.showDate = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: compact 
          ? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0)
          : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: compact 
              ? const EdgeInsets.all(0)
              : const EdgeInsets.all(5),
          child: compact ? _buildCompactLayout(context) : _buildFullLayout(context),
        ),
      ),
    );
  }

  Widget _buildFullLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Category Icon
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                ExpenseCategoryHelper.getIcon(expense.category),
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Main Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Amount Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          expense.merchant ?? expense.category,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        expense.formattedAmount,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),

                      if (showActions)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.grey[600],
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEdit?.call();
                            } else if (value == 'delete') {
                              _showDeleteConfirmation(context);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),


                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Category and Date Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          expense.category,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      // Receipt indicator
                      if (expense.isFromReceipt) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt,
                                size: 12,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Receipt',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      if (showDate) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(expense.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      
                      if (showLocation && expense.hasLocation) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        
        // Notes Section (if present)
        if (expense.notes?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.note,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    expense.notes!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Row(
      children: [
        // Category Icon (smaller)
        CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            ExpenseCategoryHelper.getIcon(expense.category),
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 16,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Main Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                expense.merchant ?? expense.category,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Category and indicators
              Row(
                children: [
                  Text(
                    expense.category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  // Receipt indicator for compact layout
                  if (expense.isFromReceipt) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.receipt,
                      size: 12,
                      color: Colors.green[600],
                    ),
                  ],
                  
                  if (showDate) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• ${_formatDate(expense.date)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  
                  if (showLocation && expense.hasLocation) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                  ],
                  
                  if (expense.notes?.isNotEmpty == true) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.note,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        
        // Amount and Actions
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              expense.formattedAmount,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
                ],
              ),
          ],
        );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this expense?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    ExpenseCategoryHelper.getIcon(expense.category),
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.merchant ?? expense.category,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${expense.formattedAmount} • ${_formatDate(expense.date)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final expenseDate = DateTime(date.year, date.month, date.day);
    
    if (expenseDate == today) {
      return 'Today';
    } else if (expenseDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return _getDayName(date.weekday);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}

// Extension for easy usage
extension ExpenseTileExtension on Expense {
  Widget toTile({
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    bool showActions = true,
    bool showLocation = true,
    bool showDate = true,
    bool compact = false,
  }) {
    return ExpenseTile(
      expense: this,
      onTap: onTap,
      onEdit: onEdit,
      onDelete: onDelete,
      showActions: showActions,
      showLocation: showLocation,
      showDate: showDate,
      compact: compact,
    );
  }
}