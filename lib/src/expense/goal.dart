import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Import for Firebase Auth to get the user
import 'package:firebase_database/firebase_database.dart';

class ExpenseInputPage extends StatefulWidget {
  const ExpenseInputPage({super.key});

  @override
  _ExpenseInputPageState createState() => _ExpenseInputPageState();
}

class _ExpenseInputPageState extends State<ExpenseInputPage> {
  final _formKey = GlobalKey<FormState>();
  String? _goalName;
  double? _finalAmount;
  DateTime? _goalCompletionTime;
  
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _goalCompletionController = TextEditingController();

  @override
  void dispose() {
    _goalCompletionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Goal Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the goal name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _goalName = value;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Final Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the final amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onSaved: (value) {
                  _finalAmount = double.tryParse(value!);
                },
              ),
              TextFormField(
                controller: _goalCompletionController, 
                decoration: const InputDecoration(labelText: 'Goal Completion Time'),
                readOnly: true,
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  setState(() {
                    _goalCompletionTime = pickedDate;
                    _goalCompletionController.text =
                        "${_goalCompletionTime!.day}/${_goalCompletionTime!.month}/${_goalCompletionTime!.year}";
                  });
                },
                validator: (value) {
                  if (_goalCompletionTime == null) {
                    return 'Please select a goal completion time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    
                    // Get current user
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      String uid = user.uid; // Get the user's unique ID
                      
                      // Save data to the user's unique database node
                      await _database.child('goal').child(uid).push().set({
                        'goalName': _goalName,
                        'finalAmount': _finalAmount,
                        'goalCompletionTime': _goalCompletionTime?.toIso8601String(),
                        'amountContributed': 0,
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Goal added successfully!')),
                      );
                      
                      // Reset the form after submission
                      _formKey.currentState!.reset();
                      setState(() {
                        _goalCompletionTime = null;
                        _goalCompletionController.clear();
                      });
                    }
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
