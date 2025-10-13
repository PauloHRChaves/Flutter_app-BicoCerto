// lib/pages/profile/wallet_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:bico_certo/services/auth_service.dart';
import 'package:bico_certo/widgets/bottom_navbar.dart';
import 'package:bico_certo/routes.dart';

// --- CONSTANTES DE NÍVEL SUPERIOR ---
const Color lightBackground = Colors.white;
// const Color cardColor = Color.fromARGB(255, 245, 245, 245); // Não utilizada
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
          // Cor do fundo do ícone é primaryBlue.withOpacity(0.2)
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

  // --- NOVAS VARIÁVEIS DE ESTADO PARA O HISTÓRICO ---
  List<Map<String, dynamic>> _transactions = [];
  bool _isHistoryLoading = true;

  @override
  void initState() {
    super.initState();
    // Inicia a checagem do status da carteira e carrega os dados ou redireciona
    _checkAndLoadWalletStatus();
  }

  @override
  void dispose() {
    // Cancela o timer de polling ao sair da tela
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

  /// 1. Função principal que inicia o fluxo de deleção
  Future<void> _handleDeleteWallet() async {
    // Mostra o primeiro diálogo de confirmação.
    final bool? confirmed = await _showDeleteConfirmationDialog();

    // Se o usuário não confirmou, encerra a função.
    if (confirmed != true) {
      return;
    }

    // Se confirmou, mostra o segundo diálogo para coletar a senha.
    final String? password = await _showPasswordDialogForDeletion();

    // Se a senha não foi fornecida, encerra a função.
    if (password == null || password.isEmpty) {
      return;
    }

    // Executa a lógica de exclusão com a senha.
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excluindo carteira...')),
      );

      // Chama o método de deleção na API
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

  /// 2. Mostra o PRIMEIRO pop-up (confirmação)
  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Carteira'),
          content: const Text(
            'Você tem certeza que quer excluir sua carteira? Esta ação é irreversível.',
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

  /// 3. Mostra o SEGUNDO pop-up (senha)
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
  // --- FIM DO FLUXO DE DELEÇÃO ---
  // =============================================================

  // --- FUNÇÃO DE CARREGAMENTO INICIAL COMBINADA (NOVA VERSÃO) ---
  /// Checa o status da carteira, carrega saldo E histórico, e redireciona se necessário.
  void _checkAndLoadWalletStatus() async {
    try {
      final details = await _authService.getWalletDetails();

      if (details.containsKey('has_wallet') && details['has_wallet'] == false) {
        if (mounted) {
          // Redireciona para a página de criação, substituindo a rota atual
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.createWalletPage,
          );
        }
      } else {
        // Se já tem carteira, carrega os dados e inicia o polling
        // NOTE: A função _fetchWalletData foi atualizada para buscar o histórico
        _fetchWalletData(showLoading: true);
        _startPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _balance = "Erro de API";
          _isLoading = false;
          _isHistoryLoading = false; // Garante que o indicador de histórico para
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de autenticação ou conexão: ${e.toString()}')),
        );
      }
    }
  }

  /// Inicia o timer para buscar dados da carteira a cada 10 segundos.
  void _startPolling() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchWalletData(showLoading: false); // Não exibe loading spinner nas atualizações automáticas
    });
  }

  // --- LÓGICA DE BUSCA E FORMATO (Fetch Data) ---
  /// Busca o saldo, endereço e histórico da carteira na API.
  void _fetchWalletData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _isHistoryLoading = true; // Define o histórico como carregando
      });
    }

    try {
      // Busca o saldo e o histórico em paralelo
      final results = await Future.wait([
        _authService.getBalance(),
        _authService.getTransactions(limit: 20),
      ]);

      final balanceData = results[0] as Map<String, dynamic>;
      final transactionData = results[1] as List<Map<String, dynamic>>;

      // Atualiza o estado da UI
      _updateStateWithData(balanceData, transactionData);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isHistoryLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _balance = "Erro ao carregar";
          _isLoading = false;
          _isHistoryLoading = false; // Para o loading mesmo em caso de erro
        });
      }
    }
  }

  /// Centraliza a lógica de atualização do estado com os dados recebidos da API.
  void _updateStateWithData(Map<String, dynamic> balanceData, List<Map<String, dynamic>> transactionData) {
    // Garante que o widget ainda está na árvore antes de atualizar o estado
    if (!mounted) return;

    // 1. Processamento do Saldo
    final dynamic balanceRaw = balanceData['balance_wei'];
    final String balanceAsString = balanceRaw?.toString() ?? '0';
    final balanceAsDouble = double.tryParse(balanceAsString) ?? 0.0;
    // Converte o valor de Wei para ETH dividindo por 10^18.
    final balanceInETH = balanceAsDouble / 1e18;

    // 2. Processamento do Endereço
    final fullAddress = balanceData['address'] as String? ?? "0x000...000";

    // 3. Atualiza o estado da tela com os valores formatados.
    setState(() {
      // Saldo
      _balance = "R\$ ${balanceInETH.toStringAsFixed(2).replaceAll('.', ',')} BRL";

      // Endereço
      _fullAddress = fullAddress;
      _displayAddress = fullAddress.length > 10
          ? '${fullAddress.substring(0, 6)}...${fullAddress.substring(fullAddress.length - 4)}'
          : fullAddress;

      // Histórico
      _transactions = transactionData;
    });
  }
  // --- LÓGICA DE COPIAR ---
  /// Copia o endereço completo da carteira para a área de transferência.
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
    // Tela de carregamento enquanto a página inicial está buscando dados
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
          IconButton(icon: const Icon(Icons.qr_code_scanner, color: darkText), onPressed: () {
            // TODO: Implementar navegação para a tela de QR Code
          }),
          // Ícone de Lixeira para exclusão da carteira
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
                    // Botão de "Portfolio"
                    TextButton(
                      onPressed: () {
                        // TODO: Implementar navegação para a tela de Portfolio
                      },
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
              // Conteúdo das Abas
              SizedBox(
                height: 400, // Altura fixa para o TabBarView
                child: TabBarView(
                  children: [
                    // Conteúdo da aba Saldo (Lista de Ativos)
                    Center(
                      child: ListTile(
                        leading: const CircleAvatar(radius: 18, backgroundColor: Colors.yellow, child: Text("B", style: TextStyle(color: darkContrastColor))),
                        title: const Text("BRL", style: TextStyle(color: darkText, fontWeight: FontWeight.bold)),
                        trailing: Text(_balance, style: const TextStyle(color: darkText)),
                        subtitle: const Text("Bico Certo", style: TextStyle(color: lightGreyText)),
                      ),
                    ),
                    // --- ABA HISTÓRICO (SUBSTITUIÇÃO) ---
                    _isHistoryLoading
                        ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                        : _transactions.isEmpty
                            ? const Center(
                                child: Text(
                                  "Nenhuma transação encontrada.",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _transactions.length,
                                itemBuilder: (context, index) {
                                  final tx = _transactions[index];

                                  // Determina se a transação é de envio ou recebimento
                                  // NOTE: O 'type' deve vir da sua API, assumindo 'send' ou 'receive'
                                  final bool isSend = tx['type'] == 'send';

                                  // Define ícone e cor com base no tipo
                                  final icon = isSend ? Icons.arrow_upward : Icons.arrow_downward;
                                  final color = isSend ? Colors.red : Colors.green;

                                  // Pega o endereço da outra parte na transação
                                  final otherPartyAddress = isSend ? tx['to'] : tx['from'] ?? "Endereço Desconhecido";
                                  final displayAddress = otherPartyAddress.length > 10
                                      ? '${otherPartyAddress.substring(0, 6)}...${otherPartyAddress.substring(otherPartyAddress.length - 4)}'
                                      : otherPartyAddress;

                                  // Formata o valor da transação (assumindo que o 'value' já vem em BRL)
                                  final value = double.tryParse(tx['value']?.toString() ?? '0') ?? 0.0;
                                  final formattedValue = "R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}";

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: color.withOpacity(0.1),
                                      child: Icon(icon, color: color, size: 20),
                                    ),
                                    title: Text(
                                      isSend ? 'Transferência Enviada' : 'Valor Recebido',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(isSend ? 'Para: $displayAddress' : 'De: $displayAddress'),
                                    trailing: Text(
                                      (isSend ? '- ' : '+ ') + formattedValue,
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              ),
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
            // Já estamos na Carteira (índice 2)
          } else if (index == 3) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.profilePage, (route) => route.isFirst);
          }
        },
      ),
    );
  }
}