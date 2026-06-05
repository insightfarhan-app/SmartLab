import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class SensorsPage extends StatefulWidget {
  final bool isRestricted;

  const SensorsPage({super.key, this.isRestricted = false});

  @override
  State<SensorsPage> createState() => _SensorsPageState();
}

class _SensorsPageState extends State<SensorsPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  double currentTemp = 0.0;
  double currentHumidity = 0.0;
  double currentPower = 0.0;

  List<double> tempHistory = [0, 0, 0, 0, 0, 0];
  List<double> humidityHistory = [0, 0, 0, 0, 0, 0];
  List<double> powerHistory = [0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _initializeListeners();
  }

  void _initializeListeners() {
    _dbRef.child('sensor/temperature').onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        double val = double.tryParse(event.snapshot.value.toString()) ?? 0.0;
        setState(() {
          currentTemp = val;
          _updateHistory(tempHistory, val);
        });
      }
    });

    _dbRef.child('sensor/humidity').onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        double val = double.tryParse(event.snapshot.value.toString()) ?? 0.0;
        setState(() {
          currentHumidity = val;
          _updateHistory(humidityHistory, val);
        });
      }
    });

    _dbRef.child('sensor/power').onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        double val = double.tryParse(event.snapshot.value.toString()) ?? 0.0;
        setState(() {
          currentPower = val;
          _updateHistory(powerHistory, val);
        });
      }
    });
  }

  void _updateHistory(List<double> historyList, double newValue) {
    historyList.add(newValue);
    if (historyList.length > 6) {
      historyList.removeAt(0);
    }
  }

  String _getStatus(double value, String type) {
    if (type == "Temp" && value > 30.0) return "High";
    if (type == "Humidity" && (value < 30.0 || value > 70.0)) return "Warning";
    if (type == "Power" && value > 2.0) return "High";
    return "Normal";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Sensors",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sensor Monitoring",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A237E),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Live data · Synchronizing...",
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF1A237E).withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isRestricted)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_clock,
                            color: Color(0xFFE65100),
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Access the LAB in working hour to see the sensor output",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  children: [
                    _buildSensorCard(
                      title: "Temperature",
                      subtitle: "Room B-03",
                      value: currentTemp.toStringAsFixed(1),
                      unit: "°C",
                      icon: Icons.thermostat,
                      baseColor: const Color(0xFF5C6BC0),
                      history: tempHistory,
                      status: _getStatus(currentTemp, "Temp"),
                    ),
                    const SizedBox(height: 16),
                    _buildSensorCard(
                      title: "Humidity",
                      subtitle: "Room B-03",
                      value: currentHumidity.round().toString(),
                      unit: "%",
                      icon: Icons.water_drop_outlined,
                      baseColor: const Color(0xFF8B5CF6),
                      history: humidityHistory,
                      status: _getStatus(currentHumidity, "Humidity"),
                    ),
                    const SizedBox(height: 16),
                    _buildSensorCard(
                      title: "Power Draw",
                      subtitle: "Main Circuit",
                      value: currentPower.toStringAsFixed(1),
                      unit: "kW",
                      icon: Icons.bolt,
                      baseColor: const Color(0xFFF59E0B),
                      history: powerHistory,
                      status: _getStatus(currentPower, "Power"),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String subtitle,
    required String value,
    required String unit,
    required IconData icon,
    required Color baseColor,
    required List<double> history,
    required String status,
  }) {
    bool isNormal = status == "Normal";
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: baseColor, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF1A237E).withOpacity(0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isNormal
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isNormal
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A237E),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A237E).withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (index) {
                double maxVal = history.reduce(max);
                double barHeight = 40.0;
                if (maxVal > 0) {
                  barHeight = max(8.0, (history[index] / maxVal) * 40.0);
                } else {
                  barHeight = 8.0;
                }
                double opacity = 0.2 + (index * 0.15);
                if (index == 5) opacity = 1.0;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.fastOutSlowIn,
                  width: MediaQuery.of(context).size.width * 0.11,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(opacity),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
