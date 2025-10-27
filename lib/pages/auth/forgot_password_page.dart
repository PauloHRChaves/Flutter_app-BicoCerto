import 'package:flutter/material.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'package:bico_certo/pages/auth/reset_password_page.dart';
import 'package:bico_certo/widgets/wave_clipper.dart';

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
        const SnackBar(
          content: Text('Código de redefinição enviado para o seu email!'),
        ),
      );

      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color.fromARGB(255, 22, 76, 110);
    const Color lightBlue = Color.fromARGB(255, 0, 100, 155);

    // Responsividade
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final double font = screenWidth * 0.05;
    final double btn = screenWidth * 0.04;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkBlue,
        elevation: 1,
        title: const Text(
          "Esqueceu a senha",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(0, -120.0),
              child: ClipPath(
                clipper: WaveClipper(),
                child: Container(color: darkBlue),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Insira seu email para receber o código de redefinição de senha:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: font),
                ),

                SizedBox(height: screenHeight * 0.03),

                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),

                SizedBox(height: screenHeight * 0.1),

                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _handleForgotPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: lightBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.2,
                            vertical: screenHeight * 0.015,
                          ),
                        ),
                        child: Text(
                          'ENVIAR',
                          style: TextStyle(
                            fontSize: btn,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
