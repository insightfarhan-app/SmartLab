import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';

class AccessCodeScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const AccessCodeScreen({super.key, required this.onSuccess});

  @override
  State<AccessCodeScreen> createState() => _AccessCodeScreenState();
}

class _AccessCodeScreenState extends State<AccessCodeScreen> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  bool _isError = false;
  String _correctCode = "2026";
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    _fetchAccessCode();
    _controllers = List.generate(4, (_) => TextEditingController());
    _focusNodes = List.generate(4, (_) => FocusNode());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _fetchAccessCode() async {
    final ref = FirebaseDatabase.instance.ref().child('settings/access_code');
    final snapshot = await ref.get();
    if (snapshot.exists) {
      if (mounted) setState(() => _correctCode = snapshot.value.toString());
    }

    // Listen for changes
    ref.onValue.listen((event) {
      if (mounted && event.snapshot.exists) {
        setState(() => _correctCode = event.snapshot.value.toString());
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      for (int i = 0; i < value.length && (index + i) < 4; i++) {
        _controllers[index + i].text = value[i];
      }
      int lastIndex = (index + value.length - 1).clamp(0, 3);
      if (lastIndex < 3) {
        _focusNodes[lastIndex + 1].requestFocus();
      } else {
        _focusNodes[lastIndex].unfocus();
        _verifyCode();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }

      if (_controllers.every((c) => c.text.isNotEmpty)) {
        _verifyCode();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _verifyCode() {
    String enteredCode = _controllers.map((c) => c.text).join();

    if (enteredCode == _correctCode) {
      setState(() => _isError = false);
      widget.onSuccess();
    } else {
      setState(() {
        _isError = true;
        _failedAttempts++;
      });

      for (var controller in _controllers) {
        controller.clear();
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _focusNodes[0].requestFocus();
        }
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isError = false);
        }
      });
    }
  }

  Widget _buildPinBox(int index) {
    bool isFocused = _focusNodes[index].hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 65,
      height: 75,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isError
              ? const Color(0xFFFF5252)
              : isFocused
              ? const Color(0xFF6C5CE7)
              : Colors.grey.shade200,
          width: isFocused || _isError ? 2 : 1.5,
        ),
        boxShadow: [
          if (isFocused)
            BoxShadow(
              color: const Color(0xFF6C5CE7).withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        maxLength: 1,
        cursorColor: const Color(0xFF6C5CE7),
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: _isError ? const Color(0xFFFF5252) : const Color(0xFF2D3436),
          height: 1.0,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) => _onDigitChanged(index, value),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return AnimatedOpacity(
      opacity: _isError ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5252).withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.gpp_bad_rounded,
              color: Color(0xFFFF5252),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              "Incorrect Access Code",
              style: TextStyle(
                color: Color(0xFFFF5252),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C5CE7).withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_open_rounded,
                    size: 48,
                    color: Color(0xFF6C5CE7),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2D3436),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Please enter the 4-digit\n access code to continue.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Row(
                      children: [
                        _buildPinBox(index),
                        if (index < 3) const SizedBox(width: 16),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 32),
                _buildErrorMessage(),
                if (_failedAttempts >= 3) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _showAdminCodeDialog,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6C5CE7),
                    ),
                    child: const Text(
                      "Forgot Code? Use Admin Bypass",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAdminCodeDialog() {
    final TextEditingController adminCodeController = TextEditingController();
    bool _isDialogError = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text("Admin Override"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Enter the master admin code to bypass security."),
                  const SizedBox(height: 16),
                  TextField(
                    controller: adminCodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Admin Code",
                      errorText: _isDialogError ? "Incorrect Admin Code" : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (adminCodeController.text == "1245") {
                      Navigator.pop(ctx);
                      widget.onSuccess();
                    } else {
                      setDialogState(() => _isDialogError = true);
                    }
                  },
                  child: const Text("Verify"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
