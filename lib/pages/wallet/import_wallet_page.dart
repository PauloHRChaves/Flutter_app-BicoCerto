// lib/pages/wallet/import_wallet_page.dart

import 'package:bico_certo/routes.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'package:flutter/material.dart';

class ImportWalletPage extends StatefulWidget {
  const ImportWalletPage({super.key});

  @override
  State<ImportWalletPage> createState() => _ImportWalletPageState();
}

class _ImportWalletPageState extends State<ImportWalletPage> {
  final _formKey = GlobalKey<FormState>();
  final _privateKeyController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _privateKeyController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _importWallet() async {
    // Valida se os campos do formulário foram preenchidos
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Chama o método que criamos no AuthService
      await _authService.importWalletFromPrivateKey(
        privateKey: _privateKeyController.text,
        password: _passwordController.text,
      );

      // Se a importação deu certo, mostra uma mensagem de sucesso
      // e navega para a tela da carteira, limpando as telas anteriores.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Carteira importada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.walletPage,
          (route) => false, // Remove todas as rotas anteriores
        );
      }
    } catch (e) {
      // Se deu erro, mostra a mensagem de erro para o usuário
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao importar carteira: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Garante que o estado de loading seja desativado, mesmo com erro
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar Carteira'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Importe uma carteira existente usando sua chave privada.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              
              // Campo para a Chave Privada
              TextFormField(
                controller: _privateKeyController,
                decoration: const InputDecoration(
                  labelText: 'Chave Privada',
                  border: OutlineInputBorder(),
                  hintText: 'Cole sua chave privada aqui',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira sua chave privada.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Campo para a Senha
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Sua Senha',
                  border: OutlineInputBorder(),
                  hintText: 'Senha de acesso da sua conta',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira sua senha.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Botão de Importar
              ElevatedButton(
                onPressed: _isLoading ? null : _importWallet,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Importar Carteira',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}