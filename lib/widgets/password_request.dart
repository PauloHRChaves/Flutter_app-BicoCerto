import 'package:bico_certo/routes.dart';
import 'package:flutter/material.dart';

// --- CONSTANTES DE COR (Mantidas para consistência) ---
const Color primaryBlue = Color.fromARGB(255, 25, 116, 172);
const Color darkText = Color.fromARGB(255, 30, 30, 30);
const Color lightBackground = Colors.white;


typedef ConfirmationCallback = Future<void> Function(String password);

class PasswordConfirmationWidget extends StatefulWidget {
  // 2. Parâmetros Necessários
  final ConfirmationCallback onConfirm;
  final String confirmationText;

  const PasswordConfirmationWidget({
    super.key,
    required this.onConfirm,
    required this.confirmationText,
  });

  @override
  State<PasswordConfirmationWidget> createState() =>
      _PasswordConfirmationWidgetState();
}

class _PasswordConfirmationWidgetState extends State<PasswordConfirmationWidget> {
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // 3. Função para Lidar com a Confirmação
  Future<void> _handleConfirmation() async {
    // Valida o formulário. Se for válido, continua.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true; // Inicia o estado de loading
    });

    final String password = _passwordController.text;

    try {

      await widget.onConfirm(password);
      
      if (mounted) {
        Navigator.pushNamed(context, AppRoutes.sessionCheck); 
      }
      
    } catch (e) {

      if (mounted) {

         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erro na confirmação: $e')),
         );
      }

    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Termina o estado de loading
        });
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Confirme a transação inserindo sua senha.",
              style: TextStyle(fontSize: 16, color: darkText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                labelText: 'Sua Senha',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira sua senha.';
                }
                return null;
              },
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryBlue))
                : ElevatedButton(
                    onPressed: _handleConfirmation, // Chama a função que executa o callback
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      widget.confirmationText, // Usa o texto de confirmação
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}



// --------------------FUNÇÕES PARA USAR O WIDGET--------------------
// devem estar dentro do código da página como função 
/*
  void _showConfirmationModal(
    BuildContext context, 
    String buttonText, 
    ConfirmationCallback onConfirm
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: PasswordConfirmationWidget(
            onConfirm: onConfirm,
            confirmationText: buttonText,
          ),
        );
      },
    );
  }

  void _handleJobCreationAttempt() {
    // 1. Validação de campos da página de Create Job
    if (_titleJobController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return; // Para aqui se a validação falhar
    }

    // 2. Se a validação passar, mostra o modal/widget de confirmação
    _showConfirmationModal(
      context, 
      "Criar Novo Trabalho", // Texto do botão de confirmação
      _submitOrder // <-- Passamos a função que irá precisar passar o a senha para o back!. Neste caso é a função que cria o job.
    );
  }

  */
  
  // no OnPressed do botão de criar job, chamar a função:
  // onPressed: _handleJobCreationAttempt,