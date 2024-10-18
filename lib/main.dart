import 'package:extrack/src/welcome_page/sliding_page.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase, FirebaseOptions;
import 'package:flutter/material.dart';
// import 'package:sms_advanced/sms_advanced.dart';




void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAu6u8GGofmWmHzraOi4j_U2F0LXI8zjXU',
        appId: '1:171573430566:android:139a6a70c2879c877e59e7',
        messagingSenderId: '171573430566',
        projectId: 'trackex-cf4e9',
        storageBucket: 'trackex-cf4e9.appspot.com',
        databaseURL: 'https://trackex-cf4e9-default-rtdb.firebaseio.com',
      ),
    );
    // await Firebase.initializeApp();
   

  }

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
      home: const SlidePage(), 
    );
  }
}
