import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/chat_scroll_controller.dart';
import '../../widgets/chat/chat_message_item.dart';
import '../../widgets/chat/chat_input_field.dart';
import '../../widgets/chat/replying_to_widget.dart';
import '../../widgets/chat/scroll_to_bottom_button.dart';
import '../../widgets/chat/typing_indicator.dart';
import '../../models/chat_message.dart';
import 'package:flutter/scheduler.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  late ChatController _chatController;
  late final ChatScrollController _scrollController = ChatScrollController();
  ChatMessage? _replyingToMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final roomId = args['roomId'] as String;

    _chatController = ChatController(roomId: roomId);

    _scrollController.onUserReachedBottom = () {
      _chatController.markAsRead();
    };

    _chatController.shouldAutoMarkAsRead = () {
      return _scrollController.isUserAtBottom;
    };

    _chatController.onNewMessageReceived = () {
      _handleNewMessageReceived();
    };

    _chatController.initialize().then((_) {
      if (!mounted) return;

      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          _scrollController.scrollToBottom(animated: false);
        });
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _chatController.reconnect();
    } else if (state == AppLifecycleState.paused) {
      _chatController.sendTypingStatus(false);
    }
  }

  void _handleNewMessageReceived() {
    if (!mounted) return;

    if (_scrollController.isUserAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollController.scrollToBottom(animated: true);
        }
      });
    } else {
      _scrollController.incrementUnreadCount();
    }
  }

  void _startReplyTo(ChatMessage message) {
    setState(() => _replyingToMessage = message);
  }

  void _cancelReply() {
    setState(() => _replyingToMessage = null);
  }

  void _handleSendMessage(String text) async {
    Map<String, dynamic>? replyToData;

    if (_replyingToMessage != null) {
      replyToData = {
        'id': _replyingToMessage!.id,
        'message': _replyingToMessage!.message,
        'sender_id': _replyingToMessage!.sender['id'],
        'sender_name': _replyingToMessage!.sender['name'],
      };
    }

    setState(() => _replyingToMessage = null);

    try {
      await _chatController.sendMessage(text, replyTo: replyToData);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollController.scrollToBottom(animated: true);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final jobTitle = args['jobTitle'] as String;

    return ChangeNotifierProvider.value(
      value: _chatController,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(jobTitle)
            ],
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: _buildMessagesList(),
                ),
                Column(
                  children: [
                    if (_replyingToMessage != null)
                      ReplyingToWidget(
                        userName: _replyingToMessage!.sender['name'] ?? 'Usuário',
                        message: _replyingToMessage!.message,
                        onCancel: _cancelReply,
                      ),
                    ChatInputField(
                      onSendMessage: _handleSendMessage,
                      onTypingChanged: _chatController.sendTypingStatus,
                    ),
                  ],
                ),
              ],
            ),
            ListenableBuilder(
              listenable: _scrollController,
              builder: (context, child) {
                if (!_scrollController.showScrollToBottomButton) {
                  return const SizedBox.shrink();
                }
                return ScrollToBottomButton(
                  onPressed: () {
                    _scrollController.scrollToBottom(animated: true);
                    _chatController.markAsRead();
                  },
                  unreadCount: _scrollController.unreadCount,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return Consumer<ChatController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.messages.isEmpty) {
          return const Center(child: Text('Nenhuma mensagem ainda'));
        }

        final reversedMessages = controller.messages.reversed.toList();

        return ListView.builder(
          controller: _scrollController.scrollController,
          padding: const EdgeInsets.all(16),
          reverse: true,
          itemCount: reversedMessages.length +
              (controller.isOtherUserTyping ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0 && controller.isOtherUserTyping) {
              return TypingIndicator(
                key: const ValueKey('typing_indicator'),
                userName: controller.typingUserName,
                showUserName: false,
              );
            }

            final messageIndex = controller.isOtherUserTyping ? index - 1 : index;
            final message = reversedMessages[messageIndex];
            final isMe = message.sender['id'] == controller.currentUserId;
            final isRead = controller.isMessageRead(
              message.id,
              message.sender['id'],
            );

            return ChatMessageItem(
              message: message,
              isMe: isMe,
              isRead: isRead,
              onReply: () => _startReplyTo(message),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}