import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:extrack/src/login/login_page.dart';
import 'package:extrack/src/expense/add_expense_page.dart'; // Page to add expenses

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
              // After signing out, redirect to login page
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
            // Total balance section
            const Text(
              'Total Balance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '\$1,250.00', // Hardcoded for now, connect to Firebase in future
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 24),
            
            // Recent Transactions section
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    title: Text('Grocery Shopping'),
                    subtitle: Text('Sep 18, 2024'),
                    trailing: Text('- \$50.00', style: TextStyle(color: Colors.red)),
                  ),
                  ListTile(
                    title: Text('Salary'),
                    subtitle: Text('Sep 15, 2024'),
                    trailing: Text('+ \$2,000.00', style: TextStyle(color: Colors.green)),
                  ),
                  ListTile(
                    title: Text('Rent'),
                    subtitle: Text('Sep 1, 2024'),
                    trailing: Text('- \$750.00', style: TextStyle(color: Colors.red)),
                  ),
                  // Add more ListTile widgets here for additional transactions
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Floating action button to add new expense
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpensePage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
