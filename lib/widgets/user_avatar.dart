import 'package:flutter/material.dart';
import 'package:bico_certo/services/user_profile_service.dart';

class UserAvatar extends StatefulWidget {
  final String userId;
  final String? userName;
  final double radius;
  final Color backgroundColor;
  final bool showBorder;
  final Color? borderColor;
  final bool enablePreview; // ✅ NOVO: Habilitar preview ao clicar

  const UserAvatar({
    super.key,
    required this.userId,
    this.userName,
    this.radius = 30.0,
    this.backgroundColor = Colors.blue,
    this.showBorder = false,
    this.borderColor,
    this.enablePreview = true, // ✅ NOVO: Habilitado por padrão
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

  void _showImagePreview() {
    if (!widget.enablePreview) return;

    final hasValidImage = _imageUrl != null && _imageUrl!.isNotEmpty && !_hasError;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _ImagePreviewDialog(
        imageUrl: hasValidImage ? _imageUrl : null,
        userName: widget.userName,
        userInitial: _userInitial,
        backgroundColor: widget.backgroundColor,
      ),
    );
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

    final clickableAvatar = widget.enablePreview
        ? GestureDetector(
      onTap: _showImagePreview,
      child: avatar,
    )
        : avatar;

    if (widget.showBorder) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.borderColor ?? Colors.white,
            width: 3,
          ),
        ),
        child: clickableAvatar,
      );
    }

    return clickableAvatar;
  }
}

class _ImagePreviewDialog extends StatelessWidget {
  final String? imageUrl;
  final String? userName;
  final String userInitial;
  final Color backgroundColor;

  const _ImagePreviewDialog({
    required this.imageUrl,
    required this.userName,
    required this.userInitial,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Imagem ou avatar grande
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: userName != null && userName!.isNotEmpty
                  ? const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              )
                  : BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: userName != null && userName!.isNotEmpty
                  ? const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              )
                  : BorderRadius.circular(16),
              child: hasImage
                  ? InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder();
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              )
                  : _buildPlaceholder(),
            ),
          ),

          const SizedBox(height: 20),

          FloatingActionButton(
            onPressed: () => Navigator.of(context).pop(),
            backgroundColor: Colors.white,
            child: const Icon(Icons.close, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 300,
      height: 300,
      color: backgroundColor,
      child: Center(
        child: Text(
          userInitial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 120,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}