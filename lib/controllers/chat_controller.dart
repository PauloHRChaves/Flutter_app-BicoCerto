import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import '../services/chat_api_service.dart';
import '../services/auth_service.dart';
import '../models/chat_message.dart';

class ChatController extends ChangeNotifier {
  final ChatApiService _chatService;
  final AuthService _authService;
  final String roomId;

  ChatController({
    required this.roomId,
    ChatApiService? chatService,
    AuthService? authService,
  })  : _chatService = chatService ?? ChatApiService(),
        _authService = authService ?? AuthService();

  final List<ChatMessage> _messages = [];
  final Map<String, bool> _readStatus = {};
  String? _currentUserId;
  bool _isLoading = true;
  bool _isConnected = false;
  bool _otherUserOnline = false;
  dynamic _channel;
  bool Function()? shouldAutoMarkAsRead;
  VoidCallback? onNewMessageReceived;

  bool _isOtherUserTyping = false;
  String _typingUserName = '';
  Timer? _typingTimer;

  List<ChatMessage> get messages => _messages;
  Map<String, bool> get readStatus => _readStatus;
  String? get currentUserId => _currentUserId;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  bool get otherUserOnline => _otherUserOnline;
  bool get isOtherUserTyping => _isOtherUserTyping;
  String get typingUserName => _typingUserName;

  bool isMessageRead(String messageId, String senderId) {
    if (senderId != _currentUserId) return false;
    return _readStatus[messageId] ?? false;
  }

  Future<void> initialize() async {
    await _loadCurrentUserId();
    await _loadMessages();
    await _connectWebSocket();
    _markAsReadWhenReady();
  }

