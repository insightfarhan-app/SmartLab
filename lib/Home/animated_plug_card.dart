import 'package:flutter/material.dart';

class AnimatedPlugCard extends StatefulWidget {
  final String title;
  final bool isOn;
  final ValueChanged<bool> onChanged;
  final bool isRestricted;
  final VoidCallback onRestricted;

  const AnimatedPlugCard({
    super.key,
    required this.title,
    required this.isOn,
    required this.onChanged,
    required this.isRestricted,
    required this.onRestricted,
  });

  @override
  State<AnimatedPlugCard> createState() => _AnimatedPlugCardState();
}

class _AnimatedPlugCardState extends State<AnimatedPlugCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragY = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // 0.0 = fully plugged in, 1.0 = unplugged
    _controller.value = widget.isOn ? 0.0 : 1.0;
  }

  @override
  void didUpdateWidget(AnimatedPlugCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOn != widget.isOn && !_isDragging) {
      if (widget.isOn) {
        _controller.animateTo(0.0, curve: Curves.easeOutBack);
      } else {
        _controller.animateTo(1.0, curve: Curves.easeOutCubic);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.isRestricted) {
      widget.onRestricted();
      return;
    }
    widget.onChanged(!widget.isOn);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (widget.isRestricted) return;
    setState(() {
      _isDragging = true;
      _dragY += details.delta.dy;
      // 50 pixels is the max pull distance
      double val = (_controller.value + (details.delta.dy / 50.0)).clamp(0.0, 1.0);
      _controller.value = val;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (widget.isRestricted) {
      widget.onRestricted();
      return;
    }
    _isDragging = false;
    _dragY = 0.0;

    if (_controller.value < 0.5) {
      // Snap to plugged in
      _controller.animateTo(0.0, curve: Curves.easeOutBack);
      if (!widget.isOn) widget.onChanged(true);
    } else {
      // Snap to unplugged
      _controller.animateTo(1.0, curve: Curves.easeOutCubic);
      if (widget.isOn) widget.onChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.isRestricted;
    final isOn = widget.isOn;

    return GestureDetector(
      onTap: _toggle,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: isLocked ? const Color(0xFFF1F5F9) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isLocked 
                ? const Color(0xFFE2E8F0) 
                : (isOn ? Colors.cyan.shade300 : Colors.grey.shade300),
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
          child: Column(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final isPlugged = _controller.value < 0.1;
                    // Y positions: Socket bottom is at 20 + 45 = 65.
                    // Plug starts with 20px prongs. To touch socket, Plug top = 65 - 20 = 45.
                    // Unplugged distance = 40. So top goes from 45 to 85.
                    final plugY = 45.0 + (_controller.value * 40.0);

                    return Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // Plug goes first so socket renders over it, hiding prongs
                        Positioned(
                          top: plugY,
                          child: PlugWidget(isOn: isOn && isPlugged),
                        ),
                        // Socket
                        Positioned(
                          top: 20,
                          child: SocketWidget(isOn: isOn && isPlugged),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Bottom Details
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
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
                            : (isOn ? Colors.cyan.shade100 : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOn ? "PLUGGED" : "UNPLUGGED",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isLocked
                              ? const Color(0xFF94A3B8)
                              : (isOn ? Colors.teal.shade700 : const Color(0xFF64748B)),
                        ),
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
}

class SocketWidget extends StatelessWidget {
  final bool isOn;
  const SocketWidget({super.key, required this.isOn});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOn ? Colors.cyan.shade300 : Colors.grey.shade300, 
          width: 2
        ),
        boxShadow: [
          if (isOn)
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.3),
              blurRadius: 15,
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 5,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(2),
              boxShadow: isOn ? [BoxShadow(color: Colors.cyanAccent, blurRadius: 4)] : [],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 5,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(2),
              boxShadow: isOn ? [BoxShadow(color: Colors.cyanAccent, blurRadius: 4)] : [],
            ),
          ),
        ],
      ),
    );
  }
}

class PlugWidget extends StatelessWidget {
  final bool isOn;
  const PlugWidget({super.key, required this.isOn});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Prongs
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 5,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 5,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              ),
            ),
          ],
        ),
        // Plug body
        Container(
          width: 44,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOn ? Colors.cyanAccent : Colors.redAccent,
                boxShadow: [
                  BoxShadow(
                    color: isOn ? Colors.cyanAccent : Colors.redAccent,
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Cord
        Container(
          width: 8,
          height: 100, // Long trailing cord
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            border: Border.symmetric(vertical: BorderSide(color: Colors.grey.shade400)),
          ),
        ),
      ],
    );
  }
}
