import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:extrack/src/login/login_page.dart';
import 'package:extrack/src/expense/add_expense_page.dart';
import 'package:extrack/src/expense/goal_view.dart'; 
import 'package:extrack/src/expense/goal.dart';  // Add necessary imports

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _totalBalance = 0.0;
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _activeGoals = [];  
  List<Map<String, dynamic>> _completedGoals = []; 
  DatabaseReference? _databaseRef;
  DatabaseReference? _goalsDatabaseRef; 

  @override
  void initState() {
    super.initState();
    _initializeDatabaseReference();
    _fetchData();
    _fetchGoals();  
  }

  void _initializeDatabaseReference() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      _databaseRef = FirebaseDatabase.instance.ref().child('transactions').child(uid);
      _goalsDatabaseRef = FirebaseDatabase.instance.ref().child('goal').child(uid); // Reference to the user's goals
    }
  }

  Future<void> _fetchData() async {
    if (_databaseRef != null) {
      _databaseRef!.onValue.listen((event) {
        final transactions = event.snapshot.value as Map<dynamic, dynamic>?;

        if (transactions != null) {
          double balance = 0.0;
          List<Map<String, dynamic>> recentTransactions = [];

          transactions.forEach((key, value) {
            double amount = value['amount'] as double;
            String transactionType = value['transactionType'];
            String category = value['category'];
            String date = value['date'];

            if (transactionType == 'Income') {
              balance += amount;
            } else if (transactionType == 'Expense') {
              balance -= amount;
            }

            recentTransactions.add({
              'amount': amount,
              'transactionType': transactionType,
              'category': category,
              'date': DateTime.parse(date),
            });
          });

          recentTransactions.sort((a, b) => b['date'].compareTo(a['date']));

          setState(() {
            _totalBalance = balance;
            _recentTransactions = recentTransactions.take(3).toList();
          });
        }
      });
    }
  }

  Future<void> _fetchGoals() async {
    if (_goalsDatabaseRef != null) {
      _goalsDatabaseRef!.onValue.listen((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
        List<Map<String, dynamic>> activeGoals = [];
        List<Map<String, dynamic>> completedGoals = [];

        data.forEach((key, value) {
          final finalAmount = value['finalAmount'] as double;
          final amountContributed = value['amountContributed'] as double? ?? 0.0;
          final isCompleted = amountContributed >= finalAmount;
          final DateTime goalCompletionTime = DateTime.parse(value['goalCompletionTime']);

          Map<String, dynamic> goal = {
            'id': key,
            'goalName': value['goalName'],
            'finalAmount': finalAmount,
            'goalCompletionTime': goalCompletionTime,
            'amountContributed': amountContributed,
          };

          if (isCompleted) {
            completedGoals.add(goal);
          } else {
            activeGoals.add(goal);
          }
        });

        setState(() {
          _activeGoals = activeGoals;
          _completedGoals = completedGoals;
        });
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  // Calculate the progress of a goal
  double _calculateProgress(Map<String, dynamic> goal) {
    return goal['finalAmount'] > 0
        ? goal['amountContributed'] / goal['finalAmount']
        : 0.0;  // Prevent division by zero
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(  // Added scroll view for content
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Goals Section
              if (_activeGoals.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Goals',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 150,  // Height of the goals section
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _activeGoals.length,
                        itemBuilder: (context, index) {
                          final goal = _activeGoals[index];
                          final progress = _calculateProgress(goal);

                          return Container(
                            width: 200,  // Width of each goal card
                            margin: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal['goalName'],
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[300],
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Progress: ${(progress * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Remaining: \$${(goal['finalAmount'] - goal['amountContributed']).toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              else
                const Center(child: Text('No active goals found.')),

              const SizedBox(height: 20),

              // Completed Goals Section
              if (_completedGoals.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Completed Goals',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 100,  // Adjust height for completed goals section
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _completedGoals.length,
                        itemBuilder: (context, index) {
                          final goal = _completedGoals[index];

                          return Container(
                            width: 200,  // Width of each goal card
                            margin: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  '${goal['goalName']} (Completed)',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              else
                const Center(child: Text('No completed goals found.')),

              const SizedBox(height: 20),

              // Total Balance Section
              Text(
                'Total Balance: \$${_totalBalance.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Recent Transactions Section
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _recentTransactions.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _recentTransactions[index];

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: transaction['transactionType'] == 'Income'
                                ? Colors.green
                                : Colors.red,
                            child: Icon(
                              transaction['transactionType'] == 'Income'
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(transaction['category']),
                          subtitle: Text(_formatDate(transaction['date'])),
                          trailing: Text(
                            '\$${transaction['amount'].toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    )
                  : const Center(child: Text('No recent transactions found.')),
            ],
          ),
        ),
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.flag),
            label: 'Add Goal',
            backgroundColor: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpenseInputPage()),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'Add Expense',
            backgroundColor: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TransactionPage()),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.visibility),
            label: 'View Goals',
            backgroundColor: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ActiveGoalsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
