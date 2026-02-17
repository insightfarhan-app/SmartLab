import 'package:flutter/material.dart';
import 'package:smartlab/Auth/access_code_screen.dart';
import 'package:smartlab/Home/HomePage.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isAuthenticated = false;

  void _onAccessGranted() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isAuthenticated
        ? const SmartLabApp()
        : AccessCodeScreen(onSuccess: _onAccessGranted);
  }
}
