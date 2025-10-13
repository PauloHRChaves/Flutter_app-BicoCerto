import 'package:flutter/material.dart';
import '../../controllers/chat_rooms_controller.dart';

class ChatRoomItem extends StatelessWidget {
  final Map<String, dynamic> room;
  final ChatRoomsController controller;

  const ChatRoomItem({
    Key? key,
    required this.room,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final unreadCount = room['unread_count'] as int? ?? 0;
    final hasUnread = unreadCount > 0;
    final jobTitle = room['job_title'] as String? ?? 'Sem título';
    final otherUser = room['other_user'] as Map<String, dynamic>?;
    final otherUserName = otherUser?['name'] as String? ?? 'Usuário';
    final lastMessage = room['last_message'] as Map<String, dynamic>?;
    final senderName = lastMessage?['full_name'];
    final lastMessageText = lastMessage?['message'] as String?;
    final isActive = room['is_active'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: hasUnread ? 2 : 1,
      child: ListTile(
        leading: _buildAvatar(otherUserName, isActive),
        title: _buildTitle(jobTitle, hasUnread, unreadCount),
        subtitle: _buildSubtitle(otherUserName, senderName, lastMessageText, hasUnread),
        trailing: Icon(
          Icons.chevron_right,
          color: hasUnread ? Colors.blue : Colors.grey,
        ),
        onTap: () => _handleTap(context),
      ),
    );
  }

  Widget _buildAvatar(String otherUserName, bool isActive) {
    return Stack(
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            otherUserName[0].toUpperCase(),
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (!isActive)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitle(String jobTitle, bool hasUnread, int unreadCount) {
    return Row(
      children: [
        Expanded(
          child: Text(
            jobTitle,
            style: TextStyle(
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hasUnread)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$unreadCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitle(
      String otherUserName,
      String? senderName,
      String? lastMessageText,
      bool hasUnread,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "($otherUserName)",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        if (lastMessageText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "$senderName: $lastMessageText",
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                color: hasUnread ? Colors.black87 : Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    final unreadCount = room['unread_count'] as int? ?? 0;

    if (unreadCount > 0) {
      controller.markRoomAsRead(room['room_id']);
    }

    await Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'roomId': room['room_id'] ?? '',
        'jobTitle': room['job_title'] ?? 'N/A',
      },
    );

    if (context.mounted) {
      controller.loadRooms();
    }
  }
}