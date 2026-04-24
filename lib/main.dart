import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:FoundIt_admin_panel/admin_login.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdminPanelApp());
}

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FounIt Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 3, 82, 42),
        brightness: Brightness.dark,
      ),
      home: const AdminLoginScreen(),
    );
  }
}