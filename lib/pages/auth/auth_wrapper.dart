import 'package:flutter/material.dart';
import 'package:bico_certo/pages/auth/login_page.dart';
import 'package:bico_certo/pages/auth/register_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isRegistering = false;

  void _togglePage() {
    setState(() { _isRegistering = !_isRegistering;});
  }

  @override
  Widget build(BuildContext context) {
    return _isRegistering ? RegisterPage(onLoginPressed: _togglePage) : LoginPage(onRegisterPressed: _togglePage);
  }
}