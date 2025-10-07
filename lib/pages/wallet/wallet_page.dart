// lib/pages/profile/wallet_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'dart:async';
import 'package:bico_certo/services/auth_service.dart'; // Correção de import
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
          child: Icon(icon, color: primaryBlue, size: 24), // Cor do ícone deve ser primaryBlue (não white)
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: darkText, fontSize: 13)), // Corrigido para darkText
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
  // FINALMENTE ACESSÍVEL: Se o import estiver correto, estas classes estarão disponíveis
  final AuthService _authService = AuthService();
  late Timer _timer; 
  
  bool _isLoading = true;
  String _balance = "Carregando...";
  String _fullAddress = "";
  String _displayAddress = "Carregando...";
  
  @override
  void initState() {
    super.initState();
    _checkAndLoadWalletStatus(); 
    // O timer será inicializado em _startPolling()
  }

  @override
  void dispose() {
    if (mounted && _timer.isActive) {
        _timer.cancel(); 
    }
    super.dispose();
  }
  
  // --- FUNÇÃO DE NAVEGAÇÃO AUXILIAR (CORRIGE ERROS DE NAVEGAÇÃO) ---
  void _navigateTo(String routeName) {
    Navigator.pushNamed(context, routeName); 
  }
  // ----------------------------------------------------

  // --- NOVA LÓGICA: CHECAGEM E REDIRECIONAMENTO ---
  void _checkAndLoadWalletStatus() async {
    try {
      final details = await _authService.getWalletDetails(); 

      if (details['has_wallet'] == true) {
        _fetchWalletData(showLoading: true); 
        _startPolling();
      } else {
        if (mounted) {
            Navigator.pushReplacementNamed(
                context,
                AppRoutes.createWalletPage,
            );
        }
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
      // Garantimos que o timer só seja inicializado uma vez
      if (mounted && (this as dynamic)._timer != null && _timer.isActive) {
          _timer.cancel();
      }
      _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
          _fetchWalletData(showLoading: false); // Busca silenciosa
      });
  }


  // --- LÓGICA DE BUSCA E FORMATO (Fetch Data) ---
  void _fetchWalletData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() { _isLoading = true; });
    }
    
    try {
      final balanceData = await _authService.getBalance();
      
      final balanceEth = (balanceData['balance_eth'] as num?)?.toDouble() ?? 0.0; 
      final fullAddress = balanceData['address'] as String? ?? "0x000...000";

      final formattedBalance = "R\$ ${balanceEth.toStringAsFixed(2).replaceAll('.', ',')} BRL";

      if (mounted) {
        setState(() {
          _balance = formattedBalance;
          _fullAddress = fullAddress;
          _displayAddress = '${fullAddress.substring(0, 6)}...${fullAddress.substring(fullAddress.length - 4)}';
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
              const Text("Wallet ID", style: TextStyle(color: darkText, fontSize: 18)),
              const Icon(Icons.keyboard_arrow_down, color: darkText),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner, color: darkText), onPressed: () {}),
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
              // --- Seção de Endereço Copiável ---
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: InkWell(
                    onTap: _copyToClipboard,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_displayAddress, style: const TextStyle(color: darkText, fontSize: 16)),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy, color: Colors.grey, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // --- Seção de Saldo Principal ---
              Center(
                child: Column(
                  children: [
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
                  // Botão ENVIAR
                  _buildWalletActionButton(
                    Icons.arrow_upward, 
                    "Enviar", 
                    primaryBlue, 
                    () => _navigateTo(AppRoutes.sendPage),
                  ),
                  // Botão RECEBER
                  _buildWalletActionButton(
                    Icons.arrow_downward, 
                    "Receber", 
                    primaryBlue, 
                    () => _navigateTo(AppRoutes.receivePage),
                  ),
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
      // --- BARRA DE NAVEGAÇÃO CUSTOMIZADA (CORRIGIDA) ---
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