import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartlab/Home/sensorpage.dart'; // Ensure this matches your directory structure
import 'package:smartlab/Home/profile_screen.dart';
import 'package:smartlab/Home/timing_screen.dart';
import 'package:smartlab/Home/users_usage_screen.dart';
import 'package:smartlab/Home/hanging_light_card.dart';
import 'package:smartlab/Home/animated_plug_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.isRestricted = false});

  final bool isRestricted;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  String tempValue = "--";
  String humidityValue = "--";
  bool isRelay1On = false; // Lights
  bool isRelay2On = false; // AC Unit
  bool isRelay3On = false; // Extra/Equipment
  bool isRelay4On = false; // 4th Channel

  String _role = "Student";
  String _userName = "Unknown";
  bool _isTimingRestricted = false;
  String _restrictionMessage =
      "Please visit during working hours to access the lab.";
  int _currentIndex = 0;

  Timer? _timeCheckTimer;
  bool _isLabOpen = true;
  int _startH = 9, _startM = 0;
  int _endH = 15, _endM = 0;

  @override
  void initState() {
    super.initState();
    _fetchRoleAndTiming();
    _initializeListeners();
    _timeCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkTime();
    });
  }

  @override
  void dispose() {
    _timeCheckTimer?.cancel();
    super.dispose();
  }

  void _initializeListeners() {
    _dbRef.child('sensor/temperature').onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        double t = double.tryParse(event.snapshot.value.toString()) ?? 0;
        setState(() => tempValue = "${t.round()}");
      }
    });

    _dbRef.child('sensor/humidity').onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        setState(() => humidityValue = event.snapshot.value.toString());
      }
    });

    _dbRef.child('control/relay1').onValue.listen((event) {
      if (mounted) {
        bool isOn = (event.snapshot.value.toString() == '1');
        setState(() => isRelay1On = isOn);
        if (isOn && (_isTimingRestricted || widget.isRestricted))
          _toggleRelay('relay1', false);
      }
    });

    _dbRef.child('control/relay2').onValue.listen((event) {
      if (mounted) {
        bool isOn = (event.snapshot.value.toString() == '1');
        setState(() => isRelay2On = isOn);
        if (isOn && (_isTimingRestricted || widget.isRestricted))
          _toggleRelay('relay2', false);
      }
    });

    _dbRef.child('control/relay3').onValue.listen((event) {
      if (mounted) {
        bool isOn = (event.snapshot.value.toString() == '1');
        setState(() => isRelay3On = isOn);
        if (isOn && (_isTimingRestricted || widget.isRestricted))
          _toggleRelay('relay3', false);
      }
    });

    _dbRef.child('control/relay4').onValue.listen((event) {
      if (mounted) {
        bool isOn = (event.snapshot.value.toString() == '1');
        setState(() => isRelay4On = isOn);
        if (isOn && (_isTimingRestricted || widget.isRestricted))
          _toggleRelay('relay4', false);
      }
    });
  }

  void _fetchRoleAndTiming() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await _dbRef.child('users/${user.uid}').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null && mounted) {
          setState(() {
            _role = data['role']?.toString() ?? "Student";
            _userName = data['name']?.toString() ?? "Unknown";
          });
        }
      }
    }

    _dbRef.child('settings/LAB_timing').onValue.listen((event) {
      if (mounted) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data == null) return;

        _isLabOpen = data['isOpen'] ?? true;
        _startH = data['startHour'] ?? 9;
        _startM = data['startMinute'] ?? 0;
        _endH = data['endHour'] ?? 15;
        _endM = data['endMinute'] ?? 0;

        _checkTime();
      }
    });
  }

  void _checkTime() {
    if (!mounted) return;

    void applyRestriction(String message) {
      if (!_isTimingRestricted) {
        if (isRelay1On) _toggleRelay('relay1', false);
        if (isRelay2On) _toggleRelay('relay2', false);
        if (isRelay3On) _toggleRelay('relay3', false);
        if (isRelay4On) _toggleRelay('relay4', false);
      }
      setState(() {
        _isTimingRestricted = true;
        _restrictionMessage = message;
      });
    }

    if (!_isLabOpen) {
      applyRestriction(
        _role == 'Teacher'
            ? "You turned off access for today."
            : "The teacher turned off access for today.",
      );
      return;
    }

    final now = DateTime.now();
    int currentMinutes = now.hour * 60 + now.minute;
    int startMinutes = _startH * 60 + _startM;
    int endMinutes = _endH * 60 + _endM;

    bool isRestrictedNow = false;

    if (startMinutes < endMinutes) {
      // Daytime shift: 9 AM to 3 PM
      isRestrictedNow =
          currentMinutes < startMinutes || currentMinutes >= endMinutes;
    } else if (startMinutes > endMinutes) {
      // Overnight shift: 9 PM to 3 AM
      isRestrictedNow =
          currentMinutes < startMinutes && currentMinutes >= endMinutes;
    } else {
      // 24 hours locked or open
      isRestrictedNow = false;
    }

    if (isRestrictedNow) {
      String formatTime(int h, int m) {
        final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
        final minute = m.toString().padLeft(2, '0');
        final period = h >= 12 ? 'PM' : 'AM';
        return "$hour:$minute $period";
      }

      String sTime = formatTime(_startH, _startM);
      String eTime = formatTime(_endH, _endM);

      applyRestriction(
        _role == 'Teacher'
            ? "You set working hours from $sTime to $eTime. Please access in working hours."
            : "Come back in working hours to access the lab.",
      );
    } else {
      setState(() {
        _isTimingRestricted = false;
      });
    }
  }

  void _toggleRelay(String node, bool state) {
    _dbRef.child('control/$node').set(state ? 1 : 0);

    // Log usage
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _dbRef.child('usage/$node').set({
        'uid': user.uid,
        'userName': _userName,
        'userRole': _role,
        'state': state ? 1 : 0,
        'timestamp': ServerValue.timestamp,
      });
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showRestrictedSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.lock_clock, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _restrictionMessage,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isRestricted = widget.isRestricted || _isTimingRestricted;

    final List<Widget> teacherTabs = [
      _buildHomeContent(isRestricted),
      SensorsPage(isRestricted: isRestricted),
      const UsersUsageScreen(),
      TimingScreen(role: _role),
      const ProfileScreen(),
    ];

    final List<Widget> studentTabs = [
      _buildHomeContent(isRestricted),
      SensorsPage(isRestricted: isRestricted),
      TimingScreen(role: _role),
      const ProfileScreen(),
    ];

    final tabs = _role == 'Teacher' ? teacherTabs : studentTabs;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped,
        selectedItemColor: const Color(0xFF5A55FF),
        unselectedItemColor: const Color(0xFF94A3B8),
        showUnselectedLabels: true,
        items: _role == 'Teacher'
            ? [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_filled),
                  label: "Home",
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: "Sensors",
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.group),
                  label: "Users",
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.access_time_rounded),
                  label: "Timing",
                ),
                BottomNavigationBarItem(
                  icon: FirebaseAuth.instance.currentUser?.photoURL != null
                      ? CircleAvatar(
                          radius: 12,
                          backgroundImage: NetworkImage(
                            FirebaseAuth.instance.currentUser!.photoURL!,
                          ),
                        )
                      : const Icon(Icons.person_outline),
                  label: "Profile",
                ),
              ]
            : [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_filled),
                  label: "Home",
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: "Sensors",
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.access_time_rounded),
                  label: "Timing",
                ),
                BottomNavigationBarItem(
                  icon: FirebaseAuth.instance.currentUser?.photoURL != null
                      ? CircleAvatar(
                          radius: 12,
                          backgroundImage: NetworkImage(
                            FirebaseAuth.instance.currentUser!.photoURL!,
                          ),
                        )
                      : const Icon(Icons.person_outline),
                  label: "Profile",
                ),
              ],
      ),
    );
  }

  Widget _buildHomeContent(bool isRestricted) {
    final Color statusColor = isRestricted
        ? const Color(0xFFCBD5E1)
        : Colors.greenAccent;
    final Color headerTextColor = isRestricted
        ? const Color(0xFFCBD5E1)
        : Colors.white;

    return Stack(
      children: [
        Container(
          height: 280,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4A44FF), Color(0xFF7C53FF)],
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   "Good Morning 👋",
                      //   style: TextStyle(
                      //     color: headerTextColor,
                      //     fontSize: 16,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      // ),
                      const SizedBox(height: 5),
                      Text(
                        "LAB Dashboard",
                        style: TextStyle(
                          color: headerTextColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildHeaderChip(
                            Icons.circle,
                            isRestricted ? "LAB Offline" : "LAB Active",
                            statusColor,
                          ),
                          const SizedBox(width: 12),
                          _buildHeaderChip(
                            Icons.memory,
                            "3 Devices",
                            headerTextColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.25,
                    children: [
                      _buildStatCard(
                        Icons.monitor,
                        const Color(0xFFE8EAF6),
                        const Color(0xFF5C6BC0),
                        humidityValue,
                        "Humidity (%)",
                      ),
                      _buildStatCard(
                        Icons.show_chart,
                        const Color(0xFFE8F5E9),
                        const Color(0xFF66BB6A),
                        "$tempValue°C",
                        "Avg Temp",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Devices",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        "View all",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7BFF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                    children: [
                      HangingLightCard(
                        title: "Relay-1",
                        isOn: isRelay1On,
                        onChanged: (v) => _toggleRelay('relay1', v),
                        isRestricted: isRestricted,
                        onRestricted: _showRestrictedSnackBar,
                      ),
                      AnimatedPlugCard(
                        title: "Relay-2",
                        isOn: isRelay2On,
                        onChanged: (v) => _toggleRelay('relay2', v),
                        isRestricted: isRestricted,
                        onRestricted: _showRestrictedSnackBar,
                      ),
                      AnimatedPlugCard(
                        title: "Relay-3",
                        isOn: isRelay3On,
                        onChanged: (v) => _toggleRelay('relay3', v),
                        isRestricted: isRestricted,
                        onRestricted: _showRestrictedSnackBar,
                      ),
                      // Container(
                      //   decoration: BoxDecoration(
                      //     color: isRestricted
                      //         ? const Color(0xFFF1F5F9)
                      //         : const Color(0xFF1E293B).withValues(alpha: 0.3),
                      //     borderRadius: BorderRadius.circular(24),
                      //     border: Border.all(
                      //       color: isRestricted
                      //           ? const Color(0xFFE2E8F0)
                      //           : Colors.grey.shade800,
                      //       width: 2,
                      //     ),
                      //   ),
                      //   // child: Center(
                      //   //   child: Column(
                      //   //     mainAxisAlignment: MainAxisAlignment.center,
                      //   //     children: [
                      //   //       Icon(
                      //   //         Icons.add_circle_outline,
                      //   //         color: Colors.grey.shade600,
                      //   //         size: 28,
                      //   //       ),
                      //   //       const SizedBox(height: 8),
                      //   //       Text(
                      //   //         "Empty Slot",
                      //   //         style: TextStyle(
                      //   //           color: Colors.grey.shade600,
                      //   //           fontSize: 12,
                      //   //           fontWeight: FontWeight.w600,
                      //   //         ),
                      //   //       ),
                      //   //     ],
                      //   //   ),
                      //   // ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderChip(IconData icon, String label, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    Color iconBg,
    Color iconColor,
    String value,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
