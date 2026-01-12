// lib/main.dart

import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart'; 
import 'profile_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COVAI E-AUCTION',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      // Start the app at the login screen
      home: const LoginScreen(), 

      // Handle named routes with arguments
      onGenerateRoute: (settings) {
        switch (settings.name) {
          
          case '/home':
            // FIX: Extract userId from arguments passed during navigation
            final args = settings.arguments;
            final String userId = (args is String) ? args : '0'; 

            return MaterialPageRoute(
              builder: (context) => MainScreenShell(userId: userId),
            );

          case '/profile':
             // Handle profile arguments
             final args = settings.arguments;
             final String customerId = (args is String) ? args : '0';

             return MaterialPageRoute(
              builder: (context) => EditableProfileScreen(
                  customerId: customerId, 
                  currentUser: 'User', 
                ),
             );

          default:
            return MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            );
        }
      },
    );
  }
}  