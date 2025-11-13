import 'package:flutter/material.dart';
import '../services/pending_rating_service.dart';
import '../main.dart' show showPendingRatingModal;

class PendingRatingChecker extends StatefulWidget {
  final Widget child;

  const PendingRatingChecker({
    super.key,
    required this.child,
  });

  @override
  State<PendingRatingChecker> createState() => _PendingRatingCheckerState();
}

class _PendingRatingCheckerState extends State<PendingRatingChecker> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    _checkPendingRating();
  }

  Future<void> _checkPendingRating() async {
    if (_hasChecked) return;

    // Aguardar um pouco para garantir que a tela carregou
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final hasPending = await PendingRatingService.hasPendingRating();
    if (hasPending && mounted) {
      _hasChecked = true;
      showPendingRatingModal(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}