import 'package:flutter/material.dart';

class RepliedMessageWidget extends StatelessWidget {
  final String userName;
  final String message;
  final bool isMe;
  final VoidCallback? onTap;

  const RepliedMessageWidget({
    Key? key,
    required this.isMe,
    required this.userName,
    required this.message,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: const Color(0xFF156b9a),
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isMe ? const Color(0xffffffff) :  const Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message.length > 80
                  ? '${message.substring(0, 80)}...'
                  : message,
              style: TextStyle(
                fontSize: 12,
                color: isMe ? Colors.white : Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}