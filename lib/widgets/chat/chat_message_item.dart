import 'package:bico_certo/widgets/chat/replied_message.dart';
import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import 'swipeable_message.dart';

class ChatMessageItem extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isRead;
  final VoidCallback onReply;

  const ChatMessageItem({
    super.key,
    required this.message,
    required this.isMe,
    required this.isRead,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return SwipeableMessage(
      key: ValueKey('msg_${message.id}_${message.replyTo?.hashCode ?? 0}'),
      isMe: isMe,
      onReply: onReply,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF156b9a) : Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.sender['name'] ?? 'Usuário',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF156b9a),
                        ),
                      ),
                    ),
                  if (message.replyTo != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RepliedMessageWidget(
                        isMe: isMe,
                        userName: message.replyTo!['sender_name'] ?? 'Usuário',
                        message: message.replyTo!['message'] ?? '',
                        onTap: () {},
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.createdAt,
                          style: TextStyle(
                            fontSize: 11,
                            color: isMe ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _buildMessageStatus(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageStatus() {
    if (message.status == 'sending') {
      return const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
        ),
      );
    }

    if (message.status == 'failed') {
      return const Icon(Icons.error_outline, size: 14, color: Colors.red);
    }

    return Icon(
      isRead ? Icons.done_all : Icons.done,
      size: 14,
      color: isRead ? Colors.blue : Colors.white70,
    );
  }
}