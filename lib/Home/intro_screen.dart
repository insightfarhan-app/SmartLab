import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(Icons.groups_rounded, "The Visionaries"),
                    const SizedBox(height: 14),
                    _buildPremiumTeamCard(
                      name: "Farhan Ijaz Khan",
                      imagePath: "assets/images/farhan.jpeg",
                      rollNo: "45",
                      batch: "10",
                      section: "A",
                      session: "2022-2026",
                      department: "Computer Science",
                      university: "University of Swabi",
                      color: const Color(0xFF4F46E5),
                      isReversed: false,
                    ),
                    const SizedBox(height: 24),
                    _buildPremiumTeamCard(
                      name: "Sahir Iqbal",
                      imagePath: "assets/images/sahir.jpeg",
                      rollNo: "12",
                      batch: "10",
                      section: "A",
                      session: "2022-2026",
                      department: "Computer Science",
                      university: "University of Swabi",
                      color: const Color(0xFF0EA5E9),
                      isReversed: true,
                    ),
                    const SizedBox(height: 40),
                    _buildSectionTitle(
                      Icons.description_rounded,
                      "About Our Project",
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "This project is based on IoT (Internet of Things) and Flutter. We created a smart automation system where we use a 4-channel relay module, DHT11 sensor, a 5V output device to turn on the ESP32, and an active buzzer for sound. The entire system is connected to a Firebase backend for real-time monitoring and control.\n\n"
                      "Through our Flutter application, users can remotely control the lab's electrical appliances using real-time relay switches. The system features role-based access, allowing Teachers to configure secure access codes, track real-time device usage history, and restrict hardware operations to specific working hours. Simultaneously, the app provides live temperature and humidity readings from the lab, ensuring a smart, secure, and automated laboratory environment.",
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildSectionTitle(
                      Icons.memory_rounded,
                      "Technology Stack",
                    ),
                    const SizedBox(height: 20),
                    _buildTechGrid(),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF5A55FF),
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 20),
        title: const Text(
          "Smart Lab Automation",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5A55FF), Color(0xFF332FD0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Decorative background circles
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF332FD0).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.biotech_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        "FINAL YEAR PROJECT",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF5A55FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF5A55FF), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumTeamCard({
    required String name,
    required String imagePath,
    required String rollNo,
    required String batch,
    required String section,
    required String session,
    required String department,
    required String university,
    required Color color,
    required bool isReversed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background subtle accent
          Positioned(
            right: isReversed ? null : 0,
            left: isReversed ? 0 : null,
            top: 0,
            bottom: 0,
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.0), color.withOpacity(0.05)],
                  begin: isReversed
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  end: isReversed
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                ),
                borderRadius: isReversed
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        bottomLeft: Radius.circular(28),
                      )
                    : const BorderRadius.only(
                        topRight: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  textDirection: isReversed
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _showFullImage(context, imagePath),
                      child: Hero(
                        tag: imagePath,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            image: DecorationImage(
                              image: AssetImage(imagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: isReversed
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Roll No: $rollNo",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Batch $batch • Sec $section",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            "Session $session",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Dept. of $department",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              university,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechGrid() {
    final List<Map<String, dynamic>> technologies = [
      {
        'icon': Icons.memory_rounded,
        'name': 'ESP32 IoT',
        'color': const Color(0xFF10B981),
      },
      {
        'icon': Icons.phone_android_rounded,
        'name': 'Flutter App',
        'color': const Color(0xFF0EA5E9),
      },
      {
        'icon': Icons.electrical_services_rounded,
        'name': '4-Ch Relay',
        'color': const Color(0xFFF59E0B),
      },
      {
        'icon': Icons.data_object_rounded,
        'name': 'Firebase Db',
        'color': const Color(0xFFF43F5E),
      },
      {
        'icon': Icons.thermostat_rounded,
        'name': 'DHT11 Sensor',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'icon': Icons.volume_up_rounded,
        'name': 'Active Buzzer',
        'color': const Color(0xFFD946EF),
      },
      {
        'icon': Icons.power_rounded,
        'name': '5V Power Unit',
        'color': const Color(0xFF64748B),
      },
      {
        'icon': Icons.cloud_done_rounded,
        'name': 'Cloud Sync',
        'color': const Color(0xFF3B82F6),
      },
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: technologies.length,
      itemBuilder: (context, index) {
        final tech = technologies[index];
        final Color color = tech['color'];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tech['icon'], color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tech['name'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: Hero(
                  tag: imagePath,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(imagePath, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
