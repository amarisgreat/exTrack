import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:extrack/src/expense/cam_expense.dart';  // Import the ScanBillPage

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _selectedTransactionType;
  String? _selectedCategory;
  DateTime? _selectedDate;
  bool _isRecurring = false;
  int _recurrenceInterval = 1; // Default to 1 month

  final List<String> _transactionTypes = ['Income', 'Expense'];

  final List<String> _incomeCategories = ['Salary', 'Gift', 'Investment', 'Other'];  // Categories for Income
  final List<String> _expenseCategories = ['Food', 'Rent', 'Shopping', 'Transport', 'Other'];  // Categories for Expense

  final double _expenseLimit = 1000.0; // Hardcoded expense limit
  DatabaseReference? _databaseRef;

  @override
  void initState() {
    super.initState();
    _initializeDatabaseReference();
  }

  void _initializeDatabaseReference() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      _databaseRef = FirebaseDatabase.instance.ref().child('transactions').child(uid);
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate() && _selectedDate != null && _databaseRef != null) {
      String key = _databaseRef!.push().key!;

      await _databaseRef!.child(key).set({
        'amount': double.parse(_amountController.text),
        'transactionType': _selectedTransactionType,
        'category': _selectedCategory,
        'date': _selectedDate!.toIso8601String(),
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'timestamp': DateTime.now().toIso8601String(),
        'isRecurring': _isRecurring,
        'recurrenceInterval': _isRecurring ? _recurrenceInterval : null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction Saved')),
      );

      _amountController.clear();
      _notesController.clear();
      setState(() {
        _selectedTransactionType = null;
        _selectedCategory = null;
        _selectedDate = null;
        _isRecurring = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: 'Select Transaction Date',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Dummy methods for calculating total income and expenses. You should replace this with actual database calculations.
  double _calculateTotalIncome() {
    return 2000.0; // Example value
  }

  double _calculateTotalExpense() {
    return 1500.0; // Example value
  }

  double _calculateBalance() {
    return _calculateTotalIncome() - _calculateTotalExpense();
  }

  // Build the transaction summary
  Widget _buildTransactionSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total Income: \$${_calculateTotalIncome()}'),
        Text('Total Expenses: \$${_calculateTotalExpense()}'),
        Text('Balance: \$${_calculateBalance()}'),
      ],
    );
  }

  // Expense limit warning widget
  Widget _buildExpenseWarning() {
    double totalExpense = _calculateTotalExpense();
    if (totalExpense > _expenseLimit) {
      return Text(
        'Warning: You have exceeded your expense limit!',
        style: const TextStyle(color: Colors.red),
      );
    }
    return Container(); // No warning if within the limit
  }

  // Recurring transaction widget
  Widget _buildRecurringOptions() {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Recurring Transaction'),
          value: _isRecurring,
          onChanged: (bool? value) {
            setState(() {
              _isRecurring = value!;
            });
          },
        ),
        if (_isRecurring)
          DropdownButtonFormField<int>(
            value: _recurrenceInterval,
            decoration: const InputDecoration(labelText: 'Repeat every'),
            items: [1, 2, 3, 6, 12].map((interval) {
              return DropdownMenuItem(
                value: interval,
                child: Text('$interval month(s)'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _recurrenceInterval = value!;
              });
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTransactionSummary(), // Add transaction summary at the top
              const SizedBox(height: 16),
              _buildExpenseWarning(), // Add expense warning
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTransactionType,
                decoration: const InputDecoration(labelText: 'Transaction Type'),
                items: _transactionTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTransactionType = value;
                    _selectedCategory = null; // Reset the category when transaction type changes
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a transaction type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: (_selectedTransactionType == 'Income'
                        ? _incomeCategories
                        : _expenseCategories)
                    .map((category) {
                  Icon categoryIcon;
                  switch (category) {
                    case 'Food':
                      categoryIcon = const Icon(Icons.restaurant);
                      break;
                    case 'Rent':
                      categoryIcon = const Icon(Icons.home);
                      break;
                    case 'Shopping':
                      categoryIcon = const Icon(Icons.shopping_cart);
                      break;
                    case 'Transport':
                      categoryIcon = const Icon(Icons.directions_car);
                      break;
                    default:
                      categoryIcon = const Icon(Icons.category);
                  }
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        categoryIcon,
                        const SizedBox(width: 8),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                keyboardType: TextInputType.text,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _selectedDate == null
                      ? 'Select Date'
                      : 'Date: ${DateFormat.yMd().format(_selectedDate!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 24),
              _buildRecurringOptions(), // Recurring options
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveTransaction,
                child: const Text('Save Transaction'),
              ),
              const SizedBox(height: 16),
              // Add the button to navigate to the ScanBillPage
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanBillPage()),
                  );
                },
                icon: const Icon(Icons.camera_alt), // Icon for the button
                label: const Text('Go to Scan Bill'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
