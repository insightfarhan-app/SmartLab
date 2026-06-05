import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smartlab/Home/HomePage.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> with TickerProviderStateMixin {
  bool isConnecting = false;
  bool isAuthenticated = false;
  bool _isLoadingRole = true;
  bool _isTeacher = false;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;

  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  bool _isError = false;
  String _correctCode = "2026";
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (_) => TextEditingController());
    _focusNodes = List.generate(4, (_) => FocusNode());

    _checkUserRole();
    _fetchAccessCode();

    // Breathing pulse animation for the connect button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Wave animation during connection
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await _dbRef.child('users/${user.uid}/role').get();
      if (snapshot.exists && snapshot.value == 'Teacher') {
        if (mounted) setState(() => _isTeacher = true);
      } else {
        // Student doesn't need access code
        if (mounted) {
          setState(() {
            _isTeacher = false;
            isAuthenticated = true; // Auto-authenticate students
          });
        }
      }
    }
    if (mounted) {
      setState(() => _isLoadingRole = false);
      // Focus first node if teacher
      if (_isTeacher && !isAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNodes[0].requestFocus();
        });
      }
    }
  }

  void _fetchAccessCode() async {
    final ref = FirebaseDatabase.instance.ref().child('settings/access_code');
    final snapshot = await ref.get();
    if (snapshot.exists) {
      if (mounted) setState(() => _correctCode = snapshot.value.toString());
    }

    ref.onValue.listen((event) {
      if (mounted && event.snapshot.exists) {
        setState(() => _correctCode = event.snapshot.value.toString());
      }
    });
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
      setState(() {
        _isError = false;
        isAuthenticated = true;
      });
      // Optionally auto-connect for teachers, or let them click the big connect button
      // We will let them click the beautiful round connect button!
    } else {
      setState(() {
        _isError = true;
        _failedAttempts++;
      });

      for (var controller in _controllers) {
        controller.clear();
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _focusNodes[0].requestFocus();
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isError = false);
      });
    }
  }

  Future<void> _handleConnect() async {
    setState(() => isConnecting = true);
    _pulseController.repeat(reverse: true);
    _waveController.repeat();

    try {
      await Future.delayed(const Duration(milliseconds: 1000)); // Show nice animation

      final statusSnapshot = await _dbRef.child('status/heartbeat').get();
      bool isConnected = false;

      if (statusSnapshot.exists && statusSnapshot.value != null) {
        int lastSeenTime = statusSnapshot.value as int;
        int currentTime = DateTime.now().millisecondsSinceEpoch;
        int diffSeconds = (currentTime - lastSeenTime) ~/ 1000;
        if (diffSeconds < 20) {
          isConnected = true;
        }
      }

      _stopConnecting();

      if (isConnected) {
        _showSuccessSnackbar();
      } else {
        _showFailureSnackbar();
      }

      // Always navigate to HomePage as requested
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      _stopConnecting();
      _showFailureSnackbar();
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    }
  }

  void _stopConnecting() {
    if (mounted) {
      _pulseController.stop();
      _waveController.stop();
      setState(() => isConnecting = false);
    }
  }

  void _showSuccessSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF10B981),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 10,
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 26),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Connected to esp32",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFailureSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFF43F5E),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 10,
        content: Row(
          children: const [
            Icon(Icons.wifi_off_rounded, color: Colors.white, size: 26),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Not connected to esp 32 make sure the esp32 is powerd on",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
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
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Row(
                children: [
                  Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF3B82F6)),
                  SizedBox(width: 12),
                  Text(
                    "Admin Override",
                    style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Enter the master admin code to bypass security.",
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: adminCodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    style: const TextStyle(color: Color(0xFF1E293B), fontSize: 18, letterSpacing: 4),
                    decoration: InputDecoration(
                      labelText: "Admin Code",
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      errorText: _isDialogError ? "Incorrect Admin Code" : null,
                      errorStyle: const TextStyle(color: Color(0xFFF43F5E)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    if (adminCodeController.text == "1245") {
                      Navigator.pop(ctx);
                      setState(() {
                        _isError = false;
                        isAuthenticated = true;
                      });
                    } else {
                      setDialogState(() => _isDialogError = true);
                    }
                  },
                  child: const Text("Verify", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWave(double delay) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final progress = (_waveController.value + delay) % 1.0;
        final size = 180.0 + (progress * 200.0);
        final opacity = (1.0 - progress).clamp(0.0, 1.0);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4F46E5).withValues(alpha: opacity * 0.15),
            border: Border.all(
              color: const Color(0xFF4F46E5).withValues(alpha: opacity * 0.3),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPinBox(int index) {
    return Container(
      width: 65,
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isError 
              ? const Color(0xFFF43F5E) 
              : _focusNodes[index].hasFocus 
                  ? const Color(0xFF3B82F6) 
                  : const Color(0xFFE2E8F0),
          width: _focusNodes[index].hasFocus ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _focusNodes[index].hasFocus
                ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          obscureText: true,
          obscuringCharacter: '●',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _isError ? const Color(0xFFF43F5E) : const Color(0xFF1E293B),
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
      ),
    );
  }

  Widget _buildErrorMessage() {
    return AnimatedOpacity(
      opacity: _isError ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: Color(0xFFE11D48), size: 20),
            SizedBox(width: 8),
            Text(
              "Incorrect Access Code",
              style: TextStyle(
                color: Color(0xFFE11D48),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectButton() {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Waves when connecting
          if (isConnecting) ...[
            _buildWave(0.0),
            _buildWave(0.33),
            _buildWave(0.66),
          ],
          
          AnimatedBuilder(
            animation: isConnecting ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            builder: (context, child) {
              return Transform.scale(
                scale: isConnecting ? _pulseAnimation.value : 1.0,
                child: GestureDetector(
                  onTap: isConnecting ? null : _handleConnect,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isConnecting
                          ? const CircularProgressIndicator(
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.wifi_tethering_rounded,
                                  color: Colors.white,
                                  size: 55,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "CONNECT",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Beautiful Light Background Accents
          Positioned(
            top: -150,
            left: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: _isLoadingRole
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3B82F6),
                    ),
                  )
                : Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Header icon
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                    blurRadius: 25,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.hub_rounded,
                                color: Color(0xFF3B82F6),
                                size: 50,
                              ),
                            ),
                            const SizedBox(height: 30),

                            Text(
                              _isTeacher && !isAuthenticated 
                                  ? "Teacher Access" 
                                  : "Smart Lab Network",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Text(
                              _isTeacher && !isAuthenticated
                                  ? "Enter your 4-digit code to access the lab"
                                  : "Tap the button below to establish a secure connection with the ESP32 hardware",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 50),

                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: _isTeacher && !isAuthenticated
                                  ? Column(
                                      key: const ValueKey('pin_entry'),
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: List.generate(4, (index) {
                                            return Row(
                                              children: [
                                                _buildPinBox(index),
                                                if (index < 3) const SizedBox(width: 12),
                                              ],
                                            );
                                          }),
                                        ),
                                        const SizedBox(height: 32),
                                        _buildErrorMessage(),
                                        if (_failedAttempts >= 3) ...[
                                          const SizedBox(height: 24),
                                          TextButton.icon(
                                            onPressed: _showAdminCodeDialog,
                                            icon: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF6366F1)),
                                            label: const Text(
                                              "Use Admin Bypass",
                                              style: TextStyle(
                                                color: Color(0xFF6366F1),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    )
                                  : _buildConnectButton(),
                            ),

                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
