import 'package:flutter/material.dart';
import 'package:bico_certo/widgets/wave_clipper.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'package:bico_certo/pages/home/home_page.dart';
import 'package:bico_certo/pages/auth/forgot_password_page.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import '../../controllers/chat_rooms_controller.dart';

// ----------------------------------------------------
// DEFINIÇÃO DA PÁGINA E CONTROLE DE ESTADO (UI)
// ----------------------------------------------------

class LoginPage extends StatefulWidget {
  // Parâmetro para a função que troca para a tela de registro
  final Function onRegisterPressed;
  const LoginPage({super.key, required this.onRegisterPressed});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  bool _passwordVisible = false;

  // Controladores para pegar o texto dos campos de email e senha
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Instância do AuthService para comunicação com a API
  final AuthService _authService = AuthService();

  // Função que executa a lógica de login
  Future<void> _handleLogin() async {
    // Valida o formulário antes de tentar o login
    if (_formKey.currentState!.validate()) {
      try {
        // Uso da API: Chama o método para obter informações do dispositivo
        final Map<String, dynamic> deviceInfo = await _authService
            .getDeviceInfo();

        // Uso da API: Chama o método de login do AuthService, passando os dados
        await _authService.login(
          email: _emailController.text,
          password: _passwordController.text,
          deviceInfo: deviceInfo,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login realizado com sucesso!')),
          );
          final chatController = context.read<ChatRoomsController>();
          await chatController.initialize();
          // Navigator.of(context).pushReplacement(
          //   MaterialPageRoute(
          //     builder: (context) => const HomePage(isLoggedIn: true),
          //   ),
          // );

          Navigator.pushNamed(context, '/chat_rooms');
        }
      } catch (e) {
        // Lógica de erro: exibe uma mensagem de erro se o login falhar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro no login: ${e.toString()}')),
          );
        }
      }
    }
  }

  // Função auxiliar para criar a decoração dos campos de texto - Possivelmente passar para pasta widgets/
  InputDecoration _inputDecoration(String label, IconData icon,) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    );
  }

  // Função auxiliar para criar a decoração dos campos de texto - Possivelmente passar para pasta widgets/
  InputDecoration _inputDecorationPass(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final double font = screenWidth * 0.04;
    final double fonttitle = screenWidth * 0.1;
    final double fontnormal = screenWidth * 0.038;

    const Color darkBlue = Color.fromARGB(255, 22, 76, 110);
    const Color lightBlue = Color.fromARGB(255, 0, 100, 155);
    const Color textblack = Color.fromARGB(255, 33, 33, 33);

    return Scaffold(
      appBar: AppBar(backgroundColor: darkBlue),
      body: Stack(
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(0, -130),
              child: ClipPath(
                clipper: WaveClipper(),
                child: Container(color: darkBlue),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.1),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(30.0),

                      child: Image.asset(
                        'assets/images/icon.png',
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Título
                    Text(
                      'LOGIN',
                      style: TextStyle(
                        fontSize: fonttitle,
                        fontWeight: FontWeight.bold,
                        color: lightBlue,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.01),

                    // Input
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration('Email', Icons.email),
                      validator: (value) =>
                          value!.isEmpty ? 'O email é obrigatório' : null,
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // Input
                    TextFormField(
                      controller: _passwordController,
                      decoration: _inputDecorationPass('Senha', Icons.lock).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_passwordVisible,
                      validator: (value) => value!.isEmpty ? 'A senha é obrigatória' : null,
                    ),

                    // Botão Esqueceu a senha
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Esqueceu a senha?',
                          style: TextStyle(
                            color: textblack,
                            fontSize: fontnormal,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // Botão Login chama a logica de Login
                    ElevatedButton(
                      onPressed: _handleLogin,
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
                        'ENTRAR',
                        style: TextStyle(
                          fontSize: font,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // Trocar para tela de Register
                    TextButton(
                      // Usa o callback passado do AuthWrapper para mudar a tela
                      onPressed: () => widget.onRegisterPressed(),
                      child: Text(
                        'Ainda não possui uma conta? Registrar',
                        style: TextStyle(
                          fontSize: font,
                          fontFamily: 'Inter',
                          color: const Color.fromARGB(255, 8, 109, 163),
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.15),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// const SizedBox - apenas um espaçamento entre elementos para manter responsividade