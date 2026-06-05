import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smartlab/Home/connection_page.dart';
import 'package:smartlab/Home/HomePage.dart';
import 'package:smartlab/Auth/login_screen.dart';
import 'package:smartlab/Auth/verify_email_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for the splash screen duration
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Not logged in -> LoginScreen
      _navigate(const LoginScreen());
    } else {
      // Logged in. Check if email is verified (unless it's Google Sign In)
      bool isGoogleSignIn = user.providerData.any(
        (p) => p.providerId == 'google.com',
      );

      if (!user.emailVerified && !isGoogleSignIn) {
        _navigate(const VerifyEmailScreen());
        return;
      }

      // Check role
      final roleSnapshot = await FirebaseDatabase.instance
          .ref('users/${user.uid}/role')
          .get();
      String role = 'Student'; // Default
      if (roleSnapshot.exists) {
        role = roleSnapshot.value as String;
      }

      // Both Teachers and Students must go through ConnectionScreen
      // ConnectionScreen itself handles role-based UI (PIN vs Connect button)
      _navigate(const ConnectionScreen());
    }
  }

  void _navigate(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FE),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon Container
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF496DFF), Color(0xFF855DFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF496DFF).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.science_outlined,
                        color: Colors.white,
                        size: 55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),
                  // Title
                  const Text(
                    'Smart LAB\nAutomation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF101B3B),
                      height: 1.25,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Subtitle
                  const Text(
                    'University of Swabi — FYP',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8F9CBB),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Loading Animation
                  // Animated Dots
                  const AnimatedDots(),
                ],
              ),
            ),
            // Bottom Pill Container
            Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 30, right: 30),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: const Color(0xFFDEE5F6),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF8F9CBB),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Secure · Realtime · Smart',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8F9CBB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedDots extends StatefulWidget {
  const AnimatedDots({super.key});

  @override
  State<AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Stagger the animation for each dot
        double delay = index * 0.2;
        double progress = (_controller.value - delay) % 1.0;
        if (progress < 0) progress += 1.0;

        // Sine wave peak calculation
        double opacity = 0.3;
        double scale = 1.0;

        if (progress < 0.5) {
          double p = progress / 0.5;
          opacity = 0.3 + (math.sin(p * math.pi) * 0.7);
          scale = 1.0 + (math.sin(p * math.pi) * 0.3);
        }

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF496DFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) => _buildDot(index)),
    );
  }
}
