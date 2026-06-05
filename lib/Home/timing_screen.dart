import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TimingScreen extends StatefulWidget {
  final String role;

  const TimingScreen({super.key, required this.role});

  @override
  State<TimingScreen> createState() => _TimingScreenState();
}

class _TimingScreenState extends State<TimingScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'settings/LAB_timing',
  );
  bool _isLoading = true;

  bool _isOpen = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 15, minute: 0);

  @override
  void initState() {
    super.initState();
    _fetchTiming();
  }

  void _fetchTiming() {
    _dbRef.onValue.listen((event) {
      if (mounted) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          setState(() {
            _isOpen = data['isOpen'] ?? true;
            _startTime = TimeOfDay(
              hour: data['startHour'] ?? 9,
              minute: data['startMinute'] ?? 0,
            );
            _endTime = TimeOfDay(
              hour: data['endHour'] ?? 15,
              minute: data['endMinute'] ?? 0,
            );
            _isLoading = false;
          });
        } else {
          // Initialize if empty
          _updateTiming(
            true,
            const TimeOfDay(hour: 9, minute: 0),
            const TimeOfDay(hour: 15, minute: 0),
          );
        }
      }
    });
  }

  Future<void> _updateTiming(
    bool isOpen,
    TimeOfDay start,
    TimeOfDay end,
  ) async {
    await _dbRef.set({
      'isOpen': isOpen,
      'startHour': start.hour,
      'startMinute': start.minute,
      'endHour': end.hour,
      'endMinute': end.minute,
    });
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF496DFF),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (isStart) {
        _updateTiming(_isOpen, picked, _endTime);
      } else {
        _updateTiming(_isOpen, _startTime, picked);
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.role == 'Teacher';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "LAB Timing",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF496DFF)),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status Card
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isOpen
                              ? [
                                  const Color(0xFF496DFF),
                                  const Color(0xFF6A85FF),
                                ]
                              : [
                                  const Color(0xFFE11D48),
                                  const Color(0xFFFB7185),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isOpen
                                        ? const Color(0xFF496DFF)
                                        : const Color(0xFFE11D48))
                                    .withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _isOpen
                                ? Icons.lock_open_rounded
                                : Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isOpen
                                ? "LAB is Currently Open"
                                : "LAB is Currently Closed",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isOpen
                                ? "Students can access the LAB during working hours."
                                : "All student access is temporarily suspended.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          if (isTeacher) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Master Override",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Switch(
                                    value: _isOpen,
                                    onChanged: (val) {
                                      _updateTiming(val, _startTime, _endTime);
                                    },
                                    activeColor: Colors.white,
                                    activeTrackColor: Colors.white.withOpacity(
                                      0.5,
                                    ),
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: Colors.white
                                        .withOpacity(0.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Timing Section
                    const Text(
                      "Working Hours",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTimeRow(
                            title: "Opening Time",
                            icon: Icons.wb_sunny_rounded,
                            time: _formatTime(_startTime),
                            isTeacher: isTeacher,
                            onTap: () => _selectTime(context, true),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Container(
                              height: 1,
                              color: const Color(0xFFF1F5F9),
                            ),
                          ),
                          _buildTimeRow(
                            title: "Closing Time",
                            icon: Icons.nightlight_round,
                            time: _formatTime(_endTime),
                            isTeacher: isTeacher,
                            onTap: () => _selectTime(context, false),
                          ),
                        ],
                      ),
                    ),

                    if (!isTeacher) ...[
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Access to the LAB dashboard is automatically restricted outside of these working hours.",
                                style: const TextStyle(
                                  color: Color(0xFF1D4ED8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTimeRow({
    required String title,
    required IconData icon,
    required String time,
    required bool isTeacher,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF64748B), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (isTeacher)
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              foregroundColor: const Color(0xFF496DFF),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              "Edit",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
