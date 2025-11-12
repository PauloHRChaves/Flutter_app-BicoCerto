import 'package:flutter/foundation.dart';

class ChatStateService extends ChangeNotifier {
  static final ChatStateService _instance = ChatStateService._internal();
  factory ChatStateService() => _instance;
  ChatStateService._internal();

  String? _currentRoomId;
  DateTime? _enteredRoomAt;
  bool _isActive = false;

  String? get currentRoomId => _currentRoomId;
  bool get isActive => _isActive;
  DateTime? get enteredRoomAt => _enteredRoomAt;

  void setCurrentRoom(String roomId) {
    _currentRoomId = roomId;
    _enteredRoomAt = DateTime.now();
    _isActive = true;
    notifyListeners();
  }

  void setInactive() {
    _isActive = false;
    notifyListeners();
  }

  void setActive() {
    if (_currentRoomId != null) {
      _isActive = true;
      notifyListeners();
    }
  }

  bool isInRoom(String roomId) {
    if (_currentRoomId != roomId) {
      return false;
    }

    if (!_isActive) {
      return false;
    }

    if (_enteredRoomAt != null) {
      final duration = DateTime.now().difference(_enteredRoomAt!);
      if (duration.inHours > 1) {
        clearCurrentRoom();
        return false;
      }
    }

    return true;
  }

  bool isInAnyRoom() {
    return _currentRoomId != null;
  }

  void clearCurrentRoom() {
    _currentRoomId = null;
    _enteredRoomAt = null;
    _isActive = false;
    notifyListeners();
  }

  void forceReset() {
    clearCurrentRoom();
  }
}