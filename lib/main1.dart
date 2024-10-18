import 'package:extrack/src/welcome_page/sliding_page.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase, FirebaseOptions;
import 'package:flutter/material.dart';
import 'package:extrack/src/theme/custome_theme.dart';  // Import the custom theme

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
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: CustomTheme.lightTheme,  // Apply the light theme here
      darkTheme: CustomTheme.darkTheme,  // Optionally add a dark theme
      themeMode: ThemeMode.system,  // Use system theme mode (light/dark)
      home: const SlidePage(),
    );
  }
}
