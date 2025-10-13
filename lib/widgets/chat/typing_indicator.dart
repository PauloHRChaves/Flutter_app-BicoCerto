import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final String userName;
  final bool showUserName;
  final Color bubbleColor;
  final Color dotColor;

  const TypingIndicator({
    super.key,
    required this.userName,
    this.showUserName = true,
    this.bubbleColor = const Color(0xFFE0E0E0),
    this.dotColor = const Color(0xFF757575),
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.bubbleColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showUserName) ...[
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                _buildAnimatedDot(0),
                const SizedBox(width: 4),
                _buildAnimatedDot(1),
                const SizedBox(width: 4),
                _buildAnimatedDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final delay = index * 0.2;
        final value = (_controller.value - delay) % 1.0;

        final scale = value < 0.5
            ? 1.0 + (value * 2) * 0.5
            : 1.5 - ((value - 0.5) * 2) * 0.5;

        return Transform.scale(
          scale: scale.clamp(0.8, 1.5),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.dotColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}