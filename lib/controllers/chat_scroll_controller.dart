import 'package:flutter/material.dart';

class ChatScrollController extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();

  bool _isUserAtBottom = true;
  bool _showScrollToBottomButton = false;
  int _unreadCount = 0;

  VoidCallback? onUserReachedBottom;

  bool get isUserAtBottom => _isUserAtBottom;
  bool get showScrollToBottomButton => _showScrollToBottomButton;
  int get unreadCount => _unreadCount;

  ChatScrollController() {
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;

    final currentScroll = scrollController.position.pixels;
    final isAtBottom = currentScroll < 100;

    if (isAtBottom != _isUserAtBottom) {
      final wasNotAtBottom = !_isUserAtBottom;

      _isUserAtBottom = isAtBottom;

      if (isAtBottom) {
        _unreadCount = 0;
        _showScrollToBottomButton = false;

        if (wasNotAtBottom && onUserReachedBottom != null) {
          onUserReachedBottom!();
        }
      } else {
        _showScrollToBottomButton = true;
      }

      notifyListeners();
    }
  }

  void scrollToBottom({bool animated = true}) {
    if (!scrollController.hasClients) {
      return;
    }

    final position = scrollController.position;

    if (!position.hasContentDimensions) {

      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom(animated: animated);
      });
      return;
    }

    if (animated) {
      scrollController.animateTo(
        position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      scrollController.jumpTo(position.minScrollExtent);
    }

    _isUserAtBottom = true;
    _showScrollToBottomButton = false;
    _unreadCount = 0;
    notifyListeners();
  }

  void incrementUnreadCount() {
    if (!_isUserAtBottom) {
      _unreadCount++;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}