import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/chat_rooms_controller.dart';
import '../../widgets/chat/chat_room_item.dart';

class ChatRoomsScreen extends StatefulWidget {
  const ChatRoomsScreen({Key? key}) : super(key: key);

  @override
  State<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends State<ChatRoomsScreen> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatRoomsController>().loadRooms();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ChatRoomsController>().loadRooms();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversas'),
        actions: [
          Consumer<ChatRoomsController>(
            builder: (context, controller, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    if (controller.totalUnreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${controller.totalUnreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChatRoomsController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.rooms.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (controller.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(controller.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.loadRooms(),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          if (controller.rooms.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma conversa ainda',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.loadRooms(),
            child: ListView.builder(
              itemCount: controller.rooms.length,
              itemBuilder: (context, index) {
                final room = controller.rooms[index];
                return ChatRoomItem(
                  room: room,
                  controller: controller,
                );
              },
            ),
          );
        },
      ),
    );
  }
}