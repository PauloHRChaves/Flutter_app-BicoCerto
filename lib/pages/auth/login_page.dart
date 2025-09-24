import 'package:flutter/material.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'package:bico_certo/pages/home/home_page.dart';
import 'package:bico_certo/widgets/wave_clipper.dart';
//import 'package:bico_certo/pages/forgot_password_page.dart';

// ----------------------------------------------------
// PARTE 1: DEFINIÇÃO DA PÁGINA E CONTROLE DE ESTADO (UI)
// ----------------------------------------------------

class LoginPage extends StatefulWidget {
  // Parâmetro para a função que troca para a tela de registro
  final Function onRegisterPressed;
  const LoginPage({super.key, required this.onRegisterPressed});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  // Chave para validar o formulário
  final _formKey = GlobalKey<FormState>();

  // Controladores para pegar o texto dos campos de email e senha
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // ----------------------------------------------------
  // PARTE 2: LÓGICA DE LOGIN (COMUNICAÇÃO COM API)
  // ----------------------------------------------------
  
  // Instância do AuthService para comunicação com a API
  final AuthService _authService = AuthService();

  // Função que executa a lógica de login
  void _handleLogin() async {
    // Valida o formulário antes de tentar o login
    if (_formKey.currentState!.validate()) {
      try {
        // Uso da API: Chama o método para obter informações do dispositivo
        final Map<String, dynamic> deviceInfo = await _authService.getDeviceInfo();
        
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
        }
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage(isLoggedIn: true)),
          );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(      
        children: [
        Positioned.fill(
          child: ClipPath(
            clipper: WaveClipper(),
            child: Container(
              color: const Color.fromARGB(255, 21, 107, 154),
            ),
          ),
        ),
      
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form( 
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Título
                    const Text(
                      'LOGIN',
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 25, 116, 172),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Input
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration('Email', Icons.email),
                      validator: (value) => value!.isEmpty ? 'O email é obrigatório' : null,
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Input
                    TextFormField(
                      controller: _passwordController,
                      decoration: _inputDecoration('Senha', Icons.lock),
                      obscureText: true,
                      validator: (value) => value!.isEmpty ? 'A senha é obrigatória' : null,
                    ),
                    
                    const SizedBox(height: 15),
                    
                    /*
                    // Botão de "Esqueceu a senha?" (UI) - AINDA NÃO APLICADO
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                          );
                        },
                        child: const Text(
                          'Esqueceu a senha?',
                          style: TextStyle(color: Color.fromARGB(255, 25, 116, 172)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    */
                    
                    // Botão Login chama a logica de Login
                    ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 25, 116, 172),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                      ),
                      child: const Text(
                        'ENTRAR',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Trocar para tela de Register
                    TextButton(
                      // Usa o callback passado do AuthWrapper para mudar a tela
                      onPressed: () => widget.onRegisterPressed(),
                      child: const Text(
                        'Ainda não possui uma conta? Registrar',
                        style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 25, 116, 172)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]
      )
    );
  }
}
// const SizedBox - apenas um espaçamento entre elementos para manter responsividade