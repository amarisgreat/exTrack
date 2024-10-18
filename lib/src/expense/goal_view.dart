import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Import FirebaseAuth to get the user
import 'package:firebase_database/firebase_database.dart';

class ActiveGoalsPage extends StatefulWidget {
  const ActiveGoalsPage({super.key});

  @override
  _ActiveGoalsPageState createState() => _ActiveGoalsPageState();
}

class _ActiveGoalsPageState extends State<ActiveGoalsPage> {
  late DatabaseReference _database;
  List<Map<String, dynamic>> _goals = [];
  final List<TextEditingController> _amountControllers = [];
  String _selectedTimeUnit = 'Days'; // Default time unit

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  // Initialize the database reference using the current user's UID
  Future<void> _initializeDatabase() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;  // Get the user's unique ID
      _database = FirebaseDatabase.instance.ref().child('goal').child(uid);  // Aligned with the path used in ExpenseInputPage
      _fetchGoals();  // Fetch goals after initializing the database reference
    }
  }

  Future<void> _fetchGoals() async {
    _database.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final List<Map<String, dynamic>> loadedGoals = [];
      _amountControllers.clear(); // Clear any previous controllers

      data.forEach((key, value) {
        loadedGoals.add({
          'id': key,
          'goalName': value['goalName'],
          'finalAmount': value['finalAmount'],
          'goalCompletionTime': DateTime.parse(value['goalCompletionTime']),
          'amountContributed': value['amountContributed'] ?? 0.0,
        });
        _amountControllers.add(TextEditingController()); // Initialize a controller for each goal
      });
      setState(() {
        _goals = loadedGoals;
      });
    });
  }

  double _calculateRemainingAmount(Map<String, dynamic> goal) {
    return goal['finalAmount'] - goal['amountContributed'];
  }

  String _calculateTimeLeft(Map<String, dynamic> goal) {
    final DateTime completionTime = goal['goalCompletionTime'];
    final Duration timeLeft = completionTime.difference(DateTime.now());

    if (timeLeft.isNegative) return 'Goal Time Passed';

    switch (_selectedTimeUnit) {
      case 'Weeks':
        return '${(timeLeft.inDays / 7).ceil()} weeks left';
      case 'Months':
        return '${(timeLeft.inDays / 30).ceil()} months left';
      default:
        return '${timeLeft.inDays} days left';
    }
  }

  double _calculateProgress(Map<String, dynamic> goal) {
    return goal['finalAmount'] > 0
        ? goal['amountContributed'] / goal['finalAmount']
        : 0.0; // Prevent division by zero
  }

  double _calculateSuggestedContribution(Map<String, dynamic> goal, String frequency) {
    final remainingAmount = _calculateRemainingAmount(goal);
    final DateTime completionTime = goal['goalCompletionTime'];
    final Duration timeLeft = completionTime.difference(DateTime.now());

    switch (frequency) {
      case 'Weekly':
        return remainingAmount / (timeLeft.inDays / 7).ceil();
      case 'Monthly':
        return remainingAmount / (timeLeft.inDays / 30).ceil();
      default: // Daily
        return remainingAmount / timeLeft.inDays;
    }
  }

  void _updateContributedAmount(String goalId, double amount) async {
    final goalRef = _database.child(goalId);
    final snapshot = await goalRef.get();
    if (snapshot.exists) {
      final currentAmount = snapshot.child('amountContributed').value as double? ?? 0.0;
      await goalRef.update({'amountContributed': currentAmount + amount});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal not found.')),
      );
    }
  }

  void _deleteGoal(String goalId) async {
    await _database.child(goalId).remove();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Goal deleted successfully!')),
    );
    _fetchGoals(); // Refresh the goal list after deletion
  }

  @override
  void dispose() {
    // Dispose of all controllers
    for (var controller in _amountControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Goals'),
      ),
      body: _goals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Text(
                        'View time left in: ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: _selectedTimeUnit,
                        items: const [
                          DropdownMenuItem(value: 'Days', child: Text('Days')),
                          DropdownMenuItem(value: 'Weeks', child: Text('Weeks')),
                          DropdownMenuItem(value: 'Months', child: Text('Months')),
                        ],
                        onChanged: (newValue) {
                          setState(() {
                            _selectedTimeUnit = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _goals.length,
                    itemBuilder: (context, index) {
                      final goal = _goals[index];
                      final remainingAmount = _calculateRemainingAmount(goal);
                      final progress = _calculateProgress(goal);
                      final timeLeft = _calculateTimeLeft(goal);
                      String selectedFrequency = 'Daily'; // Default frequency
                      final bool isGoalCompleted = goal['amountContributed'] >= goal['finalAmount'];

                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    goal['goalName'],
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Goal'),
                                          content: const Text('Are you sure you want to delete this goal?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                _deleteGoal(goal['id']);
                                                Navigator.pop(context);
                                              },
                                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (isGoalCompleted)
                                const Text(
                                  'Goal Completed!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else ...[
                                Text('Time left: $timeLeft'),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[300],
                                  color: Colors.blue,
                                ),
                                const SizedBox(height: 10),
                                Text('Remaining amount: \$${remainingAmount.toStringAsFixed(2)}'),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Text(
                                      'Contribute:',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 10),
                                    DropdownButton<String>(
                                      value: selectedFrequency,
                                      items: const [
                                        DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                                        DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                                        DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                                      ],
                                      onChanged: (newValue) {
                                        setState(() {
                                          selectedFrequency = newValue!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Suggested contribution: \$${_calculateSuggestedContribution(goal, selectedFrequency).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _amountControllers[index],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Amount',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    final amount = double.tryParse(_amountControllers[index].text);
                                    if (amount != null && amount > 0) {
                                      _updateContributedAmount(goal['id'], amount);
                                      _amountControllers[index].clear();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter a valid amount.')),
                                      );
                                    }
                                  },
                                  child: const Text('Add Contribution'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
