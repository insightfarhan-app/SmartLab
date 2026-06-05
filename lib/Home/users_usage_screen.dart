import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class UsersUsageScreen extends StatefulWidget {
  const UsersUsageScreen({super.key});

  @override
  State<UsersUsageScreen> createState() => _UsersUsageScreenState();
}

class _UsersUsageScreenState extends State<UsersUsageScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  Map<String, dynamic> _usageData = {};
  Timer? _timer;

  final Map<String, String> _relayNames = {
    'relay1': 'Relay 1 (Lights)',
    'relay2': 'Relay 2 (Switch 1)',
    'relay3': 'Relay 3 (Switch 2)',
    'relay4': 'Relay 4 (Nill)',
  };

  final Map<String, IconData> _relayIcons = {
    'relay1': Icons.lightbulb_outline,
    'relay2': Icons.ac_unit_rounded,
    'relay3': Icons.power,
    'relay4': Icons.power_settings_new_rounded,
  };

  @override
  void initState() {
    super.initState();
    _dbRef.child('usage').onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        setState(() {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          _usageData = data.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        });
      }
    });

    // Update UI every minute to refresh the "time ago" durations
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int timestamp) {
    final now = DateTime.now();
    final usedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(usedTime);

    if (difference.inMinutes < 1) return "Just now";
    if (difference.inHours < 1) return "${difference.inMinutes}m ago";
    if (difference.inDays < 1) {
      return "${difference.inHours}h ${difference.inMinutes % 60}m ago";
    }
    return DateFormat('MMM d, h:mm a').format(usedTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "LAB Usage Tracker",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _usageData.isEmpty
            ? const Center(
                child: Text(
                  "No usage data found.",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                children: [
                  const Text(
                    "Real-Time Activity",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._relayNames.keys.map((relayKey) {
                    final data = _usageData[relayKey];
                    return _buildUsageCard(relayKey, data);
                  }),
                ],
              ),
      ),
    );
  }

  Widget _buildUsageCard(String relayKey, dynamic data) {
    final bool hasData = data != null;
    final int state = hasData ? (data['state'] ?? 0) : 0;
    final bool isOn = state == 1;
    final String userName = hasData
        ? (data['userName'] ?? 'Unknown')
        : 'No Data';
    final String userRole = hasData ? (data['userRole'] ?? 'Student') : '';
    final int timestamp = hasData ? (data['timestamp'] ?? 0) : 0;

    final String relayName = _relayNames[relayKey]!;
    final IconData icon = _relayIcons[relayKey]!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOn
              ? const Color(0xFF496DFF).withOpacity(0.5)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isOn
                ? const Color(0xFF496DFF).withOpacity(0.15)
                : Colors.black.withOpacity(0.04),
            blurRadius: isOn ? 20 : 10,
            spreadRadius: isOn ? 2 : 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOn
                        ? const Color(0xFFE0E7FF)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: isOn
                        ? const Color(0xFF496DFF)
                        : const Color(0xFF94A3B8),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        relayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isOn
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isOn ? "CURRENTLY ON" : "CURRENTLY OFF",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isOn
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFDC2626),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (hasData) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(
                  color: Color(0xFFF1F5F9),
                  thickness: 1.5,
                  height: 1,
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: userRole == 'Teacher'
                        ? const Color(0xFF855DFF).withOpacity(0.1)
                        : const Color(0xFF38BDF8).withOpacity(0.1),
                    child: Icon(
                      userRole == 'Teacher'
                          ? Icons.workspace_premium
                          : Icons.school,
                      size: 16,
                      color: userRole == 'Teacher'
                          ? const Color(0xFF855DFF)
                          : const Color(0xFF38BDF8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOn ? "In Use By:" : "Last Used By:",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isOn ? "Duration:" : "Time:",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDuration(timestamp),
                        style: TextStyle(
                          fontSize: 14,
                          color: isOn
                              ? const Color(0xFF496DFF)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
