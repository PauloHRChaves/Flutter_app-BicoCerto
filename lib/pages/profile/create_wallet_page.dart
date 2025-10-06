import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'wallet_page.dart';

class CreateWalletPage extends StatefulWidget {
  const CreateWalletPage({super.key});

  @override
  State<CreateWalletPage> createState() => _CreateWalletPageState();
}

class _CreateWalletPageState extends State<CreateWalletPage> {
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleCreateWallet() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("A senha é obrigatória.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.createWallet(password: _passwordController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Carteira criada com sucesso!")),
      );
      // Navega para a WalletPage após a criação
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WalletPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao criar carteira: ${e.toString()}")),
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
      appBar: AppBar(title: const Text("Criar/Importar Carteira")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Você precisa criar uma carteira para acessar o sistema financeiro.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Sua Senha"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleCreateWallet,
                    child: const Text("Criar Nova Carteira"),
                  ),
            const SizedBox(height: 20),
            // Botão Importar (opcional)
            TextButton(
              onPressed: () {
                // Lógica futura para importação de chave privada ou mnemônica
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Funcionalidade de importação a ser implementada.")),
                );
              },
              child: const Text("Importar Carteira Existente"),
            ),
          ],
        ),
      ),
    );
  }
}