import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class SmartLabApp extends StatefulWidget {
  const SmartLabApp({super.key});

  @override
  State<SmartLabApp> createState() => _SmartLabAppState();
}

class _SmartLabAppState extends State<SmartLabApp>
    with TickerProviderStateMixin {
  bool isConnected = false;
  bool isConnecting = false;
  String statusMessage = "Tap to Connect";

  String tempValue = "--";
  String humidityValue = "--";
  String motionStatus = "No Motion";
  bool isLightOn = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();

    _dbRef.child('sensor').keepSynced(true);
    _dbRef.child('control/bulb').keepSynced(true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    setState(() {
      isConnecting = true;
      statusMessage = "Verifying ESP32 Status...";
    });

    _pulseController.repeat(reverse: true);

    try {
      final snapshot = await _dbRef.child('status/heartbeat').get();

      await Future.delayed(const Duration(milliseconds: 1500));

      if (snapshot.exists && snapshot.value != null) {
        int lastSeenTime = snapshot.value as int;
        int currentTime = DateTime.now().millisecondsSinceEpoch;

        int diffSeconds = (currentTime - lastSeenTime) ~/ 1000;
        print("ESP Last Seen: $diffSeconds seconds ago");

        if (diffSeconds < 15) {
          final bulbSnapshot = await _dbRef.child('control/bulb').get();
          if (bulbSnapshot.exists && mounted) {
            setState(() {
              isLightOn = (bulbSnapshot.value.toString() == '1');
            });
          }

          _initializeListeners();

          if (mounted) {
            setState(() {
              isConnecting = false;
              isConnected = true;
              statusMessage = "Connected";
            });
            _pulseController.stop();
          }
        } else {
          _showConnectionErrorDialog();
        }
      } else {
        _showConnectionErrorDialog();
      }
    } catch (e) {
      _showConnectionErrorDialog();
    }
  }

  void _showConnectionErrorDialog() {
    if (mounted) {
      _pulseController.stop();
      _pulseController.reset();

      setState(() {
        isConnecting = false;
        statusMessage = "Tap to Connect";
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Text("Connection Failed"),
              ],
            ),
            content: const Text(
              "Please check that the ESP is connected and then try again.",
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "OK",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _initializeListeners() {
    _dbRef.child('sensor/temperature').onValue.listen((event) {
      final val = event.snapshot.value;
      if (mounted) {
        setState(() => tempValue = val != null ? "${val.toString()}°C" : "--");
      }
    });

    _dbRef.child('sensor/humidity').onValue.listen((event) {
      final val = event.snapshot.value;
      if (mounted) {
        setState(
          () => humidityValue = val != null ? "${val.toString()}%" : "--",
        );
      }
    });

    _dbRef.child('sensor/motion').onValue.listen((event) {
      final val = event.snapshot.value;
      bool detected = (val.toString() == '1');
      if (mounted) {
        setState(
          () => motionStatus = detected ? "Motion Detected" : "No Motion",
        );
      }
    });

    _dbRef.child('control/bulb').onValue.listen((event) {
      final val = event.snapshot.value;
      if (mounted) {
        setState(() {
          isLightOn = (val.toString() == '1');
        });
      }
    });
  }

  void _toggleLight(bool value) {
    _dbRef.child('control/bulb').set(value ? 1 : 0).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to switch light: $error")),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: isConnected ? _buildDashboard() : _buildConnectScreen(),
      ),
    );
  }

  Widget _buildConnectScreen() {
    return Center(
      key: const ValueKey('ConnectScreen'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "SMART LAB",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Establish secure connection to ESP32",
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 60),

          GestureDetector(
            onTap: isConnecting ? null : _handleConnect,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isConnecting ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isConnecting
                            ? [const Color(0xFF4FC3F7), const Color(0xFF29B6F6)]
                            : [const Color(0x0fffffff), const Color(0xFFF5F5F5)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isConnecting
                              ? Colors.blue.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 10,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.white,
                          blurRadius: 10,
                          offset: const Offset(-5, -5),
                        ),
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(5, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.power_settings_new_rounded,
                          size: 60,
                          color: isConnecting ? Colors.white : Colors.grey[400],
                        ),
                        if (isConnecting)
                          const SizedBox(
                            width: 170,
                            height: 170,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 50),

          Text(
            statusMessage.toUpperCase(),
            key: const ValueKey('StatusMsg'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: isConnecting ? Colors.blue : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SafeArea(
      key: const ValueKey('Dashboard'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            FadeSlideTransition(delay: 100, child: _buildStatusCard()),
            const SizedBox(height: 30),
            FadeSlideTransition(
              delay: 200,
              child: Text(
                "CONTROLS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Connected",
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              "My Dashboard",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: -1,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            setState(() {
              isConnected = false;
              statusMessage = "Tap to Connect";
            });
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Icon(Icons.power_settings_new, color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSensorItem("Temp", tempValue, Icons.thermostat, Colors.orange),
          Container(width: 1, height: 40, color: Colors.grey[100]),
          _buildSensorItem(
            "Humidity",
            humidityValue,
            Icons.water_drop,
            Colors.blue,
          ),
          Container(width: 1, height: 40, color: Colors.grey[100]),
          _buildSensorItem(
            "Security",
            motionStatus,
            Icons.shield,
            motionStatus == "Motion Detected" ? Colors.red : Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSensorItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 0.85,
      children: [
        _buildControlCard(
          "Lab Light",
          Icons.lightbulb,
          isLightOn,
          (v) => _toggleLight(v),
          Colors.amber,
          0,
        ),
        _buildControlCard(
          "Laptop",
          Icons.laptop_mac,
          false,
          (v) {},
          Colors.blue,
          100,
        ),
        _buildControlCard(
          "Fan",
          Icons.wind_power,
          false,
          (v) {},
          Colors.cyan,
          200,
        ),
        _buildControlCard(
          "Projector",
          Icons.videocam,
          false,
          (v) {},
          Colors.purple,
          300,
        ),
      ],
    );
  }

  Widget _buildControlCard(
    String title,
    IconData icon,
    bool isActive,
    Function(bool) onChanged,
    Color activeColor,
    int delay,
  ) {
    return FadeSlideTransition(
      delay: delay,
      child: GestureDetector(
        onTap: () => onChanged(!isActive),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? activeColor.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.05),
                blurRadius: isActive ? 20 : 10,
                offset: const Offset(0, 10),
              ),
            ],
            border: isActive
                ? Border.all(color: Colors.transparent)
                : Border.all(color: Colors.grey[100]!, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isActive ? Colors.white : Colors.grey[400],
                      size: 22,
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? Colors.white : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? "ON" : "OFF",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white70 : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FadeSlideTransition extends StatefulWidget {
  final Widget child;
  final int delay;

  const FadeSlideTransition({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(position: _offsetAnimation, child: widget.child),
    );
  }
}
