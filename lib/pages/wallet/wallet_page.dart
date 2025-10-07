/*

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
*/

//1
// lib/pages/wallet/wallet_page.dart

//2

/*
import 'package:bico_certo/routes.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'package:bico_certo/widgets/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

// --- CONSTANTES DE NÍVEL SUPERIOR ---
const Color lightBackground = Colors.white;
const Color cardColor = Color.fromARGB(255, 245, 245, 245);
const Color primaryBlue = Color.fromARGB(255, 25, 116, 172);
const Color darkText = Color.fromARGB(255, 30, 30, 30);
const Color lightGreyText = Color.fromARGB(255, 97, 97, 97);
const Color darkContrastColor = Color.fromARGB(255, 18, 18, 18);

// --- Widget Auxiliar para Botões de Ação ---
Widget _buildWalletActionButton(
    IconData icon, String label, Color color, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(30),
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

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final AuthService _authService = AuthService();
  Timer? _pollingTimer; // <-- MUDANÇA: Timer agora é anulável

  // --- Variáveis de Estado para os dados da carteira ---
  String _balance = "R\$ 0,00 BRL";
  String _fullAddress = "";
  String _displayAddress = "";

  // <-- MUDANÇA: Futuro que controlará o estado inicial da tela ---
  late Future<Map<String, dynamic>> _initialLoadFuture;

  @override
  void initState() {
    super.initState();
    // Inicia a carga inicial uma única vez
    _initialLoadFuture = _performInitialLoad();
  }

  @override
  void dispose() {
    // Cancela o timer para evitar vazamento de memória
    _pollingTimer?.cancel();
    super.dispose();
  }

  // --- LÓGICA PRINCIPAL DE CARGA E VERIFICAÇÃO ---
  Future<Map<String, dynamic>> _performInitialLoad() async {
  // 1. Verifica se a carteira existe
  print('🔎 [WALLET_PAGE] Verificando se a carteira existe...'); // Linha de debug 1

  final details = await _authService.getWalletDetails();

  // A LINHA MAIS IMPORTANTE PARA DEBUG:
  print('✅ [WALLET_PAGE] Resposta da API (getWalletDetails): $details'); // Linha de debug 2

  if (details['address'] == null) {
    // Se entrar aqui, algo na condição acima falhou
    print('❌ [WALLET_PAGE] CONDIÇÃO FALHOU! details[\'has_wallet\'] não é true. Redirecionando...');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.createWalletPage);
      }
    });
    throw Exception('Carteira não encontrada. Redirecionando...');
  }

  // Se passar da condição, continuará daqui...
  print('👍 [WALLET_PAGE] Carteira encontrada! Carregando dados...');
  final balanceData = await _authService.getBalance();
  _updateStateWithData(balanceData);
  _startPolling();
  return balanceData;
}

  // --- LÓGICA DE ATUALIZAÇÃO CONTÍNUA (POLLING) ---
  void _startPolling() {
    _pollingTimer?.cancel(); // Cancela qualquer timer anterior
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      // Busca silenciosa, sem mostrar tela de loading
      _fetchWalletDataSilently();
    });
  }

  Future<void> _fetchWalletDataSilently() async {
    try {
      final balanceData = await _authService.getBalance();
      _updateStateWithData(balanceData);
    } catch (e) {
      // Em uma busca silenciosa, podemos apenas logar o erro sem incomodar o usuário
      print("Erro no polling da carteira: $e");
    }
  }

  // --- MUDANÇA: Centraliza a lógica de atualização do estado ---
  void _updateStateWithData(Map<String, dynamic> data) {
    if (!mounted) return; // Garante que o widget ainda está na árvore

    final balanceEth = (data['balance_eth'] as num?)?.toDouble() ?? 0.0;
    final fullAddress = data['address'] as String? ?? "0x000...000";

    setState(() {
      _balance = "R\$ ${balanceEth.toStringAsFixed(2).replaceAll('.', ',')} BRL";
      _fullAddress = fullAddress;
      _displayAddress = fullAddress.length > 10
          ? '${fullAddress.substring(0, 6)}...${fullAddress.substring(fullAddress.length - 4)}'
          : fullAddress;
    });
  }

  // --- LÓGICA DE COPIAR PARA A ÁREA DE TRANSFERÊNCIA ---
  void _copyToClipboard() {
    if (_fullAddress.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _fullAddress));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Endereço da carteira copiado!'),
            backgroundColor: primaryBlue),
      );
    }
  }

  // --- NAVEGAÇÃO ---
  void _navigateTo(String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      // <-- MUDANÇA: FutureBuilder gerencia a tela de loading/erro inicial
      body: FutureBuilder<Map<String, dynamic>>(
        future: _initialLoadFuture,
        builder: (context, snapshot) {
          // Enquanto espera a verificação e carga inicial
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryBlue));
          }

          // Se a carga inicial falhou (ex: sem internet ou carteira não existe)
          if (snapshot.hasError) {
            // Se o erro for de redirecionamento, a tela ficará em branco brevemente.
            // Para outros erros (ex: API), mostramos uma mensagem.
            if (!snapshot.error.toString().contains('Redirecionando')) {
              return Center(child: Text("Erro ao carregar dados.", style: TextStyle(color: darkText)));
            }
            // Retorna um container vazio enquanto o redirecionamento acontece
            return Container(color: lightBackground);
          }

          // Se tudo correu bem, constrói a UI principal
          return _buildWalletUI();
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.sessionCheck, (route) => route.isFirst);
          if (index == 1) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.ordersPage, (route) => route.isFirst);
          if (index == 3) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.profilePage, (route) => route.isFirst);
        },
      ),
    );
  }

  // <-- MUDANÇA: Toda a UI foi movida para este método ---
  Widget _buildWalletUI() {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 1,
        centerTitle: true,
        title: GestureDetector(
          onTap: _copyToClipboard,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet, color: primaryBlue, size: 24),
              const SizedBox(width: 8),
              Text(_displayAddress, style: const TextStyle(color: darkText, fontSize: 16)),
              const Icon(Icons.copy, color: Colors.grey, size: 16, key: ValueKey('copyIcon')),
            ],
          ),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: darkText),
              onPressed: () {}),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: darkText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                _balance,
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: darkText),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildWalletActionButton(Icons.arrow_upward, "Enviar", primaryBlue,
                      () => _navigateTo(AppRoutes.sendPage)),
                  _buildWalletActionButton(Icons.arrow_downward, "Receber",
                      primaryBlue, () => _navigateTo(AppRoutes.receivePage)),
                ],
              ),
              const SizedBox(height: 30),
              const TabBar(
                indicatorColor: primaryBlue,
                labelColor: darkText,
                unselectedLabelColor: lightGreyText,
                tabs: [Tab(text: "Saldo"), Tab(text: "Histórico")],
              ),
              SizedBox(
                height: 300, // Altura ajustada
                child: TabBarView(
                  children: [
                    // Aba Saldo
                    Center(
                      child: ListTile(
                        leading: const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.yellow,
                            child: Text("B", style: TextStyle(color: darkContrastColor))),
                        title: const Text("BRL", style: TextStyle(color: darkText, fontWeight: FontWeight.bold)),
                        trailing: Text(_balance, style: const TextStyle(color: darkText)),
                        subtitle: const Text("Bico Certo", style: TextStyle(color: lightGreyText)),
                      ),
                    ),
                    // Aba Histórico
                    const Center(child: Text("Histórico de Transações", style: TextStyle(color: darkText))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

*/

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
    final balanceInBRL = balanceAsDouble / 100.0; 

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