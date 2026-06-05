import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smartlab/Home/HomePage.dart';
import 'package:smartlab/Home/connection_page.dart';

class CompleteProfileScreen extends StatefulWidget {
  final User user;

  const CompleteProfileScreen({super.key, required this.user});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  String selectedRole = 'Student';
  bool isLoading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController rollNoController = TextEditingController();
  final TextEditingController batchController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    // Pre-fill name from Google Account if avaiLABle
    if (widget.user.displayName != null) {
      nameController.text = widget.user.displayName!;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    rollNoController.dispose();
    batchController.dispose();
    departmentController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    final name = nameController.text.trim();
    final rollNo = rollNoController.text.trim();
    final batch = batchController.text.trim();
    final department = departmentController.text.trim();

    if (name.isEmpty || department.isEmpty) {
      _showError("Please fill all required fields");
      return;
    }

    if (selectedRole == 'Student') {
      if (rollNo.isEmpty || batch.isEmpty) {
        _showError("Please enter Roll No and Batch");
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      Map<String, dynamic> userData = {
        'role': selectedRole,
        'name': name,
        'department': department,
        'email': widget.user.email ?? '', // Provided by Google
      };

      if (selectedRole == 'Student') {
        userData['rollNo'] = rollNo;
        userData['batch'] = batch;
      }

      await _dbRef.child('users/${widget.user.uid}').set(userData);

      if (mounted) {
        if (selectedRole == 'Teacher') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ConnectionScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      _showError("Failed to save profile. Please try again.");
    } finally {
      if (mounted) setState(() => isLoading = false);
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
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
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
          ),
          onPressed: () {
            // If they go back, they cancel setup. Sign them out.
            FirebaseAuth.instance.signOut();
            GoogleSignIn().signOut();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Complete Profile",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Almost there! We just need a few more details to set up your LAB environment.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),

                // Role Selection
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
                    _buildRoleCard("Teacher", Icons.person_outline_rounded),
                    const SizedBox(width: 16),
                    _buildRoleCard("Student", Icons.school_outlined),
                  ],
                ),
                const SizedBox(height: 32),

                // Fields
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

                AnimatedCrossFade(
                  firstChild: const SizedBox(height: 0, width: double.infinity),
                  secondChild: Column(
                    children: [
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
                              hint: "e.g., 10",
                              icon: Icons.date_range_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  crossFadeState: selectedRole == 'Student'
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),

                const SizedBox(height: 20),

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
                    onPressed: isLoading ? null : _completeProfile,
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
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Complete Setup",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
