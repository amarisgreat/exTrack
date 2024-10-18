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

  final List<String> _transactionTypes = ['Income', 'Expense'];
  
  final List<String> _incomeCategories = ['Salary', 'Gift', 'Investment', 'Other'];  // Categories for Income
  final List<String> _expenseCategories = ['Food', 'Rent', 'Shopping', 'Transport', 'Other'];  // Categories for Expense

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
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
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
