import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class BillAndSubscriptionPage extends StatefulWidget {
  const BillAndSubscriptionPage({super.key});

  @override
  _BillAndSubscriptionPageState createState() => _BillAndSubscriptionPageState();
}

class _BillAndSubscriptionPageState extends State<BillAndSubscriptionPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _peopleController = TextEditingController();

  String _selectedBillType = 'Bill';  
  String _selectedSubscription = 'Netflix';  // Default subscription value
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
      _databaseRef = FirebaseDatabase.instance.ref().child('users').child(uid).child('billsAndSubscriptions');
    }
  }

  void _saveBillOrSubscription() {
    if (_databaseRef != null) {
      String type = _selectedBillType == 'Bill' ? 'Bill' : 'Subscription';

      _databaseRef!.push().set({
        'type': type,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'details': _detailsController.text,
        'dueDate': _dueDateController.text,
        'peopleInvolved': _peopleController.text,
        'subscriptionType': _selectedSubscription,
        'timestamp': DateTime.now().toIso8601String(),
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully!')),
        );
        _clearForm();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $error')),
        );
      });
    }
  }

  void _clearForm() {
    _amountController.clear();
    _detailsController.clear();
    _dueDateController.clear();
    _peopleController.clear();
    setState(() {
      _selectedBillType = 'Bill';
      _selectedSubscription = 'Netflix';
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _detailsController.dispose();
    _dueDateController.dispose();
    _peopleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill & Subscription Manager'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Dropdown for Bill or Subscription
            DropdownButton<String>(
              value: _selectedBillType,
              items: const [
                DropdownMenuItem(value: 'Bill', child: Text('Bill')),
                DropdownMenuItem(value: 'Subscription', child: Text('Subscription')),
              ],
              onChanged: (newValue) {
                setState(() {
                  _selectedBillType = newValue!;
                });
              },
            ),
            
            const SizedBox(height: 16),

            // Amount Input Field
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Bill Details Input Field
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(
                labelText: 'Details',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Due Date Input Field
            TextField(
              controller: _dueDateController,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Due Date',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // People Involved Input Field
            TextField(
              controller: _peopleController,
              decoration: const InputDecoration(
                labelText: 'People Involved (comma-separated)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Subscription Dropdown
            if (_selectedBillType == 'Subscription')
              DropdownButton<String>(
                value: _selectedSubscription,
                items: const [
                  DropdownMenuItem(value: 'Netflix', child: Text('Netflix')),
                  DropdownMenuItem(value: 'Spotify', child: Text('Spotify')),
                  DropdownMenuItem(value: 'Hulu', child: Text('Hulu')),
                  DropdownMenuItem(value: 'Amazon Prime', child: Text('Amazon Prime')),
                ],
                onChanged: (newValue) {
                  setState(() {
                    _selectedSubscription = newValue!;
                  });
                },
              ),

            const SizedBox(height: 16),

            // Save Button
            ElevatedButton(
              onPressed: _saveBillOrSubscription,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
