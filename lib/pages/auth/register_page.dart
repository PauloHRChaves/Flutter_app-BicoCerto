import 'package:flutter/material.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'package:bico_certo/widgets/wave_clipper.dart';

// ----------------------------------------------------
// PARTE 1: DEFINIÇÃO DA PÁGINA E CONTROLE DE ESTADO (UI)
// ----------------------------------------------------

class RegisterPage extends StatefulWidget {
  // Parâmetro para a função que troca para a tela de login
  final Function onLoginPressed;
  const RegisterPage({super.key, required this.onLoginPressed});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  // Chave para validar o formulário
  final _formKey = GlobalKey<FormState>();

  // Controladores para pegar o texto dos campos
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _passwordVisible2 = false;
  // ----------------------------------------------------
  // PARTE 2: LÓGICA DE LOGIN (COMUNICAÇÃO COM API)
  // ----------------------------------------------------

  // Instância do AuthService para comunicação com a API
  final AuthService _authService = AuthService();

  // Função que executa a lógica de login
  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _authService.register(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _fullNameController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuário cadastrado com sucesso!')),
          );
          widget.onLoginPressed();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro no cadastro: ${e.toString()}')),
          );
        }
      }
    }
  }

  // Validador
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'A senha é obrigatória';
    }
    if (value.length < 8) {
      return 'Mínimo de 8 caracteres';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Deve conter 1 letra maiúscula';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Deve conter 1 letra minúscula';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Deve conter 1 caracter especial';
    }
    return null;
  }

  // ----------------------------------------------------
  // PARTE 3: CONSTRUÇÃO DA INTERFACE VISUAL (UI)
  // ----------------------------------------------------

  // Função auxiliar para criar a decoração dos campos de texto - Possivelmente passar para pasta widgets/
  InputDecoration _inputDecoration(String label, IconData icon) {
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

    const Color darkBlue = Color.fromARGB(255, 22, 76, 110);
    const Color lightBlue = Color.fromARGB(255, 0, 100, 155);

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
                    SizedBox(height: screenHeight * 0.07),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),

                      // CORREÇÃO: A imagem é o filho direto.
                      child: Image.asset(
                        'assets/images/icon.png',
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Título
                    Text(
                      'CADASTRO',
                      style: TextStyle(
                        fontSize: fonttitle,
                        fontWeight: FontWeight.bold,
                        color: lightBlue,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // Input
                    TextFormField(
                      controller: _fullNameController,
                      decoration: _inputDecoration(
                        'Nome Completo',
                        Icons.person,
                      ),
                      validator: (value) => value!.isEmpty
                          ? 'O nome completo é obrigatório'
                          : null,
                    ),

                    SizedBox(height: screenHeight * 0.02),

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
                      validator: _validatePassword,
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Input
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: _inputDecorationPass('Confirmar Senha', Icons.lock).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible2
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible2 = !_passwordVisible2;
                            });
                          },
                        ),
                      ),
                      obscureText: !_passwordVisible2,
                      
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Confirme sua senha';
                        }
                        if (value != _passwordController.text) {
                          return 'As senhas não coincidem';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Botão Cadastrar chama logica de Register
                    ElevatedButton(
                      onPressed: _handleRegister,
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
                        'CADASTRAR',
                        style: TextStyle(
                          fontSize: font,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // Trocar para tela de Login
                    TextButton(
                      onPressed: () => widget.onLoginPressed(),
                      child: Text(
                        'Já possui uma conta? Login',
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