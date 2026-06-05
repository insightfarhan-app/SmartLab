import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smartlab/Home/HomePage.dart';
import 'package:smartlab/Home/connection_page.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();

    // Check if user is already verified
    isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!isEmailVerified) {
      sendVerificationEmail();

      // Check every 3 seconds if the user verified
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    // Reload user to get latest status
    await FirebaseAuth.instance.currentUser?.reload();

    setState(() {
      isEmailVerified =
          FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    });

    if (isEmailVerified) {
      timer?.cancel();
      _navigateBasedOnRole();
    }
  }

  Future<void> _navigateBasedOnRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final roleSnapshot = await _dbRef.child('users/${user.uid}/role').get();
    String role = 'Student'; // Default fallback
    if (roleSnapshot.exists) {
      role = roleSnapshot.value as String;
    }

    if (mounted) {
      if (role == 'Teacher') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ConnectionScreen()),
        );
      } else {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      }
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();

      setState(() => canResendEmail = false);
      await Future.delayed(const Duration(seconds: 15));
      if (mounted) {
        setState(() => canResendEmail = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isEmailVerified) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF101B3B),
          ),
          onPressed: () {
            FirebaseAuth.instance.signOut();
            Navigator.pop(context); // Go back to login
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF496DFF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      color: Color(0xFF496DFF),
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  "Verify your email",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF101B3B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  "A verification email has been sent to\n${FirebaseAuth.instance.currentUser?.email}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8F9CBB),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                const CircularProgressIndicator(color: Color(0xFF6366F1)),
                const SizedBox(height: 24),
                const Text(
                  "Waiting for verification...",
                  style: TextStyle(color: Color(0xFF8F9CBB)),
                ),

                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: canResendEmail ? sendVerificationEmail : null,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: canResendEmail
                            ? const Color(0xFF6366F1)
                            : const Color(0xFFDEE5F6),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Resend Email",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: canResendEmail
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF8F9CBB),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
