import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'tasks_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCoN1SdgW6vRVsD3src9oC1FOYAWO4g9sw",
        appId: "1:138472066364:android:290d758d2a6edadff2e239",
        messagingSenderId: "138472066364",
        projectId: "companion-app-46c04",
        storageBucket: "companion-app-46c04.firebasestorage.app",
        databaseURL: "https://companion-app-46c04-default-rtdb.firebaseio.com",
      ),
    );
    print("FIREBASE INITIALIZED SUCCESSFULLY");
  } catch (e) {
    print("FIREBASE INIT ERROR: $e");
  }
  runApp(const CompanionApp());
}

class CompanionApp extends StatelessWidget {
  const CompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Companion',
      theme: ThemeData(fontFamily: 'Segoe UI'),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) return const HomePage();
          return const LoginPage();
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const HomePage(),
        '/tasks': (context) => const TasksPage(),
      },
    );
  }
}
