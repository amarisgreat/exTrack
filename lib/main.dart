import 'package:firebase_core/firebase_core.dart' show Firebase, FirebaseOptions;
import 'package:flutter/material.dart';
import 'package:extrack/src/welcome_page/sliding_page.dart';

 // Import your login page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp();// Initialize Firebase
  await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: 'AIzaSyC2X-TJwam0M102mhRVGrvLm5VN75ob9K0',
    appId: '1:929513809357:android:079f5c4695df5984291084',
    messagingSenderId: '929513809357',
    projectId: 'trackex-ee96d',
    storageBucket: 'trackex-ee96d.appspot.com',
  )
);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SlidePage(), // Start with the login page
    );
  }
}
