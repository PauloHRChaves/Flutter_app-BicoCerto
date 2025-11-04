// lib/pages/profile/create_wallet_page.dart

import 'package:flutter/material.dart';
import 'package:bico_certo/routes.dart'; // Rotas nomeadas
import 'package:bico_certo/services/auth_service.dart'; // Serviço de API

// --- CONSTANTES DE COR ---
const Color primaryBlue = Color.fromARGB(255, 25, 116, 172);
const Color darkText = Color.fromARGB(255, 30, 30, 30);
const Color lightBackground = Colors.white;

class CreateWalletPage extends StatefulWidget {
  const CreateWalletPage({super.key});

  @override
  State<CreateWalletPage> createState() => _CreateWalletPageState();
}

class _CreateWalletPageState extends State<CreateWalletPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _passwordVisible = false;
  // Função que chama a API para criar a carteira
  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { _isLoading = true; });

    try {
      // Chamada da API: Note o uso do argumento nomeado 'password:'
      final response = await _authService.createWallet(password: _passwordController.text);

      // Extrai a mensagem de sucesso do JSON retornado pela API
      final successMessage = response['message'] as String? ?? 'Carteira criada com sucesso!'; 

      if (mounted) {
        // 1. Exibe a mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
        
        // 2. Redireciona para a WalletPage (que iniciará o getBalance no initState)
        Navigator.pushReplacementNamed(context, AppRoutes.walletPage); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar carteira: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  InputDecoration _inputDecorationPass(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 25, 118, 210),
        elevation: 1,
        title: const Text("Criar Carteira", style: TextStyle(color: Colors.white, fontSize: 25)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color.fromARGB(255, 255, 255, 255)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Sua carteira será protegida com a sua senha de acesso ao aplicativo.",
                style: TextStyle(fontSize: 16, color: darkText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              TextFormField(
                controller: _passwordController,
                decoration: _inputDecorationPass('Senha').copyWith(
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

              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        "Criar Nova Carteira",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
              const SizedBox(height: 20),
              // Botão Importar
              TextButton(
                onPressed: () {
                  // Navega para a proxima pagina import wallet page:
                  Navigator.pushNamed(context, AppRoutes.importWalletPage);
                },
                child: const Text("Importar Carteira Existente", style: TextStyle(color: primaryBlue)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}