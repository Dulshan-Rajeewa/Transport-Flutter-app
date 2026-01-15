import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/data_provider.dart';
import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expenseToEdit;
  
  const AddExpenseScreen({super.key, this.expenseToEdit});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  Map<String, dynamic>? _selectedType;
  DateTime _selectedDate = DateTime.now();
  bool _showExpenseTypePicker = false;

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  final List<Map<String, dynamic>> _expenseTypes = [
    {
      'id': 'driver_pay_additional',
      'label': 'Driver Pay (additional)',
      'icon': Icons.person,
      'description': 'Additional payment for driver beyond monthly KM-based payment',
    },
    {
      'id': 'helper_salary',
      'label': 'Helper Salary',
      'icon': Icons.people,
      'description': 'Monthly or daily salary for helper',
    },
    {
      'id': 'diesel_additional',
      'label': 'Diesel/Fuel (additional)',
      'icon': Icons.local_gas_station,
      'description': 'Additional fuel expenses beyond monthly KM-based fuel cost',
    },
    {
      'id': 'repairs',
      'label': 'Repairs & Maintenance',
      'icon': Icons.build,
      'description': 'Vehicle repair costs',
    },
    {
      'id': 'monthly_service',
      'label': 'Monthly Service',
      'icon': Icons.calendar_today,
      'description': 'Regular vehicle servicing',
    },
    {
      'id': 'other',
      'label': 'Other Expenses',
      'icon': Icons.receipt,
      'description': 'Miscellaneous business expenses',
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // If editing, populate fields with existing data
    if (widget.expenseToEdit != null) {
      _amountController.text = widget.expenseToEdit!.amount.toString();
      _descriptionController.text = widget.expenseToEdit!.description ?? '';
      _selectedDate = widget.expenseToEdit!.date;
      
      // Find matching expense type
      _selectedType = _expenseTypes.firstWhere(
        (type) => type['label'] == widget.expenseToEdit!.type,
        orElse: () => _expenseTypes.last, // Default to 'Other'
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleAddExpense() async {
    if (_formKey.currentState!.validate()) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);

      final expense = Expense(
        id: widget.expenseToEdit?.id,
        type: _selectedType?['label'] ?? 'Other',
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        date: _selectedDate,
        createdAt: widget.expenseToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final bool success;
      if (widget.expenseToEdit != null) {
        success = await dataProvider.updateExpense(widget.expenseToEdit!.id!, expense);
      } else {
        success = await dataProvider.addExpense(expense);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.expenseToEdit != null 
                ? 'Expense updated successfully!' 
                : 'Expense added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(dataProvider.error ?? (widget.expenseToEdit != null 
                ? 'Failed to update expense' 
                : 'Failed to add expense')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExpenseTypeModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Expense Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _expenseTypes.length,
                  itemBuilder: (context, index) {
                  final type = _expenseTypes[index];
                  final isSelected =
                      _selectedType?['id'] == type['id'];
                  return ListTile(
                    leading: Icon(
                      type['icon'],
                      color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    title: Text(
                      type['label'],
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      type['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedType = type;
                        _showExpenseTypePicker = false;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    if (_showExpenseTypePicker) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showExpenseTypeModal();
        setState(() {
          _showExpenseTypePicker = false;
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expenseToEdit != null ? 'Edit Expense' : 'Add Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Expense Type Picker
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showExpenseTypePicker = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedType?['icon'] ?? Icons.category,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedType?['label'] ?? 'Select Expense Type',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (_selectedType != null)
                              Text(
                                _selectedType!['description'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurface),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (Rs)',
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: 'Enter amount',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Add details about this expense',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Date Picker with Today/Yesterday buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedDate = DateTime.now();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _isToday(_selectedDate)
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            foregroundColor: _isToday(_selectedDate)
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                          ),
                          child: const Text('Today'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedDate =
                                  DateTime.now().subtract(const Duration(days: 1));
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _isYesterday(_selectedDate)
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            foregroundColor: _isYesterday(_selectedDate)
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                          ),
                          child: const Text('Yesterday'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _selectDate(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                        ),
                        child: const Icon(Icons.calendar_today),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: dataProvider.isLoading ? null : _handleAddExpense,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: dataProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.expenseToEdit != null ? 'Update Expense' : 'Add Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
