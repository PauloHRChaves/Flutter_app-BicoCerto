import 'package:flutter/material.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'package:bico_certo/pages/auth/reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleForgotPassword() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _authService.forgotPassword(email: _emailController.text);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código de redefinição enviado para o seu email!')),
      );
      
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
      );
    } catch (e) {
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Esqueci a Senha'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Insira seu email para receber o código de redefinição.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 20),

            _isLoading ? const CircularProgressIndicator() : ElevatedButton(
              onPressed: _handleForgotPassword,
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}