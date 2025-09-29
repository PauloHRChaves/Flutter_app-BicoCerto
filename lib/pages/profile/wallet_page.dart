// lib/pages/profile/wallet_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../../services/auth_service.dart';
import 'dart:async';

// --- CONSTANTES DE NÍVEL SUPERIOR (Solução para o erro) ---
const Color darkBackground = Color.fromARGB(255, 18, 18, 18);
const Color cardColor = Color.fromARGB(255, 30, 30, 30);
const Color primaryBlue = Color.fromARGB(255, 25, 116, 172);
const Color lightText = Colors.white;
const Color darkText = Color.fromARGB(255, 30, 30, 30); // Definindo darkText aqui para o buildAction

// --- Função Auxiliar Definida FORA da Classe (para os botões) ---
Widget _buildWalletActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    child: Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: lightText, fontSize: 13)),
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
  String _balance = "\$0.00 USD";
  String _fullAddress = "";
  String _displayAddress = "Carregando...";
  
  @override
  void initState() {
    super.initState();
    _fetchWalletData();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchWalletData(showLoading: false); 
    });
  }

  @override
  void dispose() {
    _timer.cancel(); 
    super.dispose();
  }

  // --- LÓGICA DE BUSCA E FORMATO ---
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
        if (showLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao carregar dados: ${e.toString()}')),
            );
        }
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
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        title: GestureDetector(
          onTap: _copyToClipboard,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet, color: primaryBlue, size: 24),
              const SizedBox(width: 8),
              const Text("Wallet ID", style: TextStyle(color: lightText, fontSize: 18)),
              const Icon(Icons.keyboard_arrow_down, color: lightText),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner, color: lightText), onPressed: () {}),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: lightText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading && _balance == "\$0.00 USD"
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : DefaultTabController(
        length: 3,
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
                          Text(_displayAddress, style: const TextStyle(color: lightText, fontSize: 16)),
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
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: lightText),
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

              // --- Botões de Ação Rápida ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWalletActionButton(Icons.account_balance_wallet_outlined, "Buy & Sell", primaryBlue, () {}),
                  _buildWalletActionButton(Icons.swap_horiz, "Swap", primaryBlue, () {}),
                  _buildWalletActionButton(Icons.link, "Bridge", primaryBlue, () {}),
                  _buildWalletActionButton(Icons.arrow_upward, "Send", primaryBlue, () {}),
                  _buildWalletActionButton(Icons.arrow_downward, "Receive", primaryBlue, () {}),
                ],
              ),
              const SizedBox(height: 30),

              // --- Cartão de Financiamento (Simulado) ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.blueAccent, size: 30),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Fund your wallet", style: TextStyle(color: lightText, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("Add or transfer tokens to get started", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- Abas (Tokens, NFTs, Activity) ---
              const TabBar(
                indicatorColor: primaryBlue,
                labelColor: lightText,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: "Tokens"),
                  Tab(text: "NFTs"),
                  Tab(text: "Activity"),
                ],
              ),
              SizedBox(
                height: 400,
                child: TabBarView(
                  children: [
                    // Conteúdo da aba Tokens
                    Center(
                      child: ListTile(
                        leading: CircleAvatar(radius: 18, backgroundColor: Colors.yellow, child: Text("B", style: TextStyle(color: darkBackground))),
                        title: const Text("BRL", style: TextStyle(color: lightText, fontWeight: FontWeight.bold)),
                        trailing: Text(_balance, style: const TextStyle(color: lightText)), // Exibindo BRL no card de token
                        subtitle: const Text("Bico Certo", style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    // Conteúdo da aba NFTs
                    const Center(child: Text("Coleções de NFTs", style: TextStyle(color: lightText))),
                    // Conteúdo da aba Activity
                    const Center(child: Text("Histórico de Transações", style: TextStyle(color: lightText))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: cardColor,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Perfil"),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: "Menu"),
        ],
      ),
    );
  }
}