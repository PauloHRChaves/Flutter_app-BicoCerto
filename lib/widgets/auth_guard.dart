// lib/widgets/auth_guard.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
// IMPORT CORRIGIDO: Aponta corretamente para a sua pasta 'pages/auth'
import '../pages/auth/auth_wrapper.dart'; 

class AuthGuard extends StatefulWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  final AuthService _authService = AuthService();
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    final bool isLoggedIn = await _authService.getAuthStatus();
    
    if (!isLoggedIn && mounted) {
      // Redireciona para a tela de login (AuthWrapper)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (Route<dynamic> route) => false,
      );
    } else {
      // Se estiver logado, exibe o conteúdo da página protegida
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // Exibe um loading enquanto verifica o token
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Se a checagem terminou e o token é válido, exibe o conteúdo real da página
    return widget.child;
  }
}