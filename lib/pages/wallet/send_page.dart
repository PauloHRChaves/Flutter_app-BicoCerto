import 'package:bico_certo/services/auth_service.dart';
import 'package:flutter/material.dart';

import '../create/create_form.dart';

class SendPage extends StatefulWidget {
  const SendPage({super.key});

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Controladores para cada campo do formulário
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    // Limpeza dos controladores para evitar vazamento de memória
    _addressController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendTransfer() async {
    // Valida se os campos obrigatórios foram preenchidos
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Converte o valor do campo de texto para double
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));

      final response = await _authService.transferEth(
        password: _passwordController.text,
        toAddress: _addressController.text,
        amount: amount,
        note: _noteController.text,
      );

      if (mounted) {
        // Mostra a mensagem de sucesso da API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Transferência realizada com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Retorna para a tela da carteira após o sucesso e sinaliza para atualizar o saldo
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecorationPass(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 15, 73, 131),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color.fromARGB(255, 255, 255, 255)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Enviar Dinheiro',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campo Endereço de Destino
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Endereço da Carteira de Destino',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'O endereço de destino é obrigatório.';
                  }
                  if (!value.startsWith('0x')) {
                    return 'Endereço inválido. Deve começar com "0x".';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Campo Valor
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Valor a Enviar (BRL)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  CurrencyInputFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'O valor é obrigatório.';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Por favor, insira um número válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Campo Nota / Descrição
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Nota (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Campo Senha
              TextFormField(
                controller: _passwordController,
                decoration: _inputDecorationPass('Senha').copyWith(
                  prefixIcon: Icon(Icons.lock_outline),
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
                validator: (value) =>
                value!.isEmpty ? 'A senha é obrigatória' : null,
              ),

              const SizedBox(height: 40),
              // Botão de Envio
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleSendTransfer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _isLoading
                    ? Container() // Sem ícone durante o loading
                    : const Icon(Icons.send),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Confirmar Envio',
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