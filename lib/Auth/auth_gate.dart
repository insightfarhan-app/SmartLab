import 'package:flutter/material.dart';
import 'package:smartlab/Home/connection_page.dart';
import 'access_code_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // This variable tracks if the user has entered the correct PIN
  bool isAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    // 1. If not authenticated, show the PIN screen
    if (!isAuthenticated) {
      return AccessCodeScreen(
        onSuccess: () {
          // When the code is correct, update the state to true
          setState(() {
            isAuthenticated = true;
          });
        },
      );
    }

    // 2. If the PIN was correct, navigate them to the Connection Screen
    // (Which handles the working hours check and ESP32 verification)
    return const ConnectionScreen();
  }
}
