import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
class HangingLightCard extends StatefulWidget {
  final String title;
  final bool isOn;
  final ValueChanged<bool> onChanged;
  final bool isRestricted;
  final VoidCallback onRestricted;

  const HangingLightCard({
    super.key,
    required this.title,
    required this.isOn,
    required this.onChanged,
    required this.isRestricted,
    required this.onRestricted,
  });

  @override
  State<HangingLightCard> createState() => _HangingLightCardState();
}

class _HangingLightCardState extends State<HangingLightCard> {
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  double _swingAngle = 0.0;
  double _velocity = 0.0;
  Timer? _physicsTimer;

  @override
  void initState() {
    super.initState();
    // Use userAccelerometerEventStream to ignore Earth's gravity (device tilt)
    // This way, the pendulum only swings when the user physically shakes/moves the phone.
    _accelerometerSubscription = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      if (!mounted) return;
      // When the user shakes the phone, apply a very tiny force. 
      // A smaller multiplier means a heavy, slow reaction.
      double force = -event.x * 0.001;
      setState(() {
        _velocity += force;
      });
    });

    _physicsTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;
      setState(() {
        // Very weak gravity pull makes the pendulum swing slowly (long period)
        _velocity -= _swingAngle * 0.005;
        // High damping so it maintains momentum but smoothly slows down
        _velocity *= 0.98;
        // Apply velocity to angle
        _swingAngle += _velocity;

        // Clamp the swing angle so it NEVER touches the edges 
        // 0.20 radians is approx 11.5 degrees
        if (_swingAngle > 0.20) {
          _swingAngle = 0.20;
          _velocity *= -0.3; // Gentle bounce/loss of energy at the invisible edge
        } else if (_swingAngle < -0.20) {
          _swingAngle = -0.20;
          _velocity *= -0.3;
        }
      });
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _physicsTimer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (widget.isRestricted) {
      widget.onRestricted();
      return;
    }
    widget.onChanged(!widget.isOn);
  }

  @override
  Widget build(BuildContext context) {
    final bool isLocked = widget.isRestricted;
    final bool isOn = widget.isOn;

    return Container(
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFF1F5F9) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLocked
              ? const Color(0xFFE2E8F0)
              : (isOn
                    ? Colors.amber.withValues(alpha: 0.5)
                    : Colors.grey.shade300),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 50, // leave space for text
              child: Transform.rotate(
                angle: _swingAngle,
                alignment: Alignment.topCenter,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isOn)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: ConeLightBeam(color: Colors.white),
                        ),
                      ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return InteractiveLamp(
                          isOn: isOn,
                          maxWidth: constraints.maxWidth,
                          onToggled: _toggle,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isLocked ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLocked
                          ? const Color(0xFFE2E8F0)
                          : (isOn
                                ? Colors.amber.shade100
                                : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOn ? "ON" : "OFF",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isLocked
                            ? const Color(0xFF94A3B8)
                            : (isOn ? Colors.orange.shade800 : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConeLightBeam extends StatelessWidget {
  final Color color;

  const ConeLightBeam({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: ConeLightPainter(),
        );
      },
    );
  }
}

class ConeLightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFF176).withValues(alpha: 0.5),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final double overshoot = size.width * 2;

    final Path path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo((size.width / 2) - overshoot / 2, size.height)
      ..lineTo((size.width / 2) + overshoot / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class InteractiveLamp extends StatefulWidget {
  final bool isOn;
  final double maxWidth;
  final VoidCallback onToggled;

  const InteractiveLamp({
    super.key,
    required this.isOn,
    required this.maxWidth,
    required this.onToggled,
  });

  @override
  State<InteractiveLamp> createState() => _InteractiveLampState();
}

class _InteractiveLampState extends State<InteractiveLamp> {
  double _dragOffset = 0.0;
  bool _isDragging = false;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
      _isDragging = true;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset > 15 ||
        (details.primaryVelocity != null && details.primaryVelocity! > 100)) {
      widget.onToggled();
    }

    setState(() {
      _dragOffset = 0.0;
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggled,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Transform.translate(
            offset: Offset(0, _dragOffset.clamp(0, 20)),
            child: LampWidget(
              isOn: widget.isOn,
              maxWidth: widget.maxWidth,
              isActive: _isDragging,
            ),
          ),
        ],
      ),
    );
  }
}

class LampWidget extends StatelessWidget {
  final bool isOn;
  final double maxWidth;
  final bool isActive;

  const LampWidget({
    super.key,
    required this.isOn,
    required this.maxWidth,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: maxWidth / 2 - 1,
          child: Container(
            width: 2,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isOn
                    ? [
                        Colors.grey.shade800,
                        Colors.grey.shade600,
                        Colors.grey.shade800,
                      ]
                    : [
                        Colors.grey.shade500,
                        Colors.grey.shade400,
                        Colors.grey.shade500,
                      ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: 35,
          left: maxWidth / 2 - 40,
          child: CustomPaint(
            painter: LampPainter(isOn: isOn, isActive: isActive),
            size: const Size(80, 80),
          ),
        ),
      ],
    );
  }
}

class LampPainter extends CustomPainter {
  final bool isOn;
  final bool isActive;

  const LampPainter({required this.isOn, this.isActive = false});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final centerX = width / 2;

    final cordPaint = Paint()
      ..color = isOn ? Colors.grey[800]! : Colors.grey[500]!
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(centerX, -20), Offset(centerX, 15), cordPaint);

    final capPaint = Paint()
      ..color = isOn ? Colors.grey[900]! : Colors.grey[600]!;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(centerX, 15), width: 12, height: 12),
      capPaint,
    );

    final shadeColor = isOn
        ? (isActive ? Colors.amber[600]! : Colors.amber[800]!)
        : Colors.grey[400]!;

    final shadePaint = Paint()
      ..color = shadeColor
      ..style = PaintingStyle.fill;

    final shadePath = Path()
      ..moveTo(centerX - 25, 20)
      ..quadraticBezierTo(centerX, 10, centerX + 25, 20)
      ..lineTo(centerX + 35, 60)
      ..quadraticBezierTo(centerX, 75, centerX - 35, 60)
      ..close();

    canvas.drawPath(shadePath, shadePaint);

    final detailPaint = Paint()
      ..color = isOn ? Colors.amber[900]! : Colors.grey[500]!
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(shadePath, detailPaint);
    canvas.drawLine(
      Offset(centerX - 25, 20),
      Offset(centerX + 25, 20),
      detailPaint,
    );

    if (isOn) {
      final glowIntensity = isActive ? 0.8 : 0.6;
      final glowPaint = Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFFFFD600).withValues(alpha: glowIntensity),
                const Color(0x30FFD600),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
              radius: 0.7,
            ).createShader(
              Rect.fromCircle(center: Offset(centerX, 60), radius: 40),
            );

      canvas.drawCircle(Offset(centerX, 60), 40, glowPaint);

      final bulbPaint = Paint()..color = Colors.yellow[100]!;
      canvas.drawCircle(Offset(centerX, 60), 10, bulbPaint);

      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8);
      canvas.drawCircle(Offset(centerX - 2, 60 - 2), 2.5, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
