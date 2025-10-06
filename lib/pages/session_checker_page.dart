import 'package:flutter/material.dart';
import 'package:bico_certo/pages/home/home_page.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'package:bico_certo/widgets/loading_screen.dart';

class SessionCheckerPage extends StatefulWidget {
  const SessionCheckerPage({super.key});

  @override
  State<SessionCheckerPage> createState() => _SessionCheckerPageState();
}

class _SessionCheckerPageState extends State<SessionCheckerPage> {
  final AuthService _authService = AuthService();
  
  @override
  void initState() {
    super.initState();
    _checkAuthStatusAndNavigate();
  }

  void _checkAuthStatusAndNavigate() async {
    final isLoggedIn = await _authService.getAuthStatus();
    
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomePage(isLoggedIn: isLoggedIn)),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const LoadingScreen();
  }
}