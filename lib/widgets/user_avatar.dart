// lib/widgets/user_avatar.dart

import 'package:flutter/material.dart';
import 'package:bico_certo/services/user_profile_service.dart';

class UserAvatar extends StatefulWidget {
  final String userId;
  final String? userName;
  final double radius;
  final Color backgroundColor;
  final bool showBorder;
  final Color? borderColor;

  const UserAvatar({
    super.key,
    required this.userId,
    this.userName,
    this.radius = 30.0,
    this.backgroundColor = Colors.blue,
    this.showBorder = false,
    this.borderColor,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  final UserProfileService _profileService = UserProfileService();
  String? _imageUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadProfilePicture();
    }
  }

  Future<void> _loadProfilePicture() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final imageUrl = await _profileService.getUserProfilePicture(widget.userId);

      if (mounted) {
        setState(() {
          _imageUrl = imageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar foto do usuário ${widget.userId}: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  String get _userInitial {
    if (widget.userName != null && widget.userName!.isNotEmpty) {
      return widget.userName!.substring(0, 1).toUpperCase();
    }
    return '?';
  }

  Widget _buildAvatar() {
    final hasImage = _imageUrl != null &&
        _imageUrl!.isNotEmpty &&
        !_hasError;

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      backgroundImage: hasImage ? NetworkImage(_imageUrl!) : null,
      onBackgroundImageError: hasImage
          ? (exception, stackTrace) {
        print('Erro ao carregar imagem: $exception');
        if (mounted) {
          setState(() => _hasError = true);
        }
      }
          : null,
      child: hasImage
          ? null
          : _isLoading
          ? SizedBox(
        width: widget.radius * 0.6,
        height: widget.radius * 0.6,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.white.withOpacity(0.7),
          ),
        ),
      )
          : Text(
        _userInitial,
        style: TextStyle(
          color: Colors.white,
          fontSize: widget.radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatar();

    if (widget.showBorder) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.borderColor ?? Colors.white,
            width: 3,
          ),
        ),
        child: avatar,
      );
    }

    return avatar;
  }
}