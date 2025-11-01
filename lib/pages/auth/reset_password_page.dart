// lib/pages/reset_password_page.dart

import 'package:flutter/material.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'package:bico_certo/pages/auth/auth_wrapper.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? token;
  const ResetPasswordPage({super.key, this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.token != null) {
      _tokenController.text = widget.token!;
    }
  }

  void _handleResetPassword() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _authService.resetPassword(
        resetToken: _tokenController.text,
        code: _codeController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha redefinida com sucesso!')),
      );
      
      // O código de navegação é seguro após a checagem
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}')),
      );
    } finally {
      setState(() {_isLoading = false;});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redefinir Senha'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Insira o token, o código e sua nova senha.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Código de Verificação'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: 'Nova Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleResetPassword,
                    child: const Text('Redefinir Senha'),
                  ),
          ],
        ),
      ),
    );
  }
}