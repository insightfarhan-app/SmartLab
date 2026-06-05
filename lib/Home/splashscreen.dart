import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Matching the very light bluish-white background
      backgroundColor: const Color(0xFFF0F4FA),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Gradient Logo Container
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6B7BFF), // Soft purple-blue
                      Color(0xFF8B5CF6), // Deeper purple
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B7BFF).withOpacity(0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.science_outlined, // Conical flask icon
                    color: Colors.white,
                    size: 45,
                  ),
                ),
              ),
              const SizedBox(height: 35),

              // 2. Main Title
              const Text(
                "Smart LAB\nAutomation",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A), // Dark navy blue
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              // 3. Subtitle
              const Text(
                "University of Swabi — FYP",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8B9BB4), // Soft grayish-blue
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 45),

              // 4. Pagination Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(isActive: true),
                  const SizedBox(width: 8),
                  _buildDot(isActive: false),
                  const SizedBox(width: 8),
                  _buildDot(isActive: false),
                ],
              ),
              const SizedBox(height: 50),

              // 5. Feature Badge (Wrapped exactly like the image)
              Container(
                width: 220,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1).withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF8B9BB4),
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Secure · Realtime ·",
                          style: TextStyle(
                            color: Color(0xFF8B9BB4),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Smart",
                      style: TextStyle(
                        color: Color(0xFF8B9BB4),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for the pagination dots
  Widget _buildDot({required bool isActive}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
      ),
    );
  }
}
