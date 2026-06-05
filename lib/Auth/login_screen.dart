import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smartlab/Home/HomePage.dart';
import 'package:smartlab/Home/connection_page.dart';
import 'verify_email_screen.dart';
import 'forgot_password_screen.dart';
import 'complete_profile_screen.dart'; // We will create this next

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool isLogin = true;
  String selectedRole = 'Student';
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController rollNoController = TextEditingController();
  final TextEditingController batchController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    rollNoController.dispose();
    batchController.dispose();
    departmentController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      isLogin = !isLogin;
    });
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _handleAuthAction() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final name = nameController.text.trim();
    final rollNo = rollNoController.text.trim();
    final batch = batchController.text.trim();
    final department = departmentController.text.trim();

    if (isLogin) {
      if (email.isEmpty || password.isEmpty) {
        _showError("Please enter email and password");
        return;
      }
    } else {
      // Validate Sign Up fields
      if (email.isEmpty ||
          password.isEmpty ||
          name.isEmpty ||
          department.isEmpty) {
        _showError("Please fill all required fields");
        return;
      }
      if (selectedRole == 'Student') {
        if (rollNo.isEmpty || batch.isEmpty) {
          _showError("Please enter Roll No and Batch");
          return;
        }
      }
      if (password != confirmPassword) {
        _showError("Passwords do not match");
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        UserCredential userCred = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        await _checkRoleAndNavigate(userCred.user!);
      } else {
        UserCredential userCred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // Save complete profile data to Firebase
        Map<String, dynamic> userData = {
          'role': selectedRole,
          'name': name,
          'department': department,
          'email': email,
        };

        if (selectedRole == 'Student') {
          userData['rollNo'] = rollNo;
          userData['batch'] = batch;
        }

        await _dbRef.child('users/${userCred.user!.uid}').set(userData);

        if (!userCred.user!.emailVerified) {
          await userCred.user!.sendEmailVerification();
        }
        await _checkRoleAndNavigate(userCred.user!);
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "An error occurred");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCred = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final roleSnapshot = await _dbRef
          .child('users/${userCred.user!.uid}/role')
          .get();

      if (roleSnapshot.exists) {
        // User already has a profile setup
        await _checkRoleAndNavigate(userCred.user!);
      } else {
        // New Google user, needs to complete profile
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CompleteProfileScreen(user: userCred.user!),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "An error occurred during Google Sign In");
    } catch (e) {
      _showError("An unexpected error occurred.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _checkRoleAndNavigate(User user) async {
    if (!user.emailVerified &&
        user.providerData.every((p) => p.providerId != 'google.com')) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
        );
      }
      return;
    }

    final roleSnapshot = await _dbRef.child('users/${user.uid}/role').get();
    String role = 'Student';
    if (roleSnapshot.exists) {
      role = roleSnapshot.value as String;
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ConnectionScreen()),
      );
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildRoleCard(String roleText, IconData icon) {
    bool isSelected = selectedRole == roleText;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedRole = roleText;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF496DFF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF496DFF)
                  : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF496DFF).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                roleText,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SizedBox(height: isKeyboardOpen ? 20 : size.height * 0.08),

                  // Header Animation & Logo
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF496DFF,
                                ).withOpacity(0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.science_rounded,
                            size: 40,
                            color: Color(0xFF496DFF),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          isLogin ? "Welcome Back" : "Create Account",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLogin
                              ? "Sign in to continue to Smart LAB"
                              : "Join the modern LAB environment",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Role Selection (Animated size)
                  AnimatedCrossFade(
                    firstChild: const SizedBox(height: 0),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "I am joining as a",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildRoleCard(
                              "Teacher",
                              Icons.person_outline_rounded,
                            ),
                            const SizedBox(width: 16),
                            _buildRoleCard("Student", Icons.school_outlined),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                    crossFadeState: isLogin
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 300),
                    layoutBuilder:
                        (topChild, topChildKey, bottomChild, bottomChildKey) {
                          return Stack(
                            clipBehavior: Clip.hardEdge,
                            alignment: Alignment.topLeft,
                            children: [
                              Positioned(
                                key: bottomChildKey,
                                top: 0,
                                left: 0,
                                right: 0,
                                child: bottomChild,
                              ),
                              Positioned(key: topChildKey, child: topChild),
                            ],
                          );
                        },
                  ),

                  // Conditional SignUp Fields
                  AnimatedCrossFade(
                    firstChild: const SizedBox(height: 0),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(
                          controller: nameController,
                          label: "Full Name",
                          hint: "John Doe",
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: departmentController,
                          label: "Department",
                          hint: "Computer Science",
                          icon: Icons.domain_rounded,
                        ),
                        const SizedBox(height: 20),

                        if (selectedRole == 'Student') ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: rollNoController,
                                  label: "Roll No",
                                  hint: "e.g., 102",
                                  icon: Icons.pin_outlined,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: batchController,
                                  label: "Batch",
                                  hint: "e.g., 2024",
                                  icon: Icons.date_range_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                    crossFadeState: isLogin
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 300),
                    layoutBuilder:
                        (topChild, topChildKey, bottomChild, bottomChildKey) {
                          return Stack(
                            clipBehavior: Clip.hardEdge,
                            alignment: Alignment.topLeft,
                            children: [
                              Positioned(
                                key: bottomChildKey,
                                top: 0,
                                left: 0,
                                right: 0,
                                child: bottomChild,
                              ),
                              Positioned(key: topChildKey, child: topChild),
                            ],
                          );
                        },
                  ),

                  // Form Fields
                  _buildTextField(
                    controller: emailController,
                    label: "Email Address",
                    hint: "you@example.com",
                    icon: Icons.alternate_email_rounded,
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(
                    controller: passwordController,
                    label: "Password",
                    hint: "••••••••",
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    onTogglePassword: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    obscureText: _obscurePassword,
                  ),

                  // Confirm Password (SignUp Only)
                  AnimatedCrossFade(
                    firstChild: const SizedBox(height: 0),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _buildTextField(
                        controller: confirmPasswordController,
                        label: "Confirm Password",
                        hint: "••••••••",
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        onTogglePassword: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        obscureText: _obscureConfirmPassword,
                      ),
                    ),
                    crossFadeState: isLogin
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 300),
                    layoutBuilder:
                        (topChild, topChildKey, bottomChild, bottomChildKey) {
                          return Stack(
                            clipBehavior: Clip.hardEdge,
                            alignment: Alignment.topLeft,
                            children: [
                              Positioned(
                                key: bottomChildKey,
                                top: 0,
                                left: 0,
                                right: 0,
                                child: bottomChild,
                              ),
                              Positioned(key: topChildKey, child: topChild),
                            ],
                          );
                        },
                  ),

                  if (isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Color(0xFF496DFF),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                  SizedBox(height: isLogin ? 32 : 40),

                  // Primary Action Button
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF496DFF), Color(0xFF6A85FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF496DFF).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleAuthAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLogin ? "Sign In" : "Create Account",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isLogin
                                      ? Icons.arrow_forward_rounded
                                      : Icons.person_add_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "OR",
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Google Button
                  SizedBox(
                    height: 60,
                    child: OutlinedButton(
                      onPressed: isLoading ? null : _signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                            height: 24,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.g_mobiledata_rounded,
                                  color: Colors.blue,
                                  size: 32,
                                ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Continue with Google",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: true,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: GestureDetector(
                    onTap: _toggleAuthMode,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: isLogin
                            ? "Don't have an account? "
                            : "Already have an account? ",
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: isLogin ? "Sign Up" : "Sign In",
                            style: const TextStyle(
                              color: Color(0xFF496DFF),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    VoidCallback? onTogglePassword,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 15,
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 22),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: const Color(0xFF94A3B8),
                        size: 22,
                      ),
                      onPressed: onTogglePassword,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
      ],
    );
  }
}
