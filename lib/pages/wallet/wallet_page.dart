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
  late Timer _timer; 
  
  bool _isLoading = true;
  String _balance = "R\$ 0,00 BRL"; // Corrigido para BRL
  String _fullAddress = "";
  String _displayAddress = "Carregando...";
  
  @override
  void initState() {
    super.initState();
    _checkAndLoadWalletStatus(); 
  }

  @override
  void dispose() {
    if (mounted && _timer.isActive) {
        _timer.cancel(); 
    }
    super.dispose();
  }
  
  // --- FUNÇÃO DE NAVEGAÇÃO AUXILIAR ---
  void _navigateTo(String routeName) {
    Navigator.pushNamed(context, routeName); 
  }
  // ------------------------------------

  // --- NOVA LÓGICA: ATUALIZAÇÃO ROBUSTA DO ESTADO ---
  void _updateStateWithData(Map<String, dynamic> data) {
    if (!mounted) return;

    // Garante que o valor seja tratado como String ou número
    final dynamic balanceRaw = data['balance_eth'];
    final String balanceAsString = balanceRaw?.toString() ?? '0';

    // Converte a String para double de forma segura (para lidar com centavos)
    final balanceAsDouble = double.tryParse(balanceAsString) ?? 0.0;
    
    // Divisão por 100.0 para formatar centavos/wei em Reais
    final balanceInBRL = balanceAsDouble; 

    final fullAddress = data['address'] as String? ?? "0x000...000";

    setState(() {
      // Formata o valor final para o padrão brasileiro (R$ X.XXX,XX BRL)
      _balance = "R\$ ${balanceInBRL.toStringAsFixed(2).replaceAll('.', ',')} BRL";
      
      _fullAddress = fullAddress;
      _displayAddress = fullAddress.length > 10 
          ? '${fullAddress.substring(0, 6)}...${fullAddress.substring(fullAddress.length - 4)}'
          : fullAddress;
    });
  }

  // --- LÓGICA DE BUSCA DA CARTEIRA E POLING ---
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
        // Carteira existe: Carrega dados e inicia o Polling
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
      if (mounted && (this as dynamic)._timer != null && _timer.isActive) {
          _timer.cancel();
      }
      _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
          _fetchWalletData(showLoading: false); // Busca silenciosa
      });
  }

  void _fetchWalletData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() { _isLoading = true; });
    }
    
    try {
      final balanceData = await _authService.getBalance();
      
      // Usa a nova função para atualizar o estado com a formatação BRL
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
              Text(_displayAddress, style: const TextStyle(color: darkText, fontSize: 16)), // Endereço Encurtado
              const Icon(Icons.copy, color: lightGreyText, size: 16), // Ícone de Copiar
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
              // --- Seção de Saldo Principal ---
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Text(
                      _balance, // SALDO DINÂMICO FORMATADO
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
                  _buildWalletActionButton(
                    Icons.arrow_upward, 
                    "Enviar", 
                    primaryBlue, 
                    () => _navigateTo(AppRoutes.sendPage),
                  ),
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