  void _markAsReadWhenReady() {
    if (_isConnected) {
      markAsRead();
      return;
    }

    int attempts = 0;
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      attempts++;

      if (_isConnected) {
        timer.cancel();
        markAsRead();
      } else if (attempts >= 10) {
        timer.cancel();
        _chatService.markRoomAsRead(roomId);
      }
    });
  }

  Future<void> _loadCurrentUserId() async {
    _currentUserId = await _authService.getUserId();
    notifyListeners();
  }

  Future<void> _loadMessages() async {
    try {
      final data = await _chatService.getRoomMessages(roomId: roomId);
      _messages.clear();

      final messagesList = data['messages'] as List;
      _messages.addAll(
        messagesList.map((json) => ChatMessage.fromJson(json)),
      );

      for (var msgJson in messagesList) {
        final msgId = msgJson['id'];
        final senderId = msgJson['sender']['id'];

        if (senderId == _currentUserId) {
          _readStatus[msgId] = msgJson['read_at'] != null;
        }
      }

      _isLoading = false;
      notifyListeners();

      await _chatService.markRoomAsRead(roomId);
      _sendReadReceipt();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _connectWebSocket() async {
    try {
      _channel = await _chatService.connectWebSocket(roomId);
      _isConnected = true;
      notifyListeners();

      _channel.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDone,
      );
    } catch (e) {
      _isConnected = false;
      notifyListeners();
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    final data = jsonDecode(message);

    switch (data['type']) {
      case 'new_message':
        _handleNewMessage(data['message']);
        break;
      case 'typing':
        _handleTyping(data);
        break;
      case 'messages_read':
        _handleMessagesRead(data);
        break;
      case 'user_online':
        _handleUserOnline(data['user_id']);
        break;
      case 'user_left':
        _handleUserLeft(data['user_id']);
        break;
      case 'unread_status':
        _handleUnreadStatus(data);
        break;
    }
  }

  void _handleNewMessage(Map<String, dynamic> messageData) {
    final newMessage = ChatMessage.fromJson(messageData);
    final existingIndex = _messages.indexWhere((msg) => msg.id == newMessage.id);
    final tempIndex = _messages.indexWhere(
          (msg) => msg.isTemporary && msg.message == newMessage.message,
    );

    bool isNewMessageFromOther = false;

    if (existingIndex != -1) {
      _messages[existingIndex] = newMessage.copyWith(status: 'sent');

      if (newMessage.sender['id'] == _currentUserId) {
        _readStatus[newMessage.id] = false;
      }
    } else if (tempIndex != -1) {
      _messages.removeAt(tempIndex);
      _messages.insert(tempIndex, newMessage);

      if (newMessage.sender['id'] == _currentUserId) {
        _readStatus[newMessage.id] = false;
      }
    } else {
      _messages.add(newMessage);

      if (newMessage.sender['id'] != _currentUserId) {
        isNewMessageFromOther = true;

        final shouldMark = shouldAutoMarkAsRead?.call() ?? false;

        if (shouldMark) {
          Future.delayed(const Duration(milliseconds: 300), () {
            markAsRead();
          });
        }
      }
    }

    notifyListeners();

    if (isNewMessageFromOther && onNewMessageReceived != null) {
      Future.microtask(() {
        onNewMessageReceived?.call();
      });
    }
  }

  void _handleTyping(Map<String, dynamic> data) {
    final userId = data['user_id'];
    final isTyping = data['is_typing'] ?? false;
    final userName = data['user_name'] ?? 'Usuário';

    if (userId != _currentUserId) {
      _isOtherUserTyping = isTyping;
      _typingUserName = userName;
      notifyListeners();

      _typingTimer?.cancel();
      if (isTyping) {
        _typingTimer = Timer(const Duration(seconds: 5), () {
          _isOtherUserTyping = false;
          notifyListeners();
        });
      }
    }
  }

  void _handleMessagesRead(Map<String, dynamic> data) {
    final readByUserId = data['user_id'];

    if (readByUserId == _currentUserId) {
      return;
    }

    for (var msg in _messages) {
      if (msg.sender['id'] == _currentUserId) {
        _readStatus[msg.id] = true;
      }
    }

    notifyListeners();
  }

  void _handleUnreadStatus(Map<String, dynamic> data) {
    final messages = data['messages'] as List?;

    if (messages == null) return;

    for (var msg in messages) {
      final messageId = msg['message_id'];
      _readStatus[messageId] = true;
    }

    notifyListeners();
  }

  void _handleUserOnline(String userId) {
    if (userId != _currentUserId) {
      _otherUserOnline = true;
      notifyListeners();
    }
  }

  void _handleUserLeft(String userId) {
    if (userId != _currentUserId) {
      _otherUserOnline = false;
      _isOtherUserTyping = false;
      notifyListeners();
    }
  }

  void _handleWebSocketError(error) {
    _isConnected = false;
    notifyListeners();

    Future.delayed(const Duration(seconds: 3), () {
      _connectWebSocket();
    });
  }

  void _handleWebSocketDone() {
    _isConnected = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text, {Map<String, dynamic>? replyTo}) async {
    if (text.trim().isEmpty) return;

    final optimisticMessage = ChatMessage.optimistic(
      currentUserId: _currentUserId!,
      message: text,
      replyTo: replyTo,
    );

    _messages.add(optimisticMessage);
    _readStatus[optimisticMessage.id] = false;
    notifyListeners();

    try {
      await _chatService.sendMessage(
        roomId: roomId,
        message: text,
        replyToId: replyTo?['id'],
      );
    } catch (e) {
      final index = _messages.indexWhere((msg) => msg.id == optimisticMessage.id);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(status: 'failed');
        notifyListeners();
      }
      rethrow;
    }
  }

  void sendTypingStatus(bool isTyping) {
    if (_channel != null && _isConnected) {
      try {
        _channel.sink.add(jsonEncode({
          "type": "typing",
          "is_typing": isTyping,
        }));
      } catch (e) {
        // Silent fail
      }
    }
  }

  void _sendReadReceipt() {
    if (_channel != null && _isConnected) {
      try {
        _channel.sink.add(jsonEncode({"type": "read"}));
      } catch (e) {
        // Silent fail
      }
    }
  }

  Future<void> markAsRead() async {
    await _chatService.markRoomAsRead(roomId);
    _sendReadReceipt();
  }

  Future<void> reconnect() async {
    if (!_isConnected) {
      await _connectWebSocket();
    }
    await markAsRead();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}