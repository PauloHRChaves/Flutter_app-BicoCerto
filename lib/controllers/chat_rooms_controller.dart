import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/chat_api_service.dart';

class ChatRoomsController extends ChangeNotifier {
  final ChatApiService _apiService;

  List<dynamic> _rooms = [];
  bool _isLoading = false;
  String? _error;
  WebSocketChannel? _notificationsChannel;
  StreamSubscription? _notificationsSubscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  List<dynamic> get rooms => _rooms;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _isConnected;

  ChatRoomsController(this._apiService);

  Future<void> initialize() async {
    await _connectNotificationsWebSocket();
  }

  Future<void> loadRooms({bool onlyActive = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getChatRooms(onlyActive: onlyActive);
      _rooms = data;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _rooms = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _connectNotificationsWebSocket() async {
    if (_isConnecting) {
      return;
    }

    _isConnecting = true;

    try {
      final token = await _apiService.getToken();
      if (token == null || token.isEmpty) {
        _isConnecting = false;
        return;
      }

      _notificationsChannel = await _apiService.connectNotificationsWebSocket();
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      notifyListeners();

      _notificationsSubscription = _notificationsChannel!.stream.listen(
            (message) {
          try {
            _handleNotificationMessage(message);
          } catch (e) {
            // Silent fail
          }
        },
        onError: (error) {
          _handleWebSocketError(error);
        },
        onDone: () {
          _handleWebSocketClosed();
        },
        cancelOnError: false,
      );

      _startHeartbeat();

    } catch (e) {
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
      _scheduleReconnect();
    }
  }

  void _handleNotificationMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];

      switch (type) {
        case 'connected':
          break;

        case 'room_update':
          _handleRoomUpdate(data['data']);
          break;

        case 'pong':
          break;

        default:
          break;
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _handleRoomUpdate(Map<String, dynamic> roomData) {
    final roomId = roomData['room_id'];
    final roomIndex = _rooms.indexWhere((room) => room['room_id'] == roomId);

    if (roomIndex != -1) {
      _rooms.removeAt(roomIndex);
      _rooms.insert(0, roomData);
      notifyListeners();
    } else {
      _rooms.insert(0, roomData);
      notifyListeners();
    }
  }

  void _handleWebSocketError(dynamic error) {
    _isConnected = false;
    _isConnecting = false;
    notifyListeners();
    _scheduleReconnect();
  }

  void _handleWebSocketClosed() {
    _isConnected = false;
    _isConnecting = false;
    _heartbeatTimer?.cancel();
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _reconnectAttempts = 0;
      return;
    }

    _reconnectAttempts++;

    final delay = Duration(seconds: (2 * _reconnectAttempts).clamp(2, 30));

    _reconnectTimer = Timer(delay, () {
      if (!_isConnected && !_isConnecting) {
        _connectNotificationsWebSocket();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_notificationsChannel != null && _isConnected) {
        try {
          _notificationsChannel!.sink.add('ping');
        } catch (e) {
          _isConnected = false;
          notifyListeners();
          _scheduleReconnect();
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> markRoomAsRead(String roomId) async {
    try {
      await _apiService.markRoomAsRead(roomId);

      final roomIndex = _rooms.indexWhere((room) => room['room_id'] == roomId);
      if (roomIndex != -1) {
        final room = Map<String, dynamic>.from(_rooms[roomIndex]);
        room['unread_count'] = 0;
        _rooms[roomIndex] = room;
        notifyListeners();
      }
    } catch (e) {
      // Silent fail
    }
  }

  int get totalUnreadCount {
    return _rooms.fold<int>(
        0,
            (sum, room) => sum + (room['unread_count'] as int? ?? 0)
    );
  }

  Future<void> reconnect() async {
    _reconnectAttempts = 0;
    await disconnect();
    await _connectNotificationsWebSocket();
  }

  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _notificationsSubscription?.cancel();
    await _notificationsChannel?.sink.close();
    _notificationsChannel = null;
    _isConnected = false;
    _isConnecting = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadRooms();
    if (!_isConnected && !_isConnecting) {
      await _connectNotificationsWebSocket();
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _notificationsSubscription?.cancel();
    _notificationsChannel?.sink.close();
    _isConnected = false;
    _isConnecting = false;
    super.dispose();
  }
}