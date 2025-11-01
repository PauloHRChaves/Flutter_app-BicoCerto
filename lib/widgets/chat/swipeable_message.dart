import 'package:flutter/material.dart';

class SwipeableMessage extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  final bool isMe;

  const SwipeableMessage({
    super.key,
    required this.child,
    required this.onReply,
    this.isMe = false,
  });

  @override
  State<SwipeableMessage> createState() => _SwipeableMessageState();
}

class _SwipeableMessageState extends State<SwipeableMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;
  bool _dragUnderway = false;

  static const double _kSwipeThreshold = 80.0;
  static const double _kMaxSwipe = 100.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _dragUnderway = true;
    _controller.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_dragUnderway) return;

    final delta = details.primaryDelta ?? 0;

    if (delta > 0 || _dragExtent > 0) {
      setState(() {
        _dragExtent += delta;
        _dragExtent = _dragExtent.clamp(0.0, _kMaxSwipe);
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragUnderway) return;
    _dragUnderway = false;

    if (_dragExtent >= _kSwipeThreshold) {
      widget.onReply();
    }

    _animateBack();
  }

  void _animateBack() {
    _controller.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _dragExtent = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragExtent / _kSwipeThreshold).clamp(0.0, 1.0);

    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: widget.isMe
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  left: widget.isMe ? 0 : 20,
                  right: widget.isMe ? 20 : 0,
                ),
                child: Opacity(
                  opacity: progress,
                  child: Transform.scale(
                    scale: 0.8 + (progress * 0.2),
                    child: Icon(
                      Icons.reply,
                      color: Colors.grey[600],
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}