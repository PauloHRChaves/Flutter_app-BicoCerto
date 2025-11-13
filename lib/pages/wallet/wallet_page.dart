import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:bico_certo/services/auth_service.dart';
import 'package:bico_certo/services/chat_api_service.dart';
import 'package:bico_certo/services/wallet_state_service.dart';
import 'package:bico_certo/routes.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../utils/string_formatter.dart';

const Color lightBackground = Colors.white;
const Color primaryBlue = Color.fromARGB(255, 25, 116, 172);
const Color darkText = Color.fromARGB(255, 30, 30, 30);
const Color lightGreyText = Color.fromARGB(255, 97, 97, 97);
const Color darkContrastColor = Color.fromARGB(255, 18, 18, 18);

Widget _buildWalletActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
    ) {
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

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final AuthService _authService = AuthService();
  final ChatApiService _chatApiService = ChatApiService();
  final WalletStateService _walletStateService = WalletStateService();

  WebSocketChannel? _websocketChannel;
  bool _isWebSocketConnected = false;

  bool _isLoading = true;
  String _balance = "Carregando...";
  String _fullAddress = "";
  String _displayAddress = "Carregando...";

  List<Map<String, dynamic>> _transactions = [];
  bool _isHistoryLoading = true;

  @override
  void initState() {
    super.initState();
    _walletStateService.setViewingWallet(true);
    _checkAndLoadWalletStatus();
  }

  @override
  void dispose() {
    _walletStateService.setViewingWallet(false);
    _websocketChannel?.sink.close();
    super.dispose();
  }

  Future<void> _navigateTo(String routeName) async {
    final result = await Navigator.pushNamed(context, routeName);

    if (result == true && routeName == AppRoutes.sendPage) {
      _fetchWalletData(showLoading: false);
    }
  }

  Future<void> _connectWebSocket() async {
    try {
      _websocketChannel = await _chatApiService.connectNotificationsWebSocket();

      if (mounted) {
        setState(() {
          _isWebSocketConnected = true;
        });
      }

      _websocketChannel!.stream.listen(
            (message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isWebSocketConnected = false;
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isWebSocketConnected = false;
            });
          }

          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _connectWebSocket();
            }
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isWebSocketConnected = false;
        });
      }
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];

      if (type == 'wallet_update') {
        final updateData = data['data'];
        final transactionType = updateData['transaction_type'];
        final txMessage = updateData['message'];

        // Mostrar SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    transactionType == 'receive'
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      txMessage ?? 'Transação processada',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: transactionType == 'receive'
                  ? Colors.green[700]
                  : Colors.blue[700],
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        _fetchWalletData(showLoading: false);
      }
    } catch (e) {
      print('❌ Erro ao processar mensagem WebSocket: $e');
    }
  }

  // =============================================================
  // FLUXO DE DELEÇÃO (mantido igual)
  // =============================================================

  Future<void> _handleDeleteWallet() async {
    final bool? confirmed = await _showDeleteConfirmationDialog();

    if (confirmed != true) {
      return;
    }

    final String? password = await _showPasswordDialogForDeletion();

    if (password == null || password.isEmpty) {
      return;
    }

    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excluindo carteira...'))
      );

      await _authService.deleteWallet(password: password);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carteira excluída com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.sessionCheck,
            (route) => false,
      );
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
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text(
                'Sim, continuar',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecorationPass(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    );
  }

  Future<String?> _showPasswordDialogForDeletion() {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool passwordVisible = false;

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Confirmação de Segurança',
                style: TextStyle(fontSize: 20),
              ),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: passwordController,
                  obscureText: !passwordVisible,
                  decoration: _inputDecorationPass('Senha').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          passwordVisible = !passwordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'A senha é obrigatória' : null,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'Excluir Definitivamente',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(context).pop(passwordController.text);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _checkAndLoadWalletStatus() async {
    try {
      final details = await _authService.getWalletDetails();

      if (details.containsKey('has_wallet') && details['has_wallet'] == false) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.createWalletPage);
        }
      } else {

        _fetchWalletData(showLoading: true);
        _connectWebSocket();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _balance = "Erro de API";
          _isLoading = false;
          _isHistoryLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de autenticação ou conexão: ${e.toString()}'),
          ),
        );
      }
    }
  }

  void _fetchWalletData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _isHistoryLoading = true;
      });
    }

    try {
      final results = await Future.wait([
        _authService.getBalance(),
        _authService.getTransactions(limit: 20),
      ]);

      final balanceData = results[0] as Map<String, dynamic>;
      final transactionData = results[1] as List<Map<String, dynamic>>;

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
          _isHistoryLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    String formatted = '';
    int count = 0;

    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count == 3) {
        formatted = '.$formatted';
        count = 0;
      }
      formatted = intPart[i] + formatted;
      count++;
    }

    return '$formatted,$decPart';
  }

  void _updateStateWithData(
      Map<String, dynamic> balanceData,
      List<Map<String, dynamic>> transactionData,
      ) {
    if (!mounted) return;

    final dynamic balanceRaw = balanceData['balance_wei'];
    final String balanceAsString = balanceRaw?.toString() ?? '0';
    final balanceAsDouble = double.tryParse(balanceAsString) ?? 0.0;
    final balanceInETH = balanceAsDouble / 1e18;

    final fullAddress = balanceData['address'] as String? ?? "0x000...000";

    setState(() {
      _balance = "R\$ ${_formatCurrency(balanceInETH)}";

      _fullAddress = fullAddress;
      _displayAddress = fullAddress.length > 10
          ? '${fullAddress.substring(0, 6)}...${fullAddress.substring(fullAddress.length - 4)}'
          : fullAddress;

      _transactions = transactionData;
    });
  }

  void _copyToClipboard() {
    if (_fullAddress.isNotEmpty && _fullAddress != "0x000...000") {
      Clipboard.setData(ClipboardData(text: _fullAddress));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Endereço copiado!'))
      );
    }
  }

  Widget _buildTransactionList({required String filterType}) {
    final filteredTransactions = _transactions
        .where((tx) => tx['type'] == filterType)
        .toList();

    if (_isHistoryLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    if (filteredTransactions.isEmpty) {
      return Center(
        child: Text(
          filterType == 'receive'
              ? "Nenhum valor recebido encontrado."
              : "Nenhuma transferência enviada encontrada.",
          style: const TextStyle(color: Colors.grey, fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final tx = filteredTransactions[index];

        final bool isSend = tx['type'] == 'send';
        final icon = isSend ? Icons.arrow_upward : Icons.arrow_downward;
        final color = isSend ? Colors.red : Colors.green;

        final String otherPartyAddress =
            (isSend ? tx['to'] : tx['from']) ?? "Endereço Desconhecido";

        final displayAddress = otherPartyAddress.length > 10
            ? '${otherPartyAddress.substring(0, 6)}...${otherPartyAddress.substring(otherPartyAddress.length - 4)}'
            : otherPartyAddress;

        final value = double.tryParse(tx['value']?.toString() ?? '0') ?? 0.0;
        final formattedValue =
            "R\$ ${StringFormatter.formatAmount(value)}";

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            isSend ? 'Transferência Enviada' : 'Valor Recebido',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            isSend ? 'Para: $displayAddress' : 'De: $displayAddress',
          ),
          trailing: Text(
            (isSend ? '- ' : '+ ') + formattedValue,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        );
      },
    );
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
      backgroundColor: const Color.fromARGB(255, 237, 237, 237),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 15, 73, 131),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: _copyToClipboard,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Color.fromARGB(255, 255, 255, 255),
                size: 24,
              ),
              const SizedBox(width: 5),
              Text(
                _displayAddress,
                style: const TextStyle(
                  color: Color.fromARGB(255, 239, 239, 239),
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.copy,
                color: Color.fromARGB(255, 255, 255, 255),
                size: 16,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Color.fromARGB(255, 255, 68, 54),
            ),
            onPressed: _handleDeleteWallet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _balance,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildWalletActionButton(
                    Icons.arrow_upward,
                    "Enviar",
                    primaryBlue,
                        () => _navigateTo(AppRoutes.sendPage),
                  )
                ],
              ),
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Histórico de Transações',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 39, 39, 39),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const TabBar(
                            indicatorColor: primaryBlue,
                            labelColor: darkText,
                            unselectedLabelColor: lightGreyText,
                            tabs: [
                              Tab(text: "Recebido"),
                              Tab(text: "Enviado"),
                            ],
                          ),
                          SizedBox(
                            height: 400,
                            child: TabBarView(
                              children: [
                                _buildTransactionList(filterType: 'receive'),
                                _buildTransactionList(filterType: 'send'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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