import 'package:extrack/src/expense/goal.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:extrack/src/login/login_page.dart';
import 'package:extrack/src/expense/add_expense_page.dart';
import 'package:extrack/src/expense/goal_view.dart'; // Import goal_view.dart

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _totalBalance = 0.0;
  List<Map<String, dynamic>> _recentTransactions = [];
  DatabaseReference? _databaseRef;

  @override
  void initState() {
    super.initState();
    _initializeDatabaseReference();
    _fetchData();
  }

  void _initializeDatabaseReference() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      _databaseRef = FirebaseDatabase.instance.ref().child('transactions').child(uid);
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

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    itemCount: _recentTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _recentTransactions[index];
                      return ListTile(
                        title: Text('${transaction['category']}'),
                        subtitle: Text(_formatDate(transaction['date'])),
                        trailing: Text(
                          transaction['transactionType'] == 'Income'
                              ? '+ \$${transaction['amount'].toStringAsFixed(2)}'
                              : '- \$${transaction['amount'].toStringAsFixed(2)}',
                          style: TextStyle(
                            color: transaction['transactionType'] == 'Income'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      );
                    },
                  )
                : const Center(child: Text('No transactions found')),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExpenseInputPage()),
              );
            },
            heroTag: 'goal',
            child: const Icon(Icons.flag),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TransactionPage()),
              );
            },
            heroTag: 'expense',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(  // New button for viewing goals
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ActiveGoalsPage()),
              );
            },
            heroTag: 'viewGoals',
            tooltip: 'View Goals',
            child: const Icon(Icons.visibility),
          ),
        ],
      ),
    );
  }
}
