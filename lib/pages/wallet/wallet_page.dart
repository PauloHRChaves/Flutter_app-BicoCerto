
// lib/pages/profile/wallet_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'dart:async';
import 'package:bico_certo/services/auth_service.dart';
import 'package:bico_certo/widgets/bottom_navbar.dart';
import 'package:bico_certo/routes.dart'; 

// --- CONSTANTES DE NÍVEL SUPERIOR ---
const Color lightBackground = Colors.white;
const Color cardColor = Color.fromARGB(255, 245, 245, 245);
const Color primaryBlue = Color.fromARGB(255, 25, 116, 172);
const Color darkText = Color.fromARGB(255, 30, 30, 30);
const Color lightGreyText = Color.fromARGB(255, 97, 97, 97);
const Color darkContrastColor = Color.fromARGB(255, 18, 18, 18); 

// --- Função Auxiliar Definida FORA da Classe (para os botões) ---
Widget _buildWalletActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    child: Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: primaryBlue, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: darkText, fontSize: 13)),
      ],
    ),
  );
}
// --- FIM DA FUNÇÃO AUXILIAR ---


class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final AuthService _authService = AuthService();
  Timer? _timer; 
  
  bool _isLoading = true;
  String _balance = "Carregando...";
  String _fullAddress = "";
  String _displayAddress = "Carregando...";
  
  @override
  void initState() {
    super.initState();
    _checkAndLoadWalletStatus(); 
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }
  
  // --- FUNÇÃO DE NAVEGAÇÃO AUXILIAR ---
  void _navigateTo(String routeName) {
    Navigator.pushNamed(context, routeName); 
  }
  // ------------------------------------

  // =============================================================
  // --- FLUXO DE DELEÇÃO (Com dois pop-ups e API Call) ---
  // =============================================================

  // 1. Função principal que inicia o fluxo de deleção
  Future<void> _handleDeleteWallet() async {
    // Mostra o primeiro diálogo e espera o usuário confirmar (true) ou cancelar (false/null).
    final bool? confirmed = await _showDeleteConfirmationDialog();

    // Se o usuário não confirmou, não faz mais nada.
    if (confirmed != true) {
      return;
    }

    // Se confirmou, mostra o segundo diálogo e espera pela senha.
    final String? password = await _showPasswordDialogForDeletion();

    // Se o usuário não digitou uma senha (cancelou ou voltou), não faz mais nada.
    if (password == null || password.isEmpty) {
      return;
    }

    // Com a senha em mãos, agora sim executamos a lógica de exclusão.
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excluindo carteira...')),
      );

      // Assumindo que você adicionou o método deleteWallet no AuthService
      await _authService.deleteWallet(password: password);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carteira excluída com sucesso!'), backgroundColor: Colors.green),
      );

      // Navega para a tela de checagem de sessão e remove todas as telas anteriores
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.sessionCheck, (route) => false);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 2. Mostra o PRIMEIRO pop-up (confirmação)
  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Carteira'),
          content: const Text(
            'Você tem certeza que quer excluir sua carteira?.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false); // Retorna 'false'
              },
            ),
            TextButton(
              child: const Text('Sim, continuar', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true); // Retorna 'true'
              },
            ),
          ],
        );
      },
    );
  }

  // 3. Mostra o SEGUNDO pop-up (senha)
  Future<String?> _showPasswordDialogForDeletion() {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmação de Segurança'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Digite sua senha'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'A senha é obrigatória.';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(null); // Retorna nulo
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Excluir Definitivamente'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // Apenas retorna a senha, a lógica de API está em _handleDeleteWallet
                  Navigator.of(context).pop(passwordController.text);
                }
              },
            ),
          ],
        );
      },
    );
  }
  // =============================================================
  // --- FIM DAS NOVAS FUNÇÕES ---
  // =============================================================


  // --- NOVA LÓGICA: CHECAGEM E REDIRECIONAMENTO ---
  void _checkAndLoadWalletStatus() async {
    try {
      final details = await _authService.getWalletDetails(); 

      if (details.containsKey('has_wallet') && details['has_wallet'] == false) {
        if (mounted) {
            Navigator.pushReplacementNamed(
                context,
                AppRoutes.createWalletPage,
            );
        }
      } else {
        _fetchWalletData(showLoading: true); 
        _startPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() { 
          _balance = "Erro de API";
          _isLoading = false; 
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro de autenticação ou conexão: ${e.toString()}')),
        );
      }
    }
  }

  void _startPolling() {
      _timer?.cancel(); 

      _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
          _fetchWalletData(showLoading: false);
      });
  }


  // --- LÓGICA DE BUSCA E FORMATO (Fetch Data) ---
  void _fetchWalletData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() { _isLoading = true; });
    }
    
    try {
      final balanceData = await _authService.getBalance();
      _updateStateWithData(balanceData); 

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _balance = "Erro ao carregar";
          _isLoading = false;
        });
      }
    }
  }

  // --- MUDANÇA: Centraliza a lógica de atualização do estado ---
  void _updateStateWithData(Map<String, dynamic> data) {
    if (!mounted) return;

    final dynamic balanceRaw = data['balance_eth'];
    final String balanceAsString = balanceRaw?.toString() ?? '0';

    final balanceAsDouble = double.tryParse(balanceAsString) ?? 0.0;
    
    // Divisão por 100.0 para formatar centavos/wei em Reais
    final balanceInBRL = balanceAsDouble / 100.0; 

    final fullAddress = data['address'] as String? ?? "0x000...000";

    setState(() {
      _balance = "R\$ ${balanceInBRL.toStringAsFixed(2).replaceAll('.', ',')} BRL";
      
      _fullAddress = fullAddress;
      _displayAddress = fullAddress.length > 10 
          ? '${fullAddress.substring(0, 6)}...${fullAddress.substring(fullAddress.length - 4)}'
          : fullAddress;
    });
  }


  // --- LÓGICA DE COPIAR ---
  void _copyToClipboard() {
    if (_fullAddress.isNotEmpty && _fullAddress != "0x000...000") {
      Clipboard.setData(ClipboardData(text: _fullAddress));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Endereço copiado!')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryBlue)),
        backgroundColor: lightBackground,
      );
    }

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 1,
        title: GestureDetector(
          onTap: _copyToClipboard,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet, color: primaryBlue, size: 24),
              const SizedBox(width: 8),
              Text(_displayAddress, style: const TextStyle(color: darkText, fontSize: 18)),
              const Icon(Icons.copy, color: lightGreyText, size: 16),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner, color: darkText), onPressed: () {}),
          // --- NOVO ÍCONE DE LIXEIRA ADICIONADO AQUI ---
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _handleDeleteWallet, // <<< CHAMA O FLUXO DE DELEÇÃO
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: darkText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Seção de Saldo Principal ---
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Text(
                      _balance,
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: darkText),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "+\$0 (0.00%) Portfolio >",
                        style: TextStyle(color: Colors.greenAccent, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // --- Botões de Ação Rápida (Send e Receive) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildWalletActionButton(Icons.arrow_upward, "Enviar", primaryBlue, () => _navigateTo(AppRoutes.sendPage)),
                  _buildWalletActionButton(Icons.arrow_downward, "Receber", primaryBlue, () => _navigateTo(AppRoutes.receivePage)),
                ],
              ),
              const SizedBox(height: 30),

              // --- Abas (Saldo e Histórico) ---
              const TabBar(
                indicatorColor: primaryBlue,
                labelColor: darkText,
                unselectedLabelColor: lightGreyText,
                tabs: [
                  Tab(text: "Saldo"),
                  Tab(text: "Histórico"),
                ],
              ),
              SizedBox(
                height: 400,
                child: TabBarView(
                  children: [
                    // Conteúdo da aba Saldo
                    Center(
                      child: ListTile(
                        leading: const CircleAvatar(radius: 18, backgroundColor: Colors.yellow, child: Text("B", style: TextStyle(color: darkContrastColor))),
                        title: const Text("BRL", style: TextStyle(color: darkText, fontWeight: FontWeight.bold)),
                        trailing: Text(_balance, style: const TextStyle(color: darkText)),
                        subtitle: const Text("Bico Certo", style: TextStyle(color: lightGreyText)),
                      ),
                    ),
                    // Conteúdo da aba Histórico
                    const Center(child: Text("Histórico de Transações", style: TextStyle(color: darkText))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // --- BARRA DE NAVEGAÇÃO CUSTOMIZADA ---
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2, 
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.sessionCheck, (route) => route.isFirst);
          } else if (index == 1) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.ordersPage, (route) => route.isFirst);
          } else if (index == 2) {
            // Já estamos na Carteira, não faz nada
          } else if (index == 3) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.profilePage, (route) => route.isFirst);
          }
        },
      ),
    );
  }
}